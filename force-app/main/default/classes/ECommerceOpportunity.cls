/**
* @author 			Ramón Prades
* @date 			October-2020
* @group 			Opportunities
* @description 	    Class to create a samples opportunity from ecommerce
*/

public class ECommerceOpportunity {
    
    public Boolean ownerChanged { get; private set; }
    public Account account { get; private set; }
    private Opportunity theOpportunity;    
    private Order order; 

    /**
     * Creates a samples opportunity from a samples order
     */
    public ECommerceOpportunity(Order newOrder) {
        this.ownerChanged = false;
        this.order = newOrder;
        if (ECommerceUtils.findOpportunity(newOrder.SAP_Id__c) != null) {
            throw new ObjectExistsException();
        } else {    
            this.readAccount();
            this.fixAccountOwner();
            this.theOpportunity = this.createOpportunity();
        }
    } // constructor
        
    public Opportunity getOpportunity() {
        return this.theOpportunity;
    } // getOpportunity

    /***********************************************************************************/

    private Opportunity createOpportunity() {
        AddressDTO addressDTO = AddressDTO.readFromAccount(this.order.AccountId);        
        String name = this.buildName(this.order);
        String description = this.buildDescription(this.order);
        Id rt = RecordTypeLibrary.Opportunity_Ecommerce;
        return new Opportunity(
            Name = name,
            CloseDate = System.today().addDays(10),
            StageName = 'New',
            Product_Categories__c = 'Ceramics',
            Operation_Type__c = 'New construction',
            AccountId = this.order.AccountId,
            countryCode__c = addressDTO.countryCode,
            OwnerId = this.account.OwnerId,
            ecommerce__c = true,
            city__c = addressDTO.city,
            Address__c = addressDTO.Street,
            Postcode__c = addressDTO.postCode,
            Opportunity_Classification__c = 'Samples Ecommerce',
            RecordTypeId = rt,
            Description = description,
            SAP_Order__c = this.order.SAP_Id__c
            );
    } // createOpportunity

    private void readAccount() {
        this.account = [select Id, OwnerId from account where id = :this.order.AccountId][0];   
    } // readAccount

    private void fixAccountOwner() {
        if (this.account.OwnerId == null || UserUtils.isGenericUser(this.account.OwnerId)) {
            User owner = userUtils.getSalesOfficeRandomUser(this.order.salesOffice__c);
            if (owner != null) {
                this.ownerChanged = true;
                this.account.OwnerId = owner.Id;
            }            
        }
    } // fixAccountOwner

    private String buildName(Order order) {
        if (OrganizationUtil.isFrench(order.SalesOrg__c)) {
            return 'ECOMMERCE ÉCHANTILLON COMMANDE #' + order.Sap_Id__c;
        } else {
            return 'ECOMMERCE SAMPLES ORDER #' + order.Sap_Id__c;
        } 
    } // buildName

    private String buildDescription(Order order) {
        if (String.IsNotBlank(order.Description)) {
            return order.Description;
        } else {
            if (OrganizationUtil.isFrench(order.SalesOrg__c)) {
                return 'Opportunité automatiquement créée par le commande SAP ' + order.Sap_Id__c + '.';
            } else {
                return 'Opportunity created automatically for SAP samples order #' + order.Sap_Id__c + '.';
            } 
        } 
    } // buildDescription

} // class