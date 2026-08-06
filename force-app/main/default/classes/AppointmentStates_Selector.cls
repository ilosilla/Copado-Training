/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 31-10-2023
 * @group        :
 * @see          :
**/
public with sharing class AppointmentStates_Selector {

	/**
	* @description
	* @author Nubika Team <example@nubika.com> | 31-10-2023
	* @param stateName
	* @param country
	* @return AppointmentStates__mdt
	**/
	public static AppointmentStates__mdt getState(String stateName, String country){
		List<AppointmentStates__mdt> statesCountry  = new List<AppointmentStates__mdt>();

		List<AppointmentStates__mdt> statesAux1 = [SELECT  Label, StateName__c, StateCode__c, CountryName__c, CountryCode__c
																										FROM AppointmentStates__mdt
																												WHERE CountryCode__c =: country];
		if(statesAux1 != null && !statesAux1.isEmpty()){
			for(AppointmentStates__mdt mdt : statesAux1){
				statesCountry.add(mdt);
			}
		}

		List<AppointmentStates__mdt> statesAux2 = [SELECT  Label, StateName__c, StateCode__c, CountryName__c, CountryCode__c
																											FROM AppointmentStates__mdt
																													WHERE CountryName__c =: country];
		if(statesAux2 != null && !statesAux2.isEmpty()){
			for(AppointmentStates__mdt mdt : statesAux2){
				statesCountry.add(mdt);
			}
		}
		if(statesCountry != null && !statesCountry.isEmpty()){
			for(AppointmentStates__mdt mdt : statesCountry){
				if(mdt.StateName__c == stateName || mdt.StateCode__c == stateName){return mdt;}
			}
		}
		return null;
	}
}