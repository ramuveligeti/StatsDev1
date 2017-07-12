trigger CollectionMarkInRequestTrigger on Collection_Mark_In_Request__c (before insert, before update, after insert, after update) {
    CollectionMarkInRequestHandler handler=new CollectionMarkInRequestHandler();
    if(Trigger.isBefore){
    	handler.validateMarkInRequests(Trigger.New);
    }
    
    if(Trigger.isAfter){
    	handler.processMarkIns(Trigger.New);
    }
}