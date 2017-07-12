@isTest
private class WorkItemsGroupedByExCon_Test{
    @testSetup static void setupData(){
        Record_Outcomes__c ro = new Record_Outcomes__c();
        ro.Name = '1';
        ro.Delivery_Mode__c = 'Call';
        ro.Work_Item_Type__c = 'Courtesy contact';
        ro.Outcomes__c = 'Call Successful,Cannot Locate a Number,Scheduled Appointment,Scheduled Follow-up,Escalated,Sent Replacement Questionnaire,Data Taken Over The Phone,Advised Data Sent';
        insert ro;
        TestDataHelper.createResponseProperties();
    }
	@isTest static void testMethodOne(){
        Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
        User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Contact cnt = TestDataHelper.createContact(true);
        Contact cnt1 = TestDataHelper.createContact(false);
		cnt1.firstName = 'abc';
		cnt1.lastName = 'def';
		cnt1.email = 'abc@abc.com';
		cnt1.Address_ID__c = null;
		cnt1.Legacy_Contact_ID__c = null;
		cnt1.Mobile_Device_Id__c = null;
		insert cnt1;
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
        insert resp;
		resp = [Select Id,Unit_of_Interest__r.Unit_of_Interest_ID__c from Response__c where Id = :resp.Id];

        Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt1.Id, null, unitObj.Id, false);
        resp1.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        insert resp1;
		resp1 = [Select Id,Unit_of_Interest__r.Unit_of_Interest_ID__c from Response__c where Id = :resp1.Id];
        List<Work_Item__c> wiList = new List<Work_Item__c>();
        for(integer i=0;i<10;i++){
            Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi.Delivery_Mode__c = 'Call';
            wi.Work_Item_Type__c = 'Courtesy contact';
            wi.Status__c = 'New';
            wi.Call_Back_Time__c = system.now().addDays(1);
            wi.OwnerId = userObj1.Id;
            wi.Work_Item_ExtId__c = null;
            wiList.add(wi);
        }
        for(integer i=0;i<10;i++){
            Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, null, NULL, resp1.Id, null, false);
            wi.Delivery_Mode__c = 'Call';
            wi.Work_Item_Type__c = 'Courtesy contact';
            wi.Status__c = 'New';
            wi.Call_Back_Time__c = system.now().addDays(1);
            wi.OwnerId = userObj1.Id;
            wi.Work_Item_ExtId__c = null;
            wiList.add(wi);
        }
        insert wiList;
        Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
        wi1.Delivery_Mode__c = 'Call';
        wi1.Work_Item_Type__c = 'Courtesy contact';
        wi1.Status__c = 'New';
        wi1.Call_Back_Time__c = system.now().addDays(-1);
        wi1.OwnerId = userObj1.Id;
        insert wi1;
		Test.startTest();
		wiList = [Select Id,Response__r.Unit_of_Interest__r.Unit_of_Interest_ID__c, Unit__c,Contact__c,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c from Work_Item__c where Id in :wiList];
		System.assertEquals(20,wiList.size());
		wi1 = [Select Id,Response__r.Unit_of_Interest__r.Unit_of_Interest_ID__c, Unit__c,Contact__c,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c from Work_Item__c where Id = :wi1.Id];
		ApexPages.StandardController stdCont = new ApexPages.StandardController(wi1);
		WorkItemsGroupedByExCon wigb = new WorkItemsGroupedByExCon(stdCont);
		System.assertEquals(10,wigb.workItemsRelatedToContact.size());
		System.assertEquals(10,wigb.workItemsRelatedToCollectionUnit.size());
		Test.stopTest();
	}
}