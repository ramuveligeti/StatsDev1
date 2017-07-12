@isTest
private class SelectPrimaryContactCtrlTest {
	
	@testSetup 
	static void setupData(){
        TestDataHelper.createDataSet();
    }
	
	@isTest 
	static void testErrors_1() {
		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		
		List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A unit id was not provided')){
                b = true;
            }
        }
        system.assert(b);
	}

    @isTest static void testErrors_2(){
        Apexpages.currentPage().getParameters().put('uid', '123');
        SelectPrimaryContactCtrl controller = new SelectPrimaryContactCtrl();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A unit was not found for id 123')){
                b = true;
            }
        }
        system.assert(b);
    }
	
	@isTest 
	static void testErrors_3() {
		Unit__c u = [select Id from Unit__c limit 1];
        Apexpages.currentPage().getParameters().put('uid', u.Id);
		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		
		List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A collection id was not provided')){
                b = true;
            }
        }
        system.assert(b);
	}

    @isTest static void testErrors_4(){
		Unit__c u = [select Id from Unit__c limit 1];
        Apexpages.currentPage().getParameters().put('uid', u.Id);
        Apexpages.currentPage().getParameters().put('cid', '123');
        SelectPrimaryContactCtrl controller = new SelectPrimaryContactCtrl();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('A collection was not found for id 123')){
                b = true;
            }
        }
        system.assert(b);
    }
	
	@isTest 
	static void testCheckForPrimaryContact_1() {
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);
		ApexPages.currentPage().getParameters().put('retURL', 'testUrl');

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.checkForPrimaryContact();

		System.assertEquals(null, pr);
	}
	
	@isTest 
	static void testCheckForPrimaryContact_2() {
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];

		Contact_Role__c cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		cr.Primary_Contact__c = true;
		update cr;
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);
		ApexPages.currentPage().getParameters().put('retURL', 'testUrl');

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.checkForPrimaryContact();

		System.assertEquals('testUrl', pr.getUrl());
	}
	
	@isTest 
	static void testCheckForPrimaryContact_3() {
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];

		Contact_Role__c cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		cr.Primary_Contact__c = true;
		update cr;
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.checkForPrimaryContact();

		System.assertEquals('/', pr.getUrl());
	}
	
	@isTest 
	static void testCheckForPrimaryContact_4() {
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		Contact contact = [select Id from Contact limit 1];

		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		ctrl.contactRolesSO = null;
		PageReference pr = ctrl.checkForPrimaryContact();

		System.assertEquals('/', pr.getUrl());
	}
	
	@isTest 
	static void testCheckForPrimaryContact_5() {
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];

		Contact_Role__c cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		cr.Primary_Contact__c = true;
		update cr;
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		ctrl.isValid = false;
		PageReference pr = ctrl.checkForPrimaryContact();

		System.assertEquals(null, pr);
	}
	
	@isTest 
	static void testCancel_1() {		
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.cancel();

		System.assertEquals('/', pr.getUrl());
	}
	
	@isTest 
	static void testCancel_2() {		
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);
		ApexPages.currentPage().getParameters().put('retURL', 'testUrl');

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.cancel();

		System.assertEquals('testUrl', pr.getUrl());
	}
	
	@isTest 
	static void testSavePrimaryContact_1() {		
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);
		ApexPages.currentPage().getParameters().put('retURL', 'testUrl');

		Contact_Role__c cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		cr.Primary_Contact__c = false;
		update cr;

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		ctrl.primaryContactRoleId = cr.Id;
		PageReference pr = ctrl.savePrimaryContact();

		cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		System.assert(cr.Primary_Contact__c);
		System.assertEquals('testUrl', pr.getUrl());
	}
	
	@isTest 
	static void testSavePrimaryContact_2() {		
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		Contact_Role__c cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		cr.Primary_Contact__c = false;
		update cr;

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		ctrl.primaryContactRoleId = cr.Id;
		PageReference pr = ctrl.savePrimaryContact();

		cr = [select Primary_Contact__c from Contact_Role__c limit 1];
		System.assert(cr.Primary_Contact__c);
		System.assertEquals('/', pr.getUrl());
	}
	
	@isTest 
	static void testSavePrimaryContact_3() {		
		Unit__c unit = [select Id from Unit__c limit 1];
		Collection__c collection = [select Id from Collection__c limit 1];
		
		ApexPages.currentPage().getParameters().put('uid', unit.Id);
		ApexPages.currentPage().getParameters().put('cid', collection.Id);

		SelectPrimaryContactCtrl ctrl = new SelectPrimaryContactCtrl();
		PageReference pr = ctrl.savePrimaryContact();

		PageReference currentPage = ApexPages.currentPage();

		System.assertEquals(currentPage.getUrl(), pr.getUrl());
	}	
}