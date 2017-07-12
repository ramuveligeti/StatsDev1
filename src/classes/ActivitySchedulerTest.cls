@isTest
private class ActivitySchedulerTest{
    @testSetup static void setupData(){
        Response_API_Properties__c resApi = new Response_API_Properties__c();
        resApi.Name = 'response.status.closed';
        resApi.Value__c = 'Completed';
        Response_API_Properties__c resApi1 = new Response_API_Properties__c();
        resApi1.Name = 'activity.status.closed';
        resApi1.Value__c = 'Completed';
        Response_API_Properties__c resApi2 = new Response_API_Properties__c();
        resApi2.Name = 'error.folder.name';
        resApi2.Value__c = 'API Errors';
        Response_API_Properties__c resApi3 = new Response_API_Properties__c();
        resApi3.Name = 'workitem.status.closed';
        resApi3.Value__c = 'Completed';
        insert new List<Response_API_Properties__c>{resApi,resApi1,resApi2,resApi3};
		                
        Work_Item_Creation_Filters__c cw = new Work_Item_Creation_Filters__c();
        cw.Name = 'Wave';
        cw.Data_Type__c = 'String';
        cw.Field_API__c = 'Wave__c';
        Work_Item_Creation_Filters__c cw1 = new Work_Item_Creation_Filters__c();
        cw1.Name = 'Meshblock Code';
        cw1.Data_Type__c = 'String';
        cw1.Field_API__c = 'Meshblock_Code__c';
        Work_Item_Creation_Filters__c cw2 = new Work_Item_Creation_Filters__c();
        cw2.Name = 'Postcode';
        cw2.Data_Type__c = 'Picklist';
        cw2.Field_API__c = 'Unit_of_Interest__r.Address_Type__c';
        cw2.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw3 = new Work_Item_Creation_Filters__c();
        cw3.Name = 'Birth';
        cw3.Data_Type__c = 'Boolean';
        cw3.Field_API__c = 'Birth__c';
        Work_Item_Creation_Filters__c cw4 = new Work_Item_Creation_Filters__c();
        cw4.Name = 'Actual Start Date';
        cw4.Data_Type__c = 'Date';
        cw4.Field_API__c = 'Collection_Instance__r.Actual_Start_Date__c';
        cw4.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw5 = new Work_Item_Creation_Filters__c();
        cw5.Name = 'Account Managed';
        cw5.Data_Type__c = 'Lookup';
        cw5.Field_API__c = 'Unit_of_Interest__r.Account_Managed__c';
        cw5.Object__c = 'User';
        Work_Item_Creation_Filters__c cw6 = new Work_Item_Creation_Filters__c();
        cw6.Name = 'Created Date';
        cw6.Data_Type__c = 'Datetime';
        cw6.Field_API__c = 'createdDate';
        cw6.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw7 = new Work_Item_Creation_Filters__c();
        cw7.Name = 'Postcode1';
        cw7.Data_Type__c = 'String';
        cw7.Field_API__c = 'Unit_of_Interest__r.Postcode__c';
        cw7.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw8 = new Work_Item_Creation_Filters__c();
        cw8.Name = 'Mailable';
        cw8.Data_Type__c = 'String';
        cw8.Field_API__c = 'Unit_of_Interest__r.Mailable__c';
        cw8.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw9 = new Work_Item_Creation_Filters__c();
        cw9.Name = 'Key';
        cw9.Data_Type__c = 'Boolean';
        cw9.Field_API__c = 'Key__c';
        Work_Item_Creation_Filters__c cw10 = new Work_Item_Creation_Filters__c();
        cw10.Name = 'Behavioural Priority';
        cw10.Data_Type__c = 'Integer';
        cw10.Field_API__c = 'Behavioural_Priority__c';
        Work_Item_Creation_Filters__c cw11 = new Work_Item_Creation_Filters__c();
        cw11.Name = 'Extension Date';
        cw11.Data_Type__c = 'Date';
        cw11.Field_API__c = 'Extension_Date__c';
        Work_Item_Creation_Filters__c cw12 = new Work_Item_Creation_Filters__c();
        cw12.Name = 'Delivery Mode';
        cw12.Data_Type__c = 'Picklist';
        cw12.Field_API__c = 'Collection_Instance__r.Delivery_Mode__c';
		cw12.Object__c = 'Collection_Instance__c';
        insert new List<Work_Item_Creation_Filters__c> {cw,cw1,cw2,cw3,cw4,cw5,cw6,cw7,cw8,cw9,cw10,cw11,cw12};
            
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;

		TestDataHelper.createSystemSettings();
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'extract.filesize', value__c = '1000')
		};
   	}

	@isTest static void schedulerTest(){
        Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addMinutes(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        insert actSch;
        Activity_Schedule_Filter__c actSchFil = TestDataHelper.createActivityScheduleFilter(actSch.Id, false);
        actSchFil.Status__c = 'Scheduled';
        actSchFil.Scheduled_Date_time__c = system.now().addMinutes(60);
		actSchFil.QueryString__c = 'Select Id, Collection_Instance__c, Extension_Date__c,Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where Collection_Instance__c = \''+colIns.Id+'\'';
        insert actSchFil;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp.Wave__c = '12';
        resp.Birth__c = true;
		resp.GR_1_Label__c = 'GR_Label';
		resp.GR_1__c = 'GR1';
        resp.Extension_Date__c = system.today().addDays(2);
        insert resp;
		actSchFil = [Select Id,Scheduled_Date_time__c,QueryString__c,Activity_Schedule__c,Activity_Schedule__r.Collection_Instance_Name__c,Immediate_Extract__c from Activity_Schedule_Filter__c];
		Test.startTest();
		String CRON_EXP = '0 0 0 15 3 ? 2022';
		String jobId = System.schedule('ScheduleApexClassTest',CRON_EXP,new ActivityScheduler());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(CRON_EXP,ct.CronExpression);
		Test.stopTest();
	}
}