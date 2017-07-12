@isTest
private class SocialHouseholdHistoryViewExConTest{
    @testSetup static void setup(){
        Response_Settings__c rsc = new Response_Settings__c();
        rsc.Name = 'HLFS';
        rsc.Enable_Summary_View__c = true;
        rsc.Master_Response__c = 'Dwelling';
        rsc.Detail_Responses__c = 'Individual';
		rsc.Where_Clause__c = 'Wave__c';
        insert rsc;
        
        TestDataHelper.createResponseProperties();
    }

	@isTest static void historyViewTest(){
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'HLFS';
        col.Collection_Code__c = 'HLFS';
        insert col;
		List<Collection_Instance__c> collist = new List<Collection_Instance__c>();
		for(integer i=0;i<10;i++){
	        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
			colIns.Collection_Instance_Code__c = 'HLFS'+i;
			collist.add(colIns);
		}
		insert collist;
        Contact cnt = TestDataHelper.createContact(true);
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '--Use Workload Default--';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
		Integer cnt1=0;
        List<Response__c> respList = new List<Response__c>();
		for(Collection_Instance__c ci : collist){
			Response__c resp1 = TestDataHelper.createResponse(ci.Id, cnt.Id, null, unitObj.Id, false);
			resp1.Access_Code__c = null;
			resp1.Response_ExtId__c = null;
			resp1.Rotation__c = String.valueOf(cnt1++);
			resp1.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
			respList.add(resp1);
		}
		cnt1=0;
        for(Collection_Instance__c ci : collist){
	        Response__c resp = TestDataHelper.createResponse(ci.Id, cnt.Id, null, unitObj.Id, false);
            resp.Access_Code__c = null;
            resp.Response_ExtId__c = null;
			resp.Rotation__c = String.valueOf(cnt1++);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            respList.add(resp);
        }
        insert respList;
		Response__c rs = [Select Id from Response__c where RecordTypeId = :Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Dwelling').getRecordTypeId() order by Rotation__c desc limit 1];
        Work_Item__c wi1 = TestDataHelper.createWorkItem(null, cnt.Id, NULL, rs.Id, null, false);
        wi1.Delivery_Mode__c = 'Call';
        wi1.Work_Item_Type__c = 'Courtesy contact';
        wi1.Status__c = 'New';
        wi1.Call_Back_Time__c = system.now().addDays(-1);
		wi1.recordTypeId = Work_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert wi1;
		test.startTest();
		wi1 = [Select Id,Collection__c,RecordTypeId,Response__r.Rotation__c,Response__r.Unit_of_Interest__r.LBU__c,Unit_Id__c,Response__r.Wave__c,Collection_Instance__c from Work_Item__c];
		ApexPages.StandardController stdCont = new APexPages.StandardController(wi1);
		SocialHouseholdHistoryViewExCon sch = new SocialHouseholdHistoryViewExCon(stdCont);
		test.stopTest();
	}
}