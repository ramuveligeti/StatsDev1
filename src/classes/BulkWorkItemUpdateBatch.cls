/*
* 08/12/2016		Steven Zhu	    ECP-3606 and 3730 Added validation rule bypass
 */
global class BulkWorkItemUpdateBatch implements Database.Batchable<sObject>, Database.stateful{
    global final String query;
    global String newStatus;
    global Id newOwner;
    global Integer priorityFactor;
	global Datetime callBackTime;
	global Boolean priorityOverride;
    global Set<Id> workloads;
    
    global BulkWorkItemUpdateBatch(String soql, String status, Id ownerId) {
        this(soql, status, ownerId, null);
    }

	global BulkWorkItemUpdateBatch(String soql,Set<Id> workloadsToUpdate) {
		workloads = workloadsToUpdate;
		query = soql; 
	}

	global BulkWorkItemUpdateBatch(String soql, String status, Id ownerId, Integer priorityFactor, Datetime inputCallbackTime) {
        this.query=soql;
        this.newStatus=status;
        this.newOwner=ownerId;
		this.priorityFactor = priorityFactor;
        this.callBackTime = inputCallbackTime;
    }

	global BulkWorkItemUpdateBatch(String soql, String status, Id ownerId, Datetime inputCallbackTime) {
        this.query=soql;
        this.newStatus=status;
        this.newOwner=ownerId;
        this.callBackTime = inputCallbackTime;
    }


	 global BulkWorkItemUpdateBatch(String soql, String status, Id ownerId, Integer priorityFactor, Boolean inputPriorityOverride, Datetime inputCallbackTime ) {
        this.query=soql;
        this.newStatus=status;
        this.newOwner=ownerId;
        this.priorityFactor = priorityFactor;
		this.callBackTime = inputCallbackTime;
		this.priorityOverride = inputPriorityOverride;
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);    
    }

    global void execute(Database.BatchableContext BC,Work_Item__c[]workItems) {
    	boolean updateStatus=!String.isBlank(newStatus);
    	boolean updateOwner=!String.isBlank(newOwner);
        boolean updateWorkItemOwner = !workloads.isEmpty();
		boolean updateCallBackTime = false;
		if(callBackTime != null){updateCallBackTime = true;}

    	Set<Id> responseIds = new Set<Id>();
        System.debug('number of work items to update: ' + workItems.size());
        for(Work_Item__c w:workItems){
    		if(updateStatus)
			{
				if(newStatus == 'Closed')
				{
					if(w.status__c != 'Completed') w.status__c=newStatus;
				}else
				{
					w.status__c=newStatus;
				}
			}
    		if(updateOwner){w.ownerid=newowner;}
            if(updateWorkItemOwner && w.OwnerId != w.WorkLoad__r.OwnerId){
                w.OwnerId = w.WorkLoad__r.OwnerId;
            }
			if(updateCallBackTime){w.call_back_time__c=callBackTime;}
            if(priorityFactor!=null && !String.isBlank(w.Response__c)){
                responseIds.add(w.Response__c);
            }
    	}
        if(updateStatus || updateOwner || updateWorkItemOwner){
            update workItems;
        }

        if(!responseIds.isEmpty()){
			// put in the override control to by-pass validation rules
			System_Update__c su = System_Update__c.getOrgDefaults();
	        su.Execute__c = true;
	        update su;
            List<Response__c> responses = [select Overall_Priority_Factor__c, Overall_Priority_Override__c from Response__c where Id in :responseIds and Overall_Priority_Factor__c != :priorityFactor];
            for(Response__c r:responses){
                r.Overall_Priority_Factor__c = priorityFactor;
				if(priorityOverride != null){r.Overall_Priority_Override__c = priorityOverride;}
				
            }
            update responses;
			// reset the by-pass
	        su.Execute__c = false;
	        update su;
        }

    }

    global void finish(Database.BatchableContext BC) {
    	// do nothing
    }

}