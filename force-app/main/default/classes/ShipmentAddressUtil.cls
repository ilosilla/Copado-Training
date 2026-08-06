/** 
* Help method for CaseUtil 
* @author dguzman (nts) 
* @date 03/05/2018
*/
/**
* @service Hecho por NTS
*/
public class ShipmentAddressUtil {}
// public class ShipmentAddressUtil {
	


// 	/** 
// 	* @author gmiranda (nts) 
// 	* @date 03/05/2018
// 	* @description When a shipment address is marked as primary in creation or update, the related contact shipment address standard field should be updated to the new primary shipment address.
// 	*/
// 	public static void updatePrimaryShipmentAddress(list<Shipment_Address__c> newList, map<Id,Shipment_Address__c> oldMap)
// 	{
// 		system.debug('init updatePrimaryShipmentAddress');
// 		List<Shipment_Address__c> scopeAddresses = new List<Shipment_Address__c>();
// 		Map<Id,Contact> contacts;
// 		Set<Id> contactIds = new Set<Id>();
// 		List<Shipment_Address__c> shipmentAddressesToUpdate = new List<Shipment_Address__c>();
		
// 		for(Shipment_Address__c scopeAddress:newList)
// 		{
// 			if(scopeAddress.isPrimary__c && (oldMap == null || scopeAddress.isPrimary__c != oldMap.get(scopeAddress.Id).isPrimary__c))
// 			{
// 				scopeAddresses.add(scopeAddress);
// 				contactIds.add(scopeAddress.Contact__c);

// 			}
// 		}

// 		if(!scopeAddresses.isEmpty())
// 		{
// 			contacts =  new Map<Id,Contact>([SELECT Id,(SELECT Id FROM Shipment_Addresses__r) FROM Contact WHERE Id IN: contactIds]);
// 		}

// 		//Obtenemos los contactos asociados que deben actualizarse la dirección
// 		for(Shipment_Address__c scopeAddress:scopeAddresses)
// 		{
// 			if(contacts.containsKey(scopeAddress.contact__c))
// 			{
// 				Contact contact = contacts.get(scopeAddress.contact__c);
// 				if(String.isNotBlank(scopeAddress.City__c))
// 					contact.MailingCity = scopeAddress.City__c;

// 				if(String.isNotBlank(scopeAddress.State__c))					
// 					contact.MailingState = scopeAddress.State__c;

// 				if(String.isNotBlank(scopeAddress.Country__c))					
// 					contact.MailingCountry = scopeAddress.Country__c;

// 				if(String.isNotBlank(scopeAddress.Postal_Code__c))					
// 					contact.MailingPostalCode = scopeAddress.Postal_Code__c;

// 				if(String.isNotBlank(scopeAddress.Street__c))										
// 					contact.MailingStreet = scopeAddress.Street__c;


// 				//El resto de shipments addresses del contacto se ponen como false
// 				for(Shipment_Address__c direccion:contact.Shipment_Addresses__r)
// 				{
// 					if(direccion.ID != scopeAddress.Id)
// 					{
// 						direccion.isPrimary__c = false;
// 						shipmentAddressesToUpdate.add(direccion);	
// 					}
					
// 				}
// 			}
// 		}
// 		if(contacts != null && !contacts.isEmpty())		
// 			update contacts.values();			
			
// 		if(!shipmentAddressesToUpdate.isEmpty())
// 			update shipmentAddressesToUpdate;
			
// 	}
// }