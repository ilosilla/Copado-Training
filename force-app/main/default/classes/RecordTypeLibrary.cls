/**
* @author 			Ramón Prades
* @date 			February 2021
* @group 			Tools
* @description 	    Class to store all record types id in a single place. Prefix variables with the object name (i.e. Lead_WebRequest)
*/
public class RecordTypeLibrary {
    public static final Id Lead_WebRequest          { get { return getRecordType('Lead', 'WebRequest');       } }
    public static final Id Lead_USWebRequest        { get { return getRecordType('Lead', 'USWebRequest');       } }
    public static final Id Opportunity_Retail       { get { return getRecordType('Opportunity', 'Project_retail');   } }
    public static final Id Opportunity_Ecommerce    { get { return getRecordType('Opportunity', 'Project_retail');   } }
    public static final Id Opportunity_Trade        { get { return getRecordType('Opportunity', 'Project_trade');   } }
    public static final Id Account_PrivateCustomer  { get { return getRecordType('Account', 'Private_Customer'); } }
    public static final Id Account_TradeCustomer    { get { return getRecordType('Account', 'Trade_and_Specificators'); } }
    public static final Id Account_ResellerCustomer { get { return getRecordType('Account', 'Third_party_Retailer_Reseller'); } }    
    public static final Id Case_SAPInvoice          { get { return getRecordType('Case', 'SAPInvoiceCase'); } } 
    public static final Id Order_StandardOrder      { get { return getRecordType('Order', 'StandardOrder'); } }   
    public static final Id Case_SAPClaim            { get { return getRecordType('Case', 'SAPClaimsCase'); }}  
    public static final Id Order_StandardV1         { get { return getRecordType('Order', 'StandardOrder_V1'); }}  
    public static final Id Case_ItCase              { get { return getRecordType('Case', 'ITCase'); } }
    
    private static Id getRecordType(String obj, String name) {
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (gd.containsKey(obj)) {
            Schema.SObjectType sobjType = gd.get(obj);
            Map<String, Schema.RecordTypeInfo> recordTypes = sobjType.getDescribe().getRecordTypeInfosByDeveloperName();
            if (recordTypes.containsKey(name)) {
                return recordTypes.get(name).getRecordTypeId();
            }
        }

        return null;
    }

    /**
     * Obtiene los recordtypes disponibles para el perfil del usuario actual y
     * para el objeto pasado por parámetro
     * 
     * @author mario.navarro@seidor.com
     * @date fecha 15/12/2023
     * @param objectName nombre del objeto del que obtener los recordtypes disponibles
     * @return mapa cuya key es el identificador del recordtype y value es el nombre del recordtype
     */
    public static Map<Id, String> getProfileAvailableRecordtypes(String objectName) {
        Map<Id, String> availableRecordtypes = new Map<Id, String>();
        Schema.SObjectType objEntity = Schema.getGlobalDescribe().get(objectName);
        if (objEntity != null) {
            for(RecordTypeInfo info: objEntity.getDescribe().getRecordTypeInfos()) {
                if(info.isAvailable()) {
                    availableRecordtypes.put(info.getRecordTypeId(), info.getName());
                }
            }
        }

        return availableRecordtypes;
    }

    /**
     * Obtiene los recordtypes disponibles para el perfil del usuario actual y
     * para el objeto pasado por parámetro
     * 
     * @author mario.navarro@seidor.com
     * @date fecha 15/12/2023
     * @param objectName nombre del objeto del que obtener los recordtypes disponibles
     * @return lista de recordtypes disponible para el perfil del usuario
     */
    @AuraEnabled(cacheable=true)
    public static List<Recordtype> getAvailableRecordtypesList(String objectName) {
        List<Recordtype> typeList = [SELECT Id, Name, Description, IsPersonType
                                        FROM Recordtype 
                                        WHERE SobjectType = :objectName
                                        AND IsActive = true];
        
        Map<Id, String> profileAvailableRt = getProfileAvailableRecordtypes(objectName);
        List<Recordtype> availableList = new List<RecordType>();
        for (Recordtype rt : typeList) {
            if (profileAvailableRt.containsKey(rt.Id)) {
                availableList.add(rt);
            }
        }

        return availableList;
    }

} // class