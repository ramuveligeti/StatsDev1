@isTest
private class RolloverBatchSchedulerTest {
	public static Collection__c collection;
	public static Collection_Instance__c firstCI;
	public static Collection_Instance__c secondCI;  
	public static Collection_Instance__c thirdCI;
	public static List<Response__c> responses; 
	public static List<Unit__c> units; 
    
    public static void setup(){
    	collection = TestDataHelper.createCollection(false);
        collection.Name = 'HLFS';
        collection.Type__c = 'HLFS';
        collection.Collection_Code__c = 'test';
    	collection.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert collection;
        Id ciSocialRT = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        firstCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        firstCI.Collection_Number__c = 1;
        firstCI.RecordTypeId = ciSocialRT;
        firstCI.Rollover_Status__c = null;
        firstCI.Status__c = '';
        firstCI.Name = 'firstCI';
        firstCI.Collection_Instance_Code__c = 'xxx1';
        firstCI.Wave_Period__c = 'Weekly';
        firstCI.Rollover_Status__c = null;
        firstCI.Planned_Start_Date__c = system.today().addDays(-5);
        firstCI.Interview_Start_Date__c = system.today().addDays(-5);
        firstCI.Planned_End_Date__c = system.today().addDays(100);
        insert firstCI;
        secondCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        secondCI.Name = 'secondCI';
        secondCI.Collection_Number__c = 2;
        secondCI.Collection_Instance_Code__c = 'xxx2';
        secondCI.Wave_Period__c = 'Weekly';
        secondCI.Actual_End_Date__c = null;
        secondCI.RecordTypeId = ciSocialRT;
        secondCI.Status__c = 'Active';
        secondCI.Rollover_Status__c = null;
        secondCI.Planned_Start_Date__c = system.today();
        secondCI.Interview_Start_Date__c = system.today();
        secondCI.Planned_End_Date__c = system.today().addDays(200);
        insert secondCI; 
        Collection_Instance__c ci = [select Current_Wave__c from Collection_Instance__c where id = : secondCI.Id];
        system.debug('## Second CI current wave: ' + ci.Current_Wave__c);    
        thirdCI = TestDataHelper.createCollectionInstance(collection.Id,false);
        thirdCI.RecordTypeId = ciSocialRT;
        thirdCI.Name = 'thirdCI';
        thirdCI.Collection_Number__c = 2;
        thirdCI.Wave_Period__c = 'Weekly';
        thirdCI.Actual_End_Date__c = null;
     	thirdCI.Collection_Instance_Code__c = 'xxx3';
        thirdCI.Rollover_Status__c = null;
        thirdCI.Status__c = 'Planned';
        thirdCI.Planned_Start_Date__c = system.today().addDays(80);
        thirdCI.Interview_Start_Date__c = system.today().addDays(80);
        thirdCI.Extension_Cut_off_Date__c = system.today().addDays(90);
        thirdCI.Planned_End_Date__c = system.today().addDays(300);
        insert thirdCI;         
        
        // Insert unique Units for each response. 
        units = new List<Unit__c>();
        Id houseHoldRecordType = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Household Unit').getRecordTypeId();
        for(integer i=0;i<15;i++){
            Unit__c unit = new Unit__c();//TestDataHelper.createUnit(false);
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

		// RESPONSES:
        responses = new List<Response__c>();
        for(integer i=0;i<15;i++){
            Response__c resp = new Response__c(); //TestDataHelper.createResponse(firstCI.Id, null, null, units[i].Id, false); not using testDataHelper as it make log too long to be able to debug. Even with the lowest debug level.
            resp.Collection_Instance__c = secondCI.Id;
            resp.Unit_of_Interest__c = units[i].Id;
            resp.Access_Code__c = null;
            resp.Response_ExtId__c = null;
            resp.Rotation__c = '1';
            resp.Wave__c = '10';
            resp.RecordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
            responses.add(resp);
        }
        responses[0].Collection_Instance__c = firstCI.Id;
        responses[1].Collection_Instance__c = firstCI.Id;
        insert responses; 
        
    }
    
    @isTest static void testRolloverSchedulerStartMethod(){
    	setup();	
		test.startTest();
		// Run batch today. Will rollover wave 10 of secondCI.
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1', Datetime.now().addMinutes(1));    
        test.stopTest();
		//Check the batch is queued.
		System.assertEquals(1,[select count() from AsyncApexJob where JobType='BatchApex']);
    }     

    @isTest static void testRolloverREScheduler(){
    	setup();	
		test.startTest();
		// Run batch 6 times. 
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1a', Datetime.now().addMinutes(1)); 
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1b', Datetime.now().addMinutes(2));
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1c', Datetime.now().addMinutes(3));
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1d', Datetime.now().addMinutes(4));
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1e', Datetime.now().addMinutes(5));
        RolloverBatchScheduler.startRolloverSchedule('Rollover Schedule Test1f', Datetime.now().addMinutes(6));   
        test.stopTest();
		//Check only 5 queued.
		System.assertEquals(5,[select count() from AsyncApexJob where JobType='BatchApex' and  (Status = 'Queued')]);
    }   

    @isTest static void testRolloverSchedulerWave7orPrior(){
    	setup();	
		test.startTest();
		// Run batch today. Will rollover wave 10 of secondCI.
		DateTime dt = Datetime.now().addMinutes(1);
		String schedule = dt.format('s m H d M \'?\' yyyy');
		String jobId = System.schedule('Rollover Schedule Test3',schedule,new RolloverBatchScheduler());  
		// Get the information from the CronTrigger API object
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		// Verify the next time the job will run
		System.assertEquals(dt,ct.NextFireTime);
        test.stopTest();
		//Check the batch is queued.
		System.assertEquals(1,[select count() from AsyncApexJob where JobType='BatchApex']);
    }  
    
    @isTest static void testRolloverSchedulerNoPriorAndWave8orAfter(){
    	Collection__c c = TestDataHelper.createCollection(false);
        c.Name = 'HLFS';
        c.Type__c = 'HLFS';
        c.Collection_Code__c = 'test2';
    	c.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert c;
        
        Collection_Instance__c fourthCI = TestDataHelper.createCollectionInstance(c.Id,false);
        fourthCI.RecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId(); 
        fourthCI.Name = 'fourthCI';
        fourthCI.Collection_Number__c = 1;
     	fourthCI.Collection_Instance_Code__c = 'xxx4';
     	fourthCI.Status__c = 'Active';
        fourthCI.Rollover_Status__c = null;
        fourthCI.Planned_Start_Date__c = system.today().addDays(-60);
        fourthCI.Interview_Start_Date__c = system.today().addDays(-60);
        fourthCI.Extension_Cut_off_Date__c = system.today();
        fourthCI.Planned_End_Date__c = system.today().addDays(30);
        insert fourthCI;  	
		test.startTest();
		// Run batch today.
		DateTime dt = Datetime.now().addMinutes(1);
		String schedule = dt.format('s m H d M \'?\' yyyy');
		String jobId = System.schedule('Rollover Schedule Test3',schedule,new RolloverBatchScheduler());  
        test.stopTest();
		//Check the batch is not queued.
		System.assertEquals(0,[select count() from AsyncApexJob where JobType='BatchApex']);
    } 

    @isTest static void testRolloverResponsesFromCurrentCI(){
    	Collection__c c = TestDataHelper.createCollection(false);
        c.Name = 'HLFS';
        c.Type__c = 'HLFS';
        c.Collection_Code__c = 'test2';
    	c.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert c;
        Collection_Instance__c fourthCI = TestDataHelper.createCollectionInstance(c.Id,false);
        fourthCI.RecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId(); 
        fourthCI.Name = 'fourthCI';
        fourthCI.Wave_Period__c = 'Weekly'; 
        fourthCI.Collection_Number__c = 1;
        fourthCI.Actual_End_Date__c = null;
     	fourthCI.Collection_Instance_Code__c = 'xxx4';
     	fourthCI.Status__c = 'Active';
        fourthCI.Rollover_Status__c = null;
        fourthCI.Planned_Start_Date__c = system.today().addDays(-70);
        fourthCI.Interview_Start_Date__c = system.today().addDays(-70);
        fourthCI.Extension_Cut_off_Date__c = system.today();
        fourthCI.Planned_End_Date__c = system.today().addDays(20);
        insert fourthCI; 
        
        Collection_Instance__c fifthCI = TestDataHelper.createCollectionInstance(c.Id,false);
        fifthCI.RecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();  
        fifthCI.Name = 'fifthCI';
     	fifthCI.Collection_Instance_Code__c = 'xxx5';
     	fifthCI.Status__c = 'Planned';
        fifthCI.Rollover_Status__c = null;
        fifthCI.Wave_Period__c = 'Weekly';
        fifthCI.Collection_Number__c = 2;
        fifthCI.Actual_End_Date__c = null;
        fifthCI.Planned_Start_Date__c = system.today().addDays(1);
        fifthCI.Interview_Start_Date__c = system.today().addDays(1);
        fifthCI.Extension_Cut_off_Date__c = system.today().addDays(1);
        fifthCI.Planned_End_Date__c = system.today().addDays(30);
        insert fifthCI;  	
		test.startTest();
		// Run batch today.
		DateTime dt = Datetime.now().addMinutes(1);
		String schedule = dt.format('s m H d M \'?\' yyyy');
		String jobId = System.schedule('Rollover Schedule Test3',schedule,new RolloverBatchScheduler());  
        test.stopTest();
		//Check the batch is queued.
		System.assertEquals(1,[select count() from AsyncApexJob where JobType='BatchApex']);
    } 
        
     @isTest static void testRolloverSchedulerNoCI(){
		test.startTest();
		// Run batch today.
		DateTime dt = Datetime.now().addMinutes(1);
		String schedule = dt.format('s m H d M \'?\' yyyy');
		String jobId = System.schedule('Rollover Schedule Test3',schedule,new RolloverBatchScheduler());  
        test.stopTest();
		//Check the batch is not queued.
		System.assertEquals(0,[select count() from AsyncApexJob where JobType='BatchApex']);
    } 
       	 
    
}