export const id = 164;
export const ids = [164];
export const modules = {

/***/ 91164:
/***/ ((__unused_webpack___webpack_module__, __webpack_exports__, __webpack_require__) => {

// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  MP4Parser: () => (/* binding */ MP4Parser)
});

// EXTERNAL MODULE: ./node_modules/debug/src/index.js
var src = __webpack_require__(84474);
// EXTERNAL MODULE: ./node_modules/token-types/lib/index.js
var lib = __webpack_require__(86048);
// EXTERNAL MODULE: ./node_modules/music-metadata/lib/common/BasicParser.js
var BasicParser = __webpack_require__(46633);
// EXTERNAL MODULE: ./node_modules/music-metadata/lib/id3v1/ID3v1Parser.js
var ID3v1Parser = __webpack_require__(43772);
// EXTERNAL MODULE: ./node_modules/music-metadata/lib/common/FourCC.js
var FourCC = __webpack_require__(10780);
// EXTERNAL MODULE: ./node_modules/music-metadata/lib/ParseError.js
var ParseError = __webpack_require__(74410);
// EXTERNAL MODULE: ./node_modules/music-metadata/lib/common/Util.js
var Util = __webpack_require__(60502);
;// CONCATENATED MODULE: ./node_modules/music-metadata/lib/mp4/AtomToken.js





const debug = src('music-metadata:parser:MP4:atom');
class Mp4ContentError extends (0,ParseError/* makeUnexpectedFileContentError */.fO)('MP4') {
}
const Header = {
    len: 8,
    get: (buf, off) => {
        const length = lib.UINT32_BE.get(buf, off);
        if (length < 0)
            throw new Mp4ContentError('Invalid atom header length');
        return {
            length: BigInt(length),
            name: new lib.StringType(4, 'latin1').get(buf, off + 4)
        };
    },
    put: (buf, off, hdr) => {
        lib.UINT32_BE.put(buf, off, Number(hdr.length));
        return FourCC/* FourCcToken */.e.put(buf, off + 4, hdr.name);
    }
};
/**
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap1/qtff1.html#//apple_ref/doc/uid/TP40000939-CH203-38190
 */
const ExtendedSize = lib.UINT64_BE;
const ftyp = {
    len: 4,
    get: (buf, off) => {
        return {
            type: new lib.StringType(4, 'ascii').get(buf, off)
        };
    }
};
/**
 * Token: Movie Header Atom
 */
const mhdr = {
    len: 8,
    get: (buf, off) => {
        return {
            version: lib.UINT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            nextItemID: lib.UINT32_BE.get(buf, off + 4)
        };
    }
};
/**
 * Base class for 'fixed' length atoms.
 * In some cases these atoms are longer then the sum of the described fields.
 * Issue: https://github.com/Borewit/music-metadata/issues/120
 */
class FixedLengthAtom {
    /**
     *
     * @param {number} len Length as specified in the size field
     * @param {number} expLen Total length of sum of specified fields in the standard
     * @param atomId Atom ID
     */
    constructor(len, expLen, atomId) {
        if (len < expLen) {
            throw new Mp4ContentError(`Atom ${atomId} expected to be ${expLen}, but specifies ${len} bytes long.`);
        }
        if (len > expLen) {
            debug(`Warning: atom ${atomId} expected to be ${expLen}, but was actually ${len} bytes long.`);
        }
        this.len = len;
    }
}
/**
 * Timestamp stored in seconds since Mac Epoch (1 January 1904)
 */
const SecondsSinceMacEpoch = {
    len: 4,
    get: (buf, off) => {
        const secondsSinceUnixEpoch = lib.UINT32_BE.get(buf, off) - 2082844800;
        return new Date(secondsSinceUnixEpoch * 1000);
    }
};
/**
 * Token: Media Header Atom
 * Ref:
 * - https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-SW34
 * - https://wiki.multimedia.cx/index.php/QuickTime_container#mdhd
 */
class MdhdAtom extends FixedLengthAtom {
    constructor(len) {
        super(len, 24, 'mdhd');
    }
    get(buf, off) {
        return {
            version: lib.UINT8.get(buf, off + 0),
            flags: lib.UINT24_BE.get(buf, off + 1),
            creationTime: SecondsSinceMacEpoch.get(buf, off + 4),
            modificationTime: SecondsSinceMacEpoch.get(buf, off + 8),
            timeScale: lib.UINT32_BE.get(buf, off + 12),
            duration: lib.UINT32_BE.get(buf, off + 16),
            language: lib.UINT16_BE.get(buf, off + 20),
            quality: lib.UINT16_BE.get(buf, off + 22)
        };
    }
}
/**
 * Token: Movie Header Atom
 */
class MvhdAtom extends FixedLengthAtom {
    constructor(len) {
        super(len, 100, 'mvhd');
    }
    get(buf, off) {
        return {
            version: lib.UINT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            creationTime: SecondsSinceMacEpoch.get(buf, off + 4),
            modificationTime: SecondsSinceMacEpoch.get(buf, off + 8),
            timeScale: lib.UINT32_BE.get(buf, off + 12),
            duration: lib.UINT32_BE.get(buf, off + 16),
            preferredRate: lib.UINT32_BE.get(buf, off + 20),
            preferredVolume: lib.UINT16_BE.get(buf, off + 24),
            // ignore reserver: 10 bytes
            // ignore matrix structure: 36 bytes
            previewTime: lib.UINT32_BE.get(buf, off + 72),
            previewDuration: lib.UINT32_BE.get(buf, off + 76),
            posterTime: lib.UINT32_BE.get(buf, off + 80),
            selectionTime: lib.UINT32_BE.get(buf, off + 84),
            selectionDuration: lib.UINT32_BE.get(buf, off + 88),
            currentTime: lib.UINT32_BE.get(buf, off + 92),
            nextTrackID: lib.UINT32_BE.get(buf, off + 96)
        };
    }
}
/**
 * Data Atom Structure
 */
class DataAtom {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        return {
            type: {
                set: lib.UINT8.get(buf, off + 0),
                type: lib.UINT24_BE.get(buf, off + 1)
            },
            locale: lib.UINT24_BE.get(buf, off + 4),
            value: new lib.Uint8ArrayType(this.len - 8).get(buf, off + 8)
        };
    }
}
/**
 * Data Atom Structure
 * Ref: https://developer.apple.com/library/content/documentation/QuickTime/QTFF/Metadata/Metadata.html#//apple_ref/doc/uid/TP40000939-CH1-SW31
 */
