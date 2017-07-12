trigger ActivityScheduleTrigger on Activity_Schedule__c (before update) {
    if(trigger.isBefore && trigger.isUpdate){
    	if(Logger.isEnabled()){
        	System.debug('ActivityScheduleTrigger before update ');
        }
        ActivityScheduleTriggerHandler.beforeUpdate_UpdateActivityScheduleFilter(trigger.newMap, trigger.oldMap);
    }
}