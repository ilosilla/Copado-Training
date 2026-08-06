public class AddressStoreWRP {
     @AuraEnabled
        public PorcelanosaAddress__c address {get; set;}
        @AuraEnabled
        public Decimal distance {get; set;}
        @AuraEnabled
        public String imageStore {get; set;}

        public AddressStoreWRP(PorcelanosaAddress__c address, Decimal distance, String imageStore){
                this.address = address;
                this.distance = distance;
                this.imageStore = imageStore;
        }
        public AddressStoreWRP(){}
}