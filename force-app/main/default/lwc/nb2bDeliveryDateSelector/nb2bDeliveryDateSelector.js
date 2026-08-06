import { track, api } from 'lwc';
import LwcUtils from 'c/lwcUtils';
import momentJS from '@salesforce/resourceUrl/momentJS';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Nb2bDeliveryDateSelector extends LwcUtils {
	//input
	@api postalCode;
	@api daysToShow = 7;
	@api dateFormat = 'YYYY-MM-DD';
	//output
	@api
	get selectedDate() {
		return this._selectedDate;
	};

	//private
	deliveryDates;
	validDates;
	_selectedDate;
	_postalCode;

	connectedCallback() {
		this._postalCode = this.postalCode ? this.postalCode.split(" ")[0] : this.postalCode;
		console.log('Nb2bDeliveryDateSelector - postalCode init: ',this.postalCode);
		console.log('Nb2bDeliveryDateSelector - postalCode end: ',this._postalCode);
		this.addEventListener('doInit', this.getDoInitHandler(this));
		//this.retrieveData();
		super.loadResources({scripts: [momentJS]})
		.then(() => { this.retrieveData(); })
		.catch((e) => { console.error(e); }); 
	}

	retrieveData() {
		try{
			super.fetch('NB2B_DeliveryDateSelector_Controller','getDeliveryDates',{postalCode: this._postalCode, daysToShow: this.daysToShow, dateFormat: this.dateFormat});
		}catch(e){ console.log(e); }
	}

	getDoInitHandler() {
		return function(event){
			try{
				const data = this.handleDoInit(event);
				console.log('Nb2bDeliveryDateSelector - getDoInitHandler() - [data]:', JSON.parse(JSON.stringify(data)));

				this.fillDatesData(data);
			}catch(e){ console.log(e); }
		};
	}

	fillDatesData(data) {
		try{
			this.deliveryDates = data;
			let dates = [];
			if(this.daysToShow){
				const today = moment();
				for(var i=0;i<this.daysToShow;i++){
					let auxDate = today.clone().add(i, 'day');
					if(data.includes(auxDate.format('dddd'))) dates.push(auxDate.format(this.dateFormat));
				}
			}
			this.validDates = [...dates];
		}catch(e){ console.log(e); }
	}

	handleSelection(evt) {
		evt.stopPropagation();
		try{
			let newSelection = this.handleDoInit(evt);
			if(newSelection){
				this.changeSelectedDate(newSelection, this);
			}
		}catch(e){console.error(e);}
	}

	changeSelectedDate(selection, self){
		self._selectedDate = selection;
		super.fireEvent('dateselection',self._selectedDate);
	}
}