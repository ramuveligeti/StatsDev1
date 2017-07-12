trigger ResponseRateTrigger on Response_Rate__c (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        //Find existing active response rates and make them inactive 
        ResponseRateTriggerHandler.checkExistingActiveResponseRates(trigger.new);
    }
}