/**
 * libAddressCommons
 * 
 * Ramón, June 2023
 * 
 * Library functions to work with postal addresses
 * 
 */

import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import getPorcelanosaAddress from '@salesforce/apex/LibAddressCommonsController.getPorcelanosaAddress';

import ACCOUNT_BILLING_COUNTRY_CODE_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import ACCOUNT_BILLING_CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import ACCOUNT_BILLING_POSTCODE_FIELD from '@salesforce/schema/Account.BillingPostalCode';
import ACCOUNT_BILLING_STATE_CODE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import ACCOUNT_BILLING_STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import ACCOUNT_BILLING_STATE_FIELD from '@salesforce/schema/Account.BillingState';
import ACCOUNT_BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import ACCOUNT_PERSON_MAILING_COUNTRY_CODE_FIELD from '@salesforce/schema/Account.PersonMailingCountryCode';
import ACCOUNT_PERSON_MAILING_CITY_FIELD from '@salesforce/schema/Account.PersonMailingCity';
import ACCOUNT_PERSON_MAILING_POSTCODE_FIELD from '@salesforce/schema/Account.PersonMailingPostalCode';
import ACCOUNT_PERSON_MAILING_STATE_CODE_FIELD from '@salesforce/schema/Account.PersonMailingStateCode';
import ACCOUNT_PERSON_MAILING_STREET_FIELD from '@salesforce/schema/Account.PersonMailingStreet';
import ACCOUNT_PERSON_MAILING_COUNTRY_FIELD from '@salesforce/schema/Account.PersonMailingCountry';
import ACCOUNT_PERSON_MAILING_STATE_FIELD from '@salesforce/schema/Account.PersonMailingState';
import ACCOUNT_SAP_ID_FIELD from '@salesforce/schema/Account.SAP_Id__c';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_PHONE_FIELD from '@salesforce/schema/Account.Phone';

import CPA_STREET_FIELD from '@salesforce/schema/ContactPointAddress.Street';
import CPA_CITY_FIELD from '@salesforce/schema/ContactPointAddress.City';
import CPA_POSTCODE_FIELD from '@salesforce/schema/ContactPointAddress.PostalCode';
import CPA_COUNTRY_CODE_FIELD from '@salesforce/schema/ContactPointAddress.CountryCode';
import CPA_COUNTRY_FIELD from '@salesforce/schema/ContactPointAddress.Country';
import CPA_STATE_FIELD from '@salesforce/schema/ContactPointAddress.State';
import CPA_STATE_CODE_FIELD from '@salesforce/schema/ContactPointAddress.StateCode';
import CPA_SAP_ID_FIELD from '@salesforce/schema/ContactPointAddress.SAPId__c';
import CPA_ADDRESS_TYPE_FIELD from '@salesforce/schema/ContactPointAddress.AddressType';
import CPA_NAME_FIELD from '@salesforce/schema/ContactPointAddress.Name';
import CPA_PHONE_FIELD from '@salesforce/schema/ContactPointAddress.Phone__c';

import PA_STREET_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_CITY_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_POSTCODE_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_COUNTRY_CODE_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_ADDRESS_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_STATE_CODE_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address__c';
import PA_SAP_ID_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_SAPId__c';
import PA_NAME_FIELD from '@salesforce/schema/PorcelanosaAddress__c.Name';
import PA_PHONE_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Phone__c';
import PA_ADDRESS_TYPE_FIELD from '@salesforce/schema/PorcelanosaAddress__c.NBK_Address_Type__c';

export { formatAddress, getCountryLocale };

export default class LibAddressCommons extends LightningElement{

    @api 
        get objectId() { return this._id;}
        set objectId(value) {
            this._id = value;
            if (this._id) {
                if (this._id.startsWith('001')) {
                    this.accountId = this._id;
                } else if (this._id.startsWith('8lW')) {
                    this.contactPointId = this._id;
                } else if (this._id.startsWith('a3s')) {
                    this.porcelanosaAddressId = this._id;
                    this.readPorcelanosaAddress();
                } else {
                    this.dispatchEvent(new CustomEvent('error', {detail: 'Object Id not recognised. Please use an account or a contact point address.'}));
                }
            }
        }

