trigger MarkInRequestTrigger on Mark_In_Request__c (after insert, after update) {
	MarkInRequestTriggerHandler handler = MarkInRequestTriggerHandler.getInstance();
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            handler.processMarkInRequests(trigger.new);
        }
        
        if(Trigger.isUpdate){
            handler.processUpdate(trigger.oldMap,trigger.newMap);
        }
    }
}