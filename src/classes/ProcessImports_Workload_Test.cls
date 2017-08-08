@isTest
private with sharing class ProcessImports_Workload_Test {

// created by Eric to test the specific scenarios on loading workload
// assumption is that the Unit and the response already exists
	@testSetup
	private static void setupTest(){
		TestDataHelper.createSystemSettings();
		insert new Response_API_Properties__c[]{
			 new Response_API_Properties__c(Name='response.status.closed',value__c='Completed'),
			 new Response_API_Properties__c(Name='activity.status.closed',value__c='Completed'),
			 new Response_API_Properties__c(Name='error.folder.name',value__c='API Errors'),
			 new Response_API_Properties__c(Name='workitem.status.closed',value__c='Completed')
		};
	}
	
	@isTest
	private static void testNewWorkload_single_MarkInUsingInstrument(){
		// this is a very specific census test
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
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
		Workload__c workload = TestDataHelper.createWorkLoad(colIns.id,false);
		workload.Workload_Priority_Indicator__c=0;
		workload.Workload_Id__c = 'ELWL1';
		insert workload;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.Status__c = 'New';
        //resp.Workload__c = workload.id;
        resp.Unit_Type__c = null;
        resp.Delivery_Unit_Number__c = null;
        resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		insert resp;
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'Address canvassing';
		wi.Status__c = 'New';
        wi.workload__c = workload.id;
		wi.Work_Item_ExtId__c='erictestericabcdeftest1';
        insert wi;
        
		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
		artefact.Name = 'EricForm';
        artefact.Artefact_Code__c = 'EricForm';
		insert artefact;

        User wlowner = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Staging_Element__c testfileload = new Staging_Element__c();
        testfileload.CI_Collection_Instance_Code__c='EricTest';
        testfileload.WL_Workload_ID__c = 'ELWL2';
        testfileload.WL_Meshblock__c = 'ELWL2';
        testfileload.WL_Workload_Priority_Indicator__c = 9;
        testfileload.Workload_OwnerID__c = wlowner.id;
        testfileload.U_Unit_of_Interest_Id__c = 'ERICABCDEF';
        testfileload.A_Instrument_Code__c = 'EricForm';
        testfileload.Survey_Unit__c = true;
        testfileload.Collection_Unit__c = true;
        testfileload.R_Unit_Association__c = 'whatever';
		testfileload.WI_Work_Item_ExtId__c='erictestericabcdeftest1';
        testfileload.WI_Work_Item_Type__c='Address canvassing';
        insert testfileload;
        
		Test.startTest();
		ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(colIns.Id);
		Database.executeBatch(instance,200);		
        Test.stopTest();
        
		Staging_Element__c[] vFL=[select errors__c, failed__c from Staging_Element__c where id =: testfileload.id];
		if(vFL!=null && vFL.size()>0){
			system.debug(LoggingLevel.ERROR, vFL[0].errors__c);
		}
		system.assertEquals(0, vFL.size());
        
        // verification
        Workload__c vWL=[select id, name, Workload_ID__c, Workload_Priority_Indicator__c from workload__c where workload_id__c = 'ELWL2'];        
        
        //Response__c vR=[select workload__c from Response__c where id = :resp.id];
        //system.assertEquals(vWL.id, vR.workload__c);// should be a new workload association
        
        Work_Item__c vWI=[select ownerid from Work_Item__c where id=: wi.id];
        system.assertEquals(wlowner.id, vWI.ownerId);
                
	}

	@isTest
	private static void testNewWorkload_single(){
		// this is a very specific census test
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
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
		Workload__c workload = TestDataHelper.createWorkLoad(colIns.id,false);
		workload.Workload_Priority_Indicator__c=0;
		workload.Workload_Id__c = 'ELWL1';
		insert workload;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.Status__c = 'New';
        //resp.Workload__c = workload.id;
        resp.Unit_Type__c = null;
        resp.Delivery_Unit_Number__c = null;
        resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		insert resp;
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Delivery_Mode__c = 'TEST1';
        wi.Work_Item_Type__c = 'Address canvassing';
		wi.Status__c = 'New';
		wi.Work_Item_ExtId__c='erictestericabcdeftest1';
        wi.workload__c = workload.id;
        insert wi;

        User wlowner = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Staging_Element__c testfileload = new Staging_Element__c();
        testfileload.CI_Collection_Instance_Code__c='EricTest';
        testfileload.WL_Workload_ID__c = 'ELWL2';
        testfileload.WL_Meshblock__c = 'ELWL2';
        testfileload.WL_Workload_Priority_Indicator__c = 9;
        testfileload.Workload_OwnerID__c = wlowner.id;
        testfileload.U_Unit_of_Interest_Id__c = 'ERICABCDEF';
        testfileload.R_Mark_in_Required__c = true;
        testfileload.Survey_Unit__c = true;
        testfileload.Collection_Unit__c = true;
        testfileload.R_Unit_Association__c = 'whatever';
		testfileload.WI_Work_Item_ExtId__c='erictestericabcdeftest1';
        testfileload.WI_Work_Item_Type__c = 'Address canvassing';
        insert testfileload;
        
		Test.startTest();
		ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(colIns.Id);
		Database.executeBatch(instance,200);		
        Test.stopTest();
        
		Staging_Element__c[] vFL=[select errors__c, failed__c from Staging_Element__c where id =: testfileload.id];
		if(vFL!=null && vFL.size()>0){
			system.debug(LoggingLevel.ERROR, vFL[0].errors__c);
		}
		system.assertEquals(0, vFL.size());
        
        // verification
        Workload__c vWL=[select id, name, Workload_ID__c, Workload_Priority_Indicator__c from workload__c where workload_id__c = 'ELWL2'];        
        
        //Response__c vR=[select workload__c from Response__c where id = :resp.id];
        //system.assertEquals(vWL.id, vR.workload__c);// should be a new workload association
        Work_Item__c[]WIs=[select id, Work_Item_ExtId__c from work_item__c];
        system.assertEquals(1, WIs.size(), WIs);
        
        Work_Item__c vWI=[select ownerid from Work_Item__c where id=: wi.id];
        system.assertEquals(wlowner.id, vWI.ownerId);
                
	}

	// bulk test, testing limits
	@isTest
	private static void testNewWorkload_bulk(){
		// this is a very specific census test
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;
        User[]wlowners = new User[]{
        	TestDataHelper.createUser( 'Test1' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test2' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test3' + datetime.now().getTime()+'@gmail.com','System Administrator',false)
        };
        insert wlowners;	

		Workload__c[]workloads = new Workload__c[]{
			TestDataHelper.createWorkLoad(colIns.id,false),
			TestDataHelper.createWorkLoad(colIns.id,false),
			TestDataHelper.createWorkLoad(colIns.id,false)
		};
		workloads[0].Workload_Id__c = 'ELWL1';
		workloads[0].ownerid=wlowners[0].id;
		workloads[0].Workload_Priority_Indicator__c=0;
		workloads[1].Workload_Id__c = 'ELWL2';
		workloads[1].ownerid=wlowners[0].id;
		workloads[1].Workload_Priority_Indicator__c=0;
		workloads[2].Workload_Id__c = 'ELWL3';
		workloads[2].ownerid=wlowners[0].id;
		workloads[2].Workload_Priority_Indicator__c=0;
		insert workloads;

		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Work_Item__c[]items=new Work_Item__c[]{};
		for(integer i=0; i<200; i++){
	        Unit__c unitObj = TestDataHelper.createUnit(false);
	        unitObj.Unit_of_Interest_ID__c ='ERICABC'+i;
	        unitObj.Address_Type__c = null;
	        unitObj.Other_Address_Type__c = null;
	        unitObj.Rural_Delivery_Number__c = null;
	        unitObj.Postcode__c = '123';
	        unitObj.P_O_Box__c = null;
	        unitObj.Meshblock_Code__c='11';
	        unitObj.DP_ID__c='12'+i;
	        units.add(unitObj);
	        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
	        resp.Status__c = 'New';
	        //resp.Workload__c = workloads[0].id;
	        resp.Unit_Type__c = null;
	        resp.Delivery_Unit_Number__c = null;
	        resp.Response_ExtId__c = 'EricTestERICABC'+i;
			resps.add(resp);
	        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
	        wi.Work_Item_ExtId__c = 'TEST1'+i;
	        wi.Delivery_Mode__c = 'TEST1';
	        wi.Work_Item_Type__c = 'Address canvassing';
			wi.Status__c = 'New';
	        wi.workload__c = workloads[0].id;
	        wi.ownerid=wlowners[0].id;
	        wi.Response__r = resp;
	        items.add(wi);
		}
		insert units;
		insert resps;
		for(Work_Item__c w: items){w.Response__c=w.Response__r.id;}
		insert items;

		Staging_Element__c[]csv=new Staging_Element__c[]{};
		for(integer i=0;i<200;i++){
	        Staging_Element__c testfileload = new Staging_Element__c();
	        testfileload.CI_Collection_Instance_Code__c='EricTest';
	        testfileload.U_Unit_of_Interest_Id__c = 'ERICABC'+i;
	        testfileload.R_Mark_in_Required__c = true;
	        testfileload.Survey_Unit__c = true;
	        testfileload.Collection_Unit__c = true;
	        testfileload.R_Unit_Association__c = 'ERICABC'+i;
        	testfileload.WI_Work_Item_Type__c = 'Address canvassing';

			// split the workload to other users
			if(Math.mod(i,2)==0){
		        testfileload.WL_Workload_ID__c = 'ELWL2';
		        testfileload.WL_Workload_Priority_Indicator__c = 1;
		        testfileload.Workload_OwnerID__c = wlowners[1].id;
			}else{
		        testfileload.WL_Workload_ID__c = 'ELWL3';
		        testfileload.WL_Workload_Priority_Indicator__c = 2;
		        testfileload.Workload_OwnerID__c = wlowners[2].id;
			}
			csv.add(testfileload);
		}
        
		Test.startTest();
		insert csv;
		//ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(colIns.Id);
		//Database.executeBatch(instance,200);		
        Test.stopTest();
        
		Staging_Element__c[] vFL=[select errors__c, failed__c from Staging_Element__c where id in :csv];
		if(vFL!=null && vFL.size()>0){
			// only look at first error
			system.debug(LoggingLevel.ERROR, vFL[0].errors__c);
		}
		system.assertEquals(0, vFL.size());
        
        Workload__c[]vWL=[select id, name, ownerid, Workload_ID__c, Workload_Priority_Indicator__c from workload__c where id in:workloads];
        system.assertEquals(1,vWL[1].Workload_Priority_Indicator__c);// reset prioirty on existing workload based on file load
        system.assertEquals(2,vWL[2].Workload_Priority_Indicator__c);
        system.assertEquals(wlowners[1].id, vWL[1].ownerid);//reset workload owner
        system.assertEquals(wlowners[2].id, vWL[2].ownerid);
        
        // verification
        //Response__c[]vR=[select workload__c, (select workload__c, ownerid from Work_Items__r) from Response__c where id in:resps];        
        // verify that the reassignment of workload                
	}


	// new test for handling census workload assignment
	// this is specific using the Workitem salesforce-id as the identifier
	@isTest
	private static void test_reimportWI_withIDs(){
		// this is a very specific census test
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'EricTest';
        col.Collection_Code__c = 'EricTest';
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;
		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Work_Item__c[]items=new Work_Item__c[]{};
		for(integer i=0; i<200; i++){
	        Unit__c unitObj = TestDataHelper.createUnit(false);
	        unitObj.Unit_of_Interest_ID__c ='ERICABC'+i;
	        unitObj.Address_Type__c = null;
	        unitObj.Other_Address_Type__c = null;
	        unitObj.Rural_Delivery_Number__c = null;
	        unitObj.Postcode__c = '123';
	        unitObj.P_O_Box__c = null;
	        unitObj.Meshblock_Code__c='11';
	        unitObj.DP_ID__c='12'+i;
	        units.add(unitObj);
	        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
	        resp.Status__c = 'New';
	        //resp.Workload__c = workloads[0].id;
	        resp.Unit_Type__c = null;
	        resp.Delivery_Unit_Number__c = null;
	        resp.Response_ExtId__c = 'EricTestERICABC'+i;
			resps.add(resp);
	        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
	        wi.Work_Item_ExtId__c = 'TEST1'+i;
	        wi.Delivery_Mode__c = 'TEST1';
	        wi.Work_Item_Type__c = 'Address canvassing';
			wi.Status__c = 'New';
	        wi.workload__c = null;
	        wi.ownerid=UserInfo.getUserId();
	        wi.Response__r = resp;
	        items.add(wi);
		}
		insert units;
		insert resps;
		for(Work_Item__c w: items){w.Response__c=w.Response__r.id;}
		insert items;
        User[]wlowners = new User[]{
        	TestDataHelper.createUser( 'Test1' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test2' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test3' + datetime.now().getTime()+'@gmail.com','System Administrator',false)
        };
        insert wlowners;	
		Workload__c[]workloads = new Workload__c[]{
			TestDataHelper.createWorkLoad(colIns.id,false)
		};
		workloads[0].Workload_Id__c = 'ELWL3';
		workloads[0].ownerid=wlowners[0].id;
		workloads[0].Workload_Priority_Indicator__c=0;
		insert workloads;

		Staging_Element__c[]csv=new Staging_Element__c[]{};
		for(integer i=0;i<200;i++){
	        Staging_Element__c testfileload = new Staging_Element__c();
	        testfileload.CI_Collection_Instance_Code__c='EricTest';
	        testfileload.U_Unit_of_Interest_Id__c = 'ERICABC'+i;
	        testfileload.R_Mark_in_Required__c = true;
	        testfileload.Survey_Unit__c = true;
	        testfileload.Collection_Unit__c = true;
	        testfileload.R_Unit_Association__c = 'ERICABC'+i;
        	testfileload.WI_Work_Item_Type__c = 'Address canvassing';
			testfileload.WI_WorkItem_ID__c = items[i].id;
	        testfileload.WL_Workload_ID__c = 'ELWL3';
	        testfileload.WL_Workload_Priority_Indicator__c = 2;
	        testfileload.Workload_OwnerID__c = wlowners[0].id;
			csv.add(testfileload);
		}
		insert csv;

		Test.startTest();
		ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(colIns.Id);
		Database.executeBatch(instance,200);		
        Test.stopTest();
        
		Staging_Element__c[] vFL=[select errors__c, failed__c from Staging_Element__c where id in :csv];
		if(vFL!=null && vFL.size()>0){
			// only look at first error
			system.debug(LoggingLevel.ERROR, vFL[0].errors__c);
		}
		system.assertEquals(0, vFL.size());
		
		Work_Item__c[]wis=[select id, ownerid, workload__c from work_item__c];
		system.assertEquals(wis.size(),200);
		// verify that, through file loading with the workload id, the same item has been updated
		for(integer i=0;i<200;i++){
			system.assertEquals(wlowners[0].id, wis[i].ownerid);
			system.assertEquals(workloads[0].id, wis[i].workload__c);
		}
		
	}
}