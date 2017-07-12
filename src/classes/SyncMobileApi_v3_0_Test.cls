@isTest
private class SyncMobileApi_v3_0_Test {
	
	@testSetup 
	static void setupData(){
        Collection__c collection = new Collection__c();
        collection.Collection_Code__c = 'TEST_COL';
        insert collection;

        Collection_Instance__c collectionInstance = new Collection_Instance__c();
        collectionInstance.Collection__c = collection.Id;
        collectionInstance.Collection_Instance_Code__c = 'TEST_COL_INST';
        insert collectionInstance;

        Unit__c unit = new Unit__c();
        insert unit;

        Workload__c workload = new Workload__c();
        workload.Collection_Instance__c = collectionInstance.Id;
        workload.Workload_ID__c = 'TEST_WL';
        insert workload;

        Response__c response = new Response__c();
        response.Unit_of_Interest__c = unit.Id;
        response.Collection_Instance__c = collectionInstance.Id;
        response.Response_ExtId__c = 'ext42';
        insert response;

        Work_Item__c workitem = new Work_Item__c();
        workitem.Response__c = response.Id;
        workitem.Workload__c = workload.Id;
        workitem.Work_Item_Type__c = 'Address canvassing';
        insert workitem;

        Contact contact = new Contact();
        contact.LastName = 'Tstlastname';
        insert contact;

        Contact_Role__c contactRole = new Contact_Role__c();
        contactRole.Contact__c = contact.Id;
        contactRole.Collection__c = collection.Id;
        contactRole.Unit_of_Interest_ID__c = unit.Id;
        insert contactRole;
        
        System_Update__c config = System_Update__c.getInstance();
        config.Debug_Enabled__c = true;
        upsert config;

    }

    @isTest 
	static void testPostNoDeviceId() {
		System.debug('START testPostNoDeviceId');
		
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf('whatever');

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		  
		System.assertEquals(400, RestContext.response.statusCode);
		System.assertEquals('{"status":"error", "message":"Device id was not provided"}', RestContext.response.responseBody.toString());
		
		System.debug('END testPostNoDeviceId');
	}

    @isTest 
	static void testGetNoDeviceId() {
		System.debug('START testPostNoDeviceId');
		
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf('whatever');

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.getResults();
		Test.stopTest();
		  
		System.assertEquals(400, RestContext.response.statusCode);
		System.assertEquals('{"status":"error", "message":"Device id was not provided"}', RestContext.response.responseBody.toString());
		
		System.debug('END testPostNoDeviceId');
	}

	@isTest 
	static void testGetWrongDeviceId() {
		System.debug('START testGetWrongDeviceId');
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '100');
		RestContext.request.requestBody = Blob.valueOf('whatever');

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.getResults();
		Test.stopTest();
		  
		System.assertEquals(400, RestContext.response.statusCode);
		System.assertEquals('{"status":"error", "message":"Failed to find existing process for provided device id 100"}', RestContext.response.responseBody.toString());
		
