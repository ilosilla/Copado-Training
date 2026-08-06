/**
 * libUnitConversion
 * 
 * Ramón, June 2023
 * 
 * Library functions to convert quantities from a unit to another.
 * 
 * Valid units are: PZS, MT2, CJ, UN
 */

export { convertToPieces, convertToUKUnits, convertFromPieces, convertFromTo, isBox, isPiece, isSquareMetre };

const convertToUKUnits = (quantity, unit, pcsxbox, mt2xbox) => {
    let result = {};
    let totPieces = convertToPieces(quantity, unit, pcsxbox, mt2xbox);    
    result.boxes = Math.trunc(totPieces / pcsxbox);
    result.pieces = totPieces % pcsxbox;
    return result;
};

const convertToPieces = (quantity, unit, pcsxbox, mt2xbox) => {
    let result = 0;
    if (isPiece(unit)) {
        result = quantity;
    } else if (isBox(unit)) {
        result = quantity * pcsxbox;
    } else if (isSquareMetre(unit)) {
        result = pcsxbox * quantity / mt2xbox;
        result = Math.ceil(result);
    }
    return result;
};

const convertFromPieces = (numPieces, toUnit, pcsxbox, mt2xbox) => {
    if (isBox(toUnit)) {
        return Math.floor(numPieces/pcsxbox);
    } else if (isPiece(toUnit)) {
        return numPieces;
    } else if (isSquareMetre(toUnit)) {
        return mt2xbox * numPieces/pcsxbox
    }
    return 0;
}

const convertFromTo = (product2, fromUnit, toUnit) => {
    let result = undefined;
    if (fromUnit === toUnit) {
        result = 1;
    }
    if (product2.M2XBox__c !== null && product2.M2XBox__c !== undefined && product2.M2XBox__c > 0) {
        if (isBox(fromUnit)) {
            if (isPiece(toUnit)) result = product2.PcsXBox__c;            
            if (isSquareMetre(toUnit)) result = product2.M2XBox__c;
            if (isBox(toUnit)) result = 1;
        } else if (isSquareMetre(fromUnit)) {
            if (isPiece(toUnit)) result = product2.PcsXBox__c / product2.M2XBox__c;
            if (isBox(toUnit)) result = 1 / product2.M2XBox__c;
            if (isSquareMetre(toUnit)) result = 1; 
        } else if (isPiece(fromUnit)) {
            if (isSquareMetre(toUnit)) result = product2.M2XBox__c / product2.PcsXBox__c;
            if (isBox(toUnit)) result = 1 / product2.PcsXBox__c;
            if (isPiece(toUnit)) result = 1;
        }
    }
    return result
}

const isBox = (unit) => {
    return (unit === 'CJ' || unit === 'BOX');
}

const isPiece = (unit) => {
    return (unit === 'PZS' || unit === 'PCS');
}

const isSquareMetre = (unit) => {
    return (unit === 'MT2' || unit === 'M2');
}