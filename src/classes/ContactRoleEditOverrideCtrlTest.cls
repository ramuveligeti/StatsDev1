@isTest
private class ContactRoleEditOverrideCtrlTest {

	
	@testSetup 
	static void setupData(){
        TestDataHelper.createDataSet();

        Collection__c collection = [select Id from Collection__c limit 1];

        Id instrumentRecordTypeId = Schema.SObjectType.Artefact__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
		Artefact__c instrument = new Artefact__c();
		instrument.RecordTypeId = instrumentRecordTypeId;
		instrument.Collection__c = collection.Id;
		instrument.Artefact_Code__c = 'testCode42';
		instrument.Name = 'testName';
		instrument.Collection_Modes__c = 'CATI';
		instrument.Delivery_Modes__c = 'Post';
		instrument.Status__c = 'Active';
		insert instrument;

		SystemSettings__c catiSetting = new SystemSettings__c();
		catiSetting.Name = 'collection.mode.CATI';
		catiSetting.Value__c = 'Computer Assisted Telephone Interviewing';
		insert catiSetting;

		Contact_Role__c contactRole = [select Preferred_Collection_Mode__c, Preferred_Delivery_Mode__c from Contact_Role__c where Collection__c=:collection.Id limit 1];
		contactRole.Preferred_Collection_Mode__c = 'CATI';
		contactRole.Preferred_Delivery_Mode__c = 'Post';
		update contactRole;
    }
	
	@isTest static void testController_1() {
		Contact_Role__c contactRole = [select Id from Contact_Role__c];
		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleEditOverrideCtrl controller = new ContactRoleEditOverrideCtrl(sc);

		PageReference cancelPr = controller.cancel();
		PageReference savePr = controller.saveContactRole();

		System.assertEquals('/'+contactRole.Id, cancelPr.getUrl());
		System.assert(savePr.getUrl().startsWith('/apex/SelectPrimaryContact'));
	}
	
	@isTest static void testController_2() {
		Contact_Role__c contactRole = [select Id from Contact_Role__c];
		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleEditOverrideCtrl controller = new ContactRoleEditOverrideCtrl(sc);
		controller.contactRole.Primary_Contact__c = true;
		PageReference savePr = controller.saveContactRole();

		System.assert(savePr.getUrl().contains(SetPrimaryContactExCon.SET_PRIMARY_CONTACT_URL));
	}
	
	@isTest static void testController_3() {
		Contact_Role__c contactRole = [select Id from Contact_Role__c];
		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleEditOverrideCtrl controller = new ContactRoleEditOverrideCtrl(sc);
		controller.contactRole.Primary_Contact__c = true;
		controller.contactRole.Status__c = 'Inactive';
		PageReference savePr = controller.saveContactRole();

		System.assertEquals(ApexPages.currentPage().getUrl(), savePr.getUrl());
	}

	@isTest static void testController_4(){
		Collection__c collection = [select Id from Collection__c limit 1];
		Contact_Role__c contactRole = [select Id from Contact_Role__c where Collection__c=:collection.Id limit 1];

		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleEditOverrideCtrl controller = new ContactRoleEditOverrideCtrl(sc);

		System.assertEquals('CATI', controller.collectionMode);
		System.assertEquals('Computer Assisted Telephone Interviewing', controller.collectionModeDescription);
		System.assertEquals('Post', controller.deliveryMode);
	}

	@isTest static void testController_5(){
		Collection__c collection = [select Id from Collection__c limit 1];
		Contact_Role__c contactRole = [select Id from Contact_Role__c where Collection__c=:collection.Id limit 1];

		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleEditOverrideCtrl controller = new ContactRoleEditOverrideCtrl(sc);
		controller.collectionMode = 'random';
		controller.changeCollectionMode();

		System.assertEquals('random', controller.collectionMode);
		System.assertEquals(null, controller.collectionModeDescription);
	}
	
}