@isTest
private class TaskTriggerHandler_Test {
	@testSetup static void setupData(){
		TestDataHelper.createWrapupCodes();
		TestDataHelper.createResponseProperties();

		Case_Update_Properties__c[] config= new Case_Update_Properties__c[]{
			new Case_Update_Properties__c(name='case.status.closed',value__c='whatever'),
			new Case_Update_Properties__c(name='workitem.status.closed',value__c='whatever')
		};
		insert config;
		

		Work_Item_Outcomes_Config__c wio = new Work_Item_Outcomes_Config__c();
		wio.Name = 'Census';
		wio.Follow_up_Outcomes__c = 'Sent Replacement Questionnaire,Advised Data Sent,Scheduled Appointment,Scheduled Follow-up';
		insert wio;
		Work_Item_Outcomes_Config__c wio1 = new Work_Item_Outcomes_Config__c();
		wio1.Name = 'Business';
		wio1.Follow_up_Outcomes__c = 'Call back required,Sent Replacement Questionnaire,Advised Data Sent,Scheduled Appointment,Scheduled Follow-up';
		insert wio1;

		System_Update__c su = System_Update__c.getOrgDefaults();
		su.Execute__c = false;
		upsert su;

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
		resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		resp.Workflow_status__c='Eric';
		resp.survey_unit__c=unitObj.id;
		insert resp;
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.work_item_type__c = 'List leave';
		wi.Status__c = 'New';
		insert wi;
		
		Contact testCaller = new Contact(lastname='Test', firstname='hello');
		insert testCaller;
	}

	@isTest static void testCreateNewTaskOnWorkItem(){
		Work_Item__c wi = [select id from Work_Item__c];
		Response__c resp = [select id from Response__c];
		Contact cnt=[select id from Contact];
		Unit__c unit=[select id, name, Unit_of_Interest_ID__c from Unit__c];
		test.startTest();
		Task t=TestDataHelper.createTask(wi.Id, false);
		t.whoId = cnt.id;
		insert t;
		test.stopTest();
		t = [Select Response__c, system_contact__c, collection_unit__c, survey_unit__c, survey_Unit_ID__c from task];
		system.assertEquals(resp.Id, t.Response__c);
		system.assertEquals(unit.Id, t.collection_unit__c);
		system.assertEquals(unit.Name, t.survey_unit__c);
		system.assertEquals(unit.Unit_of_Interest_ID__c, t.Survey_Unit_ID__c);
		system.assertEquals(cnt.Id, t.system_contact__c);
	}

	@isTest static void testCreateNewTaskWithoutWhatid(){
		test.startTest();
		TestDataHelper.createTask(null, true);
		test.stopTest();
		task t = [Select Response__c from task];
		system.assertEquals(null, t.Response__c);
	}


	@isTest static void testCreateNewTaskOnCase(){
		Response__c resp = [select id from Response__c];
		
		Case cc= new Case();
		cc.Response__c = resp.id;
		cc.subject = 'CSR manually enter activity';
		insert cc;
		
		test.startTest();
		TestDataHelper.createTask(cc.Id, true);
		test.stopTest();
		
		task t = [Select Response__c from task];
		system.assertEquals(resp.Id, t.Response__c);
	}


	@isTest static void test_nonCensusCase_WrapUpSNQ(){
		Response__c resp = [select id from Response__c];
		
		Case cc= new Case();
		cc.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
		cc.Response__c = resp.id;
		cc.subject = 'snq';
		cc.Request_Code__c = 'Questionnaire Required';
		cc.Wrap_Up_Code__c = 'Close Call';
		insert cc;
				
		task[] t = [Select Response__c from task];
		system.assertEquals(0,t.size());
	}


	@isTest static void testCaseWrapUpSNQ(){
		Response__c resp = [select id from Response__c];
		
		Case cc= new Case();
		cc.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Census Case').getRecordTypeId();
		cc.Response__c = resp.id;
		cc.subject = 'snq';
		cc.Request_Code__c = 'Questionnaire Required';
		cc.Wrap_Up_Code__c = 'Close Call';
		insert cc;
				
		task t = [Select whatid,Response__c from task];
		system.assertEquals(resp.Id, t.Response__c);
		system.assertEquals(resp.Id, t.whatid);
	}


