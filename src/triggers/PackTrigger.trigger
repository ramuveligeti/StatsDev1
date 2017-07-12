trigger PackTrigger on Pack__c (before update) {
    if(trigger.isBefore && trigger.isUpdate){
        PackTriggerHandler.validatePackContentsDeliveryModes(trigger.newMap, trigger.oldMap);
    }
}