@isTest
private class WorkItemQueue_Test {
    @testSetup static void setupData(){
        Record_Outcomes__c ro = new Record_Outcomes__c();
        ro.Name = '1';
        ro.Delivery_Mode__c = 'Call';
        ro.Work_Item_Type__c = 'Courtesy contact';
        ro.Outcomes__c = 'Call Successful,Cannot Locate a Number,Scheduled Appointment,Scheduled Follow-up,Escalated,Sent Replacement Questionnaire,Data Taken Over The Phone,Advised Data Sent';
        insert ro;
        TestDataHelper.createResponseProperties();
    }
    @isTest static void assignedScheduled(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(true);
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
            Group gr = new Group();
            gr.Name = 'Unallocated_Phone_Work_Items';
            gr.type = 'Queue';
            insert gr;
            QueueSobject testQueue = new QueueSObject(QueueId = gr.Id, SobjectType = 'Work_Item__c');
            insert testQueue;
            
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
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
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = userObj.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            system.debug('wId=='+wId);
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Contact__r.Assigned__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void assigned(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(true);
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
            Group gr = new Group();
            gr.Name = 'Unallocated_Phone_Work_Items';
            gr.type = 'Queue';
            insert gr;
            QueueSobject testQueue = new QueueSObject(QueueId = gr.Id, SobjectType = 'Work_Item__c');
            insert testQueue;

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Call_Back_Time__c = null;
                wi.OwnerId = userObj1.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = null;
            wi1.OwnerId = userObj.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Contact__r.Assigned__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void appointmentScheduledFocused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-2);
            skill.Focus_Start_Date__c = system.now().addDays(-2);
            skill.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-2);
            skill1.Focus_Start_Date__c = system.now().addDays(-2);
            skill1.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-2);
            skill2.Focus_Start_Date__c = system.now().addDays(-2);
            skill2.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
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
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.Appointment__c = false;
                wi.Follow_up__c = false;
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Appointment__c = true;
            wi1.Follow_up__c = false;
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            system.debug('wi1=='+wi1.OwnerId);
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Contact__r.Assigned__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void appointmentScheduledNonFocused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-4);
            skill.Focus_Start_Date__c = system.now().addDays(-3);
            skill.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-4);
            skill1.Focus_Start_Date__c = system.now().addDays(-3);
            skill1.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-4);
            skill2.Focus_Start_Date__c = system.now().addDays(-3);
            skill2.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = true;
            unitObj.Account_Managed__c = userObj.Id;
            unitObj.Assigned__c = false;
            insert unitObj;
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Appointment__c = false;
                wi.Follow_up__c = false;
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Appointment__c = true;
            wi1.Follow_up__c = false;
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void followupScheduledFocused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-2);
            skill.Focus_Start_Date__c = system.now().addDays(-2);
            skill.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-2);
            skill1.Focus_Start_Date__c = system.now().addDays(-2);
            skill1.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-2);
            skill2.Focus_Start_Date__c = system.now().addDays(-2);
            skill2.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
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
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Follow_up__c = false;
                wi.Appointment__c = false;
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Follow_up__c = true;
            wi1.Appointment__c = false;
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            system.debug('wi1=='+wi1.OwnerId);
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Contact__r.Assigned__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void followupScheduledFocused1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-2);
            skill.Focus_Start_Date__c = system.now().addDays(-2);
            skill.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-2);
            skill1.Focus_Start_Date__c = system.now().addDays(-2);
            skill1.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-2);
            skill2.Focus_Start_Date__c = system.now().addDays(-2);
            skill2.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
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
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = true;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Follow_up__c = false;
                wi.Appointment__c = false;
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Follow_up__c = true;
            wi1.Appointment__c = false;
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Contact__r.Assigned__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void followupScheduledFocused2(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-2);
            skill.Focus_Start_Date__c = system.now().addDays(-2);
            skill.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-2);
            skill1.Focus_Start_Date__c = system.now().addDays(-2);
            skill1.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-2);
            skill2.Focus_Start_Date__c = system.now().addDays(-2);
            skill2.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = true;
            unitObj.Account_Managed__c = userObj.Id;
            unitObj.Assigned__c = false;
            insert unitObj;
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Follow_up__c = false;
                wi.Appointment__c = false;
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Follow_up__c = true;
            wi1.Appointment__c = false;
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);
        }
    }
    @isTest static void followupScheduledNonFocused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-4);
            skill.Focus_Start_Date__c = system.now().addDays(-3);
            skill.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-4);
            skill1.Focus_Start_Date__c = system.now().addDays(-3);
            skill1.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-4);
            skill2.Focus_Start_Date__c = system.now().addDays(-3);
            skill2.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = true;
            unitObj.Account_Managed__c = userObj.Id;
            unitObj.Assigned__c = false;
            insert unitObj;
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Call_Back_Time__c = system.now().addDays(1);
                wi.Follow_up__c = false;
                wi.Appointment__c = false;
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Follow_up__c = true;
            wi1.Appointment__c = false;
            wi1.Call_Back_Time__c = system.now().addDays(-1);
            wi1.OwnerId = gr.Id;
            insert wi1;
            
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
    @isTest static void Focused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-4);
            skill.Focus_Start_Date__c = system.now().addDays(-3);
            skill.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-4);
            skill1.Focus_Start_Date__c = system.now().addDays(-3);
            skill1.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-4);
            skill2.Focus_Start_Date__c = system.now().addDays(-3);
            skill2.Focus_End_Date__c = system.now().addDays(2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = true;
            unitObj.Account_Managed__c = userObj.Id;
            unitObj.Assigned__c = false;
            insert unitObj;
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp.Overall_Priority_Factor__c = 70;
            resp.Overall_Priority_Override__c = true;
            insert resp;
            Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp1.Key__c = false;
            resp1.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp1.Overall_Priority_Factor__c = 80;
            resp1.Overall_Priority_Override__c = true;
            insert resp1;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Call_Back_Time__c = null;
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                //wi.Priority__c = 99;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp1.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = null;
            wi1.OwnerId = gr.Id;
            //wi1.Priority__c = 1;
            insert wi1;
            resp1.Overall_Priority_Factor__c = 90;
            update resp1;
                        
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Id,WI_Priority__c,Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id,w.WI_Priority__c);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);
        }
    }
    @isTest static void nonFocused(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            list<Skillset__c> sk = new List<Skillset__c>();
            Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            skill.Training_Completion_Date__c = system.now().addDays(-4);
            skill.Focus_Start_Date__c = system.now().addDays(-3);
            skill.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill);
            Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Key';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            skill1.Training_Completion_Date__c = system.now().addDays(-4);
            skill1.Focus_Start_Date__c = system.now().addDays(-3);
            skill1.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill1);
            Skillset__c skill2 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill2.Skill__c = 'LBU';
            skill2.Skillset_Ext_Id__c = skill2.User_Name__c+''+skill2.Collection__c+''+skill2.Skill__c;
            skill2.Training_Completion_Date__c = system.now().addDays(-4);
            skill2.Focus_Start_Date__c = system.now().addDays(-3);
            skill2.Focus_End_Date__c = system.now().addDays(-2);
            sk.add(skill2);
            insert sk;
            sk = [Select Id,Collection__c, Skill__c,User_Name__c,Focus_Start_Date__c,Focus_End_Date__c,Training_Completion_Date__c from Skillset__c where Id in :sk];
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            User userObj1 = TestDataHelper.createUser( '1Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Contact cnt = TestDataHelper.createContact(false);
            cnt.assigned__c = false;
            insert cnt;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.LBU__c = true;
            unitObj.Account_Managed__c = userObj.Id;
            unitObj.Assigned__c = false;
            insert unitObj;
            Group gr = [Select Id from Group where DeveloperName = 'Unallocated_Phone_Work_Items' and Type='Queue'];

            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.Key__c = false;
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp.Overall_Priority_Factor__c = 70;
            resp.Overall_Priority_Override__c = true;
            insert resp;
            Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp1.Key__c = false;
            resp1.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp1.Overall_Priority_Factor__c = 80;
            resp1.Overall_Priority_Override__c = true;
            insert resp1;
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<10;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, null, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Courtesy contact';
                wi.Status__c = 'New';
                wi.Call_Back_Time__c = null;
                wi.OwnerId = gr.Id;
                wi.Work_Item_ExtId__c = null;
                //wi.Priority__c = i;
                wiList.add(wi);
            }
            insert wiList;
            Work_Item__c wi1 = TestDataHelper.createWorkItem(actSch.Id, NULL, NULL, resp1.Id, null, false);
            wi1.Delivery_Mode__c = 'Call';
            wi1.Work_Item_Type__c = 'Courtesy contact';
            wi1.Status__c = 'New';
            wi1.Call_Back_Time__c = null;
            wi1.OwnerId = gr.Id;
            //wi1.Priority__c = 11;
            insert wi1;
            resp1.Overall_Priority_Factor__c = 90;
            update resp1;
            Response__c r = [Select Id,Overall_Priority__c from Response__c where Id = :resp1.Id];
            String wId = WorkItemQueue.fetchWorkItem();
            Work_Item__c w = [Select Status__c,Contact__c,Contact__r.Assigned__c,Response__c,Response__r.Overall_Priority__c,Response__r.Unit_of_Interest__c,Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where Id = :wId];
            system.assertEquals(wi1.Id,w.Id,w.Response__r.Overall_Priority__c+'=='+r.Overall_Priority__c);
            system.assertEquals('In Progress', w.Status__c);
            system.assertEquals(true,w.Response__r.Unit_of_Interest__r.Assigned__c);

        }
    }
}