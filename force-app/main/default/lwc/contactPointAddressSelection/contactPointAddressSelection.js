/**
 * Contact Point Address selection form
 * 
 * There are a number of variables that control the behavior of the component:
 * 
 * - showDialog (_showDialog): Displays/Hides the component.
 * - isReady: The component has got the necessary ionformation from the server and it is ready to start
 * - editionMode: Displays the edition form to create or edit an address
 * - selectionMode: The component is in selection mode
 * 
 * The component can work with two sets of objects:
 * - mode = 'delivery' displays the account address and its contact point addresses
 * - mode = 'pìckup'  displays the PorcelanosaAddress__c addresses located in the account sales orgs.
 * And the data variables are:
 * - countryList: Data for the pickllist of countries.
 * - provinceList: Data for the picklist of provinces
 * - addressesPicklist: Data for the picklist of addresses
 * - addresses: list of delivery addresses
 * - pickupPoints: List of Porcelanosa Addresses that serve as pickup points and showrooms
 * - pickupPointsPicklist: picklist of pickup points
 * - showroomsPicklist: 
 * 
 * Translation profix: tr0007
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import { getCountryLocale } from 'c/libAddressCommons';

// Custom code imports
import getFormData from '@salesforce/apex/CPAddressFormController.getFormData';
import saveContactPointAddress from '@salesforce/apex/CPAddressFormController.saveContactPointAddress';

// Labels
import tr0007_001 from "@salesforce/label/c.tr0007_001";
import tr0007_002 from "@salesforce/label/c.tr0007_002";
import tr0007_003 from "@salesforce/label/c.tr0007_003";
import tr0007_004 from "@salesforce/label/c.tr0007_004";
import tr0007_005 from "@salesforce/label/c.tr0007_005";
import tr0007_006 from "@salesforce/label/c.tr0007_006";
import tr0007_007 from "@salesforce/label/c.tr0007_007";
import tr0007_008 from "@salesforce/label/c.tr0007_008";
import tr0007_009 from "@salesforce/label/c.tr0007_009";
import tr0007_010 from "@salesforce/label/c.tr0007_010";
import tr0007_011 from "@salesforce/label/c.tr0007_011";
import tr0007_012 from "@salesforce/label/c.tr0007_012";
import tr0007_013 from "@salesforce/label/c.tr0007_013";
import tr0007_014 from "@salesforce/label/c.tr0007_014";
import tr0007_015 from "@salesforce/label/c.tr0007_015";
import tr0007_016 from "@salesforce/label/c.tr0007_016";
import tr0007_017 from "@salesforce/label/c.tr0007_017";


import dict_name from "@salesforce/label/c.dict_name";
import dict_phone from "@salesforce/label/c.dict_phone";
import dict_button_cancel from "@salesforce/label/c.dict_button_cancel";
import dict_button_ok from "@salesforce/label/c.dict_button_ok";
import dict_street from "@salesforce/label/c.dict_street";
import dict_city from "@salesforce/label/c.dict_city";
import dict_postal_code from "@salesforce/label/c.dict_postal_code";
import dict_country from "@salesforce/label/c.dict_country";
import dict_save from "@salesforce/label/c.dict_save";
import dict_address_type from "@salesforce/label/c.dict_address_type";
import dict_delivery_address from "@salesforce/label/c.dict_delivery_address";
import dict_search_address from "@salesforce/label/c.dict_search_address";
import dict_state_province from "@salesforce/label/c.dict_state_province";


export default class ContactPointAddressSelection extends LightningElement {

    labels = {
        tr0007_001, tr0007_002, tr0007_003, tr0007_004, tr0007_005,
        tr0007_006, tr0007_007, tr0007_008, tr0007_009, tr0007_010,
        tr0007_011, tr0007_012, tr0007_013, tr0007_014, tr0007_015, 
        tr0007_016, tr0007_017, 
        dict_address_type, dict_delivery_address, dict_search_address, 
        dict_state_province, dict_name, dict_phone, dict_button_cancel, 
        dict_button_ok, dict_street, dict_city, dict_postal_code, dict_country, 
        dict_save, dict_address_type, dict_delivery_address, dict_search_address, 
        dict_state_province
    };

    ///////////////////////////////////////
    // VARIABLES
    ///////////////////////////////////////
    // FLAGS
    _showDialog = false;
    isReady = false;
    selectionMode = true;
    showSpinner = false;

    get editionMode() { return !this.selectionMode; }
    get isLoading() { return (!this.isReady); }
    get addressNotSelected() { return (this.selectedAddressId == null) };
    get showNewButton() { return (this.selectionMode && this.mode == 'delivery')};
    get useDeliveryAddresses() { return (this.mode == 'delivery'); }

    // Radiobutton variales
    get radioLabel() {
        if (this.mode == 'delivery') {
            return this.labels.tr0007_012; // Please select the delivery address or click the button below to create a new one
        } else if (this.mode == 'showroom') {
            return this.labels.tr0007_013; // Please select a showroom
        } else {
            return this.labels.tr0007_014; // Please select the pickup address
        }
    }

    get emptyListLabel() {
        if (this.mode == 'delivery') {
            return this.labels.tr0007_015; // It looks like this account doesn't have any delivery addresses yet. To create a new one, please click on the 'New Address' button below.
        } else if (this.mode == 'showroom') {
            return this.labels.tr0007_016; // No showrooms have been defined for the account's organisation
        } else {
            return this.labels.tr0007_017; // No pickup addresses have been defined for the account's organisation
        }
    }

    get radioOptions() {
        if (this.mode == 'delivery') {
            return this.addressesPicklist;
        } else if (this.mode == 'showroom') {
            return this.showroomsPicklist;
        } else {
            return this.pickupPointsPicklist;
        }
    }

    get radioValue() {
        return this.selectedAddressId;
    }

    get hasData() { 
        return (this.radioOptions?.length > 0)
    }

    get mainHeader() {
        if (this.isDelivery) {
            return this.labels.tr0007_001; // Delivery Addresses
        } else if (this.isPickup) {
            return this.labels.tr0007_002; // Pickup Points
        } else {
            return this.labels.tr0007_003; // Showroom Addresses
        }
    }

    get isDelivery() {
        return (this.mode == 'delivery');
    }

    get isPickup() {
        return (this.mode == 'pickup');
    }

    get isShowroom() {
        return (this.mode == 'showroom');
    }

    // DATA
    countryList;
    provinceMap;
    provinceList;
    accountName;
    accountAddress;
    defaultCountry;
    currentCountry;
    address;
    error;
    thePhone;
    selectedPointSAPId;
    newIntroLabel = this.labels.tr0007_004; // The address you're creating will be automatically synchronized with SAP

    pipckupPoints = [];
    pipckupPointsList = [];
    showroomsPicklist = [];
    addresses = [];
    addressesPicklist = [];
    addressTypesList;


    ///////////////////////////////////////
    // API
    ///////////////////////////////////////
    @api accountId;
    @api selectedAddressId;
    @api variant = "medium-tall";
    @api mode = "delivery"; // or "pickup" or "showroom"
    @api showBilling = false;

    @api
    get showDialog() {
        return this._showDialog;
    }
    set showDialog(value) {
        this._showDialog = value;
        if (this._showDialog && !this.isReady) {
            this.readDataForm();
        }
        if (!this.selectedAddressId)  {
            if (this.radioOptions && this.radioOptions.length > 0) {
                this.selectedAddressId = this.radioOptions[0].value;
            }
        } 
    }

    ///////////////////////////////////////
    // EVENT HANDLERS
    ///////////////////////////////////////

    handleAccountAddressReady(event) {
        this.accountAddress = event.detail;
        this.accountName = this.accountAddress.Name;
        this.defaultCountry = this.accountAddress.CountryCode;
    }
    
    handleNewAddressButton() {
        this.initializeAddress();
        this.selectionMode = false;
    }

    handleOKButton(event) {        
        let address = this.accountAddress;
        let result = this.getSelectedAddressObject(this.selectedAddressId);
        /*
       let result = new Object();
        result.Id = cpaId;
        result.ContactPointAddressId = cpaId;
        result.Street = address.Street;
        result.City = address.City;
        result.PostalCode = address.PostalCode;
        result.State = address.State;
        result.StateCode = address.StateCode;
        result.Country = address.Country;
        result.CountryCode = address.CountryCode;
        result.SAPId = sapId;
        */
        this.dispatchEvent(new CustomEvent('select', {detail: result}));
    }

    handleSaveButton(event) {
        let isValid = true;
        const phoneField =  this.template.querySelector('lightning-input[data-id=Phone]');
        if (phoneField.value == null || phoneField.value.trim() === '' ) {
            phoneField.setCustomValidity(this.labels.tr0007_005); // Phone is required
            isValid = false;
        } else {
            phoneField.setCustomValidity('');
        }
        phoneField.reportValidity();
        const address = this.template.querySelector('lightning-input-address');
        this.validateAddress(address)
        isValid = isValid && address.reportValidity();
        if(isValid) {
            address.accountId = this.accountId;
            let contactAddress = this.setContactAddress();
            this.saveAddress(contactAddress);
        }
    }
    
    handleCancelButton(event) {
        this.selectionMode = true;
    }

    handleCloseButton(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleAddressChange(event) {
        if (event.detail.country != this.currentCountry) {
            this.setStatesPicklist(event.detail.country);
        }
    }

    handleAddressSelection(event) {
        this.selectedAddressId = this.template.querySelector('lightning-radio-group').value;
    }

    ///////////////////////////////////////
    // SERVER ACCESS
    ///////////////////////////////////////
 
    readDataForm() {
        this.error = null;
        this.showSpinner = true;
        getFormData({accountId: this.accountId})
            .then((result) => {                            
                this.countryList = result.countries;
                this.provinceMap = result.states;
                this.addressTypesList = this.filterAddressTypes(result.addressTypes);
                this.addresses = result.addresses;
                this.addressesPicklist = result.addressesPicklist;
                this.pickupPoints = result.pickupPoints;
                this.pickupPointsPicklist = result.pickupPointsPicklist;
                this.showroomsPicklist = result.showroomsPicklist;
                this.isReady = true;
            })                
            .catch((error) => {
                this.isReady = false;
                if (error.status == 500) {
                    this.error = error;
                }
            })
            .finally(() => {
                this.showSpinner = false;
            });            
    }

    filterAddressTypes(addressTypes) {
        let result = new Array();
        for (let i = 0; i < addressTypes.length; i++) {
            if (this.showBilling || addressTypes[i].label.toLowerCase() != 'billing') {
                result.push(addressTypes[i]);
            }
        }
        return result;
    }

    saveAddress(address) {
        this.error = null;
        this.isReady = false;
        this.showSpinner = true;
        saveContactPointAddress({inputAddress: address})
            .then((result) => {
                const newAddress = result.address;
                const option = result.option;
                this.addressesPicklist.push(option);
                this.setSelectedAddress(option.value);
                this.isReady = true;
                this.addresses.push(newAddress);
                this.selectionMode = true;
            })                
            .catch((error) => {
                this.isReady = false;
                this.selectedAddressId = null;
                this.selectionMode = true;
                // if (error.status == 500) {
                    this.error = error;
                // }
            })
            .finally(() => {                
                this.showSpinner = false;
            });            
    } // saveAddress
    
    ///////////////////////////////////////
    // PRIVATE METHODS
    ///////////////////////////////////////

    validateAddress(address) {
        if (!address.country) {
            address.setCustomValidityForField(this.labels.tr0007_006, 'country'); // Country is required
        } else {
            address.setCustomValidityForField('', 'country');
        }
        if (!address.street) {
            address.setCustomValidityForField(this.labels.tr0007_007, 'street'); // Street is required'
        } else {
            address.setCustomValidityForField('', 'street');
        }
        if (!address.city) {
            address.setCustomValidityForField(this.labels.tr0007_008, 'city'); // City is required
        } else {
            address.setCustomValidityForField('', 'city');
        }
        if (!address.postalCode) {
            address.setCustomValidityForField(this.labels.tr0007_009, 'postalCode'); // Postal Code is required
        } else {
            address.setCustomValidityForField('', 'postalCode');
        }
        if (address.country === 'US' && (!address.province)) {
            address.setCustomValidityForField(this.labels.tr0007_010, 'province'); // 'State is required'
        } else {
            address.setCustomValidityForField('', 'province');     
        }
    }

    setSelectedAddress(value) {
        this.selectedAddressId = value;
    }

    setContactAddress() {
        let contactAddress = {};        

        // Header fields
        contactAddress.Id = null;
        contactAddress.Name = this.template.querySelector('lightning-input[data-id=Name]').value;
        contactAddress.Phone__c = this.template.querySelector('lightning-input[data-id=Phone]').value;
        contactAddress.AddressType = this.template.querySelector('lightning-combobox[data-id=AddressType]').value;
        contactAddress.ParentId = this.accountId;        

        // Address fields
        const address = this.template.querySelector('lightning-input-address');
        contactAddress.CountryCode = address.country;
        contactAddress.City = address.city;
        contactAddress.Street = address.street;
        contactAddress.PostalCode = address.postalCode;
        contactAddress.StateCode = address.province;

        return contactAddress;
    }

    initializeAddress() {
        this.address = {};
        this.address.Name = this.accountName;
        this.address.Phone = '';
        this.addressType = 'Shipping';
        this.address.street = '';
        this.address.city = '';
        this.address.provinceCode = '';
        this.address.countryCode = this.defaultCountry;
        this.address.postCode = '';
        this.setStatesPicklist(this.address.countryCode);
    }

    setStatesPicklist(countryCode) {
        //alert(JSON.stringify(this.provinceMap["GB"]));
        this.currentCountry = countryCode;
        this.address.provinceCode = '';
        this.provinceList = this.provinceMap[countryCode];
    }

    getSelectedAddressObject(addressId) {
        let result = new Object();
        if (this.mode == 'delivery') {
            if (addressId == this.accountId) {
                result = {...this.accountAddress};
                result.isContactPoint = false;
            } else {   
                this.addresses.forEach(function(item) {
                    if (item.Id == addressId) {
                        result = {...item};
                        result.SAPId = item.SAPId__c;
                        result.Phone = item.Phone__c;
                        result.isContactPoint = true;
                    }
                  });
            }            
        } else {
            /* pickup */
            this.pickupPoints.forEach((item) => {
                // Puto prefijo NBK
                if (item.Id == addressId) {                    
                    result.Id = item.Id;
                    result.Name = item.Name;
                    result.Street = item.NBK_Address__c.street;
                    result.City = item.NBK_Address__c.city;
                    result.PostalCode = item.NBK_Address__c.postalCode;
                    result.State = item.NBK_Address__c.state;
                    result.StateCode = item.NBK_Address__c.stateCode;
                    result.Country = item.NBK_Address__c.country;
                    result.CountryCode = item.NBK_Address__c.countryCode;
                    result.SAPId = item.NBK_SAPId__c;
                    result.Phone = item.NBK_Phone__c;
                    result.isContactPoint = false;
                }
            });
        }
        result.Locale = getCountryLocale(result.CountryCode);
        return result;
    }

}