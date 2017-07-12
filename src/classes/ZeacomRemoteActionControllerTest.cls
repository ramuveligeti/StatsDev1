@isTest
private class ZeacomRemoteActionControllerTest {
	@testSetup private static void setupTest(){
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
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		resp.Workflow_status__c='Eric';
		insert resp;
	}

    static testMethod void coverageTest() {
    	// this is a button class, all logic are delegated to the CSRActionRecorder.cls
    	
    	// ZeacomRemoteActionController is generic, it can be used as an extensions on any object
		Response__c rs = [Select Id from Response__c];
    	Work_Item__c testA=new Work_Item__c(Work_Item_Type__c='Access Code',Response__c=rs.Id);
    	insert testA;
    	ZeacomRemoteActionController ctr = new ZeacomRemoteActionController(new ApexPages.StandardController(testA));
    	
    	// testing the loading method
    	ctr.finishPreviewing();
    	
        
    }
    
}