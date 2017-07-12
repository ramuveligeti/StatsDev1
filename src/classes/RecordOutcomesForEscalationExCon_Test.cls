/**
* @author steven.zhu@stats.govt.nz.dev1
* @description remark updated unit test for ECP-3606,3730, 3651
*/
@isTest
private class RecordOutcomesForEscalationExCon_Test {
    @testSetup static void setupData(){
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;
        List<Escalation_Outcomes__c> eol = new List<Escalation_Outcomes__c>();
        Escalation_Outcomes__c ro = new Escalation_Outcomes__c(Delivery_Mode__c = 'Call');
        ro.Name = '1';
        ro.Escalation_Reason__c = 'Ceased,Out of Scope for the Collection,Potential Burden Exclusion Request,Compassionate Exclusion Request,Extension (Beyond Extension Cut-off Date),Complaint,Refusal,Business Structural Changes,AOS Change of Ownership';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Decision__c = 'Referred to CSR for follow-up';
        ro.Call_back__c = true;
        ro.Extension__c = true;
        eol.add(ro);
        ro = new Escalation_Outcomes__c(Delivery_Mode__c = 'Call');
        ro.Name = '2';
        ro.Escalation_Reason__c = 'Ceased,Complaint,Refusal,Business Structural Changes,AOS Change of Ownership,Feedback';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue,CC_Admin_Team_Queue,Supplier_Management_Advisers_Queue,Managers_Escalation_Queue';
        ro.Decision__c = 'Resolved';
        ro.Next_Step__c = 'Schedule Follow-Up';
        ro.Assign_to__c = 'Unallocated_Phone_Work_Items';
        ro.Call_back__c = true;
        ro.Extension__c = true;
        eol.add(ro);
        ro = new Escalation_Outcomes__c(Delivery_Mode__c = 'Call');
        ro.Name = '3';
        ro.Escalation_Reason__c = 'Ceased,Complaint,Refusal,Business Structural Changes,AOS Change of Ownership,Feedback';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue,CC_Admin_Team_Queue,Supplier_Management_Advisers_Queue,Managers_Escalation_Queue';
        ro.Decision__c = 'Resolved';
        ro.Next_Step__c = 'No further action required';
        ro.Assign_to__c = null;
        ro.Status__c = 'Completed';
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '4';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Out of Scope for the Collection';
        ro.Decision__c = 'Approved';
        ro.Next_Step__c = null;
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Status__c = 'Completed';
        ro.Response_Status__c = 'Closed';
        ro.Response_Status_Reason__c = 'Out of Scope';
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '5';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Out of Scope for the Collection,Potential Burden Exclusion Request,Compassionate Exclusion Request,Extension (Beyond Extension Cut-off Date)';
        ro.Decision__c = 'Declined';
        ro.Next_Step__c = 'Escalate: Refusal';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Supplier_Management_Advisers_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '6';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Out of Scope for the Collection,Potential Burden Exclusion Request,Compassionate Exclusion Request,Extension (Beyond Extension Cut-off Date)';
        ro.Decision__c = 'Declined';
        ro.Next_Step__c = 'Escalate: Complaint';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Supplier_Management_Advisers_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '7';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Out of Scope for the Collection,Potential Burden Exclusion Request,Compassionate Exclusion Request';
        ro.Decision__c = 'Declined';
        ro.Next_Step__c = 'Schedule Follow-Up';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Unallocated_Phone_Work_Items';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = true;
        ro.Extension__c = true;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '8';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Extension (Beyond Extension Cut-off Date)';
        ro.Decision__c = 'Approved';
        ro.Next_Step__c = null;
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Unallocated_Phone_Work_Items';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = true;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '9';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Extension (Beyond Extension Cut-off Date)';
        ro.Decision__c = 'Declined';
        ro.Next_Step__c = 'New Extension Date Agreed On';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Unallocated_Phone_Work_Items';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = true;
        ro.Extension__c = true;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '10';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'Escalate: Refusal';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Supplier_Management_Advisers_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '11';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'Escalate: Complaint';
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = 'Supplier_Management_Advisers_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '12';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal,Feedback';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'No further action required';
        ro.Owner__c = 'Supplier_Management_Advisers_Queue,Managers_Escalation_Queue';
        ro.Assign_to__c = null;
        ro.Status__c = 'Completed';
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '13';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'Refusal';
        ro.Owner__c = 'Supplier_Management_Advisers_Queue,Managers_Escalation_Queue';
        ro.Assign_to__c = null;
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '14';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal,Feedback';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'Escalate to Contact Centre Manager';
        ro.Owner__c = 'Supplier_Management_Advisers_Queue';
        ro.Assign_to__c = 'Managers_Escalation_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '15';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Complaint,Refusal,Feedback';
        ro.Decision__c = 'Unresolved';
        ro.Next_Step__c = 'Escalate to Field Collections Manager';
        ro.Owner__c = 'Supplier_Management_Advisers_Queue';
        ro.Assign_to__c = 'Managers_Escalation_Queue';
        ro.Status__c = null;
        ro.Response_Status__c = null;
        ro.Response_Status_Reason__c = null;
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '16';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Potential Burden Exclusion Request';
        ro.Decision__c = 'Approved';
        ro.Next_Step__c = null;
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = null;
        ro.Status__c = 'Completed';
        ro.Response_Status__c = 'Closed';
        ro.Response_Status_Reason__c = 'Burden Exclusion';
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        ro = new Escalation_Outcomes__c();
        ro.Name = '17';
        ro.Delivery_Mode__c = 'Call';
        ro.Escalation_Reason__c = 'Compassionate Exclusion Request';
        ro.Decision__c = 'Approved';
        ro.Next_Step__c = null;
        ro.Owner__c = 'CC_Escalation_Queue,LBU_Escalation_Queue';
        ro.Assign_to__c = null;
        ro.Status__c = 'Completed';
        ro.Response_Status__c = 'Closed';
        ro.Response_Status_Reason__c = 'Compassionate Exclusion';
        ro.Call_back__c = false;
        ro.Extension__c = false;
        eol.add(ro);
        insert eol;
        TestDataHelper.createResponseProperties();
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
        wi1.Escalation_Reason__c = 'Ceased';
        wi1.Status__c = 'New';
        wi1.Approval_Status__c='Awaiting for Approval';
        wi1.Call_Back_Time__c = system.now().addDays(-1);
        wi1.OwnerId = userObj.Id;
        insert wi1;
    }
    @isTest static void phoneEscalationQueueTest_Ceased(){
        Work_Item__c w = [Select Id,Escalation_Reason__c,Response_Extension_Date__c,Contact__r.Notes__c,Response__r.Unit_of_Interest__r.Notes__c,
                          Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,
                          Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,
                          Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c ];
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Group gr = [Select Id from Group where DeveloperName = 'CC_Escalation_Queue' and Type='Queue'];
        w.OwnerId = gr.Id;
		w.Queue_Id__c = gr.Id;
        update w;
        test.startTest();
        ApexPages.StandardController stdCont = new ApexPages.StandardController(w);
        RecordOutcomesForEscalationExCon roe = new RecordOutcomesForEscalationExCon(stdCont);
        roe.queueOfTheUser = 'CC_Escalation_Queue';   
        roe.fetchDecision();
        roe.workItem.Decision__c = 'Referred to CSR for follow-up';
        roe.fetchNextStep();
        system.assertEquals(null, roe.workItem.Next_Step__c);
        roe.workItem.OwnerId = userObj.Id;
        roe.save();
        system.assertEquals(userObj.Id, roe.workItem.OwnerId);

        roe.workItem.Decision__c = 'Resolved';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'Schedule Follow-Up';
        roe.checkDependentsOnNextStep();
		roe.workItem.New_Call_Back_Time__c = system.now().addDays(2);
        roe.save();
        gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];
        system.assertEquals(gr.Id,roe.workItem.OwnerId);

