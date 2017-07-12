@isTest
private class ProcessFailedMarkInRequestsExCon_Test {
    
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

        
        ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
        ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'Census';
        col.Collection_Code__c = 'Census';
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ERICABC';
        unitObj.Address_Type__c = '--Use Workload Default--';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
        // this is the primary resp
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = dfID;
        resp.Status__c = 'No Response';
        resp.Response_ExtId__c = 'EricTestERICABC';
        resp.access_code__c='ABC';
        resp.document_number__c='123';
        insert resp;
        
        DAC_Store__c[]dacs=new DAC_Store__c[]{
            new DAC_Store__c(document_id__c='1111', access_code__c='XXX1', response__c=resp.id)
        };
        insert dacs;
        
    }
    
    @isTest static void testMethod1(){
        List<Mark_In_Request__c> mirlist = new List<Mark_In_Request__c>();
        Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
        mir.Form_Type__c = 'DF';
        mir.Document_Number__c = '1111';
        mir.Access_Code__c = null;
        mir.Failed__c = true;
        mirlist.add(mir);
        Mark_In_Request__c mir1 = TestDataHelper.createMarkInRequest(false);
        mir1.Form_Type__c = 'IF';
        mir1.Document_Number__c = null;
        mir1.Access_Code__c = 'XXX1';
        mir1.Failed__c = true;
        mirlist.add(mir1);
        insert mirlist;
        
        Response__c []r=[select id from Response__c];
        system.assertEquals(1, r.size());
                
        test.startTest();
        MarkInRequestTriggerHandler h=MarkInRequestTriggerHandler.getInstance();
        h.processed=false;
        ProcessFailedMarkInRequestsExCon pm = new ProcessFailedMarkInRequestsExCon();
        pm.execute();

        test.stopTest();
        
        
        Mark_In_Request__c[]mi=[Select Id from Mark_In_Request__c where Failed__c=true];
        system.assertEquals(0, mi.size());
        r=[select id from Response__c];
        system.assertEquals(2, r.size());
        Response__c[]vr=[Select Id from Response__c where RecordType.Name = 'Census Individual'];
        system.assertEquals(1, vr.size());
        vr = [Select Id from Response__c where RecordType.Name = 'Census Dwelling'];
        system.assertEquals(1, vr.size());
    }


    @isTest static void test_failedProcessing_failedAgain(){
        List<Mark_In_Request__c> mirlist = new List<Mark_In_Request__c>();
        for(integer i=0; i< 300; i++){
            Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
            mir.Form_Type__c = 'IF';
            mir.Document_Number__c = 'ABCD';
            mir.Access_Code__c = null;
            mir.Failed__c = true;
            mirlist.add(mir);
        }
        insert mirlist;
        
        Mark_In_Request__c[]mi=[Select Id from Mark_In_Request__c where Failed__c=true];
        system.assertEquals(300, mi.size());
                        
        test.startTest();
        MarkInRequestTriggerHandler h=MarkInRequestTriggerHandler.getInstance();
        h.processed=false;
        ProcessFailedMarkInRequestsExCon pm = new ProcessFailedMarkInRequestsExCon();
        pm.execute();
        test.stopTest();
        
        mi=[Select Id, failed_reason__c from Mark_In_Request__c where Failed__c=true];
        system.assertEquals(300, mi.size());// remain failed

        mi=[Select Id, failed_reason__c from Mark_In_Request__c where Failed__c=false and processed__c=false];
        system.assertEquals(0, mi.size());
    }


}