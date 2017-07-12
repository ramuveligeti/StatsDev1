@isTest
private class WorkItemsQueueView_Test {
    @testSetup static void setupData(){
        Record_Outcomes__c ro = new Record_Outcomes__c();
        ro.Name = '1';
        ro.Delivery_Mode__c = 'Call';
        ro.Work_Item_Type__c = 'Courtesy contact';
        ro.Outcomes__c = 'Call Successful,Cannot Locate a Number,Scheduled Appointment,Scheduled Follow-up,Escalated,Sent Replacement Questionnaire,Data Taken Over The Phone,Advised Data Sent';
        insert ro;
        TestDataHelper.createResponseProperties();
    }
	@isTest static void testMethodOne() {
		User userObj = TestDataHelper.createUser('Test' + datetime.now().getTime() + '@gmail.com', 'System Administrator', true);
		system.runAs(userObj) {
			Collection__c col = TestDataHelper.createCollection(true);
			Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id, true);
			Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id, true);
			User userObj1 = TestDataHelper.createUser('1Test' + datetime.now().getTime() + '@gmail.com', 'System Administrator', true);
			Contact cnt = TestDataHelper.createContact(true);
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c = 'ENXXX';
			unitObj.Address_Type__c = '--Use Workload Default--';
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			unitObj.LBU__c = false;
			unitObj.Assigned__c = false;
			insert unitObj;
			Group gr = new Group();
			gr.Name = 'Unallocated_Phone_Work_Items';
			gr.type = 'Queue';
			insert gr;
			QueueSobject testQueue = new QueueSObject(QueueId = gr.Id, SobjectType = 'Work_Item__c');
			insert testQueue;

			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
			insert resp;
			List<Work_Item__c> wiList = new List<Work_Item__c> ();
			for (integer i = 0; i < 10; i++) {
				Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
				wi.Delivery_Mode__c = 'Call';
				wi.Work_Item_Type__c = 'Courtesy contact';
				wi.Status__c = 'New';
				wi.Appointment__c = true;
				wi.Call_Back_Time__c = system.now().addDays(-1);
				wi.OwnerId = userObj1.Id;
				wi.Work_Item_ExtId__c = null;
				wiList.add(wi);
			}
			for (integer i = 0; i < 10; i++) {
				Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
				wi.Delivery_Mode__c = 'Call';
				wi.Work_Item_Type__c = 'Courtesy contact';
				wi.Status__c = 'In Progress';
				wi.Appointment__c = true;
				wi.Call_Back_Time__c = system.now().addDays(1);
				wi.OwnerId = userObj1.Id;
				wi.Work_Item_ExtId__c = null;
				wiList.add(wi);
			}
			Id queueId = [Select Id from Group where Type = 'Queue' and DeveloperName = 'Unallocated_Phone_Work_Items'].Id;
			for (integer i = 0; i < 10; i++) {
				Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
				wi.Delivery_Mode__c = 'Call';
				wi.Work_Item_Type__c = 'Courtesy contact';
				wi.Status__c = 'New';
				wi.Appointment__c = true;
				wi.Call_Back_Time__c = system.now().addDays(1);
				wi.OwnerId = queueId;
				wi.Work_Item_ExtId__c = null;
				wiList.add(wi);
			}
			insert wiList;
			wiList = [Select Id,OwnerId,Owner.Type from Work_Item__c];
			List<Work_Item__c> w1 = [Select Id from Work_Item__c where (Status__c IN ('New', 'Pending') AND Delivery_Mode__c = 'Call' AND Response__r.RecordType.Name = 'Business Response' AND (Appointment__c = TRUE OR Follow_up__c = TRUE) AND Call_Back_Time__c != NULL AND Call_Back_Time__c <= :System.now() AND OwnerId != :queueId AND Owner.Type = 'User')];
			List<Work_Item__c> w2 = [Select Id from Work_Item__c where (Status__c IN ('New', 'Pending') AND Delivery_Mode__c = 'Call' AND Response__r.RecordType.Name = 'Business Response' AND (Call_Back_Time__c <= :System.now() OR Call_Back_Time__c = NULL) AND Appointment__c = FALSE AND Follow_up__c = FALSE AND OwnerId != :queueId AND Owner.Type = 'User')];
			List<Work_Item__c> w3 = [Select Id from Work_Item__c where (Status__c IN ('New', 'Pending') AND Delivery_Mode__c = 'Call' AND Response__r.RecordType.Name = 'Business Response' AND Call_Back_Time__c <= :System.now() AND (Appointment__c = TRUE OR Follow_up__c = TRUE) AND Call_Back_Time__c != NULL AND OwnerId = :queueId)];
			List<Work_Item__c> w4 = [Select Id from Work_Item__c where (Status__c IN ('New', 'Pending') AND Delivery_Mode__c = 'Call' AND Response__r.RecordType.Name = 'Business Response' AND Call_Back_Time__c = NULL AND Appointment__c = FALSE AND Follow_up__c = FALSE AND OwnerId = :queueId)];
			List<Work_Item__c> w5 = [Select Id,owner.type FROM Work_Item__c WHERE (Status__c IN ('New', 'Pending') AND Delivery_Mode__c = 'Call' AND Response__r.RecordType.Name = 'Business Response' AND Call_Back_Time__c > :System.now() AND (OwnerId = :queueId OR Owner.Type = 'User'))];
			Test.startTest();
			WorkItemsQueueView wiq = new WorkItemsQueueView();
			wiq.workItems = wiq.getWIs();
			//System.assertEquals(wiList.size(),wiq.workItems.size());
			System.assertEquals('In Progress',wiq.workItems[0].Status__c);
			System.assertEquals(userObj1.Id,wiq.workItems[10].OwnerId);
			//System.assertEquals(queueId,wiq.workItems[20].OwnerId);
			WorkItemsQueueView.fetchWorkItem(String.valueOf(wiList[0].Id));
			Test.stopTest();
		}
	}
}