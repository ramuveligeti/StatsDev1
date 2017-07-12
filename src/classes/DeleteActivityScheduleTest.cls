@isTest(SeeAllData=false)
private class DeleteActivityScheduleTest {
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
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(colIns.Id, true);
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

    @isTest static void deleteActivitySchedule(){
		Activity_Schedule__c asch = [Select Id from Activity_Schedule__c];
		Response__c rs = [Select Id from Response__c];
        Work_Item__c wi = TestDataHelper.createWorkItem(asch.Id, null, null, rs.Id, null, true);
        PageReference pr = page.DeleteActivityScheduleVF;
        test.setCurrentPage(pr);
        test.startTest();
        //DeleteActivityScheduleWIBatch.unitTestForceFail = true;
        ApexPages.StandardController stdController = new ApexPages.StandardController(asch);
        DeleteActivitySchedule das = new DeleteActivitySchedule(stdController);
        das.deleteActionMethod();
        das.deletionOfWorkItemsAndActivityScheduleFilters();
        test.stopTest();
        List<Work_Item__c> w = [Select Id from Work_Item__c];
        system.assertEquals(0, w.size());
        List<Activity_Schedule__c> a = [Select Id from Activity_Schedule__c];
        system.assertEquals(0, a.size());
    }

    @isTest static void deleteWorkItemsAndActivitySchedule(){
		Activity_Schedule__c asch = [Select Id from Activity_Schedule__c];
		Response__c rs = [Select Id from Response__c];
        Work_Item__c wi = TestDataHelper.createWorkItem(asch.Id, null, null, rs.Id, null, false);
        wi.Status__c = 'Completed';
        insert wi;
        PageReference pr = page.DeleteActivityScheduleVF;
        test.setCurrentPage(pr);
        test.startTest();
        //DeleteActivityScheduleWIBatch.unitTestForceFail = true;
        ApexPages.StandardController stdController = new ApexPages.StandardController(asch);
        DeleteActivitySchedule das = new DeleteActivitySchedule(stdController);
        das.deleteActionMethod();
        das.deletionOfWorkItemsAndActivityScheduleFilters();
        test.stopTest();
        List<Work_Item__c> w = [Select Id from Work_Item__c];
        system.assertEquals(0, w.size());
        List<Activity_Schedule__c> a = [Select Id from Activity_Schedule__c];
        system.assertEquals(0, a.size());
    }

    @isTest static void failWorkItemBatch(){
		Activity_Schedule__c asch = [Select Id from Activity_Schedule__c];
		Response__c rs = [Select Id from Response__c];
        Work_Item__c wi = TestDataHelper.createWorkItem(asch.Id, null, null, rs.Id, null, false);
        wi.Status__c = 'Completed';
        insert wi;
        DeleteActivityScheduleWIBatch wib = new DeleteActivityScheduleWIBatch(asch);
        wib.unitTestForceFail = true;
        test.startTest();
		Database.executebatch(wib);		
        test.stopTest();
        List<Work_Item__c> w = [Select Id from Work_Item__c];
        system.assertEquals(0, w.size());
        List<Activity_Schedule__c> a = [Select Id from Activity_Schedule__c];
        system.assertEquals(1, a.size());
    }

    @isTest static void failActivityScheduleFilterBatch(){
		Activity_Schedule__c asch = [Select Id from Activity_Schedule__c];
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Status__c = 'New';
        insert asf;
		Response__c rs = [Select Id from Response__c];
        Work_Item__c wi = TestDataHelper.createWorkItem(asch.Id, null, null, rs.Id, null, false);
        wi.Status__c = 'Completed';
        insert wi;
        DeleteActivityScheduleASFBatch wib = new DeleteActivityScheduleASFBatch(asch);
        wib.unitTestForceFail = true;
        test.startTest();
		Database.executebatch(wib);		
        test.stopTest();
        List<Activity_Schedule_Filter__c> f = [Select Id from Activity_Schedule_Filter__c];
        system.assertEquals(0, f.size());
        List<Activity_Schedule__c> a = [Select Id from Activity_Schedule__c];
        system.assertEquals(1, a.size());
    }
}