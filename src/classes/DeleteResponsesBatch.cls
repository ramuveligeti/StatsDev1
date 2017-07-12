global class DeleteResponsesBatch implements Database.Batchable<sObject> {
	
	global String query;
	global Collection_Instance__c collectionInstance;
	
	@testVisible
	private Boolean unitTestForceFail = false;
	@testVisible
	private Boolean unitTestForceCauseException = false;
	
	global DeleteResponsesBatch(Collection_Instance__c collectionInstance) {
		this.collectionInstance = collectionInstance;
		query = 'select Id from Response__c where Collection_Instance__c = \''+collectionInstance.Id+'\'';
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Response__c> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		// Get the AsyncApexJob that represents the Batch job using the Id from the BatchableContext  
		AsyncApexJob asyncApexJob = [Select Id, Status, NumberOfErrors, JobItemsProcessed,  
		 					TotalJobItems, CreatedBy.Email, ExtendedStatus  
		 					from AsyncApexJob where Id = :BC.getJobId()];
		
		if('Failed'.equals(asyncApexJob.Status) || unitTestForceFail){
			// Email the Batch Job's submitter that the Job has failed.  
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
			String[] toAddresses = new String[] {asyncApexJob.CreatedBy.Email};  
			mail.setToAddresses(toAddresses);  
			mail.setSubject('DeleteResponsesBatch Status: ' + asyncApexJob.Status);  
			mail.setPlainTextBody('The batch Apex job failed with '+ asyncApexJob.NumberOfErrors 
				+ ' failures. ExtendedStatus: ' + asyncApexJob.ExtendedStatus);  

			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}else if('Completed'.equals(asyncApexJob.Status)){
			try{
				if(unitTestForceCauseException){
					Decimal d = Decimal.valueOf('a');
				}
				String ciName = collectionInstance.Name;
				delete collectionInstance;
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
				String[] toAddresses = new String[] {asyncApexJob.CreatedBy.Email};  
				mail.setToAddresses(toAddresses);  
				mail.setSubject('Delete Collection instance data complete');  
				mail.setPlainTextBody('Collection instance '+ciName+' and all related data has been deleted');  

				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}catch(Exception e){  
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
				String[] toAddresses = new String[] {asyncApexJob.CreatedBy.Email};  
				mail.setToAddresses(toAddresses);  
				mail.setSubject('DeleteResponsesBatch Status: Failed to detete collection instatnce');  
				mail.setPlainTextBody('The batch Apex job failed with '+e);  

				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
		}
	}
	
}