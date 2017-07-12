/**
* Remark steven.zhu ECP-3573 remove a contact from response 20160920
*	
*/
@isTest
private class ManageContactControllerTest {
	
	@isTest static void testManageContactController_1() {
		Response__c response = new Response__c();
		ApexPages.StandardController std = new ApexPages.StandardController(response);

		ManageContactController controller = new ManageContactController(std);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Response Id was not provided')) {
		    	b = true;
		    }
		}
		system.assert(b);
	}

	@isTest static void testManageContactController_2() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);

		ApexPages.StandardController std = new ApexPages.StandardController(response);

		ManageContactController controller = new ManageContactController(std);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Creating new contact')){
		    	b = true;
		    }
		}
		system.assert(b);
	}

	@isTest static void testFindContact() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		controller.contactRole = contactRole;
		controller.contact = contact;
		controller.findContact();

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Updating contact: '+contact.FirstName+' '+contact.LastName)){
		    	b = true;
		    }
		}
		system.assert(b);
	}

	@isTest static void testDoSave_1() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		controller.contactRole = contactRole;
		controller.contact = contact;
		PageReference pr = controller.doSave();
		System.assert(pr.getURL().contains('/apex/SelectPrimaryContact'));
	}

	@isTest static void testDoSave_2() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.currentPage().getParameters().put('retURL','testurl');
        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		controller.contactRole = contactRole;
		controller.contactRole.Primary_Contact__c = true;
		controller.contactRole.Contact__c = null;
		controller.contact = contact;
		PageReference pr = controller.doSave();
		System.assert(pr.getURL().contains('/apex/SetPrimaryContact'));
	}

	@isTest static void testDoReset() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.currentPage().getParameters().put('retURL','testurl');
        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		controller.doReset();

		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Creating new contact')){
		    	b = true;
		    }
		}
		system.assert(b);
	}

	@isTest static void testDoCancel_1() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.currentPage().getParameters().put('retURL','testurl');
        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		PageReference pr = controller.doCancel();

		System.assert(pr.getURL().contains('testurl'));
	}

	@isTest static void testDoCancel_2() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		PageReference pr = controller.doCancel();

		System.assert(pr.getURL().contains('/'+response.Id));
	}

	@isTest static void testDoRemoveContact() {
		TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);

        ApexPages.StandardController std = new ApexPages.StandardController(response);
		ManageContactController controller = new ManageContactController(std);
		controller.contactRole = contactRole;
		controller.contact = contact;
		PageReference pr =controller.doRemoveContact();

		System.assertEquals(null,response.Contact__c);
		System.assertEquals('Inactive',contactRole.Status__c);
		System.assert(pr.getURL().contains('/'+response.Id));
	}
}