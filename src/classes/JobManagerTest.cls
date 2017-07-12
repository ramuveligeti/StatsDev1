@isTest
private class JobManagerTest {

	@testSetup
	static void dataSetup(){
		Mobile_Sync_Staging__c mss = new Mobile_Sync_Staging__c();
		mss.Mobile_App_Installation_Id__c = '42';
		insert mss;

		Datetime before = Datetime.now().addDays(-2);
		Test.setCreatedDate(mss.Id, before);
	}
	
	@isTest static void testExecute() {
		JobManager jm = new JobManager();
		jm.execute(null);
	}
	
}