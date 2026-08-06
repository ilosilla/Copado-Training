import { track, api, wire} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import LwcUtils from 'c/lwcUtils';
import momentJS from '@salesforce/resourceUrl/momentJS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { NavigationMixin } from 'lightning/navigation';
import getDataCartGroup from '@salesforce/apex/NB2B_ShippingAddressController.getDataCartGroup';
import feeWarning from '@salesforce/label/c.NB2B_WarningFee';
import dateWarning from '@salesforce/label/c.NB2B_Date_Warning';


export default class Nb2bShippingAddressSelector extends LwcUtils {
	//input
	@api cartId;
	@api daysToShow = 7;
	// @api dateFormat = 'YYYY-MM-DD';
	@api deliveryGroup;
	@api cartDeliveryGroupId;
	//output
	@api
	get selectedDate() {
		return this._selectedDate;
	};

    set selectedDate(value) {
        this._selectedDate = value;
    }
	// @api
	// get addressId() {
	// 	return this._addressId;
	// };
	@api addressId;
	@api porcelanosaAddressId;
	@api NB2B_PickupStore;
	@api order_Code;
	@api NB2B_Order_Code;
    _delivery_Date;
    @api
    get delivery_Date() {
        return this._delivery_Date;
    }

    set delivery_Date(value) {
        this._delivery_Date = value ? JSON.parse(JSON.stringify(value)) : value;
    }
	@api NB2B_DeliveryDate;
	@api deliveryInstructions;
	@api NB2B_DeliveryInstructions;
    @api NB2B_ContactPointAddress;
	@api totalAmount;
	@api availableActions = [];

	//private
	@track postalCode;
	_selectedDate;
	_addressId;
	validDates;
	showWarning;
	dateFormat;
	showWarningDate;
	addressRecup;
    cmpInitialized = false;

	labels = {feeWarning, dateWarning}


	get showCalendar(){
		return this.postalCode !== undefined;
	}

	connectedCallback() {
        console.log('Nb2bShippingAddressSelector - connectedCallback() - delivery_Date:', this.delivery_Date);
        console.log('Nb2bShippingAddressSelector - connectedCallback() - NB2B_DeliveryDate:', this.NB2B_DeliveryDate);
        console.log('Nb2bShippingAddressSelector - connectedCallback() - selectedDate:', this.selectedDate);
        console.log('Nb2bShippingAddressSelector - connectedCallback() - _selectedDate:', this._selectedDate);
		super.loadResources({scripts: [momentJS]})
		.then(() => { 
			this.getUserData();
			this.getDataCartGroup(); })
		.catch((e) => { console.error(e); });

		/*const event = new ShowToastEvent({
			title: 'Delivery date has been set automatically. If you want to check it please go to change delivery date.',
			variant: 'warning'

		});
		this.dispatchEvent(event);*/
		
	}
	renderedCallback(){

		this.NB2B_PickupStore = false; //EHG comentado. No siempre tiene que ser false
		// EHG this.NB2B_DeliveryInstructions = this.deliveryInstructions;
		this.NB2B_Order_Code = this.order_Code;
		//this.NB2B_DeliveryDate = this.delivery_Date;

	}

	getDataCartGroup() {
        getDataCartGroup({cartGroupId : this.cartDeliveryGroupId})
            .then(result => {

               if(result != null && result != undefined){
				/*if(result.deliveryDate != null && result.deliveryDate != undefined && result.deliveryDate != ''){
					//this.selectedDate = result.deliveryDate;
					//this._selectedDate = result.deliveryDate;
					//this.delivery_Date = result.deliveryDate;
					//this.template.querySelector('c-nb2b-date-picker').selectedDate = moment(this.selectedDate);
					//this.sendToFlow('selectedDate', this.delivery_Date);
				}*/
				if(result.orderCode != null && result.orderCode != undefined && result.orderCode != ''){
					this.NB2B_Order_Code = result.orderCode;
					this.order_Code = result.orderCode;
					this.sendToFlow('NB2B_Order_Code', this.order_Code);
				}
				if(result.shippingInstructions != null && result.shippingInstructions != undefined && result.shippingInstructions != ''){
					this.NB2B_DeliveryInstructions = result.shippingInstructions;
					this.deliveryInstructions = result.shippingInstructions;
				}
				if(result.contactpointaddress != null && result.contactpointaddress != undefined && result.contactpointaddress != ''){
					console.log('direccion recuperada:'+result.contactpointaddress);
					this.addressRecup = result.contactpointaddress;
					this.template.querySelector('c-nb2b-shipping-address').changeAddressFromParent(this.addressRecup);
					
				}
                if(result.deliveryDate){
					console.log('fecha recuperada:'+result.deliveryDate);
                    this._delivery_Date = result.deliveryDate;
					this.template.querySelector('c-nb2b-date-picker').changeDateFromParent(this._delivery_Date);
                }
			   }
            })
            .catch(error => {
               console.log(JSON.stringify(error));
            })
            .finally(() => {
                this.cmpInitialized=true;
            });

		}

