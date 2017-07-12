/**
* Remark steven.zhu ECP-3573 remove a contact from response 20160920
*	
*/
public with sharing class ManageContactController {
	public Boolean showSaveButton {get; private set;}
	public Boolean showCancelButton {get; private set;}
	public Boolean showFinishButton {get; private set;}
	public Boolean showRemoveContactButton {get; private set;}

	public Response__c response {get; private set;}
	public Contact contact {get; set;}
	public Contact_Role__c contactRole {get; set;}

	private String retURL;

	public ManageContactController(ApexPages.StandardController controller) {
		showSaveButton = false;
		showCancelButton = false;
		showFinishButton = false;

		Id responseId = controller.getId();
		retURL = ApexPages.currentPage().getParameters().get('retURL');

		if(String.isBlank(responseId)){
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Response Id was not provided');
			ApexPages.addMessage(msg);
			return;
		}

		List<Response__c> responses = [select 
											Contact__c,
											Unit_of_Interest__c,
											Unit_of_Interest__r.Unit_Name__c,
											Unit_of_Interest__r.Unit_of_Interest_ID__c,
											Collection_Instance__r.Collection__c,
											Collection_Instance__r.Collection__r.Name,
											Collection_Instance__r.Collection__r.Collection_Code__c
										from Response__c where Id = :responseId];

		if(responses.size()!=1){
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to find Response with Id '+responseId);
			ApexPages.addMessage(msg);
			return;
		}

		response = responses.get(0);

		resetContact();
		resetContactRole();

		if(String.isNotBlank(response.Contact__c)){
			contactRole.Contact__c = response.Contact__c;
			findContact();
			showRemoveContactButton = true;
		}
		
		showSaveButton = true;
		showCancelButton = true;

		if(String.isBlank(contactRole.Contact__c)){
			showCreatingContactMessage();
		}
	}

	private void showCreatingContactMessage(){
		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Creating new contact');
		ApexPages.addMessage(msg);
	}

	private void showUpdatingContactMessage(){
		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Updating contact: '+contact.FirstName+' '+contact.LastName);
		ApexPages.addMessage(msg);
	}

	 @TestVisible
	 public PageReference findContact(){
	 	System.debug('findContact statrted ');
		if(String.isNotBlank(contactRole.Contact__c)){			
			System.debug('looking for contact '+contactRole.Contact__c);
	        List<Contact> cnts = [select FirstName, 
	        							LastName, 
	        							Email, 
	        							Phone,
	        							MobilePhone,
	        							Company_Name__c,
	        							Main_Phone_Ext__c,
	        							HomePhone,
	        							Alt_Phone_Ext__c,
	        							Street_Road_PO_Box__c,
							        	Building_Level_Unit__c,
							        	Suburb_Rural_Delivery__c,
							        	Town_or_City__c,
							        	Country__c
        							From Contact Where Id = :contactRole.Contact__c];
	        if(cnts.size()==1){
	        	contact = cnts.get(0);
	        	findContactRole(contact.Id);
	        }
		}

		if(String.isBlank(contact.Id)){
			showCreatingContactMessage();
		}else{
			showUpdatingContactMessage();
		}
		return null;
    }

    private void findContactRole(Id contactId){
    	if(String.isNotBlank(contactId)){
    		List<Contact_Role__c> roles = [select Role__c, Primary_Contact__c, Contact__c, Care_of__c, Status__c
    						from Contact_Role__c 
    						where Status__c = 'Active' and
    								Contact__c=:contactId and 
    								Unit_of_Interest_ID__c=:response.Unit_of_Interest__c and
    								Collection__c=:response.Collection_Instance__r.Collection__c
			];

			contactRole = null;
    		if(roles.size()==1){
    			contactRole = roles.get(0);
    		}

    		if(contactRole == null){
    			resetContactRole();
    		}
    	}
    }

	public PageReference doRemoveContact(){
		try{
			//remove contacts from response
			response.Contact__c = null;
			update response;
			
			//set contact role status to be inactive
			if(contactRole != null && contactRole.Id != null)
			{
				contactRole.Status__c = 'Inactive';
				update contactRole;
			}
			
			PageReference pr = null;
			pr = new PageReference('/'+response.Id);
			return pr;
			
			
		}catch(Exception e){
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(msg);
			return null;
		}
	}

	public PageReference doSave(){
		try{
			upsert contact;

			if(String.isBlank(contactRole.Contact__c)){
				contactRole.Contact__c = contact.Id;
			}

			response.Contact__c = contact.Id;
			update response;

			PageReference pr = null;
			
			Boolean isPrimary = contactRole.Primary_Contact__c;
			contactRole.Primary_Contact__c = false;
			upsert contactRole;
			
			if(isPrimary){
				pr = new PageReference('/apex/SetPrimaryContact');
			}else{
				pr = new PageReference('/apex/SelectPrimaryContact');
			}
			pr.getParameters().put('crid', contactRole.Id);
			pr.getParameters().put('uid', response.Unit_of_Interest__c);
			pr.getParameters().put('cid', response.Collection_Instance__r.Collection__c);
			if(String.isNotBlank(retURL)){
				pr.getParameters().put('retURL', retURL);
			}else{
				pr.getParameters().put('retURL', '/'+response.Id);
			}


			return pr;
		}catch(Exception e){
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(msg);
			return null;
		}
	}

	public PageReference doReset(){
		resetContact();
		resetContactRole();
		showCreatingContactMessage();
		return null;
	}

	private void resetContact(){
		contact = new Contact();
	}

	private void resetContactRole(){
		contactRole = new Contact_Role__c();
		if(contact!=null && String.isNotBlank(contact.Id)){
			contactRole.Contact__c = contact.Id;
		}
		contactRole.Collection__c = response.Collection_Instance__r.Collection__c;
		contactRole.Unit_of_Interest_ID__c = response.Unit_of_Interest__c;
	}

	public PageReference doCancel(){
		PageReference pr = null;
		if(String.isNotBlank(retURL)){
			pr = new PageReference(retURL);
		}else{
			pr = new PageReference('/'+response.Id);
		}
		return pr;
	}
}