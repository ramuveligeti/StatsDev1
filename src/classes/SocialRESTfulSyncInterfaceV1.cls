@RestResource(urlMapping='/SocialRESTfulSyncInterfaces/1.0/*')
global class SocialRESTfulSyncInterfaceV1 {
	private static final String COLLECTION_CODE = 'HLFS';
	
	@HttpPost
    global static void upsertSocialDetails() {
        list<Contact> contactsToUpsert = new list<Contact>();
		list<Contact_Role__c> rolesToUpsert = new list<Contact_Role__c>();
		list<Response__c> responsesToUpsert = new list<Response__c>();
        list<Work_Item__c> workItemsToUpsert = new list<Work_Item__c>();
        List<ResponseContainer> responses = new List<ResponseContainer>();
        map<String,Boolean> seventyFiveFlagPerUnit = new map<String,Boolean>();
        map<String,Unit__c> notesPerUnit = new map<String,Unit__c>();
        
        try {
        	system.debug('## Body: ' + RestContext.request.requestBody.toString());
            JsonContainer jsonContainer = (JsonContainer)JSON.deserialize(RestContext.request.requestBody.toString(), SocialRESTfulSyncInterfaceV1.JsonContainer.class);
            responses = jsonContainer.householdResponses;
        } catch (Exception e) {
        	Error_Log__c eL = new Error_Log__c(Exception_Message__c = e + ' Failed to deserialize JSON body. Body: ' + RestContext.request.requestBody , Process_Name__c = 'SocialRESTfulSyncInterfaceV1.ResponseContainer');
			insert eL;  
            system.debug('Failed to deserialize JSON body. Body: ' + RestContext.request.requestBody + ' exception: ' + e);
        }
        
        for(ResponseContainer r : responses){
            
           	// Create Dwelling Responses
        	Response__c  hResponse = new Response__c(	recordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId(),
        												Status__c = r.status,
        												Response_Status_Reason__c = r.statusReason,
        												Collection_Instance__r = new Collection_Instance__c(Collection_Instance_Code__c = r.collectionInstanceCode),
        												Unit_of_Interest__r = new Unit__c( Unit_of_Interest_ID__c = r.hHFrameId),
        												X75_Indicator__c = Boolean.valueOf(r.seventyFivePlus),
        												CATI_Indicator__c = Boolean.valueOf(r.cATI),
        												Response_ExtId__c = r.collectionInstanceCode + r.externalId,
                                                        Interview_Time__c =  DateTime.parse(r.caseInterviewTime),
                                                        Edit_Time__c = DateTime.parse(r.caseEditTime),
                                                        CARI__c = Boolean.valueOf(r.cARI),
                                                        REC__c = Boolean.valueOf(r.rEC)
        											);

    		responsesToUpsert.add(hResponse);
    		seventyFiveFlagPerUnit.put(r.hHFrameId,hResponse.X75_Indicator__c);
            if(r.unitNotes != null && r.unitNotes.length() > 0){
            // Create unit notes info
            Unit__c unitInfo = new Unit__c(Notes__c = r.unitNotes,                                            
                                           Notes_Created_By__c = UserInfo.getUserId(),
                                           Notes_Modified_By__c = UserInfo.getUserId(),
            							   Notes_Created_Date__c = DateTime.parse(r.unitNotesCreatedDate),
           								   Notes_Modified_Date__c = DateTime.parse(r.unitNotesModifiedDate)
                                          );            
            notesPerUnit.put(r.hHFrameId, unitInfo);
            }
            for(WorkItemContainer w: r.workItems){
                // Create WorkItem
        		Work_Item__c newWorkItem = new Work_Item__c(Notes__c = w.notes, 
                                           Work_Item_ExtId__c = r.collectionInstanceCode + w.externalId,
                                           Notes_Created_By__c = UserInfo.getUserId(),
                                           Notes_Modified_By__c = UserInfo.getUserId(),
            							   Notes_Created_Date__c = DateTime.parse(w.notesCreatedByDate),
           								   Notes_Modified_Date__c = DateTime.parse(w.notesModifiedByDate),
                                           Response__r = new Response__c(Response_ExtId__c = hResponse.Response_ExtId__c)
										  );
        		workItemsToUpsert.add(newWorkItem);
            }
        	for(ContactContainer c: r.contacts){
        		// Create Contacts
        		Contact newContact = new Contact(	FirstName = c.fName,
													LastName = c.lName,
													Personal_email__c = c.email, // updated to reflect changes for indvidual vs business
													HomePhone = c.phone,  // updated to reflect changes for individual vs business
													MobilePhone = c.mobile,
													Gender__c = c.gender,
													Do_Not_Contact_Days__c = c.doNotContactOn,
													Best_Time_To_Contact__c = c.bestTimeToContact,
													Legacy_Contact_ID__c = COLLECTION_CODE + '-' + c.externalId
												);
        		contactsToUpsert.add(newContact);
        		// Is it Primary Contact?
        		if(c.isPrimary == 'true'){ 
        			hResponse.Responded_By__r =new Contact(Legacy_Contact_ID__c = newContact.Legacy_Contact_ID__c); 
        		}
				// Create Contact Role
				Contact_Role__c role = new Contact_Role__c(	Role__c = 'Respondent',  
															Contact__r = new Contact(Legacy_Contact_ID__c = newContact.Legacy_Contact_ID__c), 
															Primary_Contact__c = Boolean.valueOf(c.isPrimary),
															Collection__r = new Collection__c(Collection_Code__c = COLLECTION_CODE),
															Unit_of_Interest_ID__r = new Unit__c(Unit_of_Interest_ID__c = r.hHFrameId),
															Identifier__c = COLLECTION_CODE + '-' + c.externalId
														  ); 
				rolesToUpsert.add(role);
		    	// Create Individual Responses					
        		for(IndividualResponseContainer ir : c.individualResponses){
		        	Response__c iResponse = new Response__c	(	recordTypeId = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId(),
			        											Status__c = ir.status,
			        											Response_Status_Reason__c = ir.statusReason,
			        											Responded_By__r = new Contact(Legacy_Contact_ID__c = newContact.Legacy_Contact_ID__c),
			        											Collection_Instance__r = new Collection_Instance__c(Collection_Instance_Code__c = r.collectionInstanceCode),
			        											Unit_of_Interest__r = new Unit__c(Unit_of_Interest_ID__c = r.hHFrameId),
			        											Contact__r = new Contact(Legacy_Contact_ID__c = newContact.Legacy_Contact_ID__c),
			        											Response_ExtId__c = r.collectionInstanceCode + ir.externalId,
                                                                Interview_Time__c = DateTime.parse(r.caseInterviewTime),
                                                                Edit_Time__c = DateTime.parse(r.caseEditTime),
                                                                CARI__c = Boolean.valueOf(r.cARI),
                                                                REC__c = Boolean.valueOf(r.rEC)
		        											);   
                responsesToUpsert.add(iResponse);  
                      if(r.unitNotes != null && r.unitNotes.length() > 0){
                // Create unit notes info
               		Unit__c iUnitInfo = new Unit__c(Notes__c = r.unitNotes, 
                                               Notes_Created_By__c = UserInfo.getUserId(),
                                               Notes_Modified_By__c = UserInfo.getUserId(),
                                               Notes_Created_Date__c = DateTime.parse(r.unitNotesCreatedDate),
                                               Notes_Modified_Date__c = DateTime.parse(r.unitNotesModifiedDate)
                                              );            
            		notesPerUnit.put(r.hHFrameId, iUnitInfo);   
                 }
        		}
        	}
        }							

		if(!contactsToUpsert.isEmpty()){
			Schema.SObjectField extIdField = Contact.Fields.Legacy_Contact_ID__c;
			List<Database.UpsertResult> upsertResults = Database.upsert(contactsToUpsert, extIdField, false);
			System.debug('upsert contact upsertResults = '+upsertResults);
		}
		if(!responsesToUpsert.isEmpty()){
			Schema.SObjectField extIdField = Response__c.Fields.Response_ExtId__c;
			List<Database.UpsertResult> upsertResults = Database.upsert(responsesToUpsert, extIdField, false);
			System.debug('upsert responses upsertResults = '+upsertResults);
            
            //update unit notes
            updateUnitNotes(notesPerUnit);
            
            //Upsert WorkItems
            if(!workItemsToUpsert.isEmpty()){
			Schema.SObjectField wiExtIdField = Work_Item__c.Fields.Work_Item_ExtId__c;
			List<Database.UpsertResult> upsertWIResults = Database.upsert(workItemsToUpsert, wiExtIdField, false);
			System.debug('upsert workitems upsertResults = '+upsertWIResults);
            }
            
		}
		if(!rolesToUpsert.isEmpty()){
			Schema.SObjectField extIdField = Contact_Role__c.Fields.Identifier__c;
			List<Database.UpsertResult> upsertResults = Database.upsert(rolesToUpsert, extIdField, false);
			System.debug('upsert roles upsertResults = '+upsertResults);
		} 
		
		// 75+ Suppression Logic. Create new when flag is true and not existing, update to expire if SA exists, is active, and the flag is false.
		manage75PlusSuppresions(seventyFiveFlagPerUnit);
        
        
	}
    @testVisible   
    private static void updateUnitNotes(map<String,Unit__c> notesPerUnit){
       list<Unit__c> unitsToUpdate = new list<Unit__c>([select Id, Notes__c, Unit_of_Interest_ID__c from Unit__c where Unit_of_Interest_ID__c IN : notesPerUnit.keySet()]);
		for(Unit__c u: unitsToUpdate){			
            Unit__c unitInfo = notesPerUnit.get(u.Unit_of_Interest_ID__c);
            u.Notes__c = unitInfo.Notes__c;
            u.Notes_Created_By__c = unitInfo.Notes_Created_By__c; 
            u.Notes_Created_Date__c = unitInfo.Notes_Created_Date__c;
            u.Notes_Modified_Date__c = unitInfo.Notes_Modified_Date__c;
            u.Notes_Modified_By__c = unitInfo.Notes_Modified_By__c;
		}        
       if(!unitsToUpdate.isEmpty()){
        List<Database.SaveResult> updateResults = Database.update(unitsToUpdate, false); 
        System.debug('update units notes = '+updateResults);
       }
    }
    
	@testVisible
	private static void manage75PlusSuppresions(map<String,Boolean> seventyFiveFlagPerUnit){
		system.debug('## manage75PlusSuppresions: ' + seventyFiveFlagPerUnit);
		list<Special_Arrangement__c> saToUpsert = new list<Special_Arrangement__c>();
		map<Id,Boolean> flagByUnit = new map<Id,Boolean>();	
		list<Unit__c> units = new list<Unit__c>([select Unit_of_Interest_ID__c from Unit__c where Unit_of_Interest_ID__c IN : seventyFiveFlagPerUnit.keySet()]);
		for(Unit__c u:units){
			flagByUnit.put(u.Id, seventyFiveFlagPerUnit.get(u.Unit_of_Interest_ID__c));
		}
		list<Collection__c> collection = new list<Collection__c>([select Collection_Code__c from Collection__c where Collection_Code__c =: COLLECTION_CODE limit 1]);
		Id suppressionSARecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
		map<Id,Special_Arrangement__c> saMap = new map<Id,Special_Arrangement__c>([ select Suppression_Type__c, Survey_Unit__c,  Collection__c, Status__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, 
																						Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c   
				 																	 from Special_Arrangement__c 
				 																	 where Survey_Unit__c IN : flagByUnit.keySet() 
				 																	 and Collection__c =: collection[0].Id
				 																	 and RecordTypeId = : suppressionSARecordTypeId
				 																	 and Status__c = 'Active' // If a Special Arrangement expired, we create a new record if needed, to maintain a historic record of suppressions.
				 																	 and Suppression_Type__c = '75+' ]);
		map<Id,Special_Arrangement__c> saByUnit = new map<Id,Special_Arrangement__c>();
		for(Special_Arrangement__c sa: saMap.values()){
			saByUnit.put(sa.Survey_Unit__c,sa);
		}		
		for(Id unit : flagByUnit.keySet()){
			if(saByUnit.containsKey(unit)){
				if(!flagByUnit.get(unit)){
					// Expire SA.
					Special_Arrangement__c saToUpdate = saByUnit.get(unit);
					saToUpdate.Rule_End_Date__c = Date.today();
					saToUpsert.add(saToUpdate);
					continue;
				}
			}else if(flagByUnit.get(unit)){
				// Create New Special Arrangement. suppressed all year except June quarter.
				Special_Arrangement__c saToInsert = new Special_Arrangement__c(	RecordTypeId = suppressionSARecordTypeId, 
																				Collection__c = collection[0].Id,
                       															Suppression_Type__c = '75+', 
                       															Survey_Unit__c = unit,
                       															Month_1__c = true, Month_2__c = true, Month_3__c = true, Month_7__c = true, Month_8__c = true, Month_9__c = true, Month_10__c = true, Month_11__c = true, Month_12__c = true, 
                       															Month_4__c = false, Month_5__c = false, Month_6__c = false, 
                       															Rule_Start_Date__c = Date.today());
				saToUpsert.add(saToInsert);
			}
		}
		List<Database.UpsertResult> upsertResults = Database.upsert(saToUpsert,false);
		system.debug('upsert Special arrangement upsertResults = '+upsertResults); 
	}
	
    private class JsonContainer{
    	public List<ResponseContainer> householdResponses;
    }	
    
     private class WorkItemContainer{
        public String externalId;
        public String notes;
        public String notesCreatedBy;
        public String notesCreatedByDate;
        public String notesModifiedBy;
        public String notesModifiedByDate;
    }
    
    private class ResponseContainer{
        public String externalId;
        public String type;
        public String status;
        public String statusReason;
        public String collectionInstanceCode;
        public String hHFrameId;
        public String seventyFivePlus;
        public String cATI;
        public String caseInterviewTime;
        public String caseEditTime;
        public String cARI;
        public String rEC;
        public String unitNotes;
        public String unitNotesCreatedBy;
        public String unitNotesCreatedDate;
        public String unitNotesModifiedBy;
        public String unitNotesModifiedDate;
        public List<ContactContainer> contacts;
        public List<WorkItemContainer> workItems;
    }

    private class ContactContainer{
        public String fName;
        public String lName;
        public String email;
        public String phone;
        public String mobile;
        public String gender;
        //public String age; TBD: might not be on the contact level: on hold for ECP-3225
        public String doNotContactOn;
        public String bestTimeToContact;
        public String isPrimary;
        public String externalId;                
        public List<IndividualResponseContainer> individualResponses;     
    }
    
    private class IndividualResponseContainer{
        public String status;
        public String statusReason;
        public String type;
        public String externalId;
        public String caseInterviewTime;
        public String caseEditTime;
        public String cARI;
        public String rEC;
    }	
}