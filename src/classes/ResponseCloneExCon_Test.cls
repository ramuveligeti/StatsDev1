@isTest
private class ResponseCloneExCon_Test {
	@testSetup static void setupData(){
		Response_Settings__c rsc = new Response_Settings__c();
		rsc.Name = 'Census';
		rsc.Enable_Clone__c = true;
		rsc.RecordType_Name_for_Clone__c = 'Census Dwelling';
		insert rsc;
		
		TestDataHelper.createResponseProperties();
		
		DAC_Store__c[]dacs=new DAC_Store__c[]{
			new DAC_Store__c(document_id__c='1111', access_code__c='XXX1', allocation_status__c = 'Pending Print', for_print__c = true),
			new DAC_Store__c(document_id__c='8881', access_code__c='YYY1', allocation_status__c = 'Pending Print'),	
            new DAC_Store__c(document_id__c='8882', access_code__c='YYY2', allocation_status__c = 'Unallocated'),
            new DAC_Store__c(document_id__c='7773', access_code__c='ZZZ3', allocation_status__c = 'Unallocated', Is_Non_Private_Dwelling__c = true),  //AddressType NPD 
            new DAC_Store__c(document_id__c='7774', access_code__c='ZZZ4', allocation_status__c = 'Unallocated',Is_Non_Private_Dwelling__c = false),  //AddressType NPD 
            new DAC_Store__c(document_id__c='7775', access_code__c='ZZZ5', allocation_status__c = 'Unallocated',Is_Non_Private_Dwelling__c = true)    //AddressType PD
                  		
                };
		insert dacs;
		
	}
    //test clone response when AddressType = NonPrivate Dwelling,Is_Non_Private_Dwelling = true
    //expecting a DAC Store allocation stuatus to be Allocated 
   
	@isTest static void cloneMethodTest1(){
		User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
		system.runAs(userObj){
			Collection__c col = TestDataHelper.createCollection(false);
			col.Name = 'Census';
			col.Collection_Code__c = 'Census';
			insert col;
			Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
			Contact cnt = TestDataHelper.createContact(true);
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ecp2616';
			unitObj.Address_Type__c = 'Non-private dwelling';
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			insert unitObj;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			insert resp;
			resp = [Select Collection_Instance__r.Collection__r.Collection_Code__c,
					Unit_of_Interest__r.RecordTypeId,
					Unit_of_Interest__r.Level_Number__c,
					Unit_of_Interest__r.Building_Name__c,
					Unit_of_Interest__r.Unit_Number__c,
					Unit_of_Interest__r.Road_Number__c,
					Unit_of_Interest__r.Road_Number_Alpha__c,
					Unit_of_Interest__r.Road_Name__c,
					Unit_of_Interest__r.Road_Type__c,
					Unit_of_Interest__r.Rural_Delivery_Number__c,
					Unit_of_Interest__r.Suburb__c,
					Unit_of_Interest__r.Town_or_City__c,
					Unit_of_Interest__r.Postcode__c,
					Unit_of_Interest__r.DP_ID__c,
					Unit_of_Interest__r.Address_Type__c,
					Unit_of_Interest__r.Other_Address_Type__c,
					Unit_of_Interest__r.Address_Sub_Type__c,
					Unit_of_Interest__r.Meshblock_Code__c,
					//Unit_of_Interest__r.Address_Position__Latitude__s,
					//Unit_of_Interest__r.Address_Position__Longitude__s,
					Unit_of_Interest__r.Shell_Address__c,
					Unit_of_Interest__r.Related_Observed_Address__c,
					Collection_Instance__c,
					Collection_Instance__r.Collection__r.Name,
					Unit_of_Interest__r.PSU_Number__c,
					Unit_of_Interest__r.PSU_Name__c,
					Unit_of_Interest__r.Region_Number__c,
					Unit_of_Interest__r.Region_Name__c,
					Unit_of_Interest__r.Territorial_Authority_Number__c,
					Unit_of_Interest__r.Territorial_Authority_Name__c,
					Unit_of_Interest__r.Team_Leader_Area_Number__c,
					Unit_of_Interest__r.Team_Leader_Area_Name__c,
					Unit_of_Interest__r.Area_Unit_Number__c,
					Unit_of_Interest__r.Area_Unit_Name__c,
					Type__c,Wave__c,
					RecordType.Name,Unit_Delivery_Mode__c,Instrument__c,Status__c
					from Response__c where Id = :resp.Id];
			List<Work_Item__c> wiList = new List<Work_Item__c>();
			for(integer i=0;i<200 ;i++){
				Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
				wi.Work_Item_ExtId__c = 'test'+i;
				wi.Delivery_Mode__c = 'Reminder'+i;
				wiList.add(wi);
			}
			
			insert wiList;
			PageReference pageRef = Page.ResponseClone;
			Test.setCurrentPage(pageRef);
			test.startTest();
			{
				ApexPages.StandardController stdController = new ApexPages.StandardController(resp);
				ResponseCloneExCon rscx = new ResponseCloneExCon(stdController);
				for(ResponseCloneExCon.workItemWrapper wiw: rscx.workItemWrapperList){
					wiw.selected = true;
				}
				rscx.cloneResponse();				
			}
			test.stopTest();
			List<Unit__c> unitObj1 = [Select Id from Unit__c where Id <> :unitObj.Id];
			List<Work_Item__c> wi = [Select Id from Work_Item__c];
			List<Response__c> res = [Select Id, document_number__c from Response__c where Id <> :resp.Id];
			system.assertEquals(1, unitObj1.size());
			system.assertEquals(400, wi.size());
			system.assertEquals(1, res.size());
			
			Dac_Store__c dac = [select allocation_status__c from Dac_Store__c where document_id__c = '7773'];
			system.assertEquals('Allocated', dac.allocation_status__c);   
		}
	}
     //test clone response when AddressType = NonPrivate Dwelling and Is_Non_Private_Dwelling set to false
     // expecting a DAC Store allocation stuatus to be unallocated 
     
