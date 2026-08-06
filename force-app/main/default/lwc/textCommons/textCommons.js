/**
 * textCommons
 * 
 * Ramón, Septiembre 2025
 * Funciones comunes para manipulación de texto.
 *
 * Uso típico:
 * import { capitalizeFirst, capitalizeWords } from 'c/textCommons';
 */


/**
 * Capitaliza solo la primera letra de la cadena.
 *
 * @param {string} str - Texto a capitalizar.
 * @param {Object} [options]
 * @param {boolean} [options.lowerRest=false] - Si true, convierte el resto del string a minúsculas.
 * @returns {string} Cadena con la primera letra en mayúscula.
 *
 * @example
 * capitalizeFirst("hello world");           // "Hello world"
 * capitalizeFirst("hELLO", { lowerRest: true }); // "Hello"
 */
export function capitalizeFirst(str = "", { lowerRest = false } = {}) {
  if (typeof str !== "string") return "";
  const s = str.trim();
  if (!s) return "";
  const rest = lowerRest ? s.slice(1).toLowerCase() : s.slice(1);
  return s.charAt(0).toUpperCase() + rest;
}

/**
 * Capitaliza la primera letra de cada palabra de una cadena.
 *
 * @param {string} str - Texto a procesar.
 * @param {Object} [options]
 * @param {boolean} [options.lowerRest=true] - Si true, convierte el resto de cada palabra a minúsculas.
 * @param {boolean} [options.keepAllCaps=true] - Si true, conserva palabras en MAYÚSCULAS (ej. siglas).
 * @returns {string} Cadena con cada palabra capitalizada.
 *
 * @example
 * capitalizeWords("hello world");                       // "Hello World"
 * capitalizeWords("SKU code XYZ", { keepAllCaps: true }); // "SKU Code XYZ"
 */
export function capitalizeWords(str = "", { lowerRest = true, keepAllCaps = false } = {} ) {
  if (typeof str !== "string") return "";

  const s = str.trim().replace(/\s+/g, " ");
  if (!s) return "";
  
  return s
    .split(" ")
    .map((word) => {
      if (!word) return "";
      if (keepAllCaps && /^[A-Z0-9]{2,}$/.test(word)) return word; // siglas
      const head = word.charAt(0).toUpperCase();
      const tail = lowerRest ? word.slice(1).toLowerCase() : word.slice(1);
      return head + tail;
    })
    .join(" ");
}