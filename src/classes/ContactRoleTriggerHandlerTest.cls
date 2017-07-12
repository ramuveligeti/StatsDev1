@isTest
private class ContactRoleTriggerHandlerTest {
    @isTest static void afterInsertTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            List<Contact> contList = new List<Contact>();
            for(integer i=0;i<200;i++){
                Contact cnt = TestDataHelper.createContact(false);
                cnt.FirstName = 'fname'+i;
                cnt.LastName = 'lname'+i;
                cnt.email = 'test'+i+'@test.test';
                cnt.Phone = 'phone'+i;
                cnt.Legacy_Contact_ID__c = String.valueOf(i);
                cnt.Address_ID__c = String.valueOf(i);
                cnt.Mobile_Device_Id__c = String.valueOf(i);
                contList.add(cnt);
            }
            insert contList;
            Collection__c coll = TestDataHelper.createCollection(true);
            Unit__c ui = TestDataHelper.createUnit(true);
            List<Contact_Role__c> crlst = new List<Contact_Role__c>();
            for(integer i=0;i<200;i++){
                Contact_Role__c cr = TestDataHelper.createContactRole(coll.Id,ui.Id,contList[i].Id,false);
                cr.Status__c = 'Active';
                cr.Primary_Contact__c = true;
                cr.Identifier__c = String.valueOf(i);
                cr.Mobile_Device_Id__c = String.valueOf(i);
                crlst.add(cr);
            }
            test.startTest();
            {
                insert crlst;
                
                for(Contact_Role__c cr:crlst){
                    cr.Status__c = 'Inactive';
                }
                update crlst;
            }
            test.stopTest();
            List<Contact_Role__c> crlstnew = [Select Id from Contact_Role__c where Primary_Contact__c = false];
            system.assertEquals(200,crlstnew.size());
           }
    }
}