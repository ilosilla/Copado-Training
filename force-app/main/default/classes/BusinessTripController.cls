/**
* @author 		Ivan Losilla
* @date 		October 2025
* @group 		BusinessTrip
* @description 	Class to manage all components related
* @test         BusinessTripControllerTest
*/
public class BusinessTripController {
    public class WeeklyManagementException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<BusinessTrip__c> getBusinessTrips(String userId) {
        List<BusinessTrip__c> result = [SELECT id, Name,Title__c, toLabel(Country__c), StartDate__c, EndDate__c, Owner.Name FROM BusinessTrip__c WHERE OwnerId =: userId];
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static BusinessTrip__c getBusinessTripHeader(String businessTripId) {
        BusinessTrip__c result = [SELECT id, Name, Comments__c,LastVisit__c,Title__c, Comments2__c, Comments3__c, toLabel(Countries__c), StartDate__c, EndDate__c,Owner.Name,MainRisks__c,MainObjectives__c,FutureOpportunities__c,MaterialUsedComment__c,Strategies__c FROM BusinessTrip__c WHERE Id =: businessTripId];
        return result;
    }

    public static List<BusinessTripVisit__c> getBusinessTripVisits(String businessTripId) {
        List<BusinessTripVisit__c> result = [SELECT id,Title__c,Date__c,toLabel(Country__c),Account__c,Account__r.Name,Opportunity__r.Name, Lead__r.Name, Name,Channel__c,Comment__c,BusinessTrip__c,Status__c from BusinessTripVisit__c WHERE BusinessTrip__c =: businessTripId ORDER BY Date__c ASC];
        return result;
    }

    public static List<BusinessTripVisitEvent__c> getBusinessTripVisitEvents(String businessTripId) {
        List<BusinessTripVisitEvent__c> result = [SELECT id,BusinessTripVisit__c,Name,Type__c,BusinessTripVisit__r.Name,BusinessTripVisit__r.Id,Status__c,Description__c,Agreement__c,OtherType__c  FROM BusinessTripVisitEvent__c where BusinessTripVisit__r.BusinessTrip__c =: businessTripId order by BusinessTripVisit__c];
        return result;
    }

    public static List<BusinessTripVisitRequest__c> getBusinessTripVisitRequests(String businessTripId) {
        List<BusinessTripVisitRequest__c> result = [SELECT id, Name, BusinessTripVisit__c, Title__c,BusinessTripVisit__r.Name,BusinessTripVisit__r.Id, Comment__c, Priority__c, CreatedDate FROM BusinessTripVisitRequest__c WHERE BusinessTripVisit__r.BusinessTrip__c =: businessTripId];
        return result;
    }

    public static List<BusinessTripVisitAction__c> getBusinessTripVisitActions(String businessTripId) {
        List<BusinessTripVisitAction__c> result = [SELECT id, Name, BusinessTripVisit__c, Title__c,BusinessTripVisit__r.Name,BusinessTripVisit__r.Id, Comment__c, Priority__c, CreatedDate FROM BusinessTripVisitAction__c WHERE BusinessTripVisit__r.BusinessTrip__c =: businessTripId];
        return result;
    }

    public static List<BusinessTripStrategy__c> getBusinessTripStrategies(String businessTripId) {
        List<BusinessTripStrategy__c> result = [SELECT id,Account__c,toLabel(Country__c),Title__c,Account__r.Name,Name,Comment__c,Impact__c,BusinessTrip__c from BusinessTripStrategy__c WHERE BusinessTrip__c =: businessTripId];
        return result;
    }

    public static List<BusinessTripStrategyRequest__c> getBusinessTripStrategyRequests(String businessTripId) {
        List<BusinessTripStrategyRequest__c> result = [SELECT id, Name, BusinessTripStrategy__c,Title__c, BusinessTripStrategy__r.Name,BusinessTripStrategy__r.Id, Comment__c, Priority__c, CreatedDate FROM BusinessTripStrategyRequest__c WHERE BusinessTripStrategy__r.BusinessTrip__c =: businessTripId];
        return result;
    }

