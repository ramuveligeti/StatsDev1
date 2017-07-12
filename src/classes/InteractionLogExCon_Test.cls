@isTest
private class InteractionLogExCon_Test{
    @testSetup static void setupData(){
        Record_Outcomes__c ro = new Record_Outcomes__c();
        ro.Name = '1';
        ro.Delivery_Mode__c = 'Call';
        ro.Work_Item_Type__c = 'Courtesy contact';
        ro.Outcomes__c = 'Call Successful,Cannot Locate a Number,Scheduled Appointment,Scheduled Follow-up,Escalated,Sent Replacement Questionnaire,Data Taken Over The Phone,Advised Data Sent';
        insert ro;
        TestDataHelper.createResponseProperties();
    }
	@isTest static void InteractionLogTest(){
		User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Extension_Cut_off_Date__c = system.today().addDays(10);
		insert colIns;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
        User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Contact cnt = TestDataHelper.createContact(false);
        cnt.Assigned__c = false;
        insert cnt;
        Contact cnt1 = TestDataHelper.createContact(false);
		cnt1.FirstName = 'xyz';
		cnt1.LastName = 'xyz1';
		cnt1.email = 'Account@Account.co.nz';
		cnt1.phone = '987654321';
		cnt1.Address_ID__c = '123';
		cnt1.Legacy_Contact_ID__c = '345';
		cnt1.Mobile_Device_Id__c = '567';
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
        resp.Extension_Date__c = system.today().addDays(-2);
        insert resp;
        Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
        wi1.Delivery_Mode__c = 'Call';
        wi1.Work_Item_Type__c = 'Courtesy contact';
        wi1.Status__c = 'New';
        wi1.Call_Back_Time__c = system.now().addDays(-1);
        wi1.OwnerId = userObj.Id;
		wi1.Contact__c = cnt.Id;
        insert wi1;
		List<Task> ts = [Select Id from Task where whatId = :wi1.Id];
		System.assert(ts.size()==0);
        wi1 = [Select Id,Contact__r.Notes__c,Response_Extension_Date__c,Response__r.Unit_of_Interest__r.Notes__c,Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c where Id = :wi1.Id];
		Test.startTest();
		{
            ApexPages.StandardController stdCont = new APexPages.StandardController(wi1);
			InteractionLogExCon ie = new InteractionLogExCon(stdCont);
			ie.ts.System_Contact__c = cnt1.Id;
			ie.ts.Subject__c = 'Feedback';
			ie.save();
			//ie.processOutcome();
			ie.ts.Feedback_Type__c = 'Questionnaire';
			ie.ts.Description = 'abc';
			ie.save();
			ts = [Select Id from Task where whatId = :wi1.Id];
			System.assert(ts.size()==1);
			ie = new InteractionLogExCon(stdCont);
			ie.ts.System_Contact__c = cnt1.Id;
			ie.ts.Subject__c = 'Grant Extension';
			ie.workItem.Response__r.Extension_Date__c = null;
			ie.save();
			//ie.processOutcome();
			ie.workItem.Response__r.Extension_Date__c = System.today().addDays(-1);
			ie.save();
			ie.workItem.Response__r.Extension_Date__c = System.today().addDays(11);
			ie.save();
			ie.workItem.Response__r.Extension_Date__c = System.today().addDays(10);
			ie.save();
			ie = new InteractionLogExCon(stdCont);
			ie.ts.System_Contact__c = cnt1.Id;
			ie.ts.Subject__c = 'Data Taken Over The Phone - PDF/Paper';
			//ie.processOutcome();
			ie.save();
			resp = [Select Id,Status__c,Response_Status_Reason__c from Response__c];
			System.assertEquals('On hold',resp.Status__c);
			System.assertEquals('Data Received',resp.Response_Status_Reason__c);
			ts = [Select Id from Task where whatId = :wi1.Id];
			System.assertEquals(3,ts.size());
			ie.clear();
		}
		Test.stopTest();
	}
}