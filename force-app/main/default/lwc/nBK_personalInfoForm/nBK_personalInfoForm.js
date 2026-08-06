import { LightningElement, api,track } from 'lwc';
import initializePicklistValues from '@salesforce/apex/NBK_personalInfoForm_Controller.getPicklistValues';
import getPropertiesFromCountry         from '@salesforce/apex/NBK_FinderStoreController.getPropertiesFromCountry';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent
  } from "lightning/flowSupport";

//LABELS
import tileProduct from '@salesforce/label/c.NBK_tileProduct';
import naturalStoneProduct from '@salesforce/label/c.NBK_naturalStoneProduct';
import mosaicsProduct from '@salesforce/label/c.NBK_mosaicsProduct';
import hardwoodLaminateLVTProduct from '@salesforce/label/c.NBK_hardwoodLaminateLVTProduct';
import bathLabel from '@salesforce/label/c.NBK_bath';
import kitchenLabel from '@salesforce/label/c.NBK_kitchen';
import acceptPrivacyPolicy from '@salesforce/label/c.NBK_acceptPrivacyPolicy';
import firstNameLabel from '@salesforce/label/c.NBK_firstName';
import emailLabel from '@salesforce/label/c.NBK_email';
import countryLabel from '@salesforce/label/c.NBK_country';
import lastNameLabel from '@salesforce/label/c.NBK_lastName';
import phoneLabel from '@salesforce/label/c.NBK_phone';
import streetLabel from '@salesforce/label/c.NBK_street';
import cityLabel from '@salesforce/label/c.NBK_city';
import zipPostalCode from '@salesforce/label/c.NBK_zipPostalCode';
import profileLabel from '@salesforce/label/c.NBK_profile';
import appointmentTypeLabel from '@salesforce/label/c.NBK_appointmentType';
import howAboutUs from '@salesforce/label/c.NBK_howAboutUs';
import howHelpYou from '@salesforce/label/c.NBK_howHelpYou';
import productsInterested from '@salesforce/label/c.NBK_productsInterested';
import suscribeNewsLetter from '@salesforce/label/c.NBK_suscribeNewsletter';
import accept from '@salesforce/label/c.NBK_accept';
import privacyPolicies from '@salesforce/label/c.NBK_privacyPolicies';
import nextLabel from '@salesforce/label/c.NBK_nextButton';
import back from '@salesforce/label/c.NBK_back';
import selectCountry from '@salesforce/label/c.NBK_selectCountry';
import selectCustomerProfile from '@salesforce/label/c.NBK_selectCustomerProfile';
import selectTypeOfAppointment from '@salesforce/label/c.NBK_selectTypeOfAppointment';
import selectState from '@salesforce/label/c.NBK_selectState';
import stateProvince from '@salesforce/label/c.NBK_stateProvince';
import enterDetails from '@salesforce/label/c.NBK_enterDetails';
import customerAddress from '@salesforce/label/c.NBK_CustomAddress';
import appointmentDetails from '@salesforce/label/c.NBK_AppointmentDetails';
import selectedShowroom from '@salesforce/label/c.NBK_selectedShowroom';
import selectedDate from '@salesforce/label/c.NBK_SelectedDate';
import architect from '@salesforce/label/c.NBK_Profile1';
import builder from '@salesforce/label/c.NBK_Profile2';
import consumer from '@salesforce/label/c.NBK_Profile3';
import contractor from '@salesforce/label/c.NBK_Profile4';
import dealer from '@salesforce/label/c.NBK_Profile5';
import designer from '@salesforce/label/c.NBK_Profile6';
import developer from '@salesforce/label/c.NBK_Profile7';
import fabricator from '@salesforce/label/c.NBK_Profile8';
import facade from '@salesforce/label/c.NBK_Profile9';
import installer from '@salesforce/label/c.NBK_Profile10';
import press from '@salesforce/label/c.NBK_Profile11';
import prcustomer from '@salesforce/label/c.NBK_Profile12';
import prmanager from '@salesforce/label/c.NBK_Profile13';
import realtor from '@salesforce/label/c.NBK_Profile14';
import internet from '@salesforce/label/c.NBK_HearAbout1';
import magazine from '@salesforce/label/c.NBK_HearAbout2';
import newspaper from '@salesforce/label/c.NBK_HearAbout3';
import television from '@salesforce/label/c.NBK_HearAbout4';
import showroom from '@salesforce/label/c.NBK_HearAbout5';
import ecustomer from '@salesforce/label/c.NBK_HearAbout6';
import friend from '@salesforce/label/c.NBK_HearAbout7';
import other from '@salesforce/label/c.NBK_HearAbout8';
export default class NBK_personalInfoForm extends LightningElement {
    @api thiscountry;
    @api showAppointmenttype = false;
    @api availableActions = [];
    @api optionsCountry;
    @api optionsStates;
    @api optionsAppointmentType;
    @api showPersonalInfo;
    @api showPicklists;
    @api appointmentType;
    @api preselectedState;

