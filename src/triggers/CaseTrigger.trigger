trigger CaseTrigger on Case (after update) {

	if(Trigger.isAfter && Trigger.isUpdate){
		CaseTriggerHandler triggerHandler = new CaseTriggerHandler();

		triggerHandler.completeWorkItemsForCompletedCases(Trigger.newMap, Trigger.oldMap);
	}
}