@istest
public class ApexUtilTest {

	@isTest
	private static void testGuid(){
		String a = ApexUtility.GUID();
		String b = ApexUtility.GUID();
		system.assertNotEquals(a,b);
	}


	@isTest
	private static void testErrorLog(){
		Error_log__c[] errors = [select id from Error_Log__c];
		system.assertEquals(0, errors.size());
		Test.startTest();
		ApexUtility.RecordErrorLog('Test failed', 123, 'Testing class', UserInfo.getUserId());
		Test.stopTest();
		errors = [select id from Error_Log__c];
		system.assertEquals(1, errors.size());
	}

	@isTest
	private static void testSendEmail(){
        SystemSettings__c config = new SystemSettings__c(Name = 'shortUrlClient.notificationEmail',Value__c = 'nobody@test.com, no.one@test.com');
        boolean success=false;
        Test.startTest();
        success = ApexUtility.sendEmail(SystemSettings__c.getInstance('shortUrlClient.notificationEmail'), // recipients
        	'Test failed', 'Test body', // subject, body
        	null, null, null, false); // targetObjectId, templateName, whatId, saveAsActivity
        Test.stopTest();
        system.assert(success);
	}

	@isTest
	private static void testMetadataAPI(){
		// cannot be verified, just pick an object for testing
		ApexUtility.getFieldNamesOfSObject(Account.sObjectType.getDescribe().fields.getMap(), true);
		ApexUtility.getPicklistValues('Case', 'Origin', true);
	}
}