class NameAtom {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        return {
            version: lib.UINT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            name: new lib.StringType(this.len - 4, 'utf-8').get(buf, off + 4)
        };
    }
}
/**
 * Track Header Atoms structure (`tkhd`)
 * Ref: https://developer.apple.com/library/content/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25550
 */
class TrackHeaderAtom {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        return {
            version: lib.UINT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            creationTime: SecondsSinceMacEpoch.get(buf, off + 4),
            modificationTime: SecondsSinceMacEpoch.get(buf, off + 8),
            trackId: lib.UINT32_BE.get(buf, off + 12),
            // reserved 4 bytes
            duration: lib.UINT32_BE.get(buf, off + 20),
            layer: lib.UINT16_BE.get(buf, off + 24),
            alternateGroup: lib.UINT16_BE.get(buf, off + 26),
            volume: lib.UINT16_BE.get(buf, off + 28) // ToDo: fixed point
            // ToDo: add remaining fields
        };
    }
}
/**
 * Atom: Sample Description Atom ('stsd')
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25691
 */
const stsdHeader = {
    len: 8,
    get: (buf, off) => {
        return {
            version: lib.UINT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            numberOfEntries: lib.UINT32_BE.get(buf, off + 4)
        };
    }
};
/**
 * Atom: Sample Description Atom ('stsd')
 * Ref: https://developer.apple.com/documentation/quicktime-file-format/sample_description_atom
 */
class SampleDescriptionTable {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const descrLen = this.len - 12;
        return {
            dataFormat: FourCC/* FourCcToken */.e.get(buf, off),
            dataReferenceIndex: lib.UINT16_BE.get(buf, off + 10),
            description: descrLen > 0 ? new lib.Uint8ArrayType(descrLen).get(buf, off + 12) : undefined
        };
    }
}
/**
 * Atom: Sample-description Atom ('stsd')
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25691
 */
class StsdAtom {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const header = stsdHeader.get(buf, off);
        off += stsdHeader.len;
        const table = [];
        for (let n = 0; n < header.numberOfEntries; ++n) {
            const size = lib.UINT32_BE.get(buf, off); // Sample description size
            off += lib.UINT32_BE.len;
            table.push(new SampleDescriptionTable(size - lib.UINT32_BE.len).get(buf, off));
            off += size;
        }
        return {
            header,
            table
        };
    }
}
/**
 * Common Sound Sample Description (version & revision)
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap3/qtff3.html#//apple_ref/doc/uid/TP40000939-CH205-57317
 */
const SoundSampleDescriptionVersion = {
    len: 8,
    get(buf, off) {
        return {
            version: lib.INT16_BE.get(buf, off),
            revision: lib.INT16_BE.get(buf, off + 2),
            vendor: lib.INT32_BE.get(buf, off + 4)
        };
    }
};
/**
 * Sound Sample Description (Version 0)
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap3/qtff3.html#//apple_ref/doc/uid/TP40000939-CH205-130736
 */
const SoundSampleDescriptionV0 = {
    len: 12,
    get(buf, off) {
        return {
            numAudioChannels: lib.INT16_BE.get(buf, off + 0),
            sampleSize: lib.INT16_BE.get(buf, off + 2),
            compressionId: lib.INT16_BE.get(buf, off + 4),
            packetSize: lib.INT16_BE.get(buf, off + 6),
            sampleRate: lib.UINT16_BE.get(buf, off + 8) + lib.UINT16_BE.get(buf, off + 10) / 10000
        };
    }
};
class SimpleTableAtom {
    constructor(len, token) {
        this.len = len;
        this.token = token;
    }
    get(buf, off) {
        const nrOfEntries = lib.INT32_BE.get(buf, off + 4);
        return {
            version: lib.INT8.get(buf, off + 0),
            flags: lib.INT24_BE.get(buf, off + 1),
            numberOfEntries: nrOfEntries,
            entries: readTokenTable(buf, this.token, off + 8, this.len - 8, nrOfEntries)
        };
    }
}
const TimeToSampleToken = {
    len: 8,
    get(buf, off) {
        return {
            count: lib.INT32_BE.get(buf, off + 0),
            duration: lib.INT32_BE.get(buf, off + 4)
        };
    }
};
/**
 * Time-to-sample('stts') atom.
 * Store duration information for a media’s samples.
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25696
 */
class SttsAtom extends SimpleTableAtom {
    constructor(len) {
        super(len, TimeToSampleToken);
    }
}
const SampleToChunkToken = {
    len: 12,
    get(buf, off) {
        return {
            firstChunk: lib.INT32_BE.get(buf, off),
            samplesPerChunk: lib.INT32_BE.get(buf, off + 4),
            sampleDescriptionId: lib.INT32_BE.get(buf, off + 8)
        };
    }
};
/**
 * Sample-to-Chunk ('stsc') atom interface
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25706
 */
class StscAtom extends SimpleTableAtom {
    constructor(len) {
        super(len, SampleToChunkToken);
    }
}
/**
 * Sample-size ('stsz') atom
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25710
 */
class StszAtom {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const nrOfEntries = lib.INT32_BE.get(buf, off + 8);
        return {
            version: lib.INT8.get(buf, off),
            flags: lib.INT24_BE.get(buf, off + 1),
            sampleSize: lib.INT32_BE.get(buf, off + 4),
            numberOfEntries: nrOfEntries,
            entries: readTokenTable(buf, lib.INT32_BE, off + 12, this.len - 12, nrOfEntries)
        };
    }
}
/**
 * Chunk offset atom, 'stco'
 * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-25715
 */
