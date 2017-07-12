//Description: To prioritize work items based on wave for Social
//ECP-767
global class PrioritizeWorkItemsScheduler implements Schedulable {
    global void execute(SchedulableContext sc){
		Date startOfWeek = Date.today().toStartOfWeek();
        Date endOfWeek = startOfWeek.addDays(6);
		String query = 'Select Id from Response__c where Wave_Start_Date__c = '+startOfWeek+' and Collection_Code__c = \'HLFS\' and Response_Summary_Status__c <> \'Completed\' and Status__c <> \'Suppressed\' order by Wave_Start_Date__c';
		PrioritizeWorkItemsBatch pb = new PrioritizeWorkItemsBatch(query);
		Database.executebatch(pb,1000);
    }
}