/**
* @author 			Ramón Prades
* @since 			April 2021
* @group 			Utils
* @description 	    Utiloity methods to handle adddresses
* Regex taken from https://www.pixelenvision.com/1708/zip-postal-code-validation-regex-php-code-for-12-countries/
*/
public class AddressUtil {
    private Map<String,String> postCodeMapped = new Map<String,String>();

    public static String normalizeUSCode(String postCode) {
        if (postCode == null) {
            postCOde = '';
        }
        return postCode.leftPad(5,'0');
    } // normalizeUSCode

    public AddressUtil() {
        this.postCodeMapped.put('Global',null);
        this.postCodeMapped.put('Medium',null);
        this.postCodeMapped.put('Specific',null);
        this.postCodeMapped.put('Valid','true');
    }
    /**
     * Given a country and postCode, returns if the post code is valid and splited by zones.
     * p.e. postCode => LA22 9NZ, country => 'GB'
     * returns:
     *      ['Global' => 'LA', 'Medium' => 'LA22', 'Specific' => 'LA22 9NZ', 'Valid' => 'true']
     * p.e. postCode => 12003, country => 'ES'
     * returns:
     *      ['Global' => '12', 'Medium' => null, 'Specific' => '12003', 'Valid' => 'true']
     * p.e. postCode => 12003, country => 'ES'
     * 
     * If is not valid, returns: [['Global' => null, 'Medium' => null, 'Specific' => null, 'Valid' => 'false']]
     * 
     */
    public Map<String,String> splitPostCode(String country, String postCode) {
      if (String.isBlank(postCode)) {
        this.postCodeMapped.put('Global', null);
        this.postCodeMapped.put('Medium', null);
        this.postCodeMapped.put('Specific', null);
        this.postCodeMapped.put('Valid', 'true');
        return this.postCodeMapped;
      }

      switch on country {
          when 'ES' {
              splitESPostCode(postCode);
          }	
          when 'GB' {
              splitGBPostCode(postCode);
          }
          when 'FR' {
              splitFRPostCode(postCode);
          }
          when 'US' {
              splitUSPostCode(postCode);
          }
          when 'CA' {
              splitCAPostCode(postCode);
          }
      }
      this.postCodeMapped.put('Specific', postCode);
      return this.postCodeMapped;
    }

    /**
     * Validate and Split the Spanish post code
     */
    public Map<String,String> splitESPostCode(String postCode) {
        Pattern p = Pattern.compile('([1-9]{2}|[0-9][1-9]|[1-9][0-9])([0-9]{3})');
        Matcher pm = p.matcher( postCode );
        
        if( pm.matches() ){
            this.postCodeMapped.put('Global', pm.group(1));
            this.postCodeMapped.put('Specific', postCode);
            this.postCodeMapped.put('Valid', 'true');
        } else {
            this.postCodeMapped.put('Valid', 'false');
        }
        
        return this.postCodeMapped;
    }
    
    /**
     * Validate and Split the French post code
     */
    public Map<String,String> splitFRPostCode(String postCode) {
        Pattern p = Pattern.compile('(^(?:[0-8]\\d|9[0-8]))(\\d{3}$)');
        Matcher pm = p.matcher( postCode );
        
        if( pm.matches() ){
            this.postCodeMapped.put('Global', pm.group(1));
            this.postCodeMapped.put('Specific', postCode);
            this.postCodeMapped.put('Valid', 'true');
        } else {
            this.postCodeMapped.put('Valid', 'false');
        }
        
        return this.postCodeMapped;
    }
    
    /**
     * Validate and Split the English post code
     */
    public Map<String,String> splitGBPostCode(String postCode) {
        Pattern p = Pattern.compile('(^[a-zA-Z]{1,2})([0-9][0-9A-Za-z]{0,1}) {0,1}([0-9][A-Za-z]{2}$)');
        Matcher pm = p.matcher( postCode );
        
        if( pm.matches() ){
            this.postCodeMapped.put('Global', pm.group(1));
            this.postCodeMapped.put('Medium', pm.group(1) + pm.group(2));
            this.postCodeMapped.put('Specific', postCode);
            this.postCodeMapped.put('Valid', 'true');
        } else {
            this.postCodeMapped.put('Valid', 'false');
        }

        return this.postCodeMapped;
    }

    /**
     * Validate and Split the US post code
     */
    public Map<String,String> splitUSPostCode(String postCode) {
        // Pattern p = Pattern.compile('(^\\d{5})[\\-]?(\\d{4}?$)');
        Pattern p = Pattern.compile('^([0-9]{5})(?:-[0-9]{4})?$');
        Matcher pm = p.matcher( postCode );
        
        if( pm.matches() ){
            this.postCodeMapped.put('Global', pm.group(1));
            this.postCodeMapped.put('Specific', postCode);
            this.postCodeMapped.put('Valid', 'true');
        } else {
            this.postCodeMapped.put('Valid', 'false');
        }

        return this.postCodeMapped;
    }

    /**
     * Validate and Split the CA post code
     */
    public Map<String,String> splitCAPostCode(String postCode) {
        Pattern p = Pattern.compile('^([ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJKLMNPRSTVWXYZ])\\ ({0,1}\\d[ABCEGHJKLMNPRSTVWXYZ]\\d)$');
        Matcher pm = p.matcher( postCode );
        
        if( pm.matches() ){
            this.postCodeMapped.put('Global', pm.group(1));
            this.postCodeMapped.put('Specific', postCode);
            this.postCodeMapped.put('Valid', 'true');
        } else {
            this.postCodeMapped.put('Valid', 'false');
        }

        return this.postCodeMapped;
    }

    /**
    * @description Given a PostCode, returns all Sales Org where the post code is valid
    * @param postCode
    * @return List of Sales Organizations
    * 
    * @REFACTOR Pecado mortal una referencia cruizada con PostCodeObjectFinder
    *
    */
   public static List<String> salesOrgPostCode(String countryCode, String postCode) {
      PostCodeObjectFinder objFinder = new PostCodeObjectFinder('SALES_ORG');
      objFinder.countryCode = countryCode;
      objFinder.postCode = postCode;
      List<String> salesOrgs = objFinder.find();
      return salesOrgs;
    }
}