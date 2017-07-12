@isTest
private class BatchSchedulerTest {

	@testSetup
	public static void setupData(){
		Collection__c c = TestDataHelper.createCollection(true);
		Collection_Instance__c ci = TestDataHelper.createCollectionInstance(c.Id, true);
	}

	public static testmethod void testRunBatchable_1() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];
		DeleteResponsesBatch batch = new DeleteResponsesBatch(collectionInstance);
		BatchScheduler bs = new BatchScheduler(batch);
		bs.runBatchable();
	}

	public static testmethod void testRunBatchable_2() {
		Collection_Instance__c collectionInstance = [select Collection_Instance_Code__c from Collection_Instance__c];
		DeleteResponsesBatch batch = new DeleteResponsesBatch(collectionInstance);
		BatchScheduler bs = new BatchScheduler(batch);
		bs.unitTestsForceCauseSchedule = true;
		bs.runBatchable();
	}
	
}