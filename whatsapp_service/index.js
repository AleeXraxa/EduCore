const {
    default: makeWASocket,
    useMultiFileAuthState,
    DisconnectReason,
    fetchLatestBaileysVersion,
    makeCacheableSignalKeyStore,
    delay
} = require('@whiskeysockets/baileys');
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const qrcode = require('qrcode');
const pino = require('pino');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: { origin: "*" }
});

app.use(cors());
app.use(express.json());

const logger = pino({ level: 'info' });
const sessions = new Map();

// Helper to get session directory
const getSessionPath = (academyId) => path.join(__dirname, 'sessions', `session-${academyId}`);

/**
 * Initialize a WhatsApp session for an academy
 */
async function initSession(academyId) {
    if (sessions.has(academyId)) {
        return sessions.get(academyId);
    }

    const sessionPath = getSessionPath(academyId);
    const { state, saveCreds } = await useMultiFileAuthState(sessionPath);
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
        version,
        auth: {
            creds: state.creds,
            keys: makeCacheableSignalKeyStore(state.keys, logger),
        },
        printQRInTerminal: false,
        logger,
    });

    const sessionObj = {
        sock,
        status: 'initializing',
        qr: null,
    };

    sessions.set(academyId, sessionObj);

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;

        if (qr) {
            sessionObj.qr = qr;
            sessionObj.status = 'qr_ready';
            io.emit(`qr-${academyId}`, { qr });
        }

        if (connection === 'close') {
            const shouldReconnect = (lastDisconnect.error?.output?.statusCode !== DisconnectReason.loggedOut);
            console.log(`Connection closed for ${academyId}, reason: ${lastDisconnect.error}, reconnecting: ${shouldReconnect}`);
            
            sessionObj.status = 'disconnected';
            io.emit(`status-${academyId}`, { status: 'disconnected' });

            if (shouldReconnect) {
                sessions.delete(academyId);
                initSession(academyId);
            } else {
                // Fully logged out, cleanup
                sessions.delete(academyId);
                if (fs.existsSync(sessionPath)) {
                    fs.rmSync(sessionPath, { recursive: true, force: true });
                }
            }
        } else if (connection === 'open') {
            console.log(`Connection opened for ${academyId}`);
            sessionObj.status = 'connected';
            sessionObj.qr = null;
            io.emit(`status-${academyId}`, { status: 'connected' });
        }
    });

    return sessionObj;
}

// REST API Endpoints

/**
 * Trigger connection/QR generation
 */
app.post('/connect', async (req, res) => {
    const { academyId } = req.body;
    if (!academyId) return res.status(400).json({ error: 'academyId is required' });

    try {
        const session = await initSession(academyId);
        res.json({ status: session.status, hasQr: !!session.qr });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * Get current status of a session
 */
app.get('/status/:academyId', (req, res) => {
    const { academyId } = req.params;
    const session = sessions.get(academyId);

    if (!session) {
        // Check if session directory exists
        const sessionPath = getSessionPath(academyId);
        if (fs.existsSync(sessionPath)) {
            return res.json({ status: 'saved_but_inactive' });
        }
        return res.json({ status: 'not_initialized' });
    }

    res.json({ status: session.status, hasQr: !!session.qr });
});

/**
 * Send a single message
 */
app.post('/send-message', async (req, res) => {
    const { academyId, to, message } = req.body;
    console.log(`[send-message] Request received for academy: ${academyId}, to: ${to}`);
    
    if (!academyId || !to || !message) {
        return res.status(400).json({ error: 'academyId, to, and message are required' });
    }

    const session = sessions.get(academyId);
    if (!session || session.status !== 'connected') {
        console.log(`[send-message] Session not connected. Status: ${session?.status}`);
        return res.status(400).json({ error: 'WhatsApp not connected' });
    }

    try {
        let numericTo = to.replace(/[^0-9]/g, '');
        if (numericTo.startsWith('0')) {
            numericTo = '92' + numericTo.substring(1);
        }
        const jid = numericTo + '@s.whatsapp.net';
        console.log(`[send-message] Sending message to JID: ${jid}`);
        
        // Add timeout to prevent hanging on invalid JIDs
        const sendPromise = session.sock.sendMessage(jid, { text: message });
        const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error("Timeout sending message")), 8000));
        
        await Promise.race([sendPromise, timeoutPromise]);
        
        console.log(`[send-message] Message sent successfully to ${jid}`);
        res.json({ success: true });
    } catch (err) {
        console.error(`[send-message] Error sending message to ${to}:`, err);
        res.status(500).json({ error: err.message });
    }
});

/**
 * Send bulk messages
 */
app.post('/send-bulk', async (req, res) => {
    const { academyId, messages } = req.body; // messages: [{ to, message }]
    if (!academyId || !Array.isArray(messages)) {
        return res.status(400).json({ error: 'academyId and messages array are required' });
    }

    const session = sessions.get(academyId);
    if (!session || session.status !== 'connected') {
        return res.status(400).json({ error: 'WhatsApp not connected' });
    }

    const results = [];
    for (const msg of messages) {
        try {
            let numericTo = msg.to.replace(/[^0-9]/g, '');
            if (numericTo.startsWith('0')) {
                numericTo = '92' + numericTo.substring(1);
            }
            const jid = numericTo + '@s.whatsapp.net';
            
            const sendPromise = session.sock.sendMessage(jid, { text: msg.message });
            const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error("Timeout sending message")), 8000));
            
            await Promise.race([sendPromise, timeoutPromise]);
            
            results.push({ to: msg.to, success: true });
            await delay(1000); // 1s delay between bulk messages to avoid spam detection
        } catch (err) {
            results.push({ to: msg.to, success: false, error: err.message });
        }
    }

    res.json({ results });
});

/**
 * Disconnect and logout
 */
app.post('/disconnect', async (req, res) => {
    const { academyId } = req.body;
    const session = sessions.get(academyId);

    if (session) {
        try {
            await session.sock.logout();
        } catch (e) {}
        sessions.delete(academyId);
    }

    const sessionPath = getSessionPath(academyId);
    if (fs.existsSync(sessionPath)) {
        fs.rmSync(sessionPath, { recursive: true, force: true });
    }

    res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`WhatsApp Service running on port ${PORT}`);
});