    public static List<BusinessTripStrategyAction__c> getBusinessTripStrategyActions(String businessTripId) {
        List<BusinessTripStrategyAction__c> result = [SELECT id, Name, BusinessTripStrategy__c,Title__c, BusinessTripStrategy__r.Name,BusinessTripStrategy__r.Id, Comment__c, Priority__c, CreatedDate FROM BusinessTripStrategyAction__c WHERE BusinessTripStrategy__r.BusinessTrip__c =: businessTripId];
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static businesssTripData getBusinessTrip(String businessTripId) {
        businesssTripData result = new businesssTripData(businessTripId);
        return result;
    }

    @InvocableMethod(label='Send Trip PDF Email')
    public static void sendPdfFlow(List<SendPdfInput> inputs) {
        for (SendPdfInput input : inputs) {
            // Llama a tu método original
            sendPdf(input.toAddresses, input.ccAddresses, input.tripId, input.title, input.body);
        }
    }

    public static void sendPdf(List<String> toAddresses, List<String> ccAddresses, String tripId, String title, String body) {
        Blob pdfData;
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        businesssTripData bTripData = getBusinessTrip(tripId);

        email.setToAddresses(toAddresses);
        ccAddresses.add(UserInfo.getUserEmail());
        email.setCcAddresses(ccAddresses);
        email.setSubject(title);
        email.setHtmlBody(body);
        email.setWhatId(tripId);
        email.setSaveAsActivity(true);

        try {
            PageReference pdfPage = Page.BusinessTripPdf;
            if (Test.isRunningTest()) {
                pdfData = Blob.valueOf('TEST DATA'); // Mock data for tests
            } else {
                pdfPage.getParameters().put('tripId', tripId);
                pdfData = pdfPage.getContent();
            }

            Messaging.EmailFileAttachment attachmentPdf = new Messaging.EmailFileAttachment();
            attachmentPdf.setFileName('viaje comercial' + bTripData.header.Name +  '.pdf');
            attachmentPdf.setBody(pdfData);
            attachmentPdf.setContentType('application/pdf');
            attachments.add(attachmentPdf);

            // 1️⃣ Obtener los IDs de ContentDocument relacionados
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :tripId
            ];
            
            if (links.isEmpty() == false) {
                Set<Id> documentIds = new Set<Id>();
                for (ContentDocumentLink l : links) {
                    documentIds.add(l.ContentDocumentId);
                }
    
                // 2️⃣ Obtener las versiones más recientes de cada documento
                List<ContentVersion> versions = [
                    SELECT Title, VersionData, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :documentIds
                    AND IsLatest = true
                ];
    
                // 3️⃣ Crear la lista de adjuntos
                for (ContentVersion v : versions) {
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(v.Title + '.' + v.FileExtension);
                    efa.setBody(v.VersionData);
                    attachments.add(efa);
                }
            }

            email.setFileAttachments(attachments);

            // Enviar email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

        } catch (Exception exc) {
            pdfData = null;
            System.debug('❌ Error al crar el pdf: ' + exc.getMessage());
        }
    }

    public static String cloneToTrip(String tripId) {
        return cloneBusinessTrip(tripId, 'TRIP');
    }

    public static String cloneToRequest(String tripId) {
        return cloneBusinessTrip(tripId, 'REQUEST');
    }