    _id;
    accountId;
    contactPointId;
    accountAddress;
    contactAddress;
    porcelanosaAddressId;
    porcelanosaAddress;

    // Account data
    @wire(getRecord, { recordId: '$accountId', fields: [
        ACCOUNT_BILLING_COUNTRY_CODE_FIELD, 
        ACCOUNT_BILLING_STREET_FIELD,
        ACCOUNT_BILLING_CITY_FIELD,
        ACCOUNT_BILLING_POSTCODE_FIELD,
        ACCOUNT_BILLING_STATE_CODE_FIELD,
        ACCOUNT_BILLING_COUNTRY_FIELD,
        ACCOUNT_BILLING_STATE_FIELD,        
        ACCOUNT_PERSON_MAILING_COUNTRY_CODE_FIELD,
        ACCOUNT_PERSON_MAILING_STREET_FIELD,
        ACCOUNT_PERSON_MAILING_CITY_FIELD,
        ACCOUNT_PERSON_MAILING_POSTCODE_FIELD,
        ACCOUNT_PERSON_MAILING_STATE_CODE_FIELD,
        ACCOUNT_PERSON_MAILING_STATE_FIELD,
        ACCOUNT_PERSON_MAILING_COUNTRY_FIELD,
        ACCOUNT_SAP_ID_FIELD,
        ACCOUNT_NAME_FIELD, 
        ACCOUNT_PHONE_FIELD
    ] })
        wiredAccount({ error, data }) {
            if (data) {
                this.accountAddress = new Object();
                this.accountAddress.Id = this.accountId;
                this.accountAddress.sObject = 'Account';
                const billingCountryCode = getFieldValue(data, ACCOUNT_BILLING_COUNTRY_CODE_FIELD);
                if (billingCountryCode) {
                    this.accountAddress.CountryCode = getFieldValue(data, ACCOUNT_BILLING_COUNTRY_CODE_FIELD);
                    this.accountAddress.City = getFieldValue(data, ACCOUNT_BILLING_CITY_FIELD);                    
                    this.accountAddress.Street = getFieldValue(data, ACCOUNT_BILLING_STREET_FIELD);
                    this.accountAddress.StateCode = getFieldValue(data, ACCOUNT_BILLING_STATE_CODE_FIELD);
                    this.accountAddress.PostalCode = getFieldValue(data, ACCOUNT_BILLING_POSTCODE_FIELD);
                    this.accountAddress.State = getFieldValue(data, ACCOUNT_BILLING_STATE_FIELD);
                    this.accountAddress.Country = getFieldValue(data, ACCOUNT_BILLING_COUNTRY_FIELD);
                } else {
                    this.accountAddress.CountryCode = getFieldValue(data, ACCOUNT_PERSON_MAILING_COUNTRY_CODE_FIELD);
                    this.accountAddress.City = getFieldValue(data, ACCOUNT_PERSON_MAILING_CITY_FIELD);                    
                    this.accountAddress.Street = getFieldValue(data, ACCOUNT_PERSON_MAILING_STREET_FIELD);
                    this.accountAddress.StateCode = getFieldValue(data, ACCOUNT_PERSON_MAILING_STATE_CODE_FIELD);
                    this.accountAddress.PostalCode = getFieldValue(data, ACCOUNT_PERSON_MAILING_POSTCODE_FIELD);
                    this.accountAddress.State = getFieldValue(data, ACCOUNT_PERSON_MAILING_STATE_FIELD);
                    this.accountAddress.Country = getFieldValue(data, ACCOUNT_PERSON_MAILING_COUNTRY_FIELD);
                }
                this.accountAddress.Name = getFieldValue(data, ACCOUNT_NAME_FIELD);
                this.accountAddress.Phone = getFieldValue(data, ACCOUNT_PHONE_FIELD);
                this.accountAddress.SAPId = getFieldValue(data, ACCOUNT_SAP_ID_FIELD); 
                this.accountAddress.Locale = getCountryLocale(this.accountAddress.CountryCode);
                this.dispatchEvent(new CustomEvent('addressready', {detail: this.accountAddress}));
            } else if (error) {  
                 this.dispatchEvent(new CustomEvent('error', {detail: error}));
            }
        }

/*
*/
    // ContactPoint data
    @wire(getRecord, { recordId: '$contactPointId', fields: [
        CPA_STREET_FIELD,
        CPA_CITY_FIELD,
        CPA_POSTCODE_FIELD,
        CPA_COUNTRY_CODE_FIELD,
        CPA_COUNTRY_FIELD,
        CPA_STATE_FIELD,
        CPA_STATE_CODE_FIELD,
        CPA_SAP_ID_FIELD,
        CPA_ADDRESS_TYPE_FIELD,
        CPA_NAME_FIELD,
        CPA_PHONE_FIELD
    ] })
        wiredContact ({ error, data }) {    
            if (data) {
                this.contactAddress = new Object();
                this.contactAddress.Id = this.contactPointId;
                this.contactAddress.sObject = 'ContactPointAddress';
                this.contactAddress.Name = getFieldValue(data, CPA_NAME_FIELD);
                this.contactAddress.CountryCode = getFieldValue(data, CPA_COUNTRY_CODE_FIELD);
                this.contactAddress.City = getFieldValue(data, CPA_CITY_FIELD);                    
                this.contactAddress.Street = getFieldValue(data, CPA_STREET_FIELD);
                this.contactAddress.StateCode = getFieldValue(data, CPA_STATE_CODE_FIELD);
                this.contactAddress.PostalCode = getFieldValue(data, CPA_POSTCODE_FIELD);
                this.contactAddress.State = getFieldValue(data, CPA_STATE_FIELD);
                this.contactAddress.Country = getFieldValue(data, CPA_COUNTRY_FIELD);
                this.contactAddress.SAPId = getFieldValue(data, CPA_SAP_ID_FIELD);
                this.contactAddress.AddressType = getFieldValue(data, CPA_ADDRESS_TYPE_FIELD);
                this.contactAddress.Phone = getFieldValue(data, CPA_PHONE_FIELD);
                this.contactAddress.Locale = getCountryLocale(this.contactAddress.CountryCode);
                this.dispatchEvent(new CustomEvent('addressready', {detail: this.contactAddress}));
            } else if (error) {  
                 this.dispatchEvent(new CustomEvent('error', {detail: error}));
            }
        }