	handleAddressSelection(evt){
		console.log('handleAddressSelection');
		console.log('_selectedDate:'+this._selectedDate);
        if(evt.detail.refreshDate && this.cmpInitialized){
            this._selectedDate = null;
            this.selectedDate = null;
            this.delivery_Date= null;
        }
		try{
			this.addressId = evt.detail.addressId;

			this.porcelanosaAddressId = null;
			let newSelection = evt.detail;
			//show warning taxes

			if(newSelection.thirdparty == true && this.totalAmount < 1000){
				this.showWarning = true;
			}else{
				this.showWarning = false;
			}
			if(/*newSelection && newSelection.addressId !== this._addressId && */
				newSelection.postalCode !== this.postalCode){
				this.postalCode = newSelection.postalCode;
				this.retrieveData();
				this.resetDateSelector((evt.detail.refreshDate && this.cmpInitialized));
			}
		}catch(e){console.error(e);}
	}

	handleAddressSelectionPickup(evt){
		this._selectedDate = null;
		this.selectedDate = null;
		this.delivery_Date= null;
		try{
			this.porcelanosaAddressId = evt.detail.addressId;
			this.addressId = null;
			let newSelection = evt.detail;
			this.showWarning = false;

			if(/*newSelection && newSelection.addressId !== this._addressId && */
				newSelection.postalCode !== this.postalCode){
				this.postalCode = newSelection.postalCode;
				this.retrieveData();
				this.resetDateSelector(true);
			}
		}catch(e){console.error(e);}
	}

	deliveryInstChange(event){
        // console.log("handleDeliveryInstSelection: "+event.target.value);
		this.NB2B_DeliveryInstructions = event.target.value;
		//EHG mejoras B2B
		this.deliveryInstructions = event.target.value;

	}
	orderCodeChange(event){
		// console.log("handlePOSelection: "+event.target.value);
		this.NB2B_Order_Code = event.target.value;
		this.order_Code = this.NB2B_Order_Code;
	}

	handleSelectPickup(event){
		console.log('handleSelectPickup');
		console.log('_selectedDate:'+this._selectedDate);
		this._selectedDate = null;
		this.selectedDate = null;
		this.NB2B_PickupStore = event.detail;
		if(!this.NB2B_PickupStore){
			this.porcelanosaAddressId = null;
		}
	}

	retrieveData(){
		if(this.template.querySelector("c-nb2b-date-picker")){
			this.template.querySelector("c-nb2b-date-picker").getValidDates(this.postalCode);
		}
	}

	getUserData = async() => {
		try {
			let actionParams = {
				controller: 'NB2B_DeliveryDateSelector_Controller',
				actionName: 'getUserData'
			};

			let userInfo = await super.executeRemoteAction(JSON.stringify(actionParams));
			if(userInfo){
				this.dateFormat = userInfo.toUpperCase();
			}
		}catch(e){console.error(e);}
	}

	firstRendered = true;

	resetDateSelector(resetDialog) {
		this.changeSelection(undefined);
		const dialog = this.template.querySelector('c-nb2b-date-picker');
		if(resetDialog) dialog.resetSelection();

		if(this.firstRendered && (this.delivery_Date != null && this.delivery_Date != undefined && this.delivery_Date != '')){

		 	this.template.querySelector('c-nb2b-date-picker').selectedDate = moment(this.delivery_Date);
		 	this.firstRendered = false;
		 	this._selectedDate = this.delivery_Date;
		 	this.sendToFlow('selectedDate', this.delivery_Date);
		 }
	}

	handleDateSelection(evt){
		evt.stopPropagation();
		try{
			let newSelection = this.handleDoInit(evt);
			if(newSelection){
				this.changeSelection(newSelection);
			}
		}catch(e){console.error(e);}
	}

	changeSelection(selection){
		if(selection != null && selection != undefined){
			this._selectedDate = selection;
			this.NB2B_DeliveryDate = selection;
			this.delivery_Date = selection;
			this.sendToFlow('selectedDate', selection);
		}// }else{
		// 	this._selectedDate = this.delivery_Date;
		// 	this.NB2B_DeliveryDate = this.delivery_Date;
		// 	this.template.querySelector('c-nb2b-date-picker').selectedDate = moment(this.selectedDate);
		// 	this.sendToFlow('selectedDate', this.delivery_Date);
		// }
	}

	sendToFlow(evtName, data){
		const attributeChangeEvent = new FlowAttributeChangeEvent(evtName, data);
		this.dispatchEvent(attributeChangeEvent);
	}
	openModal() {
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.show();
	}

	closeModal() {
		const dialog = this.template.querySelector('c-nb2b-dialog');
		dialog.hide();
	}

	validateAndGo(){

		if(this._selectedDate == null || this._selectedDate == undefined){
			const event = new ShowToastEvent({
				title: 'Delivery Date required.',
				variant: 'warning'

			});
			this.dispatchEvent(event);
		}else if(this.order_Code == null || this.order_Code == undefined || this.order_Code == '' || this.order_Code == ' '){
			const event = new ShowToastEvent({
				title: 'Reference PO required.',
				variant: 'warning'

			});
			this.dispatchEvent(event);
		}else{
			if (this.availableActions.find((action) => action === "NEXT")) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
		}
	}
	
	goToCart() {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.cartId,
				objectApiName: 'WebCart', // objectApiName is optional
                actionName: 'view'
            }
        });
    }
	updateWarningDate(event) {
		this.showWarningDate = event.detail;
	}

}