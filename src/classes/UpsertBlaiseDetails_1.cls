@RestResource(urlMapping='/upsertBlaiseDetails/1.0.0/*')
global class UpsertBlaiseDetails_1 {
/* DELETE
	private List<Contact> contacts;
	private List<Contact_Role__c> roles;
	private List<Response__c> responses;

	private static Integer collectionNumber;
	private static String unitFrameId;

	private static final String QUATER_CODE = 'Q';
	private static final String COLLECTION_CODE = 'HLFS';
	
	@HttpPost
    global static void upsertBlaiseDetails() {
        System.debug(LoggingLevel.INFO,'upsertBlaiseDetails started');
        System.debug(LoggingLevel.INFO,'heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());

        if(RestContext.request.requestBody != null){
        	Map<String, Object> resultsMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        	if(resultsMap.containsKey('householdResponses')){
        		List<Contact> contacts = new List<Contact>();
				List<Contact_Role__c> roles = new List<Contact_Role__c>();
				List<Response__c> responses = new List<Response__c>();

        		List<Object> householdResponses_obj = (List<Object>)resultsMap.get('householdResponses');
        		if(householdResponses_obj!=null && !householdResponses_obj.isEmpty()){
        			for(Object h:householdResponses_obj){
        				Map<String, Object> householdResponse_obj = (Map<String, Object>)h;
        				Response__c hResponse = toResponse(householdResponse_obj);
		        		responses.add(hResponse);
		        		if(householdResponse_obj!=null && householdResponse_obj.containsKey('contacts') && hResponse!=null){
		        			List<Object> contacts_obj = (List<Object>)householdResponse_obj.get('contacts');
		        			if(contacts_obj!=null && !contacts_obj.isEmpty()){
		        				for(Object o:contacts_obj){
		        					Map<String, Object> contact_obj = (Map<String, Object>)o;
		        					Contact contact = toContact(contact_obj);
		    						contacts.add(contact);
		    						System.debug('contact_obj = '+contact_obj);
		        					if(isPrimaryContact(contact_obj)){
		        						Contact c = new Contact();
		        						c.Legacy_Contact_ID__c = contact.Legacy_Contact_ID__c;
		        						hResponse.Contact__r = c;
		        					}

		    						Contact_Role__c role = createContactRole('Household Member',  
		    																contact.Legacy_Contact_ID__c, 
		    																isPrimaryContact(contact_obj));
		    						roles.add(role);

		    						if(contact_obj.containsKey('individualResponses')){
		    							List<Object> iResponses_obj = (List<Object>)contact_obj.get('individualResponses');
		    							if(iResponses_obj!=null && !iResponses_obj.isEmpty()){
					        				for(Object r:iResponses_obj){
					        					Map<String, Object> individualResponse_obj = (Map<String, Object>)r;
					        					individualResponse_obj.put('collectionNumber', collectionNumber);
					        					individualResponse_obj.put('unitFrameId', unitFrameId);
					        					individualResponse_obj.put('deliverContactId', contact.Legacy_Contact_ID__c);
					        					Response__c iResponse = toResponse(individualResponse_obj);
					        					responses.add(iResponse);
				    						}
				    					}
			    					}
		        				}
		        			}
		        		}
        			}
        		}

        		if(!contacts.isEmpty()){
        			Schema.SObjectField extIdField = Contact.Fields.Legacy_Contact_ID__c;
					List<Database.UpsertResult> upsertResults = Database.upsert(contacts, extIdField, false);
					System.debug('upsert contact upsertResults = '+upsertResults);
        		}
        		if(!responses.isEmpty()){
        			Schema.SObjectField extIdField = Response__c.Fields.Response_ExtId__c;
					List<Database.UpsertResult> upsertResults = Database.upsert(responses, extIdField, false);
					System.debug('upsert responses upsertResults = '+upsertResults);
        		}
        		if(!roles.isEmpty()){
        			Schema.SObjectField extIdField = Contact_Role__c.Fields.Identifier__c;
					List<Database.UpsertResult> upsertResults = Database.upsert(roles, extIdField, false);
					System.debug('upsert roles upsertResults = '+upsertResults);
        		}
        	}
		}
	}

	private static Contact_Role__c createContactRole(String role, String contactFrameId, Boolean isPrimary){
		Contact_Role__c contactRole = new Contact_Role__c();
		contactRole.Role__c = role;
		contactRole.Primary_Contact__c = isPrimary;

		Collection__c collection = new Collection__c();
		collection.Collection_Code__c = COLLECTION_CODE;
		contactRole.Collection__r = collection;

		Unit__c u = new Unit__c();
		u.Unit_of_Interest_ID__c = unitFrameId;
		contactRole.Unit_of_Interest_ID__r = u;

		Contact c = new Contact();
		c.Legacy_Contact_ID__c = contactFrameId;
		contactRole.Contact__r = c;

		String contactRoleIdentifier = COLLECTION_CODE+unitFrameId+contactFrameId;
		contactRole.Identifier__c = contactRoleIdentifier;

		return contactRole;
	}

	@TestVisible
	private static Response__c toResponse(Map<String, Object> response_obj){
		if(response_obj!=null){
			Response__c response = new Response__c();
			if(response_obj.containsKey('type')){
				response.Type__c = String.valueOf(response_obj.get('type'));
				if('Dwelling'.equals(response.Type__c)){
					response.recordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
				}else if('Individual'.equals(response.Type__c)){
					response.recordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
				}
			}
			if(response_obj.containsKey('status')){
				response.Status__c = String.valueOf(response_obj.get('status'));
			}
			if(response_obj.containsKey('statusReason')){
				response.Response_Status_Reason__c = String.valueOf(response_obj.get('statusReason'));
			}
			if(response_obj.containsKey('collectionNumber')){
				Collection_Instance__c ci = new Collection_Instance__c();
				collectionNumber = Integer.valueOf(response_obj.get('collectionNumber'));
				ci.Collection_Instance_Code__c = QUATER_CODE+collectionNumber+COLLECTION_CODE;
				response.Collection_Instance__r = ci;
			}
			if(response_obj.containsKey('unitFrameId')){
				Unit__c u = new Unit__c();
				unitFrameId = String.valueOf(response_obj.get('unitFrameId'));
				u.Unit_of_Interest_ID__c = unitFrameId;
				response.Unit_of_Interest__r = u;

			}
			if(response_obj.containsKey('deliverContactId')){
				Contact c = new Contact();
				c.Legacy_Contact_ID__c = String.valueOf(response_obj.get('deliverContactId'));
				response.Contact__r = c;
			}
			if(response_obj.containsKey('blaiseId')){
				response.Response_ExtId__c = String.valueOf(response_obj.get('blaiseId'));
			}
			return response;
		}
		return null;
	}

	@TestVisible
	private static Contact toContact(Map<String, Object> contact_obj){
		if(contact_obj!=null){
			Contact contact = new Contact();
			if(contact_obj.containsKey('fName')){
				contact.FirstName = String.valueOf(contact_obj.get('fName'));
			}
			if(contact_obj.containsKey('lName')){
				contact.LastName = String.valueOf(contact_obj.get('lName'));
			}
			if(contact_obj.containsKey('email')){
				contact.Email = String.valueOf(contact_obj.get('email'));
			}
			if(contact_obj.containsKey('phone')){
				contact.Phone = String.valueOf(contact_obj.get('phone'));
			}
			if(contact_obj.containsKey('gender')){
				contact.Gender__c = String.valueOf(contact_obj.get('gender'));
			}
			if(contact_obj.containsKey('age')){
				contact.Age__c = Integer.valueOf(contact_obj.get('age'));
			}
			if(contact_obj.containsKey('doNotContactOn')){
				contact.Do_Not_Contact_Days__c = String.valueOf(contact_obj.get('doNotContactOn'));
			}
			if(contact_obj.containsKey('bestTimeToContact')){
				contact.Best_Time_To_Contact__c = String.valueOf(contact_obj.get('bestTimeToContact'));
			}			
			if(contact_obj.containsKey('blaiseId')){
				contact.Legacy_Contact_ID__c = String.valueOf(contact_obj.get('blaiseId'));
			}
			return contact;
		}
		return null;
	}

	@TestVisible
	private static Boolean isPrimaryContact(Map<String, Object> contact_obj){
		if(contact_obj!=null){
			if(contact_obj.containsKey('isPrimary')){
				return Boolean.valueOf(contact_obj.get('isPrimary'));
			}
		}
		return false;
	}*/
}