import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import getControllerData from '@salesforce/apex/NBK_ControllerExecuter.getControllerData';
import executeAction from '@salesforce/apex/NBK_ControllerExecuter.executeAction';

const ERROR_TOAST_VARIANT = 'error';
const WARING_TOAST_VARIANT = 'warning';

export default class LwcUtils extends NavigationMixin(LightningElement) {
    @track
    showSpinner;

    @track
    errorMessage;

    @api
    set toggleSpinner(value){
        this.showSpinner = value;
    }
    get toggleSpinner(){
        return this.showSpinner;
    }

    handleDoInit(event){
        return event.detail.eventData;
    }


    /* ----------------------- */
    /* -------  WIRING ------- */
    /* ----------------------- */

    //Params To Wire
    controllerParams;

    //RefreshData
    wireControllerResult;

    @wire(getControllerData, {dataJSON:'$controllerParams'})
    imperativeWiring(result) {
        this.wireControllerResult = result;
        try{
            if (result.data) {
                const response = JSON.parse(result.data);

                if(response.success){
                    let data = JSON.parse(response.dataJSON);
                    this.fireEvent('doInit', data, false, null);
                }else{
                    console.error('response.errorMsg', response.errorMsg);
                }
            }
        }catch(e){
            this.showToast('Error!', 'Error getting data', 'error');
        }
    }

    executeRemoteAction(dataJSON) {
        return new Promise(function(resolve, reject){
            try{
                executeAction({ dataJSON })
                    .then(JSONResponse => {
                        let response = JSON.parse(JSONResponse);
                        if(response.success){
                            let data = JSON.parse(response.dataJSON);
                            resolve(data);
                        }else if(response.validationMsg){
                            console.error('LwcUtils - executeRemoteAction() - response:', response);
                            reject({
                                ...response,
                                isRemoteAction: true,
                            });
                        }else{
                            reject(response.errorMsg);
                        }
                    })
                    .catch(error => {
                        reject(error);
                    });
            }catch(e){
                reject(e);
            }
        });
    }
    executeRemoteAction2(dataJSON) {
        return new Promise(function(resolve, reject){
            try{
                executeAction({ dataJSON })
                    .then(JSONResponse => {
                        let response = JSON.parse(JSONResponse);
                        if(response.success){
                            //let data = JSON.parse(response.dataJSON);
                            resolve(response);
                        }else{
                            reject(response.errorMsg);
                        }
                    })
                    .catch(error => {
                        reject(error);
                    });
            }catch(e){
                reject(e);
            }
        });
    }

    //Refresh ALWAYS from Server
    fetch(controller, actionName, params){
        if(this.wireControllerResult && this.wireControllerResult.data !== undefined){
            this.refreshData();
        }else{
            params.timeStamp = Date.now();
            this.remote(controller, actionName, params);
        }
    }

    remote(controller, actionName, params){
        params.controller = controller;
        params.actionName = actionName;
        this.controllerParams = JSON.stringify(params);
    }

    refreshData() {
        return refreshApex(this.wireControllerResult);
    }

    /* ----------------------- */
    /* ----- END WIRING ------ */
    /* ----------------------- */

    fireEvent(eventName, eventData, bubbles, composed){
        const evt = new CustomEvent(eventName, {
            detail: {eventData},
            bubbles: bubbles,
            composed: composed
        });
        // Fire the custom event
        this.dispatchEvent(evt);
    }

    eventData(fieldName, objectValue){
        return {
            name: fieldName,
            value: objectValue
        };
    }

    showToast(title, message, variant){
        const event = new ShowToastEvent({
            'title': title,
            'message': message,
            'variant':variant,
            'mode':'pester'
        });
        this.dispatchEvent(event);
    }

    navigate(event){
        let redirectTo = event.detail.eventData;
        this.fireEvent('navigate', redirectTo);
    }

    scrollToElement(event){
        let element = this.template.querySelector(event.detail.eventData);
        element.scrollIntoView({ block: 'end',  behavior: 'smooth' });
    }

    fireGenericEvt(evtName,data){
        try{
            this.dispatchEvent(
                new CustomEvent('genericevt',{
                    bubbles: true,
                    detail: {
                        evtName: evtName,
                        data: data
                    }
                })
            );
        }catch(e){console.error(e);}
    }

    showModal(modalViewData){
        try{
            this.fireGenericEvt('showModal',modalViewData);
        }catch(e){console.error(e);}
    }

    uuidv4() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    manageError(e){
        let errMsgStr = '';

        if(e.isRemoteAction){
            errMsgStr = e.validationMsg ? e.validationMsg : e.errorMsg;
        }else{
            errMsgStr = ((typeof e === 'string') ? e : (e.body?.message || e.message));
        }

        this.showToast(
            'Error',
            errMsgStr,
            e.validationMsg ? WARING_TOAST_VARIANT : ERROR_TOAST_VARIANT
        );

        console.error(e);
    }

    navigateToSObject(recordId,sObjectName,blankTarget){
        if(!blankTarget){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: sObjectName,
                    actionName: 'view'
                }
            });
        }else{
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: sObjectName,
                    actionName: 'view'
                }
            }).then((url) => {window.open(url,'_blank');} );
        }


    }

    loadResources(resources){
        try{
            let self = this;
            let promises = [];
            if(resources){
                if(resources.styles) resources.styles.forEach((resourceUrl)=>{ promises.push(loadStyle(self,resourceUrl)); });
                if(resources.scripts) resources.scripts.forEach((resourceUrl)=>{ promises.push(loadScript(self,resourceUrl)); });
                return Promise.all(promises);
            }else{
                return new Promise((resolve,reject)=>{resolve(null);});
            }
        }catch(e){ return new Promise((resolve,reject)=>{ reject(e); }); }
    }

    parseObject(obj){
        return obj? JSON.parse(JSON.stringify(obj)) : obj;
    }

    guid() {
        return (
            this.S4() +
            this.S4() +
            "-" +
            this.S4() +
            "-4" +
            this.S4().substring(0, 3) +
            "-" +
            this.S4() +
            "-" +
            this.S4() +
            this.S4() +
            this.S4()
        ).toLowerCase();
    }

    S4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
}