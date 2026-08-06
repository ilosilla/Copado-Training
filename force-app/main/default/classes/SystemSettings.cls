/**
 * Author           Ramón prades
 * Description      Retrieves system settings (stored in custom setting SystemSettings__c)
 * Date             May 2020
 * History              
 */
public with sharing class SystemSettings {

    // Public properties
    public static Boolean CPNotificationsEnabled { get; set; }
    public static Boolean USNotifyWebLeads { get; set; }
    public static String USClaimsManager { get; set; }
    public static Integer CPDeletionTime { get; set; }
    public static String adminProfiles { get; set; }
    public static String genericUsers { get; set; }    
    public static String DummyProduct { get; set; }    
    public static String materialBankPricebook { get; set; }    
    public static String USDefaultOwner { get; set; }    
    public static Boolean SAPConnectionDown { get; set; }
    public static String USFacadeManagerMail {get; set;}    
    public static String USAppointmentSubtype {get; set;}    
    public static String SAPCPIUrl {get; set;}    
    public static String SAPAPIUrl {get; set;}    
    public static String SAPCPIInstance {get; set;}    
    public static String SAPCPIAPIKey {get; set;}
    public static String AIModel {get; set;}
    public static Boolean SAPDispatcherEnabled {get; set;}

    private static SystemSettings__c systemSettings = null;
    
    /**
     * Class constructor
     */
    static {
        getSystemSettings();
        CPNotificationsEnabled = systemSettings.CPNotificationsEnabled__c;
        CPDeletionTime = (Integer) systemSettings.CPDeletionTime__c;
        USClaimsManager = systemSettings.USClaimsManager__c;
        adminProfiles = systemSettings.AdminProfiles__c;
        genericUsers = systemSettings.GenericUsers__c;
        dummyProduct = systemSettings.DummyProduct__c;
        USNotifyWebLeads = systemSettings.USNotifyWebLeads__c;
        materialBankPricebook = systemSettings.MaterialBankPricebook__c;
        USDefaultOwner = systemSettings.DefaultUSAMethodOwner__c;
        SAPConnectionDown = systemSettings.SapConnectionDown__c;
        USFacadeManagerMail = systemSettings.USFacadeManagerMail__c;
        USAppointmentSubtype = systemSettings.USAppointmentSubtype__c;
        SAPCPIUrl = systemSettings.SAPCPI__c;
        SAPAPIUrl = systemSettings.SAPAPI__c;
        SAPCPIInstance = systemSettings.SAPCPIInstance__c;
        SAPCPIAPIKey = systemSettings.SAPCPIAPIKey__c;
        AIModel = systemSettings.AIModel__c;
        SAPDispatcherEnabled = systemSettings.SAPDispatcherEnabled__c;
    }

    public static String dummyProducts {
        get {
            return getSystemSettings().DummyProduct__c;
        }
    }

    public static Boolean underDevelopment(String feature) {
        SystemSettings__c settings =  getSystemSettings();
        try {
            String devFeatures = settings.DevFeatures__c.toUpperCase();
            return (devFeatures.contains(feature.toUpperCase() + ';'));
        } catch (NullPointerException ex) {
            return false;
        }
    }

    public static Boolean sapConnectionDown() {
        return getSystemSettings().SapConnectionDown__c;
    }

    @testvisible
    private static SystemSettings__c getSystemSettings() {
		if (systemSettings == null) {
            systemSettings = SystemSettings__c.getOrgDefaults();
            if (systemSettings == null || systemSettings.AdminProfiles__c	== null) {
                setDefaultSettings();
            }
        } 
        return systemSettings;
    } // getSystemSettings

    @testvisible    
    private static void setDefaultSettings() {
        // By default sets Neoris configuration
        String value = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator LIMIT 1].Id;
        String valueGeneric = [SELECT Id FROM User WHERE Name LIKE '%API%' LIMIT 1].Id;
        systemSettings.AdminProfiles__c = value;		        
        systemSettings.GenericUsers__c = valueGeneric;
        systemSettings.SAPDispatcherEnabled__c = true;
        if (Test.isRunningTest()) {
            Pricebook2[] books = [select Id from Pricebook2];
            if (books.size() > 0) {
                systemSettings.materialBankPricebook__c = books[0].Id;
            }
            systemSettings.CPDeletionTime__c = 16;
            systemSettings.DummyProduct__c = '999999999';
        }        
        saveSystemSettings(systemSettings);
    } // setDefaultSettings

    @testVisible
    private static void saveSystemSettings(SystemSettings__c settings) {
        Database.insert(settings);
    } // saveSystemSettings

    
} // Class