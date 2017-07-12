trigger VariationDasetsRollup on Projects_Access__c(after delete, after insert, after update) {
    Set<id> variationIds = new Set<id>();
   
    if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate ){
    for (Projects_Access__c item : Trigger.new)
        variationIds.add(item.Project_Variation__c);
    }
    if(Trigger.isDelete){
        For(Projects_Access__c item : Trigger.old){
            variationIds.add(item.Project_Variation__c);
        }
    }
     List<Project_Variation__c> variationsToUpdate = new List<Project_Variation__c>();    
    
    // query the project variation and the related datasets and add the size of approved and approval required dataset
    for (Project_Variation__c variation : [select Id, Number_of_Approval_Required_Datasets__c, Number_of_Approved_Datasets__c from Project_Variation__c where Id IN :variationIds]) {
        Integer approvalRequired  = [SELECT count() FROM Projects_Access__c where Project_Variation__c = :variation.Id AND Approval_Required__c =: true];
        Integer totalApproved  = [SELECT count() FROM Projects_Access__c where Project_Variation__c = :variation.Id AND Is_Approved__c =: 'Yes'];
        Integer totalDataset = [SELECT count() FROM Projects_Access__c where Project_Variation__c = :variation.Id];
        variation.Number_of_Datasets_Requested__c = totalDataset;
        variation.Number_of_Approval_Required_Datasets__c = approvalRequired;
        variation.Number_of_Approved_Datasets__c = totalApproved;
        // add the variation object in to a list so we can update it
        variationsToUpdate.add(variation);
    }
    update variationsToUpdate;
}