@isTest
public class ShortUrlClient_Test {
    @testSetup
    static void setup() {
        TestDataHelper.createDataSet();
        
        insert new Webservice_Settings__c(
            Name = 'ShortUrlGenerator',
            Endpoint__c = 'www.example.com/',
            Method__c = 'GET',
            Content_Type__c = 'application/x-www-form-urlencoded',
            Private_Key__c = 'abc',
            Public_Key__c = 'cba'
        );
        
        insert new SystemSettings__c(
            Name = 'shortUrlClient.notificationEmail',
            Value__c = 'karthik.gunasekaran@stats.govt.nz'
        );
    }
    
    static Id collectionInstanceId() {
        Collection_Instance__c collectionInstance = [
            select Id
            from Collection_Instance__c
            limit 1
        ];
        return collectionInstance.Id;
    }

    @isTest
    static void RequestShortUrl() {
        try {
        	Test.startTest();
        	SingleRequestMock fakeResponse = new SingleRequestMock(200, 'Good', '', null);
			Test.setMock(HttpCalloutMock.class, fakeResponse);
            ShortUrlClient.RequestShortUrl(collectionInstanceId(), 0);
	        Test.stopTest();
        	System.assert(true);
        }
        catch (Exception e) {
        	System.assert(false);
        }
    }

    @isTest
    static void SendSuccsessEmail() {        
        Test.startTest();
        Boolean emailSent = ShortUrlClient.SendSuccsessEmail(collectionInstanceId());
        Test.stopTest();        
        System.assert(emailSent);
    }
    
    @isTest
    static void SendFailureEmail() {        
        Test.startTest();
        Boolean emailSent = ShortUrlClient.SendFailureEmail(collectionInstanceId(), 3);
        Test.stopTest();
        
        System.assert(emailSent);
    }
    
    @isTest
    static void ScheduleForRetry() {
        Test.startTest();
        String jobId = ShortUrlClient.ScheduleForRetry(collectionInstanceId(), Datetime.now().addHours(1), 0);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId);
    }
    
    @isTest
    static void SheduleStartString() {
        String expectedStartString = '0 5 1 1 1 ? 2016';
        Datetime scheduleTime = Datetime.newInstance(2016, 1, 1, 1, 0, 0);
        
        String startString = ShortUrlClient.SheduleStartString(scheduleTime);
        
        System.assertEquals(expectedStartString, startString);
    }
}