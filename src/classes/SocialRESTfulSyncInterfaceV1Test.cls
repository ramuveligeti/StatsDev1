@isTest
private class SocialRESTfulSyncInterfaceV1Test {
	public static Collection__c c;
	public static Collection_Instance__c ci;
	public static Unit__c u;
	public static String json;
		
	public static void setup(){
		json='{'+ 
			  '"householdResponses": [{'+
			    '"externalId": "Z002080001/H001",'+
			    '"type": "Household",'+
			    '"status": "status",'+
			    '"statusReason":"some reason",'+
			    '"collectionInstanceCode": "HLFSC127",'+
			    '"hHFrameId": "Z002080001",'+ 
			    '"seventyFivePlus": "true",'+
			    '"cATI": "false",'+
                '"cARI": "false",'+
                '"rEC": "false",'+
                '"unitNotes":"tested",'+
            	'"unitNotesCreatedDate":"11/6/2014 01:00 PM",'+
            	'"unitNotesModifiedDate":"11/6/2014 01:00 PM",'+
           		'"caseInterviewTime": "11/6/2014 12:00 PM",'+
                '"caseEditTime": "11/6/2014 01:00 PM",'+
            	'"workItems": [{'+
                    '"externalId": "Z002080001/H001",'+
                    '"notes":"tested",'+
                    '"notesCreatedByDate":"11/6/2014 01:00 PM",'+
                    '"notesModifiedByDate":"11/6/2014 01:00 PM"'+
       		    '}],'+
			    '"contacts": ['+
			      '{'+
			        '"fName": "firstName",'+
			        '"lName": "lastName",'+
			        '"email": "email@test.com",'+
			        '"phone": "123456a",'+
			        '"gender": "m/f",'+
			        '"doNotContactOn": "Saturday;Sunday",'+
			        '"bestTimeToContact": "Morning 8am - 12pm",'+
			        '"externalId": "Z002080001/P011",'+
			        '"isPrimary": "true",'+
			        '"individualResponses": ['+
			          '{'+
			            '"status": "status",'+
			    		'"statusReason":"some reason",'+
			            '"type": "Individual",'+
			            '"externalId": "Z002080001/P011",'+
             			'"cARI": "false",'+
              			'"rEC": "false",'+
            			'"caseInterviewTime": "11/6/2014 12:00 PM",'+
             		    '"caseEditTime": "11/6/2014 01:00 PM",'+
            			'"unitNotes":"tested",'+
            			'"unitNotesCreatedDate":"11/6/2014 01:00 PM",'+
            			'"unitNotesModifiedDate":"11/6/2014 01:00 PM"'+
			          '}'+
			        ']'+
			      '}'+
			    ']'+
			  '}]'+
			'}';
		TestDataHelper.createResponseProperties();

		c = TestDataHelper.createCollection(false);
		c.Collection_Code__c = 'HLFS';
		insert c;
		ci = TestDataHelper.createCollectionInstance(c.Id, false);
		ci.Collection_Instance_Code__c = 'HLFSC127';
		ci.Reference_Period__c = '201601';
		insert ci;
		u = TestDataHelper.createUnit(false);
		u.Unit_of_Interest_ID__c = 'Z002080001'; 
        u.Notes__c = 'test';
		insert u;       
	}
	
	@isTest static void testUpsertSocialDetails() {
		setup();
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf(json);

		SocialRESTfulSyncInterfaceV1.upsertSocialDetails();
        
        Unit__c hU = [select Id, Notes__c from Unit__c where Unit_of_Interest_ID__c='Z002080001'];
		System.assertEquals('tested', hU.Notes__c);
        
		list<Response__c> hR = new list<Response__c>([select Id from Response__c where Response_ExtId__c='HLFSC127Z002080001/H001']);
		System.assertNotEquals(0, hR.size());
        
	//	list<Work_Item__c> hWI = new list<Work_Item__c>([select Id from Work_Item__c where Work_Item_ExtId__c='HLFSC127Z002080001/H001']);
	//	System.assertNotEquals(0, hWI.size());
        
		Contact con = [select Id, Do_Not_Contact_Days__c from Contact where Legacy_Contact_ID__c='HLFS-Z002080001/P011'];
		System.assertEquals('Saturday;Sunday', con.Do_Not_Contact_Days__c);
		System.assertNotEquals(null, con);

		list<Response__c> iR = new list<Response__c>([select Id from Response__c where Response_ExtId__c='HLFSC127Z002080001/P011']);
		System.assertNotEquals(0, iR.size());

		Contact_Role__c cr = [select Id from Contact_Role__c where Contact__c=:con.Id and Unit_of_Interest_ID__c=:u.Id and Collection__c=:c.Id];
		System.assertNotEquals(null, cr);
		
		// Check 75+ suppression.
		list<Special_Arrangement__c> sa1 = new list<Special_Arrangement__c>([select count() from Special_Arrangement__c where Collection__c =: c.Id and Survey_Unit__c =: u.Id and Status__c = 'Active']);
		System.assertNotEquals(0, sa1.size());
	}

