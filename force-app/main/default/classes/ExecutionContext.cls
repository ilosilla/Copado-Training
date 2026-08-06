public class ExecutionContext {
    
    /* Aura variables */
    @AuraEnabled
    public String MasterLabel{get;set;}	
    @AuraEnabled
    public Boolean useSAP{get;set;}
    @AuraEnabled
    public String ownerAssignation{get;set;}
    @AuraEnabled
    public String extendedOpps{get;set;}
    @AuraEnabled
    public Boolean priceRequest{get;set;} // forzar despliegue de esta pxxx línea
    @AuraEnabled
    public Boolean lFlowAllowCreate{get;set;}
  
    /* Class members */
    private static ExecutionContext context;
    
    public ExecutionContext( String contextLabel ) {
        if (String.isBlank(contextLabel)) {
            contextLabel = 'DEFAULT';
        }
        Execution_Context__mdt context = [Select MasterLabel, DeveloperName,OwnerAssignation__c, Has_SAP__c, ExtendedOpps__c, PriceRequest__c, IFlow_allow_create__c From Execution_Context__mdt Where DeveloperName = :contextLabel];
        this.masterLabel = context.DeveloperName;
        this.useSAP = context.Has_SAP__c;
        this.ownerAssignation = context.OwnerAssignation__c;
        this.priceRequest = context.PriceRequest__c;
        this.extendedOpps = context.ExtendedOpps__c;
        this.lFlowAllowCreate = context.IFlow_allow_create__c;
        if (this.extendedOpps == null) {
          this.extendedOpps = '';
        }
    }
  
    @AuraEnabled(cacheable=true)
    public static ExecutionContext getUserExecutionContext() {
        String contextLabel = [Select Execution_Context__c From User Where  Id = :UserInfo.getUserId()].Execution_Context__c;
        if (ExecutionContext.context == null) {
            ExecutionContext.context =  new ExecutionContext( contextLabel );
        }
        return ExecutionContext.context;
    }
  
  }