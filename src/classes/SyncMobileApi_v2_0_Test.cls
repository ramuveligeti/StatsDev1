@isTest
private class SyncMobileApi_v2_0_Test {
	
	@testSetup 
	static void setupData(){
        TestDataHelper.createDataSet();
    }
	
	@isTest 
	static void testGenerateExtId() {
		String deviceId = 'testDeviceId123';
		String userId = UserInfo.getUserId();
		Long mobileId = 1234;
		SyncMobileApi_v2_0.mobileDeviceId = deviceId;
		String extId = SyncMobileApi_v2_0.generateExtId(mobileId);
		
		System.assertEquals('testDeviceId123'+userId+'1234', extId);
	} 

	@isTest 
	static void testProcessRequest_WorkItems() {
		System.debug('START testProcessRequest_WorkItems');
		
		Work_Item__c workitem = [select Id, Name, Version__c, LastModifiedDate, Response__c, Workload__c from Work_Item__c];
		System.debug(workitem);
		String requestBody = '{"workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed","starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Work_Item__c workitemTest = [select Status__c, Starred__c from Work_Item__c where Id=:workitem.Id];
		
		System.debug('Error Workitems: '+SyncMobileApi_v2_0.errorWorkitems.values());
		
		System.assertEquals('Completed', workitemTest.Status__c);
		System.assertEquals(true, workitemTest.Starred__c);
		
		System.debug('END testProcessRequest_WorkItems');
	}

	@isTest 
	static void testProcessRequest_Responses() {
		Response__c response = [select Id, Name, Version__c, Collection_Instance__c from Response__c];
		String requestBody = '{"responses":[{"id":"'+response.Id+'","vers":'+response.Version__c+', "ciId":"'+response.Collection_Instance__c+'", "qPack":"1234", "occStatus":"Occupied", "occReason":"testReason", "estOccupants":3}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Response__c responseTest = [select Questionnaire_Pack__c, Occupancy_Status__c, Occupancy_Status_Reason__c, Estimated_Number_of_Occupants__c from Response__c where Id=:response.Id];
		System.assertEquals('1234', responseTest.Questionnaire_Pack__c);
		System.assertEquals('Occupied', responseTest.Occupancy_Status__c);
		System.assertEquals('testReason', responseTest.Occupancy_Status_Reason__c);
		System.assertEquals(3, responseTest.Estimated_Number_of_Occupants__c);
	}

	@isTest 
	static void testProcessRequest_Units() {
		Unit__c unit = [select Id, Name, Version__c from Unit__c];
		String requestBody = '{"units":[{"mId":"43","id":"'+unit.Id+'","vers":'+unit.Version__c+', "addrType":"Test","bldName":"Smart House","lvlNum":"3","mbCode":"11","postcode":"1111","roadNum":"54","roadName":"Queen","roadType":"Street","suburb":"Grafton","town":"Auckland","unitNum":"1"}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Unit__c unitTest = [select Address_Type__c, Building_Name__c from Unit__c where Id=:unit.Id];
		System.assertEquals('Test', unitTest.Address_Type__c);
		System.assertEquals('Smart House', unitTest.Building_Name__c);
	}

