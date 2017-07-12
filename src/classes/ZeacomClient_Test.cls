@isTest
public class ZeacomClient_Test {

    @testSetup
    static void setup() {
        insert new Webservice_Settings__c(
            Name = 'zeacom',
            Endpoint__c = 'www.ecample.com/',
            Method__c= 'POST',
            Content_type__c = 'application/json',
            Private_Key__c = 'abc',
            Public_Key__c = 'cba'
        );
    }

    @isTest
    static void SetWorktime() {
        // Arrange
        String agentLine = '';
        String reason = '';
        Integer duration = 0;
        Boolean onWorkTime = true;

        // Act
        Test.startTest();
        // String agentLine, String reason, Integer duration, Boolean onWorkTime
        ZeacomClient.SetWorktime(agentLine, reason, duration, onWorkTime);
        Test.stopTest();

        // Assert
        System.assertEquals(0, ZeacomClient.DefaultDuration);
    }

    @isTest
    static void CreateXSignature() {
        // Arrange
        String expected = 'AGiMQTD1/MHAKohTREZgCzOiKyDR9Rg5wlf+Zsg/8lI=';
        String privateKey = 'abc';
        String publicKey = 'cba';
        String body = '{ "agentLine": "1234", "reason": "Calling", "duration": 0, "onWorkTime": true }';
        MulesoftHashGenerator hashGenerator = new MulesoftHashGenerator(privateKey, publicKey);

        // Act
        String actual = hashGenerator.xSignature(body, '12345');

        // Assert
        System.assertEquals(expected, actual);
    }
}