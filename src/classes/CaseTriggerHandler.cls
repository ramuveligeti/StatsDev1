public with sharing class CaseTriggerHandler {

	private static Map<String, Case_Update_Properties__c> caseUpdateProperties_private = null;
	private Map<String, Case_Update_Properties__c> getCaseUpdateProperties(){
		if(caseUpdateProperties_private == null){
			caseUpdateProperties_private = Case_Update_Properties__c.getAll();
		}
		return caseUpdateProperties_private;
	}

	private static Map<Id, Work_Item__c> notCompletedWorkItems_private;
	private Map<Id, Work_Item__c> findNotCompletedWorkItems(Set<Case> cases){
		if(notCompletedWorkItems_private == null){
			Set<Id> caseIds = new Set<Id>();
			for(Case cse:cases){
				caseIds.add(cse.Id);
			}

			String workItemStatusClosed = getCaseUpdateProperties().get('workitem.status.closed').Value__c;
			notCompletedWorkItems_private = new Map<Id, Work_Item__c>([select Id, Related_Case__c, Status__c from Work_Item__c where Related_Case__c in :caseIds and Status__c != :workItemStatusClosed]);
		}
		return notCompletedWorkItems_private;
	}

	// if the case was completed then set all its work items to completed
	public void completeWorkItemsForCompletedCases(Map<Id, Case> cases, Map<Id, Case> oldCases){
		String caseStatusClosed = getCaseUpdateProperties().get('case.status.closed').Value__c;
		String workItemStatusClosed = getCaseUpdateProperties().get('workitem.status.closed').Value__c;
		
		Set<Case> closedCases = new Set<Case>();
		for(Case cse:cases.values()){
			Case oldCase = oldCases.get(cse.Id);
			if(!String.isBlank(cse.Status) && cse.Status.equals(caseStatusClosed) && !cse.Status.equals(oldCase.Status)){
				closedCases.add(cse);
			}
		}

		if(!closedCases.isEmpty()){
			List<Work_Item__c> workItemsToUpdate = new List<Work_Item__c>();

			Map<Id, Work_Item__c> notCompletedWorkItems = findNotCompletedWorkItems(closedCases);
			System.debug('method notCompletedWorkItems = '+notCompletedWorkItems);
			for(Work_Item__c workItem:notCompletedWorkItems.values()){
				workItem.Status__c = workItemStatusClosed;
				workItemsToUpdate.add(workItem);
			}

			if(!workItemsToUpdate.isEmpty()){
				update workItemsToUpdate;
			}
		}
	}
}