trigger ContactTrigger on Contact (before insert, before update) {
    if(trigger.isBefore && trigger.isInsert){
        ContactTriggerHandler.beforeInsert_AssignAccount(trigger.new);
        PhoneValidationRules.ValidateContacts(trigger.new);
    }
    
    if (trigger.isBefore && trigger.isUpdate) {
        PhoneValidationRules.ValidateContacts(trigger.new);
    }
}