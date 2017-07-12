global class DeleteFromStagingBatch implements Database.Batchable<sObject>, Database.Stateful{
	global final string qStr;
	global ID ciID;
	global String ciCode;
    global DeleteFromStagingBatch(Collection_Instance__c ci){
        ciID=ci.id;
        ciCode=ci.Collection_Instance_code__c;
        qStr='select id from Staging_Element__c where Failed__c = true and CI_Collection_Instance_Code__c=\''+ciCode+'\'';
    }
    //Start
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(qStr);
	}
	
    global void execute(Database.BatchableContext BC,Staging_Element__c[]scope){
    	delete scope;
    }
	global void finish(Database.BatchableContext BC){}
}