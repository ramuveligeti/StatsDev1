@isTest
private class ContactTriggerHandler_Test {
    @isTest static void assignAccount(){
        Contact ct = new Contact();
        ct.FirstName = 'xxx';
        ct.LastName = 'yyy';
        test.startTest();
        insert ct; // no account association
        test.stopTest();
        ct = [Select AccountId from contact where Id = :ct.Id];
        Account ac = [Select Id,name from account];
        system.assertEquals(ct.AccountId, ac.Id);
    }
}