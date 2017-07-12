trigger TaskTrigger on Task (after insert,before insert,before update,after update) {
    TaskTriggerHandler handler = new TaskTriggerHandler();
    
    if(Trigger.isBefore && Trigger.isInsert){
        handler.associate_Response_Unit_Contact(Trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        handler.beforeUpdate_feedbackEscalationOutcome(Trigger.new,Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        CSRActionRecorder.endCalling(Trigger.new);
        // logic moved to Processbuilder
        //handler.calculateWorkflowStatus(Trigger.new);
        handler.updateWINotes(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        handler.updateWINotes(Trigger.new);
    }
    
}