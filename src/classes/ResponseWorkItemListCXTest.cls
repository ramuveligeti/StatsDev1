@istest
private class ResponseWorkItemListCXTest {

  	@testSetup
	private static void setupTest(){
		TestDataHelper.createResponseProperties();
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
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		resp.Workflow_status__c='Eric';
		insert resp;
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.Status__c = 'New';
		insert wi;
	}

	@istest static void testctr(){
		Response__c r=[select id,name from Response__c];
		ResponseWorkItemListCX c=new ResponseWorkItemListCX(new ApexPages.StandardController(r));
		system.assertEquals(1, c.workItems.size());

	}
}