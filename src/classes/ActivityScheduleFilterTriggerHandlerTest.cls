/**
* @description 
* Remark		 Steven Zhu 20160912 completedtriggerTest_census failure because webservice setting and system setting not created in test method...
*/
@isTest
private class ActivityScheduleFilterTriggerHandlerTest {
    @isTest static void abortScheduledJobTest(){
        Collection__c co = TestDataHelper.createCollection(true);
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, true);
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;
        Date myDate = system.today();
        Time myTime = Time.newInstance(3, 3, 3, 0);
        DateTime dt = DateTime.newInstance(myDate, myTime);
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Weekly';
        asch.Occurrence__c = 2;
        asch.QueryString__c = queryString;
        insert asch;
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        insert asf;
        asch.Scheduled_Date_time__c = dt+3;
        update asch;
        
        List<Activity_Schedule_Filter__c> a = [Select Id, Schedule_Job_Id__c, Scheduled_Date_time__c from Activity_Schedule_Filter__c where Id <> :asf.Id];
        system.assertEquals(2, a.size());
        system.assertEquals(dt+3, a[0].Scheduled_Date_time__c);
        system.assertEquals(dt+10, a[1].Scheduled_Date_time__c);
        test.startTest();
        a[0].Status__c = 'Inactive';
        a[1].Status__c = 'Inactive';
		a[0].Schedule_Job_Id__c = '08e17000005E8SaAAK';
		a[1].Schedule_Job_Id__c = '08e17000005E8SaAAK';
        update a;
        test.stopTest();
		system.assertEquals('Inactive', a[0].Status__c);        
    }
    
    @isTest static void modifyScheduleDateTimeTest(){
        Collection__c co = TestDataHelper.createCollection(true);
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, true);
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;
        Date myDate = system.today();
        Time myTime = Time.newInstance(3, 3, 3, 0);
        DateTime dt = DateTime.newInstance(myDate, myTime);
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Weekly';
        asch.Occurrence__c = 2;
        asch.QueryString__c = queryString;
        insert asch;
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        asf.QueryString__c = queryString;
        insert asf;
        test.startTest();
        asf.Scheduled_Date_time__c = dt+3;
        update asf;
        test.stopTest();
        system.assertEquals(dt+3, asf.Scheduled_Date_time__c);
    }

    @isTest static void completedTriggerTest_Census(){
		ID coid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		ID ciid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();

        Collection__c co = TestDataHelper.createCollection(false);
        co.recordtypeid = coid;
        insert co;
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, false);
        ci.recordtypeid = ciid;
        insert ci;
 
        Extract_Fields__c firstName = new Extract_Fields__c(
            Name = 'FName',
            API_Name__c = 'Response__r.Contact__r.FirstName'
        );
        insert firstName;

	 	Webservice_Settings__c webserviceSetting = new Webservice_Settings__c();
		webserviceSetting.Endpoint__c = 'http://test.tst';
		webserviceSetting.Method__c = 'POST';
		webserviceSetting.Content_Type__c = 'application/json';
		webserviceSetting.Private_Key__c = 'a';
		webserviceSetting.Public_Key__c = 'b';
		webserviceSetting.Name = 'ActivityScheduleExtract';
		insert webserviceSetting;

		insert new SystemSettings__c[]{
			new SystemSettings__c(Name = 'shortUrlClient.notificationEmail',Value__c = 'test@test.test'),
		 	new SystemSettings__c(Name = 'extract.filesize', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.extract', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.activitySchedule', Value__c='10'),
		 	new SystemSettings__c(Name = 'environment.name', Value__c='test')
		};

        Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
        	Name = 'TestingTestin',
            Column_Header_1__c = 'FName'
        );
        insert csvFormat;
        
        Datetime dt = system.now().addSeconds(5);
        
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Once';
        asch.Occurrence__c = 1;
        asch.QueryString__c = queryString;
        asch.Output_CSV_Format__c = csvFormat.id;
        insert asch;
        
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        asf.QueryString__c = queryString;
        asf.Immediate_Extract__c = true;
        insert asf;
        
        test.startTest();
        SingleRequestMock mockServcie = new SingleRequestMock(200, 'Success', '', null);
		Test.setMock(HttpCalloutMock.class, mockServcie);
        asf.status__c = 'Completed';
        update asf;
        test.stopTest();
        
    }

    @isTest static void completedTriggerTest_Census_2(){
		ID coid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		ID ciid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();

        Collection__c co = TestDataHelper.createCollection(false);
        co.recordtypeid = coid;
        insert co;
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, false);
        ci.recordtypeid = ciid;
        insert ci;
 
        Extract_Fields__c firstName = new Extract_Fields__c(
            Name = 'FName',
            API_Name__c = 'Response__r.Contact__r.FirstName'
        );
        insert firstName;

	 	Webservice_Settings__c webserviceSetting = new Webservice_Settings__c();
		webserviceSetting.Endpoint__c = 'http://test.tst';
		webserviceSetting.Method__c = 'POST';
		webserviceSetting.Content_Type__c = 'application/json';
		webserviceSetting.Private_Key__c = 'a';
		webserviceSetting.Public_Key__c = 'b';
		webserviceSetting.Name = 'ActivityScheduleExtract';
		insert webserviceSetting;

		insert new SystemSettings__c[]{
			new SystemSettings__c(Name = 'shortUrlClient.notificationEmail',Value__c = 'test@test.test'),
		 	new SystemSettings__c(Name = 'extract.filesize', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.extract', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.activitySchedule', Value__c='10'),
		 	new SystemSettings__c(Name = 'environment.name', Value__c='test')
		};

        Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
        	Name = 'TestingTestin',
            Column_Header_1__c = 'FName'
        );
        insert csvFormat;
        
        Datetime dt = system.now().addSeconds(5);
        
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Daily';
        asch.Occurrence__c = 1;
        asch.QueryString__c = queryString;
        asch.Output_CSV_Format__c = csvFormat.id;
        insert asch;
        
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        asf.QueryString__c = queryString;
        asf.Immediate_Extract__c = true;
        insert asf;
        
        test.startTest();
        SingleRequestMock mockServcie = new SingleRequestMock(200, 'Success', '', null);
		Test.setMock(HttpCalloutMock.class, mockServcie);
        asf.status__c = 'Completed';
        update asf;
        test.stopTest();
        
    }

    @isTest static void completedTriggerTest_Census_3(){
		ID coid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		ID ciid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();

        Collection__c co = TestDataHelper.createCollection(false);
        co.recordtypeid = coid;
        insert co;
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, false);
        ci.recordtypeid = ciid;
        insert ci;
 
        Extract_Fields__c firstName = new Extract_Fields__c(
            Name = 'FName',
            API_Name__c = 'Response__r.Contact__r.FirstName'
        );
        insert firstName;

	 	Webservice_Settings__c webserviceSetting = new Webservice_Settings__c();
		webserviceSetting.Endpoint__c = 'http://test.tst';
		webserviceSetting.Method__c = 'POST';
		webserviceSetting.Content_Type__c = 'application/json';
		webserviceSetting.Private_Key__c = 'a';
		webserviceSetting.Public_Key__c = 'b';
		webserviceSetting.Name = 'ActivityScheduleExtract';
		insert webserviceSetting;

		insert new SystemSettings__c[]{
			new SystemSettings__c(Name = 'shortUrlClient.notificationEmail',Value__c = 'test@test.test'),
		 	new SystemSettings__c(Name = 'extract.filesize', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.extract', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.activitySchedule', Value__c='10'),
		 	new SystemSettings__c(Name = 'environment.name', Value__c='test')
		};

        Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
        	Name = 'TestingTestin',
            Column_Header_1__c = 'FName'
        );
        insert csvFormat;
        
        Datetime dt = system.now().addSeconds(5);
        
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Weekly';
        asch.Occurrence__c = 1;
        asch.QueryString__c = queryString;
        asch.Output_CSV_Format__c = csvFormat.id;
        insert asch;
        
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        asf.QueryString__c = queryString;
        asf.Immediate_Extract__c = true;
        insert asf;
        
        test.startTest();
        SingleRequestMock mockServcie = new SingleRequestMock(200, 'Success', '', null);
		Test.setMock(HttpCalloutMock.class, mockServcie);
        asf.status__c = 'Completed';
        update asf;
        test.stopTest();
        
    }

    @isTest static void completedTriggerTest_Census_4(){
		ID coid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		ID ciid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();

        Collection__c co = TestDataHelper.createCollection(false);
        co.recordtypeid = coid;
        insert co;
        Collection_Instance__c ci = TestDataHelper.createCollectionInstance(co.Id, false);
        ci.recordtypeid = ciid;
        insert ci;
 
        Extract_Fields__c firstName = new Extract_Fields__c(
            Name = 'FName',
            API_Name__c = 'Response__r.Contact__r.FirstName'
        );
        insert firstName;

	 	Webservice_Settings__c webserviceSetting = new Webservice_Settings__c();
		webserviceSetting.Endpoint__c = 'http://test.tst';
		webserviceSetting.Method__c = 'POST';
		webserviceSetting.Content_Type__c = 'application/json';
		webserviceSetting.Private_Key__c = 'a';
		webserviceSetting.Public_Key__c = 'b';
		webserviceSetting.Name = 'ActivityScheduleExtract';
		insert webserviceSetting;

		insert new SystemSettings__c[]{
			new SystemSettings__c(Name = 'shortUrlClient.notificationEmail',Value__c = 'test@test.test'),
		 	new SystemSettings__c(Name = 'extract.filesize', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.extract', Value__c='10'),
		 	new SystemSettings__c(Name = 'batchSize.activitySchedule', Value__c='10'),
		 	new SystemSettings__c(Name = 'environment.name', Value__c='test')
		};

        Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
        	Name = 'TestingTestin',
            Column_Header_1__c = 'FName'
        );
        insert csvFormat;
        
        Datetime dt = system.now().addSeconds(5);
        
        String queryString = 'Select Id, Collection_Instance__c, Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\'12\' AND Meshblock_Code__c=\'100\' AND Unit_of_Interest__r.Address_Type__c=\'Private Dwelling\' AND Birth__c=true) AND Collection_Instance__c = \''+ci.Id+'\'';
        Activity_Schedule__c asch = TestDataHelper.createActivitySchedule(ci.Id, false);
        asch.Scheduled_Date_time__c = dt+1;
        asch.Frequency__c = 'Monthly';
        asch.Occurrence__c = 1;
        asch.QueryString__c = queryString;
        asch.Output_CSV_Format__c = csvFormat.id;
        insert asch;
        
        Activity_Schedule_Filter__c asf = TestDataHelper.createActivityScheduleFilter(asch.Id, false);
        asf.Scheduled_Date_time__c = dt+2;
        asf.Schedule_Job_Id__c = '08e17000005E8SaAAK';
        asf.Status__c = 'Scheduled';
        asf.QueryString__c = queryString;
        asf.Immediate_Extract__c = true;
        insert asf;
        
        test.startTest();
        SingleRequestMock mockServcie = new SingleRequestMock(200, 'Success', '', null);
		Test.setMock(HttpCalloutMock.class, mockServcie);
        asf.status__c = 'Completed';
        update asf;
        test.stopTest();
        
    }

}