//@author: Ram Veligeti
//@description: This batch class is called from DeleteActivitySchedule to delete Work Items for an Activity Schedule
//@test class: DeleteActivityScheduleTest
//@date: 15/01/2016

global class DeleteActivityScheduleWIBatch implements Database.Batchable<sObject>, Database.Stateful{
	global String query;
    global Activity_Schedule__c actSch;
	
	@testVisible
	private Boolean unitTestForceFail = false;
	
	global DeleteActivityScheduleWIBatch(Activity_Schedule__c actSch) {
		this.actSch = actSch;
		query = 'select Id from Work_Item__c where Activity_Schedule__c = \''+actSch.Id+'\'';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Work_Item__c> scope) {
		delete scope;
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
			mail.setSubject('DeleteWorkItemsBatch Status: ' + asyncApexJob.Status);  
			mail.setPlainTextBody('The batch Apex job failed with '+ asyncApexJob.NumberOfErrors 
				+ ' failures. ExtendedStatus: ' + asyncApexJob.ExtendedStatus);  

			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}else if('Completed'.equals(asyncApexJob.Status)){
			DeleteActivityScheduleASFBatch asfBatch = new DeleteActivityScheduleASFBatch(actSch);
			BatchScheduler caseBatchScheduler = new BatchScheduler(asfBatch);
			caseBatchScheduler.runBatchable();
		}
	}
}