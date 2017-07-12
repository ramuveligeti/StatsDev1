@istest
private class WorkitemWorkflowTest {
/* Commented the test class as this logic is moved from trigger to process builder - Ramu Veligeti - 15/08/16      
@testSetup
    private static void setupTest(){
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
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Work_Item_ExtId__c = 'TEST1';
        wi.Delivery_Mode__c = 'TEST1';
        wi.work_item_type__c = 'List leave';
        wi.Status__c = 'New';
        insert wi;
    }


    @isTest
    private static void test_AccType_Action1(){     
        Unit__c u = [select id from Unit__c];
        u.Address_Type__c='Private Dwelling';
        update u;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c);// set to null if there is no further action
    }  


    @isTest
    private static void test_AccType_Action3(){
        Unit__c u = [select id from Unit__c];
        u.Address_Type__c='Commercial';
        update u;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Out of Scope', vR.workflow_status__c);
    }  

    @isTest
    private static void test_OccStatus_Action1(){
        Response__c r=[select id from Response__c];
        r.occupancy_status__c='Occupied';
        update r;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c);// leave for next action to set
    }  

    @isTest
    private static void test_OccStatus_Action2(){
        Response__c r=[select id from Response__c];
        r.occupancy_status__c=null;
        update r;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c);
    }  

    @isTest
    private static void test_OccStatus_Action3(){
        Response__c r=[select id from Response__c];
        r.occupancy_status__c='Unoccupied - vacant dwelling';
        update r;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Unoccupied', vR.workflow_status__c);
    }  


    @isTest
    private static void test_WIType_Action1(){
        Response__c r=[select id from Response__c];
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, r.Id, null, false);
        wi.Work_Item_ExtId__c = 'T1';
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'List Leave';
        wi.Status__c = 'New';
        insert wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c);
    }  

    @isTest
    private static void test_WIType_Action2(){      
        Response__c r=[select id from Response__c];
        
        test.startTest();
        WorkItemTriggerHandler.workflowExecuted=false;
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, r.Id, null, false);
        wi.Work_Item_ExtId__c = 'T1';
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'Access Code';
        wi.Status__c = 'New';
        insert wi;

        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c);
    }  

    @isTest
    private static void test_WIType_Action3(){      
        Response__c r=[select id from Response__c];
        
        test.startTest();
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, r.Id, null, false);
        wi.Work_Item_ExtId__c = 'T1';
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'Access Code';
        wi.Status__c = 'New';
        insert wi;

        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;
        wi.status__c='Completed';
        update wi;

        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Forms Sent', vR.workflow_status__c);
    }  

    @isTest
    private static void test_WIType_Action4(){      
        Response__c r=[select id from Response__c];
        
        test.startTest();
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, r.Id, null, false);
        wi.Work_Item_ExtId__c = 'T1';
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'Reminder';
        wi.Status__c = 'New';
        insert wi;

        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;
        wi.status__c='Completed';
        update wi;

        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Reminder Sent', vR.workflow_status__c);
    }  

    @isTest
    private static void test_Outcome_Action(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='List Leave';
        update w;
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c wi=[select id from Work_Item__c];
        wi.status__c='Done';
        update wi;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c];
        system.assertEquals('Ready for Delivery', vR.workflow_status__c); // no outcomes on the wi
    }  

    @isTest
    private static void test_ListLeaveOutcome_Action1(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='List Leave';
        update w;
        Task t=new Task(whatid=w.id,subject='CONTACT, refusal',status='Completed');
        insert t;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c];
        w1.status__c='Done';
        update w1;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Refused', vR.workflow_status__c);
    }


    @isTest
    private static void test_ListLeaveOutcome_Action2(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='List Leave';
        update w;
        Task t=new Task(whatid=w.id,subject='Contact, Left Forms/Pack',status='Completed');
        insert t;

        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c ];
        w1.status__c='Done';
        update w1;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Forms Sent', vR.workflow_status__c);
    }  


    @isTest
    private static void test_NFRUOutcome_Action1(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='Non-Response Follow-Up';
        update w;
        Task t=new Task(whatid=w.id,subject='unable to make contact v3',status='Completed');
        insert t;

        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c ];
        w1.status__c='Completed';
        update w1;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Non Response Visit Completed', vR.workflow_status__c);
    }  

    @isTest
    private static void test_NFRUOutcome_Action2(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='non-response follow-up';
        update w;
        Task t=new Task(whatid=w.id,subject='unable to make contact v3',status='Completed');
        insert t;

        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c ];
        w1.status__c='In Progress';
        update w1;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Non-Response Visit In Progress', vR.workflow_status__c);
    }  

    @isTest
    private static void test_NFRUOutcome_Action3(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='non-response follow-up';
        update w;
        Task t=new Task(whatid=w.id,subject='contact: refusal',status='Completed');
        insert t;

        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c ];
        w1.status__c='In Progress';
        update w1;
        test.stopTest();

        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Refused', vR.workflow_status__c);
    }  

    @isTest
    private static void test_NFRUOutcome_Action4(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='non-response follow-up';
        update w;
        
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Non-Response Visit Scheduled', vR.workflow_status__c);
    }  

    @isTest
    private static void test_NFRUOutcome_Action5(){
        Work_Item__c w=[select id from Work_Item__c];
        w.work_item_type__c='non-response follow-up';
        update w;
        Task t=new Task(whatid=w.id,subject='unable to make contact v3',status='Completed');
        insert t;
        
        test.startTest();
        // reset to allow logic
        WorkItemTriggerHandler.workflowExecuted=false;  
        // only 1 exists
        Work_Item__c w1=[select id from Work_Item__c ];
        w1.notes__c='whatever';
        update w1;
        test.stopTest();
        
        // user recorded an outcome, but the workitem still in new status
        Response__c vR = [select workflow_status__c from Response__c ];
        system.assertEquals('Non-Response Visit Scheduled', vR.workflow_status__c);
    }  
*/
}