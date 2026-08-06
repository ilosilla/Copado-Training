/**
	* Type: Apex Class
	* Name: NB2B_CreateContactPointAddressController
	* @author dev@nubika.com
	* Company: Nubika S.L.
	* Date: 12/05/2022
	* Description: Apex controller for nb2bCreateContactPointAddress lwc
	* @version 1.0
*/
public without sharing class NB2B_CreateContactPointAddressController extends NBK_DynamicController {
	public override NBK_ResponseWr execute(Map<String,Object> params){
		try{
			String actionName = String.valueOf(params.get(NBK_ControllerExecuterConstants.PARAM_ACTION));
			switch on actionName{
				when 'getStatePicklistValuesByCountryCode' {return getStatePicklistValuesByCountryCode();}
				when else {
					throw new NB2B_CreateContactPointAddressControllerException('Invalid Action');
				}
			}
		}catch(Exception e){
			Logger.error(e.getMessage());
			return new NBK_ResponseWr(false,e,null);
		} finally {
			Logger.saveLog();
		}
	}

	/*-----------------------------------------------------------------------------------------
	Apex Method Name: 	getStatePicklistValuesByCountryCode
	Version: 1.0
	Created Date: 		12/05/2022
	Function: 			get a map of country codes with their related states
	param: 				N/A
	return: 			An instance of NBK_ResponseWr class
	------------------------------------------------------------------------------------------*/
	private NBK_ResponseWr getStatePicklistValuesByCountryCode(){
		NBK_ResponseWr res;
		try {
			Map<String,List<Schema.PicklistEntry>> countryStatesPicklistValueMap = NB2B_Utils.getDependentPicklistValues('ContactPointAddress', 'StateCode', true);
			Map<String,List<Map<String,String>>> countryStatesMap = new Map<String,List<Map<String,String>>>();
			for(String key : countryStatesPicklistValueMap.keySet()){
				if(!countryStatesMap.containsKey(key)){
					countryStatesMap.put(key,new List<Map<String,String>>());
				}
				for(Schema.PicklistEntry entry : countryStatesPicklistValueMap.get(key)){
					countryStatesMap.get(key).add(new Map<String,String>{'label' => entry.getLabel(), 'value' => entry.getValue()});
				}
			}
			res = new NBK_ResponseWr(true,null,!countryStatesMap.isEmpty() ? JSON.serialize(countryStatesMap) : null);
		}catch(Exception e){
			throw new NB2B_CreateContactPointAddressControllerException(e.getMessage());
		}
		return res;
	}

	private class NB2B_CreateContactPointAddressControllerException extends Exception {}
}