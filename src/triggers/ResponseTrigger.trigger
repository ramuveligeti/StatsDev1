trigger ResponseTrigger on Response__c (before insert, before update, after insert, after update, after delete, after undelete) {

	SystemSettings__c migration = SystemSettings__c.getInstance('migration.inprogress');
	boolean migrationInProgress = (migration!=null && String.isNotBlank(migration.value__c) && Boolean.valueOf(migration.value__c));

    if(trigger.isBefore && trigger.isInsert){
		//update contact
		//ResponseTriggerHandler.before_updateContact_updateUnitDeliveryMode(Trigger.new);
		//go and set the access-code, other-access-codes, and other-document-numbers if applicable
		//ResponseTriggerHandler.beforeInsert_pairDocIdAndAccessCode(Trigger.new);
		ResponseTriggerHandler.cleanUpDocumentAndAccessNumbers(Trigger.new);

        //Assign record type based on the target response type on collection instance
        ResponseTriggerHandler.assignRecordType(Trigger.new);
        //If reponse was created from another response copy fields to new response
        ResponseTriggerHandler.copyResponseFieldsFromOriginResponse(Trigger.new);
        
        // Check if unit is birthed, only if migration is not in progress
        if(!migrationInProgress){
        	UnitBirthQuery.MarkReponsesAsBirthed(Trigger.new);
        }
    }
		
    if(trigger.isBefore && trigger.isUpdate){
		//update contact
		//ResponseTriggerHandler.before_updateContact_updateUnitDeliveryMode(Trigger.new);
		//set status and previous-status on responses
		ResponseTriggerHandler.beforeUpdate_setResponseStatus(Trigger.oldMap, Trigger.NewMap);
		//go and set the access-code, other-access-codes, and other-document-numbers if applicable
		//ResponseTriggerHandler.beforeUpdate_pairDocIdAndAccessCode(Trigger.oldMap, Trigger.NewMap);
		ResponseTriggerHandler.cleanUpDocumentAndAccessNumbers(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert){
		//recalculate summary fields
		ResponseTriggerHandler.afterUpdateDwellingResponses(new Map<Id, Response__c>(),Trigger.newMap);
		// dac association
		//ResponseTriggerHandler.associateDAC(Trigger.new);
		ResponseTriggerHandler.updateDAC(Trigger.new);
		// do not trigger the workload reassignment, as this is an insert.  Workitem cannot exists after a response is created
	}

	if(Trigger.isAfter && Trigger.isUpdate){
		// When the response was completed then set status of all its work items to completed
		ResponseTriggerHandler.completeWorkItemsForCompletedResponses(Trigger.oldMap, Trigger.newMap);
		
		//recalculate summary fields
		ResponseTriggerHandler.afterUpdateDwellingResponses(Trigger.oldMap, Trigger.newMap);
		
		// reallocate workitem to updated workload
		//ResponseTriggerHandler.reallocateWorkItemstoWorkloads(Trigger.oldMap,Trigger.newMap);

		// dac association
		//ResponseTriggerHandler.associateDAC(Trigger.new);
		ResponseTriggerHandler.updateDAC(Trigger.new);

		ResponseTriggerHandler.completeWorkitemsForUnitStatus(Trigger.oldMap, Trigger.newMap);
	}

	if(Trigger.isAfter && Trigger.isDelete){
		//recalculate summary fields
		ResponseTriggerHandler.afterUpdateDwellingResponses(Trigger.oldMap, new Map<Id, Response__c>());
	}

	if(Trigger.isAfter && Trigger.isUndelete){
		//recalculate summary fields
		ResponseTriggerHandler.afterUpdateDwellingResponses(new Map<Id, Response__c>(), Trigger.newMap);
	}
}