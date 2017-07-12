/* This class is intended to be used in a trigger to handle contact
 * - create new contacts
 * - duplicate handling
 * - raise case/workitem if contact has dup conflicts
 *
 * unit tests are under CollectionMarkInRequestHandlerTest.  This is part of mark-in
 * 
 * Amendment ECP-3278
 * Date      14 September 2016
 * Author    Caterina Cuccurullo
 * Description: Address Tick logic and creation of Work item removed to be done in Process Builder.
 * 
 * Amendment Bug ECP-3642
 * Date      27 September 2016
 * Author    Caterina Cuccurullo
 * Description Work item creation removed not required for Contact update
 * 
 * Amendment ECP-3237
 * Date      13 October 2016
 * Author    Caterina Cuccurullo
 * Create & Update contact role relationship with unit when recording respondent through Collection Markin Request.
*/ 

public class RespondentContactHandler {
	static SystemSettings__c processContactSettings = SystemSettings__c.getInstance('business.markin.process.contact');
	static boolean processContact = (processContactSettings!=null && String.isNotBlank(processContactSettings.value__c) && Boolean.valueOf(processContactSettings.value__c));

	// current de-dup logic for Business (excluding social)
	// 1. fn+ln+phone
	// 2. fn+ln+email
	// 3. fn+ln+mobile
	// 4. fn+ln+otherPhone

