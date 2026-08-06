// b2bErrorPage.js
import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

// TODO(i18n): los textos están hardcodeados en inglés a propósito. En una
// iteración posterior cada `title`/`description` pasará a un Custom Label
// (import ... from '@salesforce/label/c.B2B_Error_*'); la estructura del mapa
// está pensada para que ese cambio sea un reemplazo directo, sin refactor.
//
// El `code` que llega por URL tiene la forma CLAVE:REF (p. ej. CONTEXT_ERROR:CUR).
// - La parte izquierda (CLAVE) selecciona el mensaje de este mapa.
// - El code completo se muestra como referencia interna para soporte: si nos
//   mandan un pantallazo sabemos exactamente dónde mirar.
const ERROR_CODES = {
    // Error grave: el usuario no puede hacer nada. Mensaje genérico y friendly,
    // sin botón de navegación (dead-end); se le invita a contactar con su comercial.
    CONTEXT_ERROR: {
        title: 'Something went wrong',
        description:
            'An unexpected error occurred and we’re unable to provide the service right now. ' +
            'Please contact your sales representative if you need more information.'
    },
    // Se muestra cuando no llega ningún `code` (URL inexistente / 404) o cuando
    // la clave recibida no está mapeada. Aquí sí se permite volver al inicio.
    DEFAULT: {
        title: 'Page not found',
        description: 'The page you are looking for doesn’t exist or is no longer available.'
    }
};

const DEFAULT_KEY = 'DEFAULT';

export default class B2bErrorPage extends NavigationMixin(LightningElement) {

    st_key = DEFAULT_KEY;
    st_reference = null;

    @wire(CurrentPageReference)
    capturePageRef(pageRef) {
        const raw = pageRef?.state?.code;
        if (!raw) {
            this.st_key = DEFAULT_KEY;
            this.st_reference = null;
            return;
        }

        const colon = raw.indexOf(':');
        const key = colon === -1 ? raw : raw.substring(0, colon);

        this.st_key = ERROR_CODES[key] ? key : DEFAULT_KEY;
        // En el 404 (clave desconocida / sin code) no se muestra referencia.
        // Si la clave es válida, se muestra el code completo (p. ej. CONTEXT_ERROR:CUR).
        this.st_reference = this.st_key === DEFAULT_KEY ? null : raw;
    }

    get content() {
        return ERROR_CODES[this.st_key] ?? ERROR_CODES[DEFAULT_KEY];
    }

    get title() {
        return this.content.title;
    }

    get description() {
        return this.content.description;
    }

    // Solo el 404 ofrece salida; el error grave es un dead-end.
    get showHomeButton() {
        return this.st_key === DEFAULT_KEY;
    }

    get showReference() {
        return !!this.st_reference;
    }

    get reference() {
        return this.st_reference;
    }

    handleGoHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: '/' }
        });
    }
}