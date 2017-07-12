global with sharing class RequestWorkItemExCon {

    @RemoteAction
    global static Work_Item__c requestWorkItem() {
        Id workItemId = (Id) WorkItemQueue.fetchWorkItem();
        Work_Item__c wi = new Work_Item__c();
        If (workItemId != null) {
        	CSRActionRecorder.requestWorkItem(workItemId, DateTime.now());
	        wi = [Select Id,Name from Work_Item__c where Id = :workItemId];
        }
        return wi;
    }


}