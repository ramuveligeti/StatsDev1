trigger WorkloadTrigger on Workload__c (before update, after update) {
	
	if(Trigger.isBefore && TRigger.isUpdate){
        WorkloadTriggerHandler.processCensusWorkloadCompletion(Trigger.newMap, Trigger.oldMap);
	}

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            WorkloadTriggerHandler.updateWorkItemsOwnership(Trigger.newMap, Trigger.oldMap);
        }
    }
}