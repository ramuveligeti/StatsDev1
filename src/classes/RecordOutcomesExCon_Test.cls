@isTest
private class RecordOutcomesExCon_Test {
    @testSetup static void setupData(){
        TestDataHelper.createWrapupCodes();
        TestDataHelper.createResponseProperties();
    }
    
    @isTest static void wrapupCodesTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,true);
            
            Contact cnt = TestDataHelper.createContact(true);
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, null, true);
            Workload__c workLoad = TestDataHelper.createWorkLoad(colIns.Id, true);
            Work_Item__c wi = TestDataHelper.createWorkItem(actSch.Id, cnt.Id, NULL, resp.Id, workLoad.Id, false);
            wi.Status__c = 'New';
            wi.Delivery_Mode__c = 'Call';
            wi.Work_Item_Type__c = 'Pre-notification';
            wi.Core_Result__c = 'No Contact made';
            wi.Outcome__c = 'Call back required';
            wi.Action__c = 'Send email';
            wi.New_Call_Back_Time__c = null;
            wi.Default_Call_Back_Time__c = null;
            insert wi;
            wi = [Select Id,Outcome__c,Action__c,Status__c,Delivery_Mode__c,Work_Item_Type__c,Core_Result__c,New_Call_Back_Time__c,Default_Call_Back_Time__c,Response_Extension_Date__c from Work_Item__c where Id = :wi.Id];
            test.startTest();
            {
                ApexPages.StandardController stdController = new ApexPages.StandardController(wi);
                RecordOutcomesExCon cwExCon = new RecordOutcomesExCon(stdController);
                cwExcon.coreResultSelected = 'No Contact made';
                cwExcon.findOutcomes();
                cwExcon.outcomeSelected = 'Call back required';
                cwExcon.findActions();
                cwExcon.actionSelected = 'Send email';
                cwExcon.findDefaultCallBackTime();

                cwExcon.findOutcomes();
                cwExcon.outcomeSelected = 'Call back not required';
                cwExcon.findActions();
                cwExcon.actionSelected = 'Send fax';
                cwExcon.findDefaultCallBackTime();

                cwExcon.findOutcomes();
                cwExcon.outcomeSelected = 'Call back required';
                cwExcon.findActions();
                cwExcon.actionSelected = 'Send fax';
                cwExcon.findDefaultCallBackTime();

                cwExcon.findOutcomes();
                cwExcon.outcomeSelected = 'Call back required';
                cwExcon.findActions();
                cwExcon.actionSelected = 'Send post';
                cwExcon.findDefaultCallBackTime();
                
                cwExcon.Save();
            }
            test.stopTest();
            system.assert(wi.New_Call_Back_Time__c!=null);
            Work_Item__c w = [Select Id from Work_Item__c where Id = :wi.Id];
            /*system.assert(w!=null);
            Event e = [Select Id from Event];
            system.assert(e!=null);
            system.assert(wi.Status__c=='Completed');*/
        }
    }
}