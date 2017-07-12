@isTest
private class ActivityScheduleTriggerHandlerTest {
    @isTest static void rescheduleTestMethod(){
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
		dt = System.now().addMinutes(60);
        test.startTest();
        asch.Scheduled_Date_time__c = dt;
        update asch;
        test.stopTest();
        List<Activity_Schedule_Filter__c> a = [Select Id, Scheduled_Date_time__c from Activity_Schedule_Filter__c where Id <> :asf.Id];
        system.assertEquals(2, a.size());
        system.assertEquals(dt, a[0].Scheduled_Date_time__c);
        system.assertEquals(dt+7, a[1].Scheduled_Date_time__c);
    }
}