/* Eric created this class to test specific census scenarios
*/
@isTest
private class CensusMobileTest {
	@testsetup
	private static void setup(){
		TestDataHelper.createResponseProperties();
	}

	@istest private static void testBirthWithMultipleDAC(){
		
		// not using a setup, as this is very specific setup
        DAC_Store__c[]dacs=new DAC_Store__c[]{
        	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
        	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
        	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
        	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
        	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5')
        };
        insert dacs;
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
		unitObj.Unit_of_Interest_ID__c =null;  // simulate a birth with no uoi-id
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
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = '3333,1111,5555,3333';
		resp.access_code__c=null;
		insert resp;
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.work_item_type__c = 'List leave';
		wi.Status__c = 'New';
		insert wi;
		
		
		Response__c vResp = [select document_number__c, access_code__c from Response__c];
		system.assertEquals('3333,1111,5555', vResp.document_number__c);
		system.assertEquals('XXX3,XXX1,XXX5', vResp.access_code__c);
		
		for (DAC_Store__c vDAC: [select response__c from DAC_Store__c where document_id__c in ('1111','3333','5555')] ){
			system.assertEquals(vResp.id, vDAC.response__c);
		}
		
	}
    

	@istest private static void testUpdateMultipleDAC(){
		
		// not using a setup, as this is very specific setup
        DAC_Store__c[]dacs=new DAC_Store__c[]{
        	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
        	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
        	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
        	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
        	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5')
        };
        insert dacs;
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
		unitObj.Unit_of_Interest_ID__c ='ERICTESTDATA';  // simulate a birth with no uoi-id
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
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = '1111';
		resp.access_code__c='XXX1';
		insert resp;
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.work_item_type__c = 'List leave';
		wi.Status__c = 'New';
		insert wi;
		
		DAC_Store__c vDAC1 = [select response__c from DAC_Store__c where document_id__c in ('1111')];
		system.assertEquals(resp.id, vDAC1.response__c);
		Response__c vResp = [select document_number__c, access_code__c from Response__c];
		system.assertEquals('1111', vResp.document_number__c);
		system.assertEquals('XXX1', vResp.access_code__c);

		Test.startTest();
        ResponseTriggerHandler.dacExecuted=false;
        resp.Document_number__c = '3333,5555,3333';
        update resp;
		Test.stopTest();
		
		
		vResp = [select document_number__c, access_code__c from Response__c];
		system.assertEquals('3333,5555', vResp.document_number__c);
		system.assertEquals('XXX3,XXX5', vResp.access_code__c);
		for (DAC_Store__c vDAC: [select response__c from DAC_Store__c where document_id__c in ('3333','5555')] ){
			system.assertEquals(vResp.id, vDAC.response__c);
		}
	}

	@istest private static void testUpdateMultipleDACDuplicate(){
		
		// not using a setup, as this is very specific setup
        DAC_Store__c[]dacs=new DAC_Store__c[]{
        	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
        	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
        	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
        	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
        	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5')
        };
        insert dacs;
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
		unitObj.Unit_of_Interest_ID__c ='ERICTESTDATA';  // simulate a birth with no uoi-id
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
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = '1111';
		resp.access_code__c='XXX1';
		insert resp;
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
		wi.Work_Item_ExtId__c = 'TEST1';
		wi.Delivery_Mode__c = 'TEST1';
		wi.work_item_type__c = 'List leave';
		wi.Status__c = 'New';
		insert wi;
		
		DAC_Store__c vDAC1 = [select response__c from DAC_Store__c where document_id__c in ('1111')];
		system.assertEquals(resp.id, vDAC1.response__c);
		Response__c vResp = [select document_number__c, access_code__c from Response__c];
		system.assertEquals('1111', vResp.document_number__c);
		system.assertEquals('XXX1', vResp.access_code__c);

		Test.startTest();
        ResponseTriggerHandler.dacExecuted=false;
        resp.Document_number__c = '3333,5555,3333,1111';
        update resp;
		Test.stopTest();
		
		
		vResp = [select document_number__c, access_code__c from Response__c];
		system.assertEquals('3333,5555,1111', vResp.document_number__c);
		system.assertEquals('XXX3,XXX5,XXX1', vResp.access_code__c);
		for (DAC_Store__c vDAC: [select response__c from DAC_Store__c where document_id__c in ('1111', '3333', '5555')] ){
			system.assertEquals(vResp.id, vDAC.response__c);
		}
	}

	@istest private static void testUpdateDACDuplicateReponses(){
		
		// not using a setup, as this is very specific setup
        DAC_Store__c[]dacs=new DAC_Store__c[]{
        	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
        	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
        	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
        	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
        	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5'),
        	new DAC_Store__c(document_id__c='6666', access_code__c='XXX6'),
        	new DAC_Store__c(document_id__c='7777', access_code__c='XXX7'),
        	new DAC_Store__c(document_id__c='8888', access_code__c='XXX8'),
        	new DAC_Store__c(document_id__c='9999', access_code__c='XXX9')
        };
        insert dacs;
        
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		
		Unit__c[]units=new Unit__c[]{};
		for(integer i=0; i<5; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ERICTESTDATA'+i;  
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c='12345';
			units.add(unitObj);
		}
		insert units;
		
		Response__c[] resps=new Response__c[]{};
		for(integer i=0; i<5; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[i].Id, false);
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.access_code__c=null; // set to null, will be set by before trigger
			resps.add(resp);
		}
		resps[0].document_number__c='1111';
		resps[1].document_number__c='2222';
		resps[2].document_number__c='3333';
		resps[3].document_number__c=null;
		resps[4].document_number__c='5555';
        Database.SaveResult[] yyy= Database.insert(resps,new Database.DMLOptions());
        
