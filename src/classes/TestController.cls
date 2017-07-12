public with sharing class TestController {
    public TestController() {
        
    }


    public PageReference testInserts(){
        Account a = new Account();
        a.Name = 'slavaTest';
        insert a;

        System.debug('account id = '+a.Id);

        Collection__c c = new Collection__c();
        c.Collection_Code__c='testcode12345';
        insert c;
        System.debug('collection id = '+c.Id);

        Collection_Instance__c ci = new Collection_Instance__c();
        ci.Collection_Instance_Code__c = 'ci-eyuwqtue';
        ci.Collection__c = c.Id;
        insert ci;
        System.debug('collection instance id = '+ci.Id);

        Collection_Instance__c ci1 = new Collection_Instance__c();
        ci1.Collection_Instance_Code__c = 'ci-eyuwqtue';
        ci1.Collection__c = c.Id;
        insert ci1;


        //this will fail validation
        //Contact con = new Contact();
        //insert con;

        return null;
    }
}