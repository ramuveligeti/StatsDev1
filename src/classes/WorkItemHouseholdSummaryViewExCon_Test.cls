@isTest
private class WorkItemHouseholdSummaryViewExCon_Test{
    @testSetup static void setup(){
        Response_Settings__c rsc = new Response_Settings__c();
        rsc.Name = 'Census';
        rsc.Enable_Summary_View__c = true;
        rsc.New_Detail_Response_Field_Id_s__c = 'Collection_Instance=CF00N17000000MgEY, Unit=CF00N17000000MlOJ';
        rsc.New_Detail_Response_Object_Id__c = 'a0G';
        rsc.Master_Response__c = 'Census Dwelling';
        rsc.Detail_Responses__c = 'Census Individual';
        insert rsc;
        
        TestDataHelper.createResponseProperties();
    }

	@isTest static void summaryViewTest(){
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
			resp.Wave__c = '1';
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            respList.add(resp);
        }
        insert respList;
        Response__c respDwelling = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
        respDwelling.Access_Code__c = null;
        respDwelling.Response_ExtId__c = null;
		respDwelling.Wave__c = '1';
        respDwelling.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
        insert respDwelling;
		respDwelling = [Select Id,Collection_Instance__r.Collection__r.Collection_Code__c,Collection_Instance__c,Unit_of_Interest__c,RecordType.Name,Collection_Instance__r.Name,Unit_of_Interest__r.Name
                        from Response__c where id = :respDwelling.Id];
        Work_Item__c wi1 = TestDataHelper.createWorkItem(null, cnt.Id, NULL, respDwelling.Id, null, false);
        wi1.Delivery_Mode__c = 'Call';
        wi1.Work_Item_Type__c = 'Courtesy contact';
        wi1.Status__c = 'New';
        wi1.Call_Back_Time__c = system.now().addDays(-1);
        insert wi1;
		wi1 = [Select ID,Unit_Id__c,Response__r.Wave__c,Response__r.RecordTypeId from Work_Item__c];
        PageReference pageRef = Page.ResponseSummaryView;
        Test.setCurrentPage(pageRef);
        test.startTest();
        {
            ApexPages.StandardController stdController = new ApexPages.StandardController(wi1);
            WorkItemHouseholdSummaryViewExCon rscx = new WorkItemHouseholdSummaryViewExCon(stdController);
			system.assertEquals(10,rscx.personalQuestionnaires.size());
        }
        test.stopTest();
        List<Response__c> rs = [Select Id from Response__c];
        system.assertEquals(11, rs.size());
	}
}