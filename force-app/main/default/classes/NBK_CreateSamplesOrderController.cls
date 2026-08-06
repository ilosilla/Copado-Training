/**
 * @description       : clase test del controlador de LWC NBK_CreateSamplesOrder
 * @author            : alejandro.roda@nubika.com
 * @group             : 
 * @last modified on  : 01-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class NBK_CreateSamplesOrderController {

    @AuraEnabled(cacheable=false)
    public static Pricebook2 getSamplePricebook(String country){
        /*
            Metodo para obtener un pricebook de samples a partir
            de un nombre identificativo, que estara formado por
            SAMPLES-(nombre de un pais)
        */ 
        String pricebookName = 'SAMPLES-' + country;
        List<Pricebook2> samplePBList = new PricebooksSelector().selectByName(pricebookName);

        if (samplePBList.isEmpty()){ 
            throw new NBK_CreateSamplesOrderControllerException('Error');
        }

        return samplePBList[0];

    }

    /*
    @AuraEnabled(cacheable=false)
    public static List<PicklistOption> (Id accountId){
        List<PicklistOption> picklistOpt;
        Account acc = [Select id, AddressesSynced__c  from Account where id=:accountId];
        
        Try {
            //picklistOpt =  getAddressesPicklist(accountId); 
            if(!Test.isRunningTest()){
                if(!acc.AddressesSynced__c ){
                    List<ContactPointAddress> addresses = ContactPointAddressesService.syncFromSAP(accountId, false); // o true si necesitas la lista                
                }
            }
        }Catch (ContextException cex) {
     		// Ya estaba sincronizado
     		picklistOpt =  getAddressesPicklist(accountId);
            return picklistOpt;
        }Catch(Exception e){
            system.debug('Exception e : ' + e);
        }
        
        
        picklistOpt =  getAddressesPicklist(accountId); 
        if (picklistOpt.isEmpty()){
            throw new NBK_CreateSamplesOrderControllerException('Error');
        }

        return picklistOpt;
    }
    */

    @AuraEnabled 
    public static List<Pedidos_cabeceraSet__x> getNextOrders(String accountSAPId) {
        List<Pedidos_cabeceraSet__x> orders = [
            select Customer__c, Salesorg__c,  Ordernum__c, Ordertype__c, Ddate__c, OpenF__c, status__c 
            from Pedidos_cabeceraSet__x 
            where 
                Customer__c = :accountSAPId and
                OpenF__c = 'A' and 
                status__c = '10' and 
                Ddate__c > TOMORROW and 
                ddate__c <= NEXT_N_DAYS:15            
            order by Ddate__c ];
        return orders;
    }

    @AuraEnabled
    public static List<samplesOrgWrapper> getSalesRelationShip(Id accountId){
       
        List<Sales_RelationShip__c> salesOrgs = [
            SELECT Sales_Office__c, Sales_Org__c, Distribution_Channel__c
            FROM Sales_RelationShip__c
            WHERE Account_Org__c =:accountId ORDER BY Sales_Office__c
        ];
        
        Schema.DescribeFieldResult fieldResultOrg = Sales_Relationship__c.Sales_Org__c.getDescribe();
		List<Schema.PicklistEntry> pleOrg = fieldResultOrg.getPicklistValues();
        Map<String,String> salesOrgMap = new Map<String,String>();
		for( Schema.PicklistEntry pickListVal : pleOrg){
			salesOrgMap.put(pickListVal.getValue() ,pickListVal.getLabel().toUpperCase());
		}
        
		Integer position = 1;
        List<samplesOrgWrapper> samplesOrg = new List<SamplesOrgWrapper>();
        if( !salesOrgs.isEmpty()){
            for(Sales_RelationShip__c thisRelation : salesOrgs){
                samplesOrgWrapper thisSamplesOrg = new samplesOrgWrapper();
                thisSamplesOrg.salesOrg = thisRelation.Sales_Org__c;
                thisSamplesOrg.salesOffice = thisRelation.Sales_Office__c;
                thisSamplesOrg.distributionChannel = thisRelation.Distribution_Channel__c;
                thisSamplesOrg.position = position;
                thisSamplesOrg.key = thisSamplesOrg.salesOrg + '-' + thisSamplesOrg.distributionChannel;
                thisSamplesOrg.valueList = '[' + thisSamplesOrg.key + '] ' + salesOrgMap.get(thisRelation.Sales_Org__c);
                position++;
                samplesOrg.add(thisSamplesOrg);
            }
        }
        return samplesOrg;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean getPermissionSet(){
        String permissionSetName = 'NBK_Samples_Permission';
        Boolean dontMatchPermSet = true;
        List<PermissionSetAssignment> permissionSets = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId()];

        if(!permissionSets.isEmpty()){
            for(PermissionSetAssignment perm : permissionSets){
                if(perm.PermissionSet.Name == permissionSetName){
                    dontMatchPermSet = false;
                    break;
                }
            }
        }
        return dontMatchPermSet; // OJO QUE EL RESULTADO ES AL CONTRARIO DE LO ESPERADO: FALSE = TIENE PERMISO
    }

    /*
    @AuraEnabled(cacheable=false)
    public static List<PicklistOption> getWareHousePicklist(Id accountId) {
        
        List<PicklistOption> picklist = new List<PicklistOption>();
        Account acc = [Select id, BillingCountryCode  from Account where id =:accountId limit 1];
        List<PorcelanosaAddress__c> wareHouseList = [SELECT id,Name, NBK_Address__c,NBK_Name_with_adress__c FROM PorcelanosaAddress__c 
                                                     where NBK_Address__CountryCode__s =: acc.BillingCountryCode
                                                     AND NBK_Address_Type__c includes ('Warehouse') 
                                                     AND NBK_isActive__c = true];
        
        for (PorcelanosaAddress__c cpa : wareHouseList) {
            PicklistOption opt = new PicklistOption();
            opt.value = cpa.Id;
            if (cpa.NBK_Address__c != null) {
                opt.label = cpa.Name; // Builds the picklist label
                picklist.add(opt);
            }
        }
        return picklist;
    }
    */

    @AuraEnabled(cacheable=true)
    public static DeliveryOptionsDTO getDeliveryDateOptions(String salesOrg) {
        Sales_Org__c so = [select Name, SamplesCutoff__c, SamplesMinDays__c, SamplesWeekendDays__c, TImeZone__c 
                            from Sales_Org__c 
                            where SalesOrg__c = :salesOrg limit 1];
        DeliveryOptionsDTO dto = new DeliveryOptionsDTO();
        dto.salesOrg = salesOrg;
        dto.salesOrgName = so.Name;

        // Cut-off time
        dto.cutoffTime = null;
        dto.cutoffAdditionalDays = 0;
        if (so.SamplesCutoff__c != null) {
            DateTime auxDate = DateTime.newInstance(System.today(), so.SamplesCutoff__c);
            dto.cutoffTime = auxDate.format('HH:mm');    // Cut-off time as string in warehouse time (i.e. 9:30 London)
            dto.cutoffDateTime = OrganizationUtil.getSamplesCutoff(so); // In Sales Org timezone (i.e. 10:30 Spain)             
            dto.cutoffDateTime = DateTimeCommons.advanceWeekend(dto.cutoffDateTime);
            dto.cutoffAdditionalDays = System.today().daysBetween(dto.cutoffDateTime.date());
        }        
        dto.minDeliveryDays = (Integer) so.SamplesMinDays__c;
        if (dto.minDeliveryDays == null) {
            dto.minDeliveryDays = 2;       // Default
        }
        dto.minDeliveryDate = dto.cutoffDateTime.date().addDays(dto.minDeliveryDays);
        dto.minDeliveryDate = DatetimeCommons.advanceWeekend(dto.minDeliveryDate);
        dto.cutoffDateString = dto.cutoffDateTime.format('yyyy-MM-dd HH:mm:ss', so.TimeZone__c);
        return dto;
    } 

    public class DeliveryOptionsDTO {
        @AuraEnabled public String salesOrg; 
        @AuraEnabled public String salesOrgName;
        @AuraEnabled public String cutoffTime;
        @AuraEnabled public Integer minDeliveryDays;
        @AuraEnabled public String weekendOptions;
        @AuraEnabled public DateTime cutoffDateTime;
        @AuraEnabled public String cutoffDateString;
        @AuraEnabled public Date minDeliveryDate;
        @AuraEnabled public String timezone;
        @AuraEnabled public Integer cutoffAdditionalDays = 0;
    }
    
    /*
    private static List<PicklistOption> getAddressesPicklist(Id accountId) {
        
        List<PicklistOption> picklist = new List<PicklistOption>();
        List<ContactPointAddress> contactPointList = [SELECT id,Name, address FROM ContactPointAddress WHERE ParentId = : accountId];
		
        // Add the account address first
        //if (accountId != null) {
            //PicklistOption accountOption = getAccountAddress(accountId);
            //picklist.add(accountOption);
        //}
        // And the contact addresses next
        PicklistOption optvacia = new PicklistOption();
        optvacia.value = '-';
        optvacia.label = 'Customer default address';
        picklist.add(optvacia);
        for (ContactPointAddress cpa : contactPointList) {
            PicklistOption opt = new PicklistOption();
            opt.value = cpa.Id;
            if (cpa.address != null) {
                opt.label = AddressCommons.buildAddressLabel(cpa.Name, cpa.address); // Builds the picklist label
                picklist.add(opt);
            }
        }
        return picklist;
    }
    */

    public class NBK_CreateSamplesOrderControllerException extends Exception {}
    public class PicklistOption{
        @AuraEnabled 
        public String label;
        @AuraEnabled 
        public String value;
    }
    
    public class samplesOrgWrapper{
        @AuraEnabled 
        public String valueList;
        @AuraEnabled 
        public String salesOrg;
        @AuraEnabled 
        public String salesOffice;
        @AuraEnabled 
        public String distributionChannel;
        @AuraEnabled 
        public Integer position;
        @AuraEnabled 
        public String key;
    }
}