/**
 * Samples Orders Creation/Edition FOrm
 * 
 * When creating, this form is called as an action of Opportinity and recordId refers to it,
 * When editing, recprdId refers to the order itself
 * 
 */
import { LightningElement, api, wire } from 'lwc';

import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getSamplePricebook from '@salesforce/apex/NBK_CreateSamplesOrderController.getSamplePricebook';
import getUserPermissionSet from '@salesforce/apex/NBK_CreateSamplesOrderController.getPermissionSet';
import getSalesRelationShip from '@salesforce/apex/NBK_CreateSamplesOrderController.getSalesRelationShip';
import getNextOrders from '@salesforce/apex/NBK_CreateSamplesOrderController.getNextOrders';
import getDeliveryDateOptions from '@salesforce/apex/NBK_CreateSamplesOrderController.getDeliveryDateOptions';
// import LOCALE from "@salesforce/i18n/locale";



// FIELDS
import ORDER_ID from '@salesforce/schema/Order.Id';
import ORDER_NUMBER from '@salesforce/schema/Order.OrderNumber';
import ORDER_OBJECT from '@salesforce/schema/Order';
import ORDER_STATUS from '@salesforce/schema/Order.Status';
import ORDER_ACCOUNTID from '@salesforce/schema/Order.AccountId';
import ORDER_CUSTOMER from '@salesforce/schema/Order.NB2B_OrderCode__c';
import ORDER_START_DATE from '@salesforce/schema/Order.EffectiveDate';
import ORDER_DELIVERY_DATE from '@salesforce/schema/Order.DeliveryDate__c';
import ORDER_PRICEBOOKID from '@salesforce/schema/Order.Pricebook2Id';
import ORDER_PRICEBOOK_NAME from '@salesforce/schema/Order.Pricebook2.Name';
import ORDER_DELIVERY_METHOD from '@salesforce/schema/Order.NB2B_Delivery_Method__c';
import ORDER_DELIVERY_STATUS from '@salesforce/schema/Order.NB2B_DeliveryStatus__c';
import ORDER_OPPORTUNITYID from '@salesforce/schema/Order.OpportunityId';
import ORDER_RECORDTYPEID from '@salesforce/schema/Order.RecordTypeId';
import ORDER_CURRENCYISOCOD from '@salesforce/schema/Order.CurrencyIsoCode';
import ORDER_CURRENCY from '@salesforce/schema/Order.Currency__c';
import ORDER_CONTACTPOINT from '@salesforce/schema/Order.NBK_Contact_Point_Address__c';
import ORDER_WAREHOUSE from '@salesforce/schema/Order.NBK_Warehouse_Address__c';
import ORDER_SALES_OFFICE from '@salesforce/schema/Order.SalesOffice__c';
import ORDER_SALES_ORG from '@salesforce/schema/Order.SalesOrg__c';
import ORDER_DISTRIBUTION_CHANNEL from '@salesforce/schema/Order.Distribution_channel__c';
import ORDER_OPPORTUNITY_NAME from '@salesforce/schema/Order.Opportunity.Name';
import ORDER_OPPORTUNITY_OWNER_NAME from '@salesforce/schema/Order.Opportunity.Owner.Name';
import ORDER_ACCOUNT_NAME from '@salesforce/schema/Order.Account.Name';
import ORDER_ACCOUNT_SAPID from '@salesforce/schema/Order.Account.SAP_Id__c';
import ORDER_SAP_ID from '@salesforce/schema/Order.Sap_Id__c';
import ORDER_AUTOPICK from '@salesforce/schema/Order.Autopick__c';
import ORDER_SAMPLES from '@salesforce/schema/Order.NBK_Sample__c';

const OPPORTUNITY_FIELDS = [
    'Opportunity.Id',
    'Opportunity.Name',
    'Opportunity.Owner.Name',
    'Opportunity.AccountId',
    'Opportunity.Account.Name',
    'Opportunity.Account.SAP_Id__c',
    'Opportunity.Account.Country_formula__c',
    'Opportunity.Account.BillingCountryCode',
    'Opportunity.CurrencyIsoCode',
];

