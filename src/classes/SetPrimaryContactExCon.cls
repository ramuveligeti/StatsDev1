/**
* @description This is an extension controller for SetPrimaryContact VF page. 
* @author Ram Veligeti
* @date 27.May.2015
*/
public class SetPrimaryContactExCon {
    public static final String SET_PRIMARY_CONTACT_URL = '/apex/SetPrimaryContact';

    @TestVisible private Contact_Role__c contactRole;
    private List<Contact_Role__c> existingContactRoles;
    public Boolean renderButtons{get;set;}

    private final String unitId;
    private final String collectionId;
    private final String retURL;
    
    //Standard Controller
    public SetPrimaryContactExCon(){
        renderButtons = true;
        String contactRoleId = ApexPages.CurrentPage().getParameters().get('crid');
        if(String.isBlank(contactRoleId)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'A contact role id was not provided'));
            renderButtons = false;
            return;
        }

        List<Contact_Role__c> contactRoles = [Select Primary_Contact__c, Collection__c, Unit_of_Interest_ID__c from Contact_Role__c where Id = :contactRoleId];
        if(contactRoles==null || contactRoles.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed to find contact role with id '+contactRoleId));
            renderButtons = false;
            return;
        }

        unitId = ApexPages.CurrentPage().getParameters().get('uid');
        if(String.isBlank(unitId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A unit id was not provided'));
            renderButtons = false;
            return;
        }

        collectionId = ApexPages.CurrentPage().getParameters().get('cid');
        if(String.isBlank(collectionId)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'A collection id was not provided'));
            renderButtons = false;
            return;
        }

        retURL = ApexPages.CurrentPage().getParameters().get('retURL');

        contactRole = contactRoles.get(0);

        //Query all the existing primary ContactRoles for the Collection and UOI
        existingContactRoles = [Select  Id, Contact__r.FirstName, Contact__r.LastName 
                                    from    Contact_Role__c 
                                    where   Collection__c = :contactRole.Collection__c 
                                    and     Unit_of_Interest_ID__c = :contactRole.Unit_of_Interest_ID__c
                                    and     Primary_Contact__c = true 
                                    and     Status__c = 'Active'
                                    and     Id != :contactRole.Id];

    }
    
    //Action method called when page loads
    public pageReference redirect(){
        try{ 
            //If Contact Roles exist the give a warning message, else update primary contact to true
            if(!existingContactRoles.isEmpty()){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'A primary contact ('+existingContactRoles[0].Contact__r.FirstName+' '+existingContactRoles[0].Contact__r.LastName+') for this UOI and Collection already exists. Do you want to replace the existing primary contact with this contact?'));
                return null;
            } else {
                contactRole.Primary_Contact__c = true;
                update contactRole;
                return selectNewPrimaryContactPage();
            }
        }catch(exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
            return null;
        }
    }
    
    //Method called on the button Yes
    public pageReference setPrimaryContact(){
        try{
            List<Contact_Role__c> updateContactRoles = new List<Contact_Role__c>();
            
            //Updates the primary contact to true
            contactRole.Primary_Contact__c = true;
            updateContactRoles.add(contactRole);
            
            //Update the existing primary contact to false
            for(Contact_Role__c cr: existingContactRoles){
                cr.Primary_Contact__c = false;
                updateContactRoles.add(cr);
            }
            
            //Update
            if(!updateContactRoles.isEmpty()){
                update updateContactRoles;
            }
            return selectNewPrimaryContactPage();
        }catch(exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
            return null;
        }
    }
    //Method called on the button No
    public pageReference doNotSetPrimaryContact(){
        return selectNewPrimaryContactPage();
    }

    private PageReference selectNewPrimaryContactPage(){
        PageReference pr = new PageReference(SelectPrimaryContactCtrl.SELECT_PRIMARY_CONTACT_URL);
        pr.getParameters().put('uid', unitId);
        pr.getParameters().put('cid', collectionId);
        if(!String.isBlank(retURL)){
            pr.getParameters().put('retURL', retURL);
        }
        return pr;
    }
}