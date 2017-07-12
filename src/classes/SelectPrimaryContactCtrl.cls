public with sharing class SelectPrimaryContactCtrl {

	public final static String SELECT_PRIMARY_CONTACT_URL = '/apex/SelectPrimaryContact';

	public Id primaryContactRoleId {get; set;}
	@TestVisible public List<SelectOption> contactRolesSO {get; private set;}


	private final String retURL;
	public Unit__c unit {get; private set;}
	public Collection__c collection {get; private set;}
	@TestVisible public Boolean isValid {get; private set;}

	
	public SelectPrimaryContactCtrl() {
		String unitId = ApexPages.currentPage().getParameters().get('uid');
        if(String.isBlank(unitId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A unit id was not provided'));
        	isValid = false;
            return;
        }
        List<Unit__c> units = [select Name from Unit__c where Id=:unitId];
        if(units==null || units.isEmpty()){
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A unit was not found for id '+unitId));
        	isValid = false;
            return;
        }
        unit = units.get(0);

		String collectionId = ApexPages.currentPage().getParameters().get('cid');
        if(String.isBlank(collectionId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A collection id was not provided'));
        	isValid = false;
            return;
        }
        List<Collection__c> collections = [select Name from Collection__c where Id=:collectionId];
		if(collections==null || collections.isEmpty()){
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A collection was not found for id '+collectionId));
        	isValid = false;
            return;
        }
		collection = collections.get(0);

		retURL = ApexPages.currentPage().getParameters().get('retURL');
		List<Contact_Role__c> contactRoles = [select Contact__r.Name, Role__c from Contact_Role__c where Contact__c!='' and Unit_of_Interest_ID__c=:unitId and Collection__c=:collectionId and Status__c='Active'];
		if(contactRoles!=null && !contactRoles.isEmpty()){
			contactRolesSO = new List<SelectOption>();
			for(Contact_Role__c contactRole:contactRoles){
				System.debug(contactRole);
				String contactRoleStr = contactRole.Contact__r.Name +', '+contactRole.Role__c;
				SelectOption so = new SelectOption(contactRole.Id, contactRoleStr);
				contactRolesSO.add(so);
			}
		}
		isValid = true;
	}

	public PageReference checkForPrimaryContact(){
		if(isValid){
			Integer count = [select count() from Contact_Role__c where Status__c='Active' and Contact__c!='' and Unit_of_Interest_ID__c=:unit.Id and Collection__c=:collection.Id and Primary_Contact__c=true limit 1];
			if(count==0){
				if(contactRolesSO==null || contactRolesSO.isEmpty()){
					return redirectPage();
				}
				ApexPages.Message msg1 = new ApexPages.Message(ApexPages.Severity.WARNING, 'The collection unit does not have primary contact.');
				ApexPages.Message msg2 = new ApexPages.Message(ApexPages.Severity.WARNING, 'Would you like to assign new primary contact to the collection unit?');
				ApexPages.addMessage(msg1);
				ApexPages.addMessage(msg2);
				return null;
			}else{
				return redirectPage();
			}
		}else{
			return null;
		}
	}

	public PageReference cancel(){
		return redirectPage();
	}

	private PageReference redirectPage(){
		if(!String.isBlank(retURL)){
			return new PageReference(retURL);
		}else{
			return new PageReference('/');
		}
	}

	public PageReference savePrimaryContact(){
		if(!String.isBlank(primaryContactRoleId)){
			Contact_Role__c contactRole = [select Primary_Contact__c from Contact_Role__c where Id=:primaryContactRoleId];
			contactRole.Primary_Contact__c = true;
			update contactRole;
		}else{
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No new primary contact selected.');
			ApexPages.addMessage(msg);
			return ApexPages.currentPage();
		}

		if(!String.isBlank(retURL)){
			return new PageReference(retURL);
		}else{
			return new PageReference('/');
		}
	}
}