	// this method is cater for mark-in interface
	public static void processContactRequests(set<Id>listOfIds){

		set<Id>bizMarkInIds=new set<Id>();
		for(Id whatid: listOfIds){
			// for now, just handle mark-in-request, ignore everything else
			 system.debug('whatid=='+whatid.getSobjectType()+ 'Collection_Mark_In_Request__c=='+Schema.Collection_Mark_In_Request__c.SObjectType);
			if(whatid.getSobjectType() == Schema.Collection_Mark_In_Request__c.SObjectType){
				bizMarkInIds.add(whatid);
			}
		}
        system.debug('bizMarkInIds=='+bizMarkInIds);

		if(!bizMarkInIds.isEmpty()){
			processMarkInRequests(bizMarkInIds);
		}
	}
	
	
	@testVisible
	private static void processMarkInRequests(set<Id>markInIds){
		
		SystemSettings__c tempSettings = SystemSettings__c.getInstance('CnL.workitem.queue');
		String cnlQueue = tempSettings == null?'C_L_Escalation_Queue':tempSettings.value__c;
		
		tempSettings = SystemSettings__c.getInstance('CnL.workitem.addressticktype');
		String addressTickTask = tempSettings == null?'Update Respondent Details':tempSettings.value__c;
		
		tempSettings = SystemSettings__c.getInstance('CnL.workitem.dupcontacttype');
		String contactTask = tempSettings == null?'Update Respondent Details':tempSettings.value__c;
				
		Collection_Mark_In_Request__c[]requests=[Select id, Response_ExtID__c, Response_mode__c, Image_Url__c,
			Address_Tick__c, Building_Level_Unit__c, Street_Road_POBox__c, Suburb_Rural_Delivery__c,
			Town_City__c, Country__c, First_Name__c, Last_Name__c,Email__c, Mobile_Number__c,Phone_Number__c
			from Collection_Mark_In_Request__c where id in:markInIds];
		
		// error handling queue
		String[]queueNames=new String[]{cnlQueue};
		Map<String,Id>queueMap=new Map<String,Id>();
		for(Group q: [Select Id,DeveloperName from Group where DeveloperName in :queueNames and Type = 'Queue']){
			queueMap.put(q.DeveloperName,q.Id);
		}
		
		// with the mark-in request, we should already have the Response_ExtID__c, it means, we can go straight to find the responses
		Set<String>ResponseExt=new Set<String>();
		// this map is used to reverse update existing contact details, and creating new records
		Map<String,Contact>responseContactMap=new Map<String,Contact>();
		Work_Item__c[]markInWorkitems=new Work_Item__c[]{};
		for(Collection_Mark_In_Request__c m: requests){
    //Removed Address Tick logic will be done in process builder ECP-3278 //         
	//		if(m.Address_Tick__c){                       //     
	//			Work_Item__c w = createWorkItem(m.Response_ExtID__c, addressTickTask, queueMap.get(cnlQueue));//
	//			w.notes__c = 'Address Tick';//
	//			markInWorkitems.add(w);//
	//		}//
			
			if(String.isNotblank(m.Response_ExtID__c) && hasRespondentDetails(m)){
				if (processContact){
					// assume one respons-ext to one mark-in.  if we have duplicate mark-in request, assume they contain same contact details
					ResponseExt.add(m.Response_ExtID__c);
					responseContactMap.put(m.Response_ExtID__c, convert(m));
				} 
                //Work item creation removed not required for Contact update
                //else {
				//	Work_Item__c w = createWorkItem(m.Response_ExtID__c, contactTask, queueMap.get(cnlQueue));
				//	w.notes__c = 'Manual respondent processing';
				//	markInWorkitems.add(w);
				//}
			}
		}
		system.debug('ResponseExt=='+ResponseExt + ' responseContactMap=='+responseContactMap);
		if(markInWorkitems.isEmpty() && ResponseExt.isEmpty()){return;}
		
		if(ResponseExt.isEmpty()){
			insert markInWorkitems;
			return; // no contact to create, done here
		}
		
		Map<String,Response__c>responses=new Map<String,Response__c>();
		for(Response__c r: [select id, Response_ExtID__c, unit_of_interest__c, collection_instance__r.collection__c from Response__c 
                            where Response_ExtID__c in :ResponseExt]){
			responses.put(r.Response_ExtID__c, r);
		}
		
		// we now try to create new contacts.... if they failed, we need to somehow try to locate the duplicates...
		// for some reasons, Salesforce do not return any details on the duplicate contacts based on the dup rules
		Contact[]newContacts = responseContactMap.values();
		
		
		// this insert checks 2 things:
		// 1. it checks if the address is valid on the incoming request
		// 2. checks for duplicate records
		Database.SaveResult[]dbResults = Database.insert(newContacts, false);
		// now we have to update Responses with the actual respondent details
		Map<String,Response__c> responseWithRespondent = new Map<String,Response__c>();
		// since we cannot do the non-fuzzy search, and we will use basic filters to locate existing contact, if possible
		Set<String> lastNames = new Set<String>(), mobiles = new Set<String>(), phones = new Set<String>(), emails = new Set<String>();
		integer counter=0;
		boolean foundDup=false;
		Contact[]failedContacts=new Contact[]{};
        //ECP-3237  next line  
		Contact_Role__c[]newRoles = new Contact_Role__c[]{};
		for(Database.SaveResult result:dbResults){
			Contact c = newContacts[counter];
            if(result.isSuccess()){
                //contact was inserted as it wasn't a duplicate
				Response__c r = responses.get(c.Legacy_Contact_ID__c);
				r.Responded_By__c = result.getId();
				responseWithRespondent.put(r.Response_ExtId__c, r);
				
				// create new contact role  ECP-3237 - for a new contact AC2
				// first check if the collection & unit has an existing Contact role - 
                   updateExistingContactRoles(r.collection_instance__r.collection__c, r.unit_of_interest__c);
                // insert the new Contact Role
				    newRoles.add(new Contact_Role__c(contact__c = c.id, Unit_of_Interest_ID__c = r.unit_of_interest__c,
					collection__c = r.collection_instance__r.collection__c, Primary_Contact__c = true, Role__c = 'Respondent'));
				
			} else {

				//system.debug(LoggingLevel.Info, result.getErrors());
				Database.Error error = result.getErrors()[0];
				// if we failed on duplicate error, we try to dedup it
				// otherwise, any other contact errors will be deteced now
				if(error instanceof Database.DuplicateError){
					foundDup=true;
					// now, we have to go and find the existing contact
					lastNames.add(c.LastName);
                    if(String.isNotBlank(c.mobilePhone)){					
						mobiles.add(c.mobilePhone);
					}
					if(String.isNotBlank(c.phone)){
						phones.add(c.phone);
					}
					if(String.isNotBlank(c.otherPhone)){
						// very unlikely that we will have this, as we don't capture otherphone on the paper form
						phones.add(c.otherPhone);
					}
					if(String.isNotBlank(c.email)){
						emails.add(c.email);
					}
                    
					failedContacts.add(c);
				}            
                // Workitem creation was already done through process builder in ECP-3278 
                // So to avoid creating 2 work items when both address tick and contact information received simultaneously, below code was commented
                // This issue was fixed for the bug ECP-3875
                /*else {
					// contact failed on validation rule or other reasons
					Work_Item__c w = createWorkItem(c.Legacy_Contact_ID__c, contactTask, queueMap.get(cnlQueue));
					w.notes__c = 'Received incomplete contact details, manual processing is required.';
					markInWorkitems.add(w);
				}*/
			}
			counter++;
		}

		Map<Id,Contact> updatingContactFromMarkIn = new Map<Id,Contact>();
		// dup contact handling
		if (foundDup){
			Map<String,Contact> contactMaps = new Map<String,Contact>();
			Set<String>keyToDelete = new Set<String>();
			for(Contact existingContact: [select id, FirstName, LastName, Phone, Email, MobilePhone, OtherPhone from Contact where
				LastName in :lastNames and (MobilePhone in :mobiles or Phone in :phones or Email in :emails) ]){

					// best effort to find the contact
					// create a map with fn+ln+phone (etc) to try to find the

					// since we cannot do fuzzy search on first name, if we found duplicate ln+phone, or ln+email or ln+mobile
					// we will create a manual task if we found more than 1.
					// in this case, we will delete the reference if we find more than 1
					
					// lastname is complusory field to create new contact
					if(String.isNotBlank(existingContact.Phone)){
						String k = lowerCase(existingContact.lastName) + existingContact.Phone;
						if(contactMaps.containsKey(k)){keyToDelete.add(k);}
						else{contactMaps.put(k,existingContact);}
						
						// for the full search
						k = lowerCase(existingContact.firstName) + k;
						contactMaps.put(k,existingContact);
					}
					if(String.isNotBlank(existingContact.OtherPhone)){
						// even we don't capture the OtherPhone on paper form, we are using "existing otherPhone" for dup catching
						String k = lowerCase(existingContact.lastName) + existingContact.OtherPhone;
						if(contactMaps.containsKey(k)){keyToDelete.add(k);}
						else{contactMaps.put(k,existingContact);}
						
						// for the full search
						k = lowerCase(existingContact.firstName) + k;
						contactMaps.put(k,existingContact);
					}
					if(String.isNotBlank(existingContact.MobilePhone)){
						String k = lowerCase(existingContact.lastName) + existingContact.MobilePhone;
						if(contactMaps.containsKey(k)){keyToDelete.add(k);}
						else{contactMaps.put(k,existingContact);}

						// for the full search
						k = lowerCase(existingContact.firstName) + k;
						contactMaps.put(k,existingContact);
					}
					if(String.isNotBlank(existingContact.Email)){
						String k = lowerCase(existingContact.lastName) + lowerCase(existingContact.Email);
						if(contactMaps.containsKey(k)){keyToDelete.add(k);}
						else{contactMaps.put(k,existingContact);}

						// for the full search
						k = lowerCase(existingContact.firstName) + k;
						contactMaps.put(k,existingContact);
					}
			}
			
			// remove the duplicate partial keys
			for(String k:keyToDelete){contactMaps.remove(k);}
			
			// now we have a set of contact, hopfully, we find a match
			// if we have the same contact under different mark-in and the details are different, randomly overwrite
			for(Contact c: failedContacts){
				Response__c r = null;
				Contact oldRecord = null;
				// first in first serve, no point of trying too hard
				if(String.isNotBlank(c.phone)){
					String k1 = lowerCase(c.firstName)+lowerCase(c.lastname)+c.phone;
					String k2 = lowerCase(c.lastname)+c.phone;					
					// let's try full search
					if(contactMaps.containsKey(k1)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k1);
					} else if (contactMaps.containsKey(k2)) {
						// no match on fn+ln+phone, now, only come in here, if the key has no dup
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k2);
					}
				}
				if(String.isNotBlank(c.OtherPhone)){
					// notes... this block of logic is very unlikely to happen, as we don't capture otherPhone from the paper form
					String k1 = lowerCase(c.firstName)+lowerCase(c.lastname)+c.OtherPhone;
					String k2 = lowerCase(c.lastname)+c.OtherPhone;					
					// let's try full search
					if(contactMaps.containsKey(k1)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k1);
					} else if (contactMaps.containsKey(k2)) {
						// no match on fn+ln+phone, now, only come in here, if the key has no dup
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k2);
					}
				}
				if(r==null && String.isNotBlank(c.mobilePhone)){					
					String k1 = lowerCase(c.firstName)+lowerCase(c.lastname)+c.mobilePhone;
					String k2 = lowerCase(c.lastname)+c.mobilePhone;
					
					if(contactMaps.containsKey(k1)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k1);
					} else if(contactMaps.containsKey(k2)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k2);
					}
				}
				if(r==null && String.isNotBlank(c.email)){
					String k1 = lowerCase(c.firstname)+lowerCase(c.lastname)+lowerCase(c.email);
					String k2 = lowerCase(c.lastname)+lowerCase(c.email);
					if(contactMaps.containsKey(k1)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k1);
					} else if(contactMaps.containsKey(k2)){
						r = responses.get(c.Legacy_Contact_ID__c);
						oldRecord = contactMaps.get(k2);
					}
				}
				if(r!=null){
					r.Responded_By__c = oldRecord.id;
					responseWithRespondent.put(r.Response_ExtId__c, r);
					updateContactRecord(oldRecord, c);
					updatingContactFromMarkIn.put(oldRecord.id, oldRecord);
                    ///////////////////////////////////////////////////////////////////
                    //ECP-3237 first check if the collection/unit has an existing Contact role
                    updateExistingContactRoles(r.collection_instance__r.collection__c, r.unit_of_interest__c);
                    system.debug('oldcontact=='+oldRecord + ' response==' +r );
                    List<Contact_Role__c> ConRoleExist = new list<Contact_Role__c>([Select id, contact__c, collection__c, Unit_of_Interest_ID__c, Primary_Contact__c,Role__c,Status__c from Contact_Role__c
                          where contact__c =: oldRecord.id and Collection__c =: r.collection_instance__r.collection__c
                                and Unit_of_Interest_ID__c =: r.unit_of_interest__c LIMIT 1]); 
                    
                          if (ConRoleExist.size()>0){
                              if(ConRoleExist[0].Status__c  == 'Active' && ConRoleExist[0].Primary_Contact__c == false){
                              ConRoleExist[0].Primary_Contact__c = true;  
                              update ConRoleExist[0];
                              }
                              else if(ConRoleExist[0].Status__c  == 'Inactive'){
                              ConRoleExist[0].Status__c='Active'; 
                              ConRoleExist[0].Primary_Contact__c = true;   
                              update ConRoleExist[0];
                              }
                        }
                    
                         else{                                                            
                        //ECP-3237 create contact role for an existing contact AC1
                      // newRoles.add(new Contact_Role__c(contact__c = c.id, Unit_of_Interest_ID__c = r.unit_of_interest__c,
                       newRoles.add(new Contact_Role__c(contact__c = oldRecord.id, Unit_of_Interest_ID__c = r.unit_of_interest__c,                                 
					   collection__c = r.collection_instance__r.collection__c, Primary_Contact__c = true, Role__c = 'Respondent'));
                              }
                                   
				} else {
					// no contact found... in this case, very likely be a multi-dup
					Work_Item__c w = createWorkItem(c.Legacy_Contact_ID__c, contactTask, queueMap.get(cnlQueue));
					w.notes__c = 'Duplicate contacts found';
					markInWorkitems.add(w);
				}
			}
		}
        
        //ECP-3237
		if(!newRoles.isEmpty()){
			insert newRoles; // add contact role to newly created contacts
		}

		// update all the contact first.  In this case, if we have any validation rule, or dup errors, we can pick it up
		// and creates work-item for CnL
		// it is very unlikely that we will hit those error here
		// however, the de-dup logic is hidden from here, and if the contact somehow hit the rules, it will fail
		if(!updatingContactFromMarkIn.isEmpty()){
			Contact[] updatingContacts = updatingContactFromMarkIn.values(); // update existing contact with new details
			Database.SaveResult[]updResults = Database.update(updatingContacts, false);
			counter = 0;
			for(Database.SaveResult result:updResults){
				if(!result.isSuccess()){
					// Contact update error
					Contact c = updatingContacts[counter];
					Work_Item__c w = createWorkItem(c.Legacy_Contact_ID__c, contactTask, queueMap.get(cnlQueue));
					w.notes__c = 'System failed to update the contact details from scanning ' + result.getErrors();
					markInWorkitems.add(w);
				}
				counter++;
			}		
		}
		
		// even we have problem on updating the contact record, we can still associate the contact to the response
		if(!responseWithRespondent.isEmpty()){
			update responseWithRespondent.values(); // update responses with respondent details
		}
		if(!markInWorkitems.isEmpty()){
			insert markInWorkitems; // create workitems on the response
		}
	}
	
    private static void updateExistingContactRoles(String collectionCode, String unitofInterest)
    {
          //query existing contact roles are there any contact roles already for this collection/unit that have a Primary_Contact flag = true?
                    //we can only have 1 primary contact role on a unit.      
                     List<Contact_Role__c> queryContactRoles = new List<Contact_Role__c>();                                           
                     queryContactRoles = [Select Id, Collection__c, Unit_of_Interest_ID__c 
                                 from 	Contact_Role__c 
                                 where 	Collection__c =: collectionCode   
                                 and 	Unit_of_Interest_ID__c =: unitofInterest 
                                 and 	Primary_Contact__c = true];
                    
                    
                    if(!queryContactRoles.isEmpty()){ 
                         for (Contact_Role__c queryContactR : queryContactRoles) {
                              queryContactR.Primary_Contact__c = false;
                              }
                         update queryContactRoles;
                        
                    }
    }
    
	private static void updateContactRecord (Contact oldRecord, Contact newRecord){
		if(newRecord==null || oldRecord==null){return;}
		// depends on how we matches the contact, we updates other info
		if(String.isNotBlank(newRecord.mobilePhone)){oldRecord.mobilePhone = newRecord.mobilePhone;}
		if(String.isNotBlank(newRecord.phone)){oldRecord.phone = newRecord.phone;}
		if(String.isNotBlank(newRecord.otherPhone)){oldRecord.otherPhone = newRecord.otherPhone;}
		if(String.isNotBlank(newRecord.email)){oldRecord.email = newRecord.email;}
		// overwrite the whole address, if only 1 line exists
		if(String.isNotBlank(newRecord.Building_Level_Unit__c) || String.isNotBlank(newRecord.Street_Road_PO_Box__c) || String.isNotBlank(newRecord.Suburb_Rural_Delivery__c)){
			oldRecord.Building_Level_Unit__c = newRecord.Building_Level_Unit__c;
			oldRecord.Street_Road_PO_Box__c = newRecord.Street_Road_PO_Box__c;
			oldRecord.Suburb_Rural_Delivery__c = newRecord.Suburb_Rural_Delivery__c;
			oldRecord.Town_or_City__c = newRecord.Town_or_City__c;
			oldRecord.Country__c = newRecord.Country__c;
		}
	}
	
	private static Contact convert(Collection_Mark_In_Request__c request){
		// using the Response_ExtId as legacy_contact_id for error reference
		// note.  Only 1 phone number is captured over the paper form, and we are recording that into the Phone field, not OtherPhone
		return new Contact( Legacy_Contact_ID__c=request.Response_ExtID__c, firstName=request.First_name__c, lastName=request.last_name__c,
			mobilePhone = PhoneValidationRules.FormatePrefix(request.mobile_number__c),
			phone = PhoneValidationRules.FormatePrefix(request.phone_Number__c), email = request.email__c,
			Building_Level_Unit__c = request.Building_Level_Unit__c, Street_Road_PO_Box__c=request.Street_Road_POBox__c,
			Suburb_Rural_Delivery__c = request.Suburb_Rural_Delivery__c, Town_or_City__c = request.Town_City__c, Country__c = request.Country__c);
	}
	
	private static Work_Item__c createWorkItem(String responseExtId, String wiType, Id ownerId){
		Response__c r = new Response__c(Response_ExtID__c=responseExtId);
		Work_Item__c wi = new Work_Item__c(work_item_type__c=wiType, response__r=r);
		if(ownerId!=null){wi.ownerid = ownerid;}
		return wi;
	}
	
	private static String lowerCase(String a){
		return (String.isBlank(a))?'':a.toLowercase();
	}
	
	private static boolean hasRespondentDetails(Collection_Mark_In_Request__c req){
		// not going to check all the fields
		// if we have firstName and/or lastName, return true
		// if we have 1 of the 3 lines of address, return true
		// if we have email, return true
		// if we have a mobile or phone number, return true
		return ( String.isNotBlank(req.First_Name__c) || String.isNotBlank(req.Last_Name__c) ||
			String.isNotBlank(req.Building_Level_Unit__c) || String.isNotBlank(req.Street_Road_POBox__c) || String.isNotBlank(req.Street_Road_POBox__c) ||
			String.isNotBlank(req.mobile_number__c) || String.isNotBlank(req.email__c) || String.isNotBlank(req.phone_number__c)
		);
	}
	
}