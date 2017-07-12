@isTest
private class ResponseRateTriggerHandler_Test {
    @isTest static void testMethod1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Response_Rate__c responseRate = TestDataHelper.createResponseRate(col.Id,null,false);
            responseRate.Active__c = true;
            insert responseRate;
            test.startTest();
            Response_Rate__c responseRate1 = TestDataHelper.createResponseRate(col.Id,null,false);
            responseRate1.Active__c = true;
            insert responseRate1;
            test.stopTest();
            responseRate = [Select Id,Active__c from Response_Rate__c where Id = :responseRate.Id];
            responseRate1 = [Select Id,Active__c from Response_Rate__c where Id = :responseRate1.Id];
            system.assertEquals(FALSE, responseRate.Active__c);
            system.assertEquals(true, responseRate1.Active__c);
        }
    }
}