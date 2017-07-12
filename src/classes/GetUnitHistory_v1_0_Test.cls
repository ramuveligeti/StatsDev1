/**
 * @Amendment       ECP-3007
 * @author          Caterina Cuccurullo
 * @date            07.Oct.2016
 * Added assignment of delivery mode for Inbound Enquiry Work item.
**/
@isTest
private class GetUnitHistory_v1_0_Test {

	@testSetup 
	static void setupData(){
		TestDataHelper.createResponseProperties();
		TestDataHelper.createSystemSettings();

		Unit__c unit1 = new Unit__c();
		insert unit1;

        Unit__c unit2 = new Unit__c();
		insert unit2;

		Collection__c collection = new Collection__c();
		insert collection;

		Collection_Instance__c collectionInstance = new Collection_Instance__c();
		collectionInstance.Collection__c = collection.Id;
		insert collectionInstance;

		Response__c response1 = new Response__c();
		response1.Collection_Instance__c = collectionInstance.Id;
		response1.Unit_of_Interest__c = unit1.Id;
		insert response1;

		Response__c response2 = new Response__c();
		response2.Collection_Instance__c = collectionInstance.Id;
		response2.Unit_of_Interest__c = unit2.Id;
		insert response2;

		Work_Item__c workitem1 = new Work_Item__c();
		workitem1.Work_Item_Type__c = 'List leave';
		workitem1.Response__c = response1.Id;
		insert workitem1;

		Work_Item__c workitem2 = new Work_Item__c();
		workitem2.Work_Item_Type__c = 'List leave';
		workitem2.Response__c = response2.Id;
		insert workitem2;

		Work_Item__c workitem3 = new Work_Item__c();
		workitem3.Work_Item_Type__c = 'List leave';
		workitem3.Response__c = response2.Id;
		insert workitem3;

		Work_Item__c historyWorkitem1 = new Work_Item__c();
		historyWorkitem1.Work_Item_Type__c = 'Inbound Enquiry';
        historyWorkitem1.Delivery_Mode__c = 'Call';
		historyWorkitem1.Response__c = response1.Id;
		insert historyWorkitem1;

		Work_Item__c historyWorkitem2 = new Work_Item__c();
		historyWorkitem2.Work_Item_Type__c = 'Inbound Enquiry';
        historyWorkitem2.Delivery_Mode__c = 'Call';
		historyWorkitem2.Response__c = response2.Id;
		insert historyWorkitem2;

		Task task1 = new Task();
		task1.Subject = 'test subj 1';
		task1.WhatId = historyWorkitem1.Id;
		task1.Action_Date_Time__c = Datetime.now();
		task1.Type = 'test type';
		insert task1;

		Task task2 = new Task();
		task2.Subject = 'test subj 2';
		task2.WhatId = historyWorkitem1.Id;
		insert task2;

		Task task3 = new Task();
		task3.Subject = 'test subj 3';
		task3.WhatId = historyWorkitem2.Id;
		insert task3;

		Task task4 = new Task();
		task4.Subject = 'test subj 4';
		task4.WhatId = historyWorkitem2.Id;
		insert task4;

		Task task5 = new Task();
		task5.Subject = 'test subj 4';
		task5.WhatId = historyWorkitem2.Id;
		insert task5;
    }
	
	@isTest static void test_sync() {
		List<Work_Item__c> workitems = [select Id from Work_Item__c where Work_Item_Type__c='List leave'];

		String requestJson = '{"whatId":[';
		for(Work_Item__c workitem:workitems){
			requestJson += '"'+workitem.Id+'",';
		}
		requestJson = requestJson.subString(0, requestJson.length() - 1);
		requestJson += ']}';
		System.debug('requestJson = '+requestJson);
		
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf(requestJson);
		RestContext.response = new RestResponse();
		GetUnitHistory_v1_0.sync();

		String responseJson = RestContext.response.responseBody.toString();
		System.debug('responseJson = '+responseJson);

		GetUnitHistory_v1_0.ResponseContainer responseContainer = (GetUnitHistory_v1_0.ResponseContainer)JSON.deserialize(responseJson, GetUnitHistory_v1_0.ResponseContainer.class);
		System.assert(responseContainer!=null);
		System.assertEquals(2, responseContainer.container.size());
	}
	
}