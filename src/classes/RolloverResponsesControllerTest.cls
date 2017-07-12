@isTest
private class RolloverResponsesControllerTest {	
	public static Collection__c collection;
	public static Collection_Instance__c firstCI;
	public static Collection_Instance__c secondCI; 	// The one with all responses attached. The workload also. 
	public static Collection_Instance__c thirdCI;
	public static list<Response__c> responses; 		// Wave 2
	public static Workload__c wl;					// For PSU 2. Attached to WI[1], if existing. 
	public static list<Work_Item__c> workItems; 	//  leave at least one with no work item. If responses number is 1, then no workitem is created.
	public static list<Unit__c> units; 				// PSU: from 1 to numberOfResponses.
    public static Id ciSocialRT;
    public static Special_Arrangement__c dniSA; 					// DNI Special Arrangement for first response/unit on the list.
    public static Special_Arrangement__c seventyFivePlusSA; 		// 75+ Special Arrangement for the fifth response/unit on the list. All months suppressed 
    public static Special_Arrangement__c seventy5NoSuppressionSA;   // 75+ Special Arrangement for the third response/unit on the list. No active suppressed month
	    
    public static void setup(integer numberOfResponses){
    	if(numberOfResponses < 1){
    		system.debug('Error: number of responses must be 1 or higher');
    		return;
    	} 
    	collection = TestDataHelper.createCollection(false);
        collection.Name = 'HLFS';
        collection.Collection_Code__c = 'test';
    	collection.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert collection;
        ciSocialRT = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        firstCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        firstCI.RecordTypeId = ciSocialRT;
        firstCI.Collection_Number__c = 1;
        firstCI.Rollover_Status__c = null;
        insert firstCI;
        secondCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        secondCI.Name = 'secondCI';
        secondCI.Collection_Instance_Code__c = 'xxx2';
        secondCI.RecordTypeId = ciSocialRT;
        secondCI.Status__c = 'Active';
        secondCI.Collection_Number__c = 2;
        secondCI.Rollover_Status__c = null;
        secondCI.Planned_Start_Date__c = system.today();
        secondCI.Interview_Start_Date__c = system.today().addDays(10);
        secondCI.Planned_End_Date__c = system.today().addDays(200);
        insert secondCI;     
           
        thirdCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        thirdCI.RecordTypeId = ciSocialRT;
        thirdCI.Name = 'thirdCI';
        thirdCI.Collection_Number__c = 3;
     	thirdCI.Collection_Instance_Code__c = 'xxx3';
        thirdCI.Rollover_Status__c = null;
        secondCI.Status__c = 'Planned';
        thirdCI.Planned_Start_Date__c = system.today().addDays(5);
        thirdCI.Interview_Start_Date__c = system.today().addDays(60);
        thirdCI.Planned_End_Date__c = system.today().addDays(300);
        insert thirdCI;         
        
        // Insert unique Units for each response. 
        units = new List<Unit__c>();
        Id houseHoldRecordType = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Household Unit').getRecordTypeId();
        for(integer i=0;i<numberOfResponses;i++){
            Unit__c unit = TestDataHelper.createUnit(false);
            unit.RecordTypeId = houseHoldRecordType;
            unit.Unit_of_Interest_ID__c ='EN' + i;
            unit.Address_Type__c = null;
            unit.Other_Address_Type__c = null;
			unit.PSU_Number__c = String.valueOf(i + 1);
			unit.DP_ID__c='100' + i;
            unit.Rural_Delivery_Number__c = null;
            unit.Postcode__c = '1234';
            unit.P_O_Box__c = null;
            units.add(unit);
        }
        insert units;
        Contact c = TestDataHelper.createContact(true);
        Contact_Role__c cr = TestDataHelper.createContactRole(collection.Id, units[0].Id, c.Id, false);
        cr.Role__c = 'Respondent';
        insert cr;
        
        // Special Arrangement for the first in the list:
        List<Special_Arrangement__c> saToInsert = new List<Special_Arrangement__c>();
        Id saRecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
    	dniSA = new Special_Arrangement__c(RecordTypeId = saRecordTypeId,
										Collection__c = collection.Id, 
										DNI_Suppression_Approval__c = 'Pending',
										Survey_Unit__c = units[0].Id, 
										Suppression_Type__c = 'Do Not Interview',
										Rule_Start_Date__c = system.today(),
										Rule_End_Date__c=null);	
		saToInsert.add(dniSA);
		if(units.size() >= 5){
			seventyFivePlusSA = new Special_Arrangement__c(RecordTypeId = saRecordTypeId,
										Collection__c = collection.Id, 
										Survey_Unit__c = units[4].Id, 
										Month_1__c = true, Month_2__c = true,  Month_3__c = true,  Month_4__c = true,  Month_5__c = true,  Month_6__c = true,  Month_7__c = true,  Month_8__c = true, 
										Month_9__c = true,  Month_10__c = true,  Month_11__c = true,  Month_12__c = true,
										Suppression_Type__c = '75+',
										Rule_Start_Date__c = system.today(),
										Rule_End_Date__c=null);
			saToInsert.add(seventyFivePlusSA);
		}
		if(units.size() >= 3){
			seventy5NoSuppressionSA = new Special_Arrangement__c(RecordTypeId = saRecordTypeId,
										Collection__c = collection.Id, 
										Survey_Unit__c = units[2].Id, 
										Month_1__c = false, Month_2__c = false,  Month_3__c = false,  Month_4__c = false,  Month_5__c = false,  Month_6__c = false,  Month_7__c = false,  Month_8__c = false, 
										Month_9__c = false,  Month_10__c = false,  Month_11__c = false,  Month_12__c = false,
										Suppression_Type__c = '75+',
										Rule_Start_Date__c = system.today(),
										Rule_End_Date__c=null);
			saToInsert.add(seventy5NoSuppressionSA);
		}
		insert saToInsert;	
		
		for(ProcessInstanceWorkitem sa :[Select Id From ProcessInstanceWorkitem]){
			Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
	        req2.setComments('Approving request.');
	        req2.setAction('Approve');
	        req2.setWorkitemId(sa.Id); 
	        Approval.ProcessResult result2 =  Approval.process(req2);
		}
		
		// RESPONSES:
        responses = new List<Response__c>();
        for(integer i=0;i<numberOfResponses;i++){
            Response__c resp = TestDataHelper.createResponse(secondCI.Id, null, null, units[i].Id, false);
            resp.Access_Code__c = null;
            resp.Response_ExtId__c = null;
            resp.Rotation__c = '1';
            resp.Wave__c = '2';
            resp.RecordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
            responses.add(resp);
        }
        insert responses;
        // WORKLOAD:
        wl = TestDataHelper.createWorkload(false);
        wl.Collection_Instance__c = secondCI.Id;
        wl.Area_Unit_Reference__c = '2';
        wl.Workload_Type__c = 'Interview';
        wl.Area_Unit_Name__c = 'clone test';
        insert wl;
        
        workItems = new List<Work_Item__c>();
        for(integer i=0;i<numberOfResponses -1;i++){
             Work_Item__c wi =new Work_Item__c(	Status__c = 'New', 
												Response__c = responses[i].Id, 
												Work_Item_Type__c = 'Interview',
												Delivery_Mode__c = 'Post'	// To test cloned WI.
												);
            workItems.add(wi);
        }
        insert workItems;   
        if(workItems.size() > 1){
        	workItems[1].Workload__c = wl.Id;
        	update workItems[0];     
        }
    }
    
