@isTest
private class ErrorLogRemoverTest {
	
	
	@isTest static void testRemoveLogs_1() {		
		DateTime tooOldDate = DateTime.now().addDays(-31);

		Error_Log__c el = new Error_Log__c();
		el.Process_Name__c='Mobile Sync';
		insert el;

		Test.setCreatedDate(el.Id, tooOldDate);

		List<Error_Log__c> errors1 = [select Id from Error_Log__c];

		ErrorLogRemover remover = new ErrorLogRemover();
		remover.execute(null);

		List<Error_Log__c> errors2 = [select Id from Error_Log__c];
		System.assertEquals(0, errors2.size());
	}
	
	@isTest static void testRemoveLogs_2() {
		TestDataHelper.createSystemSettings();
		
		DateTime tooOldDate = DateTime.now().addDays(-31);

		Error_Log__c el = new Error_Log__c();
		el.Process_Name__c='Mobile Sync';
		insert el;

		Test.setCreatedDate(el.Id, tooOldDate);

		List<Error_Log__c> errors1 = [select Id from Error_Log__c];

		ErrorLogRemover remover = new ErrorLogRemover();
		remover.execute(null);

		List<Error_Log__c> errors2 = [select Id from Error_Log__c];
		System.assertEquals(0, errors2.size());
	}
	
}