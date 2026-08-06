/**
 * specMap.js
 * Local helper for building the product specs list.
 * - Receives PBE + PIM (UI API shape) and returns a render-ready array.
 * - Keeps labels/units here; later you can switch labels to your i18n system.
 */

import { convertFromTo } from 'c/libUnitConversions';
//import { publish } from 'lightning/messageService';
//import PAGE_CHANNEL from '@salesforce/messageChannel/B2BRelatedProducts__c'

/** Mapa de especificaciones (ajusta los `path` a tus campos reales) */
export const SPEC_MAP_TILES = {
  color:           { icon: 'utility:palette',           label: 'Color',           src: 'pim',       path: 'Color__c_DisplayValue' },
  texture:         { icon: 'utility:touch_action',      label: 'Texture',         src: 'pim',       path: 'Relief__c' }, // boolean/text
  slipResistance:  { icon: 'utility:transport_walking', label: 'Slip Resistance', src: 'pim',       path: 'SlipResistance__c_DisplayValue' },
  height:          { icon: 'utility:height',            label: 'Height',          src: 'pim',       path: 'Length__c', impPath: 'USLength__c', type: 'length', unit: 'cm' },
  width:           { icon: 'utility:width',             label: 'Width',           src: 'pim',       path: 'Width__c', impPath: 'USWidth__c', type: 'length', unit: 'cm'  },
  thickness:       { icon: 'utility:dash',              label: 'Thickness',       src: 'pim',       path: 'Thickness__c', impPath: 'USThickness__c', type: 'length', unit: 'mm' },
  piecesPerBox:    { icon: 'utility:rows',              label: 'Pieces/Box',      src: 'product',   path: 'PcsXBox__c' },      
  sqFtPerUMV:      { icon: 'utility:expand',            label: 'Surface/{{UMV}}',   src: 'product',   path: 'M2XBox__c', type: 'surface' },     
  weightPerUMV:    { icon: 'utility:fulfillment_order', label: 'Weight/{{UMV}}',  src: 'product',   path: 'PesoUMV__c', type: 'weight' }     
};

export const SPEC_MAP_OTHERS = {
  color:           { icon: 'utility:palette',           label: 'Color',           src: 'pim',       path: 'Color__c_DisplayValue' },
  texture:         { icon: 'utility:touch_action',      label: 'Texture',         src: 'pim',       path: 'Relief__c' }, // boolean/text
  weightPerUMV:    { icon: 'utility:fulfillment_order', label: 'Weight/{{UMV}}',  src: 'product',   path: 'PesoUMV__c', type: 'weight' }     
};


const readField = (obj, key) => {
    if (!obj || !key) return undefined;
    return obj[key];
};

const normalizeField = v => (typeof v === 'boolean' ? (v ? 'Yes' : 'No') : v);

/**
 * Build spec list from product & pim data
 * @param {Object} product   // datos de producto (p.ej. PBE)
 * @param {Object} pim       // datos de PIMProduct
 * @param {string} umv       // unidad de venta (UMV)
 * @param {string} umvAbbr   // abreviatura de unidad de venta (UMV)
 * @returns {Array<{id:string, icon:string, label:string, value:any}>}
 */
export function buildSpecList(product, pim, umv, umvAbbr, unitSystem = 'imp') {
    const LB_PER_KG = 2.20462;  
    const SQFT_PER_M2 = 10.7639;
    const result = [];

    const prettyUmv = umvAbbr.charAt(0).toUpperCase() + umvAbbr.slice(1).toLowerCase();
    const SPEC_MAP = (product?.IsTile__c ? SPEC_MAP_TILES : SPEC_MAP_OTHERS);
    for (const [id, meta] of Object.entries(SPEC_MAP)) {
        // elegir fuente
        const source = meta.src === 'pim' ? pim : product;
        if (!source) continue;

        // Leer valores según impPath/intPath/path
        let raw    = meta.path    ? readField(source, meta.path)    : undefined;
        let impRaw = meta.impPath ? readField(source, meta.impPath) : undefined;         
        let type   = meta.type?.toLowerCase();
        let unit = meta.unit?.toLowerCase();

        // Procesa según el tipo
        if (type === 'length') {
            if (unit === 'cm') {
                raw = raw / 10;
            }
            raw += ' ' + unit;
        } else if (type === 'surface') {
            if (product.M2XBox__c === null && product.M2XBox__c === 0) continue;           
            if (umv === 'PZS') {
                raw = raw / product.PcsXBox__c;     // M2 por pieza
            }
            raw += ' m2';
            impRaw = (parseFloat(raw) * SQFT_PER_M2).toFixed(2);
            impRaw += ' sq ft';
        } else if (type === 'weight') {
             // Convertir de Product2.UMV a UMV
            let factor = convertFromTo(product, umv, product.Umv__c);
            raw = factor * raw;
            raw += ' kg';
            impRaw = (parseFloat(raw) * LB_PER_KG).toFixed(2) + ' lb';
        } else {
            raw = normalizeField(raw);
            if (raw === undefined || raw === null || raw === '') {
                raw = '--';
            }
            impRaw = raw;
        }
        // Construir item
        const item = {
            id,
            icon: meta.icon,
            label: (meta.label || '').replace('{{UMV}}', prettyUmv ?? umv),            
            intValue: raw,
            impValue: impRaw,
            displayValue: (unitSystem === 'int' ? raw : impRaw)
        };

        result.push(item);
    }    
    return result;
}

/**
 * Sends the list of related prodycts to the page channel
 *
export function publishRelatedProducts(messageContext, pim) {
    const items = [
      { sku: 'CAPRI STONE 45X120(A)', relType: 'COMPLEMENTARY' },
      { sku: 'PEGAMENTO-EXT-25KG',     relType: 'INSTALLATION'  },
      { sku: 'JUNTA-PERLA-2KG',        relType: 'GROUT'         }
    ];
    publish(messageContext, PAGE_CHANNEL, { items });
}
    */