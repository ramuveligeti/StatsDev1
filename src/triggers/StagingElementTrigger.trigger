trigger StagingElementTrigger on Staging_Element__c (before insert, after insert) {
	
	Map<Id, Staging_Element__c> elements_processImmediately = StagingElementTriggerHandler.findElementsToProcessImmediately(Trigger.new);
	List<Staging_Element__c> elements_processLater = new List<Staging_Element__c>();

	if(elements_processImmediately.size()<Trigger.new.size()){
		elements_processLater = StagingElementTriggerHandler.findElementsToProcessLater(Trigger.new);
	}

	if(Trigger.isBefore && Trigger.isInsert) {
		StagingElementTriggerHandler.assignFieldValues(Trigger.new);

		//validate workitem type
		for(Staging_Element__c se:elements_processLater){
			if(!String.isBlank(se.WI_Work_Item_Type__c) && !WorkItemTriggerHandler.isWorkItemTypeValid(se.WI_Work_Item_Type__c)){
				se.WI_Work_Item_Type__c.addError('Invalid workitem type "'+se.WI_Work_Item_Type__c+'". Valid workitem types are: '+WorkItemTriggerHandler.getValidWorkitemTypesString());
			}
		}
	}else if (Trigger.isAfter && Trigger.isInsert) {
		StagingElementTriggerHandler.processStagingElements(elements_processImmediately);
	}
}