    @isTest static void testMassRollover(){
    	setup(201);
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);

		test.startTest();
		system.debug('## secondCI: ' + secondCI);
		system.debug('## thirdCI: ' + thirdCI);
		
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        controller.checkProgress();
		test.stopTest();   
		
		System.assertEquals(201, controller.numberOfResponsesToClone);
		// Check number of responses.
		List<Response__c> r = new List<Response__c>([select name from Response__c where Collection_Instance__c =: thirdCI.Id]);
		System.assertEquals(201, r.size());
		controller.checkProgress();
    }

    @isTest static void testNoPreviusCIFound(){
    	setup(1);
        PageReference page = new PageReference('RolloverResponses?id=' + firstCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(firstCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
		test.stopTest();   
		System.assertEquals(true, controller.showFailedValidation);
    }    
    
    @isTest static void testNoResponsesToClone(){
    	setup(1);
        PageReference page = new PageReference('RolloverResponses?id=' + secondCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(secondCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
		test.stopTest();  
		System.assertEquals(0, controller.numberOfResponsesToClone); 
		System.assertEquals(true, controller.showFailedValidation); 
    } 
    
    @isTest static void testCannotRolloverTwice(){
    	setup(1);
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        controller.startRollover(); // Cannot start process twice.
		test.stopTest();  
		System.assertEquals(false, controller.showFailedValidation); 
    }

    @isTest static void testPartialError(){
    	setup(1);
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();        
        Collection_Instance__c ci = [select Rollover_Status__c, Rollover_Error__c from Collection_Instance__c where id =: thirdCI.Id];
        ci.Rollover_Status__c = 'Partial Error';
        ci.Rollover_Error__c = 'test';
        update ci;
        controller.checkProgress(); 
        test.stopTest();
		System.assertEquals('Partial Error', controller.collectionInstanceStatus); 
    }
    
    @isTest static void testRolloverInProgress(){
    	setup(1);
        Collection_Instance__c fourthCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        fourthCI.RecordTypeId = ciSocialRT; 
        fourthCI.Name = 'fourthCI';
        fourthCI.Collection_Number__c = 4;
     	fourthCI.Collection_Instance_Code__c = 'xxx4';
        fourthCI.Rollover_Status__c = 'xxx job id';
        fourthCI.Planned_Start_Date__c = system.today().addDays(50);
        fourthCI.Interview_Start_Date__c = system.today().addDays(60);
        fourthCI.Planned_End_Date__c = system.today().addDays(300);
        insert fourthCI;
        PageReference page = new PageReference('RolloverResponses?id=' + fourthCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(fourthCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
		test.stopTest();  
		System.assertEquals(true, controller.showFailedValidation);  
    }
    
    @isTest static void testDNISuppression(){
    	setup(1);								
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		// Check response status = suppressed.
		List<Response__c> r = new List<Response__c>([select Status__c,Response_Status_Reason__c  from Response__c where Collection_Instance__c =: thirdCI.Id]);
		System.assertEquals('Suppressed', r[0].Status__c);  
		System.assertEquals('Do Not Interview', r[0].Response_Status_Reason__c);      
    }    

    @isTest static void test75PlusSuppression(){
    	setup(5);								
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		// Check only 1 response status = suppressed and reason = 75+
		List<Response__c> r = new List<Response__c>([	select Status__c,Response_Status_Reason__c  
														from Response__c 
														where Collection_Instance__c =: thirdCI.Id
														and Status__c = 'Suppressed'
														and Response_Status_Reason__c = '75+']);
		System.assertEquals(1, r.size());  
    } 

    @isTest static void test75PlusActivationAfterNoResponse(){
    	setup(5);
    	responses[4].Status__c = 'No Response';	 // This Response has an active 75+ SA. 
    	update responses;							
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		// Check there is no 75+ suppresions. Status should be loaded as previos quarter show no response. 
		List<Response__c> r = new List<Response__c>([	select Status__c,Response_Status_Reason__c  
														from Response__c 
														where Collection_Instance__c =: thirdCI.Id
														and Status__c = 'Suppressed'
														and Response_Status_Reason__c = '75+']);
		System.assertEquals(0, r.size());  
    } 


    @isTest static void testCATICAPI(){
    	setup(1);
    	responses[0].Collection_Mode__c = 'CATI';
    	responses[0].CATI_No_Response_Counter__c  = 1;	
    	responses[0].Status__c = 'No Response';
    	update responses;							
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		// Check response is CAPI and Counter reseted
		List<Response__c> r = new List<Response__c>([	select Status__c,Response_Status_Reason__c,CATI_No_Response_Counter__c  
														from Response__c 
														where Collection_Instance__c =: thirdCI.Id
														and Collection_Mode__c = 'CAPI']);
		System.assertEquals(1, r.size()); 
		System.assertEquals(0, r[0].CATI_No_Response_Counter__c); 
    }

    @isTest static void testCAPICATI(){
    	setup(1);
    	responses[0].Collection_Mode__c = 'CAPI';
    	responses[0].CATI_Indicator__c  = true;	
    	update responses;							
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		// Check response is CATI
		List<Response__c> r = new List<Response__c>([	select CATI_Indicator__c,Status__c,Response_Status_Reason__c,CATI_No_Response_Counter__c  
														from Response__c 
														where Collection_Instance__c =: thirdCI.Id
														and Collection_Mode__c = 'CATI']);
		System.assertEquals(1, r.size()); 
		System.assertEquals(false, r[0].CATI_Indicator__c); 
    }
                    
    @isTest static void testWorkItemWorkLoadRollover(){
    	// 3 responses been created, 1 suppressed, second one with a WI, and a WL, third one active with none. Test clone and created from scratch.
    	setup(3);								
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		map<Id,Response__c> rs = new map<Id,Response__c>([select Status__c,Response_Status_Reason__c  from Response__c where Collection_Instance__c =: thirdCI.Id]);
		List<Work_Item__c> wis = new List<Work_Item__c>([select Delivery_Mode__c from Work_Item__c where Response__c IN : rs.keySet() and Workload__c != null]);
		List<Workload__c> wls = new List<Workload__c>([select Area_Unit_Name__c from Workload__c where Collection_Instance__c =: thirdCI.Id]);
		// Check # of responses created.
		System.assertEquals(3, rs.size());  
		// Check 1 is suppresed.
		Integer responsesDNI = 0;
		for(Response__c r : rs.values()){
			if(r.Response_Status_Reason__c == 'Do Not Interview') {responsesDNI++;}
		}
		System.assertEquals(1, responsesDNI);   
		// Check 3 wl where created and only 1 workload was cloned.
		System.assertEquals(3, wls.size());
		Integer clonedWL = 0;
		for(Workload__c wload : wls){
			if(wload.Area_Unit_Name__c == 'clone test') {clonedWL++;}
		}
		System.assertEquals(1, clonedWL);
		// Check 2 WI where created. All with Workloads assigned. (First Response is suppressed so no WI.)
		System.assertEquals(2, wis.size());
    } 
    
    // Change all units to belong to one PSU and check only one wl was created.
    @isTest static void testWorkLoadContactRoleRollover(){
    	setup(3);	
    	units[0].PSU_Number__c = '2'; // Set all units to belong to the same PSU, so 1 workload with 2 wi... (1 response is suppressed)							
        units[2].PSU_Number__c = '2';
        update units;
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		map<Id,Response__c> rs = new map<Id,Response__c>([select Status__c,Response_Status_Reason__c  from Response__c where Collection_Instance__c =: thirdCI.Id]);
		List<Work_Item__c> wis = new List<Work_Item__c>([select Delivery_Mode__c, Workload__c from Work_Item__c where Response__c IN : rs.keySet()]);
		List<Workload__c> wls = new List<Workload__c>([select Area_Unit_Name__c from Workload__c where Collection_Instance__c =: thirdCI.Id]);
		// Check 3 response created.
		System.assertEquals(3, rs.size());    
		// Check 1 wl created
		System.assertEquals(1, wls.size());
		// Check 2 WI where created.
		System.assertEquals(2, wis.size());
		// Check both wi are assigned to the same WL
		Integer i = 0;
		for(Work_Item__c wi : wis){
			if(wi.Workload__c == wls[0].Id){ i++; }
		}
		System.assertEquals(2, i);
		//Check contact role is now Occupant
		System.assertEquals(1,[select count() from Contact_Role__c where Role__c = 'Occupant']);	
	
    } 
        
    @isTest static void testExistingWorkLoad(){
    	setup(2);	
        Workload__c workLoad = new Workload__c();
        workLoad.Collection_Instance__c = thirdCI.Id;
        workLoad.Area_Unit_Reference__c = '2';
        workLoad.Workload_Type__c = 'Interview';
        workLoad.Area_Unit_Name__c = 'existing';
        insert workLoad;
        PageReference page = new PageReference('RolloverResponses?id=' + thirdCI.Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController sc = new ApexPages.standardController(thirdCI);
		test.startTest();
        RolloverResponsesController controller = new RolloverResponsesController(sc);
        controller.selectedWave = '2';
        controller.onWaveChange();
        controller.startRollover();
        test.stopTest();
		map<Id,Response__c> rs = new map<Id,Response__c>([select Status__c,Response_Status_Reason__c  from Response__c where Collection_Instance__c =: thirdCI.Id]);
		List<Work_Item__c> wis = new List<Work_Item__c>([select Delivery_Mode__c, Workload__c from Work_Item__c where Response__c IN : rs.keySet()]);
		List<Workload__c> wls = new List<Workload__c>([select Area_Unit_Name__c from Workload__c where Collection_Instance__c =: thirdCI.Id]);
		System.assertEquals(2, rs.size());    
		System.assertEquals(2, wls.size());
		Integer existingWL = 0;
		for(Workload__c wload : wls){
			if(wload.Area_Unit_Name__c == 'existing'){ existingWL++; }
		}
		System.assertEquals(1, existingWL);
		System.assertEquals(1, wis.size());
		// Check the newly created WorkItem is related to the existing workitem.
		System.assertEquals(workLoad.Id, wis[0].Workload__c);
		
    }  
    
    @isTest static void testErrorNotManualFirstTime(){
    	setup(1);
		test.startTest();
        RolloverBatch rb = new RolloverBatch(secondCI.Id,thirdCI.Id,new Set<Id>(),2,false);
        rb.testError = true; 
        Database.executeBatch(rb, 2);  
        test.stopTest();   	
    	// Check partial error status
    	Collection_Instance__c ciError = [select Rollover_Status__c, Rollover_Error__c from Collection_Instance__c where id =: thirdCI.Id];
    	System.assertEquals('Partial Error', ciError.Rollover_Status__c);
    }  
    
    @isTest static void testErrorNotManualSecondTime(){
    	setup(1);
    	insert new SystemSettings__c(Name = 'rolloverBatch.notificationEmail', Value__c = 'stefania.ezquerra@fronde.com');
    	Collection_Instance__c ciError = [select Rollover_Status__c, Rollover_Error__c from Collection_Instance__c where id =: thirdCI.Id];
        ciError.Rollover_Status__c = 'Partial Error';
        update ciError;
		test.startTest();
        RolloverBatch rb = new RolloverBatch(secondCI.Id,thirdCI.Id,new Set<Id>(),2,false);
        rb.testError = true; 
        Database.executeBatch(rb, 2);  
        test.stopTest();   	
    	// Check an error on the Error log object was created.
    	System.assertEquals(1, [select count() from Error_Log__c]);
    }  
}