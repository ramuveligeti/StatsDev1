@isTest
private class SetPrimaryContactExConTest {

    @isTest static void testErrorContactRoleId(){
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A contact role id was not provided')){
                b = true;
            }
        }
        system.assert(b);
    }

    @isTest static void testErrorContactRoleSearch(){
        Apexpages.currentPage().getParameters().put('crid', '123');
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Failed to find contact role with id 123')){
                b = true;
            }
        }
        system.assert(b);
    }

    @isTest static void testErrorUnitId(){
        TestDataHelper.createDataSet();
        Contact_Role__c cr = [select Id from Contact_Role__c limit 1];

        Apexpages.currentPage().getParameters().put('crid', cr.Id);
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A unit id was not provided')){
                b = true;
            }
        }
        system.assert(b);
    }

    @isTest static void testErrorCollectionId(){
        TestDataHelper.createDataSet();
        Contact_Role__c cr = [select Id from Contact_Role__c limit 1];

        Apexpages.currentPage().getParameters().put('crid', cr.Id);
        Apexpages.currentPage().getParameters().put('uid', '123');
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A collection id was not provided')){
                b = true;
            }
        }
        system.assert(b);
    }

    @isTest static void newContactRole(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Unit__c unitOfInterest = TestDataHelper.createUnit(true);
        Contact contactRec = TestDataHelper.createContact(true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unitOfInterest.Id, contactRec.Id, true);
        PageReference pageRef = Page.SetPrimaryContact;
        Test.setCurrentPage(pageRef);
        test.startTest();
        {
        	ApexPages.currentPage().getParameters().put('crid', contactRole.id);
        	ApexPages.currentPage().getParameters().put('uid', unitOfInterest.id);
        	ApexPages.currentPage().getParameters().put('cid', collection.id);
            SetPrimaryContactExCon spexcon = new SetPrimaryContactExCon();
            spexcon.redirect();
            spexcon.setPrimaryContact();
        }
        test.stopTest();
        contactRole = [select Primary_Contact__c from Contact_Role__c where id = :contactRole.id];
        system.assertEquals(true, contactRole.Primary_Contact__c);
    }
    
    @isTest static void newInactiveContactRole(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Unit__c unitOfInterest = TestDataHelper.createUnit(true);
        Contact contactRec = TestDataHelper.createContact(true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unitOfInterest.Id, contactRec.Id, false);
        contactRole.Primary_Contact__c = false;
        contactRole.status__c = 'Inactive';
        insert contactRole;
        PageReference pageRef = Page.SetPrimaryContact;
        Test.setCurrentPage(pageRef);
        test.startTest();
        {
        	ApexPages.currentPage().getParameters().put('crid', contactRole.id);
        	ApexPages.currentPage().getParameters().put('uid', unitOfInterest.id);
            ApexPages.currentPage().getParameters().put('cid', collection.id);
            ApexPages.currentPage().getParameters().put('retURL', 'test');
            SetPrimaryContactExCon spexcon = new SetPrimaryContactExCon();
            spexcon.redirect();
        }
        test.stopTest();
        contactRole = [select Primary_Contact__c from Contact_Role__c where id = :contactRole.id];
        system.assertEquals(false, contactRole.Primary_Contact__c);
    }

    @isTest static void existingActiveContactRole(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Unit__c unitOfInterest = TestDataHelper.createUnit(true);
        Contact contactRec = TestDataHelper.createContact(true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unitOfInterest.Id, contactRec.Id, false);
        contactRole.Primary_Contact__c = true;
        contactRole.status__c = 'Active';
        insert contactRole;
        PageReference pageRef = Page.SetPrimaryContact;
        Test.setCurrentPage(pageRef);
        test.startTest();
        {
        	ApexPages.currentPage().getParameters().put('crid', contactRole.id);
        	ApexPages.currentPage().getParameters().put('uid', unitOfInterest.id);
        	ApexPages.currentPage().getParameters().put('cid', collection.id);
            SetPrimaryContactExCon spexcon = new SetPrimaryContactExCon();
            spexcon.redirect();
        }
        test.stopTest();
        contactRole = [select Primary_Contact__c from Contact_Role__c where id = :contactRole.id];
        system.assertEquals(true, contactRole.Primary_Contact__c);
    }

    @isTest static void existingContactRoles(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Unit__c unitOfInterest = TestDataHelper.createUnit(true);
        List<Contact> contactList = new List<Contact>();
        for(integer i=0;i<200;i++){
	        Contact testContactRec = TestDataHelper.createContact(false);
            testContactRec.Legacy_Contact_ID__c = String.valueOf('set'+i);
            testContactRec.Address_ID__c = String.valueOf(i);
            testContactRec.Mobile_Device_Id__c = String.valueOf(i);
            testContactRec.FirstName = 'fname'+i;
            testContactRec.LastName = 'lname'+i;
            testContactRec.email = 'test'+i+'@test.test';
            testContactRec.Phone = 'phone'+i;
            contactList.add(testContactRec);
        }
        insert contactList;
        
        List<Contact_Role__c> contactRoleList = new List<Contact_Role__c>();
        for(integer i=0;i<199;i++){
            Contact_Role__c testContactRole = TestDataHelper.createContactRole(collection.Id, unitOfInterest.Id, contactList[i].Id, false);
            testContactRole.Primary_Contact__c = false;
            testContactRole.Status__c = 'Active';
            testContactRole.Identifier__c = String.valueOf(i);
            testContactRole.Mobile_Device_Id__c = String.valueOf(i);
            contactRoleList.add(testContactRole);
        }
        contactRoleList[0].Primary_Contact__c = true;
        insert contactRoleList;
        
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unitOfInterest.Id, contactList[199].Id, false);
        contactRole.Primary_Contact__c = false;
        contactRole.Status__c = 'Active';
        insert contactRole;
        PageReference pageRef = Page.SetPrimaryContact;
        Test.setCurrentPage(pageRef);
        test.startTest();
        {
        	ApexPages.currentPage().getParameters().put('crid', contactRole.id);
        	ApexPages.currentPage().getParameters().put('uid', unitOfInterest.id);
        	ApexPages.currentPage().getParameters().put('cid', collection.id);
            SetPrimaryContactExCon spexcon = new SetPrimaryContactExCon();
            spexcon.redirect();
            spexcon.setPrimaryContact();
        }
        test.stopTest();
        contactRole = [select Primary_Contact__c from Contact_Role__c where id = :contactRole.id];
        system.assertEquals(true, contactRole.Primary_Contact__c);
    }

    @isTest static void testDoNotsetPrimaryContact(){
        TestDataHelper.createDataSet();
        Contact_Role__c cr = [select Id from Contact_Role__c limit 1];
        Unit__c u = [select Id from Unit__c limit 1];
        Collection__c c = [select Id from Collection__c limit 1];
        
        ApexPages.currentPage().getParameters().put('crid', cr.id);
        ApexPages.currentPage().getParameters().put('uid', u.id);
        ApexPages.currentPage().getParameters().put('cid', c.id);
        ApexPages.currentPage().getParameters().put('retURL', 'hello');
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();
            
        PageReference pr = controller.doNotSetPrimaryContact();
        System.assert(pr.getUrl().contains(SelectPrimaryContactCtrl.SELECT_PRIMARY_CONTACT_URL));
    }

    @isTest static void testSetPrimaryContactError(){
        TestDataHelper.createDataSet();
        Contact_Role__c cr = [select Id from Contact_Role__c limit 1];
        Unit__c u = [select Id from Unit__c limit 1];
        Collection__c c = [select Id from Collection__c limit 1];
        
        ApexPages.currentPage().getParameters().put('crid', cr.id);
        ApexPages.currentPage().getParameters().put('uid', u.id);
        ApexPages.currentPage().getParameters().put('cid', c.id);
        ApexPages.currentPage().getParameters().put('retURL', 'hello');
        SetPrimaryContactExCon controller = new SetPrimaryContactExCon();


        Contact cnt = TestDataHelper.createContact(false);
        cnt.FirstName = 'fname';
        cnt.LastName = 'lname';
        cnt.email = 'test@test.test';
        cnt.Phone = 'phone';
        cnt.Legacy_Contact_ID__c = '132';
        cnt.Address_ID__c = '132';
        cnt.Mobile_Device_Id__c = '132';
        insert cnt;

        Contact_Role__c cr2 = TestDataHelper.createContactRole(c.Id, u.Id, cnt.Id, false);
        cr2.Mobile_Device_Id__c = '101';
        cr2.Identifier__c = '102';
        insert cr2;
        
        //duplication of the Mobile_Device_Id__c will trigger exception
        controller.contactRole.Mobile_Device_Id__c = '101';
        PageReference pr = controller.setPrimaryContact();
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();

        System.assert(pr==null);
        System.assert(msgs!=null && !msgs.isEmpty());
    }


}