import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CONTACT_POINT_ADDRESS_OBJECT from '@salesforce/schema/ContactPointAddress';
import saveContactPointAddress from '@salesforce/apex/CPAddressFormController.saveContactPointAddress';

export default class B2bCheckoutAddressForm extends LightningElement {

    /* =========================================================
     * PUBLIC API
     * ========================================================= */         
    @api open = false;
    @api mode = 'create';   // 'create' | 'edit'
    @api accountId;
    @api fixCountry;

    @api 
    set address(value) { 
        if (!value || Object.keys(value).length === 0) {
            this.st_address = this.initializeBlankAddress();
        } else {
            this.st_address = { ...value };
            this.ui_isDefaultAlready = value.IsDefault;
        }
        queueMicrotask(() => this.recomputeSaveDisabled());
    }
    get address() {
        return this.st_address;
    }

    /* =========================================================
     * INTERNAL STATE
     * ========================================================= */
    st_address = this.initializeBlankAddress();
    ui_isLoading = true;
    ui_isSaveDisabled = true;
    ui_errorMessage = '';
    ui_isDefaultAlready = false;
    objectInfo;
    picklistData;

    /* =========================================================
     * WIRES
     * ========================================================= */

    @wire(getObjectInfo, { objectApiName: CONTACT_POINT_ADDRESS_OBJECT })
    handleObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValuesByRecordType, {objectApiName: CONTACT_POINT_ADDRESS_OBJECT, recordTypeId: '$objectInfo.defaultRecordTypeId'})
    handlePicklists({ data, error }) {
        if (data) {
            this.picklistData = data;
            this.ui_isLoading = false;
            queueMicrotask(() => this.recomputeSaveDisabled());
        } else if (error) {
            console.error(error);
            this.ui_isLoading = false;
        }
    }

    /* =========================================================
     * GETTERS
     * ========================================================= */
    get countryNotSelected() {
        return !this.st_address?.CountryCode;
    }

    get isCountryDisabled() {
        return !!this.fixCountry;
    }

    get countryOptions() {
        return this.picklistData?.picklistFieldValues?.CountryCode?.values || [];
    }

    get stateOptions() {
        const stateField = this.picklistData?.picklistFieldValues?.StateCode;
        if (!stateField || !this.st_address?.CountryCode) {
            return [];
        }
        const controllerKey = stateField.controllerValues[this.st_address.CountryCode];
        return stateField.values.filter(option =>
            option.validFor.includes(controllerKey)
        );
    }

    get hasErrorMessage() {
        return !!this.ui_errorMessage;
    }

    get countryLabel() {
        const opts = this.countryOptions || [];
        return opts.find(o => o.value === this.st_address?.CountryCode)?.label || '';
    }

    get stateLabel() {
        const opts = this.stateOptions || [];
        return opts.find(o => o.value === this.st_address?.StateCode)?.label || '';
    }

    get panelTitle() {
        if (this.mode === 'edit') {
            return 'Edit address';
        }
        return 'New address';
    }

    /* =========================================================
     * EVENT HANDLERS
     * ========================================================= */
    handleChange(event) {
        this.ui_errorMessage = '';
        const field = event.target?.dataset?.field;
        const value = event.detail?.value ?? event.target?.value;
        if (!field) { return; }        
        this.st_address = { ...this.st_address, [field]: value };
        this.recomputeSaveDisabled();
    }

    handleCountryChange(event) {
        this.ui_errorMessage = '';
        const country = event.detail?.value ?? event.target.value;
        this.st_address = {
            ...this.st_address,
            CountryCode: country,
            StateCode: ''
        };
         queueMicrotask(() => this.recomputeSaveDisabled());
    }   
    
    handleDefaultChange(event) {
        this.ui_errorMessage = '';
        const isDefault = event.target.checked;
        this.st_address = {
            ...this.st_address,
            IsDefault: isDefault
        };
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    async handleSave() {
        this.ui_errorMessage = '';
        if (this.ui_isLoading) { return; }        
        const isValid = this.validateForm();
        this.recomputeSaveDisabled();
        if (!isValid) { return; }
        this.ui_isLoading = true;
        this.recomputeSaveDisabled();
        try {
            console.log('SE SUPONE QUE VOY A SALVAR ESTE ADDRESS: ', JSON.stringify(this.st_address));
            const saved = await this.upsertAddress();
            this.st_address = saved;
            console.info('==> CPA.Id: ', saved.Id);
            console.log('DISPATCHING SAVE EVENT WITH THIS ADDRESS: ', JSON.stringify(saved));
            const payload =  {
                address: saved,
                state: this.stateLabel,
                country: this.countryLabel 
            };
            this.dispatchEvent(new CustomEvent('save', { detail: payload }));
        } catch (e) {
            console.error('[B2bCheckoutAddressForm] Save failed', {
                mode: this.mode,
                addressId: this.st_address?.Id,
                parentId: this.accountId,
                country: this.st_address?.CountryCode,
                state: this.st_address?.StateCode,
                postalCode: this.st_address?.PostalCode,
                error: JSON.stringify(e)
            });
            this.ui_errorMessage = this.normalizeErrorMessage(e);
        } finally {
            this.ui_isLoading = false;
            queueMicrotask(() => this.recomputeSaveDisabled());
        }
    }

    /* =========================================================
     * PERSISTENCE
     * ========================================================= */  
    async upsertAddress() {        
        const inputAddress = {
            Id: this.st_address.Id,
            Name: this.st_address.Name,
            Street: this.st_address.Street,
            City: this.st_address.City,
            StateCode: this.st_address.StateCode,
            PostalCode: this.st_address.PostalCode,
            CountryCode: this.st_address.CountryCode,
            Phone__c: this.st_address.Phone__c,
            EMail__c: this.st_address.EMail__c,
            ParentId: this.accountId,
            AddressType: 'Shipping',
            IsDefault: this.st_address.IsDefault
        };
        console.log('Envio a guardar este address: ', JSON.stringify(inputAddress));
        const result = await saveContactPointAddress({ inputAddress });
        console.info('Address saved successfully', JSON.stringify(result));
        return { ...this.st_address, ...inputAddress, ...(result?.address ?? {}) };
    }

    /* =========================================================
     * VALIDATIONS
     * ========================================================= */
    validateForm() {
        const controls = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        controls.forEach((c) => {
            c.reportValidity();
            isValid = isValid && c.checkValidity();
        });
        return isValid;
    }

    /* =========================================================    
     * UTILITY METHODS       
     * ========================================================= */
    initializeBlankAddress() {
        return {
            Name: '',
            Street: '',
            City: '',
            StateCode: '',
            PostalCode: '',
            CountryCode: this.fixCountry||'US',
            Phone__c: '',
            EMail__c: '',
            ParentId: '',
            IsDefault: false
        }; 
    } 

    recomputeSaveDisabled() {
        const controls = this.template.querySelectorAll('lightning-input, lightning-combobox');
        if (!controls || controls.length === 0) {
            this.ui_isSaveDisabled = true;
            return;
        }
        this.ui_isSaveDisabled = this.ui_isLoading || Array.from(controls).some(c => !c.checkValidity());
    }

    normalizeErrorMessage(error) {
        console.error('[B2bCheckoutAddressForm] normalizeErrorMessage', error);
        return (
            error?.body?.message ||
            error?.body?.output?.errors?.[0]?.message ||
            error?.body?.output?.fieldErrors && Object.values(error.body.output.fieldErrors)?.[0]?.[0]?.message ||
            error?.message ||
            'Could not save the address. Please review the form and try again.'
        );
    }
}