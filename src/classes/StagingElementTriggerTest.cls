@isTest
private class StagingElementTriggerTest {
	
	public static testmethod void testStagingElementWorkitemType() {

		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;
		
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
		insert collectionInstance;

		Set<String> validWorkItemTypes = new Set<String>{
			'Pre-notification',
			'Questionnaire',
			'Courtesy contact',
			'Pre-notification',
			'Questionnaire',
			'Courtesy contact',
			'Reminder',
			'Non-response follow-up',
			'Replacement questionnaire',
			'Address canvassing',
			'List leave',
			'Access code',
			'Statsgate link',
			'Inbound Enquiry'
		};

		List<Staging_Element__c> goodElements = new List<Staging_Element__c>();
		for(String validWorkItemType:validWorkItemTypes){
			Staging_Element__c e = new Staging_Element__c();
			e.WI_Work_Item_Type__c = validWorkItemType;
			e.CI_Collection_Instance_Code__c = 'CICODE';
			e.R_Mark_In_Required__c = true;
			goodElements.add(e);
		}
		
		Staging_Element__c badE_1 = new Staging_Element__c();
		badE_1.WI_Work_Item_Type__c = 'address canvassing';
		badE_1.CI_Collection_Instance_Code__c = 'CICODE';
		badE_1.R_Mark_In_Required__c = true;
		
		Staging_Element__c badE_2 = new Staging_Element__c();
		badE_2.WI_Work_Item_Type__c = 'Address Canvassing';
		badE_2.CI_Collection_Instance_Code__c = 'CICODE';
		badE_2.R_Mark_In_Required__c = true;
		
		Staging_Element__c badE_3 = new Staging_Element__c();
		badE_3.WI_Work_Item_Type__c = 'some other type';
		badE_3.CI_Collection_Instance_Code__c = 'CICODE';
		badE_3.R_Mark_In_Required__c = true;

		try{
			insert goodElements;
			System.assert(true);
		}catch(Exception e){
			System.assert(false);
		}

		try{
			insert badE_1;
			System.assert(false);
		}catch(DmlException e){
			System.assert(true);
		}

		try{
			insert badE_2;
			System.assert(false);
		}catch(DmlException e){
			System.assert(true);
		}

		try{
			insert badE_3;
			System.assert(false);
		}catch(DmlException e){
			System.assert(true);
		}
	}

	public static testmethod void testMarkinrequired() {
		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;
		
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
		insert collectionInstance;

		Staging_Element__c e = new Staging_Element__c();
		e.WI_Work_Item_Type__c = 'Address canvassing';
		e.CI_Collection_Instance_Code__c = 'CICODE';
		e.R_Mark_In_Required__c = false;
		e.A_Instrument_Code__c = 'aCode';
		insert e;
		
		Staging_Element__c e2 = [select R_Mark_In_Required__c from Staging_Element__c where Id = :e.Id];
		System.assert(e2.R_Mark_in_Required__c);
	}
		
	public static testmethod void testError_1() {
		Staging_Element__c se = new Staging_Element__c();
		se.WI_Work_Item_Type__c = 'Address canvassing';
		se.CI_Collection_Instance_Code__c = 'CICODE';
		se.R_Mark_In_Required__c = false;
		se.A_Instrument_Code__c = 'aCode';
		
		try{
			insert se;
			System.assert(false);
		}catch(DmlException e){
			System.assert(true);
		}
	}
		
	public static testmethod void testError_2() {
		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;
		
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
		insert collectionInstance;
		
		List<Staging_Element__c> ses = new List<Staging_Element__c>();

		Staging_Element__c se = new Staging_Element__c();
		se.WI_Work_Item_Type__c = 'Address canvassing';
		se.CI_Collection_Instance_Code__c = 'CICODE';
		se.R_Mark_In_Required__c = false;
		se.A_Instrument_Code__c = 'aCode';
		ses.add(se);
		
		Staging_Element__c se2 = new Staging_Element__c();
		se2.WI_Work_Item_Type__c = 'Address canvassing';
		se2.CI_Collection_Instance_Code__c = 'CICODE_Random';
		se2.R_Mark_In_Required__c = false;
		se2.A_Instrument_Code__c = 'aCode';
		ses.add(se2);
		
		try{
			insert ses;
			System.assert(false);
		}catch(DmlException e){
			System.assert(true);
		}
	}

	public static testmethod void testProcessCensusElements() {
		Id censusCollectionRecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		collection.RecordTypeId = censusCollectionRecordTypeId;
		insert collection;
		
		Id censusCollectionInstanceRecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
		collectionInstance.RecordTypeId = censusCollectionInstanceRecordTypeId;
		insert collectionInstance;

		Staging_Element__c stagingElement = TestDataHelper.createStagingElement(false);
		stagingElement.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement.U_DP_ID__c = '421';
		stagingElement.U_Unit_of_Interest_Id__c = '';
		stagingElement.R_Access_Code__c = '2';
		stagingElement.WL_Workload_ID__c = 'wl102';
		stagingElement.WI_Work_Item_ExtId__c = null;
		stagingElement.C_Legacy_Contact_ID__c =null;
		stagingElement.CR_Contact_ExtId__c = null;
		stagingElement.CR_Unit_Of_Interest_Id__c = null;
		stagingElement.A_Instrument_Code__c = null;
		stagingElement.R_Mark_in_Required__c = true;
		stagingElement.Collection_Unit__c = true;
		stagingElement.Survey_Unit__c = true;
		stagingElement.R_Unit_Association__c = '421';
		stagingElement.U_Meshblock_Code__c = '1';
		stagingElement.U_Building_Name__c = 'Building2';
		stagingElement.R_Response_ExtId__c = null;
		stagingElement.Account_External_Id__c = null;
		stagingElement.WI_Work_Item_Type__c = 'Address canvassing';

		insert stagingElement;

		List<Workload__c> workloads = [select Id from Workload__c];
		List<Response__c> responses = [select Id from Response__c];
		List<Unit__c> units = [select Id from Unit__c];
		List<Work_Item__c> workitems = [select Id from Work_Item__c];

		System.assertEquals(1, workloads.size());
		System.assertEquals(1, responses.size());
		System.assertEquals(1, units.size());
		System.assertEquals(1, workitems.size());
	}
}