/**
* @author 		Ramón Prades
* @date 		May 2021
* @group 		Tools
* @description 	Formats and validates an contry-specific address
*/
public with sharing class InternationalAddress {

    private String street;
    private String city;
    private String stateCode;
    private String state;
    private String countryCode;
    private String country;
    private String postCode;

    /**
     * Reads the address from an opportunity
     */
    public static InternationalAddress fromOpportunity(Id id) {
        Opportunity opp = [select Id, Address__c, City__c, Postcode__c,countryCode__c from Opportunity where Id = :id limit 1];
        InternationalAddress addr = new InternationalAddress();
        addr.street = opp.Address__c;
        addr.city = opp.City__c;
        addr.countryCode = opp.countryCode__c;
        addr.postCode = opp.postCode__c;
        return addr;
    } // fromOpportunity

    /** 
     * Formats to string
     */
    public String format() {
        return this.formatAddress('\n');
    } // format

    /** 
     * Formats to HTML string
     */
    public String formatHTML() {
        return this.formatAddress('<br/>');
    } // formatHTML

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    
    private String formatAddress(String newLine) {
        
        String result = '';
        
        // Refactor to subclasses per country
        if (this.countryCode == 'GB') {
            result = this.street + newLine;
            result += this.city.toUpperCase() + newLine;
            result += this.postCode.toUpperCase() + newLine;
            result += this.getCountryName(this.countryCode);
        } else  {
            result = this.street + newLine;
            result += this.postCode + ' ' + this.city + newLine;
            result += this.getCountryName(this.countryCode);
        }

        return result;

    } // formatAddress

    private String getCountryName(String value){
        Schema.DescribeFieldResult statusOptions = Opportunity.CountryCode__c.getDescribe();
        Map<String, String> labelToValueMap = new Map<String, String>();
        for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
            if (p.isActive()) {
                labelToValueMap.put(p.getValue(), p.getLabel());
            }
        }
    
        if(labelToValueMap.containsKey(value)){
            return labelToValueMap.get(value);
        }
    
        return value;
    }
}