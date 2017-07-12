@isTest
private class FileMergeClientTest {

	@testSetup 
	public static void dataSetup(){
		Collection__c collection = TestDataHelper.createCollection(true);
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, true);

		Webservice_Settings__c webserviceSetting = new Webservice_Settings__c();
		webserviceSetting.Endpoint__c = 'http://test.tst';
		webserviceSetting.Method__c = 'POST';
		webserviceSetting.Content_Type__c = 'application/json';
		webserviceSetting.Private_Key__c = 'a';
		webserviceSetting.Public_Key__c = 'b';
		webserviceSetting.Name = 'FileMerge';
		insert webserviceSetting;

		SystemSettings__c notificationEmail = new SystemSettings__c();
		notificationEmail.Name = 'shortUrlClient.notificationEmail';
		notificationEmail.Value__c = 'test@test.test';
		insert notificationEmail;
	}
	
	@isTest 
	public static void testSuccess() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
		List<String> docIds = new List<String>{'abc123','abc124','abc125'};

		Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(200, 'Complete', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        FileMergeClient fmc = new FileMergeClient(collectionInstance.Id, docIds, 0);
        Datetime theFuture = Datetime.now().addMinutes(1);
		String cronStr = '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
        
		System.schedule('testJob', cronStr, fmc);
		Test.stopTest();
	}
	
	@isTest 
	public static void testFalure_1() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
		List<String> docIds = new List<String>{'abc123','abc124','abc125'};

		Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(400, 'Failed', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        FileMergeClient fmc = new FileMergeClient(collectionInstance.Id, docIds, 0);
        Datetime theFuture = Datetime.now().addMinutes(1);
		String cronStr = '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
        
		System.schedule('testJob', cronStr, fmc);
		Test.stopTest();
	}
	
	@isTest 
	public static void testFalure_2() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
		List<String> docIds = new List<String>{'abc123','abc124','abc125'};

		Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(400, 'Failed', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        FileMergeClient fmc = new FileMergeClient(collectionInstance.Id, docIds, 3);
        Datetime theFuture = Datetime.now().addMinutes(1);
		String cronStr = '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
        
		System.schedule('testJob', cronStr, fmc);
		Test.stopTest();
	}
	
	@isTest 
	public static void testFalure_3() {
		Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];

		Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(400, 'Failed', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        FileMergeClient fmc = new FileMergeClient(collectionInstance.Id, null, 3);
        Datetime theFuture = Datetime.now().addMinutes(1);
		String cronStr = '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
        
		System.schedule('testJob', cronStr, fmc);
		Test.stopTest();
	}	
}