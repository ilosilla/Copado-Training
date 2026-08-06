import { LightningElement,api,track } from 'lwc';

import bookAndAppointment   from '@salesforce/label/c.NBK_BookAndAppointment';
import distanceStore        from '@salesforce/label/c.NBK_DistanceStore';

export default class NB2B_FinderStoreItemList extends LightningElement {

    @api store;
    @track distanciaAtienda;
    @track units;
    @api country;
    @track showFr = false;
    @track showUS = false;
    labels={
        bookAndAppointment,
        distanceStore
    }

    connectedCallback() {
        this.checkKm();

    }

    checkKm(){
        const urlParams     = new URLSearchParams(window.location.search);
        this.country        = urlParams.get("country");

        if(this.country == 'US' || this.country == 'UK'){
            this.units = 'Mi';
            this.showFr = false;
            if (this.country == 'US' ){
                this.showUS = true;
            }
        }else if(this.country.toUpperCase() == 'FR'){
            this.units = 'Km';
            this.showFr = true;
        }
    }

    handleCategoryClick(event){

        const selectedEvent = new CustomEvent('selectedstore',{detail:this.store.address.Id});
        this.dispatchEvent(selectedEvent);
    }

    redirectGeoMap(event){
        console.log('redirectGeoMap');
        const selectedEvent2 = new CustomEvent('changeposition',{detail:this.store.address.Id});
        this.dispatchEvent(selectedEvent2);
    }
}