    @api firstName;
    @api lastName;
    @api email;
    @api phone;
    @api postalCode;
    @api street;
    @api city;
    @api help;
    @api privPolicies;
    @api newsletterChecked;
    @api newsletter;
    @api countrySelected;
    @api stateSelected;
    @api profileSelected;
    @api appointmentTypeSelected;
    @api hearAboutSelected;
    @api productsSelected;
    @api previousButton;

    @api selectedDateS;
    @api storeName;

    @track country;
    @track policyPrivacyLink = '';

    label = {
        tileProduct,
        naturalStoneProduct,
        mosaicsProduct,
        hardwoodLaminateLVTProduct,
        bathLabel,
        kitchenLabel,
        acceptPrivacyPolicy,
        firstNameLabel,
        emailLabel,
        countryLabel,
        lastNameLabel,
        phoneLabel,
        streetLabel,
        cityLabel,
        zipPostalCode,
        profileLabel,
        appointmentTypeLabel,
        howAboutUs,
        howHelpYou,
        productsInterested,
        suscribeNewsLetter,
        accept,
        privacyPolicies,
        back,
        nextLabel,
        selectCountry,
        selectCustomerProfile,
        selectTypeOfAppointment,
        selectState,
        stateProvince,
        enterDetails,
        customerAddress,
        appointmentDetails,
        selectedShowroom,
        selectedDate,
				architect,
				builder,
				consumer,
				contractor,
				dealer,
				designer,
				developer,
				fabricator,
				facade,
				installer,
				press,
				prcustomer,
				prmanager,
				realtor,
				internet,
				magazine,
				newspaper,
				showroom,
				television,
				ecustomer,
				friend,
				other
    }


    productsValue = [];

    get countryToUpper() {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get("country").toUpperCase();
    }

    get isUs() {
        return this.countryToUpper == 'US' || this.countryToUpper == 'CA';
    }

    get showAppointmentTypeEditable() {
        return this.isUs && this.storeName !== 'King Of Prussia';
    }

    get options() {
        return [
            { label: this.label.tileProduct, value: 'Tile' },
            { label: this.label.naturalStoneProduct, value: 'Natural Stone' },
            { label: this.label.mosaicsProduct, value: 'Mosaics' },
            { label: this.label.hardwoodLaminateLVTProduct, value: 'Hardwood-Laminate-LVT' },
            { label: this.label.bathLabel, value: 'Bath' },
            { label: this.label.kitchenLabel, value: 'Kitchen' },
        ];
    }
    get optionsProfile() {
        return [
                { label: this.label.architect, value: 'Architect' },
                { label: this.label.builder, value: 'Builder' },
                { label: this.label.consumer, value: 'Consumer' },
                { label: this.label.contractor, value: 'Contractor' },
                { label: this.label.dealer, value: 'Dealer' },
                { label: this.label.designer, value: 'Designer' },
                { label: this.label.developer, value: 'Developer' },
                { label: this.label.fabricator, value: 'Fabricator' },
                { label: this.label.facade, value: 'Facade Consultant' },
                { label: this.label.installer, value: 'Facade Installer' },
                { label: this.label.press, value: 'Press' },
                { label: this.label.prcustomer, value: 'Private Customer' },
                { label: this.label.prmanager, value: 'Project Manager' },
                { label: this.label.realtor, value: 'Realtor' }

        ];
	}
	get optionsHearAbout() {
		return [
				{ label: this.label.internet, value: 'Internet' },
				{ label: this.label.magazine, value: 'Magazine' },
				{ label: this.label.newspaper, value: 'Newspaper' },
				{ label: this.label.television, value: 'Television' },
				{ label: this.label.showroom, value: 'Showroom' },
				{ label: this.label.ecustomer, value: 'Existing Customer' },
				{ label: this.label.friend, value: 'Friend' },
				{ label: this.label.other, value: 'Other' }

		];
}

    connectedCallback(){
        this.initializePicklistValues();
        if(this.preselectedState != undefined){
            this.stateSelected = this.preselectedState;
        }
        this.setCountryForm();
    }

    sendFormToGtm() {
        document.dispatchEvent(
            new CustomEvent("ma_step_3", 
            { "detail" : 
                { 
                    event: "ma_step_3",
                    appointment_category: "make an appointment form",
                    appointment_action: "4_complete_the_form",
                    appointment_label: this.storeName,
                    appointment_form_type_visit: this.appointmentTypeSelected,
                    appointment_form_type_project: this.productsSelected,
                    appointment_form_type_user: this.profileSelected
                 }
            })
        );
    }

    transformDate(format){
        try{
            var date = moment(this.selectedDateS).format(format);
            var hours = moment(this.selectedDateS).format('HH');
            var hoursp = parseInt(moment(this.selectedDateS).format('hh'));
            var minutessp = parseInt(moment(this.selectedDateS).format('mm'));
            var ampm = hours < 12 ? 'AM' : 'PM';
            this.selectedDateS = date+' '+hoursp+':'+minutessp+''+ampm;

        }catch(error){
            console.error(error);
        }
    }

