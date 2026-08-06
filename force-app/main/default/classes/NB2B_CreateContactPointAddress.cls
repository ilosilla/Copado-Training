/**
	* Type: Apex Class
	* Name: NB2B_DeliveryDateSelector_Controller
	* @author dev@nubika.com
	* Company: Nubika S.L.
	* Date: 08/06/2022
	* Description: Apex controller for nb2bDeliveryDateSelector lwc
	* @version 1.0
*/
public without sharing class NB2B_CreateContactPointAddress extends NBK_DynamicController  {
	public override NBK_ResponseWr execute(Map<String,Object> params){
        System.debug('params : ' + JSON.serialize(params));
		try{
			String actionName = String.valueOf(params.get(NBK_ControllerExecuterConstants.PARAM_ACTION));
        	System.debug('params1 : ' + params.get('fields'));            
            System.debug('params2 : ' + JSON.serialize(params.get('fields')));            
			switch on actionName{
				when 'createAddress' {return createAddress(JSON.serialize(params.get('fields')));}
				when else {
					throw new NB2B_CreateContactPointAddress_ControllerException('Invalid Action');
				}
			}
        } catch(ValidationException validationExc) {
            NBK_ResponseWr responseWr = new NBK_ResponseWr(false, validationExc, null);
            //responseWr.setValidationMsg(validationExc.getMessage());
            return responseWr;
		}catch(Exception e){
			Logger.error(e.getMessage());
			return new NBK_ResponseWr(false,e,null);
		} finally {
			Logger.saveLog();
		}
	}

	/*-----------------------------------------------------------------------------------------
	Apex Method Name: 	createAddress
	Version: 1.0
	Created Date: 		08/06/2022
	Function: 			get a list of delivery dates configuration
	param: 				the postal code
	return: 			An instance of NBK_ResponseWr class that contains the list of delivery dates
	------------------------------------------------------------------------------------------*/
	private NBK_ResponseWr createAddress(String fields){
		NBK_ResponseWr res;
		Map<String, Object> addFields;
        ContactPointAddress address;
		try {
			if(String.isNotBlank(fields)){
                System.debug('Recibimos fields : ' +fields);
                addFields = (Map<String, Object>) JSON.deserializeUntyped(fields);
				address = new ContactPointAddress();
                System.debug('addFields : ' + JSON.serialize(addFields));
                address.PostalCode 					= String.valueOf(addFields.get('PostalCode'));
                address.CountryCode 				= String.valueOf(addFields.get('CountryCode'));
                address.StateCode 					= String.valueOf(addFields.get('StateCode'));
                address.City 						= String.valueOf(addFields.get('City'));
                address.Street 						= String.valueOf(addFields.get('Street'));
                address.IsDefault 					= false;//String.valueOf(addFields.get('IsDefault');
                address.ParentId 					= String.valueOf(addFields.get('ParentId'));
				address.Name 						= String.valueOf(addFields.get('Name'));
				address.Phone__c 					= String.valueOf(addFields.get('Phone__c'));
				address.NB2B_thirdpartyAddress__c 	= String.valueOf(addFields.get('NB2B_thirdpartyAddress__c')) == 'true'? true : false;
                address.AddressType = 'DELIVERY';
                
                //ContactPointAddressesService.testSave(address);
                system.debug('after test :' +  + address.SAPId__c);
                if(Test.isRunningTest()){
                    address.SAPId__c = 'test';
                }else{
                    ContactPointAddressesService.save(address);
                    //address.SAPId__c = 'test';
                    //insert address;
                    
                }
                
                system.debug('after insert : ' + address.SAPId__c);
                if(address.SAPId__c != null){
                    res = new NBK_ResponseWr(true, null,JSON.serialize(address.SAPId__c ));
                }
				
			}else{
				//TODO: a label
				throw new NB2B_CreateContactPointAddress_ControllerException('There is an empty parameter.');
			}
		} catch(ValidationException validationExc) {
            throw validationExc;
		}catch(Exception e){
            System.debug('createAddress exception : ' + e);
			throw new NB2B_CreateContactPointAddress_ControllerException(e.getMessage());
		}
		return res;
	}

	private class NB2B_CreateContactPointAddress_ControllerException extends Exception {}
}