class StcoAtom extends SimpleTableAtom {
    constructor(len) {
        super(len, lib.INT32_BE);
        this.len = len;
    }
}
/**
 * Token used to decode text-track from 'mdat' atom (raw data stream)
 */
class ChapterText {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const titleLen = lib.INT16_BE.get(buf, off + 0);
        const str = new lib.StringType(titleLen, 'utf-8');
        return str.get(buf, off + 2);
    }
}
function readTokenTable(buf, token, off, remainingLen, numberOfEntries) {
    debug(`remainingLen=${remainingLen}, numberOfEntries=${numberOfEntries} * token-len=${token.len}`);
    if (remainingLen === 0)
        return [];
    if (remainingLen !== numberOfEntries * token.len)
        throw new Mp4ContentError('mismatch number-of-entries with remaining atom-length');
    const entries = [];
    // parse offset-table
    for (let n = 0; n < numberOfEntries; ++n) {
        entries.push(token.get(buf, off));
        off += token.len;
    }
    return entries;
}
/**
 * Sample-size ('tfhd') TrackFragmentHeaderBox
 */
class TrackFragmentHeaderBox {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const flagOffset = off + 1;
        const header = {
            version: lib.INT8.get(buf, off),
            flags: {
                baseDataOffsetPresent: Util/* getBit */.mh(buf, flagOffset + 2, 0),
                sampleDescriptionIndexPresent: Util/* getBit */.mh(buf, flagOffset + 2, 1),
                defaultSampleDurationPresent: Util/* getBit */.mh(buf, flagOffset + 2, 3),
                defaultSampleSizePresent: Util/* getBit */.mh(buf, flagOffset + 2, 4),
                defaultSampleFlagsPresent: Util/* getBit */.mh(buf, flagOffset + 2, 5),
                defaultDurationIsEmpty: Util/* getBit */.mh(buf, flagOffset, 0),
                defaultBaseIsMoof: Util/* getBit */.mh(buf, flagOffset, 1)
            },
            trackId: lib.UINT32_BE.get(buf, 4)
        };
        let dynOffset = 8;
        if (header.flags.baseDataOffsetPresent) {
            header.baseDataOffset = lib.UINT64_BE.get(buf, dynOffset);
            dynOffset += 8;
        }
        if (header.flags.sampleDescriptionIndexPresent) {
            header.sampleDescriptionIndex = lib.UINT32_BE.get(buf, dynOffset);
            dynOffset += 4;
        }
        if (header.flags.defaultSampleDurationPresent) {
            header.defaultSampleDuration = lib.UINT32_BE.get(buf, dynOffset);
            dynOffset += 4;
        }
        if (header.flags.defaultSampleSizePresent) {
            header.defaultSampleSize = lib.UINT32_BE.get(buf, dynOffset);
            dynOffset += 4;
        }
        if (header.flags.defaultSampleFlagsPresent) {
            header.defaultSampleFlags = lib.UINT32_BE.get(buf, dynOffset);
        }
        return header;
    }
}
/**
 * Sample-size ('trun') TrackRunBox
 */
class TrackRunBox {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const flagOffset = off + 1;
        const trun = {
            version: lib.INT8.get(buf, off),
            flags: {
                dataOffsetPresent: Util/* getBit */.mh(buf, flagOffset + 2, 0),
                firstSampleFlagsPresent: Util/* getBit */.mh(buf, flagOffset + 2, 2),
                sampleDurationPresent: Util/* getBit */.mh(buf, flagOffset + 1, 0),
                sampleSizePresent: Util/* getBit */.mh(buf, flagOffset + 1, 1),
                sampleFlagsPresent: Util/* getBit */.mh(buf, flagOffset + 1, 2),
                sampleCompositionTimeOffsetsPresent: Util/* getBit */.mh(buf, flagOffset + 1, 3)
            },
            sampleCount: lib.UINT32_BE.get(buf, off + 4),
            samples: []
        };
        let dynOffset = off + 8;
        if (trun.flags.dataOffsetPresent) {
            trun.dataOffset = lib.UINT32_BE.get(buf, dynOffset);
            dynOffset += 4;
        }
        if (trun.flags.firstSampleFlagsPresent) {
            trun.firstSampleFlags = lib.UINT32_BE.get(buf, dynOffset);
            dynOffset += 4;
        }
        for (let n = 0; n < trun.sampleCount; ++n) {
            if (dynOffset >= this.len) {
                debug("TrackRunBox size mismatch");
                break;
            }
            const sample = {};
            if (trun.flags.sampleDurationPresent) {
                sample.sampleDuration = lib.UINT32_BE.get(buf, dynOffset);
                dynOffset += 4;
            }
            if (trun.flags.sampleSizePresent) {
                sample.sampleSize = lib.UINT32_BE.get(buf, dynOffset);
                dynOffset += 4;
            }
            if (trun.flags.sampleFlagsPresent) {
                sample.sampleFlags = lib.UINT32_BE.get(buf, dynOffset);
                dynOffset += 4;
            }
            if (trun.flags.sampleCompositionTimeOffsetsPresent) {
                sample.sampleCompositionTimeOffset = lib.UINT32_BE.get(buf, dynOffset);
                dynOffset += 4;
            }
            trun.samples.push(sample);
        }
        return trun;
    }
}
/**
 * HandlerBox (`hdlr`)
 */
class HandlerBox {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        const _flagOffset = off + 1;
        const charTypeToken = new lib.StringType(4, 'utf-8');
        return {
            version: lib.INT8.get(buf, off),
            flags: lib.UINT24_BE.get(buf, off + 1),
            componentType: charTypeToken.get(buf, off + 4),
            handlerType: charTypeToken.get(buf, off + 8),
            componentName: new lib.StringType(this.len - 28, 'utf-8').get(buf, off + 28),
        };
    }
}
/**
 * Chapter Track Reference Box (`chap`)
 */
