@istest
private  class CensusCallCentreUpdateControllerTest {
  	@testSetup
	private static void setupTest(){
		TestDataHelper.createResponseProperties();
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
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
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.work_item_type__c = 'List leave';
		wi.Status__c = 'New';
		insert wi;


		Case_Update_Properties__c[] config= new Case_Update_Properties__c[]{
			new Case_Update_Properties__c(name='case.status.closed',value__c='whatever'),
			new Case_Update_Properties__c(name='workitem.status.closed',value__c='whatever')
		};
		insert config;
	}

// no need for intensive testing... all the logic already existed under WorkitemWorkflowTest.cls
	@isTest
	private static void test_callCenterUpdate_workflowstatus(){
		Response__c r=[select id, Workflow_Status__c, Response_Summary_Status__c, status__c,
			Unit_of_Interest__c, Unit_of_Interest__r.Address_Type__c from Response__c];
		Case c = new Case(subject='testing');
		c.Response__c = r.id;
		c.Response__r = r;
		insert c;
		Test.setCurrentPage(Page.CensusCallCentreUpdatePage);
		CensusCallCentreUpdateController ctr = new CensusCallCentreUpdateController(new ApexPages.StandardController(c));

		test.startTest();
		ctr.save();
		test.stopTest();

		
		Response__c vR = [select workflow_status__c from Response__c ];
		system.assertEquals('Ready for Delivery', vR.workflow_status__c);
	}  



    
}