    public static String cloneBusinessTrip(String tripId, String type) {
        SavePoint sp = Database.setSavePoint();
        try {

            /**********************************
             * 1️⃣ CLONAR HEADER
             **********************************/
            BusinessTrip__c original = [
                SELECT Id, Name, Title__c, Countries__c, StartDate__c, EndDate__c, 
                    Comments__c, Comments2__c, Comments3__c, MainRisks__c, 
                    MainObjectives__c, FutureOpportunities__c, MaterialUsedComment__c,
                    LastVisit__c,Strategies__c, OwnerId
                FROM BusinessTrip__c
                WHERE Id = :tripId
            ];

            original.Status__c = 'CONVERTED';

            BusinessTrip__c cloneHeader = original.clone(false, false, false, false);
            cloneHeader.Type__c = type;
            cloneHeader.RequestTrip__c = tripId;
            insert cloneHeader;



            /**********************************
             * 2️⃣ CLONAR VISITS
             **********************************/
            List<BusinessTripVisit__c> visits = [
                SELECT Id, Title__c, Date__c, Country__c, Account__c, Opportunity__c, 
                    Lead__c, Name, Channel__c, Comment__c, Status__c
                FROM BusinessTripVisit__c
                WHERE BusinessTrip__c = :tripId
                ORDER BY Date__c ASC
            ];

            List<BusinessTripVisit__c> visitClones = new List<BusinessTripVisit__c>();
            for (BusinessTripVisit__c v : visits) {
                BusinessTripVisit__c nv = v.clone(false, false, false, false);
                nv.BusinessTrip__c = cloneHeader.Id;
                visitClones.add(nv);
            }

            insert visitClones;

            // 🔁 Map VISIT original → nuevo
            Map<Id, Id> visitMap = new Map<Id, Id>();
            for (Integer i = 0; i < visits.size(); i++) {
                visitMap.put(visits[i].Id, visitClones[i].Id);
            }



            /**********************************
             * 3️⃣ CLONAR VISIT ACTIONS
             **********************************/
            List<BusinessTripVisitAction__c> visitActions = [
                SELECT Id, Name, BusinessTripVisit__c, Comment__c, Priority__c, Title__c
                FROM BusinessTripVisitAction__c
                WHERE BusinessTripVisit__r.BusinessTrip__c = :tripId
            ];

            List<BusinessTripVisitAction__c> visitActionClones = new List<BusinessTripVisitAction__c>();
            for (BusinessTripVisitAction__c a : visitActions) {
                BusinessTripVisitAction__c na = a.clone(false, false, false, false);
                na.BusinessTripVisit__c = visitMap.get(a.BusinessTripVisit__c);
                visitActionClones.add(na);
            }
            insert visitActionClones;



            /**********************************
             * 4️⃣ CLONAR VISIT REQUESTS
             **********************************/
            List<BusinessTripVisitRequest__c> visitReqs = [
                SELECT Id, Name, BusinessTripVisit__c, Comment__c, Priority__c, Title__c
                FROM BusinessTripVisitRequest__c
                WHERE BusinessTripVisit__r.BusinessTrip__c = :tripId
            ];

            List<BusinessTripVisitRequest__c> visitReqClones = new List<BusinessTripVisitRequest__c>();
            for (BusinessTripVisitRequest__c r : visitReqs) {
                BusinessTripVisitRequest__c nr = r.clone(false, false, false, false);
                nr.BusinessTripVisit__c = visitMap.get(r.BusinessTripVisit__c);
                visitReqClones.add(nr);
            }
            insert visitReqClones;



            /**********************************
             * 5️⃣ CLONAR VISIT EVENTS
             **********************************/
            List<BusinessTripVisitEvent__c> visitEvents = [
                SELECT Id, Name, BusinessTripVisit__c, Type__c, Status__c, Description__c, Agreement__c, OtherType__c
                FROM BusinessTripVisitEvent__c
                WHERE BusinessTripVisit__r.BusinessTrip__c = :tripId
            ];

            List<BusinessTripVisitEvent__c> visitEventClones = new List<BusinessTripVisitEvent__c>();
            for (BusinessTripVisitEvent__c e : visitEvents) {
                BusinessTripVisitEvent__c ne = e.clone(false, false, false, false);
                ne.BusinessTripVisit__c = visitMap.get(e.BusinessTripVisit__c);
                visitEventClones.add(ne);
            }
            insert visitEventClones;



            /**********************************
             * 6️⃣ CLONAR STRATEGIES
             **********************************/
            List<BusinessTripStrategy__c> strategies = [
                SELECT Id, Account__c, Country__c, Title__c, Name, Comment__c, Impact__c
                FROM BusinessTripStrategy__c
                WHERE BusinessTrip__c = :tripId
            ];

            List<BusinessTripStrategy__c> stratClones = new List<BusinessTripStrategy__c>();
            for (BusinessTripStrategy__c s : strategies) {
                BusinessTripStrategy__c ns = s.clone(false, false, false, false);
                ns.BusinessTrip__c = cloneHeader.Id;
                stratClones.add(ns);
            }

            insert stratClones;

            // 🔁 Map STRATEGY original → nuevo
            Map<Id, Id> strategyMap = new Map<Id, Id>();
            for (Integer i = 0; i < strategies.size(); i++) {
                strategyMap.put(strategies[i].Id, stratClones[i].Id);
            }



            /**********************************
             * 7️⃣ CLONAR STRATEGY ACTIONS
             **********************************/
            List<BusinessTripStrategyAction__c> stratActions = [
                SELECT Id, Name, BusinessTripStrategy__c, Comment__c, Priority__c, Title__c
                FROM BusinessTripStrategyAction__c
                WHERE BusinessTripStrategy__r.BusinessTrip__c = :tripId
            ];

            List<BusinessTripStrategyAction__c> stratActionClones = new List<BusinessTripStrategyAction__c>();
            for (BusinessTripStrategyAction__c a : stratActions) {
                BusinessTripStrategyAction__c na = a.clone(false, false, false, false);
                na.BusinessTripStrategy__c = strategyMap.get(a.BusinessTripStrategy__c);
                stratActionClones.add(na);
            }
            insert stratActionClones;



            /**********************************
             * 8️⃣ CLONAR STRATEGY REQUESTS
             **********************************/
            List<BusinessTripStrategyRequest__c> stratReqs = [
                SELECT Id, Name, BusinessTripStrategy__c, Comment__c, Priority__c, Title__c
                FROM BusinessTripStrategyRequest__c
                WHERE BusinessTripStrategy__r.BusinessTrip__c = :tripId
            ];

            List<BusinessTripStrategyRequest__c> stratReqClones = new List<BusinessTripStrategyRequest__c>();
            for (BusinessTripStrategyRequest__c r : stratReqs) {
                BusinessTripStrategyRequest__c nr = r.clone(false, false, false, false);
                nr.BusinessTripStrategy__c = strategyMap.get(r.BusinessTripStrategy__c);
                stratReqClones.add(nr);
            }
            insert stratReqClones;



            /**********************************
             * FINAL
             **********************************/
            update original;
            return cloneHeader.Id;

        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }

    public class SendPdfInput {
        @InvocableVariable(required=true)
        public List<String> toAddresses;

        @InvocableVariable(required=true)
        public List<String> ccAddresses;

        @InvocableVariable(required=true)
        public String tripId;

        @InvocableVariable(required=true)
        public String title;

        @InvocableVariable(required=false)
        public String body;
    }

    public class BusinessTripVisitWrapper {
        public BusinessTripVisit__c visit { get; set; }
        public List<BusinessTripVisitAction__c> actions { get; set; }
        public List<BusinessTripVisitEvent__c> events { get; set; }
        public List<BusinessTripVisitRequest__c> requests { get; set; }

        public BusinessTripVisitWrapper(BusinessTripVisit__c v,
                                    List<BusinessTripVisitAction__c> actions,
                                    List<BusinessTripVisitRequest__c> requests,
                                    List<BusinessTripVisitEvent__c> events) {
            this.visit = v;
            this.actions = actions;
            this.requests = requests;
            this.events = events;
        }
    }

    public class BusinessTripStrategyWrapper {
        public BusinessTripStrategy__c strategy { get; set; }
        public List<BusinessTripStrategyAction__c> actions { get; set; }
        public List<BusinessTripStrategyRequest__c> requests { get; set; }

        public BusinessTripStrategyWrapper(BusinessTripStrategy__c s,
                                        List<BusinessTripStrategyAction__c> actions,
                                        List<BusinessTripStrategyRequest__c> requests) {
            this.strategy = s;
            this.actions = actions;
            this.requests = requests;
        }
    }

    public class businesssTripData {
        @AuraEnabled
        public BusinessTrip__c header;

        @AuraEnabled
        public List<BusinessTripVisitWrapper> visits;

        @AuraEnabled
        public List<BusinessTripStrategyWrapper> strategies;

        @AuraEnabled
        public Map<Id, List<ContentDocumentLink>> fileLinks;

        public businesssTripData(String tripId) {
            this.header = BusinessTripController.getBusinessTripHeader(tripId);

            List<BusinessTripVisit__c> visitRecords = BusinessTripController.getBusinessTripVisits(tripId);
            List<BusinessTripVisitAction__c> visitActions = getBusinessTripVisitActions(tripId);
            List<BusinessTripVisitRequest__c> visitRequests = getBusinessTripVisitRequests(tripId);
            List<BusinessTripVisitEvent__c> visitEvents = getBusinessTripVisitEvents(tripId);

            List<BusinessTripStrategy__c> strategyRecords = BusinessTripController.getBusinessTripStrategies(tripId);
            List<BusinessTripStrategyAction__c> strategyActions = getBusinessTripStrategyActions(tripId);
            List<BusinessTripStrategyRequest__c> strategyRequests = getBusinessTripStrategyRequests(tripId);

            Set<Id> parentIds = new Set<Id>();
            Map<Id, List<ContentDocumentLink>> filesByParent = new Map<Id, List<ContentDocumentLink>>();

            filesByParent.put(this.header.Id, new List<ContentDocumentLink>());
            parentIds.add(this.header.Id);

            for (BusinessTripVisit__c v : visitRecords) {
                filesByParent.put(v.Id, new List<ContentDocumentLink>());
                parentIds.add(v.Id);
            }
            for (BusinessTripVisitAction__c va : visitActions) {
                filesByParent.put(va.Id, new List<ContentDocumentLink>());
                parentIds.add(va.Id);
            }
            for (BusinessTripVisitRequest__c vr : visitRequests) {
                filesByParent.put(vr.Id, new List<ContentDocumentLink>());
                parentIds.add(vr.Id);
            }
            for (BusinessTripVisitEvent__c ve : visitEvents) {
                filesByParent.put(ve.Id, new List<ContentDocumentLink>());
                parentIds.add(ve.Id);
            }
            for (BusinessTripStrategy__c s : strategyRecords) {
                filesByParent.put(s.Id, new List<ContentDocumentLink>());
                parentIds.add(s.Id);
            }
            for (BusinessTripStrategyAction__c sa : strategyActions) {
                filesByParent.put(sa.Id, new List<ContentDocumentLink>());
                parentIds.add(sa.Id);
            }
            for (BusinessTripStrategyRequest__c sr : strategyRequests) {
                filesByParent.put(sr.Id, new List<ContentDocumentLink>());
                parentIds.add(sr.Id);
            }

            List<ContentDocumentLink> fileLinks = [
                SELECT ContentDocumentId,
                    LinkedEntityId,
                    ContentDocument.Title,
                    ContentDocument.FileType,
                    ContentDocument.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :parentIds
            ];

            for (ContentDocumentLink cdl : fileLinks) {
                if (!filesByParent.containsKey(cdl.LinkedEntityId)) {
                    filesByParent.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                }
                filesByParent.get(cdl.LinkedEntityId).add(cdl);
            }

            this.fileLinks = filesByParent;

            System.debug(this.fileLinks);


            Map<Id, List<BusinessTripVisitAction__c>> visitActionsMap = new Map<Id, List<BusinessTripVisitAction__c>>();
            for (BusinessTripVisitAction__c action : visitActions) {
                if (!visitActionsMap.containsKey(action.BusinessTripVisit__c)) {
                    visitActionsMap.put(action.BusinessTripVisit__c, new List<BusinessTripVisitAction__c>());
                }
                visitActionsMap.get(action.BusinessTripVisit__c).add(action);
            }

            Map<Id, List<BusinessTripVisitRequest__c>> visitRequestsMap = new Map<Id, List<BusinessTripVisitRequest__c>>();
            for (BusinessTripVisitRequest__c request : visitRequests) {
                if (!visitRequestsMap.containsKey(request.BusinessTripVisit__c)) {
                    visitRequestsMap.put(request.BusinessTripVisit__c, new List<BusinessTripVisitRequest__c>());
                }
                visitRequestsMap.get(request.BusinessTripVisit__c).add(request);
            }

            Map<Id, List<BusinessTripVisitEvent__c>> visitEventsMap = new Map<Id, List<BusinessTripVisitEvent__c>>();
            for (BusinessTripVisitEvent__c event : visitEvents) {
                if (!visitEventsMap.containsKey(event.BusinessTripVisit__c)) {
                    visitEventsMap.put(event.BusinessTripVisit__c, new List<BusinessTripVisitEvent__c>());
                }
                visitEventsMap.get(event.BusinessTripVisit__c).add(event);
            }

            Map<Id, List<BusinessTripStrategyAction__c>> strategyActionsMap = new Map<Id, List<BusinessTripStrategyAction__c>>();
            for (BusinessTripStrategyAction__c action : strategyActions) {
                if (!strategyActionsMap.containsKey(action.BusinessTripStrategy__c)) {
                    strategyActionsMap.put(action.BusinessTripStrategy__c, new List<BusinessTripStrategyAction__c>());
                }
                strategyActionsMap.get(action.BusinessTripStrategy__c).add(action);
            }

            Map<Id, List<BusinessTripStrategyRequest__c>> strategyRequestsMap = new Map<Id, List<BusinessTripStrategyRequest__c>>();
            for (BusinessTripStrategyRequest__c request : strategyRequests) {
                if (!strategyRequestsMap.containsKey(request.BusinessTripStrategy__c)) {
                    strategyRequestsMap.put(request.BusinessTripStrategy__c, new List<BusinessTripStrategyRequest__c>());
                }
                strategyRequestsMap.get(request.BusinessTripStrategy__c).add(request);
            }

            this.visits = new List<BusinessTripVisitWrapper>();
            for (BusinessTripVisit__c v : visitRecords) {
                this.visits.add(
                    new BusinessTripVisitWrapper(
                        v,
                        visitActionsMap.get(v.Id),
                        visitRequestsMap.get(v.Id),
                        visitEventsMap.get(v.Id)
                    )
                );
            }

            this.strategies = new List<BusinessTripStrategyWrapper>();
            for (BusinessTripStrategy__c s : strategyRecords) {
                this.strategies.add(
                    new BusinessTripStrategyWrapper(
                        s,
                        strategyActionsMap.get(s.Id),
                        strategyRequestsMap.get(s.Id)                    )
                );
            }
        }
    }
}