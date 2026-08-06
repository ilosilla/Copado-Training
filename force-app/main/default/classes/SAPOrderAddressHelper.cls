/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    Searches the SAPId of the addresses of a list of orders
 * 
 * Use method "matchSAPId" to update the SAPId on the delivery addresses .
*/
public class SAPOrderAddressHelper {

    private Order[] orders;                                         
    private Set<Id> orderIds;                                       
    private Set<Id> accountIds;
    private List<OrderDeliveryGroup> orderDeliveryGroups;
    Map<Id, Order> ordersById;                                      // Map relating order Id with order object
    Map<Id, List<OrderDeliveryGroup>> shippingByAccount;            // Map relating accounts with their list of delivery addresses
    Map<Id, LocalAddressDTO[]> accountAddressMap;                   // Maps accounts to their deliveru addresses (in LocalDTO format) 
    Map<Id, LocalAddressDTO> orderMatches;                          // Map of matched addresses    

    public SAPOrderAddressHelper(Order[] orders) {
        this.orders = orders;
        this.indexOrders();
        this.orderDeliveryGroups = this.readDeliveryAddresses();       
    }

    public Boolean matchSAPId() {        
        this.indexDeliveryGroups();      
        this.readAccountAddresses();
        this.readContactPointAddresses();
        return (this.match() > 0);
    }

    public List<OrderDeliveryGroup> getDeliveryAddresses() {
        return this.orderDeliveryGroups;
    }

    public Map<Id, OrderDeliveryGroup> getDeliveryAddressesMap() {        
        Map<Id, OrderDeliveryGroup> result = new Map<Id, OrderDeliveryGroup>();
        for (OrderDeliveryGroup dg :this.orderDeliveryGroups) {
            result.put(dg.OrderId, dg);
        }
        return result;    
    }

    private Integer match() {
        this.orderDeliveryGroups = new List<OrderDeliveryGroup>();
        OrderDeliveryGroup[] changedDeliveries = new List<OrderDeliveryGroup>();
        this.orderMatches = new Map<Id, LocalAddressDTO>();
        for (Id accountId : this.shippingByAccount.keySet()) {
            List<LocalAddressDTO> accountAddresses = this.accountAddressMap.get(accountId);         
            List<OrderDeliveryGroup> deliveries = this.shippingByAccount.get(accountId);            
            for (OrderDeliveryGroup delivery :deliveries ) {
                if (delivery.SAPId__c == null) {
                    AddressDTO deliveryDTO = this.deliveryGroupToAddress(delivery);
                    for (LocalAddressDTO localDTO : accountAddresses) {
                        if (deliveryDTO.isTheSame(localDTO.address)) {
                            delivery.SAPId__c = localDTO.SAPId;
                            changedDeliveries.add(delivery);
                            this.orderMatches.put(delivery.OrderId, localDTO);
                            break;
                        }
                    }
                }                 
                this.orderDeliveryGroups.add(delivery);
            }
        }
        update changedDeliveries;
        return this.orderMatches.keySet().size();
    }

    private List<OrderDeliveryGroup> readDeliveryAddresses() {        
        return [select  Id, SAPId__c, OrderId, DeliverToCountryCode, DeliverToStateCode, DeliverToCity, DeliverToStreet, DeliverToPostalCode, DeliveryInstructions, DesiredDeliveryDate, EMailAddress, PhoneNumber from  OrderDeliveryGroup where OrderId in :this.orderIds];
    } 
    
    private void indexDeliveryGroups() {
        this.accountIds = new Set<Id>();
        this.shippingByAccount = new Map<Id, List<OrderDeliveryGroup>>();        
        for (OrderDeliveryGroup shippingGroup  :this.orderDeliveryGroups) {
            Order o = this.ordersById.get(shippingGroup.OrderId);
            if (o != null) {
                List<OrderDeliveryGroup> addresses = shippingByAccount.get(o.AccountId);
                if(addresses == null) {
                    addresses = new List<OrderDeliveryGroup>();
                    shippingByAccount.put(o.AccountId, addresses);
                }
                addresses.add(shippingGroup);
                if (!this.accountIds.contains(o.AccountId)) {
                    this.accountIds.add(o.AccountId);
                }
            }
        }
    }

    private void readAccountAddresses() {
        this.accountAddressMap = new Map<Id, LocalAddressDTO[]>();
        Account[] accounts = new AccountsSelector().selectById(this.accountIds);        
        for (Account acc :accounts) {
            LocalAddressDTO dto = new LocalAddressDTO();
            dto.Id = acc.Id;
            dto.SAPId = acc.SAP_Id__c;
            dto.isAccountAddress = true;
            dto.address = this.accountToAddress(acc);
            LocalAddressDTO[] addresses = new List<LocalAddressDTO>();
            addresses.add(dto);            
            this.accountAddressMap.put(acc.Id, addresses);            
        }
    }

    private void readContactPointAddresses() {
        ContactPointAddress[] cpas = new ContactPointAddressesSelector().selectByAccount(this.accountIds);        
        for (ContactPointAddress cpa :cpas) {
            LocalAddressDTO dto = new LocalAddressDTO();
            dto.Id = cpa.Id;
            dto.SAPId = cpa.SAPId__c;
            dto.isAccountAddress = false;
            dto.address = this.contactPointToAddress(cpa);
            LocalAddressDTO[] addresses = this.accountAddressMap.get(cpa.ParentId);// Must exist!
            addresses.add(dto);            
            this.accountAddressMap.put(cpa.ParentId, addresses);            
        }
    }


    private void indexOrders() {
        this.ordersById = new Map<Id, Order>();
        this.orderIds = new Set<Id>();
        for (Order o :this.orders) {
            this.orderIds.add(o.Id);
            this.ordersById.put(o.Id, o);
        }        
    }

    private AddressDTO accountToAddress(Account account) {
        AddressDTO dto = new AddressDTO();
        if (account.IsPersonAccount) {
            dto.country = account.PersonMailingCountry;
            dto.countryCode = account.PersonMailingCountryCode;
            dto.street = account.PersonMailingStreet;
            dto.city = account.PersonMailingCity;
            dto.postCode = account.PersonMailingState;
            dto.state = account.PersonMailingState; 
            dto.stateCode = account.PersonMailingStateCode;    
        } else {            
            dto.country = account.BillingCountry;
            dto.countryCode = account.BillingCountryCode;
            dto.street = account.BillingStreet;
            dto.city = account.BillingCity;
            dto.postCode = account.BillingPostalCode;
            dto.state = account.BillingState; 
            dto.stateCode = account.BillingStateCode;
            dto.phone1 = account.Phone;
            dto.phone2 = account.PersonMobilePhone;
        }
        return dto;
    }

    private AddressDTO contactPointToAddress(ContactPointAddress cpa) {
        AddressDTO result = new AddressDTO();
        result.street = cpa.Street;
        result.city = cpa.City;
        result.StateCode = cpa.StateCode;
        result.countryCode = cpa.CountryCode;
        result.postCode = cpa.PostalCode;
        return result;

    }

    private AddressDTO deliveryGroupToAddress(OrderDeliveryGroup source) {
        AddressDTO result = new AddressDTO();
        result.street = source.DeliverToStreet;
        result.city = source.DeliverToCity;
        result.StateCode = source.DeliverToStateCode;
        result.countryCode = source.DeliverToCountryCode;
        result.postCode = source.DeliverToPostalCode;
        return result;
    }

    public class LocalAddressDTO {
        public Id Id;
        public String SAPId;
        public Boolean isAccountAddress = false;
        public AddressDTO address;
    }
}