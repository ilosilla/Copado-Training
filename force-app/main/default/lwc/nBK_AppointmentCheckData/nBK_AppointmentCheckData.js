import { LightningElement,api,track } from 'lwc';
import {
  FlowNavigationBackEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";
import registerError from '@salesforce/apex/NBK_AppointmentCheckDataCtr.registerError';
import nBK_AppointmentDataError from '@salesforce/label/c.NBK_AppointmentDataError';


export default class NBK_AppointmentCheckData extends LightningElement {

    @api selectedStore;
    @api currentSelectedDateTime;
    @api businessHours;
    @track showwating = true;
    latitude;
    longitude;

    label = {
        nBK_AppointmentDataError
    };

    connectedCallback() {
        //this.checkPosition();
        console.log('connectedCallback');
        console.log('currentSelectedDateTime:'+this.currentSelectedDateTime);
        console.log('businessHours:'+JSON.stringify(this.businessHours));
        this.checkDaySelectedParent();
    }

     async checkDaySelectedParent() {
        try {
            // Llama al primer método y espera a que termine
            console.log('Primer metodo');
            await this.checkPositionAsync();

            // Una vez que firstMethod haya terminado, llama al segundo método
            console.log('segundo metodo');
            this.checkDaySelected();
        } catch (error) {
            console.error(error);
        }
    }

    checkPositionAsync() {
        return new Promise((resolve) => {
               console.log('BUSCANDO POSICION GEOGRAFICA');
                navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;

                    console.log('Latitud:'+ this.latitude+', Longitud:'+this.longitude );
            
                    resolve();
                },
                (error) => {
                    console.error('Error al obtener la ubicación:', error);
                    resolve();
                }
                );
        });
    }

    checkPosition(){
        try{
            navigator.geolocation.getCurrentPosition(
            (position) => {
                this.latitude = position.coords.latitude;
                this.longitude = position.coords.longitude;
                console.log('Latitud:'+ latitude+', Longitud:'+longitude );
            },
            (error) => {
                console.error('Error al obtener la ubicación:', error);
            }
            );
        }catch(error2){
            console.log(error2);
        }
    }

    checkDaySelected(){
        var errorCheck = false;
        //Comprobar si el día está dentro de las business Hours para esa tienda.
        console.log('fecha seleccionada es:'+this.currentSelectedDateTime);
        //Desmembrar la fecha en dia y hora
        var fechaS = this.currentSelectedDateTime.substring(0, 10);
        var horaS = this.currentSelectedDateTime.substring(11, 19);
        console.log('fechaS:'+fechaS);
        console.log('horaS:'+horaS);

        const dateString = fechaS;

        // Paso 1: Crear un objeto Date a partir del string
        const dateObj = new Date(dateString);
        console.log('dateObj:'+dateObj);

        // Paso 2: Obtener el día de la semana (0: Domingo, 1: Lunes, ..., 6: Sábado)
        const dayOfWeek = dateObj.getDay();

        // Paso 3: Mapear el número del día de la semana a su nombre
        const daysOfWeekNames = ['Sun', 'Mon', 'Tue', 'Wen', 'Thu', 'Fri', 'Sat'];
        var dayName = daysOfWeekNames[dayOfWeek];
        console.log('Fecha en formato Date:', dateObj);
        console.log('Día de la semana:', dayName);
        

        //PRUEBA
        //dayName = 'Sun';

        //Paso 4: Comprobar si en ese dia de la semana la tienda en cuestion está abierta
        if(dayName == 'Mon' && (this.businessHours.MondayStartTime == null || this.businessHours.MondayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Tue' && (this.businessHours.TuesdayStartTime == null || this.businessHours.TuesdayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Wen' && (this.businessHours.WednesdayStartTime == null || this.businessHours.WednesdayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Thu' && (this.businessHours.ThursdayStartTime == null || this.businessHours.ThursdayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Fri' && (this.businessHours.FridayStartTime == null || this.businessHours.FridayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Sat' && (this.businessHours.SaturdayStartTime == null || this.businessHours.SaturdayEndTime == null)){
            errorCheck = true;
        }else if(dayName == 'Sun' && (this.businessHours.SundayStartTime == null || this.businessHours.SundayEndTime == null)){
            errorCheck = true;
        }

        if(errorCheck == true){
            console.log('Hay error disparar procedimento');
            this.showwating = false;
            var bodyS = '';
            //Inicio procedimiento de error.
            //Paso 1: Recuperamos datos del Navegador
            try{
                const browserInfo = {
                    userAgent: window.navigator.userAgent,
                    appName: window.navigator.appName,
                    appVersion: window.navigator.appVersion,
                    platform: window.navigator.platform,
                    language: window.navigator.language,
                };

                console.log('browserInfo:'+JSON.stringify(browserInfo));
                bodyS = bodyS + ',INFORMACIÓN NAVEGADOR:'+JSON.stringify(browserInfo);
            }catch(error1){
                console.log(error1);
            }
            
            // Obtener la hora actual
            const currentTime = new Date();
            console.log('HORA ACTUAL USUARIO:', currentTime);
            bodyS = bodyS + ','+'HORA ACTUAL USUARIO:'+ currentTime;

            // Obtener la zona horaria del navegador
            const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            console.log('ZONA HORARIA USUARIO:', timeZone);
            bodyS = bodyS + ','+'ZONA HORARIA USUARIO:'+ timeZone;

            if(this.latitude != null && this.longitude != null){
                bodyS = bodyS + ','+'POSICION GEOGRAFICA USUARIO: Latitud:'+ this.latitude+', Longitud:'+this.longitude;
            }
   
            bodyS = bodyS + ','+'FECHA SELECCIONADA:'+ this.currentSelectedDateTime;

            console.log('Esto es lo que se va a pintar:'+bodyS);

            registerError({body: bodyS});
            

        }else{
            console.log('No hay error puede continuar');
            //Navegar al siguiente step
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }

    
    }
}