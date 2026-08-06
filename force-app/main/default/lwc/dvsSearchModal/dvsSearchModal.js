import { LightningElement, api, track, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import Id from '@salesforce/user/Id';

import getCompanies from '@salesforce/apex/DvsService.getCompanies';
import applyChanges from '@salesforce/apex/DvsService.applyChanges';
import confirmData from '@salesforce/apex/DvsService.confirmData';
import getDiscrepancy from '@salesforce/apex/DvsService.getDiscrepancy';
import getObjectApiName from '@salesforce/apex/DvsService.getObjectApiName';
import confirmNoResults from '@salesforce/apex/DvsService.confirmNoResults';
import getAccountDvsData from '@salesforce/apex/DvsService.accountDvsData';
import getUserCanConfirm from '@salesforce/apex/DvsService.isAccounting';
import getDvsEnabled from '@salesforce/apex/DvsService.isDvsEnabled';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import dvsConfirmMessage from '@salesforce/label/c.dvs_confirm_discard';
import dvsSearchResult from '@salesforce/label/c.dict_search_results';
import componentTitle from '@salesforce/label/c.dvs_search_company';
import confirmChanges from '@salesforce/label/c.dvs_confirm_changes';
import applyChangesLabel from '@salesforce/label/c.dvs_apply_changes';
import dvsConfirmNoResultsMessage from '@salesforce/label/c.dvs_confirm_no_results';
import discardChanges from '@salesforce/label/c.dvs_discard_changes';
import searchBy from '@salesforce/label/c.dict_search_by';
import name from '@salesforce/label/c.dict_name';
import city from '@salesforce/label/c.dict_city';
import postcode from '@salesforce/label/c.dict_postal_code';
import fuzzySearch from '@salesforce/label/c.dvs_fuzzy_search';
import newSearch from '@salesforce/label/c.dict_new_search';
import search from '@salesforce/label/c.dict_search';
import confirm from '@salesforce/label/c.dict_confirm';
import existingData from '@salesforce/label/c.dict_existing_data';
import officialData from '@salesforce/label/c.dict_official_data';
import confirmDataLabel from '@salesforce/label/c.dict_confirm_data';
import keepExistingData from '@salesforce/label/c.dict_keep_data';
import keepOfficialData from '@salesforce/label/c.dvs_apply_official';
import dvsStatusMessage from '@salesforce/label/c.dvs_status_message';
import noData from '@salesforce/label/c.dict_no_data';
import discardMessage from '@salesforce/label/c.dvs_confirm_discard_message';
import requestConfirmation from '@salesforce/label/c.dvs_request_confirmation';
import discardedLabel from '@salesforce/label/c.dict_discarded';
import unknownLabel from '@salesforce/label/c.dvs_no_results_found';
import confirmedLabel from '@salesforce/label/c.dict_confirmed';
import noResultsConfirmed from '@salesforce/label/c.dvs_no_results_confirmed';
import dvsEnabledLabel from '@salesforce/label/c.dvs_not_enabled';
import dvsCheckDataLabel from '@salesforce/label/c.dvs_check_info';

export default class inseeSearchForm extends LightningElement {
    userId = Id;

    @track byId = true;
    @track byName = false;
    @track hasResult = false;
    @track result = {};
    @track selectedCompany = {};
    @track currentAccount = {};
    @track accountdDvsData = {};
    @track userCanConfirm = false;
    @track errorMsg = null;
    @track parameters = {};
    @track accountResult = null;
    @track isNameDifferent = false;
    @track isIdDifferent = false;
    @track isId2Different = false;
    @track isAddressDifferent = false;
    @track perfectMatch;
    @track nameLabel;
    @track id1Label;
    @track id2Label;
    @track addressLabel;
    @track streetLabel;
    @track postalCodeLabel;
    @track cityLabel;
    @track searchByIdLabel;
    @track resultsArray = [];
    @track discrepancyOutput;
    @track waitingForResult = false;
    @track dvsEnabled = false;

    _recordId;
    @api hideUpdateButton;
    @api companyNameResult = null;
    @api companyStreetResult = null;
    @api companyPostalCodeResult = null;
    @api companyCityResult = null;
    @api companyId1Result = null;
    @api companyId2Result = null;
    @api companyNameCurrent = null;
    @api companyStreetCurrent = null;
    @api companyPostalCodeCurrent = null;
    @api companyCityCurrent = null;
    @api companyId1Current = null;
    @api companyId2Current = null;
    @api fuzzySearch = false;
    @api currentAccount = {};
    @api discrepancyFound;
    @api fieldLabels;
    @api searchStatus;
    @api storeRecordId;
    @api objectName;
    @api idNumberValue;;

    label = {
        dvsConfirmMessage,
        dvsSearchResult,
        componentTitle,
        confirmChanges,
        discardChanges,
        searchBy,
        name,
        city,
        postcode,
        fuzzySearch,
        newSearch,
        search,
        confirm,
        applyChangesLabel,
        existingData,
        officialData,
        confirmDataLabel,
        keepExistingData,
        keepOfficialData,
        dvsStatusMessage,
        noData,
        discardMessage,
        requestConfirmation,
        discardedLabel,
        unknownLabel,
        confirmedLabel,
        noResultsConfirmed,
        dvsEnabledLabel,
        dvsCheckDataLabel
    };

    pStyle = 'slds-truncate';

    @api defineDiscrepancyStyle(isDifferent) {
        let discrepancyStyle = this.pStyle;
        if (isDifferent) {
            discrepancyStyle += ' discrepancy-highlight';
        }
        return discrepancyStyle;
    }

    get upperExistingData() {
        return this.label.existingData.toUpperCase();
    }

    get upperOfficialData() {
        return this.label.officialData.toUpperCase();
    }

    get textResults() {
        return (this.label.dvsSearchResult + ': ' + this.numberResults).toUpperCase();
    }

    get checkDataText() {
        return this.label.dvsCheckDataLabel.toUpperCase();
    }

    get statusMessage() {
        var result = '';
        if (this.accountdDvsData.DVSAction__c != null) {
            var result = this.label.dvsStatusMessage;
            switch(this.accountdDvsData.DVSAction__c) {
                case 'DISCARDED':
                    result = result.replace('{0}', this.label.discardedLabel);
                  break;
                case 'ACCEPTED':
                    result = result.replace('{0}', this.label.confirmedLabel);
                  break;
                case 'UNKNOWN':
                    result = result.replace('{0}', this.label.noResultsConfirmed);
                  break;
                default:
                    result = result.replace('{0}', this.label.confirmedLabel);
            }
            result = result.replace('{1}', this.accountdDvsData.DVSAcceptedBy__r.Name);
        }

        return result;
    }

    get labelStyle() {
        let discrepancyStyle = this.pStyle;
        if (this.isNameDifferent) {
            discrepancyStyle += ' discrepancy-highlight';
        }
        return discrepancyStyle;
    }

    get idStyle() {
        let discrepancyStyle = this.pStyle;
        if (this.isIdDifferent) {
            discrepancyStyle += ' discrepancy-highlight';
        }
        return discrepancyStyle;
    }

    get notWaitingForResult() {
        return !this.waitingForResult;
    }

    get otherIdStyle() {
        let discrepancyStyle = this.pStyle;
        if (this.isId2Different) {
            discrepancyStyle += ' discrepancy-highlight';
        }
        return discrepancyStyle;
    }

    get addressStyle() {
        let discrepancyStyle = this.pStyle;
        if (this.isAddressDifferent) {
            discrepancyStyle += ' discrepancy-highlight';
        }
        return discrepancyStyle;
    }

    get numberResults() {
        return this.resultsArray.length;
    }

    get actionLabel() {
        var result = '';
        if (this.dvsDiscarded) {
            result = this.label.discardedLabel;
        }
        if (this.dvsConfirmed) {
            result = this.label.confirmedLabel;
        }
        if (this.dvsNoResults) {
            result = this.label.unknownLabel;
        }
    }

    get dvsAction() {
        return this.accountdDvsData.DVSAction__c;
    }

    get dvsManaged() {
        return this.accountdDvsData.DVSAction__c != null;
    }

    get needsConfirmation() {
        return this.dvsDiscarded || this.dvsNoResults;
    }

    get accountOnSAP() {
        return this.accountdDvsData.Sap_Id__c != '';
    }

    get dvsDiscarded() {
        return this.accountdDvsData.DVSAction__c == 'DISCARDED';
    }

    get dvsNotDiscarded() {
        return this.accountdDvsData.DVSAction__c != 'DISCARDED';
    }

    get dvsConfirmed() {
        return this.accountdDvsData.DVSAction__c == 'CONFIRMED';
    }

    get dvsNotConfirmed() {
        return this.accountdDvsData.DVSAction__c != 'CONFIRMED';
    }

    get dvsAccepted() {
        return this.accountdDvsData.DVSAction__c == 'ACCEPTED';
    }

    get dvsNoResults() {
        return this.accountdDvsData.DVSAction__c == 'UNKNOWN';
    }

    @api set recordId(value) {
        if (value !== this._recordId) {
            this._recordId = value;
            console.log('this.recordId' + this._recordId);
        }
    }

    get recordId() {
        return this._recordId;
    }

    get hasMultipleResults() {
        return this.resultsArray.length;
    }

    @wire(getAccountDvsData, { recordId: '$_recordId'})
    wiredAccount({error, data}) {
        if (data) {
            this.accountdDvsData = data;
        }
    }

    @wire(getDvsEnabled, { recordId: '$_recordId'})
    wiredDvsEnabled({error, data}) {
        if (data) {
            this.dvsEnabled = data;
        }
    }

    @wire(getUserCanConfirm, { recordId: '$_recordId'})
    wiredCanConfirm({error, data}) {
        if (data) {
            this.userCanConfirm = data;
        }
    }

    @wire(getObjectApiName, { recordId: '$_recordId'})
    wiredApiName({error, data}) {
        if (data) {
            this.objectName = data;
            this.storeRecordId = this._recordId;
            getDiscrepancy({id: this.storeRecordId, objectName: this.objectName})
            .then((response) => {
                if(response.singleSearchSociety != null) {
                    this.discrepancyFound = true;
                }
                this.selectedCompany = response.singleSearchSociety;
                this.currentAccount = response.currentAccount;
                this.fieldLabels = response.fieldLabels;
                this.searchStatus = response.searchStatus;
                this.storeRecordId = response.accountId;
        
                this.getFieldsLabels(this.fieldLabels);

                this.fillOutputVariables(this.selectedCompany, this.currentAccount);

                this.parameters['name'] = this.currentAccount[this.nameLabel];
                this.parameters['city'] = this.currentAccount[this.cityLabel];
                this.parameters['postalCode'] = this.currentAccount[this.postalCodeLabel];
                this.parameters['idNumber'] = this.currentAccount[this.id1Label];

                if (this.discrepancyFound) {
                    this.discrepancyOutput = this.selectedCompany[this.nameLabel];
                    if (this.selectedCompany[this.id1Label] != null) {
                        this.discrepancyOutput += ' (' + this.selectedCompany[this.id1Label] + ')';
                    }
                    this.discrepancyOutput += ' - ' + this.selectedCompany[this.streetLabel] + ', ' + this.selectedCompany[this.postalCodeLabel] + ' ' + this.selectedCompany[this.cityLabel];
                }

                if (this.currentAccount[this.id1Label] != null) {
                    this.onSearchClick();
                }
            });
        }
        else if (error) {
            console.log(error);
        }
    }

    onSearchTypeChange(event) {
        const field = event.target.value;
        this.byId = (field == "ID");
        this.byName = !this.byId;
    }

    onParamChange(event) {
        var paramName = event.target.name;
        console.log(paramName);
        var paramValue;
        if (paramName.endsWith("_bool")) {
            paramValue = event.target.checked;
            paramName = paramName.replace("_bool", "");
        } else {
            paramValue = event.target.value;
        }
        this.parameters[paramName] = paramValue;
    }

    handleCheckbox(event) {
        console.log(event.target);
        this.fuzzySearch = event.target.checked;
        var paramName = event.target.name;
        console.log('paramName: ' + paramName);
        var paramValue = this.fuzzySearch;
        console.log('paramValue: ' + paramValue);
        this.parameters[paramName] = paramValue;
    }

    compareValues(valueA, valueB ) {
        if (valueA != valueB) {
            return true;
        } else {
            return false;
        }
    }

    closeComponent() {
        const event = new CustomEvent('closecomponent', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(event);
    }

    fillOutputVariables(companyFound, currentAccount) {

        if (currentAccount != null) {
            this.companyNameCurrent = currentAccount[this.nameLabel];
            this.companyStreetCurrent = currentAccount[this.streetLabel];
            this.companyPostalCodeCurrent = currentAccount[this.postalCodeLabel];
            this.companyCityCurrent = currentAccount[this.cityLabel];
            this.companyId1Current = currentAccount[this.id1Label];
            this.companyId2Current = currentAccount[this.id2Label];
            this.idNumberValue = currentAccount[this.id1Label] != null ? currentAccount[this.id1Label] : currentAccount[this.id2Label];
        }

        if (companyFound == null) {
            this.companyNameResult = null;
            this.companyAddressResult = null;
            this.companyId1Result = null;
            this.companyId2Result = null;
        } else {
            this.companyNameResult = companyFound[this.nameLabel];
            this.companyStreetResult = companyFound[this.streetLabel];
            this.companyPostalCodeResult = companyFound[this.postalCodeLabel];
            this.companyCityResult = companyFound[this.cityLabel];
            this.companyId1Result = companyFound[this.id1Label];
            this.companyId2Result = companyFound[this.id2Label];

            this.isNameDifferent = this.compareValues(this.companyNameResult,this.companyNameCurrent);
            this.isIdDifferent = this.compareValues(this.companyId1Result, this.companyId1Current);
            this.isId2Different = this.compareValues(this.companyId2Result, this.companyId2Current);
            this.isAddressDifferent = (this.compareValues(this.companyStreetResult, this.companyStreetCurrent)) || (this.compareValues(this.companyPostalCodeResult, this.companyPostalCodeCurrent)) || (this.compareValues(this.companyCityResult, this.companyCityCurrent));

            if (this.isNameDifferent || this.isIdDifferent || this.isId2Different || this.isAddressDifferent) {
                this.perfectMatch = false;
            } else {
                this.perfectMatch = true;
            }
        }
    }

    onSearchClick(event) {
        this.waitingForResult = true;
        console.log('waiting for result: ' + this.waitingForResult);
        this.parameters['id'] = this.storeRecordId;
        const searchParams = Object.assign({}, this.parameters);
        if (!this.byId) {
            searchParams.idNumber = null;
        }
        getCompanies({input: searchParams, fuzzySearch: this.fuzzySearch})
        .then( (response) => {
            this.waitingForResult = false;
            this.result = response;
            if (response.singleSearchSocieties == null || response.singleSearchSocieties.length == 0) {

                this.errorMsg = response.message;
            }
        })
        .catch( (error) => {
            this.waitingForResult = false;
            this.errorMsg = error.body.message;
        }).finally(()=> {
            this.hasResult = true;

            if (this.result.singleSearchSocieties == null || this.result.singleSearchSocieties.length == 0) {
                this.waitingForResult = false;
                this.selectedCompany = {};
                this.fillOutputVariables(null, null);
            } else {
                for (let key in this.result.singleSearchSocieties) {
                    this.resultsArray.push({name: this.result.singleSearchSocieties[key][this.nameLabel], id1: this.result.singleSearchSocieties[key][this.id1Label], street: this.result.singleSearchSocieties[key][this.streetLabel], postalCode: this.result.singleSearchSocieties[key][this.postalCodeLabel], city: this.result.singleSearchSocieties[key][this.cityLabel]});
                }
                this.selectedCompany = this.result.singleSearchSocieties[0];
                this.currentAccount = this.result.currentAccount;

                this.fillOutputVariables(this.selectedCompany, this.currentAccount);
                

                this.hideUpdateButton = false;
            }
        });
    }

    onCompanySelected(event) {
        if (this.result) {
            this.selectedCompany = this.result.singleSearchSocieties[event.target.value];
            this.fillOutputVariables(this.selectedCompany, this.currentAccount);
        }
    }

    onPreviousClicked(event) {
        this.resultsArray = [];
        if (this.accountResult != null) {
            this.accountResult = null;
        } else {
            this.hasResult = false;
            this.discrepancyFound = false;
        }

        this.parameters['name'] = this.currentAccount[this.nameLabel];
        this.parameters['city'] = this.currentAccount[this.cityLabel];
        this.parameters['postalCode'] = this.currentAccount[this.postalCodeLabel];
        this.parameters['fuzzySearch'] = this.fuzzySearch;
        this.parameters['idNumber'] = this.currentAccount[this.id1Label];
        console.log(this.parameters);
    }

    onConfirmData(event) {
        this.hasResult = false;
        this.waitingForResult = true;
        confirmData({accountId: this.storeRecordId})
        .then( (response) => {
            this.accountResult = response;
            if (response.success) {
                if (this.objectName == 'Account') {
                    this.navigateToRecord();
                } else {
                    this.navigateToDvsList();
                }
            } else {
                this.showToast(response.message, 'error');
            }
        })
        .catch( (error) => {
            console.log(error);
            console.info("error: " + error.body.message);
        });
    }

    onApplyChanges(event) {
        this.hasResult = false;
        this.waitingForResult = true;
        applyChanges({company: this.selectedCompany, accountId: this.storeRecordId, discardChanges : false})
        .then( (response) => {
            this.accountResult = response;
            if (response.success) {
                if (this.objectName == 'Account') {
                    this.navigateToRecord();
                } else {
                    this.navigateToDvsList();
                }
            } else {
                this.showToast(response.message, 'error');
            }
        })
        .catch( (error) => {
            console.log(error);
            console.info("error: " + error.body.message);
        });
    }

    onConfirmNoResults(event) {
        this.hasResult = false;
        this.waitingForResult = true;
        confirmNoResults({accountId: this.storeRecordId})
        .then( (response) => {
            this.accountResult = response;
            console.log(response);
            if (response.success) {
                if (this.objectName == 'Account') {
                    this.navigateToRecord();
                } else {
                    this.navigateToDvsList();
                }
            } else {
                this.showToast(response.message, 'error');
            }
        })
        .catch( (error) => {
            console.log(error);
            console.info("error: " + error.body.message);
        });
    }

    onDiscardChanges(event) {
        this.hasResult = false;
        this.waitingForResult = true;
        applyChanges({company: this.selectedCompany, accountId: this.storeRecordId, discardChanges : true})
        .then( (response) => {
            this.accountResult = response;
            if (response.success) {
                if (this.objectName == 'Account') {
                    this.navigateToRecord();
                } else {
                    this.navigateToDvsList();
                }
            } else {
                this.showToast(response.message, 'error');
            }

        })
        .catch( (error) => {
            console.info("error: " + error.body.message);
        });
    }

    async onDiscardChangesPopup(event) {
        const result = await LightningConfirm.open({
            message: this.label.discardMessage,
            variant: 'header',
            label: this.label.requestConfirmation,
            theme: 'warning'
        });

        if(result) {
            this.onDiscardChanges(event);
        }
    }

    async onConfirmNoResultsPopup(event) {
        const result = await LightningConfirm.open({
            message: dvsConfirmNoResultsMessage,
            variant: 'header',
            label: this.label.noData,
            theme: 'warning'
            // setting theme would have no effect
        });

        if(result) {
            this.onConfirmNoResults(event);
        }
    }

    handleEnter(event) {
        if (event.keyCode === 13) {
            this.onSearchClick();
        }
    }

    getFieldsLabels(fieldsLabels) {
        for (let i in fieldsLabels) {
            switch (i) {
                case 'Name':
                    this.nameLabel = fieldsLabels['Name'];
                case 'Id1':
                    this.id1Label = fieldsLabels['Id1'];
                case 'Id2':
                    this.id2Label = fieldsLabels['Id2'];
                case 'Address':
                    this.addressLabel = fieldsLabels['Address'];
                case 'Street':
                    this.streetLabel = fieldsLabels['Street'];
                case 'PostalCode':
                    this.postalCodeLabel = fieldsLabels['PostalCode'];
                case 'City':
                    this.cityLabel = fieldsLabels['City'];
                case 'SearchById':
                    this.searchByIdLabel = fieldsLabels['SearchById'];
            }
        }
    }

    @api
    showToast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                message: message,
                variant: variant,
            })
        );
    }

    navigateToRecord() {
        console.log("Go to record");
        window.location.replace("/" + this.recordId);
    }

    navigateToDvsList() {
        console.log("Go to DVS list");
        
        window.location.replace("/lightning/o/DvsDiscrepancy__c/list?filterName=All");
    }
}