    readPorcelanosaAddress() {
        getPorcelanosaAddress({addressId: this.porcelanosaAddressId})
            .then((result) => {
                this.porcelanosaAddress = new Object();
                this.porcelanosaAddress.Id = this.porcelanosaAddressId;
                this.porcelanosaAddress.sObejct = 'PorcelanosaAddress__c';
                this.porcelanosaAddress.Name = result.Name;
                this.porcelanosaAddress.CountryCode = result.NBK_Address__c.countryCode;
                this.porcelanosaAddress.Country = result.NBK_Address__c.country;
                this.porcelanosaAddress.City = result.NBK_Address__c.city;
                this.porcelanosaAddress.Street = result.NBK_Address__c.street;
                this.porcelanosaAddress.StateCode = result.NBK_Address__c.stateCode;
                this.porcelanosaAddress.State = result.NBK_Address__c.state;
                this.porcelanosaAddress.PostalCode = result.NBK_Address__c.postalCode;
                this.porcelanosaAddress.SAPId = result.NBK_SAPId__c;
                this.porcelanosaAddress.Phone = result.NBK_Phone__c;
                this.porcelanosaAddress.AddressType = result.NBK_AddressType__c;
                this.porcelanosaAddress.Locale = getCountryLocale(this.porcelanosaAddress.CountryCode);
                this.dispatchEvent(new CustomEvent('addressready', {detail: this.porcelanosaAddress}));
            })
            .catch((error) => {
                this.dispatchEvent(new CustomEvent('error', {detail: error}));
            });
    }
    
} // default class

