/**
* @author               Ivan Losilla
* @since                June 2020
* @group                Tools
* @description          Finds the objects assigned to a post code. Searches objects in the following order:
*                       1) Full post code range + country
*                       1) Full post code + country
*                       2) Part post code + country
*                       3) State + country
*                       4) Country
*/
public class PostCodeObjectFinder {

    public String countryCode;
    public String state;
    public String postCode;
    private String objectType;
    private SystemLog logger;

    public PostCodeObjectFinder(String objectType) {
        this.objectType = objectType;
        this.logger = new SystemLog('DEBUG');
        this.logger.setTag('PostCodeObjectFinder');
        this.logger.addDebug('Object Type is ' + objectType);
    }

    /**
     * @description  Returns the first objectId matching the parameters set.
    * @return List<PostCodeObjects__c> result
    */
    public String findFirst() {
        List<String> listStrings = find();
        String result = null;

        if (listStrings.size() > 0) {
            result = listStrings[0];
        }
        return result;
    }

    /**
     * @description  Returns all objectIds matching the parameters set, splitting the postCode if needed to search any option.
    * @return List of object ids
    */
    public List<String> find() {
        return getObjectIdsFromPCOList(this.findRecords());
    }

    public void test() {
        this.postCode = 'XXXXX';
    }

    /**
     * @description  Returns all objectIds matching the parameters set, splitting the postCode if needed to search any option. Accumulates
     * all possible results (by looking at all levels)
     * @return list of post code objects
     */
    public List<PostCodeObjects__c> findAllRecords() {
        List<PostCodeObjects__c> result = new List<PostCodeObjects__c>();

        if (this.countryCode == 'US' && String.isNotBlank(this.postCode)) {
            this.postCode = AddressUtil.normalizeUSCode(this.postCode);
            this.postCode = this.postCode.substring(0, 5);
        }
        
        // Searches with postcode
        if (String.isNotBlank(this.postCode)) {
            // Primero con el código exacto
            List<PostCodeObjects__c> list2 = selectPostcode(true);
            result.addAll(list2);

            // Segundo con rango
            List<PostCodeObjects__c> list1 = selectPostcodeRange();
            result.addAll(list1);
        }

        // searches with state
        if (String.isNotBlank(this.state)) {
            List<PostCodeObjects__c> list3 = selectState(this.state);
            result.addAll(list3);
        }

       // searches with country
       List<PostCodeObjects__c> list4 = selectState('');
       result.addAll(list4);

        return result;
    }

    /**
     * @description  Returns all objectIds matching the parameters set, splitting the postCode if needed to search any option.
    * @return list of post code objects
    */
    public List<PostCodeObjects__c> findRecords() {

        List<PostCodeObjects__c> result = new List<PostCodeObjects__c>();

        if (this.countryCode == 'US' && String.isNotBlank(this.postCode)) {
            this.postCode = AddressUtil.normalizeUSCode(this.postCode);
            this.postCode = this.postCode.substring(0, 5);
        }
        
        // Searches with postcode
        if (String.isNotBlank(this.postCode)) {
            result = selectPostcode(false);
        }

        // Searches with postcodeRanges
        if (result.size() == 0 && String.isNotBlank(this.postCode)) {
            result = selectPostcodeRange();
        }

        // searches with state
        if (result.size() == 0 && String.isNotBlank(this.state)) {
            result = selectState(this.state);
        }

        // searches with country
        if (result.size() == 0 ) {
            result = selectState('');
        }

        return result;

    } // find

    /***************************************************/
    /**************** PRIVATE METHODS ******************/
    /***************************************************/
    private List<PostCodeObjects__c> selectPostcode(Boolean fullMode) {        
        
        List<PostCodeObjects__c> result = new List<PostCodeObjects__c>();

        Map<String,String> postCodeParts = new AddressUtil().splitPostCode(this.countryCode, this.postCode);        
        String[] parts = new String[3];
        parts[0] = postCodeParts.get('Specific');
        parts[1] = postCodeParts.get('Medium');
        parts[2] = postCodeParts.get('Global');

        for (Integer i = 0; i <= 2; i++) {
            if (String.isNotBlank(parts[i])) {
                result = [select Id, ObjectId__c, ObjectType__c, PostCode__c, Country__c, State__c, Profile__c, ProductLine__c
                            from PostCodeObjects__c
                            where ObjectType__c = :this.objectType
                            and postCode__c = :parts[i]
                            and country__c = :this.countryCode];
                if (!fullMode && result.size() > 0) {
                    break;
                }
            }
        } // for
        return result;
    }

    private List<PostCodeObjects__c> selectPostcodeRange() {        
        
        List<PostCodeObjects__c> result = new List<PostCodeObjects__c>();
        
        this.logger.addSection('selectPostcodeRange Method');

        Map<String,String> postCodeParts = new AddressUtil().splitPostCode(this.countryCode, this.postCode);        
        String[] parts = new String[3];
        parts[0] = postCodeParts.get('Specific');
        parts[1] = postCodeParts.get('Medium');
        parts[2] = postCodeParts.get('Global');        
        this.logger.addDebug('PostCode ' + this.countryCode + '-' + this.postCode + ' split into the follwing parts:');
        this.logger.addDebug('- part0 (Specific) : ' + parts[0]);
        this.logger.addDebug('- part1 (Medium)   : ' + parts[1]);
        this.logger.addDebug('- part2 (Global)   : ' + parts[2]);

        for (Integer i = 0; i <= 2; i++) {            
            if (String.isNotBlank(parts[i])) {
                this.logger.addDebug('Reading postcodes for part ' + i + ' with value ' + parts[i]);
                result = [select Id, ObjectId__c, ObjectType__c, PostCode__c, Country__c, State__c, Profile__c, ProductLine__c
                from PostCodeObjects__c
                where ObjectType__c = :this.objectType
                    and postCode__c <> null and postCodeTo__c <> null
                    and postCode__c <= :parts[i] and postCodeTo__c >= : parts[i]
                    and country__c = :this.countryCode];
                    this.logger.addDebug(result.size() + ' records found');

                if (result.size() > 0) {
                    break;
                }
            }
        } // for
        this.logger.addDebug('Returning a list with ' + result.size() + ' items');
        this.logger.saveLog();
        return result;
    }

    private List<PostCodeObjects__c> selectState(String stateMask) {
        List<PostCodeObjects__c> result = new List<PostCodeObjects__c>();        
        result = [select Id, ObjectId__c, ObjectType__c, PostCode__c, Country__c, State__c, Profile__c, ProductLine__c
                    from PostCodeObjects__c
                    where ObjectType__c = :objectType
                    and State__c = :stateMask                    
                    and PostCode__c = null
                    and country__c = :this.countryCode];
        return result;
    }
    
    /**
    * @description  Given a list of PostCodeObjects__c, returns a Set with the Ids of the related Objects
    * @return List<String> result
    */
    private static List<String> getObjectIdsFromPCOList( List<PostCodeObjects__c> PCOlist) {
      List<String> IDList = new List<String>();
      for (PostCodeObjects__c pco : PCOList) {
          IDList.add(pco.objectId__c);
      }
      return IDList;
  }
}