@isTest
private class ProcessStagingElementsExCon_Test{
	
	@TestSetup
	public static void dataSetup(){
		TestDataHelper.createResponseProperties();
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'fileUploadBatchSize', value__c = '1000')
		};
	}
	
    @isTest 
	static void testConstructor() {
		Collection__c c = new Collection__c();
		c.Name = 'test Collection';
		insert c;

		Collection_Instance__c ci = new Collection_Instance__c();
		ci.Name = 'testName';
		ci.Collection__c = c.Id;
		insert ci;

		ApexPages.StandardController stdController = new ApexPages.StandardController(ci);
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);
	}
		
	@isTest 
	static void testProcessStagingElements_2(){
		Collection__c c = new Collection__c();
		c.Name = 'test Collection';
		insert c;

		Collection_Instance__c ci = new Collection_Instance__c();
		ci.Name = 'testName';
		ci.Collection__c = c.Id;
		insert ci;
        ci = [Select Collection_Instance_Code__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c,batch_job_id__c
        	from Collection_Instance__c where Id = :ci.id];

		ApexPages.StandardController stdController = new ApexPages.StandardController(ci);
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);

		instance.processStagingElements();
	}
	
	@isTest 
	static void testProcessStagingElements_3(){
		Collection__c c = new Collection__c();
		c.Name = 'test Collection';
		insert c;

		Collection_Instance__c ci = new Collection_Instance__c();
		ci.Name = 'testName';
		ci.Collection__c = c.Id;
		insert ci;
        ci = [Select Collection_Instance_Code__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c,batch_job_id__c
        	from Collection_Instance__c where Id = :ci.id];

		ApexPages.StandardController stdController = new ApexPages.StandardController(ci);
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);

		instance.processStagingElements();
		instance.processStagingElements();
	}
	
	@isTest 
	static void testBack_1(){
		Collection__c c = new Collection__c();
		c.Name = 'test Collection';
		insert c;

		Collection_Instance__c ci = new Collection_Instance__c();
		ci.Name = 'testName';
		ci.Collection__c = c.Id;
		insert ci;

		ApexPages.StandardController stdController = new ApexPages.StandardController(ci);
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);

		//PageReference pr = instance.back();
		//System.assertNotEquals(null, pr);
	}
	
	@isTest 
	static void testBack_2(){
		Collection__c c = new Collection__c();
		c.Name = 'test Collection';
		insert c;

		Collection_Instance__c ci = new Collection_Instance__c();
		ci.Name = 'testName';
		ci.Collection__c = c.Id;
		insert ci;

		ci.Id = null;

		ApexPages.StandardController stdController = new ApexPages.StandardController(ci);
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);
	}
    
    @isTest static void processImportsFromStagingBatchTest(){
		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;

		Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
		insert collectionInstance;
		
		Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
		artefact.Name = 'ACODE';
		insert artefact;

		Unit__c unit = TestDataHelper.createUnit(false);
		unit.Unit_of_Interest_ID__c = 'unit42';
		unit.DP_ID__c = '';
		insert unit;
        
		List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
		Staging_Element__c stagingElement1 = new Staging_Element__c(); //TestDataHelper.createStagingElement(false);
		stagingElement1.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement1.U_DP_ID__c = 'unit42';
		stagingElement1.U_Unit_of_Interest_Id__c = 'unit42';
		stagingElement1.U_Record_Type__c = 'ENT';
        stagingElement1.R_Delivery_Rural_Delivery_Number__c = null;
        stagingElement1.R_Delivery_Level_Number__c = null;
		stagingElement1.R_Unit_Association__c = 'unit42';
		stagingElements.add(stagingElement1);
		
		Staging_Element__c stagingElement2 = new Staging_Element__c();
		stagingElement2.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement2.U_Unit_of_Interest_Id__c = 'unit43';
		stagingElement2.U_Record_Type__c = 'ENT';
        stagingElement2.R_Delivery_Rural_Delivery_Number__c = null;
        stagingElement2.R_Delivery_Level_Number__c = null;
		stagingElement2.R_Unit_Association__c = 'unit43';
		stagingElements.add(stagingElement2);

		Staging_Element__c stagingElement3 = new Staging_Element__c();
		stagingElement3.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement3.U_Unit_of_Interest_Id__c = 'unit44';
		stagingElement3.U_Record_Type__c = 'KAU';
        stagingElement3.R_Delivery_Rural_Delivery_Number__c = null;
        stagingElement3.R_Delivery_Level_Number__c = null;
		stagingElement3.R_Unit_Association__c = 'unit44';
		stagingElements.add(stagingElement3);

		Staging_Element__c stagingElement4 = new Staging_Element__c();
		stagingElement4.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement4.U_Unit_of_Interest_Id__c = 'unit45';
		stagingElement4.U_Record_Type__c = 'GEO';
        stagingElement4.R_Delivery_Rural_Delivery_Number__c = null;
        stagingElement4.R_Delivery_Level_Number__c = null;
		stagingElement4.R_Unit_Association__c = 'unit45';
		stagingElements.add(stagingElement4);

		Staging_Element__c stagingElement5 = new Staging_Element__c();
		stagingElement5.CI_Collection_Instance_Code__c = 'CICODE';
		stagingElement5.U_Unit_of_Interest_Id__c = 'unit46';
		stagingElement5.U_Record_Type__c = 'ENT';
        stagingElement5.R_Delivery_Rural_Delivery_Number__c = null;
        stagingElement5.R_Delivery_Level_Number__c = null;
		stagingElement5.R_Unit_Association__c = 'unit46';
		stagingElements.add(stagingElement5);
		
		insert stagingElements;

        collectionInstance = [select Collection_Instance_Code__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c,Batch_Job_Id__c
                              from 	Collection_Instance__c 
                              where Id = :collectionInstance.Id];
        
		ApexPages.StandardController stdController = new ApexPages.StandardController(collectionInstance);
        test.startTest();
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);
        instance.processStagingElements();
        test.stopTest();
        List<Unit__c> ul = [Select Id from Unit__c];
		System.assertEquals(5, ul.size());
		//System.assertEquals(5, stagingElements.size());
        List<Staging_Element__c> se = [Select Id,Failed__c,Errors__c from Staging_Element__c where Failed__c = true];
        system.debug('se=='+se);
    }

    @isTest static void processDeleteFromStagingBatchTest(){
		Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;

		Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
		insert collectionInstance;
		
		Unit__c unit = TestDataHelper.createUnit(false);
		unit.Unit_of_Interest_ID__c = 'unit42';
		unit.DP_ID__c = '';
		insert unit;
        
		Staging_Element__c[]stagingElements = new Staging_Element__c[]{
			new Staging_Element__c(CI_Collection_Instance_Code__c = 'CICODE',failed__c=true,U_Unit_of_Interest_Id__c='ERIC111'),
			new Staging_Element__c(CI_Collection_Instance_Code__c = 'CICODE',failed__c=true,U_Unit_of_Interest_Id__c='ERIC222'),
			new Staging_Element__c(CI_Collection_Instance_Code__c = 'CICODE',failed__c=true,U_Unit_of_Interest_Id__c='ERIC333'),
			new Staging_Element__c(CI_Collection_Instance_Code__c = 'CICODE',failed__c=true,U_Unit_of_Interest_Id__c='ERIC444'),
			new Staging_Element__c(CI_Collection_Instance_Code__c = 'CICODE',failed__c=true,U_Unit_of_Interest_Id__c='ERIC555')
		};
		insert stagingElements;

        collectionInstance = [select Collection_Instance_Code__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c,Batch_Job_Id__c
                              from 	Collection_Instance__c 
                              where Id = :collectionInstance.Id];
        
		ApexPages.StandardController stdController = new ApexPages.StandardController(collectionInstance);
        test.startTest();
		ProcessStagingElementsExCon instance = new ProcessStagingElementsExCon(stdController);
        instance.deleteStagingElements();
        // this one shall fail, just for coverage purposes
        instance.processStagingElements();
        test.stopTest();
        
        Staging_Element__c[]v=[select id from Staging_ELement__c];
        system.assertEquals(0,v.size());
    }
	
	
}