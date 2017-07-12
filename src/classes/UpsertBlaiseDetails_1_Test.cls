@isTest
private class UpsertBlaiseDetails_1_Test {
/* DELETE
	private static String getJson(){
		return '{'+
				  '"householdResponses": [{'+
				    '"blaiseId": "hresposneblaiseId42",'+
				    '"type": "Household",'+
				    '"status": "status",'+
				    '"statusReason":"some reason",'+
				    '"collectionNumber": 1,'+
				    '"unitFrameId": "unitframeId42",'+
				    '"contacts": ['+
				      '{'+
				        '"fName": "firstName",'+
				        '"lName": "lastName",'+
				        '"email": "email@test.com",'+
				        '"phone": "123456a",'+
				        '"gender": "m/f",'+
				        '"age": 42,'+
				        '"doNotContactOn": "Saturday;Sunday",'+
				        '"bestTimeToContact": "Morning 8am - 12pm",'+
				        '"blaiseId": "contactblaiseId42",'+
				        '"isPrimary": "true",'+
				        '"individualResponses": ['+
				          '{'+
				            '"status": "status",'+
				    		'"statusReason":"some reason",'+
				            '"type": "Individual",'+
				            '"blaiseId": "iresposneblaiseId42"'+
				          '}'+
				        ']'+
				      '}'+
				    ']'+
				  '}]'+
				'}';
	}
	
	@isTest static void testUpsertBlaiseDetails_1() {

		TestDataHelper.createResponseProperties();

		Collection__c c = TestDataHelper.createCollection(false);
		c.Collection_Code__c = 'HLFS';
		insert c;

		Collection_Instance__c ci = TestDataHelper.createCollectionInstance(c.Id, false);
		ci.Collection_Instance_Code__c = 'Q1HLFS';
		ci.Reference_Period__c = '201601';
		insert ci;

		Unit__c u = TestDataHelper.createUnit(false);
		u.Unit_of_Interest_ID__c = 'unitframeId42';
		insert u;

		String json = getJson();
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf(json);

		UpsertBlaiseDetails_1.upsertBlaiseDetails();

		Response__c hR = [select Id from Response__c where Response_ExtId__c='hresposneblaiseId42'];
		System.assertNotEquals(null, hR);

		Contact con = [select Id from Contact where Legacy_Contact_ID__c='contactblaiseId42'];
		System.assertNotEquals(null, con);

		System.debug('responses = '+[select Id, Response_ExtId__c from Response__c]);

		Response__c iR = [select Id from Response__c where Response_ExtId__c='iresposneblaiseId42'];
		System.assertNotEquals(null, iR);

		Contact_Role__c cr = [select Id from Contact_Role__c where Contact__c=:con.Id and Unit_of_Interest_ID__c=:u.Id and Collection__c=:c.Id];
		System.assertNotEquals(null, cr);
	}
	*/
	
}