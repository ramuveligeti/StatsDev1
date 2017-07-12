trigger VariationResearchersRollup on Researcher__c(after delete, after insert, after update) {
  Set<id> variationIds = new Set<id>();
   
    if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate ){
    for (Researcher__c item : Trigger.new)
        variationIds.add(item.Project_Variation__c);
    }
    if(Trigger.isDelete){
        For(Researcher__c item : Trigger.old){
            variationIds.add(item.Project_Variation__c);
        }
    }
     List<Project_Variation__c> variationsToUpdate = new List<Project_Variation__c>();    
    
    // query the project variation and the related researchers and set number of researches included for this variation
    for (Project_Variation__c variation : [select Id, Number_of_Researchers_Included__c from Project_Variation__c where Id IN :variationIds]) {
        Integer totalResearchersAdded = [SELECT count() FROM Researcher__c where Project_Variation__c = :variation.Id];
        variation.Number_of_Researchers_Included__c = totalResearchersAdded;
        // add the variation object in to a list so we can update it
        variationsToUpdate.add(variation);
    }
    update variationsToUpdate;
}