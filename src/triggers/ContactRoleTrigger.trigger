trigger ContactRoleTrigger on Contact_Role__c (after insert, before update) {
	//After insert check if the Primary Contact already exist
    if(Trigger.isAfter && Trigger.isInsert){
	    ContactRoleTriggerHandler.checkPrimaryContactExist(trigger.newMap);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
		//After insert check if the Primary Contact already exist
        ContactRoleTriggerHandler.checkPrimaryContactExist(trigger.newMap);
        
	    //If status is Inactive then Primary contact is false
	    ContactRoleTriggerHandler.updatePrimaryContact(trigger.new, trigger.oldMap);
    }
}