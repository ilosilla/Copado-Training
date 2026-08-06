/**
* @author   Ramón prades
* @date     Marzo 2021
* @group    Tools
* @description Gets an an owner from the combination of state, profile, productline (made for the US)
*
* As the algorithm is quite complex, this is how it should work (apart from postcode and state):
*
* On the database we have:
* - USER0   KRION   CONSUMER
* - USER1   KRION   null
*  -USER2   null    CONSUMER
*
* The results:
* - SEARCH KRION+CONSUMER     returns USER0
* - SEARCH KRION              returns USER1
* - SEARCH CONSUMER           returns USER2
* - SEARCH KITCHEN+CONSUMER   returns USER2
* - SEARCH KRION+FIXER        returns USER1
*
* In other words:
* - First we match both values
* - Then match product line and empty profile
* - Then match profile and empty productline
*
*/
public class USAAssignator extends AbstractOwnerAssignator 
{

    private List<PostCodeObjects__c> matches;
    private String blankToken = '@@@'; // Blanks give problems. We replace blanks with this token in the source code.
  
    public override User getOwner() {

        User user = this.getFilteredOwner();

        // If no filters, or no match using filters, do a plain search for sales office
        if (user == null) {
            SalesOfficeAssignator assignator = new SalesOfficeAssignator();
            assignator.setCountry(this.countryCode);
            assignator.setPostCode(this.postCode);
            assignator.setState(this.state);
            user = assignator.getOwner();
        }

        // If still no filters, check the unlisted country
        if (user == null && this.countryCode != 'US' && this.countryCode != 'CA' ) {
            user = this.getUnlistedCountriesOwner();
        }

        // Default user for USA Assignation method
        if (user == null && SystemSettings.USDefaultOwner != null) {
            user = UserUtils.getData(SystemSettings.USDefaultOwner);
        }

        return user;

    } // getOwner

    /*************************************************/
    /************* PRIVATE METHODS *******************/
    /*************************************************/
    
    private User getFilteredOwner() {

        String productFilter = this.productLine;
        if (String.IsBlank(productFilter)) {
            productFilter = blankToken;
        }    

        String profileFilter = this.profile;
        if (String.IsBlank(profileFilter)) {
            profileFilter = blankToken;
        }
        this.readList();
        this.prepareList();

        PostCodeObjects__c pcode = null;

        // Searches matches on product line and profile.
        if (productFilter != blankToken && profileFIlter != blankToken) {
            pcode = this.filterAll(productFilter, profileFilter);
        }
        
        // If not match, search per product line only
        if (pcode == null && productFilter != blankToken) {
        pcode = this.filterAll(productFilter, blankToken);
        }

        // If not match, search per profile
        if (pcode == null && profileFilter != blankToken) {
        pcode = this.filterAll(blankToken, profileFilter);
        }

        // If not match, search without profile and without product line
        if (pcode == null) {
            pcode = this.filterAll(blankToken, blankToken);
        }

        User user = null;
        if (pcode != null) {
        user = [select Id, Firstname, Lastname, sales_Office__c, Name, Appointment__c, EMail from User where Id = :pcode.objectId__c limit 1];
        }
        
        return user;
    } // getFilteredOwner

    private PostCodeObjects__c filterAll(String productLineFilter, String profileFilter) {    
        // Premise: the list is orderded from most specific to more generic (postcode to country)
        for (PostCodeObjects__c pcode :this.matches) {
            if (productLineFilter.contains(pcode.ProductLine__c) && profileFilter == pcode.Profile__c) {
                return pcode;        
            }
        }
        return null;
    } // filterAll

    /**
     * Reads a list of PostCodeObjects where the postcode matches the postcode passed,
     * then matches the state and finally the country. The result is a list where we havel all matches sorted from
     * more specific (the postcode) to more general (the country).
     */
    private void readList() {
        this.matches =  new List<PostCodeObjects__c>();    
        PostCodeObjectFinder finder1 = new PostCodeObjectFinder('OWNER_USA');
        finder1.countryCode = this.countryCode;
        finder1.state = this.state;
        finder1.postCode = this.postCode;
        this.matches =  finder1.findAllRecords();
    } // readPostCodes

    /**
     * Prepares the list of PostCodeObjects to optimize the search (uses blank tokens and convert all profiles and products to capitals)
     */
    private void prepareList() {
        for (PostCodeObjects__c pcode :this.matches) {
            if (String.IsEmpty(pcode.ProductLine__c)) {
                pcode.ProductLine__c = blankToken;
            } else {
                pcode.ProductLine__c = pcode.ProductLine__c.ToUpperCase();
            }
            if (String.IsEmpty(pcode.Profile__c)) {
                pcode.Profile__c = blankToken;        
            } else {
                pcode.Profile__c = pcode.Profile__c.ToUpperCase();
            }
        } //for
    } // prepareList
        
    private void debugList() {
        for (PostCodeObjects__c match :this.matches) {
            System.debug(' RPR -> ' + match.Profile__c + ' Y ' + match.ProductLine__c + ' Y ' + match.objectId__c);
        }
    }

    private User getUnlistedCountriesOwner() {
        User owner = null;
        PostCodeObjectFinder finder1 = new PostCodeObjectFinder('OWNER_USA');
        finder1.countryCode = '**';
        this.matches =  finder1.findAllRecords();
        if (this.matches.size() > 0) {
            owner = [select Id, Firstname, Lastname, sales_Office__c, Name, Appointment__c, EMail, IsActive from User where Id = :this.matches[0].objectId__c limit 1];
            if (!owner.isActive) {
                owner = null;
            }
        }
        return owner;
    }
} // class