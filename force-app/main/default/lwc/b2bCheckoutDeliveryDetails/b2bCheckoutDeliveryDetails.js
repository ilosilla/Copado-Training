/**
 * b2bCheckoutDeliveryDetails.js
 *
 * API (public):
 *  - @api mode: 'edit' | 'summary'
 *  - @api deliveryOptions: { deliveryDate, deliveryInstructions }
 *  - @api deliveryRequirement:  { ...fields__c }
 *  - @api logisticsContext: {info about preparation times, cut-off, etc)}
 *
 * Events:
 *  - confirmdata: { deliveryOptions, deliveryRequirement }
 *  - changedata:  (no payload) request edit mode
 */
import { LightningElement, api, wire  } from "lwc";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import DELIVERY_REQ_OBJECT from '@salesforce/schema/DeliveryRequirement__c';
const MAX_SUMMARY_LEN = 180;

export default class B2bCheckoutDeliveryDetails extends LightningElement {

    /* =========================================================
    * PUBLIC API
    * ========================================================= */
    @api mode; // 'edit' | 'summary'

    @api
    set deliveryDate(value) {
        console.log('EN EL SETTER DE FECHA TENGO ' + value);
        this.st_deliveryDate = value;
        this.needsValidation = Boolean(this.st_deliveryDate);
    }
    get deliveryDate() {
        return this.st_deliveryDate;
    }

    @api
    set deliveryInstructions(value) {
        this.st_deliveryInstructions = this.normalizeDeliveryInstructions(value);
    }
    get deliveryInstructions() {
        return this.st_deliveryInstructions;
    }


    @api
    set deliveryRequirement(value) {
        this.st_requirement = this.normalizeDeliveryRequirement(value);
    }
    get deliveryRequirement() {
        return this.st_requirement;
    }

    @api 
    set logisticsContext(value) {
        this.st_logisticsContext = this.normalizeLogistics(value);
    }
    get logisticsContext() {
        return this.st_logisticsContext;
    }


    /* =========================================================
     * INTERNAL STATE
     * ========================================================= */
    st_deliveryDate = null;
    st_deliveryInstructions = '';;
    st_requirement = {};
    st_logisticsContext = null;
    st_dateErrorMessage = '';

    ui_isInstructionsExpanded = false;
    
    needsValidation = false;
    siteTypeOptions = [];
    buildingTypeOptions = [];


    /* =========================================================
     * LIFECYCLE HOOKS
     * ========================================================= */

    renderedCallback() {
        // Initial validations        
        if (this.needsValidation) {
            const control = this.template.querySelector('[data-id="deliveryDate"]');
            if (control) {
                this.validateDeliveryDate(control, this.st_deliveryDate);
                this.needsValidation = false;
            }
        }
    }

    /* =========================================================
     * GETTERS
     * ========================================================= */
    get isEditing() {
        return this.mode === "edit";
    }

    get isSummary() {
        return this.mode === "summary";
    }

    get isConfirmDisabled() {
        return !!this.st_dateErrorMessage || !this.st_deliveryDate;
    }  
    
    get deliveryDateSummaryLine() {
        const dateValue = this.st_deliveryDate; // puede ser Date o string tipo '2026-03-18'
        if (!dateValue) return '';
        const date = (dateValue instanceof Date) ? dateValue : new Date(dateValue);
        const formatted = new Intl.DateTimeFormat('en-US', {
            weekday: 'short',
            month: 'short',
            day: '2-digit',
            year: 'numeric',
        }).format(date);
        return `Delivery date — ${formatted}`;
    }

    get deliveryContactSummaryLine() {
        const name = (this.st_requirement.DeliveryContactName__c || '').trim();
        const phone = (this.st_requirement.DeliveryContactPhone__c || '').trim();
        const email = (this.st_requirement.DeliveryContactEmail__c || '').trim();

        const parts = [];
        if (name) parts.push(name);
        if (phone) parts.push(phone);
        if (email) parts.push(email);

        // Si no hay nada, no mostramos la línea
        if (parts.length === 0) return '';

        // "Contact — Name · Phone · Email"
        return `Contact — ${parts.join(' · ')}`;
    }

    get hasLongInstructions() {
        const t = (this.st_deliveryInstructions || '').trim();
        return t.length > MAX_SUMMARY_LEN;
    }

    get instructionsTextToShow() {
        const t = (this.st_deliveryInstructions || '').trim();
        if (!t) return '';
        if (this.ui_isInstructionsExpanded || !this.hasLongInstructions) {
            return t;
        }        
        const cut = t.slice(0, MAX_SUMMARY_LEN);
        const lastSpace = cut.lastIndexOf(' ');
        const safe = lastSpace > 60 ? cut.slice(0, lastSpace) : cut; // evita cortar demasiado pronto
        return `${safe.trim()}…`;
    }

