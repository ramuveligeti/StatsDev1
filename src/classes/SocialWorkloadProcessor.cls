public class SocialWorkloadProcessor implements Queueable {
	public void execute(QueueableContext context) {
        Id socialCollectionRT = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
    	Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];

        Date sevenDaysAgo = Date.today().addDays(-7);

        AggregateResult[] results = [select Workload__c, COUNT(Id) from Work_Item__c where 
        												Response__r.Wave_End_Date__c!=null and
        												Response__r.Wave_End_Date__c<:sevenDaysAgo and
        												Workload__r.Collection_Instance__r.Collection__r.RecordTYpeId=:socialCollectionRT and
        												Workload__r.OwnerId!=:completedQueue.Id and
        												Workload__r.Workload_Status__c='Complete'
								GROUP BY Workload__c];

		Set<Id> workloadIds = new Set<Id>();
		for(AggregateResult result:results){
			workloadIds.add(String.valueOf(result.get('Workload__c')));
		}
        
        if(!workloadIds.isEmpty()){
        	List<Workload__c> socialWorkloads = [select OwnerId from Workload__c where Id in :workloadIds];
        	for(Workload__c workload:socialWorkloads){
	        	workload.OwnerId = completedQueue.Id;
	        }
	        update socialWorkloads;
        }
	}
}