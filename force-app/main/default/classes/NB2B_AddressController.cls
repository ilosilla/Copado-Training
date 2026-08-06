public with sharing class NB2B_AddressController extends NBK_DynamicController  {
	public override NBK_ResponseWr execute(Map<String,Object> params){
		try{
			String actionName = String.valueOf(params.get(NBK_ControllerExecuterConstants.PARAM_ACTION));
			switch on actionName{
				when 'getAddresses' {return getAddresses(String.valueOf(params.get('webcartId')));}
				when 'getAddressPickup' {return getAddressPickup(String.valueOf(params.get('deliveryGroup')));}
				when else {
					throw new NB2B_AddressControllerException('Invalid Action');
				}
			}
		}catch(Exception e){
			Logger.error(e.getMessage());
			return new NBK_ResponseWr(false,e,null);
		} finally {
			Logger.saveLog();
		}
	}

	private NBK_ResponseWr getAddresses (String recordIdStr){
		NBK_ResponseWr res;
		try {
			List<WebCart> webCartAccount = NB2B_AccountSelector.getAccountForUserRoles(recordIdStr);
			String accountId = !webCartAccount.isEmpty() ? webCartAccount[0].AccountId : null;
			if(String.isNotBlank(accountId)){
				NB2B_AddressControllerWrapper auxRes = new NB2B_AddressControllerWrapper(accountId,NB2B_AccountSelector.selectPointAddressesByAccountId(accountId), NB2B_AccountSelector.getAccountShippingAddress(accountId));
				res = new NBK_ResponseWr(true,null,JSON.serialize(auxRes));
			}else{
				throw new NB2B_AddressControllerException('Cuenta no encontrada en SalesForce');
			}
		}catch(Exception e){
			throw new NB2B_AddressControllerException(e.getMessage());
		}
		return res;
	}

	private NBK_ResponseWr getAddressPickup (String deliveryGroup){
		NBK_ResponseWr res;
		List<PorcelanosaAddress__c> pickupListAddress = new List<PorcelanosaAddress__c>();
		try {
			if(String.isNotBlank(deliveryGroup)){
				System.debug('### deliveryGroup: '+deliveryGroup);
				Sales_Relationship__c thisSales = [Select id, Sales_Org__c from Sales_Relationship__c where id=:deliveryGroup limit 1];
				pickupListAddress = NB2B_AccountSelector.selectPointAddressesByDeliveryGroup(thisSales.Sales_Org__c);
				System.debug('### pickupListAddress: '+pickupListAddress);
				res = new NBK_ResponseWr(true,null,JSON.serialize(pickupListAddress));

			}else{
				throw new NB2B_AddressControllerException('DeliveryGroup no encontrado en SalesForce');
			}
		}catch(Exception e){
			throw new NB2B_AddressControllerException(e.getMessage());
		}
		return res;
	}

	public class NB2B_AddressControllerWrapper {
		private String accountId;
		private List<ContactPointAddress> addressList;
		private Address accountAddress;

		public NB2B_AddressControllerWrapper(String accountId, List<ContactPointAddress> addressList,Address accountAddress){
			this.accountId = accountId;
			this.addressList = addressList;
			this.accountAddress = accountAddress;
		}
	}

	private class NB2B_AddressControllerException extends Exception {}

}