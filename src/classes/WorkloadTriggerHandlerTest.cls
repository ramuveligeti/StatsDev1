@isTest
private class WorkloadTriggerHandlerTest{
    @testSetup static void setupData(){
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
        Response_API_Properties__c resApi = new Response_API_Properties__c();
        resApi.Name = 'response.status.closed';
        resApi.Value__c = 'Completed';
        Response_API_Properties__c resApi1 = new Response_API_Properties__c();
        resApi1.Name = 'activity.status.closed';
        resApi1.Value__c = 'Completed';
        Response_API_Properties__c resApi2 = new Response_API_Properties__c();
        resApi2.Name = 'error.folder.name';
        resApi2.Value__c = 'API Errors';
        Response_API_Properties__c resApi3 = new Response_API_Properties__c();
        resApi3.Name = 'workitem.status.closed';
        resApi3.Value__c = 'Completed';
        insert new List<Response_API_Properties__c>{resApi,resApi1,resApi2,resApi3};          
      
    }
    
    static testMethod void workLoadTrigger(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            test.startTest();
            UnitCounter__c uc = new UnitCounter__c();
            uc.AutoIncrement__c = '123';
            insert uc;
            Workload__c workLoadObj = new Workload__c();
            workLoadObj.Workload_ID__c = '132';
            insert workLoadObj;
            system.assertEquals(workLoadObj.Default_Address_Type__c, null);
            workLoadObj.Default_Address_Type__c = 'Commercial';
            update workLoadObj;
            test.stopTest();
        }
    }
    
    static testMethod void bulkWorkLoadTrigger(){
        //Added system settings for incident Incident 192372 Salesforce CPU problem
        TestDataHelper.createSystemSettings();
		insert new SystemSettings__c[]{
            new SystemSettings__c(name = 'batchSize.workitemOwnerUpdate', value__c = '200')
		};
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            test.startTest();
            Workload__c workLoadObj = TestDataHelper.createWorkLoad(false);
            workLoadObj.Default_Address_Type__c=null;
            insert workLoadObj;
            Response__c rs = [Select Id from Response__c];
            List<Work_Item__c> workItemList = new List<Work_Item__c>();
            for(Integer i=0;i<200;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(null, null, null, rs.Id, workLoadObj.Id, false);
                wi.Work_Item_ExtId__c = 'test'+i;
                wi.Status__c = (Math.mod(i,2)==0)?'New':'Completed';
                workItemList.add(wi);
            }
            insert workItemList;
            system.assertEquals(workLoadObj.Default_Address_Type__c, null);
            User userObj1 = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            workLoadObj.Default_Address_Type__c = 'Commercial';
            workLoadObj.OwnerId = userObj1.Id;
            update workLoadObj;
            test.stopTest();
            for(Work_Item__c wi: [Select Id, status__c,ownerid from Work_Item__c] ){
                if(wi.status__c=='Completed'){
                    // logic changed as part of ECP1836, reassign everything
                    system.assertEquals(userObj1.id, wi.ownerid);
                } else {
                    system.assertEquals(userObj1.id, wi.ownerid);
                }
            }
        }
    }

    @isTest static void testProcessWorkloadCompletion(){
        TestDataHelper.createSystemSettings();
        //Added system settings for incident Incident 192372 Salesforce CPU problem
        insert new SystemSettings__c[]{
            new SystemSettings__c(name = 'batchSize.workitemOwnerUpdate', value__c = '200')
		};
        TestDataHelper.createResponseProperties();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        Collection__c collection = TestDataHelper.createCollection(false);
        collection.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert collection;
        
        Collection_Instance__c collectionInstance = [Select Id from Collection_Instance__c];

        List<Workload__c> workloads = new List<Workload__c>();
        for(Integer i=0; i<500; i++){
            Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, false);         
            workload.Workload_Status__c = 'In Progress';
            workloads.add(workload);
        }
        insert workloads;

        List<Workload__c> workloadsToUpdate = [select Workload_Status__c from Workload__c];
        for(Workload__c workload:workloadsToUpdate){
            workload.Workload_Status__c = 'Complete';
        }
        update workloadsToUpdate;

        Group completedQueue = [select Id from Group where Type='Queue' and DeveloperName='Completed_Work'];
        List<Workload__c> workloadsToTest = [select OwnerId from Workload__c];
        for(Workload__c workload:workloadsToTest){
            System.assertEquals(completedQueue.Id, workload.OwnerId);
        }
    }
}