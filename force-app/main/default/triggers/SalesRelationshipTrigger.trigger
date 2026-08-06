trigger SalesRelationshipTrigger on Sales_Relationship__c (before insert, before update, before delete, after insert, after update, after delete) {
      TriggerDispatcher.run(new SalesRelationshipTriggerHandler());
  }