@isTest
private class MarkInRequestTriggerHandler_Test {
	@testSetup static void setupData(){
		TestDataHelper.createResponseProperties();
	}


	@isTest static void testBulkMarkInDataLock(){
		
		DAC_Store__c[]dacs=new DAC_Store__c[]{};
		for(integer i=0;i<100;i++){
			integer x=1000+i;
			dacs.add(new DAC_Store__c(document_id__c=''+x, access_code__c='XXX-'+x));
		}
		insert dacs;

		ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'Census';
		col.Collection_Code__c = 'Census';
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		Contact cnt = TestDataHelper.createContact(true);
		
		Unit__c[]units=new Unit__c[]{};
		for(integer i=0; i<100; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ERICABC'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			unitObj.DP_ID__c='1111';
			units.add(unitObj);
		}
		insert units;
		// this is the primary resp
		Response__c[]resps=new Response__c[]{};
		for(integer i=0; i<100; i++){
			integer x=1000+i;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, units[i].Id, false);
			resp.RecordTypeId = dfID;
			resp.Status__c = 'No Response';
			resp.Response_ExtId__c = 'EricTest1ERICABC'+i;
			resp.access_code__c='';
			resp.document_number__c=''+x;
			resps.add(resp);
		}
		insert resps;
	
		Test.startTest();
		Mark_In_Request__c[]mis=new Mark_In_Request__c[]{};
		Mark_In_Request__c[]mis2=new Mark_In_Request__c[]{};
		// running 800 mark-in request on the same 100 units, trying to get locking issue
		for(integer i=0; i<8; i++){
			for(integer j=0; j<100; j++){
				integer x=1000+j;
				Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
				mir.Form_Type__c = (i==0)?'DF':'IF';
				mir.Document_Number__c = ''+x;
				mis.add(mir);
			}
		}
		insert mis;//800
		Test.stopTest();