		System.debug('END testGetWrongDeviceId');
	}

    @isTest 
	static void testProcessRequest_WorkItems() {
		System.debug('START testProcessRequest_WorkItems');

		Workload__c workload = [select Id from Workload__c];
        Response__c response = [select Id from Response__c];
		Work_Item__c workitem = [select Id, Name, Version__c, LastModifiedDate, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed","starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Work_Item__c workitemTest = [select Status__c, Starred__c from Work_Item__c where Id=:workitem.Id];
		System.assertEquals('Completed', workitemTest.Status__c);
		System.assertEquals(true, workitemTest.Starred__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_WorkItems');
	}

    @isTest 
	static void testProcessRequest_Responses() {
		System.debug('START testProcessRequest_Responses');

		Response__c response = [select Id, Name, Version__c, Collection_Instance__c from Response__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "responses":[{"id":"'+response.Id+'","vers":'+response.Version__c+', "ciId":"'+response.Collection_Instance__c+'", "qPack":"1234", "occStatus":"Occupied", "occReason":"testReason", "estOccupants":3}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Response__c responseTest = [select Questionnaire_Pack__c, Occupancy_Status__c, Occupancy_Status_Reason__c, Estimated_Number_of_Occupants__c from Response__c where Id=:response.Id];
		System.assertEquals('1234', responseTest.Questionnaire_Pack__c);
		System.assertEquals('Occupied', responseTest.Occupancy_Status__c);
		System.assertEquals('testReason', responseTest.Occupancy_Status_Reason__c);
		System.assertEquals(3, responseTest.Estimated_Number_of_Occupants__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_Responses');
	}

    @isTest 
	static void testProcessRequest_Units() {
		System.debug('START testProcessRequest_Units');

		Unit__c unit = [select Id, Name, Version__c from Unit__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "units":[{"mId":"43","id":"'+unit.Id+'","vers":'+unit.Version__c+', "addrType":"Test","bldName":"Smart House","lvlNum":"3","mbCode":"11","postcode":"1111","roadNum":"54","roadName":"Queen","roadType":"Street","suburb":"Grafton","town":"Auckland","unitNum":"1"}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Unit__c unitTest = [select Address_Type__c, Building_Name__c from Unit__c where Id=:unit.Id];
		System.assertEquals('Test', unitTest.Address_Type__c);
		System.assertEquals('Smart House', unitTest.Building_Name__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_Units');
	}

    @isTest 
	static void testProcessRequest_Tasks() {
		System.debug('START testProcessRequest_Tasks');

		Work_Item__c workitem = [select Id, Name, Version__c, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "tasks":[{"mId":4231, "subject":"phone call","actTime":"2015-10-09T02:30:00.000+0000","wi_mId":"1","type":"Dwelling"}], "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed", "mId":"1", "starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';

		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Task taskTest = [select Subject, WhatId, Type from Task where mId__c=4231];
		System.assertEquals('phone call', taskTest.Subject);
		System.assertEquals(workitem.Id, taskTest.WhatId);
		System.assertEquals('Dwelling', taskTest.Type);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_Tasks');
	}

    @isTest 
	static void testProcessRequest_Events() {
		System.debug('START testProcessRequest_Events');

		Work_Item__c workitem = [select Id, Name, Version__c, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "events":[{"mId":888,"subject":"phone call","actTime":"2015-10-09T02:30:00.000+0000","whatId":"'+workitem.Id+'"}], "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed", "mId":"1", "starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Event eventTest = [select Subject, WhatId, ActivityDateTime from Event where mId__c=888 limit 1];
		System.assertEquals('phone call', eventTest.Subject);
		System.assertEquals(workitem.Id, eventTest.WhatId);
		System.assertEquals(DateTime.newInstanceGMT(2015, 10, 9, 2, 30, 0), eventTest.ActivityDateTime);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_Events');
	}

    @isTest 
	static void testProcessRequest_Contacts() {
		System.debug('START testProcessRequest_Contacts');

		Contact contact = [select Version__c, FirstName, LastName, Personal_email__c, Phone, MobilePhone, Gender__c, Age__c from Contact];
		System.debug('contact = '+contact);
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "contacts":[{"id":"'+contact.Id+'","vers":'+contact.Version__c+',"fName":"testName","lName":"testsurname","email":"test@test.test", "phone":"2222222", "mobile":"1111111", "gender":"M", "age":42}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		System.debug('log enabled = '+Logger.isEnabled());
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Contact testContact = [select Version__c, FirstName, LastName, Personal_email__c, HomePhone, MobilePhone, Gender__c, Age__c from Contact where Id=:contact.Id];
		System.debug(LoggingLevel.INFO, 'testContact = '+testContact);
		System.assertEquals('testName', testContact.FirstName);
		System.assertEquals('testsurname', testContact.LastName);
		System.assertEquals('test@test.test', testContact.Personal_email__c);
		System.assertEquals('2222222', testContact.HomePhone);
		System.assertEquals('1111111', testContact.MobilePhone);
		System.assertEquals('M', testContact.Gender__c);
		System.assertEquals(42, testContact.Age__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_Contacts');
	}

    @isTest 
	static void testProcessRequest_ContactRoles() {
		System.debug('START testProcessRequest_ContactRoles');

		Contact_Role__c contactRole = [select Version__c, Contact__c, Unit_of_Interest_ID__c, Collection__c, Primary_Contact__c, Role__c from Contact_Role__c];
		System.debug('contactRole = '+contactRole);
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "contactRoles":[{"id":"'+contactRole.Id+'","vers":'+contactRole.Version__c+',"cntId":"'+contactRole.Contact__c+'","uId":"'+contactRole.Unit_of_Interest_ID__c+'","colId":"'+contactRole.Collection__c+'", "role":"TestRole42", "isPrimary":true}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Contact_Role__c testContactRole = [select Primary_Contact__c, Role__c from Contact_Role__c where Id=:contactRole.Id];
		System.debug('testContactRole = '+testContactRole);
		System.assertEquals(true, testContactRole.Primary_Contact__c);
		System.assertEquals('TestRole42', testContactRole.Role__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testProcessRequest_ContactRoles');
	}

    @isTest 
	static void testDni() {
		System.debug('START testDni');

		Workload__c workload = [select Id from Workload__c];
        Response__c response = [select Id from Response__c];
		Work_Item__c workitem = [select Id, Name, Version__c, LastModifiedDate, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "workitems":[{"escalations":"Do Not Interview - Temporary", "id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed","starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Work_Item__c workitemTest = [select Status__c, Starred__c from Work_Item__c where Id=:workitem.Id];
		System.assertEquals('Completed', workitemTest.Status__c);
		System.assertEquals(true, workitemTest.Starred__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testDni');
	}

    @isTest 
	static void testRefusal() {
		System.debug('START testRefusal');

        Response__c response = [select Id from Response__c];
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "refusals":[{"refused": "Individual Form","onBehalf": "Herself/himself","status": "New","notes": "some Notes 2","reason": "Anti-Government","vers": 1,"respId": "'+response.Id+'","mId": 123}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		Refusal__c refusal = [select Status__c, Response__c, Refused_on_behalf_of__c, Refused_to_complete__c from Refusal__c];
		System.assertEquals('New', refusal.Status__c);
		System.assertEquals(response.Id, refusal.Response__c);
		System.assertEquals('Herself/himself', refusal.Refused_on_behalf_of__c);
		System.assertEquals('Individual Form', refusal.Refused_to_complete__c);
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');

		RestContext.response = new RestResponse();

		SyncMobileApi_v3_0.getResults();

		System.assertEquals(200, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.size()>0);

		System.debug('END testRefusal');
	}

    @isTest 
	static void testDuplicateRefusal() {
		System.debug('START testDuplicateRefusal');

        Response__c response = [select Id from Response__c];
        
        Refusal__c refusal = new Refusal__c();
        refusal.Response__c = response.Id;
        refusal.Refused_to_complete__c = 'Individual Form';
        refusal.Refused_on_behalf_of__c = 'Herself/himself';
        refusal.Status__c = 'New';
        refusal.Refusal_Reason__c = 'Anti-Government';
        insert refusal;
		
		String requestBody = '{"versionCode":-42,"versionName":"-42test", "refusals":[{"refused": "Individual Form","onBehalf": "Herself/himself","status": "New","notes": "some Notes 2","reason": "Anti-Government","vers": 1,"respId": "'+response.Id+'","mId": 124}]}';
		
		RestContext.request = new RestRequest();
		RestContext.request.params.put('device_id', '42');
		RestContext.request.requestBody = Blob.valueOf(requestBody);

		RestContext.response = new RestResponse();

		Test.startTest();
		SyncMobileApi_v3_0.sync();
		Test.stopTest();
		
		List<Refusal__c> refusals = [select Status__c, Response__c, Refused_on_behalf_of__c, Refused_to_complete__c from Refusal__c];
		System.assertEquals(1, refusals.size());

		System.debug('END testDuplicateRefusal');
	}
    
    @isTest static void testSocialIndividualResponses(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','Social Mobile User',true);
        system.runAs(userObj){
            Workload__c workload = [select Id from Workload__c];
            Response__c response = [select Id from Response__c];
            Work_Item__c workitem = [select Id, Name, Version__c, LastModifiedDate, Response__c, Workload__c from Work_Item__c];
            Unit__c unit = [Select Id from Unit__c];
            Collection_Instance__c collectionInstance = [Select Id from Collection_Instance__c];
            workItem.ownerId = userObj.Id;
            update workItem;
            
            String requestBody = '{"versionCode":-42,"versionName":"-42test", "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed","starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
            
            RestContext.request = new RestRequest();
            RestContext.request.params.put('device_id', '42');
            RestContext.request.requestBody = Blob.valueOf(requestBody);
                        
            Response__c indResponse = new Response__c();
            indResponse.Unit_of_Interest__c = unit.Id;
            indResponse.Collection_Instance__c = collectionInstance.Id;
            indResponse.Response_ExtId__c = 'ext421';
            indResponse.RecordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            insert indResponse;
            
            RestContext.response = new RestResponse();
            
            Test.startTest();
            SyncMobileApi_v3_0.sync();
            Test.stopTest();

            RestContext.request = new RestRequest();
            RestContext.request.params.put('device_id', '42');
            
            RestContext.response = new RestResponse();
            
            SyncMobileApi_v3_0.getResults();
            
            System.assertEquals(200, RestContext.response.statusCode);
            System.assert(RestContext.response.responseBody.size()>0);
            System.assert(RestContext.response.responseBody.toString().containsIgnoreCase('indResponses'));
            
            System.debug('END testProcessRequest_Responses');
        }
    }
}