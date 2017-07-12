/*
* Batch apex to update Work Item Owner Id with Workload owner Id
*/
global class BulkWorkItemUpdateOwnerBatch implements Database.Batchable<sObject>, Database.stateful {
	
	global final String query;
	global Set<Id> workloads;

	//Constructor
	global BulkWorkItemUpdateOwnerBatch(String soql,Set<Id> workloadsToUpdate) {
		workloads = workloadsToUpdate;
		query = soql; 
	}
	
	//Start
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	//Execute
   	global void execute(Database.BatchableContext BC, List<Work_Item__c> scope) {
		for(Work_Item__c wi: scope){
			if(wi.OwnerId != wi.Workload__r.OwnerId){
				wi.OwnerId = wi.Workload__r.OwnerId;
			}
		}
		update scope;
	}
	
	//Finish
	global void finish(Database.BatchableContext BC) {
		//do nothing
	}
}