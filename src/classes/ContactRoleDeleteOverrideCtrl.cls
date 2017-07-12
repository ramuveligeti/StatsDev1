public with sharing class ContactRoleDeleteOverrideCtrl {
	private Contact_Role__c contactRole;
	private final Id unitId;
	private final Id collectionId;
	private final String retURL;

	public ContactRoleDeleteOverrideCtrl(ApexPages.StandardController sc) {
		this.contactRole = [select 
								Collection__c,
								Unit_of_Interest_ID__c
							from Contact_Role__c where Id=:sc.getId()];
		retURL = ApexPages.currentPage().getParameters().get('retURL');
		unitId = contactRole.Unit_of_Interest_ID__c;
		collectionId = contactRole.Collection__c;
	}

	public PageReference deleteContactRole(){
		delete contactRole;

		PageReference pr = new PageReference(SelectPrimaryContactCtrl.SELECT_PRIMARY_CONTACT_URL);
		pr.getParameters().put('uid', unitId);
		pr.getParameters().put('cid', collectionId);
		if(!String.isBlank(retURL)){
			pr.getParameters().put('retURL', retURL);
		}
		return pr;
	}
}