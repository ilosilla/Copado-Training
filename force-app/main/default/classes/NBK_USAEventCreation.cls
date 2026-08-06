public without sharing class NBK_USAEventCreation {

    @InvocableMethod(label='Create event' description='Appointment event generation')
    public static void generateAppointmentEvent(List<Request> req) {
        System.debug('****** generateAppointmentEvent *****:'+req);
        try{
            if(!req.isEmpty()){
            
                Event ev = new Event();
                String fechaSel = req[0].fechaHoraStr;
                Timezone tz = Timezone.getTimeZone(req[0].businessH.TimeZoneSidKey);  
                Datetime fechaLocal = Datetime.valueOf(fechaSel);

                Datetime fechaGmt = fechaLocal.addSeconds(-tz.getOffset(fechaLocal) / 1000);
                System.debug('fecha inicio evento:'+fechaLocal);

                ev.StartDateTime = fechaGmt;
                ev.EndDateTime = fechaGmt.addHours(1);

                /*
                Datetime fechaConvertida = Datetime.valueOf(fechaSel);                
                System.debug('fechaconvertida = '+fechaConvertida);

                //Calcular el offset de la tienda
                 
                Timezone tz = Timezone.getTimeZone(req[0].businessH.TimeZoneSidKey);          
                Long milisegundosOffset = tz.getOffset(fechaConvertida);
                Integer horasOffset = (Integer)milisegundosOffset / (1000 * 60 * 60);  
                horasOffset = horasOffset * -1;

                fechaConvertida = fechaConvertida.addHours(horasOffset);
                System.debug('fecha inicio evento:'+fechaConvertida);
                

                ev.StartDateTime = fechaConvertida;
                ev.EndDateTime = fechaConvertida.addHours(1);
                */
                                
                ev.Event_type__c = req[0].eventType;
                ev.WhoId = req[0].whoId;
                ev.Subject = req[0].subject;
                ev.Description = req[0].description;
                ev.OwnerId = req[0].ownerId;
                insert ev;  
            }
        }catch(Exception ex){
            System.debug('ERROR EN CREATE EVENT: '+ex.getMessage());
            Logger.error('[APPOINTMENT_MANAGER_CREATE_EVENT]: ' + ex.getMessage());
            Logger.saveLog();
        }
    }
    
    public class Request{
        @InvocableVariable(required=true)
        public Datetime startDate;
        @InvocableVariable(required=true)
        public Datetime endDate;
        @InvocableVariable(required=true)
        public String eventType;
        @InvocableVariable(required=true)
        public String whoId;
        @InvocableVariable(required=true)
        public String subject;
        @InvocableVariable(required=false)
        public String description;
        @InvocableVariable(required=true)
        public String ownerId;
        @InvocableVariable(required=true)
        public String fechaHoraStr;
        @InvocableVariable(required=true)
        public BusinessHours businessH;
    }
    
}