        roe.workItem.Decision__c = 'Resolved';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'No further action required';
        roe.checkDependentsOnNextStep();
        roe.save();
        system.assertEquals('Completed',roe.workItem.Status__c);
        test.stopTest();
    }
    
    @isTest static void phoneEscalationQueueTest_OutofScope(){
        Work_Item__c w = [Select Id,Escalation_Reason__c,Response_Extension_Date__c,Contact__r.Notes__c,Response__r.Unit_of_Interest__r.Notes__c,
                          Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,
                          Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,
                          Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c ];
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Group gr = [Select Id from Group where DeveloperName = 'CC_Escalation_Queue' and Type='Queue'];
        w.OwnerId = gr.Id;
		w.Queue_Id__c = gr.Id;
        w.Escalation_Reason__c = 'Out of Scope for the Collection';
        update w;
        test.startTest();
        ApexPages.StandardController stdCont = new ApexPages.StandardController(w);
        RecordOutcomesForEscalationExCon roe = new RecordOutcomesForEscalationExCon(stdCont);
        roe.queueOfTheUser = 'CC_Escalation_Queue';    
        roe.fetchDecision();
        roe.workItem.Decision__c = 'Approved';
        roe.fetchNextStep();
        system.assertEquals(null, roe.workItem.Next_Step__c);
        roe.save();
        system.assertEquals('Completed',roe.workItem.Status__c);

        roe.workItem.Decision__c = 'Declined';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'Escalate: Refusal';
        roe.save();

        gr = [Select Id from Group where DeveloperName = 'Supplier_Management_Advisers_Queue' and Type='Queue'];
        system.assertEquals(gr.Id,roe.workItem.OwnerId);

        roe.workItem.Decision__c = 'Declined';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'Schedule Follow-Up';
        roe.checkDependentsOnNextStep();
		roe.workItem.New_Call_Back_Time__c = system.now().addDays(2);
        roe.save();
        gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];
        system.assertEquals(gr.Id,roe.workItem.OwnerId);
        test.stopTest();
    }

    @isTest static void phoneEscalationQueueTest_Escalation(){
        Work_Item__c w = [Select Id,Escalation_Reason__c,Response_Extension_Date__c,Contact__r.Notes__c,Response__r.Unit_of_Interest__r.Notes__c,
                          Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,
                          Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,
                          Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c ];
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Group gr = [Select Id from Group where DeveloperName = 'CC_Escalation_Queue' and Type='Queue'];
        w.OwnerId = gr.Id;
		w.Queue_Id__c = gr.Id;
        w.Requested_Extension_Date__c = system.today().addDays(12);
        w.Escalation_Reason__c = 'Extension (Beyond Extension Cut-off Date)';
        update w;
        test.startTest();
        ApexPages.StandardController stdCont = new ApexPages.StandardController(w);
        RecordOutcomesForEscalationExCon roe = new RecordOutcomesForEscalationExCon(stdCont);
		roe.queueOfTheUser = 'CC_Escalation_Queue'; 
        roe.fetchDecision();
        roe.workItem.Decision__c = 'Approved';
        roe.fetchNextStep();
        system.assertEquals(null, roe.workItem.Next_Step__c);
        roe.save();
        system.assertEquals(system.today().addDays(12), roe.workItem.Requested_Extension_Date__c);
        gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];
        system.assertEquals(gr.Id,roe.workItem.OwnerId);
        Response__c r = [Select Id,Extension_Date__c,Extension_Past_Cut_Off__c from Response__c];
        system.assertEquals(r.Extension_Date__c,roe.workItem.Requested_Extension_Date__c);
		System.assert(r.Extension_Past_Cut_Off__c);
		
        Task ts = [Select Id,New_Call_Back_Time__c from Task where whatId = :roe.workItem.Id];
		system.assert(ts.New_Call_Back_Time__c==roe.workItem.New_Call_Back_Time__c);
        test.stopTest();
    }

    @isTest static void rmaTeamQueueTest(){
        Work_Item__c w = [Select Id,Escalation_Reason__c,Response_Extension_Date__c,Contact__r.Notes__c,Response__r.Unit_of_Interest__r.Notes__c,
                          Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,
                          Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,
                          Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c ];
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Group gr = [Select Id from Group where DeveloperName = 'Supplier_Management_Advisers_Queue' and Type='Queue'];
        w.OwnerId = gr.Id;
		w.Queue_Id__c = gr.Id;
        w.Escalation_Reason__c = 'Complaint';
        update w;
        test.startTest();
        ApexPages.StandardController stdCont = new ApexPages.StandardController(w);
        RecordOutcomesForEscalationExCon roe = new RecordOutcomesForEscalationExCon(stdCont);
        roe.queueOfTheUser = 'Supplier_Management_Advisers_Queue';
        roe.fetchDecision();
        roe.workItem.Decision__c = 'Unresolved';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'Escalate to Contact Centre Manager';
        roe.checkDependentsOnNextStep();
        roe.save();

        gr = [Select Id from Group where DeveloperName = 'Managers_Escalation_Queue' and Type='Queue'];
        system.assertEquals(gr.Id,roe.workItem.OwnerId);
        test.stopTest();
    }
    @isTest static void managerTeamQueueTest(){
        Work_Item__c w = [Select Id,Escalation_Reason__c,Response_Extension_Date__c,Contact__r.Notes__c,Response__r.Unit_of_Interest__r.Notes__c,
                          Response__r.Unit_of_Interest__c,Response__r.Contact__c,Approval_Status__c,Response__r.Collection_Instance__r.Extension_Cut_off_Date__c,
                          Delivery_Mode__c,Work_Item_Type__c,Response__r.Extension_Date__c,Response__r.RecordType.Name,Response__r.Unit_of_Interest__r.LBU__c,
                          Response__r.Unit_of_Interest__r.Assigned__c,Response__c,Contact__r.Assigned__c,Name from Work_Item__c ];
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Group gr = [Select Id from Group where DeveloperName = 'Managers_Escalation_Queue' and Type='Queue'];
        w.OwnerId = gr.Id;
		w.Queue_Id__c = gr.Id;
        w.Escalation_Reason__c = 'Feedback';
        update w;
        test.startTest();
        ApexPages.StandardController stdCont = new ApexPages.StandardController(w);
        RecordOutcomesForEscalationExCon roe = new RecordOutcomesForEscalationExCon(stdCont);
        roe.queueOfTheUser = 'Managers_Escalation_Queue';
        roe.fetchDecision();
        roe.workItem.Decision__c = 'Unresolved';
        roe.fetchNextStep();
        roe.workItem.Next_Step__c = 'No further action required';
        roe.checkDependentsOnNextStep();
        roe.save();

        system.assertEquals('Completed',roe.workItem.Status__c);
        test.stopTest();
    }
}