class ChapterTrackReferenceBox {
    constructor(len) {
        this.len = len;
    }
    get(buf, off) {
        let dynOffset = 0;
        const trackIds = [];
        while (dynOffset < this.len) {
            trackIds.push(lib.UINT32_BE.get(buf, off + dynOffset));
            dynOffset += 4;
        }
        return trackIds;
    }
}

;// CONCATENATED MODULE: ./node_modules/music-metadata/lib/mp4/Atom.js



const Atom_debug = src('music-metadata:parser:MP4:Atom');
class Atom {
    static async readAtom(tokenizer, dataHandler, parent, remaining) {
        // Parse atom header
        const offset = tokenizer.position;
        Atom_debug(`Reading next token on offset=${offset}...`); //  buf.toString('ascii')
        const header = await tokenizer.readToken(Header);
        const extended = header.length === 1n;
        if (extended) {
            header.length = await tokenizer.readToken(ExtendedSize);
        }
        const atomBean = new Atom(header, extended, parent);
        const payloadLength = atomBean.getPayloadLength(remaining);
        Atom_debug(`parse atom name=${atomBean.atomPath}, extended=${atomBean.extended}, offset=${offset}, len=${atomBean.header.length}`); //  buf.toString('ascii')
        await atomBean.readData(tokenizer, dataHandler, payloadLength);
        return atomBean;
    }
    constructor(header, extended, parent) {
        this.header = header;
        this.extended = extended;
        this.parent = parent;
        this.children = [];
        this.atomPath = (this.parent ? `${this.parent.atomPath}.` : '') + this.header.name;
    }
    getHeaderLength() {
        return this.extended ? 16 : 8;
    }
    getPayloadLength(remaining) {
        return (this.header.length === 0n ? remaining : Number(this.header.length)) - this.getHeaderLength();
    }
    async readAtoms(tokenizer, dataHandler, size) {
        while (size > 0) {
            const atomBean = await Atom.readAtom(tokenizer, dataHandler, this, size);
            this.children.push(atomBean);
            size -= atomBean.header.length === 0n ? size : Number(atomBean.header.length);
        }
    }
    async readData(tokenizer, dataHandler, remaining) {
        switch (this.header.name) {
            // "Container" atoms, contains nested atoms
            case 'moov': // The Movie Atom: contains other atoms
            case 'udta': // User defined atom
            case 'mdia': // Media atom
            case 'minf': // Media Information Atom
            case 'stbl': // The Sample Table Atom
            case '<id>':
            case 'ilst':
            case 'tref':
            case 'moof':
                return this.readAtoms(tokenizer, dataHandler, this.getPayloadLength(remaining));
            case 'meta': { // Metadata Atom, ref: https://developer.apple.com/library/content/documentation/QuickTime/QTFF/Metadata/Metadata.html#//apple_ref/doc/uid/TP40000939-CH1-SW8
                // meta has 4 bytes of padding, ignore
                const peekHeader = await tokenizer.peekToken(Header);
                const paddingLength = peekHeader.name === 'hdlr' ? 0 : 4;
                await tokenizer.ignore(paddingLength);
                return this.readAtoms(tokenizer, dataHandler, this.getPayloadLength(remaining) - paddingLength);
            }
            default:
                return dataHandler(this, remaining);
        }
    }
}

// EXTERNAL MODULE: ./node_modules/music-metadata/lib/matroska/types.js
var types = __webpack_require__(97514);
// EXTERNAL MODULE: ./node_modules/uint8array-extras/index.js
var uint8array_extras = __webpack_require__(20978);
// EXTERNAL MODULE: ./node_modules/@borewit/text-codec/lib/index.js
var text_codec_lib = __webpack_require__(32130);
;// CONCATENATED MODULE: ./node_modules/music-metadata/lib/mp4/MP4Parser.js










const MP4Parser_debug = src('music-metadata:parser:MP4');
const tagFormat = 'iTunes';
const encoderDict = {
    raw: {
        lossy: false,
        format: 'raw'
    },
    MAC3: {
        lossy: true,
        format: 'MACE 3:1'
    },
    MAC6: {
        lossy: true,
        format: 'MACE 6:1'
    },
    ima4: {
        lossy: true,
        format: 'IMA 4:1'
    },
    ulaw: {
        lossy: true,
        format: 'uLaw 2:1'
    },
    alaw: {
        lossy: true,
        format: 'uLaw 2:1'
    },
    Qclp: {
        lossy: true,
        format: 'QUALCOMM PureVoice'
    },
    '.mp3': {
        lossy: true,
        format: 'MPEG-1 layer 3'
    },
    alac: {
        lossy: false,
        format: 'ALAC'
    },
    'ac-3': {
        lossy: true,
        format: 'AC-3'
    },
    mp4a: {
        lossy: true,
        format: 'MPEG-4/AAC'
    },
    mp4s: {
        lossy: true,
        format: 'MP4S'
    },
    // Closed Captioning Media, https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap3/qtff3.html#//apple_ref/doc/uid/TP40000939-CH205-SW87
    c608: {
        lossy: true,
        format: 'CEA-608'
    },
    c708: {
        lossy: true,
        format: 'CEA-708'
    }
};
function distinct(value, index, self) {
    return self.indexOf(value) === index;
}
/*
 * Parser for the MP4 (MPEG-4 Part 14) container format
 * Standard: ISO/IEC 14496-14
 * supporting:
 * - QuickTime container
 * - MP4 File Format
 * - 3GPP file format
 * - 3GPP2 file format
 *
 * MPEG-4 Audio / Part 3 (.m4a)& MPEG 4 Video (m4v, mp4) extension.
 * Support for Apple iTunes tags as found in a M4A/M4V files.
 * Ref:
 *   https://en.wikipedia.org/wiki/ISO_base_media_file_format
 *   https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/Metadata/Metadata.html
 *   http://atomicparsley.sourceforge.net/mpeg-4files.html
 *   https://github.com/sergiomb2/libmp4v2/wiki/iTunesMetadata
 *   https://wiki.multimedia.cx/index.php/QuickTime_container
 */
