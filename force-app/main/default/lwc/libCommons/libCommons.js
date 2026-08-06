/**
 * libCommons.js
 * Ramón
 * Enero 20205
 * ---
 * Módulo con funciones JS de utilidad general.
 * NO AÑADIR FUCNIONES QUE NO TENGAN ESE CARÁCTER GLOPBAL DE APLICACIÓN
 * ---
 * Utilización:
 * - Importar este archivo en el componente que lo necesite.
 *   import * as LibCommons from 'c/libCommons';
 * 
 * - Invocar las funciones con el prefijo LibCommons:
 *   const empty = LibCommons.isEmpty(value);
 * 
 * 
 */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import dict_error from "@salesforce/label/c.dict_error";
import dict_warning from "@salesforce/label/c.dict_warning";

const LABELS = {
    dict_error, dict_warning
};


/**
 * True if the value is null or undefinedd
 */
export function isEmpty(value) {
    return (value === null || value === undefined);
}

/**
 * True if the value is null or undefined or blank
 */
export function isBlank(value) {
    return (value === null || value === undefined || value.trim() === '');
}

/**
 * Displays an error toast message using the Lightning Web Component (LWC) ShowToastEvent.
 * This toast notifies the user of an error and can be configured to remain visible until dismissed.
 *
 * @param {string} errorMessage - The error message to display in the toast notification.
 * @param {boolean} [sticky=false] - Whether the toast should be sticky (true) or auto-dismissed (false).
 *
 * @example
 * // Show a non-sticky error toast
 * showErrorToast('An unexpected error occurred.');
 *
 * @example
 * // Show a sticky error toast
 * showErrorToast('Critical error occurred!', true);
 */
export function showErrorToast(errorMessage, sticky = false) {
    dispatchEvent(
        new ShowToastEvent({
            title: LABELS.dict_error || 'Error',
            variant: 'error',
            mode: sticky ? 'sticky' : '',
            message: errorMessage,
    }));
}

/**
 * Displays a warning toast message using the Lightning Web Component (LWC) ShowToastEvent.
 * This toast notifies the user of an issue and can be configured to remain visible until dismissed.
 *
 * @param {string} message - The error message to display in the toast notification.
 * @param {boolean} [sticky=false] - Whether the toast should be sticky (true) or auto-dismissed (false).
 *
 * @example
 * // Show a non-sticky error toast
 * showErrorToast('An unexpected error occurred.');
 *
 * @example
 * // Show a sticky error toast
 * showErrorToast('Critical error occurred!', true);
 */
export function showWarningToast(message, sticky = false) {
    dispatchEvent(
        new ShowToastEvent({
            title: LABELS.dict_warning || 'Warning',
            variant: 'warning',
            mode: sticky ? 'sticky' : '',
            message: message,
    }));
}


/**
 * True if the value is null or undefined or blank
 */
export function getSandboxName() {
    let name = null;
    const hostname = window.location.hostname;
     if (hostname.includes('--')) {;    
        const parts = hostname.split('--')[1].split('.');
        name = parts[0]; // Get the first part after the `--`
     }
     return name;
}

/**
 * Extracts a list of error messages form an error object.
 */
export function parseErrors(error) {
    
    let errors = [];
    
    if  (error === null || error === undefined) {
        return errors;
    }

    if (typeof error === 'string') {
        errors.push(error);
        return errors;
    }

    const isArray = Array.isArray(error) &&  error.every(item => typeof item === "string");
    if (isArray) {
        return error;
    }

    if (Object.hasOwn(error, 'body') && Object.hasOwn(error.body, 'pageErrors')) {
        for (const pageError of error.body.pageErrors) {
            errors.push(pageError.message);
        }
    }

    if (Object.hasOwn(error, 'message')) {
        errors.push(error.message);
    }
    
    return errors;
}