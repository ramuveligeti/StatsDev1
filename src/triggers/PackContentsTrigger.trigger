trigger PackContentsTrigger on Pack_Contents__c (before insert, before update) {
    if(Trigger.isBefore && Trigger.isInsert){
        PackContentsTriggerHandler.validateDeliveryModeOfPackContents(trigger.new,new Map<Id,Pack_Contents__c>());
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        PackContentsTriggerHandler.validateDeliveryModeOfPackContents(trigger.new,trigger.oldMap);
    }
}