		// cannot verify anything apart from the test doesn't fail due to data locking
		// every record either processed or failed
		Mark_In_Request__c[] v=[select processed__c, failed__c from Mark_In_Request__c where processed__c=false and failed__c=false];
		system.assert(v.isempty());
	}

	@isTest static void testBulkMarkIn(){
		
		DAC_Store__c[]dacs=new DAC_Store__c[]{};
		for(integer i=0;i<300;i++){
			integer x=1000+i;
			dacs.add(new DAC_Store__c(document_id__c=''+x, access_code__c='XXX-'+x));
		}
		insert dacs;

		ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'Census';
		col.Collection_Code__c = 'Census';
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		Contact cnt = TestDataHelper.createContact(true);
		
		Unit__c[]units=new Unit__c[]{};
		for(integer i=0; i<300; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ERICABC'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			unitObj.DP_ID__c='1111';
			units.add(unitObj);
		}
		insert units;
		// this is the primary resp
		Response__c[]resps=new Response__c[]{};
		for(integer i=0; i<300; i++){
			integer x=1000+i;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, units[i].Id, false);
			resp.RecordTypeId = dfID;
			resp.Status__c = 'No Response';
			resp.Response_ExtId__c = 'EricTest1ERICABC'+i;
			resp.access_code__c='';
			resp.document_number__c=''+x;
			resps.add(resp);
		}
		insert resps;
	
		Test.startTest();
		Mark_In_Request__c[]mis=new Mark_In_Request__c[]{};
		for(integer i=0; i<300; i++){
			integer x=1000+i;
			Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
			mir.Form_Type__c = 'DF';
			mir.Document_Number__c = ''+x;
			mis.add(mir);
		}
		insert mis;
		Test.stopTest();
		
		integer i=0;
		for(Mark_In_Request__c m:[select processed__c, failed__c from Mark_In_Request__c]){
			system.assert(m.processed__c);
			system.assert(!m.failed__c);
			i++;
		}
		system.assertEquals(300,i);
	}

	@isTest static void testBulkMarkInFailed(){
		
		DAC_Store__c[]dacs=new DAC_Store__c[]{};
		for(integer i=0;i<300;i++){
			integer x=1000+i;
			dacs.add(new DAC_Store__c(document_id__c=''+x, access_code__c='XXX-'+x));
		}
		insert dacs;
		Test.startTest();
		Mark_In_Request__c[]mis=new Mark_In_Request__c[]{};
		for(integer i=0; i<300; i++){
			integer x=1000+i;
			Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
			mir.Form_Type__c = 'DF';
			mir.Document_Number__c = ''+x;
			mis.add(mir);
		}
		insert mis;
		Test.stopTest();
		
		integer i=0;
		for(Mark_In_Request__c m:[select processed__c, failed__c from Mark_In_Request__c]){
			system.assert(m.failed__c);// nothing to match again
			system.assert(!m.processed__c);// not a zombile
			i++;
		}
		system.assertEquals(300,i);
	}
	
	
	@isTest static void testMethod1(){
		DAC_Store__c[]dacs=new DAC_Store__c[]{
			new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
			new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
			new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
			new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
			new DAC_Store__c(document_id__c='5555', access_code__c='XXX5'),
			new DAC_Store__c(document_id__c='9999', access_code__c='XXX9'),
			new DAC_Store__c(document_id__c='8888', access_code__c='YYY8'),
			new DAC_Store__c(document_id__c='8881', access_code__c='YYY1'),
			new DAC_Store__c(document_id__c='8882', access_code__c='YYY2')
			};
		insert dacs;
		
		
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
		Contact cnt = TestDataHelper.createContact(true);
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.Unit_of_Interest_ID__c ='ERICABC1';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '123';
		unitObj.P_O_Box__c = null;
		unitObj.DP_ID__c='1111';
		Unit__c unitObj2 = TestDataHelper.createUnit(false);
		unitObj2.Unit_of_Interest_ID__c ='ERICABC2';
		unitObj2.Address_Type__c = null;
		unitObj2.Other_Address_Type__c = null;
		unitObj2.Rural_Delivery_Number__c = null;
		unitObj2.Postcode__c = '125';
		unitObj2.P_O_Box__c = null;
		unitObj2.DP_ID__c='2222';
		Unit__c unitObj3 = TestDataHelper.createUnit(false);
		unitObj3.Unit_of_Interest_ID__c ='ERICABC3';
		unitObj3.Address_Type__c = null;
		unitObj3.Other_Address_Type__c = null;
		unitObj3.Rural_Delivery_Number__c = null;
		unitObj3.Postcode__c = '126';
		unitObj3.P_O_Box__c = null;
		unitObj3.DP_ID__c='3333';
		upsert new Unit__c[]{unitObj,unitObj2,unitObj3};
		// this is the primary resp
		Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp.RecordTypeId = dfID;
		resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTest1ERICABC';
		resp.document_number__c='123';
		Response__c resp2 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp2.RecordTypeId = dfID;
		resp2.Status__c = 'No Response';
		Response__c resp3 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp3.RecordTypeId = dfID;
		resp3.Status__c = 'No Response';
		resp3.Response_ExtId__c = 'EricTest1ERICXYZ';
		resp3.document_number__c=null;
		Response__c resp4 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp4.RecordTypeId = dfID;
		resp4.Status__c = 'No Response';
		resp4.Response_ExtId__c = 'EricTest1ERICERIC';
		resp4.document_number__c=null;
		
		Response__c resp5 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj2.Id, false);
		resp5.RecordTypeId = dfID;
		resp5.Status__c = 'No Response';
		resp5.Response_ExtId__c = 'EricTest2ERICINS1';
		resp5.document_number__c='8881';
		resp5.response_summary_status__c='No Response';
		resp5.Number_of_Occupants__c=1;
				
		Response__c resp6 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj3.Id, false);
		resp6.RecordTypeId = dfID;
		resp6.Status__c = 'No Response';
		resp6.Response_ExtId__c = 'EricTest3ERICINS2';
		resp6.document_number__c='8882';
		resp6.response_summary_status__c='No Response';
		resp6.Number_of_Occupants__c=0;
		
		insert new Response__c[]{resp,resp2,resp3,resp4,resp5,resp6};
		ID[]resId = new Id[]{resp.Id,resp2.Id,resp3.Id,resp4.Id,resp5.Id,resp6.Id};

		Response__c vResp = [select Id,Document_Number__c,Access_Code__c,Unit_of_Interest__c,Collection_Instance__c from Response__c where ID=:resp.id];
		
		test.startTest();
		// let's chagne some responses to completed
		ResponseTriggerHandler.dacExecuted=false;
		
		resp.document_number__c='8888,1111,2222';			
		resp2.document_number__c='9999';
		resp3.document_number__c='3333';
		resp4.document_number__c='4444,5555';
		update new Response__c[]{resp,resp2,resp3,resp4};
			
		
		// resp2 is not a primary response, do nothing
		vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp2.id];
		system.assertEquals('XXX9',vResp.Access_Code__c);
		system.assertEquals('9999',vResp.Document_Number__c);
		
		// resp has an existing doc/acc-code, appending multiple will reset to a single value, and append the rest to additional ids
		vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp.id];
		system.assertEquals('YYY8,XXX1,XXX2',vResp.Access_Code__c);
		system.assertEquals('8888,1111,2222',vResp.Document_Number__c);
		
		// resp3 has no existing doc/acc-code, adding new one do nothing
		vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp3.id];
		system.assertEquals('XXX3',vResp.Access_Code__c);
		system.assertEquals('3333',vResp.Document_Number__c);
		
		// resp4 has no exisitng, and got multiple ids, append additional ids
		vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp4.id];
		system.assertEquals('XXX4,XXX5',vResp.Access_Code__c);
		system.assertEquals('4444,5555',vResp.Document_Number__c);
		
		
		vResp = [select Mark_in__c,Document_Number__c,Access_Code__c from Response__c where ID=:resp5.id];
		system.assertEquals('YYY1',vResp.Access_Code__c);
		system.assertEquals('8881',vResp.Document_Number__c);
		system.assert(!vResp.Mark_In__c);
		
		vResp = [select Number_of_Occupants__c,Document_Number__c,Access_Code__c from Response__c where ID=:resp6.id];
		system.assertEquals('YYY2',vResp.Access_Code__c);//no changes from insert
		system.assertEquals('8882',vResp.Document_Number__c); 
		system.assertEquals(0,vResp.Number_of_Occupants__c);
		
		
		DAC_Store__c[]vDac=[select document_id__c,Access_Code__c,response__c from DAC_Store__c where id in :dacs];
		// same order
		system.assertEquals(resp.id, vDac[0].response__c);
		system.assertEquals(resp.id, vDac[1].response__c);
		system.assertEquals(resp3.id, vDac[2].response__c);
		system.assertEquals(resp4.id, vDac[3].response__c);
		system.assertEquals(resp4.id, vDac[4].response__c);
		system.assertEquals(resp2.Id, vDac[5].response__c);
		system.assertEquals(resp.id, vDac[6].response__c);
		system.assertEquals(resp5.id, vDac[7].response__c);
		system.assertEquals(resp6.id, vDac[8].response__c);
		
		// reset trigger to recalculate df, so, we can process some mark-in
