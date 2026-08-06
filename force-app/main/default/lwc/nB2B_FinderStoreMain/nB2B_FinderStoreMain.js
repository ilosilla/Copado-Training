/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 01-12-2023
 * @group        :
 * @see          :
**/
import { LightningElement, api, track  } from 'lwc';

import {FlowNavigationNextEvent}        from "lightning/flowSupport";
import { FlowAttributeChangeEvent }     from 'lightning/flowSupport';
import { ShowToastEvent }               from 'lightning/platformShowToastEvent';
import { getLocationService }           from 'lightning/mobileCapabilities';
import AppointmentImgNotFound from '@salesforce/resourceUrl/AppointmentImgNotFound';

/* APEX IMPORTS */
import getInitialStores                 from '@salesforce/apex/NBK_FinderStoreController.getInitialStores';
import getInitialAssociates             from '@salesforce/apex/NBK_FinderStoreController.getInitialAssociates';
import searchStores                     from '@salesforce/apex/NBK_FinderStoreController.searchStores';
import searchAssociates                 from '@salesforce/apex/NBK_FinderStoreController.searchAssociates';
import searchAllStoresFromCountry       from '@salesforce/apex/NBK_FinderStoreController.searchAllStoresFromCountry';
import getAddressPosition               from '@salesforce/apex/NBK_FinderStoreController.getAddressPosition';
import getPropertiesFromCountry         from '@salesforce/apex/NBK_FinderStoreController.getPropertiesFromCountry';

/* LABELS IMPORTS */
import distanceCalculateFrom            from '@salesforce/label/c.NBK_DistanceCalculateFrom';
import appointmentInStore               from '@salesforce/label/c.NBK_AppointmentInStore';
import ziporcity                        from '@salesforce/label/c.NBK_ZipOrCity';
import storelisting                     from '@salesforce/label/c.NBK_StoreListing';
import seeAllStores                     from '@salesforce/label/c.NBK_SeeAllStores';
import bookAndAppointment               from '@salesforce/label/c.NBK_BookAndAppointment';
import back                             from '@salesforce/label/c.NBK_back';
import error1                           from '@salesforce/label/c.NBK_AppointmentErro1';
import error2                           from '@salesforce/label/c.NBK_AppointmentErro2';
import attention                        from '@salesforce/label/c.NBK_Attention';
import toast1                        		from '@salesforce/label/c.NBK_ToastAddres1';
import toast2                       		from '@salesforce/label/c.NBK_ToastAddres2';



export default class NB2B_FinderStoreMain extends LightningElement {

    @track storeList;
    @track associateList;
    @track loaded = false;
    @track selStreet;
    @track selCity;
    @track selCountry;
    @track selPostalCode;
    @track selProvince;
    @track selState;
    @track selLatitude;
    @track selLongitude;
    @api storeid;
    @api country;
    @api selectedStore;
    @track latIni;
    @track lonIni;
    @track imagenUrl = AppointmentImgNotFound;
    userLat;
    userLon;
    mapMarkers = [];
    mapMarkersFromSF = [];
    @track zoomLevel = 6;
    @track center;
    @track showAllStores = false;
    countryAuxi;
    @track numberAssocies;
    @track associeStores;

    //VARIABLES ZOOM
    @track zoomGeneral=6;
    @track zoomFinderCity=6;
    @track zoomFinderState=6;
    @track zoomFinderCountry=6;
    @track zoomStore=6;

		@track calculateFrom;
		@track showToastBar = false;
		@track label1 = toast1;
		@track label2 = toast2;

    labels = {
        distanceCalculateFrom,
        appointmentInStore,
        ziporcity,
        storelisting,
        seeAllStores,
        bookAndAppointment,
        back,
        error1,
        attention,
        error2
    }

    mapOptions = {
        zoomControl: true,
        disableDefaultUI: false,
    };

    get isFrance() {
        return this.country.toUpperCase() == 'FR';
    }

    get isUnitedStates() {
        return this.country.toUpperCase() == 'US';
    }


    async connectedCallback(){
        try{
            this.loadingOn();
            //await this.getLocationSync();
            await Promise.race([this.getLocationSync(), new Promise(resolve => setTimeout(resolve, 4000))]);
            this.initSync();
        } catch (error) {
            console.error(error);
        }
    }

    initSync() {
        this.initLoad("country");
    }

