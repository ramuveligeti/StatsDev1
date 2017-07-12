@isTest
private class ResponseSummaryViewExCon_Test {
    @testSetup static void setup(){
        Response_Settings__c rsc = new Response_Settings__c();
        rsc.Name = 'Census';
        rsc.Enable_Summary_View__c = true;
        rsc.New_Detail_Response_Field_Id_s__c = 'Collection_Instance=CF00N17000000MgEY, Unit=CF00N17000000MlOJ';
        rsc.New_Detail_Response_Object_Id__c = 'a0G';
        rsc.Master_Response__c = 'Census Dwelling';
        rsc.Detail_Responses__c = 'Census Individual';
        insert rsc;
        
        Response_Settings__c rsc1 = new Response_Settings__c();
        rsc1.Name = 'Business';
        rsc1.Enable_Summary_View__c = true;
        rsc1.New_Detail_Response_Field_Id_s__c = 'Collection_Instance=CF00N17000000MgEY, Unit=CF00N17000000MlOJ';
        rsc1.New_Detail_Response_Object_Id__c = 'a0G';
        rsc1.Master_Response__c = 'Business Response';
        rsc1.Detail_Responses__c = 'Business Response';
        rsc1.Where_Clause__c = 'Wave__c';
        insert rsc1;
        
        TestDataHelper.createResponseProperties();
    }
    
    @isTest static void responseSummaryViewTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<10;i++){
	            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                resp.Access_Code__c = null;
                resp.Response_ExtId__c = null;
                resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
                respList.add(resp);
            }
            insert respList;
            Response__c respDwelling = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            respDwelling.Access_Code__c = null;
            respDwelling.Response_ExtId__c = null;
            respDwelling.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
            insert respDwelling;
			respDwelling = [Select Id,Collection_Instance__r.Collection__r.Collection_Code__c,Collection_Instance__c,Unit_of_Interest__c,RecordType.Name,Collection_Instance__r.Name,Unit_of_Interest__r.Name
                            from Response__c where id = :respDwelling.Id];
            PageReference pageRef = Page.ResponseSummaryView;
            Test.setCurrentPage(pageRef);
            test.startTest();
            {
                ApexPages.StandardController stdController = new ApexPages.StandardController(respDwelling);
                ResponseSummaryViewExcon rscx = new ResponseSummaryViewExcon(stdController);
            }
            test.stopTest();
            List<Response__c> rs = [Select Id from Response__c];
            system.assertEquals(11, rs.size());
        }
    }
    
    @isTest static void responseSummaryViewSocialTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Business';
            col.Collection_Code__c = 'Business';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<10;i++){
	            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                resp.Access_Code__c = null;
                resp.Response_ExtId__c = null;
                resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
                respList.add(resp);
            }
            insert respList;
            Response__c respDwelling = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            respDwelling.Access_Code__c = null;
            respDwelling.Response_ExtId__c = null;
            respDwelling.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            insert respDwelling;
			respDwelling = [Select Id,Survey_Unit__c,Wave__c,Unit_Association__c,Collection_Instance__r.Collection__r.Collection_Code__c,Collection_Instance__c,Unit_of_Interest__c,RecordType.Name,Collection_Instance__r.Name,Unit_of_Interest__r.Name
                            from Response__c where id = :respDwelling.Id];
            PageReference pageRef = Page.ResponseSummaryView;
            Test.setCurrentPage(pageRef);
            test.startTest();
            {
                ApexPages.StandardController stdController = new ApexPages.StandardController(respDwelling);
                ResponseSummaryViewExcon rscx = new ResponseSummaryViewExcon(stdController);
            }
            test.stopTest();
            List<Response__c> rs = [Select Id from Response__c];
            system.assertEquals(11, rs.size());
        }
    }
    
}