const ORDER_FIELDS = [
    ORDER_ID,
    ORDER_NUMBER,
    ORDER_STATUS,
    ORDER_ACCOUNTID,
    ORDER_CUSTOMER,
    ORDER_START_DATE,
    ORDER_DELIVERY_DATE,
    ORDER_PRICEBOOKID,
    ORDER_PRICEBOOK_NAME,
    ORDER_DELIVERY_METHOD,
    ORDER_DELIVERY_STATUS,
    ORDER_OPPORTUNITYID,
    ORDER_RECORDTYPEID,
    ORDER_CURRENCYISOCOD,
    ORDER_CURRENCY,
    ORDER_CONTACTPOINT,
    ORDER_WAREHOUSE,
    ORDER_SALES_OFFICE,
    ORDER_SALES_ORG,
    ORDER_DISTRIBUTION_CHANNEL,
    ORDER_OPPORTUNITY_NAME,
    ORDER_OPPORTUNITY_OWNER_NAME,
    ORDER_ACCOUNT_NAME,
    ORDER_ACCOUNT_SAPID,
    ORDER_AUTOPICK,
    ORDER_SAP_ID,
    ORDER_SAMPLES
];


//LABELS
import NBK_CreateSamplesOrderTitle from '@salesforce/label/c.NBK_CreateSamplesOrderTitle';
import NBK_CreateSamplesOrderAccName from '@salesforce/label/c.NBK_CreateSamplesOrderAccName';
import NBK_CreateSamplesOrderCustRef from '@salesforce/label/c.NBK_CreateSamplesOrderCustRef';
import NBK_CreateSamplesOrderOrderDate from '@salesforce/label/c.NBK_CreateSamplesOrderOrderDate';
import NBK_CreateSamplesOrderDelMethod from '@salesforce/label/c.NBK_CreateSamplesOrderDelMethod';
import NBK_CreateSamplesOrderDelDate from '@salesforce/label/c.NBK_CreateSamplesOrderDelDate';
import NBK_CreateSamplesOrderPriceBook from '@salesforce/label/c.NBK_CreateSamplesOrderPriceBook';
import NBK_CreateSamplesOrderOrdStatus from '@salesforce/label/c.NBK_CreateSamplesOrderOrdStatus';
import NBK_CreateSamplesOrderDelStatus from '@salesforce/label/c.NBK_CreateSamplesOrderDelStatus';

export default class NBK_CreateSamplesOrder extends NavigationMixin(LightningElement) {
    
    labels = {
        NBK_CreateSamplesOrderTitle,
        NBK_CreateSamplesOrderAccName,
        NBK_CreateSamplesOrderCustRef,
        NBK_CreateSamplesOrderOrderDate,
        NBK_CreateSamplesOrderDelMethod,
        NBK_CreateSamplesOrderDelDate,
        NBK_CreateSamplesOrderPriceBook,
        NBK_CreateSamplesOrderOrdStatus,
        NBK_CreateSamplesOrderDelStatus
    }

    @api recordId;
    @api objectApiName;

    opportunityId;
    opportunityName;
    ownerName;
    accountId;
    accountSAPId;
    accountName;
    currencyIsoCode;
    pricebookName;
    pricebookId;
    orderDate;
    autopick;

    deliveryOptions;
    deliveryWarning;
    //lblDeliveryWarning = "To secure delivery on &1 please ensure that the order is posted before &2 (warehouse time).";
    lblDeliveryWarning = "Cut-off time to secure delivery on &1 is &2 (warehouse time).";
    lblTime = '&1&2';
    lblToday = 'today';
    lblTomorrow = 'tomorrow';
    lblNextDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    customerReference;
    deliveryDate;
    objectInfo;
    recordTypeSamples;
    orderStatusSel;
    optionsOrderStatus;
    optionsDeliveryMethod;
    deliveryMethodSel = '3';
    optionsDeliveryStatus;
    deliveryStatusSel;
    showContactPointAddress = true;
    showPickupAddress = false;
    recordTypeOrder;
    hasPermissions = false;    

    showSpinner = true;

    optionsSalesRelationShip;
    salesOrgDisabled = false;
    salesOrgSelected;
    salesOrgId;
    salesRelationShip;
    debugText;
    orderId = null;
    orderNumber = null;
    sapOrderNumber = null;

