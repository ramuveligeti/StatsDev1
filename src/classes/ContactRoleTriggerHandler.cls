/**
 * @description This class is called from ContactRoleTrigger
 * @author Ram Veligeti
 * @date 19.Apr.2015
 */
public class ContactRoleTriggerHandler {
    
    //After Insert Method
    //To check if there is primary contact already exist for the Collection and UOI
    public static void checkPrimaryContactExist(Map<Id,Contact_Role__c> contactRoles){
        List<Contact_Role__c> queryContactRoles = new List<Contact_Role__c>();
        Set<Id> collectionId = new Set<Id>();
        Set<Id> uoiId = new Set<Id>();
		
        //Filter records for Primary Contact is True and Status is Active
        for(Contact_Role__c cr: contactRoles.values()){
            if(cr.Primary_Contact__c && cr.Status__c == 'Active'){
                collectionId.add(cr.Collection__c);
                uoiId.add(cr.Unit_of_Interest_ID__c);
            }
        }
        
        //Query all the existing contact roles to check if Primary Contact exist
        if(!collectionId.isEmpty() && !uoiId.isEmpty()){
	        queryContactRoles = [Select Id, Collection__c, Unit_of_Interest_ID__c 
                                 from 	Contact_Role__c 
                                 where 	Id not in :contactRoles.keySet() 
                                 and 	Collection__c in :collectionId 
                                 and 	Unit_of_Interest_ID__c in :uoiId 
                                 and 	Status__c = 'Active' 
                                 and 	Primary_Contact__c = true];
        }
        
        //If the list is not null
        if(!queryContactRoles.isEmpty()){
            for(Contact_Role__c cr: contactRoles.values()){
                for(Contact_Role__c qr: queryContactRoles){
                    //If the Collection and UOI exist the display error
                    if(cr.Collection__c == qr.Collection__c && cr.Unit_of_Interest_ID__c == qr.Unit_of_Interest_ID__c){
		            	contactRoles.get(cr.Id).addError('Primary Contact already exist for the Collection and UOI');
                    }
                }
            }
        }
    }
    
    //Before Update Method
    //If Status is Inactive then Primary contact should be set to false
    //This can be handle through WorkFlows 
    public static void updatePrimaryContact(List<Contact_Role__c> contactRoles, Map<Id,Contact_Role__c> oldContactRolesMap ){
			
        for(Contact_Role__c cr: contactRoles){
            if(oldContactRolesMap.get(cr.Id).Status__c != cr.Status__c && cr.Status__c == 'Inactive'){
                cr.Primary_Contact__c = false;
            }
        }
    }
}