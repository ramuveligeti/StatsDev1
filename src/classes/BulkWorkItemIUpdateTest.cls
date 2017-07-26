/*
*  Remark: Steven Zhu 20161104  ECP3747, handling multi-select none option selected null error bug
*/
@isTest
private class BulkWorkItemIUpdateTest {

    @testsetup
    private static void setup(){
        insert new Response_API_Properties__c[]{
             new Response_API_Properties__c(Name='response.status.closed',value__c='Completed'),
             new Response_API_Properties__c(Name='activity.status.closed',value__c='Completed'),
             new Response_API_Properties__c(Name='error.folder.name',value__c='API Errors'),
             new Response_API_Properties__c(Name='workitem.status.closed',value__c='Completed')
        };
        
            
        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = false;
        upsert su;

        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricBiz';
        col.Collection_Code__c = 'EricBiz';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert col;
        
        Grouping__c gr = new Grouping__c();
        gr.GR_1_Label__c = 'test1';
        gr.GV1__c = 'testV1';
        gr.Active__c = true;
        gr.Collection__c = col.Id;
        insert gr;
        
		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.Artefact_Code__c = '321';
        artefact.Delivery_Modes__c = 'Post;Email';
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Status__c = 'Active';
        insert artefact;

        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricBiz';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        colIns.Grouping__c = gr.Id;
        insert colIns;
        Activity_Schedule__c sch = TestDataHelper.createActivitySchedule(colIns.id,false);
        sch.Scheduled_Date_time__c = null;
        sch.Frequency__c = null;
        sch.Occurrence__c = null;
        sch.Delivery_mode__c='Call';
        sch.Work_Item_Type__c='Pre-notification';
        Activity_Schedule__c sch2 = TestDataHelper.createActivitySchedule(colIns.id,false);
        sch2.Scheduled_Date_time__c = null;
        sch2.Frequency__c = null;
        sch2.Occurrence__c = null;
        sch2.Delivery_mode__c='Post';
        sch2.Work_Item_Type__c='NRFU';
        insert new Activity_Schedule__c[]{sch,sch2};
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='EricBizABC';
        unitObj.Address_Type__c = null;
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.recordtypeid = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp.Status__c = 'New';
        resp.Unit_Type__c = null;

        resp.Delivery_Unit_Number__c = null;
        resp.Response_ExtId__c = 'EricBizEricBizABC'; // ramu changed logic to use association
        resp.Overall_Priority_Factor__c = 1;
        insert resp;

		Response__c resp2 = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp2.recordtypeid = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp2.Status__c = 'New';
        resp2.Unit_Type__c = null;


        resp2.Delivery_Unit_Number__c = null;
        resp2.Response_ExtId__c = 'EricBizEricBizDEF'; // ramu changed logic to use association
        resp2.Overall_Priority_Factor__c = 2;
		resp2.Overall_Priority_Override__c = true;
		resp2.Collection_Mode__c = 'SAPQ';
		resp2.Wave__c = '1';

        insert resp2;
		User wlowner = TestDataHelper.createUser( 'TestUser20160905@gmail.com','System Administrator',true);

        Work_Item__c wi = TestDataHelper.createWorkItem(sch.id, null, null, resp.id, null,false);
        wi.Status__c = 'New';
        wi.Delivery_Mode__c = 'Call';
        wi.Work_Item_Type__c = 'Pre-notification';
        Work_Item__c wi2 = TestDataHelper.createWorkItem(sch.id, null, null, resp.id, null,false);
        wi2.Status__c = 'New';
        wi2.Delivery_Mode__c = 'Post';
        wi2.Work_Item_Type__c = 'Pre-notification';
        Work_Item__c wi3 = TestDataHelper.createWorkItem(sch.id, null, null, resp.id, null,false);
        wi3.Status__c = 'In Progress';
        wi3.Delivery_Mode__c = 'Call';
        wi3.Work_Item_Type__c = 'Pre-notification';
		wi3.Escalated__c = true;
        Work_Item__c wi4 = TestDataHelper.createWorkItem(sch2.id, null, null, resp2.id, null,false);
        wi4.Status__c = 'Completed';
        wi4.Delivery_Mode__c = 'Post';
        wi4.Work_Item_Type__c = 'Pre-notification';
		wi4.Escalated__c = true;
		Work_Item__c wi5 = TestDataHelper.createWorkItem(sch.id, null, null, resp2.id, null,false);
        wi5.Status__c = 'In Progress';
        wi5.Delivery_Mode__c = 'Email';
        wi5.Work_Item_Type__c = 'Questionnaire';
        Work_Item__c wi6 = TestDataHelper.createWorkItem(sch2.id, null, null, resp2.id, null,false);
        wi6.Status__c = 'Completed';
        wi6.Delivery_Mode__c = 'Web';
        wi6.Work_Item_Type__c = 'Reminder';
		wi6.Instrument__c = artefact.id;
		wi6.ownerId = wlowner.id;
		wi6.Call_Back_Time__c = system.now().addDays(1);

        Work_Item__c[]wis=new Work_Item__c[]{wi,wi2,wi3,wi4,wi5,wi6};
        for(Work_Item__c w:wis){
            w.Core_Result__c = null;
            w.Outcome__c = null;
            w.Action__c = null;
            w.New_Call_Back_Time__c = null;
            w.Default_Call_Back_Time__c = null;
            w.Work_Item_ExtId__c=null;
            w.Mobile_Device_Id__c=null;
        }
        insert wis;
    }

