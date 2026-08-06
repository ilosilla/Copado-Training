/**
* @author 		Ramón Prades
* @date 		November 2022
* @group 		Settings
* @description  Class to handle system global settings
*/
public class PorcelanosaSetting {

    public String key {get; private set;}
    public String subkey {get; private set;}
    public String value1 {get; private set;}
    public String value2 {get; private set;}
    public String value3 {get; private set;}
    public String value4 {get; private set;}
    public String description {get; private set;}
    public Boolean isActive {get; private set;}

    public  PorcelanosaSetting(String key, String subkey) {
        PorcelanosaSetting__c[] settings = [select key__c, subkey__c, value1__c, value2__c, value3__c, value4__c, Description__c, isActive__c from PorcelanosaSetting__c where key__c = :key and subkey__c = :subkey];
        if (settings.size() == 0) {
            throw new ObjectNotFoundException('Setting with key "' + key + '" and subkey "' + subkey + '" does not exist');
        }
        this.key = settings[0].key__c;
        this.subkey = settings[0].subkey__c;
        this.value1 = settings[0].value1__c;
        this.value2 = settings[0].value2__c;
        this.value3 = settings[0].value3__c;
        this.value4 = settings[0].value4__c;
        this.description = settings[0].description__c;
        this.isActive = settings[0].isActive__c;
    }
}