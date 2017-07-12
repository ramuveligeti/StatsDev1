//ECP-767
global class PrioritizeWorkItemsBatch implements Database.Batchable<SObject> {
	global String queryString;
	global PrioritizeWorkItemsBatch(String query) {
		queryString = query;
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(queryString);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<Response__c> scope) {
		Date startOfWeek = Date.today().toStartOfWeek();
		Date startOfPreviousWeek = startOfWeek.addDays(-7);
		Date startOfWeekBefore = startOfPreviousWeek.addDays(-7);
		for(Response__c rs:scope){
			if(rs.Wave_Start_Date__c == startOfWeek){
				rs.Overall_Priority_Factor__c = 999;
				rs.Overall_Priority_Override__c = true;
			}else if(rs.Wave_Start_Date__c == startOfPreviousWeek){
				rs.Overall_Priority_Factor__c = 9999;
				rs.Overall_Priority_Override__c = true;
			}else if(rs.Wave_Start_Date__c == startOfWeekBefore){
				rs.Overall_Priority_Factor__c = 99999;
				rs.Overall_Priority_Override__c = true;
			}
		}
		update scope;
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
	}
}