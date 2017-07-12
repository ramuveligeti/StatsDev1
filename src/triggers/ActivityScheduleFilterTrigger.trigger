trigger ActivityScheduleFilterTrigger on Activity_Schedule_Filter__c (after update, before update) {
    
    if(trigger.isAfter && trigger.isUpdate){
        System.debug('AS filter trigger after update');
        //To Abort Scheduled jobs
        ActivityScheduleFilterTriggerHandler.afterUpdate_AbortScheduledJob(trigger.newMap,trigger.oldMap);
		//Only for Census - To send extracts to mulesoft if the immediate is true
		ActivityScheduleFilterTriggerHandler.executeMuleSoftClientForCensus(trigger.new,trigger.old);
    }
    
    if(trigger.isBefore && trigger.isUpdate){
        System.debug('AS filter trigger before update');
        ActivityScheduleFilterTriggerHandler.beforeUpdate_ModifyScheduleDatetime(trigger.newMap,trigger.oldMap);
    }
}