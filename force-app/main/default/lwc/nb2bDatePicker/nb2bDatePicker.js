import { track, api } from 'lwc';
import LwcUtils from 'c/lwcUtils';
import momentJS from '@salesforce/resourceUrl/momentJS';
import getb2bMetadata from '@salesforce/apex/NB2B_DatePicker.getb2bMetadata';
export default class Nb2bDatePicker extends LwcUtils {
 //input variables
 @api daysToShow;
 validDates;
 @api postalCode;
 @api dateFormat;// = 'YYYY-MM-DD';
 //input labels
 @api inputLabel = 'Delivery Date *';
 @api modalTitle = 'Select date';
 @api buttonLabelBefore = 'Select date';
 @api buttonLabelAfter = 'Change selected date';
 @api todayButtonLabel = 'Today';
 @api prevButtonLabel = 'Prev';
 @api nextButtonLabel = 'Next';
 @api showWarningDate = false;

 //pivate
 @api selectedDate;
 _selectedDate;
 @api selFormatDateAux;

 // renderedCallback(){
 // 	console.log('selFormatDateAux:'+this.selFormatDateAux);
 // 	console.log('this.formattedSelectedDate:'+this.formattedSelectedDate);
 // 	if(this.formattedSelectedDate == null || this.formattedSelectedDate == undefined || this.formattedSelectedDate == ''){
 // 		console.log('FORMATEANDO ******');
 // 		this.formattedSelectedDate = moment(this.selFormatDateAux);
 // 	}
 // }


 get formattedSelectedDate() {
  console.log('Nb2bDatePicker - formattedSelectedDate() - this.selectedDate:', (this.selectedDate) ? JSON.parse(JSON.stringify(this.selectedDate)) : this.selectedDate);
  return this.selectedDate ? moment(this.selectedDate).format(this.dateFormat) : '';
 }

 get showInput() {
  return this.selectedDate ? true : false;
 }

 get buttonLabel() {
  return this.selectedDate ? this.buttonLabelAfter : this.buttonLabelBefore;
 }

 connectedCallback() {
  try{
   super.loadResources({scripts: [momentJS]})
   .then(() => {
        if(this.selFormatDateAux && this.selFormatDateAux.split('-').length===3){
          this.selectedDate = moment(new Date(
            parseInt(this.selFormatDateAux.split('-')[0]),
            parseInt(this.selFormatDateAux.split('-')[1])-1,
            parseInt(this.selFormatDateAux.split('-')[2])
          ));
        }
      })
   .catch((e) => { console.error(e); });
  }catch(e){console.error(e);}

 }

 @api
 resetSelection(){
  //console.log('****RESET****');
  //console.log('this.selectedDate:'+this.selectedDate);
  this._selectedDate = undefined;
  this.selectedDate = undefined;
 }

  @api
  changeDateFromParent(deliverydate){
  console.log('Nb2bDatePicker - changeDateFromParent() - deliverydate:', deliverydate);
    this.selectedDate = moment(new Date(
      parseInt(deliverydate.split('-')[0]),
      parseInt(deliverydate.split('-')[1])-1,
      parseInt(deliverydate.split('-')[2])
    ));
  }

 openModal() {
  const dialog = this.template.querySelector('c-nb2b-dialog');
  dialog.show();
 }

 closeModal() {
  const dialog = this.template.querySelector('c-nb2b-dialog');
  dialog.hide();
 }

 handleSelection(evt){
  evt.stopPropagation();
  try{
   let newSelection = this.handleDoInit(evt);
   if(newSelection){
    this._selectedDate = newSelection;
   }
  }catch(e){console.error(e);}
 }

 handleAccept(){
  this.selectedDate = this._selectedDate;
    const formattedSelDate = this.selectedDate ? moment(this.selectedDate).format('YYYY-MM-DD') : null;
  super.fireEvent('selection',formattedSelDate);
  this.closeModal();
 }

 @api
 getValidDates(postalcode){
  this.postalCode = postalcode;
  this.retrieveData(this.postalCode);
 }

 retrieveData = async(postalcode) => {
  try {
   let _postalCode = postalcode ? postalcode.split(" ")[0] : postalcode;
   let actionParams = {
    controller: 'NB2B_DeliveryDateSelector_Controller',
    actionName: 'getDeliveryDates',
    postalCode: _postalCode
   };

   let data = await super.executeRemoteAction2(JSON.stringify(actionParams));
   if(data){
    // console.log("delivery days: "+JSON.stringify(data));
    this.fillDatesData(data);
   }
  }catch(e){console.error(e);}
 }

 fillDatesData(data) {
   try{
    let dates = [];
    let daysData = data.dataJSON;
    if(this.daysToShow){
     var country = 'United Kingdom';
     var getHour = 0;
     var getDays = 0;
     var iAuxdates = 0;
     var delayAux = 0;
     const today = moment();
     getb2bMetadata({country})
        .then((result) =>{
          if (result != null){
           getHour = result[0].Cutover_Time__c;
           getDays = result[0].Days_to_wait__c;
           console.log('getHour'+getHour);
           console.log('getDays'+ getDays);
					 var breakmoment =0;
					 if(getHour!=null){
						breakmoment = moment().set({hour: getHour, minute:0,second:0,millisecond:0});
					 }else{
						breakmoment = moment().set({hour: 23, minute:59,second:59,millisecond:59});
					 }
           var iAux = getDays;
           if(data.defaultAdd == true && data.daysToDelay != null){
             iAux = data.daysToDelay;
             const updateWarning = new CustomEvent("warningvaluechange", {detail: true});
             this.dispatchEvent(updateWarning);
           }else{
             const updateWarning = new CustomEvent("warningvaluechange", {detail: false});
             this.dispatchEvent(updateWarning);
           }
           if(breakmoment <= today){
             iAux++;
           }
					 //FINES DE SEMANA
					 var diaHoy = today.format('dddd');
					 console.log('diaHoy:'+diaHoy);
					 if(diaHoy == 'Saturday'){
						iAux += 2;
					 }else if(diaHoy == 'Sunday'){
						iAux += 1;
					 }
					 //FINES DE SEMANA

					 for(var i=0;i<this.daysToShow;i++){
             let auxDate = today.clone().add(i, 'day');
						 if(iAux <= iAuxdates){
							if(daysData.includes(auxDate.format('dddd'))){
								dates.push(auxDate.format(this.dateFormat));
							}
						 }else{
							iAuxdates++;
						 }
          }
						this.validDates = [...dates];
          }else {
           console.error('No se ha podido cargar la configuracion');
          }
        })
        .catch((error) =>{
          console.log('ERROR' + JSON.stringify(error));
        })
   }

  }catch(e){ console.log(e); }
  // console.log("salen validdates: "+this.validDates);
 }
}