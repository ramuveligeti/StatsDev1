/**
* Amendment -  Caterina Cuccurullo 25 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
* ECP-2843: Cross collection suppression SZhu 20160825
* ECP-3773  Extension SA should not trigger validation rule any more
*/       
@isTest
private class SpecialArrangementProcessorTest {
	@testsetup 
	static void setup(){
		TestDataHelper.createResponseProperties();
		insert new System_Update__c(SetupOwnerId=UserInfo.getOrganizationId(), Execute__c=false);
	}

	@isTest
    static void response_sa_validate_data_test() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c=null;
		colIns.Reference_Period__c=null;
		colIns.Return_Date__c=system.today().addDays(40);
		insert colIns;
		
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		system.assert(!ap.validated);
    }

	// this test is no longer needed
/*
    static void response_sa_validate_date_test() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
        colIns.Planned_Start_Date__c = system.today().addDays(-100);
        colIns.Actual_Start_Date__c = system.today().addDays(-90);
        colIns.Extension_Cut_off_Date__c = system.today().addDays(-30);
        colIns.Planned_Close_Off__c = system.today().addDays(-25);
        colIns.Actual_Close_Off__c = system.today().addDays(-20);
        colIns.Planned_End_Date__c = system.today().addDays(-10);
        colIns.Actual_End_Date__c = system.today().addDays(-5);
		colIns.Return_Date__c=system.today().addDays(-40);
		insert colIns;
		
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		system.assert(!ap.validated);
    }
*/

	@isTest
    static void response_sa_processing_extension_date_test() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
		colIns.Return_Date__c=system.today()+40;
        colIns.Planned_Start_Date__c = system.today().addDays(2);
        colIns.Planned_Close_Off__c = system.today().addDays(3);
		insert colIns;
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.recordtypeid=uRT;
		unitObj.Unit_of_Interest_ID__c ='EricTest';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '1234';
		unitObj.P_O_Box__c = null;
		unitObj.Meshblock_Code__c='11';
		unitObj.DP_ID__c='10001';
		insert unitObj;
		Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
		resp.recordTypeId=rRT;
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = null;
		resp.access_code__c=null;
		resp.survey_unit__c = unitObj.id;
		insert resp;
    	Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Extension').getRecordTypeId();
		Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=unitObj.id,recordtypeid=rt,
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Month_4__c=true,Extension_Period_Days__c='100');
		insert sa;
		
		// testing, will NOT throw error on extension date validation rule anymore 
		// Szhu 20161208 modified the behaviour for ECP- 773
		Test.startTest();
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();		
		Test.stopTest();
		
		system.assert(!ap.gethasError());
    }

	@isTest
    static void response_sa_processing_test() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
		colIns.Return_Date__c=system.today()+40;
        colIns.Planned_Start_Date__c = system.today().addDays(2);
        colIns.Planned_Close_Off__c = system.today().addDays(3);
        colIns.Extension_Cut_off_Date__c = system.today().addDays(50);
		insert colIns;
		
		integer[]extensions=new integer[]{1,2,3,4,5};
		integer[]periodicCollections=new integer[]{51,52,53,54,55};
		integer[]suppression=new integer[]{101,102,103,104,105};
		Map<integer,integer>consolidation=new Map<integer,integer>{151=>155,152=>155,153=>155,154=>155};
		
		// instead of running the file-loading logic, just create the test data
		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<200; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=0; i<200; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[i].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.survey_unit__c = units[i].id;
			resp.extension_date__c = null;
			resps.add(resp);
		}
		insert resps;


		Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
		for(integer x:periodicCollections){//month based
        	Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Periodic Collection').getRecordTypeId();
			Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[x].id,recordtypeid=rt,
				Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Month_4__c=true);
			sas.add(sa);
		}

		for(integer x:suppression){//period based
        	Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
			Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[x].id,recordtypeid=rt,
				Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Suppression_Type__c='Burden');
			sas.add(sa);
		}

		for(integer x:extensions){//month based
        	Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Extension').getRecordTypeId();
			Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[x].id,recordtypeid=rt,
				Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Month_4__c=true,Extension_Period_Days__c='5');
			sas.add(sa);
		}

		for(integer x:consolidation.keySet()){
        	Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Consolidation').getRecordTypeId();
			Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[x].id,recordtypeid=rt,
				Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Month_4__c=true,Consolidated_Unit__c=units[consolidation.get(x)].id);
			sas.add(sa);
		}
		insert sas;
		
		Test.startTest();
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		Test.stopTest();
		
		// don't care about SOQL count, this verification just do 1 by 1
		for(integer x:periodicCollections){//month based
			Response__c r = [select status__c, response_status_reason__c from Response__c where id=: resps[x].id];
			system.assertEquals('Suppressed',r.status__c);
			system.assertEquals('Periodic Collection',r.response_status_reason__c);
		}

		for(integer x:suppression){//period based
			Response__c r = [select status__c, response_status_reason__c from Response__c where id=: resps[x].id];
			system.assertEquals('Suppressed',r.status__c);
			system.assertEquals('Burden Exclusion',r.response_status_reason__c);
		}

		for(integer x:extensions){//month based
			Response__c r = [select status__c, response_status_reason__c,extension_date__c from Response__c where id=: resps[x].id];
			system.assertEquals('New',r.status__c);
			// cannot do the assertion, business hour is inherit from the org, and we are testing next business day
			//system.assertEquals(system.today()+45, r.extension_date__c);
			system.assertNotEquals(null, r.extension_date__c);
		}

		for(integer x:consolidation.keySet()){
			Response__c r = [select status__c, response_status_reason__c from Response__c where id=: resps[x].id];
			system.assertEquals('Suppressed',r.status__c);
			system.assertEquals('Consolidated Collection',r.response_status_reason__c);
		}

		system.assert(!ap.gethasError());
    }


	@isTest
    static void response_sa_processing_test2() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;

		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Status__c = 'Active';
        insert artefact;

		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
		colIns.Return_Date__c=system.today()+40;
        colIns.Planned_Start_Date__c = system.today().addDays(2);
        colIns.Planned_Close_Off__c = system.today().addDays(3);
		insert colIns;

		Contact spider = TestDataHelper.createContact(true);
				
		// instead of running the file-loading logic, just create the test data
		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<10; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=0; i<10; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[i].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = '12';
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.collection_mode__c = 'SCER';
			resp.contact__c = null;
			resp.survey_unit__c = units[i].id;
			resp.unit_delivery_mode__c='Post';
			resps.add(resp);
		}
		resps[7].instrument__c=artefact.id;
		insert resps;

		Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
    	Id rt1 = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Multiple Questionnaires').getRecordTypeId();
		Special_Arrangement__c sa1=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[3].id,recordtypeid=rt1,
			collection_mode__c = 'OCPQ', contact__c=spider.id, unit_delivery_mode__c='Withheld',
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null);
		sas.add(sa1);

    	Id rt2 = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Instrument Assignment').getRecordTypeId();
		Special_Arrangement__c sa2=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[7].id,recordtypeid=rt2,
			Instrument_Name__c=artefact.id, contact__c=spider.id,
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null);
		sas.add(sa2);
		insert sas;
		
		Test.startTest();
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		Test.stopTest();
		
		Response__c[] verifiedResps = [select id, contact__c, instrument__c, collection_mode__c, unit_delivery_mode__c from Response__c];
		for(integer i=0; i<10; i++){
			if(i!=3 && i!=7){ // otherwise no changes
				system.assertEquals(null, verifiedResps[i].contact__c);
				system.assertEquals(null, verifiedResps[i].instrument__c);
				system.assertEquals('SCER', verifiedResps[i].collection_mode__c);
				system.assertEquals('Post', verifiedResps[i].unit_delivery_mode__c);
			}
		}
		system.assertEquals(null, verifiedResps[3].contact__c); // sa not setting it any more
		system.assertEquals(null, verifiedResps[3].instrument__c);
		system.assertEquals('OCPQ', verifiedResps[3].collection_mode__c);  // updated by sa
		system.assertEquals('Withheld',verifiedResps[3].unit_delivery_mode__c);

		system.assertEquals(spider.id, verifiedResps[7].contact__c);  // updated by sa
		system.assertEquals(artefact.id, verifiedResps[7].instrument__c);
		system.assertEquals('SCER', verifiedResps[7].collection_mode__c);		
		
		system.assert(!ap.gethasError());
    }

	@isTest
    static void response_sa_processing_multi_instrument() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;

		Artefact__c artefact1 = TestDataHelper.createArtefact(col.Id, false);
        artefact1.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact1.Status__c = 'Active';
        artefact1.artefact_code__c='T1';
        artefact1.Artefact_ExtId__c='T1';
		Artefact__c artefact2 = TestDataHelper.createArtefact(col.Id, false);
        artefact2.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact2.Status__c = 'Active';
        artefact2.artefact_code__c='T2';
        artefact1.Artefact_ExtId__c='T2';
        insert new Artefact__c[]{artefact1,artefact2};

		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
		colIns.Return_Date__c=system.today()+40;
        colIns.Planned_Start_Date__c = system.today().addDays(2);
        colIns.Planned_Close_Off__c = system.today().addDays(3);
		insert colIns;
					
		Contact spider = TestDataHelper.createContact(false);
        spider.Suburb__c = 'Testville';
        insert spider;
				
		// instead of running the file-loading logic, just create the test data
		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<1; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=0; i<2; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[0].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = '12';
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.collection_mode__c = 'SCER';
			resp.contact__c = null;
			resp.survey_unit__c = units[0].id;
			resp.unit_delivery_mode__c='Post';
			resps.add(resp);
		}
		resps[0].instrument__c=artefact1.id;
		resps[1].instrument__c=artefact2.id;
		insert resps;

		Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
    	Id rt2 = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Instrument Assignment').getRecordTypeId();
		Special_Arrangement__c sa2=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[0].id,recordtypeid=rt2,
			Instrument_Name__c=artefact2.id, contact__c=spider.id,
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null);
		sas.add(sa2);
		insert sas;
		
		Test.startTest();
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		Test.stopTest();
		
		Response__c[] verifiedResps = [select id, contact__c, instrument__c, collection_mode__c, unit_delivery_mode__c, 
			Delivery_Road_Number__c, Delivery_Road_Name__c, Delivery_Suburb__c
			from Response__c];
		system.assertEquals(spider.id, verifiedResps[1].contact__c);  // updated by sa
		system.assertEquals(artefact2.id, verifiedResps[1].instrument__c);
		system.assertEquals('Testville', verifiedResps[1].delivery_suburb__c); // override delivery address from contact

		system.assertEquals(null, verifiedResps[0].contact__c);  // no SA on this one
		system.assertEquals(artefact1.id, verifiedResps[0].instrument__c);
		
		system.assert(!ap.gethasError());
    }


	@isTest
    static void no_response_test() {
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;

		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Status__c = 'Active';
        insert artefact;

		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Collection_Period__c='April';
		colIns.Reference_Period__c=system.today().year()+'04';
		colIns.Return_Date__c=system.today()+40;
        colIns.Planned_Start_Date__c = system.today().addDays(2);
        colIns.Planned_Close_Off__c = system.today().addDays(3);
		insert colIns;
		
		Contact spider = TestDataHelper.createContact(true);
				
		// instead of running the file-loading logic, just create the test data
		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<10; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=0; i<5; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[i].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.collection_mode__c = 'SCER';
			resp.contact__c = null;
			resp.survey_unit__c = units[i].id;
			resp.unit_delivery_mode__c='Post';
			resps.add(resp);
		}
		insert resps;

		Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
    	Id rt1 = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Multiple Questionnaires').getRecordTypeId();
		Special_Arrangement__c sa1=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[6].id,recordtypeid=rt1,
			collection_mode__c = 'OCPQ', contact__c=spider.id, unit_delivery_mode__c='Withheld',
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null);
		sas.add(sa1);

    	Id rt2 = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Instrument Assignment').getRecordTypeId();
		Special_Arrangement__c sa2=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[7].id,recordtypeid=rt2,
			Instrument_Name__c=artefact.id, contact__c=spider.id,
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null);
		sas.add(sa2);
		insert sas;
		
		Test.startTest();
		SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest');
		ap.autoProcessing();
		Test.stopTest();
		
		// nothing to process.  The SA relates to units that are not in the sample
				
		system.assert(!ap.gethasError());
    }
    
    @isTest
    static void cross_collection_supp_test()
    {
        /*create test data
         * 5 collections, 5 collection instances, 5 artefacts 
         * 5 units 1 ENT and 2 GEO and 2 other
         * 5 responses per collection instance, matching unit
         * collection unit on the response being ENT and survey unit being GEO on 2 GEO response
         * collection and survey unit both being ENT on the ENT response
         * Special Arrangement rule on the ENT collection unit created, with extention date
         */
        
        Collection__c[] collections = new Collection__c[]{};
        Collection_instance__c[] colInstances = new Collection_instance__C[]{};
        Artefact__c[] artefacts = new Artefact__c[]{};        
            
        for(integer i=1; i<=2; i++)
        {
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'StevenTest' + i;
            col.Collection_Code__c = 'StevenTest' + i;
            col.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
            collections.add(col);
        }
        insert collections;
        
        integer counter =1;
        for(Collection__C col : collections)
        {
           
          	Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            colIns.Collection_Instance_Code__c='CI' + col.Name;
            colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
            colIns.Collection_Period__c='August';
            colIns.Reference_Period__c=system.today().year()+'08';
            colIns.Return_Date__c=system.today()+40;
            colIns.Planned_Start_Date__c = system.today();
            colIns.Planned_Close_Off__c = system.today().addDays(30);

            colInstances.add(colIns);
            
            Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
            artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        	artefact.Status__c = 'Active';
        	artefact.artefact_code__c='T'+counter;
        	artefact.Artefact_ExtId__c='T'+counter;
            artefacts.add(artefact);
            counter++;
        }
        insert colInstances;
        insert artefacts;
       
		Response__c[]resps=new Response__c[]{};
 
        Id eRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        
        
        
        Unit__c unitObjENT = TestDataHelper.createUnit(false);
                unitObjENT.recordtypeid=eRT;
                unitObjENT.Unit_of_Interest_ID__c ='ENT3';
                unitObjENT.Address_Type__c = null;
                unitObjENT.Other_Address_Type__c = null;
                unitObjENT.Rural_Delivery_Number__c = null;
                unitObjENT.Postcode__c = '1234';
                unitObjENT.P_O_Box__c = null;
                unitObjENT.Meshblock_Code__c='11';
                unitObjENT.DP_ID__c=''+(10003);
      			
        insert unitObjENT;
       
        //create responses
        //create 2  responses across collection instances with same unit ID
        for(integer i=0; i<2; i++){
                    
            Response__c resp = TestDataHelper.createResponse(colInstances[i].Id, null, null, unitObjENT.Id, false);
                         
            resp.recordTypeId=rRT;
            resp.Status__c = 'New';
            resp.Unit_Type__c = null;
            resp.Delivery_Unit_Number__c = null;
            resp.Response_ExtId__c = 'StevenTestwhatever'+i;
            resp.Workflow_status__c=null;
            resp.Document_Number__c = null;
            resp.access_code__c=null;
            resp.collection_mode__c = 'SCER';
            resp.contact__c = null;
            resp.survey_unit__c = unitObjENT.id;
            resp.unit_delivery_mode__c='Post';
            resp.instrument__c = artefacts[i].id;
            resps.add(resp);
        }
	
        Insert resps;
        

        Id rtCCS = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Cross Collection Suppression').getRecordTypeId();
        
        Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
        //create CCS SA with unit being the ENT unit   
        Special_Arrangement__c sa1 =new Special_Arrangement__c(Unit__c=unitObjENT.id,recordtypeid=rtCCS,
			Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Suppression_Type__c='Burden');
        sas.add(sa1);
       		
		insert sas;
        
        Test.startTest();
        SpecialArrangementProcessor ap1;
        for(Collection_Instance__c colIns : colInstances)
        {
		    ap1 = new SpecialArrangementProcessor(colIns.Collection_Instance_Code__c);
			ap1.autoProcessing();
        }
      	Test.stopTest(); 	
        
        //check all responses have been suppressed
       
        for(Response__C resp :[select id, contact__c, instrument__c, collection_mode__c, unit_delivery_mode__c, 
			Delivery_Road_Number__c, Delivery_Road_Name__c, Delivery_Suburb__c, status__c, response_status_reason__c
			from Response__c])
        {
            system.assertEquals('Suppressed',resp.status__c);
		    system.assertEquals('Burden Exclusion',resp.response_status_reason__c);
            
        }
       
    }

}