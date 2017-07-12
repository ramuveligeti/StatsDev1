/**
* @description   Test class for the WorkItemTriggerHandler Class
* @author       Ram Veligeti
* @date       10.04.2015
*/
/**
* Amendment -  Caterina Cuccurullo 22 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
*/
      
@isTest
private class WorkItemTriggerHandler_Test {
    @testSetup static void setupData(){
        TestDataHelper.createWrapupCodes();
        TestDataHelper.createResponseProperties();
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
    }

    //Test Method for createCallBackWorkItems() Method 
    @isTest static void createCallBackWorkItemsTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            
            Contact cnt = TestDataHelper.createContact(true);
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, null, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;
            Workload__c workLoad = TestDataHelper.createWorkLoad(colIns.Id, true);
            Workload__c workLoadNew = TestDataHelper.createWorkLoad(colIns.Id, true);
            test.startTest();
            Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, workLoad.Id, false);
            wi.Delivery_Mode__c = 'Call';
            wi.Work_Item_Type__c = 'Pre-notification';
            wi.Core_Result__c = 'No contact made';
            wi.Outcome__c = 'Call back required';
            wi.Action__c = 'Send email';
            wi.Status__c = 'New';
            insert wi;
            system.assertEquals(workLoad.OwnerId, wi.OwnerId);
            wi.Status__c = 'In Progress';
            wi.New_Call_Back_Time__c = system.now().addDays(1);
            update wi;
            List<Work_Item__c> wl = [Select Id,Status__c,Work_Item_ExtId__c,Default_Call_Back_Time__c,Core_Result__c,Outcome__c,Action__c,Call_Back_Time__c from Work_Item__c where id = :wi.Id];
            system.assertEquals(1,wl.size());
            system.assertEquals('In Progress',wl[0].Status__c);
            //system.assertEquals(null,wl[0].Work_Item_ExtId__c);
            //system.assertEquals(null,wl[0].Default_Call_Back_Time__c);
            //system.assertEquals(null,wl[0].Core_Result__c);
            system.assertEquals(wi.Outcome__c,wl[0].Outcome__c);
            //system.assertEquals(null,wl[0].Action__c);
            system.assertEquals(wi.New_Call_Back_Time__c.date(),wl[0].Call_Back_Time__c.date().addDays(1));
            wl[0].Status__c = 'Completed';
            wl[0].Workload__c = workLoadNew.Id;
            update wl;
            system.assertEquals('Not Started', workLoadNew.Workload_Status__c);
            test.stopTest();
        }
    }
    
    //Bulk Test Method for createCallBackWorkItems() Method 
    @isTest static void bulkCreateCallBackWorkItemsTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            
            Contact cnt = TestDataHelper.createContact(true);
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, null, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert resp;

            Workload__c workLoad = TestDataHelper.createWorkLoad(colIns.Id, true);
            test.startTest();
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<200;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, workLoad.Id, false);
                wi.Delivery_Mode__c = 'Call';
                wi.Work_Item_Type__c = 'Pre-notification';
                wi.Core_Result__c = 'No contact made';
                wi.Outcome__c = 'Call back required';
                wi.Action__c = 'Send email';
                wi.Status__c = 'New';
                wi.Work_Item_ExtId__c = 'test'+i;
                wiList.add(wi);
            }
            insert wiList;
            for(Work_Item__c wi: wiList){
                wi.Status__c = 'In Progress';
                wi.New_Call_Back_Time__c = system.now().addDays(1);
            }
            update wiList;
            List<Work_Item__c> wi = [Select Id,Status__c,Response__c from Work_Item__c where Status__c = 'In Progress' and id in :wiList];
            system.assertEquals(200,wi.size(),wiList.size());
            for(Work_Item__c w: wi){
                //w.Status__c = 'New';
                w.Approval_Status__c = 'Approved';
                w.Requested_Extension_Date__c = system.today().addDays(10);
            }
            update wi;
            //List<Work_Item__c> wi1 = [Select Id,Status__c,Response__c from Work_Item__c where id not in :wiList and id not in :wi];
            //system.assertEquals(200,wi1.size());
            resp = [Select Id,Extension_Date__c from Response__c where Id = :resp.Id];
            //system.assertEquals(wi[0].Requested_Extension_Date__c,resp.Extension_Date__c);
            test.stopTest();
            Workload__c wl = [Select Id,Workload_Status__c from Workload__c where Id = :workLoad.Id];
            //system.assertEquals('Complete', wl.Workload_Status__c);
        }
    }

    public static testmethod void testIsWorkItemTypeValid(){
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Pre-notification'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Questionnaire'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Courtesy contact'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Reminder'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Non-response follow-up'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Replacement questionnaire'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Address canvassing'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('List leave'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Access code'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Statsgate link'));
        System.assert(WorkItemTriggerHandler.isWorkItemTypeValid('Inbound Enquiry'));


        System.assert(!WorkItemTriggerHandler.isWorkItemTypeValid('test'));
        System.assert(!WorkItemTriggerHandler.isWorkItemTypeValid('whatever'));
        System.assert(!WorkItemTriggerHandler.isWorkItemTypeValid('questionnaire'));
        System.assert(!WorkItemTriggerHandler.isWorkItemTypeValid('non-response follow-up'));
        System.assert(!WorkItemTriggerHandler.isWorkItemTypeValid('Access Code'));
    }

    public static testmethod void testValidateWorkitems(){
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
        Work_Item__c item1 = new Work_Item__c();
        item1.Work_Item_Type__c = 'Address canvassing';
        item1.response__c = resp.Id;

        Work_Item__c item2 = new Work_Item__c();
        item2.Work_Item_Type__c = 'Address canvassing bad';
        item2.response__c = resp.Id;

        List<Work_Item__c> items = new List<Work_Item__c>();
        items.add(item1);
        items.add(item2);

        //WorkItemTriggerHandler.validateWorkitems(items);

        try{
            insert item1;
            System.assert(true);
        }catch(Exception e){
            System.assert(false);
        }

        try{
            item1.Work_Item_Type__c = 'bad type';
            update item1;
            System.assert(false);
        }catch(Exception e){
            System.assert(true);
        }

        try{
            insert item2;
            System.assert(false);
        }catch(Exception e){
            System.assert(true);
        }
    }
    
    @isTest static void ContactAssignmentTest(){
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert col;
        
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;

        Contact[]contacts=new Contact[]{};
        for(integer i=0; i<10; i++){
            Contact c = new Contact(lastName='Parker'+i, firstName='Peter');
            contacts.add(c);
        }
        insert contacts;
        
        Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        Unit__c[]units=new Unit__c[]{};
        for(integer i=0; i<10; i++){
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.recordtypeid=uRT;
            unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
            unitObj.Address_Type__c = null;
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '1234';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c='11';
            unitObj.DP_ID__c=''+(10000+i);
            units.add(unitObj);
        }
        insert units;
        Response__c[]resps=new Response__c[]{};
        for(integer i=0; i<10; i++){
            Response__c resp = TestDataHelper.createResponse(colIns.Id, contacts[i].id, null, units[i].Id, false);
            resp.recordTypeId=rRT;
            resp.Status__c = 'New';
            resp.Unit_Type__c = null;
            resp.Delivery_Unit_Number__c = null;
            resp.Response_ExtId__c = 'EricTestwhatever'+i;
            resp.Workflow_status__c=null;
            resp.Document_Number__c = null;
            resp.access_code__c=null;
            resp.collection_mode__c = 'SCER';
            resp.contact__c = null;
            resp.survey_unit__c = units[i].id;
            resps.add(resp);
        }
        insert resps;
        
        Response__c[]vResps=[select id, contact__c from Response__c];
        for(integer i=0; i<10; i++){
            vResps[i].contact__c=contacts[i].id;
        }
        vResps[7].contact__c=null;
        vResps[9].contact__c=null;
        update vResps;
        
        for(integer i=0; i<10; i++){
            if( i==7 || i==9 ){
                system.assertEquals(null, vResps[i].contact__c);
            }else{
                system.assertEquals(contacts[i].id, vResps[i].contact__c, 'row '+i);
            }
        }
        
        Test.startTest();
        Work_Item__c[]wis=new Work_Item__c[]{};
        for(integer i=0; i<10; i++){
            Work_Item__c wi = TestDataHelper.createWorkItem(null, null, null, resps[i].Id, null, false);
            wi.Delivery_Mode__c = 'Call';
            wi.Work_Item_Type__c = 'Pre-notification';
            wi.Work_Item_ExtId__c = 'testingEric123'+i;
            wis.add(wi);
        }
        wis[3].Delivery_Mode__c='Fax';
        insert wis;
        Test.stopTest();
        
        Work_Item__c[] verifications=[select id, contact__c from Work_Item__c];
        system.assertEquals(10, verifications.size());
        for(integer i=0; i<10; i++){
            if( i==3 || i==7 || i==9 ){
                system.assertEquals(null, verifications[i].contact__c);
            }else{
                system.assertEquals(contacts[i].id, verifications[i].contact__c, 'row '+i);
            }
        }
    }
    
    
    @isTest 
    static void BusinessWorkItemResponseUpdate(){
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert col;
        
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;

        Contact[]contacts=new Contact[]{};
        for(integer i=0; i<10; i++){
            Contact c = new Contact(lastName='Parker'+i, firstName='Peter');
            contacts.add(c);
        }
        insert contacts;
        
        Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        Unit__c[]units=new Unit__c[]{};
        for(integer i=0; i<10; i++){
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.recordtypeid=uRT;
            unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
            unitObj.Address_Type__c = null;
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '1234';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c='11';
            unitObj.DP_ID__c=''+(10000+i);
            units.add(unitObj);
        }
        insert units;
        Response__c[]resps=new Response__c[]{};
        for(integer i=0; i<10; i++){
            Response__c resp = TestDataHelper.createResponse(colIns.Id, contacts[i].id, null, units[i].Id, false);
            resp.recordTypeId=rRT;
            resp.Status__c = 'Loaded';
            resp.Unit_Type__c = null;
            resp.Delivery_Unit_Number__c = null;
            resp.Response_ExtId__c = 'EricTestwhatever'+i;
            resp.Workflow_status__c=null;
            resp.Document_Number__c = null;
            resp.access_code__c=null;
            resp.collection_mode__c = 'SCER';
            resp.contact__c = null;
            resp.survey_unit__c = units[i].id;
            resps.add(resp);
        }
        insert resps;
        Work_Item__c[]wis=new Work_Item__c[]{};
        for(integer i=0; i<10; i++){
            Work_Item__c wi = TestDataHelper.createWorkItem(null, null, null, resps[i].Id, null, false);
            wi.Delivery_Mode__c = 'Post';
            wi.Work_Item_Type__c = (Math.mod(i,2)==0)?'Questionnaire':'Access Code';
            wi.Work_Item_ExtId__c = 'testingEric123'+i;
            wi.status__c='New';
            wis.add(wi);
        }
        for(integer i=0; i<10; i++){
            Work_Item__c wi = TestDataHelper.createWorkItem(null, null, null, resps[i].Id, null, false);
            wi.Delivery_Mode__c = 'Post';
            wi.Work_Item_Type__c = 'Pre-notification';
            wi.Work_Item_ExtId__c = 'testingEric123x'+i;
            wi.status__c='New';
            wis.add(wi);
        }
        insert wis;

        Test.startTest();
        for(integer i=10; i<20; i++){
            wis[i].status__c='Completed';
        }
        update wis;

        Response__c[]vrs=[select id, status__c from Response__c];       
        system.assertEquals(10, vrs.size());
        for(Response__c v:vrs){
            system.assertEquals('Loaded', v.status__c);
        }

        for(integer i=0; i<10; i++){
            wis[i].status__c='Completed';
        }
        update wis;

        vrs=[select id, status__c from Response__c];        
        system.assertEquals(10, vrs.size());
        for(Response__c v:vrs){
            system.assertEquals('In Progress', v.status__c);
        }
        Test.stopTest();
    }
}