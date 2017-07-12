public class WorkItemHouseholdSummaryViewExCon{
	public List<Response__c> personalQuestionnaires{get;set;}
	public WorkItemHouseholdSummaryViewExCon(ApexPages.StandardController stdCont){
		Work_Item__c wi = (Work_Item__c)stdCont.getRecord();
		String individualRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Individual').getRecordTypeId();
		personalQuestionnaires = [Select Id,Name,Contact__c,Contact__r.Name,Status__c,Response_Status_Reason__c from Response__c where Unit_of_Interest__c = :wi.Unit_Id__c and Wave__c = :wi.Response__r.Wave__c and RecordTypeId = :individualRecordTypeId];
	}
}