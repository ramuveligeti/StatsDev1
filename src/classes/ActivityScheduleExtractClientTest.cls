@isTest
public class ActivityScheduleExtractClientTest {

	@testSetup 
	public static void setup(){
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
        
        Extract_Schedule__c es = new Extract_Schedule__c();
		es.Activity_Schedule_Id__c = asch.Id;
		es.Scheduled_Date_time__c = asch.Scheduled_Date_time__c;
		es.CSV_Header__c = 'Fname';
		es.File_Name__c = 'test file';
		es.SOQL_String__c = 'select id from Response__c';
		es.Work_Item_Type__c = 'Questionnaire';
		es.Delivery_Mode__c = 'Post';
		es.Collection_Instance_Id__c = ci.id;
		es.Output_CSV_Format__c = csvFormat.Id;
		es.Collection_Type__c = 'Census';
		insert es;

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
		 	new SystemSettings__c(name = 'extract.filesize', Value__c='10'),
		 	new SystemSettings__c(name = 'batchSize.extract', Value__c='10'),
		 	new SystemSettings__c(name = 'batchSize.activitySchedule', Value__c='10'),
		 	new SystemSettings__c(name = 'environment.name', Value__c='test')
		};
	}
	
	@isTest 
	public static void testSuccess_ActivitySchedule() {
		Activity_Schedule_Filter__c filter = [select Id from Activity_Schedule_Filter__c limit 1];

        SingleRequestMock fakeResponse = new SingleRequestMock(200, 'Complete', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();       
		// even we have set the http-mock.  Under a schedule job, the mock didn't kick in.  however, it can help to test the exception path 
        ActivityScheduleExtractClient client = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Create, filter.id, 0);
        Datetime theFuture = Datetime.now().addMinutes(1);
		String cronStr = '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
		System.schedule('testJob', cronStr, client);
		Test.stopTest();
	}

	@isTest 
	public static void testSuccess_ExtractSchedule() {
		Extract_Schedule__c ext = [select Id from Extract_Schedule__c limit 1];

        SingleRequestMock fakeResponse = new SingleRequestMock(200, 'Complete', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();        
		// do the test inline to capture the proper path
        ActivityScheduleExtractClient.submitRequestAsync('Extract', ext.id, 0);
		Test.stopTest();
	}

	@isTest 
	public static void testFalure_1_nullID() {
        SingleRequestMock fakeResponse = new SingleRequestMock(400, 'Failed', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();
        ActivityScheduleExtractClient.submitRequest(ActivityScheduleExtractClient.Mode.Extract, null, 0);
		Test.stopTest();
	}

	@isTest 
	public static void testFalure_2_400() {
		Extract_Schedule__c ext = [select Id from Extract_Schedule__c limit 1];

        SingleRequestMock fakeResponse = new SingleRequestMock(400, 'Failed', '', null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Test.startTest();
        ActivityScheduleExtractClient.submitRequest(ActivityScheduleExtractClient.Mode.Extract, ext.id, 3);
		Test.stopTest();
	}
	
}