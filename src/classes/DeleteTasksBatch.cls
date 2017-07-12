global class DeleteTasksBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	global String query;
	global Set<Id> workItemIds;
	global Collection_Instance__c collectionInstance;
	
	@testVisible
	private Boolean unitTestForceFail = false;
	
	global DeleteTasksBatch(Collection_Instance__c collectionInstance) {
		this.collectionInstance = collectionInstance;
		//task are associated with work items so we have to batch on work items 
		query = 'select Id from Work_Item__c where Collection_Instance__c = \''+collectionInstance.Id+'\'';
		System.debug('query = '+query);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('start(Database.BatchableContext BC) query = '+query);
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Work_Item__c> scope) {
		Set<Id> ids = new Set<Id>();
		for(Work_Item__c w :scope)
		{
			ids.add(w.Id);
		}
		List<Task> tasks = [select Id from Task where WhatId in :ids]; 
		
		System.debug('scope.size() = '+tasks.size());
		delete tasks;
	}
	
	global void finish(Database.BatchableContext BC) {
		// Get the AsyncApexJob that represents the Batch job using the Id from the BatchableContext  
		AsyncApexJob asyncApexJob = [Select Id, Status, NumberOfErrors, JobItemsProcessed,  
		 					TotalJobItems, CreatedBy.Email, ExtendedStatus  
		 					from AsyncApexJob where Id = :BC.getJobId()];
		
		if('Failed'.equals(asyncApexJob.Status) || unitTestForceFail){
			// Email the Batch Job's submitter that the Job is finished.  
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
			String[] toAddresses = new String[] {asyncApexJob.CreatedBy.Email};  
			mail.setToAddresses(toAddresses);  
			mail.setSubject('DeleteTasksBatch Status: ' + asyncApexJob.Status);  
			mail.setPlainTextBody('The batch Apex job failed with '+ asyncApexJob.NumberOfErrors 
				+ ' failures. ExtendedStatus: ' + asyncApexJob.ExtendedStatus);  

			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}else if('Completed'.equals(asyncApexJob.Status)){
			DeleteWorkloadsBatch workloadsBatch = new DeleteWorkloadsBatch(collectionInstance);
			BatchScheduler workloadsBatchScheduler = new BatchScheduler(workloadsBatch);
			workloadsBatchScheduler.runBatchable();
		}
	}
}