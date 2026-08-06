/**
* @author 			Ivan Losilla
* @date 			May 2021
* @group 			REST
* @description 	    REST service to create Waiting List persons
*/
@RestResource(urlMapping='/custom/waitinglist/*')
global class RESTWaitingList {

    @HttpGet
    global static void ping () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"hola":"mundo"}');
    }
    
    @HttpPost
    global static void create (String FirstName, String LastName, String Phone, String Email, String SalesOffice) {
        RestResponse response = RestContext.response;
        WaitingList__c wlPerson = null;
        try {
            if (String.isBlank(FirstName) || String.isBlank(LastName) || String.isBlank(Phone) || String.isBlank(SalesOffice)) {
                response.statusCode = 404;
                response.responseBody = Blob.valueOf('{"Message": "All fields are required!"}');
            } else {
                List<Sales_Office__c> salesOfficeDMLBase = [Select Id, SalesOffice__c from Sales_Office__c];
                List<Sales_Office__c> salesOfficeDML = [Select Id, SalesOffice__c from Sales_Office__c where SalesOffice__c =: SalesOffice];
                if (salesOfficeDML.size() == 0) {
                    response.statusCode = 404;
                    response.responseBody = Blob.valueOf('{"Message":"Sales Office not valid"}');
                } else {
                    wlPerson = new WaitingList__c(FirstName__c = FirstName,
                                                                LastName__c = LastName,
                                                                Phone__c = Phone,
                                                                Email__c = Email,
                                                                SalesOffice__c = salesOfficeDML[0].Id);
                    insert wlPerson;
                    WaitingList newWL = new WaitingList(wlPerson.Id);
                    newWL.sendNotificationNewWLItem();
                    response.statusCode = 204;
                    response.responseBody = Blob.valueOf('Object created!');
                }
            }

        } catch (ObjectExistsException ex) {
            response.statusCode = 404;
            response.responseBody = Blob.valueOf('{"Message": "Waiting List person failed!"}');
        }
    } // create
        
} // class