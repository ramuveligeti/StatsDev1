/*
 * @description Developed for user story CAI-39 because mulesoft was unable to invoke Salesforce Restful APIs
 * If Mulesoft is ever able to successfully invoke Restful APIs then this trigger should be removed
 *
 * @author Anna Young
 * @date 11.11.2016
 * 
*/
trigger restMethodCallerTrigger on Rest_Method_Caller__c (before update) {
List<Rest_Method_Caller__c> restMethodCallers =trigger.new;
    restMethodCallerTriggerHandler handler = new restMethodCallerTriggerHandler();
     for (Rest_Method_Caller__c restMethodCaller: restMethodCallers )
    {
       handler.processUpdate(restMethodCaller);
    }
}