	@isTest 
	static void testProcessRequest_Tasks() {
		Work_Item__c workitem = [select Id, Name, Version__c, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"tasks":[{"mId":4231, "subject":"phone call","actTime":"2015-10-09T02:30:00.000+0000","wi_mId":"1","type":"Dwelling"}], "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed", "mId":"1", "starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Task taskTest = [select Subject, WhatId, Type from Task where mId__c=4231];
		System.assertEquals('phone call', taskTest.Subject);
		System.assertEquals(workitem.Id, taskTest.WhatId);
		System.assertEquals('Dwelling', taskTest.Type);
	}

	@isTest 
	static void testProcessRequest_Events() {
		Work_Item__c workitem = [select Id, Name, Version__c, Response__c, Workload__c from Work_Item__c];
		
		String requestBody = '{"events":[{"mId":888,"subject":"phone call","actTime":"2015-10-09T02:30:00.000+0000","wi_mId":"1"}], "workitems":[{"id":"'+workitem.Id+'","vers":'+workitem.Version__c+',"respId":"'+workitem.Response__c+'","status":"Completed", "mId":"1", "starred":true,"wlId":"'+workitem.Workload__c+'","type":"Address canvassing"}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Event eventTest = [select Subject, WhatId, ActivityDateTime from Event where mId__c=888 limit 1];
		System.assertEquals('phone call', eventTest.Subject);
		System.assertEquals(workitem.Id, eventTest.WhatId);
		System.assertEquals(DateTime.newInstanceGMT(2015, 10, 9, 2, 30, 0), eventTest.ActivityDateTime);
	}
	
	@isTest 
	static void testInsertUnits() {
		Unit__c unit = TestDataHelper.createUnit(false);
		
		List<Unit__c> units = new List<Unit__c>();
		units.add(unit);
		SyncMobileApi_v2_0.saveObjects(units, 'insert');
		SyncMobileApi_v2_0.saveObjects(units, 'update');
		
		
	}

	@isTest 
	static void testGenerateResponseContainer() {
		SyncMobileApi_v2_0.systemSettings = SystemSettings__c.getAll();
		SyncMobileApi_v2_0.ResponseContainer responseC = SyncMobileApi_v2_0.generateResponseContainer();

		String jsonStr = responseC.toJson();

		System.assert(jsonStr.contains('"workloads":[{'));
		System.assert(jsonStr.contains('"workitems":[{'));
		System.assert(jsonStr.contains('"responses":[{'));
		System.assert(jsonStr.contains('"units":[{'));
	}

	@isTest 
	static void testSync_1() {
		RestContext.request = new RestRequest();
		RestContext.response = new RestResponse();
		RestContext.request.requestBody = Blob.valueOf('');
		SyncMobileApi_v2_0.sync();

		System.debug('RestContext.response.responseBody = '+RestContext.response.responseBody.toString());
		System.assertEquals(200, RestContext.response.statusCode);
	}

	@isTest 
	static void testSync_2() {
		RestContext.request = new RestRequest();
		RestContext.response = new RestResponse();

		String badJson = '{"deviceId":"123qwe", "contacts":[{"vers":2a,"mid":123,"id":"0031700000Kmtz5","mobile":"021 123 4567","phone":"0000002","email":"slava.yakovlev@fronde.com","lName":"Yakovlev","fName":"Slava","age":36,"gender":"m"}]}';

		RestContext.request.requestBody = Blob.valueOf(badJson);
		SyncMobileApi_v2_0.sync();

		System.assertEquals(400, RestContext.response.statusCode);
	}

	@isTest 
	static void testProcessRequest_Contacts() {
		Contact contact = [select Version__c, FirstName, LastName, Email, Phone, MobilePhone, Gender__c, Age__c from Contact];
		System.debug('contact = '+contact);
		
		String requestBody = '{"contacts":[{"id":"'+contact.Id+'","vers":'+contact.Version__c+',"fName":"testName","lName":"testsurname","email":"test@test.test", "phone":"2222222", "mobile":"1111111", "gender":"M", "age":42}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Contact testContact = [select Version__c, FirstName, LastName, Email, Phone, MobilePhone, Gender__c, Age__c from Contact];
		System.assertEquals('testName', testContact.FirstName);
		System.assertEquals('testsurname', testContact.LastName);
		System.assertEquals('test@test.test', testContact.Email);
		System.assertEquals('2222222', testContact.Phone);
		System.assertEquals('1111111', testContact.MobilePhone);
		System.assertEquals('M', testContact.Gender__c);
		System.assertEquals(42, testContact.Age__c);
	}

	@isTest 
	static void testProcessRequest_ContactRoles() {
		Contact_Role__c contactRole = [select Version__c, Contact__c, Unit_of_Interest_ID__c, Collection__c, Primary_Contact__c, Role__c from Contact_Role__c];
		System.debug('contactRole = '+contactRole);
		
		String requestBody = '{"contactRoles":[{"id":"'+contactRole.Id+'","vers":'+contactRole.Version__c+',"cntId":"'+contactRole.Contact__c+'","uId":"'+contactRole.Unit_of_Interest_ID__c+'","colId":"'+contactRole.Collection__c+'", "role":"TestRole42", "isPrimary":true}]}';
		SyncMobileApi_v2_0.processRequest(requestBody);
		
		Contact_Role__c testContactRole = [select Primary_Contact__c, Role__c from Contact_Role__c where Id=:contactRole.Id];
		System.debug('testContactRole = '+testContactRole);
		System.assertEquals(true, testContactRole.Primary_Contact__c);
		System.assertEquals('TestRole42', testContactRole.Role__c);
	}
	
}