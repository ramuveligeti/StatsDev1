/**
* @description This is called for Response Rate Trigger. 
* @author Ram Veligeti
* @date 09.Sep.2015
*/
public class ResponseRateTriggerHandler {
    //If the current response rate is Active then make all other response rates to Inactive
    public static void checkExistingActiveResponseRates(List<Response_Rate__c> newResponseRates){
        Set<Id> collectionIds = new Set<Id>();
        Set<Id> newResponseRateId = new Set<Id>();
        for(Response_Rate__c rr: newResponseRates){
            if(rr.Active__c){
                collectionIds.add(rr.Collection__c);
                newResponseRateId.add(rr.Id);
            }
        }
        
        if(!collectionIds.isEmpty()){
            List<Response_Rate__c> existingResponseRates = [Select Id, Active__c from Response_Rate__c where Collection__c in :collectionIds and Active__c = true and Id not in :newResponseRateId];
            if(!existingResponseRates.isEmpty()){
                for(Response_Rate__c er: existingResponseRates){
                    er.Active__c = false;
                }
                
                update existingResponseRates;
            }
        }
    }
}