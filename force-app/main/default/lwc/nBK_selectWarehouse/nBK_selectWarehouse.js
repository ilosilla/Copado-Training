import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
//CSS
import overrideMap from '@salesforce/resourceUrl/nBK_selectWarehouse';
//APEX CLASSES
import allWarehousesByState from '@salesforce/apex/NBK_selectWarehouseController.getWarehousesByState';
import getStatePicklistVal from '@salesforce/apex/NBK_selectWarehouseController.getStatePicklist';
import initMap from '@salesforce/apex/NBK_selectWarehouseController.initializeMap';

export default class NBK_selectWarehouse extends LightningElement {

    @api warehousesList = [];
    @api optionsStates = [];
    @api stateVal;
    @api markers = [];
    @api selectedMarkers = [];
    @track showMap = false;
    @track showMapSelection = false;

    //Variable output para el flow 
    @api nameWithAddress;

    connectedCallback(){
        this.getPicklistVals();
        this.initializeMarkersMap();
    }

    renderedCallback() {
        //console.log('# Entro en renderedCallback');
        Promise.all([loadStyle(this, overrideMap)]);
        //console.log('# Salgo en renderedCallback');
    }

    getPicklistVals(){
        getStatePicklistVal({})
        .then((result) =>{
            //console.log('# Result de getPicklistVals ' + JSON.stringify(result));
            this.optionsStates = result;
            console.log("states: "+JSON.stringify(result));
        })
        .catch((error) =>{
            //console.log('ERROR getPicklistVals' + JSON.stringify(error));
        })
    }

    initializeMarkersMap(){
        initMap({})
        .then((result) =>{
            this.markers = result;
            //console.log('# Result de initializeMarkersMap ' + JSON.stringify(this.markers));
            this.showMap = true;
            this.showMapSelection = false;
        })
        .catch((error) =>{
            //console.log('ERROR initializeMarkersMap' + JSON.stringify(error));
        })
    }

    getPorcelanosaAdresses(event){
        let country;
        if(event.detail.value == 'CANADA'){
            country = 'CA';
        }else{
            country = 'US';
        }
        console.log("country: "+country);
        console.log("state: "+event.detail.value);
        //console.log('# Inicio getPorcelanosaAdresses valor de stateVal ' + event.detail.value);
        allWarehousesByState({country : country, state : event.detail.value})
        .then((result) =>{
            //console.log('# Result de getPorcelanosaAdresses ' + JSON.stringify(result));
            this.warehousesList = result;
        })
        .catch((error) =>{
            //console.log('ERROR getPorcelanosaAdresses' + JSON.stringify(error));
        });
    }

    handleChooseWarehouse(event){
        //console.log('# onclick choose warehouse ' + JSON.stringify(event.currentTarget.dataset.id));
        let warehouseName = event.currentTarget.dataset.id;
        this.markWarehouseSelectedOnMap(warehouseName);
        //console.log('# onclick choose warehouse get name' + JSON.stringify(event.currentTarget.dataset.name))
        this.nameWithAddress = event.currentTarget.dataset.name;
    }

    markWarehouseSelectedOnMap(warehouseName){
        this.showMap = false;
        this.showMapSelection = true;
        //console.log('# markWarehouseSelectedOnMap input warehouseName ' + warehouseName);
        let auxMarkers = [];
        this.markers.forEach(element => {
            //console.log('# markWarehouseSelectedOnMap element ' + JSON.stringify(element));
            if(element.value === warehouseName){
                auxMarkers = [...auxMarkers, element];
            }
        });
        //console.log('# markWarehouseSelectedOnMap auxMarkers list ' + JSON.stringify(auxMarkers));
        if(auxMarkers.length != 0){
            this.selectedMarkers = [];
            this.selectedMarkers = auxMarkers;
        }
        //console.log('# markWarehouseSelectedOnMap end markers list ' + JSON.stringify(this.markers));
    }

}