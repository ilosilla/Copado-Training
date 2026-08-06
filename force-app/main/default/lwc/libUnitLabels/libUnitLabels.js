/**
 * =========================================================
 * libUnitLabels
 * ---------------------------------------------------------
 * Canonical unit handling for B2B UI.
 *
 * Responsibilities:
 * - Normalize SAP / legacy unit codes
 * - Provide UI-friendly labels (singular / plural)
 * - Define decimal precision rules per unit
 * - Centralize unit semantics for reuse across:
 *   PDP, Cart, Checkout, Orders, Invoices, etc.
 *
 * Design principles:
 * - UI-first (no SAP leakage)
 * - Deterministic (no DB calls)
 * - i18n-ready
 * =========================================================
 */

/* =========================================================
 * 1. NORMALIZATION
 * ========================================================= */

const UNIT_NORMALIZATION = {
    CJ: 'BOX'
};

/* =========================================================
 * 2. UNIT DEFINITIONS (EN)
 * ========================================================= */

const UNIT_DEFINITIONS_EN = {
    BOX: {
        singular: 'Box',
        plural: 'Boxes',
        decimals: 0
    },
    PCS: {
        singular: 'Piece',
        plural: 'Pieces',
        decimals: 0
    },
    UN: {
        singular: 'Unit',
        plural: 'Units',
        decimals: 0
    },
    BAG: {
        singular: 'Bag',
        plural: 'Bags',
        decimals: 0
    },
    PAL: {
        singular: 'Pallet',
        plural: 'Pallets',
        decimals: 0
    },
    KG: {
        singular: 'kg',
        plural: 'kg',
        decimals: 2
    },
    L: {
        singular: 'L',
        plural: 'L',
        decimals: 2
    },
    M2: {
        singular: 'm²',
        plural: 'm²',
        decimals: 2
    },
    MT2: {
        singular: 'm²',
        plural: 'm²',
        decimals: 2
    },
    SQF: {
        singular: 'sq ft',
        plural: 'sq ft',
        decimals: 2
    },
    ROL: {
        singular: 'Roll',
        plural: 'Rolls',
        decimals: 0
    }
};

/* =========================================================
 * 3. HELPERS
 * ========================================================= */

export function normalizeUnit(unitCode) {
    if (!unitCode) {
        return null;
    }
    return UNIT_NORMALIZATION[unitCode] ?? unitCode;
}

function getFallbackUnit(unitCode) {
    return {
        singular: unitCode,
        plural: unitCode,
        decimals: 2
    };
}

/* =========================================================
 * 4. PUBLIC API
 * ========================================================= */

export function getUnitDefinition(unitCode, locale = 'en') {
    const normalized = normalizeUnit(unitCode);

    switch (locale) {
        case 'en':
        default:
            return UNIT_DEFINITIONS_EN[normalized]
                ?? getFallbackUnit(normalized);
    }
}

export function formatQuantity(quantity, unitCode, locale = 'en') {
    if (quantity === null || quantity === undefined) {
        return '';
    }

    const qty = Number(quantity);
    if (Number.isNaN(qty)) {
        return quantity;
    }

    const { decimals } = getUnitDefinition(unitCode, locale);
    return qty.toFixed(decimals);
}

export function getUnitLabel(quantity, unitCode, locale = 'en') {
    const qty = Number(quantity);
    const def = getUnitDefinition(unitCode, locale);

    return qty === 1 ? def.singular : def.plural;
}

export function formatQuantityWithUnit(quantity, unitCode, locale = 'en') {
    const formattedQty = formatQuantity(quantity, unitCode, locale);
    const label = getUnitLabel(quantity, unitCode, locale);

    return `${formattedQty} ${label}`.trim();
}

export function formatPricePerUnit({amount, currencyIsoCode, unitCode, locale = 'en-US'}) {
    if (amount === null || amount === undefined || !unitCode) {
        return '';
    }

    const unitDef = getUnitDefinition(unitCode, locale.startsWith('en') ? 'en' : locale);
    const unitLabel = unitDef?.singular ?? unitCode;

    const formatter = new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: currencyIsoCode ?? 'USD'
    });

    return `${formatter.format(amount)} / ${unitLabel}`;
}