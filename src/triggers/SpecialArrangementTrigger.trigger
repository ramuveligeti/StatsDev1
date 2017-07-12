trigger SpecialArrangementTrigger on Special_Arrangement__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    SpecialArrangementTriggerHandler handler = new SpecialArrangementTriggerHandler();
    
    /* Before Insert 
    if(Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeInsert(Trigger.new);
    } */ 
    // After Insert 
    if(Trigger.isInsert && Trigger.isAfter){    
        handler.onAfterInsert(Trigger.new); 
    } 
    /* Before Update 
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap);
    } 
    // After Update 
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.newMap);
    } 
    /* Before Delete  
    if(Trigger.isDelete && Trigger.isBefore){
        handler.onBeforeDelete(Trigger.old, Trigger.oldMap);
    } 
    /* After Delete 
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.onAfterDelete(Trigger.old, Trigger.oldMap);
    }
    /* After Undelete 
    else if(Trigger.isUnDelete){
        handler.onUndelete(Trigger.new);
    } */
}