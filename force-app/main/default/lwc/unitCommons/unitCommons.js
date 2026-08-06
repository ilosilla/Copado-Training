/**
 * unitCommons.js
 * 
 * Ramón, September 2025
 * Common library for handling unit translations in B2B applications.
 *
 * This module provides:
 * - A centralized dictionary of unit codes (UNITS_MAP) with translations in English, Spanish, and French.
 * - Automatic locale detection based on the current Salesforce user language.
 * - A helper method (getUnitLabel) to return the singular, plural, or abbreviation of a unit.
 */

import LANG from '@salesforce/i18n/lang';

/**
 * Centralized dictionary of unit translations.
 * Keys: unit code (e.g., "CJ", "PZS", "KG")
 * Values: object with languages ("en", "es", "fr"), each containing:
 *   - singular: string
 *   - plural: string
 *   - abbr: string
 */
const UNITS_MAP = {
    PZS: {
        en: { singular: "Piece", plural: "Pieces", abbr: "PCS" },
        es: { singular: "Pieza", plural: "Piezas", abbr: "PZS" },
        fr: { singular: "Pièce", plural: "Pièces", abbr: "PCS" }
    },
    PAL: {
        en: { singular: "Pallet", plural: "Pallets", abbr: "PAL" },
        es: { singular: "Palé", plural: "Palés", abbr: "PAL" },
        fr: { singular: "Palette", plural: "Palettes", abbr: "PAL" }
    },
    SAC: {
        en: { singular: "Bag", plural: "Bags", abbr: "BAG" },
        es: { singular: "Saco", plural: "Sacos", abbr: "SAC" },
        fr: { singular: "Sac", plural: "Sacs", abbr: "SAC" }
    },
    MT2: {
        en: { singular: "Square Meter", plural: "Square Meters", abbr: "M2" },
        es: { singular: "Metro cuadrado", plural: "Metros cuadrados", abbr: "M2" },
        fr: { singular: "Mètre carré", plural: "Mètres carrés", abbr: "M2" }
    },
    BID: {
        en: { singular: "Can", plural: "Cans", abbr: "CAN" },
        es: { singular: "Bidón", plural: "Bidones", abbr: "BID" },
        fr: { singular: "Bidon", plural: "Bidons", abbr: "BID" }
    },
    CJ: {
        en: { singular: "Box", plural: "Boxes", abbr: "BOX" },
        es: { singular: "Caja", plural: "Cajas", abbr: "CJ" },
        fr: { singular: "Carton", plural: "Cartons", abbr: "CJ" }
    },
    CM: {
        en: { singular: "Centimeter", plural: "Centimeters", abbr: "CM" },
        es: { singular: "Centímetro", plural: "Centímetros", abbr: "CM" },
        fr: { singular: "Centimètre", plural: "Centimètres", abbr: "CM" }
    },
    DM2: {
        en: { singular: "Square Decimeter", plural: "Square Decimeters", abbr: "DM2" },
        es: { singular: "Decímetro cuadrado", plural: "Decímetros cuadrados", abbr: "DM2" },
        fr: { singular: "Décimètre carré", plural: "Décimètres carrés", abbr: "DM2" }
    },
    KG: {
        en: { singular: "Kilogram", plural: "Kilograms", abbr: "KG" },
        es: { singular: "Kilogramo", plural: "Kilogramos", abbr: "KG" },
        fr: { singular: "Kilogramme", plural: "Kilogrammes", abbr: "KG" }
    },
    L: {
        en: { singular: "Liter", plural: "Liters", abbr: "L" },
        es: { singular: "Litro", plural: "Litros", abbr: "L" },
        fr: { singular: "Litre", plural: "Litres", abbr: "L" }
    },
    M: {
        en: { singular: "Meter", plural: "Meters", abbr: "M" },
        es: { singular: "Metro", plural: "Metros", abbr: "M" },
        fr: { singular: "Mètre", plural: "Mètres", abbr: "M" }
    },
    M2: {
        en: { singular: "Square Meter", plural: "Square Meters", abbr: "M2" },
        es: { singular: "Metro cuadrado", plural: "Metros cuadrados", abbr: "M2" },
        fr: { singular: "Mètre carré", plural: "Mètres carrés", abbr: "M2" }
    },
    ML: {
        en: { singular: "Milliliter", plural: "Milliliters", abbr: "ML" },
        es: { singular: "Mililitro", plural: "Mililitros", abbr: "ML" },
        fr: { singular: "Millilitre", plural: "Millilitres", abbr: "ML" }
    },
    ROL: {
        en: { singular: "Roll", plural: "Rolls", abbr: "ROL" },
        es: { singular: "Rollo", plural: "Rollos", abbr: "ROL" },
        fr: { singular: "Rouleau", plural: "Rouleaux", abbr: "ROL" }
    },
    SQF: {
        en: { singular: "Square Foot", plural: "Square Feet", abbr: "SQF" },
        es: { singular: "Pie cuadrado", plural: "Pies cuadrados", abbr: "SQF" },
        fr: { singular: "Pied carré", plural: "Pieds carrés", abbr: "SQF" }
    },
    UN: {
        en: { singular: "Unit", plural: "Units", abbr: "UN" },
        es: { singular: "Unidad", plural: "Unidades", abbr: "UN" },
        fr: { singular: "Unité", plural: "Unités", abbr: "UN" }
    },
    CM2: {
        en: { singular: "Square Centimeter", plural: "Square Centimeters", abbr: "CM2" },
        es: { singular: "Centímetro cuadrado", plural: "Centímetros cuadrados", abbr: "CM2" },
        fr: { singular: "Centimètre carré", plural: "Centimètres carrés", abbr: "CM2" }
    }
};

/**
 * Detects the current Salesforce user language.
 * Normalizes to "en", "es", or "fr". Defaults to "en".
 * @returns {string} The normalized language code.
 */
function getUserLocale() {
    const raw = (LANG || 'en').toLowerCase().replace('_', '-');
    const base = raw.split('-')[0];
    return ['en', 'es', 'fr'].includes(base) ? base : 'en';
}

/**
 * Returns all labels (singular, plural, abbreviation) for a given unit.
 *
 * @param {string} unitCode - The unit code (e.g., "CJ", "PZS", "KG").
 * @param {string} [locale] - The language code ("en", "es", "fr").
 *                            If not provided, the current user locale is used.
 * @returns {{code: string, singular: string, plural: string, abbr: string}} Labels object.
 */
function getUnitLabels(unitCode, locale) {
    locale = locale.toLowerCase();
    const loc = (locale && ['en', 'es', 'fr'].includes(locale)) ? locale : getUserLocale();
    const unitData = UNITS_MAP[unitCode];
    if (!unitData) {
        return {
            code: unitCode,
            singular: unitCode,
            plural: unitCode,
            abbr: unitCode
        };
    }
    const langData = unitData[loc] || unitData['en'];
    return {
        code: unitCode,
        singular: langData.singular,
        plural: langData.plural,
        abbr: langData.abbr
    };
}

export {
    getUnitLabels,
    getUserLocale,
    UNITS_MAP
};