    setCountryForm(){
        getPropertiesFromCountry({country: this.countryToUpper})
            .then(result => {
                if(result != null){
                    this.country = result.nameShown;
                    this.countrySelected = result.nameShown;
                    this.transformDate(result.dateFormat);
                    this.policyPrivacyLink = result.privacyPolicyLink;
                }
            })
        .catch(error => {
            console.error('Error fetching country properties: ', error);
        });
    }

    initializePicklistValues(){
        /*initializePicklistValues({field : 'customerProfile'})
        .then((result) =>{
            this.optionsProfile = result;
        })
        .catch((error) =>{
            console.log('ERROR getPicklistVals' + JSON.stringify(error));
        });

        initializePicklistValues({field : 'hearAbout'})
        .then((result) =>{
            this.optionsHearAbout = result;
        })
        .catch((error) =>{
            console.log('ERROR getPicklistVals' + JSON.stringify(error));
        });
				*/

        initializePicklistValues({field : 'country'})
        .then((result) =>{
            this.optionsCountry = result;
        })
        .catch((error) =>{
            console.log('ERROR getPicklistVals' + JSON.stringify(error));
        });

        initializePicklistValues({field : 'states'})
        .then((result) =>{
            this.optionsStates = result;
        })
        .catch((error) =>{
            console.log('ERROR getPicklistVals' + JSON.stringify(error));
        });

        initializePicklistValues({field : 'appointmentType'})
        .then((result) =>{                       
            this.optionsAppointmentType = result;
            if (this.countryToUpper == 'US' || this.countryToUpper == 'CA') { 
                if (this.storeName == 'King Of Prussia'){
                    this.showAppointmenttype = false;
                    this.appointmentTypeSelected = 'VIRTUAL';
                }else{
                    this.showAppointmenttype = true;
                }
            } else {
                this.showAppointmenttype = false;
                this.appointmentTypeSelected = 'SHOWROOM';
            }
        })
        .catch((error) =>{
            console.log('ERROR getPicklistVals' + JSON.stringify(error));
        });
    }

    handleNext() {
        const validInputs = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

            const validInputsCombobox = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

            const validInputsTextArea = [...this.template.querySelectorAll('lightning-textarea')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);

            let checkbox = this.template.querySelector('[data-id="privacyPolicies"]');
            if(!checkbox.checked){
                checkbox.setCustomValidity(this.label.acceptPrivacyPolicy);
                checkbox.reportValidity();
            }

        if(validInputs && validInputsCombobox && validInputsTextArea && checkbox.checked){
            if (this.availableActions.find((action) => action === "NEXT")) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.previousButton = false;
                this.sendFormToGtm();
                this.dispatchEvent(navigateNextEvent);
            }
        }
    }

    handleBack() {
        if (this.availableActions.find((action) => action === "BACK")) {
            this.previousButton = true;
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }
    handleChangeAddress(event){
        this.street = event.target.street;
        this.city = event.target.city;
        this.postalCode = event.target.postalCode;
        this.countrySelected = event.target.country;
        this.province = event.target.province;
        this.stateSelected = event.target.province;

    }

    handleInputName(event){
        let inputId = event.currentTarget.dataset.id;
        if(inputId === 'name'){
            this.firstName = event.target.value;
        } else if (inputId === 'lastName'){
            this.lastName = event.target.value;
        } else if (inputId === 'email'){
            this.email = event.target.value;

        } else if (inputId === 'phone'){
            this.phone = event.target.value;
        } else if (inputId === 'postalCode'){
            this.postalCode = event.target.value;
        } else if (inputId === 'street'){
            this.street = event.target.value;
        } else if (inputId === 'city'){
            this.city = event.target.value;
        } else if (inputId === 'help'){
            this.help = event.target.value;
        } else if (inputId === 'privacyPolicies'){
            this.privPolicies = event.target.checked;
        } else if (inputId === 'newsletter'){
            this.newsletterChecked = event.target.checked;
        }
    }

    handleChangePicklist(event){
        let inputId = event.currentTarget.dataset.id;
        if(inputId === 'country') {
            this.countrySelected = event.detail.value;
        } else if (inputId === 'state') {
            this.stateSelected = event.detail.value;
        } else if (inputId === 'profile') {
            this.profileSelected = event.detail.value;
        } else if (inputId === 'hearAbout') {
            this.hearAboutSelected = event.detail.value;
        } else if (inputId === 'appointmentType') {
            this.appointmentTypeSelected = event.detail.value;
        }
    }

    handleChangeProducts(event){
        if(this.productsValue != undefined){
            this.productsSelected = event.detail.value.join(',');
        }
    }

allowSubmit;

}