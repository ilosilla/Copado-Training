import { LightningElement,api,track } from 'lwc';

import nBK_selectedShowroom from '@salesforce/label/c.NBK_selectedShowroom';
import nBK_contactPhone from '@salesforce/label/c.NBK_contactPhone';
import nBK_contactEmail from '@salesforce/label/c.NBK_contactEmail';
import AppointmentImgNotFound from '@salesforce/resourceUrl/AppointmentImgNotFound';
import StoreImagesAppointment from '@salesforce/resourceUrl/StoreImagesAppointment';


export default class NBK_AppointmentStoreInfo extends LightningElement {

    @api store;
    @track imagenUrl = AppointmentImgNotFound;
    @track link;
//StoreImages

    labels = {
        nBK_selectedShowroom,
        nBK_contactPhone,
        nBK_contactEmail
    }

    sendStoreInfoToGtm() {
        document.dispatchEvent(
            new CustomEvent("ma_step_1", 
            { "detail" : 
                { 
                    event: "ma_step_1",
                    appointment_category: "make an appointment form",
                    appointment_action: "1_store",
                    appointment_label: this.store.Name
                 }
            })
        );
    }

    connectedCallback() {
        this.getImage();
        this.sendStoreInfoToGtm();
    }
   
    getImage(){
        try{
            var nameimage = this.store.Name;
            nameimage = nameimage.replaceAll(' ','');
            nameimage = nameimage.replaceAll('–','');
            nameimage = nameimage.replaceAll('-','');
            nameimage = nameimage.replaceAll('_','');
            nameimage = nameimage.replaceAll('_','');
            nameimage = nameimage.replaceAll('(','');
            nameimage = nameimage.replaceAll(')','');
            nameimage = nameimage.replaceAll(',','');
            var imgurl = StoreImagesAppointment+'/StoreImages/'+nameimage+'.jpg';
            
            this.checkIfImageExists(imgurl, (exists) => {
                    if (exists) {
                        this.imagenUrl = imgurl;
                    } else {
                        console.error('Image does not exists.');
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