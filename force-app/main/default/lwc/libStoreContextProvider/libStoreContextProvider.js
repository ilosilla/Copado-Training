/**
 * ─────────────────────────────────────────────────────────────────────────────
 *  storeContextProvider
 * ─────────────────────────────────────────────────────────────────────────────
 *  PURPOSE
 *  -------
 *  Headless LWC that loads the B2B store context for the current user session
 *  and delivers it to the parent component via a custom event.
 *
 *  The context contains account-level and store-level settings that drive
 *  market-specific behaviour: currency, payment methods, surcharges, etc.
 *  It is cached server-side in Platform Session Cache to avoid repeated SOQL
 *  on every page load.
 *
 *  USAGE
 *  -----
 *  1. Add the component to your LWC template:
 *
 *       <c-lib-store-context-provider
 *           oncontextreceived={handleContext}
 *           oncontexterror={handleContextError}>
 *       </c-lib-store-context-provider>
 *
 *  2. Handle the event in your JS:
 *
 *       handleContext(event) {
 *           this.st_storeContext = event.detail;
 *           // context.currencyIsoCode, context.isCreditCardAllowed, etc.
 *       }
 *
 *       handleContextError(event) {
 *           console.error('Context error', event.detail.message);
 *       }
 *
 *  EVENTS
 *  ------
 *  contextreceived  — fires with the B2BContext object in event.detail
 *  contexterror     — fires with { message } if the context cannot be loaded
 *
 *  UTILITIES
 *  ---------
 *  getFlagEmoji(countryCode)  — converts a 2-letter ISO country code to its
 *                               flag emoji. E.g. 'US' → 🇺🇸, 'IE' → 🇮🇪.
 *                               Works with any ISO 3166-1 alpha-2 code.
 *
 *  @author  Ramón Prades
 *  @since   2026
 * ─────────────────────────────────────────────────────────────────────────────
 */

import { LightningElement } from 'lwc';
import { getSessionContext } from 'commerce/contextApi';
import getContext from '@salesforce/apex/B2BContextProvider.getContext';
import Logger from 'c/libLogger';

/**
 * Converts a 2-letter ISO country code to its flag emoji.
 * @param {string} countryCode — e.g. 'US', 'IE', 'AE'
 * @returns {string} flag emoji or empty string if invalid
 */
export function getFlagEmoji(countryCode) {
    if (!countryCode || countryCode.length !== 2) return '';
    return countryCode.toUpperCase()
        .replace(/./g, c => String.fromCodePoint(127397 + c.charCodeAt(0)));
}

export default class LibStoreContextProvider extends LightningElement {

    logger = new Logger('LibStoreContextProvider');

    async connectedCallback() {
        try {
            this.logger.highlight('connectedCallback');

            const session = await getSessionContext();
            this.logger.debug('Session context', session, { json: true, pretty: true });

            const accountId    = session?.effectiveAccountId;
            const buyerGroupId = session?.buyerGroups?.[0]?.id;

            this.logger.info('Resolved accountId', accountId);
            this.logger.debug('Session buyerGroups', session?.buyerGroups, { json: true, pretty: true });
            this.logger.info('Resolved buyerGroupId', buyerGroupId);

            if (!accountId) {
                this._failContext('CONTEXT_ERROR:ACC');
                return;
            }

            this.logger.debug('Calling B2BContextProvider.getContext', {
                accountId,
                buyerGroupId
            }, { json: true, pretty: true });

            const context = await getContext({ accountId, buyerGroupId });
            this.logger.debug('Raw context from Apex', context, { json: true, pretty: true });

            if (this._syncLanguageCookie(context.userLanguage)) return; // redirect in progress
            const flag = context?.market?.countryCode ? getFlagEmoji(context.market.countryCode) : '';
            const enrichedContext = {
                ...context,
                marketDisplayLabel: flag ? `${flag} ${context.market?.label}` : (context.market?.label || ''),
                userLocale: (context.userLocale || 'en-US').replace('_', '-')   // es_ES → es-ES, listo para Intl
            };
            this.logger.debug('Enriched context', enrichedContext, { json: true, pretty: true });
            this.dispatchEvent(new CustomEvent('contextreceived', { detail: enrichedContext, bubbles: false }));

        } catch (error) {
            const raw  = error?.body?.message || error?.message || '';
            // Los errores de contexto de Apex ya vienen como CONTEXT_ERROR:XXX.
            // Cualquier otro fallo inesperado se marca como :UNK.
            const code = raw.startsWith('CONTEXT_ERROR') ? raw : 'CONTEXT_ERROR:UNK';
            this._failContext(code);
        }
    }

    /**
     * El contexto es imprescindible: de él dependen stock, métodos de pago y
     * recargos. Si no se puede cargar, no se puede operar → se redirige a la
     * página de error. Se mantiene el evento contexterror por compatibilidad y
     * para posible logging del consumidor.
     */
    _failContext(code) {
        this.logger.error('Error loading B2B context', code);
        this.dispatchEvent(new CustomEvent('contexterror', { detail: { message: code }, bubbles: false }));
        this._redirectToError(code);
    }

    /**
     * Redirige a la página de error del site conservando el prefijo de idioma si
     * lo hay. Usa window.location.replace (sin entrada en el historial) igual que
     * _syncLanguageCookie. Guard anti-bucle: si ya estamos en /error no redirige
     * (el provider también se monta en el footer, que aparece en la propia página
     * de error).
     */
    _redirectToError(code) {
        const segments = window.location.pathname.split('/').filter(Boolean); // ['b2bportal', 'en-US'?, ...]
        if (segments[segments.length - 1] === 'error') return; // ya estamos en la página de error

        const base = segments[0] ? `/${segments[0]}` : '';
        const lang = /^[a-z]{2}-[A-Z]{2}$/.test(segments[1] || '') ? `/${segments[1]}` : '';
        window.location.replace(`${base}${lang}/error?code=${encodeURIComponent(code)}`);
    }

    /**
     * Detects language changes between sessions using a lastLanguage cookie.
     * If the logged-in user's language differs from the last recorded one,
     * updates the cookie and redirects to the correct language-prefixed URL.
     * LWR reads the URL prefix server-side, so the redirect guarantees correct rendering.
     * Returns true if a redirect was triggered (caller should stop processing).
     */
    _syncLanguageCookie(userLanguage) {
        if (!userLanguage) return false;

        const match        = document.cookie.match(/(?:^|;\s*)lastLanguage=([^;]+)/);
        const lastLanguage = match ? match[1] : null;

        if (lastLanguage === userLanguage) return false; // same language as last session

        // Persist the new language for future comparisons
        document.cookie = `lastLanguage=${userLanguage}; path=/; max-age=31536000`;

        if (lastLanguage === null) return false; // first visit — just record the language, no redirect needed

        // Build redirect URL with the correct language prefix
        const urlLang = userLanguage.replace('_', '-');      // en_GB → en-GB
        const parts   = window.location.pathname.split('/'); // ['', 'b2bportal', ...]
        if (/^[a-z]{2}-[A-Z]{2}$/.test(parts[2])) {
            parts[2] = urlLang;                              // replace existing prefix
        } else {
            parts.splice(2, 0, urlLang);                     // insert prefix after base path
        }
        console.log('Hacemos la redirección a la URL con el idioma correcto:', parts.join('/') + window.location.search);
        window.location.replace(parts.join('/') + window.location.search);
        return true;
    }
}