/**
 * getCountryLocale
 * 
 * Returns the country locale for ligthning-formatted-address.
 */
const getCountryLocale = (countryCode) => {
    let locale = '';
    switch (countryCode) {
        case 'CA': locale = 'en-CA'; break;
        case 'DE': locale = 'de-DE'; break;
        case 'ES': locale = 'es-ES'; break;
        case 'FR': locale = 'fr-FR'; break;
        case 'GB': locale = 'en-GB'; break;
        case 'IE': locale = 'en-IE'; break;
        case 'IT': locale = 'it-IT'; break;
        case 'MX': locale = 'es-MX'; break;
        case 'PT': locale = 'pt-PT'; break;
        case 'US': locale = 'en-US'; break;
    }
    return locale; // balnk if not found-it will use the user's locale
}
/**
 * formatAddress
 * 
 * Formats an address in a string with new line characters on it.
 * 
 * addressObject is any object with the following fields: Street, City, Country and CountryCode,
 * State and StateCode and PostalCode. 
 * 
 */

const newLine = '\n';
let street = '';
let city = '';
let country = '';
let countryCode = '';
let state = '';
let stateCode = ''; 
let postalCode = '';
 
const formatAddress = (addressObject) => {
    readAddressFields(addressObject);
    if (countryCode == 'US') {
        return formatUSAddress();
    } else if (countryCode == 'GB') {
        return formatUKAddress();
    } else if (countryCode == 'FR') {
        return formatFRAddress();
    } else {
        return formatDefaultAddress();
    }
}

const formatUSAddress = () => {
    let formatted = '';
    if (street.length > 0) {
        formatted = street + newLine;
    }

    let line = city;
    if (stateCode.length > 0 || postalCode.length > 0) {
        formatted += line + ', ' + stateCode + ' ' + postalCode + newLine;
    }

    if (country.length > 0) {
        formatted += country.toUpperCase();
    }
    
    return formatted;
}

const formatUKAddress = () => {
    let formatted = '';
    if (street.length > 0) {
        formatted = street + newLine;
    }
    if (city.length > 0) {
        formatted += city + newLine;
    }
    if (postalCode.length > 0) {
        formatted += postalCode + newLine;
    }
    if (country.length > 0) {
        formatted += country;
    }
    
    return formatted;
}


const formatFRAddress = () => {
    let formatted = '';
    if (street.length > 0) {
        formatted = street + newLine;
    }

    let line = postalCode + ' ' + city;
    line = line.trim();
    if (line.length > 0) {
        formatted += line + newLine;
    }

    if (country.length > 0) {
        formatted += country;
    }
    
    return formatted;
}

const formatDefaultAddress = () => {
    // const newLine = '\n';

    let formatted = '';
    if (street.length > 0) {
        formatted = street + newLine;
    }

    let line = postalCode + ' ' + city;
    line = line.trim();
    if (line.length > 0) {
        formatted += line + newLine;
    }

    if (state.length > 0 && state.toLowercase() != city.toLowerCase()) {
        formatted += state + newLine;
    }

    if (country.length > 0) {
        formatted += country;
    }
    
    return formatted;
}

const readAddressFields = (addressObject) => {
    street = denullify(addressObject.Street);
    city = denullify(addressObject.City);
    country = denullify(addressObject.Country);
    countryCode = denullify(addressObject.CountryCode);
    state = denullify(addressObject.State);
    stateCode = denullify(addressObject.StateCode);
    postalCode = denullify(addressObject.PostalCode);
}

const denullify = (value) => {
    if (value == null || value == undefined) {
        return '';
    } else {
        return value;
    }
}