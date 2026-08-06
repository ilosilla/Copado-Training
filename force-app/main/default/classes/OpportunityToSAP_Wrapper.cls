global class OpportunityToSAP_Wrapper {
    
    global Opportunity opportunity;
    global List<OpportunityContactRole> opportunityActorsList;
    
    global OpportunityToSAP_Wrapper(Opportunity opportunity, List<OpportunityContactRole> opportunityContactRolesList){
        
        this.opportunity = opportunity;
        this.opportunityActorsList = opportunityContactRolesList;
        
    }

}