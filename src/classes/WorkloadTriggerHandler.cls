//updated this class for incident Incident 192372 Salesforce CPU problem - Karthik Gunasekaran - updated on 22/06/2017
public class WorkloadTriggerHandler {

    public static void updateWorkItemsOwnership(Map<Id, Workload__c> newMap, Map<Id, Workload__c> oldMap) {
      
       //updated below lines for incident Incident 192372 Salesforce CPU problem  
      Id workloadOwnerId=null;  
      Set<Id> workLoadIds = new Set<Id>();    
      //Set<Id>ids=new Set<Id>();
      //
        for (Workload__c workload:newMap.values()){
			// if the owner has changed, include this
			if(workload.OwnerId != oldMap.get(workload.Id).OwnerId){
                //updated below lines for incident Incident 192372 Salesforce CPU problem
                //ids.add(workload.Id);
                workLoadIds.add(workload.Id);
                //workloadOwnerId = workload.OwnerId ;
            }
        }
         //updated below line for Incident 192372 Salesforce CPU problem  
         if(workLoadIds.isEmpty()){return;}
        //Commented below lines for Incident 192372 Salesforce CPU problem  
        /*
		//if(ids.isEmpty()){return;}

        
        
		// go through the list of workitems (!completed) under the workload and reassign to new owner
		Work_Item__c[]wis=new Work_Item__c[]{};
        Id censusCollectionRecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];
        for(Workload__c wl:[select Id, Default_Address_Type__c, OwnerId,
				    (select Id, OwnerId, Workload__c from Work_Items__r 
                        where Workload__r.Collection_Instance__r.Collection__r.RecordTypeId=:censusCollectionRecordTypeId or OwnerId!=:completedQueue.Id
                    )
				from Workload__c where Id in:ids]){
            //Loop through Work Items to check OwnerId
            for(Work_Item__c i:wl.Work_Items__r){
                if(i.OwnerId!=newMap.get(wl.id).OwnerId){
                    i.OwnerId=newMap.get(wl.id).OwnerId;
                    wis.add(i);
                }
            }		  
        }
        if(wis.isEmpty()){return;}
       */
        //Update Work Items
    	try {
            //updated below line for Incident 192372 Salesforce CPU problem  
    		//update wis;	
            BulkWorkItemUpdate(workLoadIds);
    	} catch (DMLException ex) {
    		for (Workload__c workload:newMap.values()) {
    			workload.addError('An error occurred updating this workloads Units, the error was: ' + ex.getMessage());
    		}
    	}   
     }

    
    public static void processCensusWorkloadCompletion(Map<Id, Workload__c> newMap, Map<Id, Workload__c> oldMap){
        //find all census collection instances. we do not expect many
        Id censusCollectionInstanceRT = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
    	List<Collection_Instance__c> censusCollectionInstances = [
    		select Id 
    		from Collection_Instance__c 
    		where 
    			RecordTypeId = :censusCollectionInstanceRT
		];

		Set<Id> censusCollectionInstanceIds = new Set<Id>();
		for(Collection_Instance__c censusCollectionInstance:censusCollectionInstances){
			censusCollectionInstanceIds.add(censusCollectionInstance.Id);
		}

        Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];
        Set<Id> completedCensusWorkloadIds = new Set<Id>();
        for(Workload__c newWorkload:newMap.values()){
            if(censusCollectionInstanceIds.contains(newWorkload.Collection_Instance__c) && 'Complete'.equals(newWorkload.Workload_Status__c) && !'Complete'.equals(oldMap.get(newWorkload.Id).Workload_Status__c)){
                newWorkload.OwnerId = completedQueue.Id;
            }
        }
    }
    
    //Created below method for Incident 192372 Salesforce CPU problem  
    public static void BulkWorkItemUpdate(Set<Id> workLoadIds){
        Id censusCollectionRecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];
        //Update workitems using batch process
		String soql='SELECT Id,OwnerId,Workload__c,Workload__r.OwnerId FROM Work_Item__c WHERE Workload__c IN :workloads ';

            
		//String whereClause1 = genWhereClause('','Workload__c', workLoadIds);		
		//system.debug('whereClause1 work load ids: ' + whereClause1);

		//string whereClause2 = 'and OwnerId != \''+ workloadOwnerId+ '\' ';
		//system.debug('whereClause2 work load ids: ' + whereClause2);

		string whereClause = 'and (Workload__r.Collection_Instance__r.Collection__r.RecordTypeId = \''+ censusCollectionRecordTypeId+ '\'  or OwnerId != \''+ completedQueue.Id + '\' )';
		system.debug('whereClause2 work load ids: ' + whereClause);

        //soql+=whereClause1;
        //soql+=whereClause2;
        soql+=whereClause;

        system.debug('Work items query is : ' + soql);

        //Id batchId;
        BulkWorkItemUpdateBatch batch = new BulkWorkItemUpdateBatch(soql,workLoadIds);
        integer batchSize = SystemSettings.getIntegerValue('batchSize.workitemOwnerUpdate');
        Id batchId = Database.executeBatch(batch, batchSize);
    }
    
    //Created below method for Incident 192372 Salesforce CPU problem  
    /*/Added this for producing criteria with in () when selected multiple options
	private static String genWhereClause(String prefix, String field, List<Id> values){
        if(values == null) {
            return null;
        }
		
		string valueString = '';
		for(String s :values)
		{
			
			//if values contains empty string meaning none option selected, dont do anything in this case to avoid soql errors
			if(String.isBlank(s)){return null;}
		    if(valueString.length() > 0) valueString += ',';
			valueString +=  '\'' + s + '\'';
		}

        if(String.isBlank(valueString)){return null;}
        return prefix + field + ' in (' + valueString + ') ';
        
    }*/
}