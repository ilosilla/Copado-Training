import { api, track } from 'lwc';
import LwcUtils from 'c/lwcUtils';
import checkoutPickup from '@salesforce/label/c.NB2B_Checkout_Pickup';


export default class Nb2bShippingAddress extends LwcUtils {
	//public
	@api recordId;
	@api deliveryGroup;
	//labels
	@api shippingAddressLabel = 'Delivery Address';//label.NB2B_ShipAddressTitle
	@api selectAddressLabel = 'Select Address';//label.NB2B_selectAddress
	@api changeAddressLabel = 'Change delivery Address';//label.NB2B_ChangeAddress
	@api addAddressLabel = 'Add Address';//label.NB2B_AddAddress
	label = {
        checkoutPickup
    }
	//private
	addresses;
	@track selectedAddress;
	options;
	edit = false;
	pickupAddress = false;
    cmpInitialized = false;
	pickupList;
	pickupListNormalizedAddress;
	//helper
	_selectedAddress;
	@track pickchecked;

	get showAddress(){
		return this.selectedAddress /*&& this.selectedAddress.Address*/ ? true : false;
	}

	get selectedOption(){
		return this._selectedAddress ? this._selectedAddress.Id : undefined;
	}

	get modalTitle() {
		console.log('modalTitle:'+this.selectAddressLabel);
		return this.selectAddressLabel;
		//return join(' ', labels.Add, labels.Address);
	}

	get mapMarkers(){
		if(this.selectedAddress){
			let addressObj = this.selectedAddress.Address ? this.selectedAddress.Address : this.selectedAddress;

			return [
				{
					location: {
						City: addressObj.city,
						Country: addressObj.Country,
						PostalCode: addressObj.postalCode,
						State: addressObj.state,
						Street: addressObj.street,
					}
				}
			];
		}
	}

	connectedCallback() {
        this.cmpInitialized = false;
		this.retrieveData();
	}

	retrieveData = async() => {
		try {
			let _data = await super.executeRemoteAction(
				JSON.stringify({
					controller: 'NB2B_AddressController',
					actionName: 'getAddresses',
					webcartId: this.recordId
				})
			);
			if(_data !== null || _data !== undefined){
				//console.log('Nb2bShippingAdress - retrieveData() - [data]: ', JSON.parse(JSON.stringify(_data)));
			}
			let addressId = this.selectedAddres ? this.selectedAddres.Id : undefined;
			this.fillAddressData(_data, addressId);
			this.edit = true;

			// this.resData = JSON.parse(_data.dataJSON);
			// console.log('resData: '+this.resData);
			this.getAddressPickup();

		}catch(e){console.error(e);}finally{
            this.cmpInitialized = true;
        }
	}
	getAddressPickup = async() => {
		try {
			console.log("getAddressPickup deliverygroup: "+this.deliveryGroup);
			let response = await super.executeRemoteAction(
				JSON.stringify({
					controller: 'NB2B_AddressController',
					actionName: 'getAddressPickup',
					deliveryGroup: this.deliveryGroup
				})
			);
			if(response !== null || response !== undefined){
				//console.log('Nb2bShippingAdress - getAddressPickup() - [response]: ', JSON.parse(JSON.stringify(response)));
				this.pickupList = response;
				this.pickupListNormalizedAddress = [];
				let thiscontext = this;

				response.forEach(element => {
					let normalizedAddress = ' ' + element.NBK_Address__c.street + ' ' +
											element.NBK_Address__c.city + ' ' +
											element.NBK_Address__c.state + ' ' +
											element.NBK_Address__c.country + ' ' +
											element.NBK_Address__c.postalCode+ ' ' + (element.IsDefault?'(Default address)':'');
					normalizedAddress = normalizedAddress.replaceAll('null', '');
					thiscontext.pickupListNormalizedAddress.push({ label: normalizedAddress, value: element.Id});
				});
			}


		}catch(e){console.error(e);}
	}

	fillAddressData(data, selectedId){
		let _options = [];
		let _addresses = [];
		let addressSelection;
		let defaultAddress;
		if(data){
			this.accountId = data.accountId;

			data.addressList.forEach(element => {
				_addresses.push(element);

				let normalizedAddress = ' ' + element.Name + ': ' +
										element.Address.street + ' ' +
										element.Address.city + ' ' +
										element.Address.state + ' ' +
										element.Address.country + ' ' +
										element.Address.postalCode+ ' ' + (element.IsDefault?'(Default address)':'');

				normalizedAddress = normalizedAddress.replaceAll('null', '');

				_options.push({ label: normalizedAddress, value: element.Id});

				if(selectedId && element.Id == selectedId){
					addressSelection = element;
				}
				if(element.IsDefault === true){
					defaultAddress = element;
				}
			});
			/*if (!defaultAddress && data.addressList.length > 0){
				defaultAddress = data.addressList[0];
			}*/
		}
		//Ordenar OPTIONS
		try{
			if(_options != null && _options != undefined){
				_options.sort(function (a, b) {
					if (a.label < b.label) {
						return -1;
					}
					if (a.label > b.label) {
						return 1;
					}
					return 0;
					});
			}
		}catch(error1){
			console.error(error1);
		}

		this.addresses = _addresses;
		this.options = _options;

		defaultAddress = data.accountAddress;
		if (addressSelection || defaultAddress){
			this.setAddressSelection(addressSelection ? addressSelection : defaultAddress);
		}
	}


