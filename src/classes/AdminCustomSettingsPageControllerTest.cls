@isTest
private class AdminCustomSettingsPageControllerTest {

	@testSetup
	static void setup(){
		insert new SystemSettings__c(name ='zeacom.blocking.duration', value__c='30');
	}

	@isTest
    static void testController() {
        AdminCustomSettingsPageController c = new AdminCustomSettingsPageController();
        c.edit();
        c.cancel();
        c.edit();
        c.editableCustomSettings[0].value__c='60';
        c.save();
        
        system.assertEquals('60', SystemSettings__c.getInstance('zeacom.blocking.duration').value__c);
    }
}