	@isTest static void testCaseWrapUpRefusal(){
		Response__c resp = [select id from Response__c];
		
		Case cc= new Case();
		cc.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Census Case').getRecordTypeId();
		cc.Response__c = resp.id;
		cc.subject = 'refuasl';
		cc.Request_Code__c = 'Refusal';
		cc.Wrap_Up_Code__c = 'Close Call';
		insert cc;
				
		task t = [Select whatid, subject, Response__c from task];
		system.assertEquals(resp.Id, t.Response__c);
		system.assertEquals(resp.Id, t.whatid);
	}

	@isTest static void testWINotes(){
		Work_Item__c wi = [select id from Work_Item__c];
		Response__c resp = [select id from Response__c];
		List<Task> ts = new List<Task>();
		for(integer i=0; i<4; i++){
			task t = TestDataHelper.createTask(wi.Id, false);
			t.Description = 'Notes '+i;
			t.Outcome__c = 'Esacalated';
			ts.add(t);
		}
		insert ts;
		test.startTest();
		task t1 = TestDataHelper.createTask(wi.Id, false);
		t1.Description = 'Notes 4';
		t1.Outcome__c = 'Esacalated';
		insert t1;
		System.debug('t1=='+t1.Outcome__c);
		test.stopTest();
		ts = [Select Id from Task];
		System.assertEquals(5,ts.size());
		wi = [Select ID,Notes__c from Work_Item__c];
		System.debug('aaaa==='+wi.Notes__c);
		System.assert(wi.Notes__c.containsIgnoreCase('Notes 0'));
		System.assert(wi.Notes__c.containsIgnoreCase('Notes 1'));
		System.assert(wi.Notes__c.containsIgnoreCase('Notes 2'));
		System.assert(wi.Notes__c.containsIgnoreCase('Notes 3'));
		System.assert(wi.Notes__c.containsIgnoreCase('Notes 4'));
	}

	@isTest static void testFeedbackEscalation(){
		Work_Item__c wi = [select id from Work_Item__c];
		Response__c resp = [select id from Response__c];
		List<Task> ts = new List<Task>();
		task t1 = TestDataHelper.createTask(wi.Id, false);
		t1.Description = 'Notes 4';
		t1.escalated__c = true;
		t1.Escalation_Reason__c = 'Feedback';
		t1.Feedback_Type__c = 'Questionnaire design';
		insert t1;
		System.debug('t1=='+t1.Outcome__c);
		test.startTest();
		t1.Decision__c='Unresolved';
		t1.Next_Step__c = 'Esacalte to Contact Centre';
		update t1;
		test.stopTest();
		ts = [Select Id,Status from Task where Id=:t1.Id];
		System.assertEquals(ts[0].Status,'Completed');
		ts = [Select Id,Status from Task where Id!=:t1.Id];
		System.assertEquals(ts[0].Status,'Open');
	}
	@isTest static void testFeedbackEscalationMulti(){
		Work_Item__c wi = [select id from Work_Item__c];
		Response__c resp = [select id from Response__c];
		List<Task> ts = new List<Task>();
		task t1 = TestDataHelper.createTask(wi.Id, false);
		t1.Description = 'Notes 4';
		t1.escalated__c = true;
		t1.Escalation_Reason__c = 'Feedback';
		t1.Feedback_Type__c = 'Questionnaire design';
        t1.Multi_Escalate_Feedback_Id__c = 'abc';
		insert t1;
		task t2 = TestDataHelper.createTask(wi.Id, false);
		t2.Description = 'Notes 4';
        t2.Multi_Escalate_Feedback_Id__c = 'abc';
        t2.Status = 'Open';
		insert t2;
		System.debug('t1=='+t1.Outcome__c);
		test.startTest();
		t1.Decision__c='Unresolved';
		t1.Next_Step__c = 'Esacalte to Contact Centre';
		update t1;
		test.stopTest();
		ts = [Select Id,Status from Task where Id=:t1.Id];
		System.assertEquals(ts[0].Status,'Completed');
		ts = [Select Id,Status from Task where Id!=:t1.Id and Id != :t2.Id];
		System.assertEquals(ts[0].Status,'Open');
        task ts1=[Select Id,Status from Task where Id = :t2.Id];
        System.assertEquals(ts1.Status,'Completed');
	}
}