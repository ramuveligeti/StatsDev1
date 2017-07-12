@isTest
private class DeleteCollectionInstanceTest {

	@testSetup
	public static void setupData(){
		Case_Update_Properties__c[] config= new Case_Update_Properties__c[]{
			new Case_Update_Properties__c(name='case.status.closed',value__c='whatever'),
			new Case_Update_Properties__c(name='workitem.status.closed',value__c='whatever')
		};
		insert config;

		TestDataHelper.createResponseProperties();
		Collection__c c = TestDataHelper.createCollection(true);
		Collection_Instance__c ci = TestDataHelper.createCollectionInstance(c.Id, true);
		
		Staging_Element__c se = TestDataHelper.createStagingElement(false);
		se.CI_Collection_Instance_Code__c = ci.Collection_Instance_Code__c;
		insert se;

		Unit__c u = TestDataHelper.createUnit(true);
		Response__c r = TestDataHelper.createResponse(ci.Id, null, null, u.Id, true);
		Case cse = TestDataHelper.createCase(ci.Id, true);

		Activity_Schedule__c actsc = TestDataHelper.createActivitySchedule(ci.Id, false);
		actsc.Status__c = 'New';
		insert actsc;

		Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(actsc.Id, false);
		asf.Status__c = 'New';
		insert asf;

		Workload__c w = TestDataHelper.createWorkLoad(ci.Id, true);
		Work_Item__c wi = TestDataHelper.createWorkItem(actsc.Id, null, cse.Id, r.Id, w.Id, true);

		Task t = TestDataHelper.createTask(wi.Id, true);
	}

	public static testmethod void testDeleteCollectionInstanc_1() {
		Collection_Instance__c ci = TestDataHelper.createCollectionInstance(null, false);
		ApexPages.StandardController st_controller = new ApexPages.StandardController(ci);
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('No collection instance Id was provided')){
		    	b = true;
		    }
		}
		System.assert(b);
		System.assert(controller.showDeleteButton==false);
	}

	public static testmethod void testDeleteCollectionInstanc_2() {
		Collection_Instance__c ci = [select Id from Collection_Instance__c];
		String ciId = ci.Id;
		
		ApexPages.StandardController st_controller = new ApexPages.StandardController(ci);
		delete ci;
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('No collection instance exists with Id ')){
		    	b = true;
		    }
		}
		System.assert(b);
		System.assert(controller.showDeleteButton==false);
	}

	public static testmethod void testDeleteCollectionInstanc_3() {
		Collection_Instance__c ci = [select Id, Status__c from Collection_Instance__c];
		ci.Status__c = 'Active';
		update ci;

		ApexPages.StandardController st_controller = new ApexPages.StandardController(ci);
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Active collection instance can not be deleted')){
		    	b = true;
		    }
		}
		System.assert(b);
		System.assert(controller.showDeleteButton==false);
	}
	
	public static testmethod void testDeleteCollectionInstance() {
		Integer ci = [select count() from Collection_Instance__c];
		Integer se = [select count() from Staging_Element__c];
		Integer u = [select count() from Unit__c];
		Integer r = [select count() from Response__c];
		Integer cse = [select count() from Case];
		Integer actsc = [select count() from Activity_Schedule__c];
		Integer asf = [select count() from Activity_Schedule_Filter__c];
		Integer w = [select count() from Workload__c];
		Integer wi = [select count() from Work_Item__c];

		System.assertEquals(1, ci);
		System.assertEquals(1, se);
		System.assertEquals(1, u);
		System.assertEquals(1, r);
		System.assertEquals(1, cse);
		System.assertEquals(1, actsc);
		System.assertEquals(1, asf);
		System.assertEquals(1, w);
		System.assertEquals(1, wi);

		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c];

		ApexPages.StandardController st_controller = new ApexPages.StandardController(collectionInstance);
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		Test.startTest();
		controller.deleteCollectionInstance();
		Test.stopTest();

		Integer ci2 = [select count() from Collection_Instance__c];
		Integer se2 = [select count() from Staging_Element__c];
		Integer u2 = [select count() from Unit__c];
		Integer r2 = [select count() from Response__c];
		Integer cse2 = [select count() from Case];
		Integer actsc2 = [select count() from Activity_Schedule__c];
		Integer asf2 = [select count() from Activity_Schedule_Filter__c];
		Integer w2 = [select count() from Workload__c];
		Integer wi2 = [select count() from Work_Item__c];

		System.assertEquals(0, ci2);
		System.assertEquals(0, se2);
		System.assertEquals(1, u2); // units are not deleted
		System.assertEquals(0, r2);
		System.assertEquals(0, cse2);
		System.assertEquals(0, actsc2);
		System.assertEquals(0, asf2);
		System.assertEquals(0, w2);
		System.assertEquals(0, wi2);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b1 = false;
		boolean b2 = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Collection instance and its all related data will be deleted in the background')){
		    	b1 = true;
		    }
		    if (msg.getDetail().contains('The results will be sent to')){
		    	b2 = true;
		    }
		}
		System.assert(b1);
		System.assert(b2);
	}

	public static testmethod void testCancel_1() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c];

		ApexPages.StandardController st_controller = new ApexPages.StandardController(collectionInstance);
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		PageReference ref1 = controller.cancel();
		System.assertEquals('/'+collectionInstance.Id, ref1.getUrl());
	}

	public static testmethod void testCancel_2() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c];

		ApexPages.StandardController st_controller = new ApexPages.StandardController(collectionInstance);
		DeleteCollectionInstanceController controller = new DeleteCollectionInstanceController(st_controller);

		controller.collectionInstance = null;
		PageReference ref1 = controller.cancel();
		System.assertEquals('/', ref1.getUrl());
	}

	public static testmethod void testDeleteStagingElementsBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteStagingElemetsBatch batch = new DeleteStagingElemetsBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteActivityScheduleFilterBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteActivityScheduleFilterBatch batch = new DeleteActivityScheduleFilterBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteActivityScheduleBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteActivityScheduleBatch batch = new DeleteActivityScheduleBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteTasksBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteTasksBatch batch = new DeleteTasksBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteWorkloadsBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteWorkloadsBatch batch = new DeleteWorkloadsBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteWorkItemsBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteWorkItemsBatch batch = new DeleteWorkItemsBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteCasesBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteCasesBatch batch = new DeleteCasesBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteResponsesBatchFail() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteResponsesBatch batch = new DeleteResponsesBatch(collectionInstance);
		batch.unitTestForceFail = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}

	public static testmethod void testDeleteResponsesBatchException() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];

		DeleteResponsesBatch batch = new DeleteResponsesBatch(collectionInstance);
		batch.unitTestForceCauseException = true;
		Test.startTest();
		Database.executebatch(batch);
		Test.stopTest();
	}
}