	 @isTest
    private static void test_Multi_Type_Schedule(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.inputPriorityOverride = 'Yes';
        ctr.priorityFactorInput = '1';
        //ctr.priorityOverride = true;
        ctr.filterWIT= new List<String>{'Pre-notification','Questionnaire'};
        ctr.inputStatus='TESTING';

		ctr.filterAS=new List<String>();
        for(Activity_Schedule__c sch :[select id from Activity_Schedule__c])
		{
			ctr.filterAS.add(sch.id);
		}

        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(5,c);
    }

    @isTest
    private static void test_Type_Schedule(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT= new List<String>{'Pre-notification'};
        ctr.inputStatus='TESTING';

        Activity_Schedule__c sch=[select id from Activity_Schedule__c limit 1];
        ctr.filterAS=new List<String>{sch.id};
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(3,c);
    }

    @isTest
    private static void test_Type_Mode(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);
    }

	@isTest
    private static void test_Type_Escalated(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterES='Yes';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);
    }

	@isTest
    private static void test_Type_Owner(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);

		User u = [select id from User where Username = 'TestUser20160905@gmail.com' limit 1];
        ctr.filterWIT=new List<String>{'Reminder'};
        ctr.dummyFilter.OwnerId=u.id;
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_OverallPriorityFactorGT1(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);

        ctr.filterWIT=new List<String>{'Reminder'};
        ctr.filterOpf=' > 1';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_OverallPriorityOverride(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);

        ctr.filterWIT=new List<String>{'Reminder'};
        ctr.filterOpo='Yes';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_Callbacktime(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);

        ctr.filterWIT=new List<String>{'Reminder'};
        ctr.dummyWI_StartDate.Call_Back_Time__c=system.now().addDays(-1);
        ctr.dummyWI_EndDate.Call_Back_Time__c=system.now().addDays(2);
        ctr.inputStatus='TESTING';

        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_CollectionMode(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.dummyRFilter.Collection_Mode__c='SAPQ';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
		Work_Item__c[]wis=[select status__c from Work_Item__c];
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_Wave(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterWave='1';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        integer c=0;
		Work_Item__c[]wis=[select status__c from Work_Item__c];
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(1,c);
    }

	@isTest
    private static void test_Type_Mode_key(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.filterKey='Yes';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(0,c);// test resopnse is key
    }

	@isTest
    private static void test_Type_WIT_none(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{''};
        ctr.filterDM=new List<String>{'Call'};
        ctr.filterKey='No';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);// test resopnse is not key
    }

	@isTest
    private static void test_Type_Mode_Nonkey(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.filterKey='No';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);// test resopnse is not key
    }

	@isTest
    private static void test_Type_Mode_LBU(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.filterLBU='Yes';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(0,c);// test unit is not LBU
    }

	@isTest
    private static void test_Type_Mode_NonLBU(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.filterLBU='No';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);// test unit is not LBU
    }

	@isTest
    private static void test_Type_Mode_RespStatus(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.dummyRFilter.status__c='In Progress';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(0,c);// test resopnse is not key
    }

	@isTest
    private static void test_Type_Status_mode(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        resetCtr(ctr);
        ctr.filterWIT=new List<String>{'Pre-notification'};
        ctr.filterDM=new List<String>{'Call'};
        ctr.dummyFilter.status__c='New';
        ctr.inputStatus='TESTING';
        
        Test.startTest();
        ctr.save();
        Test.stopTest();
        
        system.assert(ctr.batched);
        Work_Item__c[]wis=[select status__c from Work_Item__c];
        system.assertEquals(6, wis.size());
        integer c=0;
        for(Work_Item__c w:wis){
            c+=(w.status__c=='TESTING'?1:0);
        }
        system.assertEquals(2,c);
    }


    private static void resetCtr(BulkWorkItemUpdateController ctr){
        ctr.dummyFilter.workload__c=null;
        ctr.dummyFilter.activity_schedule__c=null;
        ctr.dummyRFilter.status__c=null;
        ctr.dummyRFilter.response_Summary_status__c=null;
        ctr.filterWIT=null;
        ctr.filterDM=null;
        ctr.filterAS=null;
        ctr.filterWIS=null;
        ctr.filterFU=null;
        ctr.filterLBU=null;
        ctr.filterKey=null;
        ctr.inputStatus=null;
        ctr.inputUser=null;
        ctr.inputQueue=null;
		ctr.filterWave = null;
		ctr.filterOpf = null;
		ctr.filterOpo = null;
		ctr.filterES = null;
    }

    @isTest
    private static void test_error(){
        PageReference tp=Page.BulkWorkItemUpdate;
        Test.setCurrentPage(tp);
        Collection_Instance__c ci = [select id,name, Grouping__c from Collection_Instance__c where Collection_Instance_Code__c='EricBiz'];
        BulkWorkItemUpdateController ctr = new BulkWorkItemUpdateController(new ApexPages.StandardController(ci));
        
        system.assert(!ctr.batched);
        // testing error conditions - less than 2 filters
        resetCtr(ctr);
        ctr.save();
        system.assert(!ctr.batched);
        // testing no update
        ctr.dummyFilter.status__c='whatever';
        ctr.dummyFilter.work_item_type__c='abc';
        ctr.filterFU='Yes';
        ctr.filterKey='Yes';
        ctr.filterLBU='Yes';
        ctr.save();
        system.assert(!ctr.batched);
        // testing user/queue setup simultaneously
        ctr.inputUser=UserInfo.getUserId();
        ctr.inputQueue=ctr.activeQueues[1].getValue();
        ctr.save();
        system.assert(!ctr.batched);
        ctr.inputQueue='';
        ctr.inputStatus='whatever';
        
        test.startTest();
        // won't find anything
        ctr.save();
        test.stopTest();
        
        system.assert(ctr.batched);
        
        ctr.cancel();
    }
    
    
    
    
}