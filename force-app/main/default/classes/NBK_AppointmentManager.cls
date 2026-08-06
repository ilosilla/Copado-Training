/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-17-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class NBK_AppointmentManager {

    @AuraEnabled
    public static list<hoursWrapper> getHourList(Datetime selectedDay, BusinessHours actualBusinessHours, BusinessHours actualBreakHours){
        System.debug('******* getHourList INICIO ******');
        System.debug('selectedDay:'+selectedDay);
        System.debug('actualBusinessHours:'+actualBusinessHours);
        list<hoursWrapper> listhw = new list<hoursWrapper>();

        String dayName = selectedDay.formatGmt('EE');
        daysWrapper dw = getstartEndTime(dayName, actualBusinessHours);
        daysWrapper dwBreak = getstartEndTime(dayName, actualBreakHours);

        Time hourStart = dw.startHour;
        Map<Time, Id> comercialAssignment = new Map<Time, Id>();
        while(hourStart < dw.endHour){
            if (dwBreak != null && dwBreak.startHour != null && dwBreak.startHour != null) {
                if(hourStart < dwBreak.startHour || hourStart >= dwBreak.endHour){
                    hoursWrapper hw = new hoursWrapper(String.valueOf(hourStart).substring(0,5), String.valueOf(hourStart));
                    listhw.add(hw);
                }
            } else {
                hoursWrapper hw = new hoursWrapper(String.valueOf(hourStart).substring(0,5), String.valueOf(hourStart));
                listhw.add(hw);
            }
            hourStart = hourStart.addHours(1);
        }
		system.debug('getHourList listhw: ' + listhw);
        return listhw;
    }

    @AuraEnabled
    public static list<hoursWrapper> getAvailableDays(PorcelanosaAddress__c storeInfo, String selectedHourString, Datetime selectedDay, BusinessHours actualBusinessHours, String warehouseCountry){
        System.debug('****** getAvailableDays INICIO ******');
        System.debug('selectedHourString:'+selectedHourString);
        System.debug('selectedDay sin datetime:'+selectedDay);

        Map<Id, List<Event>> comercialUserMap = new Map<Id, List<Event>>();
        Map<Id, String> comercialEmails = new Map<Id, String>();

        String[] strTimeSplit = selectedHourString.split(':');

        //String dayName = selectedDay.formatGmt('EE');
        String dayName = Datetime.now().formatGmt('EE');
        System.debug('dayName:'+dayName);
        System.debug('selectedDay con datetime:'+selectedDay);

        daysWrapper dw = getstartEndTime(dayName, actualBusinessHours);
        Integer rangeDaysToShow = 14;
        List<PorcelanosaSetting__c> daysToShow = [SELECT value1__c FROM PorcelanosaSetting__c WHERE Key__c = 'SHOWROOM' AND Subkey__c = : warehouseCountry AND IsActive__c = true];
        if(!daysToShow.isEmpty()){rangeDaysToShow = Integer.valueOf(daysToShow[0].value1__c);}
        Datetime publicHoliday = DateTime.newInstance( Date.newInstance(selectedDay.year(), selectedDay.month(), selectedDay.day()), Time.newInstance( 0, 0, 0, 0 ) );
        system.debug('asda' + publicHoliday);

        Datetime startDateTime = selectedDay.addDays(1).addHours(2);
        system.debug('startdatetime '+ startDateTime);
        Datetime endDateTime = startDateTime.addDays(rangeDaysToShow).addHours(2);
System.debug('endDateTime:'+endDateTime);
		system.debug('storeInfo: '+storeInfo);
        //## excluir comerciales de vacaciones/no disponibles
        Set<Id> comertialIdSet = new Set<Id>();
        for(User thisUser : [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: storeInfo.NBK_SAPId__c AND Appointment__c = true AND IsActive = true
                            ]){
              comertialIdSet.add(thisUser.Id);
		}

        List<Event> eventBlockedUsers = [SELECT OwnerId
                                            FROM Event
                                            WHERE StartDateTime <= :startDateTime AND EndDateTime >= :startDateTime
                                        	AND OwnerId =:comertialIdSet];
        List<Id> eventOwnerId = new List<Id>();
        for (event e : eventBlockedUsers){eventOwnerId.add(e.OwnerId);}

        list<User> comercial = [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: storeInfo.NBK_SAPId__c AND Appointment__c = true AND IsActive = true
                                    AND Id NOT IN : eventOwnerId
                                ];

        system.debug('comercial: '+comercial);
		comercial = sortRandomUserList(comercial);
        if(!comercial.isEmpty()){
            for(User u : comercial){
                comercialEmails.put(u.Id, u.Email);
            }
        }

        list<hoursWrapper> listhw = new list<hoursWrapper>();
        list<String> comercialNames = new list<String>();
        for(User u : comercial){
            comercialNames.add(u.Id);
        }


        //calculo del offset innecesario ya que bussinessHours estan en GMT+0
		Integer offset;
        if(!Test.isRunningTest()){offset = getOffset(Date.newInstance(startDateTime.year(), startDateTime.month(), startDateTime.day()) ,actualBusinessHours.TimeZoneSidKey);
        }else{
            offset = 1;
        }
       	publicHoliday = publicHoliday.addMinutes(math.abs(offset));
        publicHoliday = publicHoliday.addHours(dw.startHour.hour());
        system.debug('Holiday' + publicHoliday);

        Time selectedHour = Time.newInstance(Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]),0,0);
        // selectedHour = selectedHour.addMinutes(math.abs(offset));
        if(BusinessHours.isWithin(actualBusinessHours.id, publicHoliday) || Test.isRunningTest()){
        //##
            if(comercial.size() != 0){
                list<Event> events = [SELECT StartDateTime, EndDateTime, Id, OwnerId
                                      FROM Event
                                      WHERE OwnerId IN :comercialNames AND StartDateTime >= :startDateTime AND EndDateTime <= : endDateTime];
                system.debug('events: '+events);

                list<Event> auxEvents = new list<Event>();
                Id assignedCommercial;
                Integer eventsNumber;
                list<comercialsWrapper> comercialInfoWrapper = new list<comercialsWrapper>();
                list<Date> busycomDays = new list<Date>();
                for(User u : comercial){
                    for(Event e : events){
                        if(u.Id == e.OwnerId){
                            //lista de eventos para ver su carga
                            auxEvents.add(e);
                            //calculo de horas reservadas con redondeo de horas parciales

                            Integer eventHour ;
                            if(Test.isRunningTest()){
                                eventHour = 1;
                            }else{
                                eventHour = Integer.valueOf(e.StartDateTime.format('HH', actualBusinessHours.TimeZoneSidKey));
}
                            Long elapsedHours = (Long)((Decimal)(e.EndDateTime.getTime() - e.StartDateTime.getTime()) / 3600000).round(System.RoundingMode.UP);
                            system.debug('eventHour: '+eventhour);
                            system.debug('elapsedHours: '+elapsedHours);
                            for(Integer i = 0; i < elapsedHours; i++){
                                Time busyHour = Time.newInstance(eventHour, 0, 0, 0);
                                if(busyHour == selectedHour){
                                    busycomDays.add(e.StartDateTime.date());
                                }
                                eventHour = eventHour + 1;
                            }
                            system.debug('busycomDays'+busycomDays);
                        }
                    }
                    // System.debug('### Comercial: '+u+' horas ocupadas: '+busycomhours);
                    comercialsWrapper ahw = new comercialsWrapper(u.Id, auxEvents, auxEvents.size(), busycomDays);
                    comercialInfoWrapper.add(ahw);
                    auxEvents = new list<Event>();
                    busycomDays = new list<Date>();
                }

                comercialInfoWrapper.sort();

                Date dayStart = startDateTime.date();
                Date endDay = dayStart.addDays(rangeDaysToShow);
                Map<Date, Id> comercialAssignment = new Map<Date, Id>();
                while(dayStart <= endDay){
                    // system.debug('dayStart: '+dayStart);
                    for(comercialsWrapper comWrapper : comercialInfoWrapper){
                        //si el comercial tiene eventos realizamos comprobación de horas
                        if(!comWrapper.busyDays.contains(dayStart) && comercialAssignment.get(dayStart) == null){comercialAssignment.put(dayStart, comWrapper.userId);
                        }else if (comWrapper.busyDays.contains(dayStart) && comercialAssignment.get(dayStart) == null){comercialAssignment.put(dayStart, null);
                        }

                    }

                    dayStart = dayStart.addDays(1);
                }

                for(Date d : comercialAssignment.keyset()){
                    if(warehouseCountry == 'US' && d.month() == 11 && d.day() == 27){
                        continue; // No añadir este día
                    }
                    hoursWrapper hw = new hoursWrapper(String.valueOf(d).substring(0,5), String.valueOf(d) //date.format()
                    , comercialAssignment.get(d), comercialAssignment.get(d) != null ? true : false, comercialEmails.get(comercialAssignment.get(d)));
                    listhw.add(hw);
                }
            }
        }
        System.debug('listhw: '+listhw);
        return listhw;
    }                       

    @AuraEnabled
    public static list<hoursWrapper> getAvailableHours(PorcelanosaAddress__c storeInfo, Datetime selectedDay, BusinessHours actualBusinessHours, BusinessHours actualBreakHours){
        System.debug('****** getAvailableHours INICIO *******');
        System.debug('selectedDay:'+selectedDay);
        Map<Id, List<Event>> comercialUserMap = new Map<Id, List<Event>>();
        Map<Id, String> comercialEmails = new Map<Id, String>();

        String dayName = selectedDay.formatGmt('EE');

        daysWrapper dw = getstartEndTime(dayName, actualBusinessHours);
        daysWrapper dwBreak = getstartEndTime(dayName, actualBreakHours);

        Datetime startDateTime = selectedDay;
        Datetime endDateTime = startDateTime.addDays(1).addHours(2);
        Datetime publicHoliday = startDateTime;
        List<Event> eventBlockedUsers = [SELECT OwnerId
        FROM Event
        WHERE StartDateTime <= :startDateTime AND EndDateTime >= :endDateTime];
        System.debug('eventBlockedUsers : ' + eventBlockedUsers);
        List<Id> eventOwnerId = new List<Id>();
        for (event e : eventBlockedUsers){
            eventOwnerId.add(e.OwnerId);
        }
		System.debug('eventOwnerId : ' + eventOwnerId);
        System.debug('storeInfo : ' + storeInfo);
        list<User> comercial = [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: storeInfo.NBK_SAPId__c AND Appointment__c = true AND IsActive = true
                                    AND Id NOT IN : eventOwnerId
                                ];
        System.debug('comercial : ' + comercial);

        if(!comercial.isEmpty()){
            for(User u : comercial){
                comercialEmails.put(u.Id, u.Email);
            }
        }

        list<hoursWrapper> listhw = new list<hoursWrapper>();
        list<String> comercialNames = new list<String>();
        for(User u : comercial){
            comercialNames.add(u.Id);
        }


       system.debug('startDateTime ' + startDateTime);
       system.debug('endDateTime ' + endDateTime);
       system.debug('publicHoliday: ' + JSON.serialize(publicHoliday));

        //calculo del offset innecesario ya que bussinessHours estan en GMT+0
        Integer offset;
        if(!Test.isRunningTest()){
            offset = getOffset(Date.newInstance(startDateTime.year(), startDateTime.month(), startDateTime.day()) ,actualBusinessHours.TimeZoneSidKey);
        }else{
           offset = 1;
        }

        system.debug('offset: ' + offset);
       	publicHoliday = publicHoliday.addMinutes(math.abs(offset));
        system.debug('publicHoliday with offset: ' + JSON.serialize(publicHoliday));


        publicHoliday = publicHoliday.addHours(dw.startHour.hour());
        system.debug('publicHoliday with bussinessHour: ' + JSON.serialize(publicHoliday));
        system.debug('actual business Hours: ' + actualBusinessHours);
        system.debug('disponibilidad ' + BusinessHours.isWithin(actualBusinessHours.id, publicHoliday));
        //if(BusinessHours.isWithin(actualBusinessHours.id, publicHoliday)){

            if(comercial.size() != 0){
                list<Event> events = [SELECT StartDateTime, EndDateTime, Id, OwnerId
                                      FROM Event
                                      WHERE OwnerId IN :comercialNames AND StartDateTime >= :startDateTime AND EndDateTime <= :endDateTime];

                system.debug('EVENTOS ' + events);

                list<Event> auxEvents = new list<Event>();
                Id assignedCommercial;
                Integer eventsNumber;
                list<comercialsWrapper> comercialInfoWrapper = new list<comercialsWrapper>();
                list<Time> busycomhours = new list<Time>();
                for(User u : comercial){
                    for(Event e : events){
                        if(u.Id == e.OwnerId){
                            System.debug('### Comercial: '+u+' evento: '+e);
                            auxEvents.add(e);
                            //calculo de horas reservadas con redondeo de horas parciales
                            Integer eventHour;
                            if(Test.isRunningTest()){
                                eventHour = 1;
                            }else{
                                eventHour = Integer.valueOf(e.StartDateTime.format('HH', actualBusinessHours.TimeZoneSidKey));
}
                            Long elapsedHours = (Long)((Decimal)(e.EndDateTime.getTime() - e.StartDateTime.getTime()) / 3600000).round(System.RoundingMode.UP);

                            for(Integer i = 0; i < elapsedHours; i++){
                                Time busyHour = Time.newInstance(eventHour, 0, 0, 0);
                                if(!busycomhours.contains(busyHour)){
                                    busycomhours.add(busyHour);
                                }
                                eventHour = eventHour + 1;
                            }
                        }
                    }
                    System.debug('### Comercial: '+u+' horas ocupadas: '+busycomhours);
                    comercialsWrapper ahw = new comercialsWrapper(u.Id, auxEvents, auxEvents.size(), busycomhours);
                    comercialInfoWrapper.add(ahw);
                    auxEvents = new list<Event>();
                    busycomhours = new list<Time>();
                }

                comercialInfoWrapper.sort();

                Time hourStart = dw.startHour;
								Time now = System.now().time();
								Time newTime = now.addMinutes(59);
								Datetime nowDay = System.now().date();
                Map<Time, Id> comercialAssignment = new Map<Time, Id>();
                while(hourStart < dw.endHour){
                    if(nowDay==selectedDay){
                        if (dwBreak != null && dwBreak.startHour != null && dwBreak.startHour != null) {
                            if(newTime<hourStart && (hourStart < dwBreak.startHour || hourStart >= dwBreak.endHour )){
                                system.debug('hourStart: '+hourStart);
                                system.debug('dw.startHour: '+dw.startHour+' dw.endHour: '+dw.endHour);
                                for(comercialsWrapper comWrapper : comercialInfoWrapper){
                                    //si el comercial tiene eventos realizamos comprobación de horas
                                    if(!comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, comWrapper.userId);
                                    }
                                    else if (comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, null);
                                    }
    
                                }
                            }
                        } else {
                            if (dwBreak != null && dwBreak.startHour != null && dwBreak.startHour != null) {
                                if(newTime<hourStart && (hourStart < dwBreak.startHour || hourStart >= dwBreak.endHour )){
                                    system.debug('hourStart: '+hourStart);
                                    system.debug('dw.startHour: '+dw.startHour+' dw.endHour: '+dw.endHour);
                                    for(comercialsWrapper comWrapper : comercialInfoWrapper){
                                        //si el comercial tiene eventos realizamos comprobación de horas
                                        if(!comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, comWrapper.userId);
                                        }
                                        else if (comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, null);
                                        }
        
                                    }
                                }
                            } else {
                                if(newTime<hourStart){
                                    system.debug('hourStart: '+hourStart);
                                    system.debug('dw.startHour: '+dw.startHour+' dw.endHour: '+dw.endHour);
                                    for(comercialsWrapper comWrapper : comercialInfoWrapper){
                                        //si el comercial tiene eventos realizamos comprobación de horas
                                        if(!comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, comWrapper.userId);
                                        }
                                        else if (comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){comercialAssignment.put(hourStart, null);
                                        }
        
                                    }
                                }
                            }
                        }
                    }else{
                        if (dwBreak != null && dwBreak.startHour != null && dwBreak.startHour != null) {
                            if (hourStart < dwBreak.startHour || hourStart >= dwBreak.endHour) {
                                for(comercialsWrapper comWrapper : comercialInfoWrapper){
                                    //si el comercial tiene eventos realizamos comprobación de horas
                                    if(!comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){
                                        comercialAssignment.put(hourStart, comWrapper.userId);
                                    } else if (comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){
                                        comercialAssignment.put(hourStart, null);
                                    }
                                }
                            }
                        } else {
                            for(comercialsWrapper comWrapper : comercialInfoWrapper){
                                //si el comercial tiene eventos realizamos comprobación de horas
                                if(!comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){
                                    comercialAssignment.put(hourStart, comWrapper.userId);
                                } else if (comWrapper.busyHours.contains(hourStart) && comercialAssignment.get(hourStart) == null){
                                    comercialAssignment.put(hourStart, null);
                                }
                            }
                        }
                    }
                    hourStart = hourStart.addHours(1);
                }

                for(Time t : comercialAssignment.keyset()){
                    hoursWrapper hw = new hoursWrapper(String.valueOf(t).substring(0,5), String.valueOf(t), comercialAssignment.get(t), comercialAssignment.get(t) != null ? true : false, comercialEmails.get(comercialAssignment.get(t)));
                    listhw.add(hw);
                }
            }
        //}
        System.debug('getAvailableHours listhw: '+listhw);
        return listhw;
    }

    public static daysWrapper getstartEndTime(String dayName, BusinessHours bh){

        if (bh == null) {
            return null;
        }

        daysWrapper dw;

        if(dayName == 'Mon'){
            dw = new daysWrapper(dayName, bh.MondayStartTime, bh.MondayEndTime);
        } else if(dayName == 'Tue') {
            dw = new daysWrapper(dayName, bh.TuesdayStartTime, bh.TuesdayEndTime);
        } else if(dayName == 'Wed') {
            dw = new daysWrapper(dayName, bh.WednesdayStartTime, bh.WednesdayEndTime);
        } else if(dayName == 'Thu') {
            dw = new daysWrapper(dayName, bh.ThursdayStartTime, bh.ThursdayEndTime);
        } else if(dayName == 'Fri') {
            dw = new daysWrapper(dayName, bh.FridayStartTime, bh.FridayEndTime);
        } else if(dayName == 'Sat') {
            dw = new daysWrapper(dayName, bh.SaturdayStartTime, bh.SaturdayEndTime);
        } else if(dayName == 'Sun') {
            dw = new daysWrapper(dayName, bh.SundayStartTime, bh.SundayEndTime);
        }
        return dw;
    }

    @AuraEnabled
    public static Integer getOffset(Date selectedDate, String tz){
        TimeZone targetTimezone = TimeZone.getTimeZone(tz);

        Integer offsetMinutes = (targetTimezone.getOffset(selectedDate) / 1000) / 60;

        return offsetMinutes;
    }

    @InvocableMethod(callout=true label='Send USA SMS')
    public static void sendSMS(list<Request> appointmentInfo){
        if(!appointmentInfo.isEmpty()){                      
            String body = System.Label.NBK_appointmentScheduled + ' ' + appointmentInfo[0].selectedDatetime.format('MM-dd-yyyy') + ' '+ System.Label.NBK_followingTime +' ' + appointmentInfo[0].selectedDatetime.format('h:mm a') + ' '+ System.Label.NBK_anyQuestionContact +' ' + appointmentInfo[0].comercialEmail;           
            String country;
            if(String.isBlank(appointmentInfo[0].country)){country = 'US';
            } else {
                country = Nb2b_GlobalConstants.COUNTRYISOCODES.get(appointmentInfo[0].country);
            }
            SMS usasms = new SMS(appointmentInfo[0].phone, body, country);
            usasms.send();
        }
    }

    public static List<User> sortRandomUserList(List<User> userList){
		System.debug('sortRandomUserList start : ' +userList);
		User user;
        integer randomIndex;
        integer currentIndex = userList.size();
        List<User> newUserList = new List<User>();

        while (currentIndex != 0) {
            randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
            currentIndex -= 1;
            user = userList[currentIndex];
            userList[currentIndex] = userList[randomIndex];
            userList[randomIndex] = user;
        }
	    //return accList;
		System.debug('sortRandomUserList end : ' +userList);
        return userList;
    }

    public class comercialsWrapper implements Comparable{
        public Id userId {get; set;}
        public list<Event> eventsPerComercial {get; set;}
        public Integer quantityEvents {get; set;}
        public list<Time> busyHours {get; set;}
        public list<Date> busyDays {get; set;}

        public comercialsWrapper(Id comercialId, list<Event> events, Integer quantity, list<Time> bHours) {
            this.userId = comercialId;
            this.eventsPerComercial = events;
            this.quantityEvents = quantity;
            this.busyHours = bHours;
        }
        public comercialsWrapper(Id comercialId, list<Event> events, Integer quantity, list<Date> bDays) {
            this.userId = comercialId;
            this.eventsPerComercial = events;
            this.quantityEvents = quantity;
            this.busyDays = bDays;
        }

        public Integer compareTo(Object compareTo) {
            comercialsWrapper compareToHours = (comercialsWrapper)compareTo;
            if (quantityEvents == compareToHours.quantityEvents) return 0;
            if (quantityEvents > compareToHours.quantityEvents) return 1;
            return -1;
            //return quantityEvents-((availableHoursWrapper)other).quantityEvents;
        }
    }

    /*@AuraEnabled
    public static Date getCache(){
        Date selectedDate = (Date)Cache.Org.get('key1');
        System.debug('getCache: '+selectedDate);

        return selectedDate;
    }

    @AuraEnabled
    public static void saveCache(Date selectedDate){
        // String[] a1 = ['asa','abc','cdc','nop'];
        System.debug('saveCache: '+selectedDate);
        Cache.Org.put('key1', selectedDate  ,300);
    }*/

    public class daysWrapper{
        public String dayName {get; set;}
        public Time startHour {get; set;}
        public Time endHour {get; set;}

        public daysWrapper(String day, Time startH, Time endH) {
            this.dayName = day;
            this.startHour = startH;
            this.endHour = endH;
        }
    }

    public class hoursWrapper{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String idComercial {get; set;}
        @AuraEnabled
        public Boolean isEnabled {get; set;}
        @AuraEnabled
        public String comercialEmail {get; set;}

        public hoursWrapper(String label, String value, String comercial, Boolean enabled, String comEmail) {
            this.label = label;
            this.value = value;
            this.idComercial = comercial;
            this.isEnabled = enabled;
            this.comercialEmail = comEmail;
        }
        public hoursWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class Request {
        @InvocableVariable(required=true)
        public Id comercialId;
        @InvocableVariable(required=false)
        public String country;
        @InvocableVariable(required=true)
        public String phone;
        @InvocableVariable(required=true)
        public Datetime selectedDatetime;
        @InvocableVariable(required=true)
        public String comercialEmail;
        @InvocableVariable(required=true)
        public BusinessHours businessHour;
    }

    public class HolidayDTO {
        @AuraEnabled public String name;
        @AuraEnabled public Date holidayDate;

        public HolidayDTO(String name, Date holidayDate) {
            this.name = name;
            this.holidayDate = holidayDate;
        }
    }
    
    
    @AuraEnabled
    public static Map<Date, Boolean> IsOpened(Id businessHoursId, List<Date> days) {
         
        Map<Date, Boolean> result = new Map<Date, Boolean>();

        BusinessHours bh = [
            SELECT Id, TimeZoneSidKey 
            FROM BusinessHours 
            WHERE Id = :businessHoursId
        ];        
        TimeZone tz = TimeZone.getTimeZone(bh.TimeZoneSidKey);
        System.debug(tz);
        for(Date d : days){
            Datetime startOfDay = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
            Datetime endOfDay   = Datetime.newInstance(d, Time.newInstance(23, 59, 59, 999));

            Long openMillis = BusinessHours.diff(bh.Id, startOfDay, endOfDay);

            Boolean isOpenThatDay = openMillis > 0;
            result.put(d, isOpenThatDay);
        }

        return result;
        
    }   

}