    // Address management variables
    // ------------------------------------------------------------
    pickupLabel = 'Pickup Address';
    deliveryLabel = 'Delivery Address';
    showroomLabel = 'Showroom Address';
    pickupAddress={};
    deliveryAddress={};
    showroomAddress={};
    openAddressesDialog = false;
    nextOrdersNumber = 0;

    get FIELDS() {
        const objName = this.objectApiName?.toLowerCase();
        if (objName == 'opportunity') {
            return OPPORTUNITY_FIELDS;
        } else if (objName == 'order') {
            return ORDER_FIELDS;
        } else {
            return [];
        }
    }    

    get windowTitle() {
        if (this.orderNumber != null && this.orderNumber > 0) {
            return 'Samples Order #' + this.orderNumber;
        } else {
            return this.labels.NBK_CreateSamplesOrderTitle;
        }
    }

    get minDeliveryDate() {
        if (this.deliveryOptions) {
            return this.deliveryOptions?.minDeliveryDate?.getDate();
        } else {
            return new Date();
        }
    }

    get addressMode() {
        if (this.deliveryMethodSel == 1 || this.deliveryMethodSel == 2) {
            return 'pickup';
        } else if (this.deliveryMethodSel == 4) {
            return 'showroom';
        } else {
            return 'delivery';
        }
    }

    get addressLabel() {        
        if (this.addressMode == 'delivery') {
            return this.deliveryLabel;
        } else if (this.addressMode == 'pickup') {
            return this.pickupLabel;
        } else {
            return this.showroomLabel;
        }
    }

    get selectedAddress() {
        switch (this.addressMode) {
            case 'showroom':
                return this.showroomAddress;
                break;
            case 'pickup':
                return this.pickupAddress;
                break;
            default:
                return this.deliveryAddress;                    
        }
    }

    get hasAddress() {
        return (this.selectedAddress && Object.keys(this.selectedAddress).length> 0);
    }

    get selectedAddressId() {
        return this.selectedAddress?.Id;
    }

    get isOrderInSAP() {
        return (this.sapOrderNumber!=null && Number(this.sapOrderNumber.length) > 0);
    }

    get isReadonly() {
        return (!this.hasPermissions || this.isOrderInSAP);
    }

    //----------------------------------------------------------------------------------------------

    get samplesRecordTypeId() {
        // Returns a map of record type Ids
        if (this.objectInfo.data && this.objectInfo.data.recordTypeInfos) {
            const rtis = this.objectInfo.data.recordTypeInfos;
            console.log('ESTABLEZCO EL RECORD TYPE SAMPLES ' + (Object.keys(rtis).find((rti) => rtis[rti].name === "Samples")));
            return Object.keys(rtis).find((rti) => rtis[rti].name === "Samples");
        } else {
            console.log('pooues es un undefined');
            return undefined;
        }
    }

    get hasNextOrders() {
        return (!this.isReadonly && this.nextOrdersNumber > 0);
    }

