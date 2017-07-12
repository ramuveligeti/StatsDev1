@isTest 
private class InboundEnquiryWorkItemButtonTest {
	@testSetup
	private static void setupTest(){
		insert new Response_API_Properties__c[]{
			 new Response_API_Properties__c(Name='response.status.closed',value__c='Completed'),
			 new Response_API_Properties__c(Name='activity.status.closed',value__c='Completed'),
			 new Response_API_Properties__c(Name='error.folder.name',value__c='API Errors'),
			 new Response_API_Properties__c(Name='workitem.status.closed',value__c='Completed')
		};
		
			
		System_Update__c su = System_Update__c.getOrgDefaults();
		su.Execute__c = false;
		upsert su;
	}

	@isTest
	private static void testCtr(){
		// this is a very specific census test
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricBiz';
        col.Collection_Code__c = 'EricBiz';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricBiz';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='EricBizABC';
        unitObj.Address_Type__c = null;
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.recordtypeid = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp.Status__c = 'New';
        resp.Unit_Type__c = null;
        resp.Delivery_Unit_Number__c = null;
        resp.Response_ExtId__c = 'EricBizEricBizABC'; // ramu changed logic to use association
		insert resp;

		Test.startTest();
        PageReference pageRef = Page.InboundEnquiryWorkItemButton;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('rid', resp.id);
        InboundEnquiryWorkItemButton ctr = new InboundEnquiryWorkItemButton();
        ctr.createWorkItem();
        system.assertNotEquals(null, ctr.wi);
        system.assertNotEquals(null, ctr.wi.id);
        Test.stopTest();
	}
}