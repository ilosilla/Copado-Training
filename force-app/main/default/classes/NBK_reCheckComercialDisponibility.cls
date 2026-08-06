/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-21-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class NBK_reCheckComercialDisponibility {

    @InvocableMethod(callout=true label='ReCheck comercial disponibility')
    public static list<responseDisponibility> recheckDisponibility(list<comercialDisponibility> appointmentInfo){
        try{
            System.debug('recheckDisponibility:'+appointmentInfo);
            responseDisponibility res = new responseDisponibility();
            //res.newComercialId = appointmentInfo[0].userId;
            list<responseDisponibility> response = new list<responseDisponibility>();
            if(!appointmentInfo.isEmpty()){

                /*CAMBIO FECHA SELECCIONADA*/
                String fechaSel = appointmentInfo[0].fechaHoraStr;
                Datetime fechaConvertida = Datetime.valueOf(fechaSel);
                System.debug('fechaconvertida = '+fechaConvertida);

                //Calcular el offset de la tienda
                Timezone tz = Timezone.getTimeZone(appointmentInfo[0].businessH.TimeZoneSidKey);          
                Long milisegundosOffset = tz.getOffset(fechaConvertida);
                Integer horasOffset = (Integer)milisegundosOffset / (1000 * 60 * 60);  
                horasOffset = horasOffset * -1;

                fechaConvertida = fechaConvertida.addHours(horasOffset);
                System.debug('fecha inicio evento:'+fechaConvertida);
                /*CAMBIO FECHA SELECCIONADA*/

                
                res.newComercialEmail = appointmentInfo[0].comercialEmail;
                res.newComercialId = appointmentInfo[0].userId;
                //list<Event> e = [SELECT Id FROM Event WHERE OwnerId = :appointmentInfo[0].userId AND StartDateTime = :appointmentInfo[0].dateSelected WITH SECURITY_ENFORCED];
                list<Event> e = [SELECT Id FROM Event WHERE OwnerId = :appointmentInfo[0].userId AND StartDateTime = :fechaConvertida WITH SECURITY_ENFORCED];
                System.debug('Event list: '+e);
                if(e.isEmpty()){
                    res.continueDisponibility = true;
                    res.availableCustomer = false;
                } else {
                    res.continueDisponibility = false;
                    res.availableCustomer = false;
                }
                //}
                response.add(res);

            }
            System.debug('response:'+response);
            return response;

        }catch(Exception ex){
            System.debug('ERROR EN SENDEMAIL: '+ex.getMessage());
            Logger.error('[APPOINTMENT_RECHECK_DISPONIBILITY]: ' + ex.getMessage());
            Logger.saveLog();
            return null;
        }
        
    }

    public class ComercialDisponibility {
        @InvocableVariable(required=true)
        public Id userId;
        @InvocableVariable(required=true)
        public Datetime dateSelected;
        @InvocableVariable(required=true)
        public String email;
        @InvocableVariable(required=true)
        public String salesOffice;
        @InvocableVariable(required=true)
        public String comercialEmail;
        @InvocableVariable(required=true)
        public String fechaHoraStr;
        @InvocableVariable(required=true)
        public BusinessHours businessH;
    }

    public class ResponseDisponibility {
        @InvocableVariable
        public Boolean continueDisponibility;
        @InvocableVariable
        public Boolean availableCustomer;
        @InvocableVariable
        public Id newComercialId;
        @InvocableVariable
        public Id newWhoId;
        @InvocableVariable
        public String newComercialEmail;
    }

}