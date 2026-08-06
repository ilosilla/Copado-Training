import { LightningElement,api,track } from 'lwc';

import bookAndAppointment from '@salesforce/label/c.NBK_BookAndAppointment';
import AppointmentImgNotFound from '@salesforce/resourceUrl/AppointmentImgNotFound';
import StoreImagesAppointment from '@salesforce/resourceUrl/StoreImagesAppointment';
import StoreImagesAppointmentUK from '@salesforce/resourceUrl/StoreImagesAppointmentUK';
import StoreImagesAppointmentFR from '@salesforce/resourceUrl/StoreImagesAppointmentFR';
import StoreImagesAppointmentDE from '@salesforce/resourceUrl/StoreImagesAppointmentDE';

export default class NB2B_FinderStoreItem extends LightningElement {

    @api store;
    @api country;
    @track distanciaAtienda;
    @track imagenUrl = AppointmentImgNotFound;
    labels={
        bookAndAppointment
    }

    connectedCallback() {
        this.getImage();
        this.distanciaAtienda =  Math.trunc( this.store.Distancia );
    }

    handleCategoryClick(event){
        console.log('handleCategoryClick');

        const selectedEvent = new CustomEvent('selectedstore',{detail:this.store.address.Id});
        this.dispatchEvent(selectedEvent);
    }


    getImage(){
        try{
            var nameimage = this.store.address.Name;
            nameimage = nameimage.replaceAll(' ','');
            nameimage = nameimage.replaceAll('–','');
            nameimage = nameimage.replaceAll('-','');
            nameimage = nameimage.replaceAll('_','');
            nameimage = nameimage.replaceAll('_','');
            nameimage = nameimage.replaceAll('(','');
            nameimage = nameimage.replaceAll(')','');
            nameimage = nameimage.replaceAll(',','');

						var imgurl= '';

						if(this.country.toUpperCase()=='US'){
							imgurl = StoreImagesAppointment+'/StoreImages/'+nameimage+'.jpg';
						}else if(this.country.toUpperCase() == 'UK'){
							imgurl = StoreImagesAppointmentUK+'/StoreImages/'+nameimage+'.jpg';
						}else if(this.country.toUpperCase() == 'FR'){
							imgurl = StoreImagesAppointmentFR+'/StoreImages/'+nameimage+'.jpg';
						}else if(this.country.toUpperCase() == 'DE'){
							imgurl = StoreImagesAppointmentDE+'/StoreImages/'+nameimage+'.jpg';
						}else if(this.country.toUpperCase() == 'SE'){
							imgurl = StoreImagesAppointmentDE+'/StoreImages/'+nameimage+'.jpg';
						}else {
							imgurl = StoreImagesAppointment+'/StoreImages/'+nameimage+'.jpg';
						}


            this.checkIfImageExists(imgurl, (exists) => {
                    if (exists) {
                        this.imagenUrl = imgurl;
                    }
                    });
        }catch(error){
            console.log(error);
        }

    }

    checkIfImageExists(url, callback) {
        const img = new Image();
        img.src = url;

        if (img.complete) {
            callback(true);
        } else {
            img.onload = () => {
            callback(true);
            };

            img.onerror = () => {
            callback(false);
            };
        }
    }

}