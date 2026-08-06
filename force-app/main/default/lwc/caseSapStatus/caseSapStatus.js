/**
 * Collection Status
 * Ramon 2024-2025
 * 
 * Prefix: tr0002
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { downloadOrder, downloadInvoice, downloadDeliveryNote } from 'c/libDownloadSapDocument';
import { getRecord } from 'lightning/uiRecordApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import CASE_SAPORDERNUMBER_FIELD from '@salesforce/schema/Case.SAPOrderNumber__c';
import CASE_SAPDELIVERYNUMBER_FIELD from '@salesforce/schema/Case.SAPDeliveryNumber__c';
import CASE_SAPDELIVERYSTATUS_FIELD from '@salesforce/schema/Case.SAPDeliveryStatus__c';
import CASE_SAPCREDITNOTE_FIELD from '@salesforce/schema/Case.SAPCreditNote__c';
import CASE_SAPGOODSPOSTED_FIELD from '@salesforce/schema/Case.SAPGoodsPosted__c';

import tr0002_005 from '@salesforce/label/c.tr0002_005';
import dict_creditNote from '@salesforce/label/c.dict_creditNote';
import dict_returns_order from "@salesforce/label/c.dict_returns_order";
import dict_delivery_note from "@salesforce/label/c.dict_delivery_note";
import dict_delivery_status from "@salesforce/label/c.dict_delivery_status";
import tr0002_006 from "@salesforce/label/c.tr0002_006";
import dict_goods_received from "@salesforce/label/c.dict_goods_received";

export default class CaseSapStatus extends LightningElement {
    
    @api recordId;
    @api returnsOrder;
    @api deliveryNote;
    @api deliveryStatus;
    @api goodsPosted;
    @api creditNote;

    labels = {tr0002_005, dict_creditNote, dict_returns_order, dict_delivery_note, dict_delivery_status, tr0002_006, dict_goods_received}

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_SAPORDERNUMBER_FIELD, CASE_SAPDELIVERYNUMBER_FIELD, CASE_SAPDELIVERYSTATUS_FIELD, CASE_SAPCREDITNOTE_FIELD, CASE_SAPGOODSPOSTED_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.returnsOrder = getFieldValue(data, CASE_SAPORDERNUMBER_FIELD);
            this.deliveryNote = getFieldValue(data, CASE_SAPDELIVERYNUMBER_FIELD);
            this.deliveryStatus = getFieldValue(data, CASE_SAPDELIVERYSTATUS_FIELD);
            this.creditNote = getFieldValue(data, CASE_SAPCREDITNOTE_FIELD);
            this.goodsPosted = getFieldValue(data, CASE_SAPGOODSPOSTED_FIELD);
        }
    }

    get name() {
        return this.record.fields.Name.value;
    }
    isLoading = false;
    get isCaseInSAP() { return (this.returnsOrder);}
    get currentStatus() {
        if (this.goodsPosted) {
            return this.labels.dict_goods_received.toUpperCase();
        }
        return this.deliveryStatus;
    }

    get showDeliveryInfo() {
        return (this.deliveryNote != null && this.creditNote == null);
    }

    handleDownloadOrder(event) {
        const field = this.template.querySelector('[data-id="returnsOrderField"]');
        field.isLoading(true);
        downloadOrder(this.returnsOrder, this.callbackFunction, field);
    }

    handleDownloadCredit(event) {
        const field = this.template.querySelector('[data-id="creditNoteField"]');
        field.isLoading(true);
        downloadInvoice(this.creditNote, this.callbackFunction, field);
    }

    handleDownloadDelivery(event) {
        const field = this.template.querySelector('[data-id="deliveryNoteField"]');
        field.isLoading(true);
        downloadDeliveryNote(this.deliveryNote, this.callbackFunction, field);
    }

    callbackFunction(field) {
        field.isLoading(false);
    }
}