class MP4Parser extends BasicParser/* BasicParser */.s {
    constructor() {
        super(...arguments);
        this.tracks = new Map();
        this.hasVideoTrack = false;
        this.hasAudioTrack = true;
        this.atomParsers = {
            /**
             * Parse movie header (mvhd) atom
             * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-56313
             */
            mvhd: async (len) => {
                const mvhd = await this.tokenizer.readToken(new MvhdAtom(len));
                this.metadata.setFormat('creationTime', mvhd.creationTime);
                this.metadata.setFormat('modificationTime', mvhd.modificationTime);
            },
            chap: async (len) => {
                const td = this.getTrackDescription();
                const trackIds = [];
                while (len >= lib.UINT32_BE.len) {
                    trackIds.push(await this.tokenizer.readNumber(lib.UINT32_BE));
                    len -= lib.UINT32_BE.len;
                }
                td.chapterList = trackIds;
            },
            /**
             * Parse mdat atom.
             * Will scan for chapters
             */
            mdat: async (len) => {
                if (this.options.includeChapters) {
                    const trackWithChapters = [...this.tracks.values()].filter(track => track.chapterList);
                    if (trackWithChapters.length === 1) {
                        const chapterTrackIds = trackWithChapters[0].chapterList;
                        const chapterTracks = [...this.tracks.values()].filter(track => chapterTrackIds.indexOf(track.header.trackId) !== -1);
                        if (chapterTracks.length === 1) {
                            return this.parseChapterTrack(chapterTracks[0], trackWithChapters[0], len);
                        }
                    }
                }
                await this.tokenizer.ignore(len);
            },
            ftyp: async (len) => {
                const types = [];
                while (len > 0) {
                    const ftype = await this.tokenizer.readToken(ftyp);
                    len -= ftyp.len;
                    const value = ftype.type.replace(/\W/g, '');
                    if (value.length > 0) {
                        types.push(value); // unshift for backward compatibility
                    }
                }
                MP4Parser_debug(`ftyp: ${types.join('/')}`);
                const x = types.filter(distinct).join('/');
                this.metadata.setFormat('container', x);
            },
            /**
             * Parse sample description atom
             */
            stsd: async (len) => {
                const stsd = await this.tokenizer.readToken(new StsdAtom(len));
                const trackDescription = this.getTrackDescription();
                trackDescription.soundSampleDescription = stsd.table.map(dfEntry => this.parseSoundSampleDescription(dfEntry));
            },
            /**
             * Parse sample-sizes atom ('stsz')
             */
            stsz: async (len) => {
                const stsz = await this.tokenizer.readToken(new StszAtom(len));
                const td = this.getTrackDescription();
                td.sampleSize = stsz.sampleSize;
                td.sampleSizeTable = stsz.entries;
            },
            date: async (len) => {
                const date = await this.tokenizer.readToken(new lib.StringType(len, 'utf-8'));
                await this.addTag('date', date);
            }
        };
    }
    static read_BE_Integer(array, signed) {
        const integerType = (signed ? 'INT' : 'UINT') + array.length * 8 + (array.length > 1 ? '_BE' : '');
        const token = lib[integerType];
        if (!token) {
            throw new Mp4ContentError(`Token for integer type not found: "${integerType}"`);
        }
        return Number(token.get(array, 0));
    }
    async parse() {
        this.hasVideoTrack = false;
        this.hasAudioTrack = true;
        this.tracks.clear();
        let remainingFileSize = this.tokenizer.fileInfo.size || 0;
        while (!this.tokenizer.fileInfo.size || remainingFileSize > 0) {
            try {
                const token = await this.tokenizer.peekToken(Header);
                if (token.name === '\0\0\0\0') {
                    const errMsg = `Error at offset=${this.tokenizer.position}: box.id=0`;
                    MP4Parser_debug(errMsg);
                    this.addWarning(errMsg);
                    break;
                }
            }
            catch (error) {
                if (error instanceof Error) {
                    const errMsg = `Error at offset=${this.tokenizer.position}: ${error.message}`;
                    MP4Parser_debug(errMsg);
                    this.addWarning(errMsg);
                }
                else
                    throw error;
                break;
            }
            const rootAtom = await Atom.readAtom(this.tokenizer, (atom, remaining) => this.handleAtom(atom, remaining), null, remainingFileSize);
            remainingFileSize -= rootAtom.header.length === BigInt(0) ? remainingFileSize : Number(rootAtom.header.length);
        }
        // Post process metadata
        const formatList = [];
        this.tracks.forEach(track => {
            const trackFormats = [];
            track.soundSampleDescription.forEach(ssd => {
                const streamInfo = {};
                const encoderInfo = encoderDict[ssd.dataFormat];
                if (encoderInfo) {
                    trackFormats.push(encoderInfo.format);
                    streamInfo.codecName = encoderInfo.format;
                }
                else {
                    streamInfo.codecName = `<${ssd.dataFormat}>`;
                }
                if (ssd.description) {
                    const { description } = ssd;
                    if (description.sampleRate > 0) {
                        streamInfo.type = types/* TrackType */.S.audio;
                        streamInfo.audio = {
                            samplingFrequency: description.sampleRate,
                            bitDepth: description.sampleSize,
                            channels: description.numAudioChannels
                        };
                    }
                }
                this.metadata.addStreamInfo(streamInfo);
            });
            if (trackFormats.length >= 1) {
                formatList.push(trackFormats.join('/'));
            }
        });
        if (formatList.length > 0) {
            this.metadata.setFormat('codec', formatList.filter(distinct).join('+'));
        }
        const audioTracks = [...this.tracks.values()].filter(track => {
            return track.soundSampleDescription.length >= 1 && track.soundSampleDescription[0].description && track.soundSampleDescription[0].description.numAudioChannels > 0;
        });
        // Calculate duration and bitrate of audio tracks
        for (const audioTrack of audioTracks) {
            if (audioTrack.media.header && audioTrack.media.header.timeScale > 0) {
                audioTrack.sampleRate = audioTrack.media.header.timeScale;
                if (audioTrack.media.header.duration > 0) {
                    MP4Parser_debug('Using duration defined on audio track');
                    audioTrack.samples = audioTrack.media.header.duration;
                    audioTrack.duration = audioTrack.samples / audioTrack.sampleRate;
                }
                if (audioTrack.fragments.length > 0) {
                    MP4Parser_debug('Calculate duration defined in track fragments');
                    let totalTimeUnits = 0;
                    audioTrack.sizeInBytes = 0;
                    for (const fragment of audioTrack.fragments) {
                        for (const sample of fragment.trackRun.samples) {
                            const dur = sample.sampleDuration ?? fragment.header.defaultSampleDuration ?? 0;
                            const size = sample.sampleSize ?? fragment.header.defaultSampleSize ?? 0;
                            if (dur === 0) {
                                throw new Error("Missing sampleDuration and no defaultSampleDuration in track fragment header");
                            }
                            if (size === 0) {
                                throw new Error("Missing sampleSize and no defaultSampleSize in track fragment header");
                            }
                            totalTimeUnits += dur;
                            audioTrack.sizeInBytes += size;
                        }
                    }
                    if (!audioTrack.samples) {
                        audioTrack.samples = totalTimeUnits;
                    }
                    if (!audioTrack.duration) {
                        audioTrack.duration = totalTimeUnits / audioTrack.sampleRate;
                    }
                }
                else if (audioTrack.sampleSizeTable.length > 0) {
                    audioTrack.sizeInBytes = audioTrack.sampleSizeTable.reduce((sum, n) => sum + n, 0);
                }
            }
            const ssd = audioTrack.soundSampleDescription[0];
            if (ssd.description && audioTrack.media.header) {
                this.metadata.setFormat('sampleRate', ssd.description.sampleRate);
                this.metadata.setFormat('bitsPerSample', ssd.description.sampleSize);
                this.metadata.setFormat('numberOfChannels', ssd.description.numAudioChannels);
                if (audioTrack.media.header.timeScale === 0 && audioTrack.timeToSampleTable.length > 0) {
                    const totalSampleSize = audioTrack.timeToSampleTable
                        .map(ttstEntry => ttstEntry.count * ttstEntry.duration)
                        .reduce((total, sampleSize) => total + sampleSize);
                    audioTrack.duration = totalSampleSize / ssd.description.sampleRate;
                }
            }
            const encoderInfo = encoderDict[ssd.dataFormat];
            if (encoderInfo) {
                this.metadata.setFormat('lossless', !encoderInfo.lossy);
            }
        }
        if (audioTracks.length >= 1) {
            const firstAudioTrack = audioTracks[0];
            if (firstAudioTrack.duration) {
                this.metadata.setFormat('duration', firstAudioTrack.duration);
                if (firstAudioTrack.sizeInBytes) {
                    this.metadata.setFormat('bitrate', 8 * firstAudioTrack.sizeInBytes / firstAudioTrack.duration);
                }
            }
        }
        this.metadata.setFormat('hasAudio', this.hasAudioTrack);
        this.metadata.setFormat('hasVideo', this.hasVideoTrack);
    }
    async handleAtom(atom, remaining) {
        if (atom.parent) {
            switch (atom.parent.header.name) {
                case 'ilst':
                case '<id>':
                    return this.parseMetadataItemData(atom);
                case 'moov':
                    switch (atom.header.name) {
                        case 'trak':
                            return this.parseTrackBox(atom);
                        case 'udta':
                            return this.parseTrackBox(atom);
                    }
                    break;
                case 'moof':
                    switch (atom.header.name) {
                        case 'traf':
                            return this.parseTrackFragmentBox(atom);
                    }
            }
        }
        // const payloadLength = atom.getPayloadLength(remaining);
        if (this.atomParsers[atom.header.name]) {
            return this.atomParsers[atom.header.name](remaining);
        }
        MP4Parser_debug(`No parser for atom path=${atom.atomPath}, payload-len=${remaining}, ignoring atom`);
        await this.tokenizer.ignore(remaining);
    }
    getTrackDescription() {
        // ToDo: pick the right track, not the last track!!!!
        const tracks = [...this.tracks.values()];
        return tracks[tracks.length - 1];
    }
    async addTag(id, value) {
        await this.metadata.addTag(tagFormat, id, value);
    }
    addWarning(message) {
        MP4Parser_debug(`Warning: ${message}`);
        this.metadata.addWarning(message);
    }
    /**
     * Parse data of Meta-item-list-atom (item of 'ilst' atom)
     * @param metaAtom
     * Ref: https://developer.apple.com/library/content/documentation/QuickTime/QTFF/Metadata/Metadata.html#//apple_ref/doc/uid/TP40000939-CH1-SW8
     */
    parseMetadataItemData(metaAtom) {
        let tagKey = metaAtom.header.name;
        return metaAtom.readAtoms(this.tokenizer, async (child, remaining) => {
            const payLoadLength = child.getPayloadLength(remaining);
            switch (child.header.name) {
                case 'data': // value atom
                    return this.parseValueAtom(tagKey, child);
                case 'name': // name atom (optional)
                case 'mean':
                case 'rate': {
                    const name = await this.tokenizer.readToken(new NameAtom(payLoadLength));
                    tagKey += `:${name.name}`;
                    break;
                }
                default: {
                    const uint8Array = await this.tokenizer.readToken(new lib.Uint8ArrayType(payLoadLength));
                    this.addWarning(`Unsupported meta-item: ${tagKey}[${child.header.name}] => value=${(0,uint8array_extras/* uint8ArrayToHex */.EY)(uint8Array)} ascii=${(0,text_codec_lib/* textDecode */.c)(uint8Array, 'ascii')}`);
                }
            }
        }, metaAtom.getPayloadLength(0));
    }
    async parseValueAtom(tagKey, metaAtom) {
        const dataAtom = await this.tokenizer.readToken(new DataAtom(Number(metaAtom.header.length) - Header.len));
        if (dataAtom.type.set !== 0) {
            throw new Mp4ContentError(`Unsupported type-set != 0: ${dataAtom.type.set}`);
        }
        // Use well-known-type table
        // Ref: https://developer.apple.com/library/content/documentation/QuickTime/QTFF/Metadata/Metadata.html#//apple_ref/doc/uid/TP40000939-CH1-SW35
        switch (dataAtom.type.type) {
            case 0: // reserved: Reserved for use where no type needs to be indicated
                switch (tagKey) {
                    case 'trkn':
                    case 'disk': {
                        const num = lib.UINT8.get(dataAtom.value, 3);
                        const of = lib.UINT8.get(dataAtom.value, 5);
                        // console.log("  %s[data] = %s/%s", tagKey, num, of);
                        await this.addTag(tagKey, `${num}/${of}`);
                        break;
                    }
                    case 'gnre': {
                        const genreInt = lib.UINT8.get(dataAtom.value, 1);
                        const genreStr = ID3v1Parser/* Genres */.jR[genreInt - 1];
                        // console.log("  %s[data] = %s", tagKey, genreStr);
                        await this.addTag(tagKey, genreStr);
                        break;
                    }
                    case 'rate': {
                        const rate = (0,text_codec_lib/* textDecode */.c)(dataAtom.value, 'ascii');
                        await this.addTag(tagKey, rate);
                        break;
                    }
                    default:
                        MP4Parser_debug(`unknown proprietary value type for: ${metaAtom.atomPath}`);
                }
                break;
            case 1: // UTF-8: Without any count or NULL terminator
            case 18: // Unknown: Found in m4b in combination with a '©gen' tag
                await this.addTag(tagKey, (0,text_codec_lib/* textDecode */.c)(dataAtom.value));
                break;
            case 13: // JPEG
                if (this.options.skipCovers)
                    break;
                await this.addTag(tagKey, {
                    format: 'image/jpeg',
                    data: Uint8Array.from(dataAtom.value)
                });
                break;
            case 14: // PNG
                if (this.options.skipCovers)
                    break;
                await this.addTag(tagKey, {
                    format: 'image/png',
                    data: Uint8Array.from(dataAtom.value)
                });
                break;
            case 21: // BE Signed Integer
                await this.addTag(tagKey, MP4Parser.read_BE_Integer(dataAtom.value, true));
                break;
            case 22: // BE Unsigned Integer
                await this.addTag(tagKey, MP4Parser.read_BE_Integer(dataAtom.value, false));
                break;
            case 65: // An 8-bit signed integer
                await this.addTag(tagKey, lib.UINT8.get(dataAtom.value, 0));
                break;
            case 66: // A big-endian 16-bit signed integer
                await this.addTag(tagKey, lib.UINT16_BE.get(dataAtom.value, 0));
                break;
            case 67: // A big-endian 32-bit signed integer
                await this.addTag(tagKey, lib.UINT32_BE.get(dataAtom.value, 0));
                break;
            default:
                this.addWarning(`atom key=${tagKey}, has unknown well-known-type (data-type): ${dataAtom.type.type}`);
        }
    }
    async parseTrackBox(trakBox) {
        // @ts-expect-error
        const track = {
            media: {},
            fragments: []
        };
        await trakBox.readAtoms(this.tokenizer, async (child, remaining) => {
            const payLoadLength = child.getPayloadLength(remaining);
            switch (child.header.name) {
                case 'chap': {
                    const chap = await this.tokenizer.readToken(new ChapterTrackReferenceBox(remaining));
                    track.chapterList = chap;
                    break;
                }
                case 'tkhd': // TrackHeaderBox
                    track.header = await this.tokenizer.readToken(new TrackHeaderAtom(payLoadLength));
                    break;
                case 'hdlr': // TrackHeaderBox
                    track.handler = await this.tokenizer.readToken(new HandlerBox(payLoadLength));
                    track.isAudio = () => track.handler.handlerType === 'audi' || track.handler.handlerType === 'soun';
                    track.isVideo = () => track.handler.handlerType === 'vide';
                    if (track.isAudio()) {
                        this.hasAudioTrack = true;
                    }
                    else if (track.isVideo()) {
                        this.hasVideoTrack = true;
                    }
                    break;
                case 'mdhd': { // Parse media header (mdhd) box
                    const mdhd_data = await this.tokenizer.readToken(new MdhdAtom(payLoadLength));
                    track.media.header = mdhd_data;
                    break;
                }
                case 'stco': {
                    const stco = await this.tokenizer.readToken(new StcoAtom(payLoadLength));
                    track.chunkOffsetTable = stco.entries; // remember chunk offsets
                    break;
                }
                case 'stsc': { // sample-to-Chunk box
                    const stsc = await this.tokenizer.readToken(new StscAtom(payLoadLength));
                    track.sampleToChunkTable = stsc.entries;
                    break;
                }
                case 'stsd': { // sample description box
                    const stsd = await this.tokenizer.readToken(new StsdAtom(payLoadLength));
                    track.soundSampleDescription = stsd.table.map(dfEntry => this.parseSoundSampleDescription(dfEntry));
                    break;
                }
                case 'stts': { // time-to-sample table
                    const stts = await this.tokenizer.readToken(new SttsAtom(payLoadLength));
                    track.timeToSampleTable = stts.entries;
                    break;
                }
                case 'stsz': {
                    const stsz = await this.tokenizer.readToken(new StszAtom(payLoadLength));
                    track.sampleSize = stsz.sampleSize;
                    track.sampleSizeTable = stsz.entries;
                    break;
                }
                case 'dinf':
                case 'vmhd':
                case 'smhd':
                    MP4Parser_debug(`Ignoring: ${child.header.name}`);
                    await this.tokenizer.ignore(payLoadLength);
                    break;
                default: {
                    MP4Parser_debug(`Unexpected track box: ${child.header.name}`);
                    await this.tokenizer.ignore(payLoadLength);
                }
            }
        }, trakBox.getPayloadLength(0));
        // Register track
        this.tracks.set(track.header.trackId, track);
    }
    parseTrackFragmentBox(trafBox) {
        let tfhd;
        return trafBox.readAtoms(this.tokenizer, async (child, remaining) => {
            const payLoadLength = child.getPayloadLength(remaining);
            switch (child.header.name) {
                case 'tfhd': { // TrackFragmentHeaderBox
                    const fragmentHeaderBox = new TrackFragmentHeaderBox(child.getPayloadLength(remaining));
                    tfhd = await this.tokenizer.readToken(fragmentHeaderBox);
                    break;
                }
                case 'tfdt': // TrackFragmentBaseMediaDecodeTimeBo
                    await this.tokenizer.ignore(payLoadLength);
                    break;
                case 'trun': { // TrackRunBox
                    const trackRunBox = new TrackRunBox(payLoadLength);
                    const trun = await this.tokenizer.readToken(trackRunBox);
                    if (tfhd) {
                        const track = this.tracks.get(tfhd.trackId);
                        track?.fragments.push({ header: tfhd, trackRun: trun });
                    }
                    break;
                }
                default: {
                    MP4Parser_debug(`Unexpected box: ${child.header.name}`);
                    await this.tokenizer.ignore(payLoadLength);
                }
            }
        }, trafBox.getPayloadLength(0));
    }
    /**
     * @param sampleDescription
     * Ref: https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap3/qtff3.html#//apple_ref/doc/uid/TP40000939-CH205-128916
     */
    parseSoundSampleDescription(sampleDescription) {
        const ssd = {
            dataFormat: sampleDescription.dataFormat,
            dataReferenceIndex: sampleDescription.dataReferenceIndex
        };
        let offset = 0;
        if (sampleDescription.description) {
            const version = SoundSampleDescriptionVersion.get(sampleDescription.description, offset);
            offset += SoundSampleDescriptionVersion.len;
            if (version.version === 0 || version.version === 1) {
                // Sound Sample Description (Version 0)
                ssd.description = SoundSampleDescriptionV0.get(sampleDescription.description, offset);
            }
            else {
                MP4Parser_debug(`Warning: sound-sample-description ${version} not implemented`);
            }
        }
        return ssd;
    }
    async parseChapterTrack(chapterTrack, track, len) {
        if (!chapterTrack.sampleSize) {
            if (chapterTrack.chunkOffsetTable.length !== chapterTrack.sampleSizeTable.length)
                throw new Error('Expected equal chunk-offset-table & sample-size-table length.');
        }
        const chapters = [];
        for (let i = 0; i < chapterTrack.chunkOffsetTable.length && len > 0; ++i) {
            const start = chapterTrack.timeToSampleTable
                .slice(0, i)
                .reduce((acc, cur) => acc + cur.duration, 0);
            const chunkOffset = chapterTrack.chunkOffsetTable[i];
            const nextChunkLen = chunkOffset - this.tokenizer.position;
            const sampleSize = chapterTrack.sampleSize > 0 ? chapterTrack.sampleSize : chapterTrack.sampleSizeTable[i];
            len -= nextChunkLen + sampleSize;
            if (len < 0)
                throw new Mp4ContentError('Chapter chunk exceeding token length');
            await this.tokenizer.ignore(nextChunkLen);
            const title = await this.tokenizer.readToken(new ChapterText(sampleSize));
            MP4Parser_debug(`Chapter ${i + 1}: ${title}`);
            const chapter = {
                title,
                timeScale: chapterTrack.media.header ? chapterTrack.media.header.timeScale : 0,
                start,
                sampleOffset: this.findSampleOffset(track, this.tokenizer.position)
            };
            MP4Parser_debug(`Chapter title=${chapter.title}, offset=${chapter.sampleOffset}/${track.header.duration}`); // ToDo, use media duration if required!!!
            chapters.push(chapter);
        }
        this.metadata.setFormat('chapters', chapters);
        await this.tokenizer.ignore(len);
    }
    findSampleOffset(track, chapterOffset) {
        let chunkIndex = 0;
        while (chunkIndex < track.chunkOffsetTable.length && track.chunkOffsetTable[chunkIndex] < chapterOffset) {
            ++chunkIndex;
        }
        return this.getChunkDuration(chunkIndex + 1, track);
    }
    getChunkDuration(chunkId, track) {
        let ttsi = 0;
        let ttsc = track.timeToSampleTable[ttsi].count;
        let ttsd = track.timeToSampleTable[ttsi].duration;
        let curChunkId = 1;
        let samplesPerChunk = this.getSamplesPerChunk(curChunkId, track.sampleToChunkTable);
        let totalDuration = 0;
        while (curChunkId < chunkId) {
            const nrOfSamples = Math.min(ttsc, samplesPerChunk);
            totalDuration += nrOfSamples * ttsd;
            ttsc -= nrOfSamples;
            samplesPerChunk -= nrOfSamples;
            if (samplesPerChunk === 0) {
                ++curChunkId;
                samplesPerChunk = this.getSamplesPerChunk(curChunkId, track.sampleToChunkTable);
            }
            else {
                ++ttsi;
                ttsc = track.timeToSampleTable[ttsi].count;
                ttsd = track.timeToSampleTable[ttsi].duration;
            }
        }
        return totalDuration;
    }
    getSamplesPerChunk(chunkId, stcTable) {
        for (let i = 0; i < stcTable.length - 1; ++i) {
            if (chunkId >= stcTable[i].firstChunk && chunkId < stcTable[i + 1].firstChunk) {
                return stcTable[i].samplesPerChunk;
            }
        }
        return stcTable[stcTable.length - 1].samplesPerChunk;
    }
}


/***/ })

};
