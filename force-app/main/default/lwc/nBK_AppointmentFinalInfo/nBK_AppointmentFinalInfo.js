import { LightningElement,api,track } from 'lwc';

import tit1 from '@salesforce/label/c.NBK_BookingCompleted';
import tit2 from '@salesforce/label/c.NBK_BookingSuccess1';
import tit3 from '@salesforce/label/c.NBK_BookingSuccess2';
import date from '@salesforce/label/c.NBK_Date';
import location from '@salesforce/label/c.NBK_Location';

export default class NBK_AppointmentFinalInfo extends LightningElement {

	@api store;
	@api selectedDate;
	@api appointmentType;
    @track selectedDateS;
    @track appointmentTypeS;
    @track isVirtual = false;
		@track showFR = false;
    labels = {
		tit1,
		tit2,
		tit3,
		date,
		location
	}


    connectedCallback() {
        this.transformDate();
        this.transformType();
		this.selectCountry();
		this.sendSuccessToGtm();
    }

	sendSuccessToGtm() {
        document.dispatchEvent(
            new CustomEvent("ma_step_4", 
            { "detail" : 
                { 
                    event: "ma_step_4",
                    appointment_category: "make an appointment form",
                    appointment_action: "5_make_appointment_success",
                    appointment_label: this.store.Name,
                    appointment_form_type_visit: this.appointmentTypeS
                 }
            })
        );
    }

		selectCountry(){
			const urlParams	= new URLSearchParams(window.location.search);
			var countrys		= urlParams.get("country");
			if(countrys == 'US' || countrys == 'UK'){
				this.showFR=false;
			}else if(countrys == 'FR'){
				this.showFR=true;
			}
		}

    transformType(){
        this.appointmentTypeS = this.appointmentType.toLowerCase();
        if(this.appointmentTypeS == 'virtual'){
            this.isVirtual = true;
        }
    }

    transformDate(){
        try{
					const urlParams	= new URLSearchParams(window.location.search);
					var countrys		= urlParams.get("country");
					var format 			= 'DD/MM/YYYY';
					if(countrys == 'US'){format ='MM/DD/YYYY';
					}else if(countrys == 'UK'){format ='DD/MM/YYYY';
					}else if(countrys == 'FR'){format ='DD/MM/YYYY';
					}
            var date = moment(this.selectedDate).format(format);
            var hours = moment(this.selectedDate).format('HH');
            var minutes = moment(this.selectedDate).format('mm');
			var hoursp = parseInt(moment(this.selectedDateS).format('hh'));
            var minutessp = parseInt(moment(this.selectedDateS).format('mm'));
			var ampm = hours < 12 ? 'AM' : 'PM';
			this.selectedDateS = date+' '+hours+':'+minutes+''+ampm;

        }catch(error){
            console.error(error);
        }
	}




}