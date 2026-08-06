/**
 * ----------------------------------------------------------------------------------------------------------
 *  LIBRARY NAME: libLogger
 *  DESCRIPTION:
 *      Lightweight logging helper for Lightning Web Components.
 *
 *      Logging is disabled by default. To enable/disable it, open the browser console and use:
 *          porsaLogger.enable()
 *          porsaLogger.disable()
 *          porsaLogger.isEnabled()
 *
 *      WARN and ERROR levels are intentionally not fully wrapped:
 *      the error message is always visible; the detail object only when debug is enabled.
 *      This library is non-visual and intended to be imported by other LWCs.
 * ----------------------------------------------------------------------------------------------------------
 */

const COOKIE_NAME = 'porsa_lwc_debug';

const isDebugEnabled = () => document.cookie.includes(COOKIE_NAME + '=true');

// Expose console helpers on window so they can be called directly from the browser console
window.porsaLogger = {
    enable: () => { 
        const expires = new Date(Date.now() + 24 * 60 * 60 * 1000).toUTCString();
        document.cookie = COOKIE_NAME + '=true; path=/; expires=' + expires; 
        console.info('[libLogger] Debug enabled for 24h — reload to see init logs.'); 
    },
    disable: () => { 
        document.cookie = COOKIE_NAME + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/'; 
        console.info('[libLogger] Debug disabled.'); 
    },
    isEnabled: () => isDebugEnabled()
};

export default class libLogger {

    constructor(componentName) {
        this.componentName = componentName || 'UnknownComponent';
    }

    debug(message, data, options = {}) {
        if (isDebugEnabled()) {
            console.debug(
                this._formatMessage(message),
                this._normalizeData(data, options)
            );
        }
    }

    info(message, data, options = {}) {
        if (isDebugEnabled()) {
            console.info(
                this._formatMessage(message),
                this._normalizeData(data, options)
            );
        }
    }

    highlight(message, data, options = {}) {
        if (isDebugEnabled()) {
            console.info(`\n${'='.repeat(60)}\n  [${this.componentName}] ${message}\n${'='.repeat(60)}`);
            if (data !== undefined) {
                console.info(`[${this.componentName}] `, this._normalizeData(data, options));
            }
        }
    }

    error(message, data) {
        console.error(this._formatMessage(message));
        if (isDebugEnabled()) {
            console.error(this._normalizeData(data, {}));
        }
    }

    /* ============================================================
     * Internal helpers
     * ============================================================
     */

    _formatMessage(message) {
        return `[${this.componentName}] ${message}`;
    }

    _normalizeData(data, options) {
        const { json = false, pretty = false } = options;

        if (data === null) return '<null>';
        if (data === undefined) return '<undefined>';
        if (data instanceof Error) return data;
        if (typeof data !== 'object') return data;

        if (Array.isArray(data) && data.length === 0) return '<empty array>';
        if (!Array.isArray(data) && Object.keys(data).length === 0) return '<empty object>';

        if (json === true) {
            try {
                return pretty === true
                    ? JSON.stringify(data, null, 2)
                    : JSON.stringify(data);
            } catch (e) {
                console.warn(`[${this.componentName}] Failed to stringify log data`, e);
                return data;
            }
        }

        try {
            return JSON.parse(JSON.stringify(data));
        } catch (e) {
            console.warn(`[${this.componentName}] Failed to serialize log data`, e);
            return data;
        }
    }
}