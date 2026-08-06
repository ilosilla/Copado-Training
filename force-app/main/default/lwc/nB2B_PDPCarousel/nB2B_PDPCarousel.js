import { LightningElement, api, track } from 'lwc';
import NB2B_Image_Comming_Soon from '@salesforce/resourceUrl/NB2B_Image_Comming_Soon';

export default class NB2B_PDPCarousel extends LightningElement {
    @api urlImageList;

    defaultImage = NB2B_Image_Comming_Soon;
    @track urlImageWrapperList = [];

    get allImagesChecked() {
        try {
            return this.urlImageWrapperList.reduce((allChecked, urlImgWr) => allChecked && urlImgWr.checked, true);
        } catch (error) {
            console.error(error);
        }
    }

    get finalUrlImageList() {
        try {
            return this.urlImageWrapperList.map(urlImgWr =>
                urlImgWr.isAvailable ? urlImgWr.imgUrl : this.defaultImage
            );
        } catch (error) {
            console.error(error);
        }
    }

    connectedCallback(){
        try {
            this.setUrlImageWrapperList();
            this.checkAllImagesAvailability();
        } catch (error) {
            console.error(error);
        }
    }

    setUrlImageWrapperList() {
        this.urlImageList.forEach(imgUrl => this.urlImageWrapperList.push({
            imgUrl,
            checked: false,
            isAvailable: false,
        }));
    }

    checkAllImagesAvailability() {
        this.urlImageList.forEach(imgUrl => this.checkImageAvailability(imgUrl));
    }

    checkImageAvailability(imgUrl){
        try {
            console.log(`NB2B_PDPCarousel - checkImageAvailability() - imgUrl: "${imgUrl}"`);
            const img = new Image();
            img.src = imgUrl;

            img.onload = (function() {
                try {
                    console.log(`NB2B_PDPCarousel - checkImageAvailability() - imgUrl: "${imgUrl}" is available`);
                    this.setImgUrlAsAvailable(imgUrl);
                    this.setImgUrlAsChecked(imgUrl);
                } catch (error) {
                    console.error(error);
                }
            }).bind(this);

            img.onerror = (function() {
                try {
                    console.log(`NB2B_PDPCarousel - checkImageAvailability() - imgUrl: "${imgUrl}" is not available`);
                    this.setImgUrlAsChecked(imgUrl);
                } catch (error) {
                    console.error(error);
                }
            }).bind(this);
        } catch (error) {
            console.error(error);
        }
    }

    setImgUrlAsChecked(imgUrl) {
        // We use forEach in case there are more than one image with the same url
        this.urlImageWrapperList.forEach(wr => {
            if(wr.imgUrl===imgUrl){
                wr.checked = true;
            }
        });
    }

    setImgUrlAsAvailable(imgUrl) {
        // We use forEach in case there are more than one image with the same url
        this.urlImageWrapperList.forEach(wr => {
            if(wr.imgUrl===imgUrl){
                wr.isAvailable = true;
            }
        });
    }
}