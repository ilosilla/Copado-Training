/**
* @author 		Ramón Prades
* @date 		August 2021
* @group 		REST
* @description 	Generic web service to let external systems communicate events that change the state of salesforce objects. 
*               It is meant to simplfy the implementation of simple actions that aren't worth the development of a indivudual web service.
*/
@RestResource(urlMapping='/x-events/*')
global class RESTXEvent {

    @HttpGet global static void ping () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"message":"Hi from X-Events class!"}');
    }

    @HttpPost global static void post (String event, String source, String target, Map<String,String> args) {
        Integer httpCode = 204;
        String message = '';
        RestResponse response = RestContext.response;                
        try {
            switch on event.toUpperCase() {
                when 'QUOTE' {
                    SetOpportunityQuoted(target, source, args);
                }
                when else {
                    httpCode = 404;
                    message = 'Wrong event name "' + event + '"';
                }
            }
            // opp = createSamplesOpportunity(order);
            response.statusCode = httpCode;
            response.responseBody = Blob.valueOf(message);                                
        } catch (QueryException ex2) {
            response.statusCode = 404;
            response.responseBody = Blob.valueOf('Wrong opportunity Id');                                
        }
    } // post

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private static void SetOpportunityQuoted(String opportunityId, String source, Map<String,String> args) {
        if (args == null) {
            args = new Map<String, String>();
        }
        Opportunity opp = [select Id, StageName, Have_you_sent_a_quote__c, Amount_custom__c, Currency__c from Opportunity where id = :opportunityId limit 1];
        // Change only if stage is 'Qualification'
        if (opp.StageName == OpportunityUtil.QUALIFICATION_STAGE || opp.StageName == OpportunityUtil.SPECIFICATION_STAGE) {
            opp.StageName = OpportunityUtil.QUOTATION_STAGE;
            opp.Have_you_sent_a_quote__c = 'Yes';
            opp.Have_we_won_specification__c = 'Yes';
            if (opp.Amount_custom__c == 0) {
                setAmountFields(opp, args);
            }
            update opp;
        }
    } // SetOpportunityQuoted

    private static void setAmountFields(Opportunity opp, Map<String,String> args) {
        Decimal amount = opp.Amount_custom__c;
        String curr = opp.Currency__c;
        if (args.containsKey('amount')) {
            String amountStr = args.get('amount').trim();
            if (args.containsKey('currency')) {
                curr = args.get('currency');
            }
            opp.Amount_custom__c = Decimal.valueOf(amountStr);
            opp.Currency__c = curr;
        }
    } // setAmountFields

} // class