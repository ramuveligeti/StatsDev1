/* Remarks:
*  2017-01-11: SZhu ECP-3793: 'Collection Mode' on response is not updated when Primary Contact role's collection mode changes 
*
*/


public with sharing class ContactRoleEditOverrideCtrl {

	private Map<String, SystemSettings__c> settings;

	public Contact_Role__c contactRole {get; set;}
	private final Id unitId;
	private final Id collectionId;
	private final String retURL;

	public List<SelectOption> collectionModes {get; private set;}
	public String collectionMode {get; set;}
	public String collectionModeDescription {get; private set;}
	public List<SelectOption> deliveryModes {get; private set;}
	public String deliveryMode {get; set;}

	public ContactRoleEditOverrideCtrl(ApexPages.StandardController sc) {
		settings = SystemSettings__c.getAll();

		this.contactRole = [select 
								Contact__c,
								Primary_Contact__c,
								Role__c,
								Status__c,
								Collection__c,
								Preferred_Collection_Mode__c,
								Preferred_Delivery_Mode__c,
								//Mode_Description__c,
								Unit_of_Interest_ID__c,
								Notes__c,
								Identifier__c,
								Care_of__c
							from Contact_Role__c where Id=:sc.getId()];
		retURL = ApexPages.currentPage().getParameters().get('retURL');
		unitId = contactRole.Unit_of_Interest_ID__c;
		collectionId = contactRole.Collection__c;

		getModes();

		setCollectionMode(contactRole.Preferred_Collection_Mode__c);
		setDeliveryMode(contactRole.Preferred_Delivery_Mode__c);
	}

	public PageReference saveContactRole(){
		if(isValid()){
			PageReference pr = null;
			if(contactRole.Primary_Contact__c){
				pr = new PageReference(SetPrimaryContactExCon.SET_PRIMARY_CONTACT_URL);
				contactRole.Primary_Contact__c = false;
			}else{
				pr = new PageReference(SelectPrimaryContactCtrl.SELECT_PRIMARY_CONTACT_URL);
			}
			if(String.isNotBlank(collectionMode)){
				contactRole.Preferred_Collection_Mode__c = collectionMode;
				//if(String.isNotBlank(collectionModeDescription)){
				//	contactRole.Mode_Description__c = collectionModeDescription;
				//}
			}else
			{
				contactRole.Preferred_Collection_Mode__c = null;
			}
			if(String.isNotBlank(deliveryMode)){
				contactRole.Preferred_Delivery_Mode__c = deliveryMode;
			}else
			{
				contactRole.Preferred_Delivery_Mode__c = null;
			}
			update contactRole;

			
			pr.getParameters().put('crid', contactRole.Id);
			pr.getParameters().put('uid', unitId);
			pr.getParameters().put('cid', collectionId);
			if(!String.isBlank(retURL)){
				pr.getParameters().put('retURL', retURL);
			}
			return pr;
		}else{
			return ApexPages.currentPage();
		}

		
	}

	public PageReference changeCollectionMode(){
		setCollectionMode(collectionMode);
		return null;
	}

	private void setCollectionMode(String mode){
		collectionMode = mode;
		SystemSettings__c sysSetting = settings.get('collection.mode.'+mode);
		if(sysSetting!=null){
			collectionModeDescription = sysSetting.Value__c;
		}else{
			collectionModeDescription = null;
		}
	}

	private void setDeliveryMode(String mode){
		deliveryMode = mode;
	}

	private void getModes(){
		Id instrumentRecordTypeId = Schema.SObjectType.Artefact__c.getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
		List<Artefact__c> instruments = [select Delivery_Modes__c, Collection_Modes__c from Artefact__c 
											where Collection__c =:collectionId and RecordTypeId=:instrumentRecordTypeId and Status__c='Active'];

		if(instruments!=null && !instruments.isEmpty()){
			Set<String> collectionModesStringSet = new Set<String>();
			Set<String> deliveryModesStringSet = new Set<String>();
			for(Artefact__c instrument:instruments){
				if(String.isNotBlank(instrument.Collection_Modes__c)){
					List<String> collectionModesStringList = instrument.Collection_Modes__c.split(';');
					collectionModesStringSet.addAll(collectionModesStringList);
				}
				if(String.isNotBlank(instrument.Delivery_Modes__c)){
					List<String> deliveryModesStringList = instrument.Delivery_Modes__c.split(';');
					deliveryModesStringSet.addAll(deliveryModesStringList);
				}
			}
			collectionModes = toSelectOptions(collectionModesStringSet);
			deliveryModes = toSelectOptions(deliveryModesStringSet);
		}
	}

	private List<SelectOption> toSelectOptions(Set<String> selectElements){
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','-- None --'));
		if(selectElements!=null && !selectElements.isEmpty()){
			for(String selectElement:selectElements){
				SelectOption option = new SelectOption(selectElement,selectElement);
				options.add(option);
			}
		}
		return options;
	}

	private Boolean isValid(){
		Boolean result = true;
		if('Inactive'.equals(contactRole.Status__c) && contactRole.Primary_Contact__c){
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR,'Cannot set primary contact for inactive contact role'));
            result = false;
        }
        return result;
	}

	public PageReference cancel(){
		return new PageReference('/'+contactRole.Id);
	}
}