	@isTest static void testUpdate75plusSA() {
		setup();
		Special_Arrangement__c saToInsert = new Special_Arrangement__c(	RecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId(), 
																		Collection__c = c.Id,
               															Suppression_Type__c = '75+', 
               															Survey_Unit__c = u.Id,
               															Month_1__c = true, Month_2__c = true, Month_3__c = true, Month_7__c = true, Month_8__c = true, Month_9__c = true, Month_10__c = true, Month_11__c = true, Month_12__c = true, 
               															Month_4__c = false, Month_5__c = false, Month_6__c = false, 
               															Rule_Start_Date__c = Date.today().addDays(-1));
        insert saToInsert;
		String jsonFalse = '{'+ 
		  '"householdResponses": [{'+
		    '"externalId": "Z002080001/H001",'+
		    '"type": "Household",'+
		    '"status": "status",'+
		    '"statusReason":"some reason",'+
		    '"collectionInstanceCode": "HLFSC127",'+
		    '"hHFrameId": "Z002080001",'+ 
		    '"seventyFivePlus": "false",'+
		    '"cATI": "false",'+
            '"cARI": "false",'+
            '"rEC": "false",'+
            '"unitNotes":"tested",'+
           	'"unitNotesCreatedDate":"11/6/2014 01:00 PM",'+
            '"unitNotesModifiedDate":"11/6/2014 01:00 PM",'+
            '"caseInterviewTime": "11/6/2014 12:00 PM",'+
            '"caseEditTime": "11/6/2014 01:00 PM",'+
            '"workItems": [{'+
                    '"externalId": "Z002080001/H001",'+
                    '"notes":"tested",'+
                    '"notesCreatedByDate":"11/6/2014 01:00 PM",'+
                    '"notesModifiedByDate":"11/6/2014 01:00 PM"'+
       		    '}],'+
		    '"contacts": ['+
		      '{'+
		        '"fName": "firstName",'+
		        '"lName": "lastName",'+
		        '"email": "email@test.com",'+
		        '"phone": "123456a",'+
		        '"gender": "m/f",'+
		        '"doNotContactOn": "Saturday;Sunday",'+
		        '"bestTimeToContact": "Morning 8am - 12pm",'+
		        '"externalId": "Z002080001/P011",'+
		        '"isPrimary": "true",'+
		        '"individualResponses": ['+
		          '{'+
		            '"status": "status",'+
		    		'"statusReason":"some reason",'+
		            '"type": "Individual",'+
		            '"externalId": "Z002080001/P011",'+
                    '"cARI": "false",'+
                    '"rEC": "false",'+
                    '"caseInterviewTime": "11/6/2014 12:00 PM",'+
                    '"caseEditTime": "11/6/2014 01:00 PM"'+
		          '}'+
		        ']'+
		      '}'+
		    ']'+
		  '}]'+
		'}';
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf(jsonFalse);

		SocialRESTfulSyncInterfaceV1.upsertSocialDetails();

		// Check 75+ suppression is expired
		list<Special_Arrangement__c> sa1 = new list<Special_Arrangement__c>([select count() from Special_Arrangement__c where Collection__c =: c.Id and Survey_Unit__c =: u.Id and Status__c = 'Expired']);
		System.assertEquals(1, sa1.size());
	}
	
	@isTest static void testUpsertSocialDetailsJSONError() {
		setup();
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf('malFormedJson');

		SocialRESTfulSyncInterfaceV1.upsertSocialDetails();

		list<Error_Log__c> error = new list<Error_Log__c>([select Id from Error_Log__c]);
		System.assertEquals(1, error.size());
	}	
}