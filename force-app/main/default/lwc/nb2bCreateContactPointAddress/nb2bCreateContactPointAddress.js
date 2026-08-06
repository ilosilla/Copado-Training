import { api, wire } from 'lwc';
import LwcUtils from 'c/lwcUtils';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import COUNTRY_FIELD from '@salesforce/schema/ContactPointAddress.CountryCode';
import getUserCountry from '@salesforce/apex/NB2B_ShippingAddressController.getUserCountry';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CPA_OBJECT from '@salesforce/schema/ContactPointAddress';

export default class Nb2bCreateContactPointAddress extends LwcUtils {
	//input
	@api accountId;

	//private
	strStreet;
	strCity;
	strState;
	strCountry;
	strPostalCode;
	mapStatesByCountryCode;
	_countryOptions;
    displaySpinner = false;
    userCountryCode;

	get stateOptions(){
		return (this.strCountry && this.mapStatesByCountryCode) ? this.mapStatesByCountryCode[this.strCountry] : [];
	}

	get countryOptions(){
		return this._countryOptions ? this._countryOptions : [];
	}

    @wire(getObjectInfo, { objectApiName: CPA_OBJECT })
	objectInfo;

	@wire(getPicklistValues, {
		recordTypeId: '$objectInfo.data.defaultRecordTypeId',
		fieldApiName: COUNTRY_FIELD
	})
	getCountryValues({ error, data }) {
		if (data) {
			let countries = [];
			data.values.forEach((elem) => {
				countries.push({
					label: elem.label,
					value: elem.value
				});
			});
			this._countryOptions = [...countries];
		} else if (error) {
			console.error(error);
		}
	};

	connectedCallback() {
        this.retrieveUserCountry();
		this.retrieveData();
	}

	retrieveData = async() => {
		try {
			let actionParams = {
				controller: 'NB2B_CreateContactPointAddressController',
				actionName: 'getStatePicklistValuesByCountryCode'
			};

			let data = await super.executeRemoteAction(JSON.stringify(actionParams));
			if(data){
				this.mapStatesByCountryCode = data;
			}
		}catch(e){console.error(e);}
	}

    retrieveUserCountry = async() => {
        try {
            let data = await getUserCountry();
            this.userCountryCode = data;
        }catch(e){console.error(e);}
    }

	closeModal() {
		try{
			super.fireEvent('close');
		} catch(e){ console.error(e); }
	}
	
	handleSave(event){
		event.preventDefault();
		let fields = event.detail.fields;
		fields.Street = this.strStreet;
		fields.City = this.strCity;
		fields.StateCode = this.strState;
		fields.CountryCode = this.strCountry;
		fields.PostalCode = this.strPostalCode;
		fields.Phone__c = event.detail.fields.Phone__c;
		fields.NB2B_thirdpartyAddress__c = event.detail.fields.NB2B_thirdpartyAddress__c;
		
		
		this.createAddress(fields);
		//this.template.querySelector('lightning-record-edit-form').submit(fields);
	}

	createAddress = async(fields) => {
		console.log('Entra createAddress');
		try {
			let actionParams = {
				controller: 'NB2B_CreateContactPointAddress',
				actionName: 'createAddress',
				fields, fields
			};

            this.displaySpinner = true;
			let data = await super.executeRemoteAction(JSON.stringify(actionParams));
			console.log('sale createAddress : ' + data);
			if(data){
				console.log('sale createAddress : ' + data);
                this.showToast('Success', 'Delivery address created', 'success');
				super.fireEvent('success',data);
				this.closeModal();
				//this.mapStatesByCountryCode = data;
			}else{
				this.showToast('Error', 'The delivery address you request cannot be created. A sales rep will sontact you as soon as possible', 'The delivery address you request cannot be created. A sales rep will sontact you as soon as possible');
			}
		}catch(e){
			console.error(e);
			this.manageError(e, 'The delivery address you request cannot be created. A sales rep will sontact you as soon as possible');
		}finally{
            this.displaySpinner = false;
        }
	}

	handleSuccess(event){
		//super.fireEvent('success',event.detail.id);
		//this.closeModal();
	}

	addressInputChange(event){
		this.strStreet = event.target.street;
		this.strCity =  event.target.city;
		this.strState = event.target.province;
		this.strCountry = event.target.country;
		this.strPostalCode = event.target.postalCode;
	}

	handleError(event){
		this.showToast('Error', event.detail.detail, 'error');
	}
}