     getLocationSync() {
        return new Promise((resolve, reject) => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(position => {

                    // Get the Latitude and Longitude from Geolocation API
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;
                    this.userLat = latitude;
                    this.userLon = longitude;
                    //PRUEBA
                    //this.userLat = 37.736070724069734;
                    //this.userLon = -122.42755834217614;
                    resolve();
                });
            }
        });
    }


    initLoad(param){
        this.loadingOn();
        const urlParams     = new URLSearchParams(window.location.search);
        this.country        = urlParams.get(param);
        const attributeChangeEvent = new FlowAttributeChangeEvent('country', this.country);
        this.dispatchEvent(attributeChangeEvent);
        getPropertiesFromCountry({country: this.country})
            .then(result => {
                if(result != null){
                    if(this.userLat == null && this.userLon == null){
                        this.latIni         = result.latitude;
                        this.lonIni         = result.longitude;
                    }else{
                        this.latIni         = this.userLat;
                        this.lonIni         = this.userLon
                    }
                    this.zoomGeneral        = result.zoomGeneral;
                    this.zoomStore          = result.zoomStore;
                    this.zoomFinderCity     = result.zoomFinder;
                    this.zoomFinderState    = result.zoomFinderState;
                    this.zoomFinderCountry  = result.zoomFinderCountry;
                    this.countryAuxi        = result.countryAuxi;

                    //Centrar el mapa
                    this.center = {
                                location: {Latitude: this.latIni,Longitude: this.lonIni,},

                            };

                    //Inital zoom
                    this.zoomLevel = this.zoomGeneral;

                    //Busqueda inical de tiendas
                    this.getInitalStores();
                    this.getInitalAssociates();
                }
            })
            .catch(error => {
               console.log('error:'+JSON.stringify(error));
               this.loadingOff();
            });

    }

    // INITAL METHOD LOAD STORES BY COUNTRY
    getInitalAssociates() {
        getInitialAssociates({latitude : this.latIni, longitude : this.lonIni, country:this.country})
        .then(result => {
            console.log(this.country);
            console.log(result);
            this.associateList = result;
            this.setAssociateLocationsMaps(result);

            this.loadingOff();
        })
        .catch(error => {
           console.log('error:'+JSON.stringify(error));
           this.loadingOff();
        });
    }

    // INITAL METHOD LOAD STORES BY COUNTRY
    getInitalStores() {
            getInitialStores({latitude : this.latIni, longitude : this.lonIni, country:this.country})
            .then(result => {
                console.log('STORES')
                console.log(result)
                console.log(this.country)
                this.storeList = result;

                if(result != null){
                    this.sortStores();
                    this.setStoreLocationsMaps(result);
                    //obtener lugar inicial
                    getAddressPosition({lat : this.latIni, lon : this.lonIni, country: this.country})
                        .then(result => {
                            this.selCity = result;
														this.calculateFrom = result;
                        })
                        .catch(error => {
                            console.log('error:'+JSON.stringify(error));
                            this.loadingOff();
                        });
                }else{
                    const event = new ShowToastEvent({
                        title: attention,
                        message: error2,
                        variant: 'error',
                    });
                    this.dispatchEvent(event);
                }

                this.loadingOff();
            })
            .catch(error => {
               console.log('error:'+JSON.stringify(error));
               this.loadingOff();
            });
    }

    //LOAD MARKERS OF ALL STORES
    setStoreLocationsMaps( result ){
        var mapaAuxi = [];
        try{
            result.forEach(function(element) {
                if(element.address.NBK_Address__Latitude__s != null && element.address.NBK_Address__Longitude__s != null){
                    var descriptionCity = '';
            
                    if(element.address.NBK_Address__c.state == undefined || element.address.NBK_Address__c.state == null || element.address.NBK_Address__c.state == ''){
                        descriptionCity = element.address.NBK_Address__c.street+" , "+element.address.NBK_Address__c.postalCode+" , "+element.address.NBK_Address__c.city
                    }else{
                        descriptionCity = element.address.NBK_Address__c.street+" , "+element.address.NBK_Address__c.postalCode+" , "+element.address.NBK_Address__c.state
                    }    

                    let marker = {
                        location: {
                            Latitude:element.address.NBK_Address__Latitude__s,
                            Longitude: element.address.NBK_Address__Longitude__s

                        },  value: element.address.Id,
                            title: element.address.Name,
                            description: descriptionCity
                        };

                    mapaAuxi.push(marker);
                }
            });
        }catch(error){
            console.error(error);
        }
        this.mapMarkers = [];
        this.mapMarkersFromSF = [...mapaAuxi];
        this.mapMarkers = this.mapMarkersFromSF;
    }

    //LOAD MARKERS OF ALL STORES
    setAssociateLocationsMaps( result ){
        var mapaAuxi = [];
        try{
            result.forEach(function(element) {
                console.log('ASSOCIATE')
                if(element.address.NBK_Address__Latitude__s != null && element.address.NBK_Address__Longitude__s != null){
                    let marker = {
                        location: {
                            Latitude:element.address.NBK_Address__Latitude__s,
                            Longitude: element.address.NBK_Address__Longitude__s

                        },  value: element.address.Name,
                            title: element.address.Name,
                            description: element.address.NBK_Address__Street__s+" , "+element.address.NBK_Address__PostalCode__s
                        };

                    mapaAuxi.push(marker);
                }
            });
        }catch(error){
            console.error(error);
        }
        console.log(mapaAuxi);
        //this.mapMarkers = [];
        this.mapMarkersFromSF = [...mapaAuxi];
        this.mapMarkers = this.mapMarkers.concat(this.mapMarkersFromSF);
    }

    loadingOn(){
        this.loaded = true;
    }

    loadingOff(){
        this.loaded = false;
        this.numberStores = this.storeList?.length;
        this.numberAssocies = this.associateList?.length;
    }

		closeModelToast(){
			this.showToastBar = false;
		}

		toastSeeAllStores(){
			this.showToastBar = false;
			this.showAllStores = true;
		}

    //CHANGE ADDRESS EVENT WHEN SELECT NEW ADDRESS FROM INPUT
    handleChangeAddress(event){
        console.log('handleChangeAddress');

        this.selStreet      = event.target.street;
        this.selCity        = event.target.city;
        this.selPostalCode  = event.target.postalCode;
        this.selCountry     = event.target.country;
        this.selProvince    = event.target.province;
        // console.log('this.selStreet:'+this.selStreet);
				// console.log('this.selCity:'+this.selCity);
				// console.log('this.selPostalCode:'+this.selPostalCode);
				// console.log('this.selCountry:'+this.selCountry);
				// console.log('this.selProvince:'+this.selProvince);

				if(this.country.toUpperCase() == 'UK' && this.selCountry != 'United Kingdom'){
						this.selCountry='';
						this.selCity='';
						this.selPostalCode='';
						this.selProvince='';
						this.selStreet='';
				}
				if(this.country.toUpperCase() == 'FR' && this.selCountry != 'France'){
					this.selCountry='';
					this.selCity='';
					this.selPostalCode='';
					this.selProvince='';
					this.selStreet='';
				}
				//Para cuando busca por estado o pais
				if(this.selCity != null && this.selCity != '' && this.selCity != undefined){
					this.calculateFrom = this.selCity;
				}else if(this.selProvince != null && this.selProvince != '' && this.selProvince != undefined){
					this.calculateFrom = this.selProvince;
				}else if(this.selCountry != null && this.selCountry != '' && this.selCountry != undefined){
					this.calculateFrom = this.selCountry;
				}

				//casuistica para UK. El input de google no devuelve direcciones para ciertos condados.
				// Si en todos los datos del evento el valor es null, habría que intentar buscar en openstreetmaps ese valor
				if((this.country.toUpperCase() == 'UK' || this.country.toUpperCase() == 'FR') && this.selCity == '' && this.selProvince == '' && this.selStreet == ''){
					this.showToastBar = true;
					  setTimeout(() => {
              this.closeModelToast();
        	  }, 6000);
						return;
				}else{
					if(this.country.toUpperCase() == 'UK'){
							this.center = {
									location: {City: this.selCity,Street: this.selStreet,State: this.selProvince,Country: this.selCountry},
											title: this.selCity,
											description: this.selCity+' , '+this.selCountry};
					}else{
							this.center = {
							location: {City: this.selCity,State: this.selProvince,Country: this.selCountry},
									title: this.selCity,
									description: this.selCity+' , '+this.selCountry};
					}
					this.setCenterInMap(this.selStreet,this.selCity,this.selProvince,this.selCountry);
					this.setZoom(this.selStreet,this.selCity,this.selCountry,this.selProvince);

					try{
							this.searchStores();
					}catch(e){
							console.error(e);
					}
				}


    }


    setCenterInMap(street,city,state,country){
        try{
            //Buscar en el mapa el elemento con title Distance to stores calculated from here
            var mapaAuxi = [];
            var search = false;
            try{
                this.mapMarkers.forEach(function(element) {
                    if(element.title == 'Distance to stores calculated from here'){
                        search = true;
                        //cambiamos el centro
                        let marker = {
                                location: {City: city != undefined ? city : '',Street: street != undefined ? street : '',State: state != undefined ? state : '',Country: country != undefined ? country : ''},
                            title: 'Distance to stores calculated from here',
                            icon: 'utility:account',
                            mapIcon: {path: 'M 0,0 C -2,-20 -10,-22 -10,-30 A 10,10 0 1,1 10,-30 C 10,-22 2,-20 0,0 z',fillColor: 'gold',fillOpacity: 1,strokeOpacity: 1,strokeColor: '#000',strokeWeight: 1,scale: 0.5}
                        };
                        mapaAuxi.push(marker);
                    }else{
                        mapaAuxi.push(element);
                    }
                });

                if(search == false){
                    // SI no lo encuentra meter uno nuevo
                    let marker = {
                                location: {City: city != undefined ? city : '',Street: street != undefined ? street : '',State: state != undefined ? state : '',Country: country != undefined ? country : ''},
                            title: 'Distance to stores calculated from here',
                            icon: 'utility:account',
                            mapIcon: {path: 'M 0,0 C -2,-20 -10,-22 -10,-30 A 10,10 0 1,1 10,-30 C 10,-22 2,-20 0,0 z',fillColor: 'gold',fillOpacity: 1,strokeOpacity: 1,strokeColor: '#000',strokeWeight: 1,scale: 0.5}
                        };
                        mapaAuxi.push(marker);
                }
            }catch(error){
                console.error(error);
            }
            this.mapMarkers = [];
            this.mapMarkers = [...mapaAuxi];
        }catch(error){
            console.error(error);
        }
    }


    setZoom(street,city,country,province){
        //console.log('setZoom');
        //console.log('this.zoomLevel INI:'+this.zoomLevel);
        //Diferencia el zoom del mapa que debe tomar dependiendo de lo que se busque.
        if(this.notNullValue(city) || this.notNullValue(street)){
            //console.log('zoom level city');
            this.zoomLevel = this.zoomFinderCity;
        }else if(this.notNullValue(province)){
            //console.log('zoom level state');
            this.zoomLevel = this.zoomFinderState;
        }else{
            //console.log('zoom level country');
            this.zoomLevel = this.zoomFinderCountry;
        }
       // console.log('this.zoomLevel FIN:'+this.zoomLevel);
    }

    notNullValue(value){
        if(value != null && value != '' && value != undefined){
            return true;
        }else{
            return false;
        }
    }

    quitarAcentos(cadena){
        const acentos = {'á':'a','é':'e','í':'i','ó':'o','ú':'u','Á':'A','É':'E','Í':'I','Ó':'O','Ú':'U','à':'a','è':'e','ì':'i','ò':'o','ù':'u','À':'A','È':'E','Ì':'I','Ò':'O','Ù':'U','ä':'a','ë':'e','ï':'i','ö':'o','ü':'u','Ä':'A','Ë':'E','Ï':'I','Ö':'O','Ü':'U','â':'a','ê':'e','î':'i','ô':'o','û':'u','Â':'A','Ê':'E','Î':'I','Ô':'O','Û':'U'};
        return cadena.split('').map( letra => acentos[letra] || letra).join('').toString();	
    }
    
    searchStores(){
        this.loadingOn();
        console.log('searchStores');
        console.log('this.selStreet:'+this.selStreet);
        console.log('this.selCity:'+this.selCity);
        console.log('this.selCity SIN ACENTOS:'+this.quitarAcentos(this.selCity));
        console.log('this.selPostalCode:'+this.selPostalCode);
        console.log('this.selProvince:'+this.selProvince);
        console.log('this.country:'+this.country);
        console.log('this.selcountry:'+this.selCountry);
        //Mapeo para US CA
        var countryAuxi;
        if(this.selCountry == 'United States'){
            countryAuxi = 'US';
        }else if(this.selCountry == 'Canada'){
             countryAuxi = 'CA';
        }else{
            countryAuxi = this.country;
        }
        this.selCity = this.quitarAcentos(this.selCity);

        searchStores({street: this.selStreet, city : this.selCity, postalcode : this.selPostalCode, province: this.selProvince, country: countryAuxi})
            .then(result => {
                //console.log('result:'+JSON.stringify(result));
                this.storeList = result;
                if(result != null){
                    this.sortStoresByDistance();
                }
                this.loadingOff();
            })
            .catch(error => {
               console.log('error:'+JSON.stringify(error));
               this.loadingOff();
            });

        searchAssociates({street: this.selStreet, city : this.selCity, postalcode : this.selPostalCode, province: this.selProvince, country: countryAuxi})
        .then(result => {
            //console.log('result:'+JSON.stringify(result));
            this.associateList = result;
            if(result != null){
                this.sortAssociatesByDistance();
            }
            this.loadingOff();
        })
        .catch(error => {
            console.log('error:'+JSON.stringify(error));
            this.loadingOff();
        });

    }

    searchAllStores(){
        this.loadingOn();

        searchAllStoresFromCountry({ country: this.country})
            .then(result => {
                this.storeList = [];
                this.storeList = result;
                //console.log('searchall result:'+result);
                if(result != null){
                    this.sortStores();
                }
                this.loadingOff();
            })
            .catch(error => {
               console.log('error:'+JSON.stringify(error));
               this.loadingOff();
            });
    }

    setCenterMap(markercent){
        this.center = markercent;
    }

    handleselectedstore(event){
        this.dispatchEvent(new FlowAttributeChangeEvent('storeid', event.detail));
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handlechangeposition(event){
        var mapaAuxi = [];
        //recorrer las tiendas y hacer zoom sobre su lat y long
        try{

            let elementFound = this.storeList.find(element => {
                return element.address.Id == event.detail && element.address.NBK_Address__Latitude__s != null && element.address.NBK_Address__Longitude__s != null;
            });
            var descriptionCity = '';
            
            if(elementFound.address.NBK_Address__c.state == undefined || elementFound.address.NBK_Address__c.state == null || elementFound.address.NBK_Address__c.state == ''){
                descriptionCity = elementFound.address.NBK_Address__c.street+" , "+elementFound.address.NBK_Address__c.postalCode+" , "+elementFound.address.NBK_Address__c.city
            }else{
                descriptionCity = elementFound.address.NBK_Address__c.street+" , "+elementFound.address.NBK_Address__c.postalCode+" , "+elementFound.address.NBK_Address__c.state
            }

            this.center = {
                location: {
                    Latitude: elementFound.address.NBK_Address__Latitude__s,
                    Longitude: elementFound.address.NBK_Address__Longitude__s

                },  value: elementFound.address.Id,
                    title: elementFound.address.Name,
                    description: descriptionCity
            };

        }catch(error){
            console.error(error);
        }
        this.zoomLevel = this.zoomStore;
    }

    handlechangepositionAssociates(event){
        try{
            let elementFound = this.associateList.find(element => {
                return element.address.Name == event.currentTarget.dataset.name && element.address.NBK_Address__Latitude__s != null && element.address.NBK_Address__Longitude__s != null;
            });

            this.center = {
                location: {
                    Latitude: elementFound.address.NBK_Address__Latitude__s,
                    Longitude: elementFound.address.NBK_Address__Longitude__s

                },  value: elementFound.address.Name,
                    title: elementFound.address.Name,
                    description: elementFound.address.NBK_Address__street__s+" , "+elementFound.address.NBK_Address__PostalCode__s
            };

        }catch(error){
            console.error(error);
        }
        this.zoomLevel = this.zoomStore;
    }

    seeAllStoresEvent(){
        this.showAllStores = true;
        this.searchAllStores();
    }

    seeAllStoresBack(){
        this.sortStores();
        this.showAllStores = false;
        this.initLoad("country");
        this.getInitalStores();
        this.getInitalAssociates();
        this.zoomLevel = this.zoomGeneral;
    }

    sortStores(){
        try{
            function compare( a, b ) {
                //console.log('a.address.Name:'+a.address.Name);
                //console.log('b.address.Name:'+b.address.Name);
            if ( a.address.Name < b.address.Name ){return -1;}
            if ( a.address.Name > b.address.Name ){return 1;}
            return 0;
            }
            this.storeList.sort( compare );
        }catch(error){
            console.error(error);
        }

    }

    sortStoresByDistance(){
        function compare( a, b ) {
        if ( a.distance < b.distance ){return -1;}
        if ( a.distance > b.distance ){return 1;}
        return 0;
        }
        this.storeList.sort( compare );
    }

    sortAssociatesByDistance(){
        function compare( a, b ) {
        if ( a.distance < b.distance ){return -1;}
        if ( a.distance > b.distance ){return 1;}
        return 0;
        }
        this.associateList.sort( compare );
        this.associateList = this.associateList.slice(0,2)
    }



}