    get instructionsToggleLabel() {
     if (!this.hasLongInstructions) return '';
        return this.ui_isInstructionsExpanded ? ' [Less]' : ' [More]';
    }

    /* =========================================================
     * WIRED DATA
     * ========================================================= */    
    @wire(getObjectInfo, { objectApiName: DELIVERY_REQ_OBJECT }) objectInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: DELIVERY_REQ_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    }) wiredPicklists({ data, error }) {
        if (data) {
            const fields = data.picklistFieldValues;

            this.siteTypeOptions = (fields.SiteType__c?.values || []).map(v => ({
                label: v.label,
                value: v.value
            }));

            this.buildingTypeOptions = (fields.BuildingType__c?.values || []).map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error) {
            // Optional: log or handle error
            console.error('Error loading delivery requirement picklists', error);
        }
    }        

    /* =========================================================
    * EVENT HANDLERS (called from HTML)
    * ========================================================= */

    handleToggleInstructions() {
        this.ui_isInstructionsExpanded = !this.ui_isInstructionsExpanded;
    }

    handleChange() {
        this.dispatchEvent(
        new CustomEvent("changedata", {
            bubbles: true,
            composed: true
        }));
    }

    handleConfirm() {
        const payload = {
            deliveryDate: this.st_deliveryDate,
            deliveryInstructions: this.normalizeDeliveryInstructions(this.st_deliveryInstructions),
            deliveryRequirement: this.normalizeDeliveryRequirement(this.st_requirement)
        };
        this.dispatchEvent(
            new CustomEvent("confirmdata", {
                detail: payload,
                bubbles: true,
                composed: true
            })
        );
    }

    handleDateChange(event) {
        this.st_deliveryDate = (event.target.value || null);
        this.validateDeliveryDate(event.target, this.st_deliveryDate);
    }

    handleInstructionsChange(event) {
        this.st_deliveryInstructions = event.target.value || "";
    }

    /**
     * Generic handler for lightning-input / lightning-combobox with data-field
     */
    handleFieldChange(event) {
        const field = event.target?.dataset?.field;
        if (!field) return;
        this.st_requirement = {
            ...this.st_requirement,
            [field]: event.target.value ?? null
        };
    }

    handleCheckboxChange(event) {
        const field = event.target?.dataset?.field;
        if (!field) return;
        this.st_requirement = {
            ...this.st_requirement,
            [field]: Boolean(event.target.checked)
        };
    }

    /* =========================================================
     * VALIDATIONS & GUARDS
     * ========================================================= */

    validateDeliveryDate(input, value) {  
        this.st_dateErrorMessage = '';
        let errorMessage = null;
        // Required
        if (!value) {
            errorMessage = 'Please select a desired delivery date.';  
        } else {
            const selectedDate = this.parseYYYYMMDDToLocalDate(value);
            if (this.isWeekend(selectedDate)) {
                errorMessage = 'Delivery date must be Monday to Friday.';
            } else {
                const minDeliveryDate = this.computeMinDeliveryDate(this.st_logisticsContext);  
                console.info(`[B2BCheckoutDeliveryDetails] Validating delivery date. Value was ${value} Selected: ${selectedDate}, Min allowed: ${minDeliveryDate.toDateString()}`);       
                if (selectedDate < minDeliveryDate) {                    
                    errorMessage = this.buildMinDeliveryDateError(this.st_logisticsContext, minDeliveryDate);
                }
            }
        }        
        if (errorMessage) {
            this.isDeliveryDateValid = false;
            input.setCustomValidity(' ');
        } else {
            this.isDeliveryDateValid = true;
            input.setCustomValidity('');
        }
        // input.reportValidity();
        this.st_dateErrorMessage = errorMessage;
    }
    /**
     * Called by the container before navigating away from this step.
     * Must return: { valid: boolean, message?: string }
     *
    validate() {
        // Let Lightning inputs show their own errors first
        const inputs = Array.from(
        this.template.querySelectorAll(
            "lightning-input, lightning-combobox, lightning-textarea"
        )
        );

        // Report validity for visible fields
        let allValid = true;
        inputs.forEach((cmp) => {
        // If a subsection is hidden (ship vs pickup), its inputs won't exist in DOM. Good.
        if (typeof cmp.reportValidity === "function") {
            const ok = cmp.reportValidity();
            allValid = allValid && ok;
        } else if (typeof cmp.checkValidity === "function") {
            const ok = cmp.checkValidity();
            allValid = allValid && ok;
        }
        });

        return { valid: allValid };
    }
    */

    /* =========================================================
    * NORMALIZATION HELPERS
    * ========================================================= */
    normalizeDeliveryInstructions(rawInstructions) {
        const instructions = rawInstructions ?? '';
        return this.stripTechnicalMetadata(instructions);
    }

    normalizeDeliveryRequirement(raw) {
        const v = raw || {};
        // Keep as-is, but ensure all checkbox fields are booleans if present
        const boolFields = [
            "LiftgateRequired__c",
            "LoadingDockOnSite__c",
            "InsideDelivery__c",
            "ForkliftAvailableOnSite__c",
            "LimitedAccess__c",
            "AppointmentRequired__c"
        ];

        const out = { ...v };
        boolFields.forEach((f) => {
            if (out[f] !== undefined && out[f] !== null) {
                out[f] = Boolean(out[f]);
            } else {
                out[f] = false;
            }
        });
        return out;
    }

    /**
     * Normalize logistics in case the backend returns null for some fields (e.g. cutoffTime) to avoid issues in the UI layer
     */
    normalizeLogistics(raw) {        
        return {
            preparationDays: raw?.preparationDays ?? 2,
            cutoffMinutes: Number.isInteger(raw?.cutoffMinutes) ? raw.cutoffMinutes : null,
            cutoffTimeLabel: raw?.cutoffTimeLabel ?? null,
            timeZone: raw?.timeZone ?? null
        };
    }

    /* ===================================================
     * UTILITY METHODS
     * =================================================== */
    isWeekend(dateObj) {
        const day = dateObj.getDay(); // 0=Sun, 6=Sat
        return day === 0 || day === 6;
    }

    addBusinessDays(dateObj, days) {
        let d = new Date(dateObj.getTime());
        let added = 0;
        while (added < days) {
            d.setDate(d.getDate() + 1);
            if (!this.isWeekend(d)) {
                added++;
            }
        }
        return d;
    }

    toLocalDateOnly(dateObj) {
        return new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate());
    }

    parseYYYYMMDDToLocalDate(value) {
        const date = new Date(value);
        return new Date(date.getFullYear(), date.getMonth(), date.getDate());       
    }

   /**
    * Builds user-friendly help text for delivery date based on logistics info, e.g. cutoff time and preparation days. 
    * This is used in the delivery details step to inform users about delivery date constraints.
    */
    buildMinDeliveryDateError(logistics, minDate) {
        const days = logistics.preparationDays ?? 2;
        let message = `Orders need ${days} business day${days > 1 ? 's' : ''} to prepare.`;
        if (logistics.cutoffTimeLabel) {
            message += ` Orders placed after ${logistics.cutoffTimeLabel} start counting from the next business day.`;
        }
        message += ` The earliest delivery date is ${this.formatDateLong(minDate)}.`;
        return message;
    }

    formatDateLong(date) {
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            month: 'long',
            day: 'numeric'
        });
    }
    
    /**
     * Computes the minimum allowed delivery date based on logistics constraints.
     *
     * Rules:
     * - preparationDays are business days (Mon–Fri)
     * - if current time is after cutoffTime, add +1 extra business day
     * - no holidays considered (for now)
     *
     */
    computeMinDeliveryDate(logistics = this.st_logisticsContext) {
        const warehouseNow = this.getWarehouseNow(logistics.timeZone);
        const today = this.toLocalDateOnly(warehouseNow);
        let daysToAdd = logistics.preparationDays ?? 2;
        if (Number.isInteger(logistics.cutoffMinutes) && this.isAfterCutoff(logistics.cutoffMinutes, warehouseNow)) {
            daysToAdd += 1;
        }
        return this.addBusinessDays(today, daysToAdd);
    }

    /**
     * Warehouse local time
     */
    getWarehouseNow(timeZone) {
        if (!timeZone) {
            return new Date(); // fallback: browser time
        }
        // Convert "now" to warehouse local time
        return new Date(
            new Date().toLocaleString('en-US', { timeZone })
        );
    }

    /**
     * Check if local time is after cutoff time
     */
    isAfterCutoff(cutoffMinutes, warehouseNow) {
        if (!Number.isInteger(cutoffMinutes)) {
            return false;
        }
        const nowMinutes = warehouseNow.getHours() * 60 + warehouseNow.getMinutes();
        return nowMinutes >= cutoffMinutes;
    }    

    /**
     * Strips technical metadata from a delivery instructions string.
     */
    stripTechnicalMetadata(value) {
        if (!value) {
            return '';
        }

        // Remove #ADDR:XXXXXXXXXXXXXXX (15 or 18 chars)
        return value
            .replace(/\n?#ADDR:[a-zA-Z0-9]{15,18}/g, '')
            .trim();
    }


}