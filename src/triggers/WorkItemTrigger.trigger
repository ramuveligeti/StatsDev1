trigger WorkItemTrigger on Work_Item__c (after insert,after update,before insert,before update) {
	//if this flag is set to false do not run trigger
	if(!StagingElementUtils.runCalculations){
		return;
	}
	

	if(Trigger.isAfter){
		if(Trigger.isUpdate){
			//After Update event handler
			WorkItemTriggerHandler.AfterUpdateHandler(Trigger.newMap,Trigger.oldMap); 
		}
		
		if(Trigger.isInsert){
			//After Insert event handler
			WorkItemTriggerHandler.AfterInsertHandler(Trigger.newMap,new Map<Id,Work_Item__c>());
		}
	}
	
	if(Trigger.isBefore){
		if(Trigger.isInsert){
			//before insert handler			
			WorkItemTriggerHandler.BeforeInsertHandler(Trigger.new, new Map<Id, Work_Item__c>());
			
		}
		
		if(Trigger.isUpdate){
			WorkItemTriggerHandler.BeforeUpdateHandler(Trigger.newMap, Trigger.oldMap);
		}
	}


}