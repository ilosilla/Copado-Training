/**
 * claimSapStatus
 * Ramón Nov 2024
 * 
 * Component to displayn the status of the orders related to a claim
 * 
 * Translation prefix: tr0002
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import { downloadOrder } from 'c/libDownloadSapDocument';
import getOrderStatus from "@salesforce/apex/ClaimSAPStatusController.getOrderStatus"; 

import CASE_ORDER_FIELD from '@salesforce/schema/Case.OrderId__c';
import CASE_COMPENSATION_FIELD from '@salesforce/schema/Case.CompensationOrderId__c';
import CASE_COLLECTION_FIELD from '@salesforce/schema/Case.CollectionOrderId__c';

import ORDER_ID from "@salesforce/schema/Order.Id";
import ORDER_NUMBER_FIELD from "@salesforce/schema/Order.OrderNumber";
import ORDER_SAP_REQUEST_FIELD from "@salesforce/schema/Order.SAPRequestStatus__c";
import ORDER_SAP_ID_FIELD from "@salesforce/schema/Order.Sap_Id__c";
import ORDER_STATUS_FIELD from "@salesforce/schema/Order.Status";


import tr0002_001 from "@salesforce/label/c.tr0002_001";
import tr0002_002 from "@salesforce/label/c.tr0002_002";
import tr0002_003 from "@salesforce/label/c.tr0002_003";
import tr0002_004 from "@salesforce/label/c.tr0002_004";
import dict_sap_status from "@salesforce/label/c.dict_sap_status";
import dict_order_num from "@salesforce/label/c.dict_order_num";
import dict_order_number_label from "@salesforce/label/c.dict_order_number_label";
import dict_not_applicable from "@salesforce/label/c.dict_not_applicable";
import dict_not_sent_yet from "@salesforce/label/c.dict_not_sent_yet";


export default class ClaimSapStatus extends LightningElement {
    
    label = {
        tr0002_001, tr0002_002, tr0002_003, tr0002_004, dict_sap_status, dict_order_num,
        dict_order_number_label, dict_not_applicable, dict_not_sent_yet
    };
    hasChanged = false;

    @api 
        get recordId() { return this._recordId; } 
        set recordId(value) { 
            this._recordId = value;
        } 
    @api 
        get replacementId() { return this._replacementId; }
        set replacementId(value) { 
            this._replacementId = value; 
        }
    @api 
        get compensationId() { return this._compensationId; }
        set compensationId(value) { this._compensationId = value; }
    @api 
        get collectionId() { return this._collectionId; }
        set collectionId(value) { this._collectionId = value; }

    caseError = '';
    _recordId;
    _replacementId;
    _compensationId;
    _collectionId;
    replacementOrder = {};
    compensationOrder = {};
    collectionOrder = {};

    get hasReplacement() {
        return (this.replacementOrder?.orderNumber ?? false);
    }

    get hasCompensation() {
        return (this.compensationOrder.orderNumber);
    }

    get hasCollection() {
        return (this.collectionOrder.orderNumber);
    }

    get showOrderDownload() {
        return (this.replacementOrder.sapId !== null);
    }

    get showCompensationDownload() {
        return (this.compensationOrder.sapId !== null );
    }    

    get showCollectionDownload() {
        return (this.collectionOrder.sapId !== null);
    }  
    
    async readOrderData(data) {
        console.log("Reading order data: \n" + JSON.stringify(data));
        let result = {};
        result.Id = getFieldValue(data, ORDER_ID);
        result.orderNumber = getFieldValue(data, ORDER_NUMBER_FIELD);
        result.sapId = this.normalizeOrderValue(getFieldValue(data, ORDER_SAP_ID_FIELD));
        result.sapRequest = getFieldValue(data, ORDER_SAP_REQUEST_FIELD);
        result.sapRequestLabel = getFieldDisplayValue(data, ORDER_SAP_REQUEST_FIELD);
        result.orderStatus = getFieldValue(data, ORDER_STATUS_FIELD);
        result.orderStatusLabel = getFieldDisplayValue(data, ORDER_STATUS_FIELD);
        result.sapRequestId = null;
        result.sapMessage = null;
        console.log("En el readOrder " + result.sapValue);
        await this.setSAPValue(result);
        console.log("En el readOrder2 " + result.sapValue);
        return result;
    }

    async setSAPValue(orderData) {
        if (orderData.sapId) {
            orderData.sapValue = this.label.dict_order_num.replace('{0}', orderData.sapId);
        } else if (orderData.sapRequest) {
            orderData.sapValue = orderData.sapRequestLabel;            
            if (orderData.sapRequest.toLowerCase() === 'queued') {
                console.log("En el setSAPValue " + orderData.sapValue);
                await this.readSAPRequest(orderData);
                console.log("En el setSAPValue 2 " + orderData.sapValue);
            }
        } else {
            orderData.sapValue = orderData.orderStatus;
            if (orderData.orderStatus?.toLowerCase() === 'draft') {
                orderData.sapValue += ' (' + this.label.dict_not_sent_yet + ')';
            } else {
                orderData.sapValue = orderData.orderStatusLabel;
            }
        }
    }

    async readSAPRequest(orderData) {
        try {
            const data = await getOrderStatus({orderId : orderData.Id});
            orderData.sapRequestId = data.requestId;
            orderData.sapValue = data.requestStatusLabel;
            if (data.hasError) {
                orderData.sapMessage = data.errorMessage;
            }   
            console.log("El replacementORder es " + orderData.sapValue);         
        } catch (ex) {
            console.error(JSON.stringify(ex));
        }   
    }

    normalizeOrderValue(value) {
        return value === '--' ? null : value;
    }

    handleDownloadReplacement() {
        const field = this.template.querySelector('[data-id="replacement-status"]');
        field?.isLoading(true);   
        downloadOrder(this.replacementOrder.sapId, this.callbackFunction, field);
    }

    handleDownloadCompensation() {
        const field = this.template.querySelector('[data-id="compensation-status"]');
        field?.isLoading(true);
        downloadOrder(this.compensationOrder.sapId, this.callbackFunction, field);
    }

    handleDownloadCollection() {
        const field = this.template.querySelector('[data-id="collection-status"]');
        field?.isLoading(true);
        downloadOrder(this.collectionOrder.sapId, this.callbackFunction, field);
    }

    callbackFunction(field) {
        field?.isLoading(false);
    }
        
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [CASE_ORDER_FIELD, CASE_COMPENSATION_FIELD, CASE_COLLECTION_FIELD]
    }) wiredCase({ error, data }) {
        if (data) {
            console.log('Data received ' + JSON.stringify(data));
            this._replacementId = getFieldValue(data, CASE_ORDER_FIELD);
            this._compensationId = getFieldValue(data, CASE_COMPENSATION_FIELD);                   
            this._collectionId = getFieldValue(data, CASE_COLLECTION_FIELD);                   
        } else if (error) {
            this.caseError = 'Error reading the case details';
            console.error('---> Error reading the case:' + error + ' *** ' + JSON.stringify(error)); 
        }
    }

    @wire(getRecord, {
        recordId: "$replacementId",
        fields: [ORDER_ID, ORDER_NUMBER_FIELD, ORDER_SAP_ID_FIELD, ORDER_SAP_REQUEST_FIELD, ORDER_STATUS_FIELD]
    }) async setReplacementOrderData({ error, data }) {
        if (data) {
            console.log("Antes de la llamada");
            this.replacementOrder = await this.readOrderData(data);
            console.log("Despues de la llamada " + this.replacementOrder.sapValue);
        } else if (error) {
            console.error('Error reading replacement Order: ' + error);
        }
    }

    @wire(getRecord, {
        recordId: "$compensationId",
        fields: [ORDER_ID, ORDER_NUMBER_FIELD, ORDER_SAP_ID_FIELD, ORDER_SAP_REQUEST_FIELD, ORDER_STATUS_FIELD]
    }) async setCompensationOrderData({ error, data }) {
        if (data) {
            this.compensationOrder = await this.readOrderData(data);
        } else if (error) {
            console.error('Error reading compensation Order: ' + error);
        }
    }

    @wire(getRecord, {
        recordId: "$collectionId",
        fields: [ORDER_ID, ORDER_NUMBER_FIELD, ORDER_SAP_ID_FIELD, ORDER_SAP_REQUEST_FIELD, ORDER_STATUS_FIELD]
    }) async setCollectionOrderData({ error, data }) {
        if (data) {
            this.collectionOrder = await this.readOrderData(data);
        } else if (error) {
            console.error('Error reading collection Order: ' + error);
        }
    }


}