system.debug(logginglevel.error, 'creating mark-in');
		ResponseTriggerHandler.Executed=false;
		
		List<Mark_In_Request__c> mirlist = new List<Mark_In_Request__c>();
		Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
		mir.Form_Type__c = 'IF';
		mir.Document_Number__c = '1111';
		mir.Access_Code__c = 'XXX1';
		mirlist.add(mir);
		Mark_In_Request__c mir1 = TestDataHelper.createMarkInRequest(false);
		mir1.Form_Type__c = 'IF';
		mir1.Document_Number__c = '2222';
		mirlist.add(mir1);
		Mark_In_Request__c mir2 = TestDataHelper.createMarkInRequest(false);
		mir2.Form_Type__c = 'IF';
		mir2.Document_Number__c = '3333';
		mir2.Number_of_Occupants__c = null;
		mirlist.add(mir2);
		Mark_In_Request__c mir3 = TestDataHelper.createMarkInRequest(false);
		mir3.Form_Type__c = null;
		mir3.Document_Number__c = '8882';
		mir3.Access_Code__c = null;
		mir3.Number_of_Occupants__c = 3;
		mirlist.add(mir3);
		Mark_In_Request__c mir4 = TestDataHelper.createMarkInRequest(false);
		mir4.Form_Type__c = 'IF';
		mir4.Document_Number__c = '5555';
		mir4.Number_of_Occupants__c = null;
		mirlist.add(mir4);
		Mark_In_Request__c mir5 = TestDataHelper.createMarkInRequest(false);
		mir5.Form_Type__c = 'IF';
		mir5.Document_Number__c = '4444';
		mir5.Number_of_Occupants__c = null;
		mirlist.add(mir5);
		Mark_In_Request__c mir6 = TestDataHelper.createMarkInRequest(false);
		mir6.Form_Type__c = 'IF';
		mir6.Document_Number__c = '9999';
		mir6.Number_of_Occupants__c = null;
		mirlist.add(mir6); 
		Mark_In_Request__c mir7 = TestDataHelper.createMarkInRequest(false);
		mir7.Form_Type__c = 'IF';
		mir7.Document_Number__c = '8881';
		mir7.Number_of_Occupants__c = null;
		mirlist.add(mir7); 
		Mark_In_Request__c mir8 = TestDataHelper.createMarkInRequest(false);
		mir8.Form_Type__c = 'DF';
		mir8.Document_Number__c = null;
		mir8.Access_Code__c = 'YYY1';
		mir8.Number_of_Occupants__c = null;
		mirlist.add(mir8); 
		Mark_In_Request__c mir9 = TestDataHelper.createMarkInRequest(false);
		mir9.Form_Type__c = 'IF';
		mir9.Document_Number__c = '8888';
		mir9.Number_of_Occupants__c = null;
		mirlist.add(mir9); 
		Mark_In_Request__c mir10 = TestDataHelper.createMarkInRequest(false);
		mir10.Form_Type__c = 'IF';
		mir10.Document_Number__c = '888812';
		mir10.Number_of_Occupants__c = 20;
		mirlist.add(mir10); // error
		Mark_In_Request__c mir11 = TestDataHelper.createMarkInRequest(false);
		mir11.Form_Type__c = 'DF'; 
		mir11.Document_Number__c = '8881';
		mir11.Access_Code__c = null;
		mir11.Number_of_Occupants__c = null;
		mirlist.add(mir11); 
		
		insert mirlist;//12 requests
		
		Test.stopTest();
	   
		// 12 mark-in requests
		// 2 - error
		// 1 - mark in primary df
		// 1 - create new df (dup)
		// 7 - new IFs
		// 1 - update primary df on occupany
	   
		vResp = [select Mark_In__c, Response_Summary_status__c, Status__c from Response__c where ID=:resp5.id];
		system.assert(vResp.Mark_In__c);
		system.assertEquals('Completed',vResp.Status__c);
		system.assertEquals('Completed',vResp.Response_Summary_status__c);
		vResp = [select Number_of_Occupants__c, Response_Summary_status__c, Status__c from Response__c where ID=:resp6.id];
		system.assertEquals('no response',vResp.Status__c.toLowerCase());
		system.assertEquals('no response',vResp.Response_Summary_status__c.toLowerCase());
		system.assertEquals(3,vResp.Number_of_Occupants__c);
		List<Mark_In_Request__c> mi = [Select Id,Document_Number__c,Access_Code__c from Mark_In_Request__c where failed__c = true];
		system.assertEquals(2, mi.size(),mi);
		List<Response__c> res2 = [Select Id from Response__c where Id not in :resId and RecordType.Name = 'Census Individual'];
		system.assertEquals(7, res2.size());
		List<Response__c> res1 = [Select Id from Response__c where Id not in :resId and RecordType.Name = 'Census Dwelling'];
		system.assertEquals(1, res1.size());
		
	}
	
	
	
	@isTest static void testMethod_simultaneous_requests_DF_Occu(){
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
		Contact cnt = TestDataHelper.createContact(true);
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.Unit_of_Interest_ID__c ='ERICABC1';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '123';
		unitObj.P_O_Box__c = null;
		unitObj.DP_ID__c='1111';
		upsert new Unit__c[]{unitObj};
		// this is the primary resp
		Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp.RecordTypeId = dfID;
		resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTest1ERICABC';
		resp.access_code__c='XXX1';
		resp.document_number__c='1111';
		insert new Response__c[]{resp};
		DAC_Store__c[]dacs=new DAC_Store__c[]{
			new DAC_Store__c(document_id__c='1111', access_code__c='XXX1', Response__c=resp.id)
		};
		insert dacs;
		ResponseTriggerHandler.Executed=false;
		
		Test.startTest();
		List<Mark_In_Request__c> mirlist = new List<Mark_In_Request__c>();
		Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
		mir.Form_Type__c = 'IF';
		mir.Document_Number__c = '1111';
		mir.Access_Code__c = 'XXX1';
		mirlist.add(mir);
		Mark_In_Request__c mir1 = TestDataHelper.createMarkInRequest(false);
		mir1.Form_Type__c = 'IF';
		mir1.Document_Number__c = '1111';
		mirlist.add(mir1);
		Mark_In_Request__c mir2 = TestDataHelper.createMarkInRequest(false);
		mir2.Form_Type__c = 'DF';
		mir2.Document_Number__c = '1111';
		mir2.Number_of_Occupants__c = null;
		mirlist.add(mir2);
		Mark_In_Request__c mir3 = TestDataHelper.createMarkInRequest(false);
		mir3.Form_Type__c = null;
		mir3.Document_Number__c = null;
		mir3.Access_Code__c = 'XXX1';
		mir3.Number_of_Occupants__c = 3;
		mirlist.add(mir3);
		insert mirlist;
		Test.stopTest();
		
		Response__c vResp = [select Mark_in__c,Number_of_Occupants__c, Response_Summary_status__c, Status__c from Response__c where ID=:resp.id];
		system.assert(vResp.Mark_in__c);
		system.assertEquals(3,vResp.Number_of_Occupants__c);
		system.assertEquals('completed',vResp.Status__c.toLowerCase());
		system.assertEquals('no response',vResp.Response_Summary_status__c.toLowerCase());
	}

	@isTest static void testMethod_simultaneous_requests_Occu_DF(){
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
		Contact cnt = TestDataHelper.createContact(true);
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.Unit_of_Interest_ID__c ='ERICABC1';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '123';
		unitObj.P_O_Box__c = null;
		unitObj.DP_ID__c='1111';
		upsert new Unit__c[]{unitObj};
		// this is the primary resp
		Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
		resp.RecordTypeId = dfID;
		resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTest1ERICABC';
		resp.access_code__c='XXX1';
		resp.document_number__c='1111';
		insert new Response__c[]{resp};
		DAC_Store__c[]dacs=new DAC_Store__c[]{
			new DAC_Store__c(document_id__c='1111', access_code__c='XXX1', Response__c=resp.id)
		};
		insert dacs;
		ResponseTriggerHandler.Executed=false;
		
		Test.startTest();
		List<Mark_In_Request__c> mirlist = new List<Mark_In_Request__c>();
		Mark_In_Request__c mir = TestDataHelper.createMarkInRequest(false);
		mir.Form_Type__c = 'IF';
		mir.Document_Number__c = '1111';
		mir.Access_Code__c = 'XXX1';
		mirlist.add(mir);
		Mark_In_Request__c mir1 = TestDataHelper.createMarkInRequest(false);
		mir1.Form_Type__c = 'IF';
		mir1.Document_Number__c = '1111';
		mirlist.add(mir1);
		Mark_In_Request__c mir2 = TestDataHelper.createMarkInRequest(false);
		mir2.Document_Number__c = '1111';
		mir2.Form_Type__c = null;
		mir2.Access_Code__c = null;
		mir2.Number_of_Occupants__c = 2;
		mirlist.add(mir2);
		Mark_In_Request__c mir3 = TestDataHelper.createMarkInRequest(false);
		mir3.Form_Type__c = 'DF';
		mir3.Document_Number__c = null;
		mir3.Access_Code__c = 'XXX1';
		mirlist.add(mir3);
		insert mirlist;
		Test.stopTest();
		
		Response__c vResp = [select Mark_in__c,Number_of_Occupants__c, Response_Summary_status__c, Status__c from Response__c where ID=:resp.id];
		system.assertEquals(2,vResp.Number_of_Occupants__c);
		system.assert(vResp.Mark_in__c);
		system.assertEquals('completed',vResp.Status__c.toLowerCase());
		system.assertEquals('completed',vResp.Response_Summary_status__c.toLowerCase());
	}

}