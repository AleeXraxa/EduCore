import {
    default as makeWASocket,
    useMultiFileAuthState,
    DisconnectReason,
    fetchLatestBaileysVersion,
    makeCacheableSignalKeyStore,
    delay
} from '@whiskeysockets/baileys';
import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import qrcode from 'qrcode';
import pino from 'pino';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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
        queue: [],
        isProcessing: false,
    };

    sessions.set(academyId, sessionObj);

    // Queue processing logic
    const processQueue = async (aid) => {
        const session = sessions.get(aid);
        if (!session || session.isProcessing || session.queue.length === 0 || session.status !== 'connected') return;

        session.isProcessing = true;
        console.log(`[Queue-${aid}] Starting processing. Total items: ${session.queue.length}`);

        while (session.queue.length > 0) {
            const item = session.queue[0]; // Peek
            const { to, message, resolve, reject } = item;

            try {
                let numericTo = to.replace(/[^0-9]/g, '');
                if (numericTo.startsWith('0')) {
                    numericTo = '92' + numericTo.substring(1);
                }
                const jid = numericTo + '@s.whatsapp.net';
                
                await session.sock.sendMessage(jid, { text: message });
                console.log(`[Queue-${aid}] Sent to ${to}`);
                
                if (resolve) resolve({ success: true, to });
            } catch (err) {
                console.error(`[Queue-${aid}] Failed for ${to}:`, err.message);
                if (reject) reject(err);
            }

            session.queue.shift(); // Remove processed item
            
            if (session.queue.length > 0) {
                const waitTime = 1500 + Math.random() * 1000; // 1.5s - 2.5s variable delay
                await delay(waitTime);
            }
        }

        session.isProcessing = false;
        console.log(`[Queue-${aid}] Finished processing all items.`);
    };

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
            sessionObj.isProcessing = false; // Stop queue worker
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
            
            // Start processing if items were queued while disconnected
            processQueue(academyId);
        }
    });

    // Attach queue helper to session for easy access
    sessionObj.enqueue = (to, message) => {
        return new Promise((resolve, reject) => {
            sessionObj.queue.push({ to, message, resolve, reject });
            processQueue(academyId);
        });
    };

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
 * Send a single message (waits for queue turn)
 */
app.post('/send-message', async (req, res) => {
    const { academyId, to, message } = req.body;
    
    if (!academyId || !to || !message) {
        return res.status(400).json({ error: 'academyId, to, and message are required' });
    }

    const session = sessions.get(academyId);
    if (!session || session.status !== 'connected') {
        return res.status(400).json({ error: 'WhatsApp not connected' });
    }

    try {
        // Enqueue and wait for result
        const result = await session.enqueue(to, message);
        res.json(result);
    } catch (err) {
        console.error(`[API-Single] Error:`, err.message);
        res.status(500).json({ error: err.message });
    }
});

/**
 * Send bulk messages (Fire and forget into queue)
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

    // Fire and forget: Add all to queue without awaiting
    messages.forEach(msg => {
        session.enqueue(msg.to, msg.message).catch(e => {
            console.error(`[API-Bulk-Bg] Failed for ${msg.to}:`, e.message);
        });
    });

    res.json({ success: true, queuedCount: messages.length });
});

/**
 * Get queue information
 */
app.get('/queue-info/:academyId', (req, res) => {
    const { academyId } = req.params;
    const session = sessions.get(academyId);

    if (!session) return res.status(404).json({ error: 'Session not found' });

    res.json({
        queueSize: session.queue.length,
        isProcessing: session.isProcessing,
        status: session.status
    });
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

let isShuttingDown = false;

/**
 * Graceful Shutdown: Finish queue then exit
 */
app.post('/shutdown', (req, res) => {
    console.log('[System] Shutdown request received. Waiting for queues to clear...');
    isShuttingDown = true;
    res.json({ success: true, message: 'Shutting down gracefully' });

    const checkAndExit = () => {
        let allEmpty = true;
        for (const [aid, session] of sessions) {
            if (session.queue.length > 0 || session.isProcessing) {
                allEmpty = false;
                break;
            }
        }

        if (allEmpty) {
            console.log('[System] All queues clear. Exiting.');
            process.exit(0);
        } else {
            setTimeout(checkAndExit, 2000);
        }
    };

    checkAndExit();
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`WhatsApp Service running on port ${PORT}`);
});