    @isTest static void cloneMethodTest2(){
		User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
		system.runAs(userObj){
			Collection__c col = TestDataHelper.createCollection(false);
			col.Name = 'Census';
			col.Collection_Code__c = 'Census';
			insert col;
			Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
			Contact cnt = TestDataHelper.createContact(true);
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ecp26169X';
			unitObj.Address_Type__c = 'Non-private dwelling';
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			insert unitObj;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			insert resp;
			resp = [Select Collection_Instance__r.Collection__r.Collection_Code__c,
					Unit_of_Interest__r.RecordTypeId,
					Unit_of_Interest__r.Level_Number__c,
					Unit_of_Interest__r.Building_Name__c,
					Unit_of_Interest__r.Unit_Number__c,
					Unit_of_Interest__r.Road_Number__c,
					Unit_of_Interest__r.Road_Number_Alpha__c,
					Unit_of_Interest__r.Road_Name__c,
					Unit_of_Interest__r.Road_Type__c,
					Unit_of_Interest__r.Rural_Delivery_Number__c,
					Unit_of_Interest__r.Suburb__c,
					Unit_of_Interest__r.Town_or_City__c,
					Unit_of_Interest__r.Postcode__c,
					Unit_of_Interest__r.DP_ID__c,
					Unit_of_Interest__r.Address_Type__c,
					Unit_of_Interest__r.Other_Address_Type__c,
					Unit_of_Interest__r.Address_Sub_Type__c,
					Unit_of_Interest__r.Meshblock_Code__c,
					//Unit_of_Interest__r.Address_Position__Latitude__s,
					//Unit_of_Interest__r.Address_Position__Longitude__s,
					Unit_of_Interest__r.Shell_Address__c,
					Unit_of_Interest__r.Related_Observed_Address__c,
					Collection_Instance__c,
					Collection_Instance__r.Collection__r.Name,
					Unit_of_Interest__r.PSU_Number__c,
					Unit_of_Interest__r.PSU_Name__c,
					Unit_of_Interest__r.Region_Number__c,
					Unit_of_Interest__r.Region_Name__c,
					Unit_of_Interest__r.Territorial_Authority_Number__c,
					Unit_of_Interest__r.Territorial_Authority_Name__c,
					Unit_of_Interest__r.Team_Leader_Area_Number__c,
					Unit_of_Interest__r.Team_Leader_Area_Name__c,
					Unit_of_Interest__r.Area_Unit_Number__c,
					Unit_of_Interest__r.Area_Unit_Name__c,
					Type__c,Wave__c,
					RecordType.Name,Unit_Delivery_Mode__c,Instrument__c,Status__c
					from Response__c where Id = :resp.Id];
			List<Work_Item__c> wiList = new List<Work_Item__c>();
			for(integer i=0;i<200 ;i++){
				Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
				wi.Work_Item_ExtId__c = 'test'+i;
				wi.Delivery_Mode__c = 'Reminder'+i;
				wiList.add(wi);
			}
			
			insert wiList;
			PageReference pageRef = Page.ResponseClone;
			Test.setCurrentPage(pageRef);
			test.startTest();
			{
				ApexPages.StandardController stdController = new ApexPages.StandardController(resp);
				ResponseCloneExCon rscx = new ResponseCloneExCon(stdController);
				for(ResponseCloneExCon.workItemWrapper wiw: rscx.workItemWrapperList){
					wiw.selected = true;
				}
				rscx.cloneResponse();				
			}
			test.stopTest();
			List<Unit__c> unitObj1 = [Select Id from Unit__c where Id <> :unitObj.Id];
			List<Work_Item__c> wi = [Select Id from Work_Item__c];
			List<Response__c> res = [Select Id, document_number__c from Response__c where Id <> :resp.Id];
			system.assertEquals(1, unitObj1.size());
			system.assertEquals(400, wi.size());
			system.assertEquals(1, res.size());
			
			Dac_Store__c dac = [select allocation_status__c from Dac_Store__c where document_id__c = '7774'];
			system.assertEquals('Unallocated', dac.allocation_status__c);   
            }
	}
     //test clone response when AddressType = Private Dwelling Is_Non_Private_Dwelling = true
     // expecting a DAC Store allocation stuatus to be unallocated 
    @isTest static void cloneMethodTest3(){
		User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
		system.runAs(userObj){
			Collection__c col = TestDataHelper.createCollection(false);
			col.Name = 'Census';
			col.Collection_Code__c = 'Census';
			insert col;
			Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
			Contact cnt = TestDataHelper.createContact(true);
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ecp2616';
			unitObj.Address_Type__c = 'Private dwelling';
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			insert unitObj;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			insert resp;
			resp = [Select Collection_Instance__r.Collection__r.Collection_Code__c,
					Unit_of_Interest__r.RecordTypeId,
					Unit_of_Interest__r.Level_Number__c,
					Unit_of_Interest__r.Building_Name__c,
					Unit_of_Interest__r.Unit_Number__c,
					Unit_of_Interest__r.Road_Number__c,
					Unit_of_Interest__r.Road_Number_Alpha__c,
					Unit_of_Interest__r.Road_Name__c,
					Unit_of_Interest__r.Road_Type__c,
					Unit_of_Interest__r.Rural_Delivery_Number__c,
					Unit_of_Interest__r.Suburb__c,
					Unit_of_Interest__r.Town_or_City__c,
					Unit_of_Interest__r.Postcode__c,
					Unit_of_Interest__r.DP_ID__c,
					Unit_of_Interest__r.Address_Type__c,
					Unit_of_Interest__r.Other_Address_Type__c,
					Unit_of_Interest__r.Address_Sub_Type__c,
					Unit_of_Interest__r.Meshblock_Code__c,
					//Unit_of_Interest__r.Address_Position__Latitude__s,
					//Unit_of_Interest__r.Address_Position__Longitude__s,
					Unit_of_Interest__r.Shell_Address__c,
					Unit_of_Interest__r.Related_Observed_Address__c,
					Collection_Instance__c,
					Collection_Instance__r.Collection__r.Name,
					Unit_of_Interest__r.PSU_Number__c,
					Unit_of_Interest__r.PSU_Name__c,
					Unit_of_Interest__r.Region_Number__c,
					Unit_of_Interest__r.Region_Name__c,
					Unit_of_Interest__r.Territorial_Authority_Number__c,
					Unit_of_Interest__r.Territorial_Authority_Name__c,
					Unit_of_Interest__r.Team_Leader_Area_Number__c,
					Unit_of_Interest__r.Team_Leader_Area_Name__c,
					Unit_of_Interest__r.Area_Unit_Number__c,
					Unit_of_Interest__r.Area_Unit_Name__c,
					Type__c,Wave__c,
					RecordType.Name,Unit_Delivery_Mode__c,Instrument__c,Status__c
					from Response__c where Id = :resp.Id];
			List<Work_Item__c> wiList = new List<Work_Item__c>();
			for(integer i=0;i<200 ;i++){
				Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
				wi.Work_Item_ExtId__c = 'test'+i;
				wi.Delivery_Mode__c = 'Reminder'+i;
				wiList.add(wi);
			}
			
			insert wiList;
			PageReference pageRef = Page.ResponseClone;
			Test.setCurrentPage(pageRef);
			test.startTest();
			{
				ApexPages.StandardController stdController = new ApexPages.StandardController(resp);
				ResponseCloneExCon rscx = new ResponseCloneExCon(stdController);
				for(ResponseCloneExCon.workItemWrapper wiw: rscx.workItemWrapperList){
					wiw.selected = true;
				}
				rscx.cloneResponse();				
			}
			test.stopTest();
			List<Unit__c> unitObj1 = [Select Id from Unit__c where Id <> :unitObj.Id];
			List<Work_Item__c> wi = [Select Id from Work_Item__c];
			List<Response__c> res = [Select Id, document_number__c from Response__c where Id <> :resp.Id];
			system.assertEquals(1, unitObj1.size());
			system.assertEquals(400, wi.size());
			system.assertEquals(1, res.size());
			
			Dac_Store__c dac = [select allocation_status__c from Dac_Store__c where document_id__c = '7775'];
			system.assertEquals('Unallocated', dac.allocation_status__c);   
		}
	}
    
        
	@isTest static void cloneMethodTest4(){
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
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			insert resp;
			resp = [Select Collection_Instance__r.Collection__r.Collection_Code__c,
					Unit_of_Interest__r.RecordTypeId,
					Unit_of_Interest__r.Level_Number__c,
					Unit_of_Interest__r.Building_Name__c,
					Unit_of_Interest__r.Unit_Number__c,
					Unit_of_Interest__r.Road_Number__c,
					Unit_of_Interest__r.Road_Number_Alpha__c,
					Unit_of_Interest__r.Road_Name__c,
					Unit_of_Interest__r.Road_Type__c,
					Unit_of_Interest__r.Rural_Delivery_Number__c,
					Unit_of_Interest__r.Suburb__c,
					Unit_of_Interest__r.Town_or_City__c,
					Unit_of_Interest__r.Postcode__c,
					Unit_of_Interest__r.DP_ID__c,
					Unit_of_Interest__r.Address_Type__c,
					Unit_of_Interest__r.Other_Address_Type__c,
					Unit_of_Interest__r.Address_Sub_Type__c,
					Unit_of_Interest__r.Meshblock_Code__c,
					//Unit_of_Interest__r.Address_Position__Latitude__s,
					//Unit_of_Interest__r.Address_Position__Longitude__s,
					Unit_of_Interest__r.Shell_Address__c,
					Unit_of_Interest__r.Related_Observed_Address__c,
					Collection_Instance__c,
					Collection_Instance__r.Collection__r.Name,
					Unit_of_Interest__r.PSU_Number__c,
					Unit_of_Interest__r.PSU_Name__c,
					Unit_of_Interest__r.Region_Number__c,
					Unit_of_Interest__r.Region_Name__c,
					Unit_of_Interest__r.Territorial_Authority_Number__c,
					Unit_of_Interest__r.Territorial_Authority_Name__c,
					Unit_of_Interest__r.Team_Leader_Area_Number__c,
					Unit_of_Interest__r.Team_Leader_Area_Name__c,
					Unit_of_Interest__r.Area_Unit_Number__c,
					Unit_of_Interest__r.Area_Unit_Name__c,
					Type__c,Wave__c,
					RecordType.Name,Unit_Delivery_Mode__c,Instrument__c,Status__c
					from Response__c where Id = :resp.Id];
			List<Work_Item__c> wiList = new List<Work_Item__c>();
			for(integer i=0;i<200 ;i++){
				Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
				wi.Work_Item_ExtId__c = 'test'+i;
				wi.Delivery_Mode__c = 'Reminder'+i;
				wiList.add(wi);
			}
			
			insert wiList;
			PageReference pageRef = Page.ResponseClone;
			Test.setCurrentPage(pageRef);
			test.startTest();
			{
				ApexPages.StandardController stdController = new ApexPages.StandardController(resp);
				ResponseCloneExCon rscx = new ResponseCloneExCon(stdController);
				for(ResponseCloneExCon.workItemWrapper wiw: rscx.workItemWrapperList){
					wiw.selected = true;
				}
				rscx.cloneResponse();				
			}
			test.stopTest();
			List<Unit__c> unitObj1 = [Select Id from Unit__c where Id <> :unitObj.Id];
			List<Work_Item__c> wi = [Select Id from Work_Item__c];
			List<Response__c> res = [Select Id, document_number__c from Response__c where Id <> :resp.Id];
			system.assertEquals(1, unitObj1.size());
			system.assertEquals(400, wi.size());
			system.assertEquals(1, res.size());
			
			Dac_Store__c dac = [select allocation_status__c from Dac_Store__c where document_id__c = '8882'];
			system.assertEquals('Allocated', dac.allocation_status__c);
		}

	}

}