global class TriggerFactory {
	
	private class TriggerHandlerException extends Exception {}

	/** 
	* Public static method to create and execute a trigger handler
	*/
	global static void createHandler(Schema.sObjectType soType)
	{
		ITrigger handler = getHandler(soType);
		
		if (handler == null)	throw new TriggerHandlerException('No Trigger Handler registered for Object Type: ' + soType);
		
		execute(handler);
	}

	/** 
	*  Method to control the execution of the handler
	*/
	private static void execute(ITrigger handler)
	{
		if(Trigger.isBefore)
		{
			handler.bulkBefore(trigger.new, trigger.oldMap);
			
			if		(Trigger.isInsert)		handler.beforeInsert(trigger.new);
			else if	(Trigger.isUpdate)		handler.beforeUpdate(trigger.new, trigger.oldMap);
			else if	(Trigger.isDelete)		handler.beforeDelete(trigger.oldMap);
		}
		else
		{
			handler.bulkAfter(trigger.new, trigger.oldMap);
			
			if 		(Trigger.isInsert)		handler.afterInsert(trigger.new);
			else if (Trigger.isUpdate)		handler.afterUpdate(trigger.new, trigger.oldMap);
			else if (Trigger.isDelete)		handler.afterDelete(trigger.oldMap);
		}

		handler.andFinally();
	}

	/** 
	*  Method to get the appropriate handler for the object type. Modify this method to add any additional handlers.
	*/
	private static ITrigger getHandler(Schema.sObjectType soType)
	{
		//  if 		(soType == Case.sObjectType)					return new CaseHandler();
		//  else if	(soType == Shipment_Address__c.sObjectType)		return new ShipmentAddressHandler();
		//  else if	(soType == Product_Case__c.sObjectType)			return new ProductCaseHandler();
		//  else if	(soType == EmailMessage.sObjectType)			return new EmailMessageHandler();
		//  else if	(soType == Task.sObjectType)					return new ActivityHandler();
		//  else if	(soType == Event.sObjectType)					return new ActivityHandler();
		//  else														return null;
		return null;
	}
}