	setAddressSelection(address){
		this.selectedAddress = address;

		let data = {
			postalCode: address.Address ? address.Address.postalCode : address.postalCode,
			addressId: address.Id,
			thirdparty: address.NB2B_thirdpartyAddress__c
		}
		//console.log("selectedAddres: "+JSON.stringify(this.selectedAddress));
		// super.fireEvent('selection',data);
		const evt = new CustomEvent('selection', {
            detail: {...data, refreshDate: (this.cmpInitialized && !this.changingAddressFromParent)},
        });
        this.dispatchEvent(evt);
	}

	openModal() {
		this._selectedAddress = this.selectedAddress;
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.show();
	}

	closeModal() {
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.hide();
	}

	handleCancel() {
		this.closeModal();
	}

	handleSave() {
		try{
			this.setAddressSelection(this._selectedAddress);
			this.closeModal();
		} catch(e){ console.error(e); }
	}

	handleAddressCreation(event) {
		event.stopPropagation();
		try{
			let addressId = this.handleDoInit(event);
			//Aqui devuelve sapId
			console.log('addressId:'+addressId);
			this.retrieveData()
			.then(() => {
				this._selectedAddress =  this.searchAddressBySAPId(addressId);
				//let searchedAddress =  this.searchAddress(addressId);
				//this.setAddressSelection(searchedAddress);
				//this.closeModal();
			})
			.catch((e) => { /*this.setError(e, this);*/console.error(e); });
		} catch(e){ console.error(e); }
	}

	searchAddressBySAPId(addressId){
		let address;
		this.addresses.every(function(obj){
			if(obj.SAPId__c === addressId){
				address = obj;
				return false;
			}
			return true;
		});
		return address;
	}

	searchAddress(addressId){
		let address;
		this.addresses.every(function(obj){
			if(obj.Id === addressId){
				address = obj;
				return false;
			}
			return true;
		});
		return address;
	}

	@api async changeAddressFromParent(addId){
		console.log('changeAddressFromParent:'+addId);
        this.changingAddressFromParent = true;
		try {
			//retrieve data
			let _data =  await super.executeRemoteAction(
					JSON.stringify({
						controller: 'NB2B_AddressController',
						actionName: 'getAddresses',
						webcartId: this.recordId
					})
				);
			let addressId = addId ? addId : undefined;
			this.fillAddressData(_data, addressId);
			this.edit = true;

			//retrieve data
			this._selectedAddress = this.searchAddress(addId);
			this.selectedAddress = this._selectedAddress;

			let data = {
				postalCode: this.selectedAddress.Address ? this.selectedAddress.Address.postalCode : this.selectedAddress.postalCode,
				addressId: this.selectedAddress.Id,
				thirdparty: this.selectedAddress.NB2B_thirdpartyAddress__c
			}

			const evt = new CustomEvent('selection', {
				...data,
                refreshDate: (this.cmpInitialized && !this.changingAddressFromParent),
			});
			this.dispatchEvent(evt);
		} catch (e) {
			console.error(e)
		} finally {
            this.changingAddressFromParent = false;
        }
	}

	handleAddressSelection(event) {
		event.stopPropagation();
		try{
			let addressId = this.handleDoInit(event);
			this._selectedAddress = this.searchAddress(addressId);
		} catch(e){ console.error(e); }
	}

	renderedCallback(){
		const style = document.createElement('style');
		style.innerText = `.slds-map {
		max-height: 200px!important;min-width: auto;
		}
		.slds-map:before{padding-top:200px!important}`;
		if(this.template.querySelector('lightning-map') != null && typeof(this.template.querySelector('lightning-map')) != 'undefined'){
			this.template.querySelector('lightning-map').appendChild(style);
		}
	}


	handleCheckChange(event){
		this.pickupAddress = event.target.checked;
		this.pickchecked = event.target.checked;

		// super.fireEvent('selectpickup',this.pickupAddress);
		const evt = new CustomEvent('checkpickup', {
            detail: this.pickupAddress
        });
        this.dispatchEvent(evt);

		//console.log("pickupAddress: "+this.pickupAddress);
		//console.log("this.pickupListNormalizedAddress.length: "+this.pickupListNormalizedAddress.length);
		window.setTimeout(() => {
			if (this.pickupListNormalizedAddress.length == 1){
				this.selectedAddressPickup = this.pickupListNormalizedAddress[0].value;
				let e = {detail: {value: this.selectedAddressPickup}};
				this.handlePickupAddressSelection(e);
			}
		}, 500);
	}

	handlePickupAddressSelection(event) {
		let address;
		let addressId = event.detail.value;
		//console.log("select address pickup1: "+event.detail.value);
		// this.selectedAddress = address;
		// console.log("select address pickup1: "+this.selectedAddress);
	 	// super.fireEvent('selection', address);
		try{
			this.pickupList.every(function(obj){
				//console.log("obj: "+obj.Id);
				if(obj.Id === addressId){
					address = obj;
					//console.log('true');
				}
			});
			this._selectedAddress = address;
			//console.log("select address pickup2: "+JSON.stringify(address));

			//console.log("select address pickup2: "+JSON.stringify(this._selectedAddress));

			let data = {
				postalCode: address.NBK_Address__c.postalCode,
				addressId: address.Id
			}
			console.log('handlePickupAddressSelection data:'+JSON.stringify(data));
			const evt = new CustomEvent('selectionpickup', {
				detail: data
			});
			this.dispatchEvent(evt);
		} catch(e){ console.error(e); }
	}

	// setDeliverySelection(event){
	// 	super.fireEvent('deliveryselection',event.target.value);
	// }
	setPOSelection(event){

	}
}