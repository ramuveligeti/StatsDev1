@isTest
private class CountResponsesForCollectionInstance_Test 
{ 
	@testSetup static void setupData()
	{
		Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            colIns.Extension_Cut_off_Date__c = system.today().addDays(10);
			insert colIns;
            Contact cnt = TestDataHelper.createContact(false);
            cnt.Assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = false;
            unitObj.Assigned__c = false;
            insert unitObj;

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp.Extension_Date__c = system.today().addDays(-2);
			resp.Mark_in_Required__c = true;
			resp.Key__c = true;

            insert resp;
	}
	@isTest static void testMethod1(){
		 
			Collection_Instance__c colIns = [select id from Collection_Instance__c limit 1];
			Test.startTest();
			List<Id> listIDs = new list<Id>();

			listIDs.add(colIns.Id);
			CountResponsesForCollectionInstance.count(listIDs); 
            
			Test.stopTest();

			Collection_Instance__c   collectionInstance = [select
				Collection_Instance_Code__c,
				Collection__c,
				Id,
				RecordType.Name,
				Sample_Size__c,
				Keys_Sample_Size__c,
				Net_Keys__c,
				Net_Responses__c
			from Collection_Instance__c
			where Id = :colIns.Id
			];
			system.assertEquals(1, collectionInstance.Keys_Sample_Size__c);
			system.assertEquals(1, collectionInstance.Net_Keys__c);
			system.assertEquals(1, collectionInstance.Net_Responses__c);
					
	}

	@isTest static void testMethodSampleAndNetResponses(){
		 
			Collection_Instance__c colIns = [select id from Collection_Instance__c limit 1];
			Test.startTest();
			List<Id> listIDs = new list<Id>();

			listIDs.add(colIns.Id);
			CountSampleAndNetResponses.count(listIDs); 
            
			Test.stopTest();

			Collection_Instance__c   collectionInstance = [select
				Id,
				Net_Responses__c,
				Sample_Size__c
			from Collection_Instance__c
			where Id = :colIns.Id
			];
			
			system.assertEquals(1, collectionInstance.Net_Responses__c);
			system.assertEquals(1, collectionInstance.Sample_Size__c);
					
	}

	@isTest static void testMethodKeyResponses(){
		 
			Collection_Instance__c colIns = [select id from Collection_Instance__c limit 1];
			Test.startTest();
			List<Id> listIDs = new list<Id>();

			listIDs.add(colIns.Id);
			CountKeyResponsesForCollectionInstance.count(listIDs); 
            
			Test.stopTest();

			Collection_Instance__c   collectionInstance = [select
				Id,
				Keys_Sample_Size__c,
				Net_Keys__c
			from Collection_Instance__c
			where Id = :colIns.Id
			];
			system.assertEquals(1, collectionInstance.Keys_Sample_Size__c);
			system.assertEquals(1, collectionInstance.Net_Keys__c);
					
	}

	@isTest static void testMethodAllTypeOfResponses(){
		 
			Collection_Instance__c colIns = [select id from Collection_Instance__c limit 1];
			Test.startTest();
			List<Id> listIDs = new list<Id>();

			listIDs.add(colIns.Id);
			CountAllTypeOfResponses.count(listIDs); 
            
			Test.stopTest();

			Collection_Instance__c   collectionInstance = [select
				Id,
				Keys_Sample_Size__c,
				Net_Keys__c,
				Net_Responses__c,
				Sample_Size__c
			from Collection_Instance__c
			where Id = :colIns.Id
			];
			system.assertEquals(1, collectionInstance.Keys_Sample_Size__c);
			system.assertEquals(1, collectionInstance.Net_Keys__c);
			system.assertEquals(1, collectionInstance.Net_Responses__c);
			system.assertEquals(1, collectionInstance.Sample_Size__c);
					
	}

	

}