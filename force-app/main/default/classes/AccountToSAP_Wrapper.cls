global class AccountToSAP_Wrapper {
    
    global Account customer;
    global List<Sales_Relationship__c> companies;

    global AccountToSAP_Wrapper(Account account, List<Sales_Relationship__c> salesRelations){
        
        this.customer = account;
        this.companies = salesRelations;

    }
    
}