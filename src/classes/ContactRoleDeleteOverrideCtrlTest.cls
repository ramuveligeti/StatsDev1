@isTest
private class ContactRoleDeleteOverrideCtrlTest {
	
	@testSetup 
	static void setupData(){
        TestDataHelper.createDataSet();
    }
	
	@isTest static void testController() {
		Contact_Role__c contactRole = [select Id from Contact_Role__c];
		ApexPages.currentPage().getParameters().put('retURL', 'hello URL');
		ApexPages.StandardController sc = new ApexPages.StandardController(contactRole);
		ContactRoleDeleteOverrideCtrl controller = new ContactRoleDeleteOverrideCtrl(sc);

		PageReference pr = controller.deleteContactRole();

		System.assert(pr.getUrl().startsWith('/apex/SelectPrimaryContact'));
	}
	
}