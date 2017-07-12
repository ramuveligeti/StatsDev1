trigger UnitTrigger on Unit__c (before insert, after insert, after update) {
    if(Trigger.isBefore && Trigger.isInsert){
        UnitTriggerHandler.copyUnitFieldsFromOriginUnit(Trigger.new);
    }
}