		// before trigger logic has run, and set the access code to the right values
		Response__c[] vResps=[select id, Document_number__c, access_code__c from Response__c];
		system.assertEquals('XXX1', vResps[0].Access_code__c);
		system.assertEquals('XXX2', vResps[1].Access_code__c);
		system.assertEquals('XXX3', vResps[2].Access_code__c);
		system.assertEquals(null,   vResps[3].Access_code__c);
		system.assertEquals('XXX5', vResps[4].Access_code__c);

		// retesting before trigger logic, but one of the record will failed
		Test.startTest();
        ResponseTriggerHandler.dacExecuted=false;
        resps[0].Document_number__c = '1111,9999'; // add 9999 to the existing
        resps[1].Document_number__c='2222,9999'; // also add 9999 to the existing list.... expecting this record to fail update due to unique constraints
        resps[2].Document_number__c='8888'; // replace with 8888
        resps[3].Document_number__c='7777'; // set it from null
        resps[4].Document_number__c='5555'; // leave it unchange
        Database.SaveResult[] xxx= Database.update(resps,new Database.DMLOptions());
		Test.stopTest();
		
		Response__c vR = [select document_number__c, access_code__c from Response__c where id = :resps[0].id];
		system.assertEquals('1111,9999', vR.document_number__c);  // expecting '9999', as this record contains no error
		system.assertEquals('XXX1,XXX9', vR.access_code__c); // however, before trigger logic has gone
		system.assert(xxx[0].isSuccess());  // record has been saved successfully, but only half the logic has been committed
		
		vR = [select document_number__c, access_code__c from Response__c where id = :resps[1].id];
		system.assertEquals('2222,9999', vR.document_number__c); // changes on this record has rolled back due to error on updating
		system.assertEquals('XXX2,XXX9', vR.access_code__c); // roll back to previous state
		system.assert(xxx[1].isSuccess()); 

		vR = [select document_number__c, access_code__c from Response__c where id = :resps[2].id];
		system.assertEquals('8888', vR.document_number__c); // as expected, record saved with new doc-id
		system.assertEquals('XXX8', vR.access_code__c); // however, before trigger logic has gone
		system.assert(xxx[2].isSuccess()); // no error, but access-code logic is gone, and record is "semi" commited

		vR = [select document_number__c, access_code__c from Response__c where id = :resps[3].id];
		system.assertEquals('7777', vR.document_number__c); // as expected, record saved with new doc-id
		system.assertEquals('XXX7', vR.access_code__c); // however, the access-code mapping (before trigger logic) disappear
		system.assert(xxx[3].isSuccess());
		
		vR = [select document_number__c, access_code__c from Response__c where id = :resps[4].id];
		system.assertEquals('5555', vR.document_number__c); // no changes
		system.assertEquals('XXX5', vR.access_code__c); // expect no changes, but wiped the previously set value
		system.assert(xxx[4].isSuccess()); // no changes

	}

	@istest private static void testInsertDACDuplicateReponses(){
		
		// not using a setup, as this is very specific setup
        DAC_Store__c[]dacs=new DAC_Store__c[]{
        	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
        	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
        	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
        	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
        	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5'),
        	new DAC_Store__c(document_id__c='6666', access_code__c='XXX6'),
        	new DAC_Store__c(document_id__c='7777', access_code__c='XXX7'),
        	new DAC_Store__c(document_id__c='8888', access_code__c='XXX8'),
        	new DAC_Store__c(document_id__c='9999', access_code__c='XXX9')
        };
        insert dacs;
        
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		
		Unit__c[]units=new Unit__c[]{};
		for(integer i=0; i<5; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ERICTESTDATA'+i;  
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c='12345';
			units.add(unitObj);
		}
		insert units;
		
		Response__c[] resps=new Response__c[]{};
		for(integer i=0; i<5; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[i].Id, false);
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.access_code__c=null; // set to null, will be set by before trigger
			resps.add(resp);
		}
		resps[0].document_number__c='1111';
		resps[1].document_number__c='2222';
		resps[2].document_number__c='3333';
		resps[3].document_number__c='5555';
		resps[4].document_number__c='5555';
        Database.SaveResult[] xxx= Database.insert(resps,new Database.DMLOptions());
        
		// before trigger logic has run, and set the access code to the right values
		Response__c[] vResps=[select id, Document_number__c, access_code__c from Response__c];
		system.assert(xxx[0].isSuccess()); 
		system.assertEquals(vResps[0].Access_code__c, 'XXX1');
		system.assert(xxx[1].isSuccess()); 
		system.assertEquals(vResps[1].Access_code__c, 'XXX2');
		system.assert(xxx[2].isSuccess()); 
		system.assertEquals(vResps[2].Access_code__c, 'XXX3');
		system.assert(xxx[3].isSuccess()); 
		system.assertEquals(vResps[3].Access_code__c, 'XXX5');
		system.assert(xxx[4].isSuccess()); 
		system.assertEquals(1, [select count() from Response__c where id=:resps[4].id ]);

	}
}