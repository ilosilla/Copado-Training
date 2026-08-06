/**
* @author       Ramón prades
* @date         Febrero 2024
* @group        Tools
* @description  Gets an an owner from the a country.
*               Default owner should be in country '**'.
*
*/
public without sharing class CountryOwnerAssignator extends AbstractOwnerAssignator {


    public override User getOwner() {
        if (String.IsBlank(this.variant)) {
            throw new ContextException('Please define a variant before calling CountryOwnerAssignator.getOwner');
        }
        return this.getCountryOwner(this.countryCode);
    } // getOwner

    private User getCountryOwner(String countryCode) {

        String userId = null;

        List<PostCodeObjects__c> matches = this.readList(countryCode);
        if (matches.size() == 0) {
            matches = this.readList('**');
        }

        if (matches.size() > 0) {
            userId = matches[0].objectId__c;
            return new UsersSelector().selectById(userId);
        } else {
            return null;
        }        
    } // getFilteredOwner

    /**
     * Reads a list of PostCodeObjects where the postcode matches the postcode passed,
     * then matches the state and finally the country. The result is a list where we havel all matches sorted from
     * more specific (the postcode) to more general (the country).
     */
    private List<PostCodeObjects__c> readList(String countryCode) {
        PostCodeObjectFinder finder1 = new PostCodeObjectFinder(this.variant);
        finder1.countryCode = countryCode;
        finder1.state = this.state;
        finder1.postCode = this.postCode;
        return finder1.findAllRecords();
    } // readPostCodes

}