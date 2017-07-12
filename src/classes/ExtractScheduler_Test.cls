@isTest
private class ExtractScheduler_Test{
	static String WorkItemType = 'Reminder';
	static String DeliveryMode = 'Email';
	static String ExtractType = 'Post';
	static String ExtractFieldName = 'First Name';
	static String ExtractAPIName = 'Response__r.Contact__r.FirstName';
	static String CSVFormatName = 'Reminder Email FirstNames';
	static String DocumentFolder = Label.Work_Item_Extracts_Document_Folder;
	static String ContactFirstName = 'Joe Thiemo Cassius Jonatan Theodor Thoma';
	@testSetup static void setupData(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Extract_Fields__c firstName = new Extract_Fields__c(
            Name = ExtractFieldName,
            Header__c = ExtractFieldName,
            Extract_Type__c = ExtractType,
            API_Name__c = ExtractAPIName,
            Collection__c = collection.Name,
            Sequence__c = 1
        );

        insert firstName;
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;

        Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
        	Name = CSVFormatName,
            Column_Header_1__c = ExtractFieldName
        );

        insert csvFormat;

		TestDataHelper.createSystemSettings();
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'extract.filesize', value__c = '1000')
		};
	 }
	 @isTest static void executeTest(){
		Collection__c collection = [Select Id from Collection__c];
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert collectionInstance;
		
        Work_Item_CSV_Format__c csvFormat = [
            SELECT Id, Grouping__c, Contextual_Mappings__c
            FROM Work_Item_CSV_Format__c
            LIMIT 1
        ];

		Extract_Schedule__c es = new Extract_Schedule__c();
		es.Collection_Instance_Id__c = collectionInstance.Id;
		es.Work_Item_Type__c = 'Pre-Notification';
		es.Delivery_Mode__c = 'Post';
		es.Collection_Type__c = 'Business';
		es.Scheduled_Date_time__c = System.now().addMinutes(2);
		es.Output_CSV_Format__c = csvFormat.Id;
		insert es;

		Test.startTest();
		String CRON_EXP = '0 0 0 15 3 ? 2022';
		String jobId = System.schedule('ExtractSchedulerTest',CRON_EXP,new ExtractScheduler());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(CRON_EXP,ct.CronExpression);
		Test.stopTest();
	}

	@isTest static void extractSchedulerConTest(){
        Work_Item_CSV_Format__c csvFormat = [
            SELECT Id, Grouping__c, Contextual_Mappings__c
            FROM Work_Item_CSV_Format__c
            LIMIT 1
        ];

		ExtractSchedulerCon es = new ExtractSchedulerCon();
		es.actSch.Output_CSV_Format__c = csvFormat.Id;
		es.actSch.Scheduled_Date_time__c = System.now().addMinutes(2);
		es.actSch.Work_Item_Type__c = 'Pre-Notification';
		es.actSch.Delivery_Mode__c = 'Post';
		es.Save();
		es.cancel();
	}
}