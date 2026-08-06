import { LightningElement, wire, track } from 'lwc';

import getData from "@salesforce/apex/OppPriceRequestComponentController.getFactoryHistoricData";

import exportLabel from '@salesforce/label/c.dict_export_data';
import exportDescriptionLabel from '@salesforce/label/c.prequest_export_description';
import showingLabel from '@salesforce/label/c.dict_showing';
import totalRecordsLabel from '@salesforce/label/c.dict_total_records';
import prequest_reference_price from '@salesforce/label/c.prequest_reference_price';
import prequest_factory_price from '@salesforce/label/c.prequest_factory_price';
import 	prequest_approve_code from '@salesforce/label/c.prequest_approve_code';
import prequest_approved_price from '@salesforce/label/c.prequest_approved_price';
import prequest_price_needed from '@salesforce/label/c.prequest_price_needed';
import dict_opportunity from '@salesforce/label/c.dict_opportunity';
import dict_quantity from '@salesforce/label/c.dict_quantity';
import dict_status from '@salesforce/label/c.dict_status';
import dict_unit from '@salesforce/label/c.dict_unit';
import dict_product from '@salesforce/label/c.dict_product';
import dict_approver from '@salesforce/label/c.dict_approver';
import dict_Reviewed from '@salesforce/label/c.dict_reviewed';
import dict_search from '@salesforce/label/c.dict_search';
import dict_created from '@salesforce/label/c.dict_created';

const customLabel = {
    exportLabel,
    exportDescriptionLabel,
    showingLabel,
    totalRecordsLabel,
    prequest_reference_price,
    prequest_factory_price,
    prequest_approve_code,
    prequest_approved_price,
    prequest_price_needed,
    dict_opportunity,
    dict_product,
    dict_quantity,
    dict_status,
    dict_unit,
    dict_approver,
    dict_Reviewed,
    dict_search,
    dict_created
};

const columns = [
    { label: customLabel.dict_opportunity, fieldName: 'Link', type: 'url', typeAttributes: { label: { fieldName: 'OpportunityName' } }, },
    { label: customLabel.dict_product, fieldName: 'Product' },
    { label: customLabel.dict_quantity, fieldName: 'Quantity', type: 'number', menuAlignment: 'center' },
    { label: customLabel.prequest_reference_price, fieldName: 'ReferencePrice', type: 'currency' },
    { label: customLabel.prequest_factory_price, fieldName: 'CustomerPrice', type: 'currency' },
    { label: customLabel.prequest_price_needed, fieldName: 'PriceNeeded', type: 'currency' },
    { label: customLabel.prequest_approved_price, fieldName: 'ApprovedPrice', type: 'currency' },
    { label: customLabel.dict_created, fieldName: 'CreatedBy'},
    { label: customLabel.dict_approver, fieldName: 'Approver' },
    { label: customLabel.dict_status, fieldName: 'Status' },
    { label: customLabel.prequest_approve_code, fieldName: 'ApproveCode' },
    { label: customLabel.dict_Reviewed, fieldName: 'Reviewed', type: 'date' },
];

export default class OppPriceRequestHistoric extends LightningElement {
    @track searchString;
    @track historicData;
    @track initialHistoricData;
    // JS Properties 
    pageSizeOptions = [ 25, 50, 75, 100]; //Page size options
    historicData = [];
    initialHistoricData = [];
    columns = []; //columns information available in the data table
    totalRecords = 0; //Total no.of records
    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    label=customLabel;

    columnHeader = [customLabel.dict_opportunity, customLabel.dict_product, customLabel.dict_quantity, customLabel.prequest_reference_price,
                    customLabel.prequest_factory_price,customLabel.prequest_price_needed, customLabel.prequest_approved_price,
                    customLabel.dict_unit,customLabel.dict_approver, customLabel.dict_status, customLabel.prequest_approve_code, customLabel.dict_Reviewed ]

    columns = columns;
    showSpinner = false;

    get componentReady() {
        return this.initialHistoricData.length > 0;
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    @wire(getData) historicData({data,error}){
        if (data) {
            let result = [];
            data.forEach((elem) => {
                var newElem = {
                    Product: elem.ProductCodeFormula__c + '-' + elem.ProductName__c,
                    Link: elem.PriceRequestHeader__r.Opportunity__r.Link_a_Oportunidad_ANA__c,
                    Quantity: elem.Quantity__c,
                    ReferencePrice: elem.ReferencePrice__c,
                    CustomerPrice: elem.Price__c,
                    UnitOfPrice: elem.UnitOfPrice__c,
                    PriceNeeded: elem.PriceNeeded__c,
                    ApprovedPrice: elem.ApprovedPrice__c,
                    OpportunityName: elem.PriceRequestHeader__r.Opportunity__r.Name,
                    Approver: elem.Approver__r != null ? elem.Approver__r.Name : '',
                    Status: elem.Status__c,
                    ApproveCode: elem.PriceRequestHeader__r.ApproveCode__c,
                    Reviewed: elem.ReviewedDate__c,
                    CreatedBy: elem.CreatedBy.Name
                }
                result.push(newElem);
            });
            this.historicData = result;
            this.initialHistoricData = result;
            this.totalRecords = result.length; // update total records count                 
            this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
            this.paginationHelper();
        } else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        this.showSpinner = true;
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }
    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.historicData[i]);
        }
    }

    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
 
        if (searchKey) {
            this.historicData = this.initialHistoricData;
 
            if (this.historicData) {
                let searchRecords = [];
 
                for (let record of this.historicData) {
                    let valuesArray = Object.values(record);
 
                    for (let val of valuesArray) {
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
                this.historicData = searchRecords;
                this.totalRecords = searchRecords.length; // update total records count                 
                this.paginationHelper();
            }
        } else {
            this.historicData = this.initialHistoricData;
        }
    }

    exportContactData(){
        // Prepare a html table
        let doc = '<table>';
        // Add styles for the table
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';          
        doc += '</style>';
        // Add all the Table Headers
        doc += '<tr>';
        this.columnHeader.forEach(element => {            
            doc += '<th>'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.historicData.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.Link+'</th>'; 
            doc += '<th>'+record.Product+'</th>'; 
            doc += '<th>'+record.Quantity+'</th>';
            doc += '<th>'+record.ReferencePrice+'</th>';
            doc += '<th>'+record.CustomerPrice+'</th>'; 
            doc += '<th>'+record.PriceNeeded+'</th>'; 
            doc += '<th>'+record.ApprovedPrice+'</th>'; 
            doc += '<th>'+record.UnitOfPrice+'</th>'; 
            doc += '<th>'+record.Approver+'</th>'; 
            doc += '<th>'+record.Status+'</th>'; 
            doc += '<th>'+record.ApproveCode+'</th>'; 
            doc += '<th>'+record.Reviewed+'</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Contact Data.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

}