    connectedCallback() {
        this.checkUserPermissionSet();
        //this.orderDate = this.convertDate(new Date());
    }


    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
        objectInfo;   
    
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ORDER_STATUS })
    getOrderStatus({ error, data }) {
        if (data) {
            let status = [];
            data.values.forEach((elem) => {
                this.orderStatusSel = (elem.label == 'Draft') ? elem.value : this.orderStatusSel;
                status.push({
                    label: elem.label,
                    value: elem.value
                });                
            });
            this.optionsOrderStatus = [...status];
        } else if (error) {
            console.error(error);
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$samplesRecordTypeId', fieldApiName: ORDER_DELIVERY_METHOD })
    getDeliveryMethods({ error, data }) {
        if (data) {
            let values = [];
            data.values.forEach((elem) => {
                values.push({
                    label: elem.label,
                    value: elem.value
                });
            });
            this.optionsDeliveryMethod = [...values];
        } else if (error) {
            console.error(error);
        }
    };

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ORDER_DELIVERY_STATUS })
    getDeliveryStatus({ error, data }) {
        if (data) {
            let values = [];
            data.values.forEach((elem) => {
                this.deliveryStatusSel = (elem.label == 'Pending') ? elem.value : this.deliveryStatusSel;
                values.push({
                    label: elem.label,
                    value: elem.value
                });
            });
            this.optionsDeliveryStatus = [...values];
        } else if (error) {
            console.error(error);
        }
    };

    /* -----------------------
     * getRecord
     * ----------------------- */
    @wire(getRecord, { recordId: '$recordId', fields: '$FIELDS' })
    wiredRecord({ error, data }) {    
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (data) {
            if (this.objectApiName.toLowerCase() == 'order') {
                this.setExistingOrderData(data);
            } else {
                this.setNewOrderData(data)
            }
            this.showSpinner = false;
        }
    }

    /* -----------------------------
     * Get delivery date options
     * ----------------------------- */
    @wire(getDeliveryDateOptions, { salesOrg: '$salesOrgId'}) 
    getDDateOption({error, data}) {
        if (data) {
            this.deliveryOptions = new Object();
            this.deliveryOptions.cutoffDateTime = new Date(data.cutoffDateTime);            
            this.deliveryOptions.cutoffTime = data.cutoffTime;            
            this.deliveryOptions.minDeliveryDate = new Date(data.minDeliveryDate + " 0:00:00");
            this.deliveryOptions.minDeliveryDays = data.minDeliveryDays;
            this.deliveryOptions.timeZone = data.timezone;
            this.deliveryOptions.cutoffAdditionalDays =  data.cutoffAdditionalDays;
            this.setDeliveryWarning();
            //const cutoffDT = new Date(this.deliveryOptions.cutoffDateTime);            
            //const myTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            //const myCutoffTime = this.convertDateToTZ(cutoffDT, myTimeZone);
        } else if (error) {
           console.log("Esto es un error en del date *" + this.salesOrgId + "* y " + JSON.stringify(error));
        } 
    }


    /**
     * Assigns data to create a new order
     */
    setNewOrderData(data) {
        this.orderId = null;
        this.orderNumber = 0;
        this.accountSAPId = data.fields?.Account?.value?.fields?.SAP_Id__c?.value;
        this.accountName = data.fields?.Account?.value?.fields?.Name?.value;
        const accountCountry = data.fields?.Account?.value?.fields?.Country_formula__c?.value;
        this.currencyIsoCode = data.fields?.CurrencyIsoCode.value;
        this.accountId = data.fields?.AccountId.value;
        this.opportunityId = data.fields?.Id.value;
        this.opportunityName = data.fields?.Name.value;
        this.ownerName = data.fields?.Owner?.value?.fields?.Name.value;
        this.addressObjectId = this.accountId;        
        this.deliveryMethodSel = '3';
        this.getSamplePricebookByCountryName(accountCountry);
        this.getSalesRelationShipOptions();
        this.getAccountOrders();
        this.setDefaultValues();
    }

    /**
     * Assigns data to edit an existing order
     */
    setExistingOrderData(data) {
        this.orderId = data.fields?.Id.value;
        this.orderNumber = data.fields?.OrderNumber.value;
        this.accountSAPId = data.fields?.Account?.value?.fields?.SAP_Id__c?.value;
        this.accountName = data.fields?.Account?.value?.fields?.Name?.value;
        this.currencyIsoCode = data.fields?.CurrencyIsoCode.value;
        this.accountId = data.fields?.AccountId.value;
        this.opportunityId = data.fields?.OpportunityId.value;
        this.opportunityName = data.fields?.Opportunity.value?.fields?. Name.value;
        this.ownerName = data.fields?.Opportunity.value.fields?.Owner?.value?.fields?.Name.value;
        this.addressObjectId = this.accountId;
        this.pricebookId = data.fields?.Pricebook2Id.vallue;
        this.pricebookName = data.fields?.Pricebook2.value.fields.Name.value;
        this.getSalesRelationShipOptions();
        this.getAccountOrders();
        this.orderDate = data.fields?.EffectiveDate.value;
        this.deliveryDate = data.fields?.DeliveryDate__c.value;
        this.customerReference = data.fields?.NB2B_OrderCode__c.value;
        this.sapOrderNumber = data.fields?.Sap_Id__c?.value;
        this.autopick = data.fields?.Autopick__c?.value;
        let autopickField = this.template.querySelector('[data-element="autopick-checkbox"]');
        autopickField.checked = this.autopick;

        const salesOrg = data.fields?.SalesOrg__c.value;
        const channel = data.fields?.Distribution_channel__c.value;
        this.salesOrgSelected = salesOrg + '-' + channel;
        this.deliveryMethodSel = data.fields?.NB2B_Delivery_Method__c.value;
        const contactAddressId = data.fields?.NBK_Contact_Point_Address__c.value;
        const porsaAddressId = data.fields?.NBK_Warehouse_Address__c.value;

        let addressId = this.accountId;
        if (this.deliveryMethodSel == 3) {
            if (contactAddressId != null) {
                addressId = contactAddressId;
            }
        } else {
            addressId = porsaAddressId;
        }
        this.addressObjectId = addressId;
    }

    setDefaultValues() {
        this.orderDate = this.convertDate(new Date());
        let reference = this.opportunityName;
        if (reference.length > 30) {
            reference = reference.substring(0,30);
        }
        this.customerReference = reference;
        this.autopick = true;
        let autopickField = this.template.querySelector('[data-element="autopick-checkbox"]');
        autopickField.checked = this.autopick;
    }

    setDeliveryWarning() {
        this.deliveryWarning = '';
        if (this.deliveryOptions.cutoffTime != null) {
            let p2 = this.lblTime.replace('&1', this.deliveryOptions.cutoffTime);
            if (this.deliveryOptions.cutoffAdditionalDays == 0) {
                p2 = p2.replace('&2', ' ' + this.lblToday);
            } else if (this.deliveryOptions.cutoffAdditionalDays == 1) {
                p2 = p2.replace('&2', ' ' + this.lblTomorrow);
            } else {
                const numDay = this.deliveryOptions.cutoffDateTime.getDay();
                p2 = p2.replace('&2', ' ' + this.lblNextDays[numDay]);
            }
            const p1 = this.deliveryOptions.minDeliveryDate.toLocaleDateString();
            this.deliveryWarning = this.lblDeliveryWarning.replace('&1', p1);
            this.deliveryWarning = this.deliveryWarning.replace('&2', p2);
        }
    }

    getAccountOrders() {
        this.nextOrdersNumber = 0;
        getNextOrders({ accountSAPId: this.accountSAPId})
            .then((result) => {
                try {
                    this.nextOrdersNumber = result.length;
                } catch(error) {
                    console.log(error);
                }
            });
    }

    getSalesRelationShipOptions() {
        getSalesRelationShip({ accountId: this.accountId })
            .then((result) => {
                this.salesRelationShip = result;
                var options = [];
                result.forEach(o => {
                    var option = { label: o.valueList, value: o.key };
                    options.unshift(option);
                });

                this.optionsSalesRelationShip = options;

                if (options.length == 0) {
                    this.salesOrgDisabled = true;
                } else {
                    this.salesOrgSelected = options[0].value;
                    this.salesOrgId = this.salesOrgSelected.substring(0,3);
                    this.salesOrgDisabled = (options.length == 1);
                }

            })
            .catch((error) => {
                console.log("Error getSalesRelationShip: " + JSON.stringify(error));
            });
    }

    /**
     * Change address button
     */
    handleAddressChange(event) {
        this.openAddressesDialog = true;
    }

    handleAddressCancel(event) {
        this.openAddressesDialog = false;
    }

    handleAddressSelect(event) {
        this.openAddressesDialog = false;
        switch (this.addressMode) {
            case 'showroom':
                this.showroomAddress = event.detail;
                break;
            case 'pickup':
                this.pickupAddress = event.detail; 
                break;
            default:
                this.deliveryAddress = event.detail; 
        }
    }

    handleDeliveryAddressReady(event) {
        this.showSpinner = false;
        if (this.addressMode == 'delivery') {
            this.deliveryAddress = event.detail;
        } if (this.addressMode == 'showroom') {
            this.showroomAddress = event.detail;
        } else if (this.addressMode == 'pickup') {
            this.pickupAddress = event.detail;
        }
    }

    changeValue(event) {
        var name = event.target.name;
        var value = event.target.value;
        switch (name) {
            case 'customerReference':
                this.customerReference = value;
                break;
            case 'deliveryDate':
                this.deliveryDate = value;
                //this.validateDeliveryDate();
                break;
            case 'deliveryMethod':
                this.deliveryMethodSel = value;
                break;
            case 'orderDate':
                this.orderDate = value;
                break;
            case 'salesOrg':
                this.salesOrgSelected = value;
                this.salesOrgId = this.salesOrgSelected.substring(0,3);
                break;
            case 'autopick':
                this.autopick = event.target.checked;
                break;
        }
    }

    handleClose(event) {
        this.closeQuickAction();
        this.dispatchEvent(new CustomEvent('close', {}));
    }

    handleSave(event) {
        if (this.checkValidation()) {
            this.showSpinner = true;    
            if (!this.orderId) {
                this.createRecord();
            } else {
                this.updateRecord();
            }
        }
    }

    /**
     * Sets fiedls for creating an new record
     */
    setRecordNewFields(fields) {  
        var salesOffice;
        var salesOrg;
        var distributionChannel;

        this.salesRelationShip.forEach((s) => {
            if (s.key == this.salesOrgSelected) {
                salesOffice = s.salesOffice;
                salesOrg = s.salesOrg;
                distributionChannel = s.distributionChannel;
            }
        })
    
        fields[ORDER_STATUS.fieldApiName] = this.orderStatusSel;
        fields[ORDER_ACCOUNTID.fieldApiName] = this.accountId;
        fields[ORDER_START_DATE.fieldApiName] = this.formatDate(new Date());
        fields[ORDER_PRICEBOOKID.fieldApiName] = this.pricebookId;
        fields[ORDER_DELIVERY_STATUS.fieldApiName] = this.deliveryStatusSel;
        fields[ORDER_OPPORTUNITYID.fieldApiName] = this.opportunityId;
        fields[ORDER_RECORDTYPEID.fieldApiName] = this.recordTypeOrder;
        fields[ORDER_CURRENCYISOCOD.fieldApiName] = this.currencyIsoCode;
        fields[ORDER_CURRENCY.fieldApiName] = this.currencyIsoCode;
        fields[ORDER_SALES_OFFICE.fieldApiName] = salesOffice;
        fields[ORDER_SALES_ORG.fieldApiName] = salesOrg;
        fields[ORDER_DISTRIBUTION_CHANNEL.fieldApiName] = distributionChannel;        
        fields[ORDER_SAMPLES.fieldApiName] = true; 
        fields[ORDER_RECORDTYPEID.fieldApiName] = this.samplesRecordTypeId;     
    }

    /**
     * Sets fiedls for updating an existing record
     */
    setRecordExistingFields(fields) {      
        if (this.orderId) {
            fields[ORDER_ID.fieldApiName] = this.orderId;
        }    
        fields[ORDER_AUTOPICK.fieldApiName] = this.autopick;
        fields[ORDER_CUSTOMER.fieldApiName] = this.customerReference;
        var dateA = new Date(this.deliveryDate);
        dateA.setHours(new Date().getHours());
        dateA.setMinutes(new Date().getMinutes() + 1);
        fields[ORDER_DELIVERY_DATE.fieldApiName] = this.formatDate(dateA);
        fields[ORDER_DELIVERY_METHOD.fieldApiName] = this.deliveryMethodSel;
                
        fields[ORDER_CONTACTPOINT.fieldApiName] = null;
        fields[ORDER_WAREHOUSE.fieldApiName] = null;

        if (this.deliveryMethodSel == 3) {
            if (this.accountId != this.deliveryAddress.Id) {
                fields[ORDER_CONTACTPOINT.fieldApiName] = this.deliveryAddress.Id;
            }
        } else if (this.deliveryMethodSel == 4) {
            fields[ORDER_WAREHOUSE.fieldApiName] = this.showroomAddress.Id;
        } else {
            fields[ORDER_WAREHOUSE.fieldApiName] = this.pickupAddress.Id;
        }
    }

    createRecord() {        
        const fields = {};
        this.setRecordNewFields(fields);
        this.setRecordExistingFields(fields);
        const recordInput = { apiName: ORDER_OBJECT.objectApiName, fields };

        console.log('ESTOY A PUNTO De CREAR EL PEDIDO CON ESTOS DATOS: ' + JSON.stringify(recordInput));
        createRecord(recordInput)
            .then(order => {
                console.log('PEDIDO CREADO CON ID: ' + JSON.stringify(order));
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Order created !',
                        variant: 'success',
                    }),
                );
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: order.id,
                        objectApiName: 'Order',
                        actionName: 'view'
                    }
                });
                this.closeQuickAction();
            })
            .catch(error => {
                this.showSpinner = false;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message + '.' + error?.body?.output?.fieldErrors?.Status[0]?.message,
                        variant: 'error',
                    }),
                );
            });
    }

    updateRecord() {
        const fields = {};
        this.setRecordExistingFields(fields);
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Order updated !',
                        variant: 'success',
                    }),
                );
                this.closeQuickAction();
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message + '.' + error?.body?.output?.fieldErrors?.Status[0]?.message,
                        variant: 'error',
                    }),
                );
            });
    }

    validateDeliveryDate() {
        let message = '';
        if (this.deliveryDate != null) {
            const dd = new Date(this.deliveryDate);
            if (dd.getDay() == 0 || dd.getDay() == 6) {
                message = 'Deliveries are not permitted on weekends.'
            } else if (dd == this.deliveryOptions.minDeliveryDate) {
                message =  'Ojo a al fecha ';
            } else if (dd < this.deliveryOptions.minDeliveryDate) {
                message = 'Earliest delivery date is ' + this.deliveryOptions.minDeliveryDate.toLocaleDateString();
            }
        }
        return message;
    }

    checkValidation() {
        var OK = true;
        var message;
        if (this.customerReference == null || this.customerReference == '') {
            message = 'A customer reference is required';
            OK = false;
        } else if (this.deliveryMethodSel == null || this.deliveryMethodSel == '') {
            message = 'Please select a delivery method';
            OK = false;
        } else if (this.deliveryDate == null || this.deliveryDate == '') {
            message = 'Please enter a delivery date';
            OK = false;
        } else if (this.salesOrgSelected == null) {
            message = 'Customer does not exist in SAP. Please select or create a sales relationship and try again.';
            OK = false;
        } else if (!this.hasAddress) {
            if ((this.deliveryMethodSel == 1 || this.deliveryMethodSel == 2)) {
                message = 'Please select a pickup address';
                OK = false;
            } else {
                message = 'Please select a delivery address';
                OK = false;
            }
        }

        if (OK) {
            message = this.validateDeliveryDate();
            OK = (message.length == 0);
        }

        if (!OK) {
            const event = new ShowToastEvent({
                title: 'Attention!',
                message: message,
                variant: 'warning'
            });
            this.dispatchEvent(event);
            return false;
        }
        return true;
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    convertDate(date) {
        var yyyy = date.getFullYear().toString();
        var mm = (date.getMonth() + 1).toString();
        var dd = date.getDate().toString();

        var mmChars = mm.split('');
        var ddChars = dd.split('');

        return yyyy + '-' + (mmChars[1] ? mm : "0" + mmChars[0]) + '-' + (ddChars[1] ? dd : "0" + ddChars[0]);
    }

    formatDate(date) {

        let d = date;
        let month = '' + (d.getMonth() + 1);
        let day = '' + d.getDate();
        let year = d.getFullYear();

        if (month.length < 2)
            month = '0' + month;
        if (day.length < 2)
            day = '0' + day;
        return [year, month, day].join('-');
    }

    getSamplePricebookByCountryName(accountCountry) {

        getSamplePricebook({ country: accountCountry })
            .then((result) => {
                this.pricebookName = result.Name;
                this.pricebookId = result.Id;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error fetching samples pricebook',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                this.closeQuickAction();
            });
    }

    checkUserPermissionSet() {
        getUserPermissionSet({}).then((result) => {
            if (result == true) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'You do not have permissions to perform this action. Please contact the administrator',
                        variant: 'warning',
                        mode: 'sticky',
                    }),
                );
            }
            this.hasPermissions = !result;
        }).catch((error) => {
            console.log("Error checkUserPermissionSet: " + JSON.stringify(error));
        });
    }

}