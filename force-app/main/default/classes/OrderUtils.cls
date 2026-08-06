/**
* @author 		Ramón Prades
* @date 		April 2021
* @group 		Orders
* @description 	Utility methods to create opportunities from Order (used to interface from SAP)
* @deprecated Abril 2022 No se utilizan los Orders para nada
*/
public class OrderUtils {}
// public class OrderUtils 
// {
    
//     public static Opportunity createEcommerceOpportunity(Order newOrder, String IdRecordTypeOpp) {
//         //Already exist opportunity linked to the SAP order?
//         Boolean alreadyExistOpp = OpportunityUtil.oppLinkedToSapOrder(newOrder.SAP_Id__c);
//         if (alreadyExistOpp) {
//             return new Opportunity();
//         }

//         String countryParent = '';
//         String addressParent = '';
//         String postcodeParent = '';
//         String cityParent = '';
//         String code = '';
//         String descriptionOpp = '';
//         Map<String,String> oppDesc = new Map<String,String>{};
//         Map<String,String> oppNames = new Map<String,String>{};
//         Boolean hasSapCode = true;
//         User newOppOwner = null;

//         if (newOrder.AccountId != null) {
//             Account acc = [Select Id,
//                                 ownerId,
//                                 Owner.LanguageLocaleKey,
//                                 RecordTypeId,
//                                 PersonMailingCountryCode,
//                                 PersonMailingStreet,
//                                 PersonMailingPostalCode,
//                                 PersonMailingCity,
//                                 BillingCountryCode,
//                                 BillingStreet,
//                                 BillingPostalCode,
//                                 BillingCity from Account where Id =: newOrder.AccountId ];
            
//             // Should we change the owner of the account?
//             if (acc.OwnerId == null || UserUtils.isGenericUser(acc.Owner)) {                
//                 newOppOwner = userUtils.getSalesOfficeRandomUser(newOrder.salesOffice__c);
//                 if (newOppOwner != null) {
//                     acc.OwnerId = newOppOwner.Id;
//                     update acc;
//                 }            
//             }

//             if (acc.RecordTypeId == [SELECT Id FROM RecordType WHERE DeveloperName = 'Private_Customer'].ID) {
//                 // It's a private Costumer. Address fields are on PersonMail
//                 countryParent = acc.PersonMailingCountryCode;
//                 addressParent = acc.PersonMailingStreet;
//                 postcodeParent = acc.PersonMailingPostalCode;
//                 cityParent = acc.PersonMailingCity;
//             } else {
//                 countryParent = acc.BillingCountryCode;
//                 addressParent = acc.BillingStreet;
//                 postcodeParent = acc.BillingPostalCode;
//                 cityParent = acc.BillingCity;
//             }
            
//             if (newOrder.SAP_Id__c == null) {
//                 code = newOrder.OrderNumber;
//                 hasSapCode = false;
//             } else {
//                 code = newOrder.SAP_Id__c;
//             }

//             //SET OPTIONS ON NAME AND DESC FOR MULTIPLE LANG
//             // list of locale https://developer.salesforce.com/forums/?id=906F00000008o2ZIAQ
//             oppNames.put('en_US', 'ECOMMERCE SAMPLES OPP. - ORDER #' + code);
//             oppNames.put('en_GB', 'ECOMMERCE SAMPLES OPP. - ORDER #' + code);
//             oppNames.put('fr', 'ECOMMERCE ÉCHANTILLON OPP. - ORDER #' + code);
//             oppNames.put('es', 'ECOMMERCE MUESTRAS OPP. - ORDER #' + code);

//             if (hasSapCode) {
//                 oppDesc.put('en_US', 'Automatic Opportunity created by a SAP Order (#' + code + ')');
//                 oppDesc.put('en_GB', 'Automatic Opportunity created by a SAP Order (#' + code + ')');
//                 oppDesc.put('fr', 'Opportunité automatique créée par une commande SAP (#' + code + ')');
//                 oppDesc.put('es', 'Oportunidad automática creada por un pedido SAP (#' + code + ')');
//             } else {
//                 oppDesc.put('en_US', 'Automatic Opportunity created by an Order (#' + code + ')');
//                 oppDesc.put('en_GB', 'Automatic Opportunity created by an Order (#' + code + ')');
//                 oppDesc.put('fr', 'Opportunité automatique créée par une commande (#' + code + ')');
//                 oppDesc.put('es', 'Oportunidad automática creada por un pedido (#' + code + ')');
//             }

//             // SET NAME AND DESCRIPTION, DEPENDING ON OWNER'S LANGUAGE
//             String newOppName = oppNames.get('en_GB');
//             String newOppDesc = oppDesc.get('en_GB');

//             if( oppNames.ContainsKey(acc.Owner.LanguageLocaleKey) ){
//                 newOppName = oppNames.get(acc.Owner.LanguageLocaleKey);
//             }
//             if( oppDesc.ContainsKey(acc.Owner.LanguageLocaleKey) ){
//                 newOppDesc = oppDesc.get(acc.Owner.LanguageLocaleKey);
//             }

//             // CREATE NEW OPPORTUNITY
//             return new Opportunity(
//                 Name = newOppName,
//                 CloseDate = newOrder.CreatedDate.date().addDays(7),
//                 StageName = 'Qualification',
//                 Product_Categories__c = 'Ceramics',
//                 Operation_Type__c = 'New construction',
//                 AccountId = newOrder.AccountId,
//                 countryCode__c = countryParent,
//                 OwnerId = acc.OwnerId,
//                 ecommerce__c = true,
//                 city__c = cityParent,
//                 Address__c = addressParent,
//                 Postcode__c = postcodeParent,
//                 Opportunity_Classification__c = 'Samples Ecommerce',
//                 RecordTypeId = IdRecordTypeOpp,
//                 Description = newOppDesc
//                 );
//         }

//         return new Opportunity();
//     }
// }