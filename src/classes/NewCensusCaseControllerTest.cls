@isTest
private class NewCensusCaseControllerTest {

  	@testSetup
	private static void setupTest(){
		TestDataHelper.createResponseProperties();
		
		Case_Update_Properties__c[]caseSetting=new Case_Update_Properties__c[]{
			new Case_Update_Properties__c(name='case.status.closed',value__c='Inactive'),
			new Case_Update_Properties__c(name='error.folder.name',value__c='API Errors'),
			new Case_Update_Properties__c(name='workitem.status.closed',value__c='Completed')
		};
		insert caseSetting;
		
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.Unit_of_Interest_ID__c ='ERICABCDEF';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '123';
		unitObj.P_O_Box__c = null;
		unitObj.Meshblock_Code__c='11';
		unitObj.DP_ID__c='12345';
		insert unitObj;
		Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
		resp.RecordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		resp.Workflow_status__c='Eric';
		insert resp;
	}

// coverage test only
	@isTest static void coverageTest(){
		Response__c r=[select id, collection_instance__c from Response__c];
		NewCensusCaseController c=new NewCensusCaseController(new ApexPages.StandardController(r));
		system.assertEquals(null, c.caseId);
		c.newCase();
		system.assertNotEquals(null, c.caseId);
	}

}