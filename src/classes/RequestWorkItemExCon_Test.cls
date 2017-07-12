@isTest 
public class RequestWorkItemExCon_Test {
    
    @testSetup
    static void setup() {
        insert new Webservice_Settings__c(
            Name = 'zeacom',
            Endpoint__c = 'www.ecample.com/',
            Method__c = 'Post',
            Content_Type__c = 'application/json',
            Private_Key__c = 'abc',
            Public_Key__c = 'abc'
        );
    }

    @isTest
    static void requestWorkItem_Throws_NoWorkItemFound() {
        // Arrange
        Work_Item__c workItem = new Work_Item__c();
        
        // Act
        try {
        	Test.startTest();
            workItem = RequestWorkItemExCon.requestWorkItem();
        	Test.stopTest();
            system.assert(false, 'should not reach here');
		}
        catch (Exception e) {
            // Assert
            System.assert(true, 'No matching skillsets found, so no work item to assign to a CSR.');
        }        
    }
}