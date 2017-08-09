@isTest
private class SocialWorkloadProcessorTest {
	
	@TestSetup
	public static void setupData(){
        insert new SystemSettings__c[]{
			new SystemSettings__c(Name = 'batchSize.workitemOwnerUpdate',Value__c = '200')
		};

        TestDataHelper.createResponseProperties();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        Id socialCollectionRT = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.RecordTypeId = socialCollectionRT;
        insert collection;
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Wave_Period__c = 'Weekly';
        collectionInstance.Interview_Start_Date__c = Date.today().addDays(-15);
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        
        Workload__c workload_1 = TestDataHelper.createWorkLoad(collectionInstance.Id, false);
        workload_1.Workload_Status__c = 'In Progress';
        workload_1.Workload_ID__c = 'w1';
        insert workload_1;
	   	
	   	Response__c response_1 = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);

        Work_Item__c workItem_1 = TestDataHelper.createWorkItem(null, null, null, response_1.Id, workLoad_1.Id, false);
        workItem_1.Mobile_Device_Id__c = 'm1';
        workItem_1.Work_Item_ExtId__c = 'e1';
        insert workItem_1;
        
        Workload__c workload_2 = TestDataHelper.createWorkLoad(collectionInstance.Id, false);
        workload_2.Workload_Status__c = 'Complete';
        workload_2.Workload_ID__c = 'w2';
        insert workload_2;
	   	
	   	Response__c response_2 = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, false);
	   	response_2.Wave__c = '1';
	   	insert response_2;

        Work_Item__c workItem_2 = TestDataHelper.createWorkItem(null, null, null, response_2.Id, workload_2.Id, false);
        workItem_2.Mobile_Device_Id__c = 'm2';
        workItem_2.Work_Item_ExtId__c = 'e2';
        workItem_2.Status__c = ' Completed';
        insert workItem_2;
	}

	@isTest static void testExecute_1() {
		Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];
		List<Workload__c> workloads = [select OwnerId from Workload__c];
		for(Workload__c w:workloads){
			System.assertNotEquals(completedQueue.Id, w.OwnerId);
		}

		SocialWorkloadProcessor proc = new SocialWorkloadProcessor();
		proc.execute(null);

		List<Workload__c> workloads_2 = [select OwnerId, Workload_ID__c from Workload__c];
		for(Workload__c w:workloads_2){
			if(w.Workload_ID__c=='w1'){
				System.assertNotEquals(completedQueue.Id, w.OwnerId);
			}else if(w.Workload_ID__c=='w2'){
				System.assertEquals(completedQueue.Id, w.OwnerId);
			}
		}

	}
	
}