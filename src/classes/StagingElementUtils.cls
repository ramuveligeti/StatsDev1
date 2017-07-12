/*
* This class does not have explisit unit tests
* This should be covered by ProcessImportsFromStagingBatch unit tests and StagingElementTrigger unit tests
*
* Amendment -  Caterina Cuccurullo 22 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
* Amendment -  Bharathi Gunasekar 15 June 2017
* Bug		-  ECP - 3844, 3879
*              #3844 - The delivery address details on the response is updated from units 
*              #3879 - The contact and delivery address details on the response is updated from units primary contact
* Amendment -  Bharathi Gunasekar 06 July 2017
* Bug		-  ECP - 3921
*              #3921 - Contact is not being associated to response after sample load
*/
         
public class StagingElementUtils {
  private static System_Update__c systemUpdateSettings = System_Update__c.getInstance(UserInfo.getUserId());

  public static Boolean runCalculations = true;

  private static final String DEFAULT_UNIT_RECORD_TYPE_NAME = 'Household Unit';
  private final static Set<String> singletonWorkitems = new Set<String>{'Address canvassing','Access code','List leave'};

  private Map<String, Schema.SObjectField> stagingFieldMap ;
  private Set<String> stagingFields_Unit; 
  private Set<String> stagingFields_Response; 
  private Set<String> stagingFields_Grouping;
  private Set<String> stagingFields_Contextual; 
  private Set<String> stagingFields_Workload; 
  private Set<String> stagingFields_Workitem; 
  private Set<String> stagingFields_Contact; 
  private Set<String> stagingFields_ContactRole; 
  private Map<String, RecordTypeInfo> unitRecordTypes;
  private Map<String, RecordTypeInfo> responseRecordTypes;
    private Map<String, RecordTypeInfo> workItemRecordTypes;
  private Grouping__c grouping;
  private Contextual_Mappings__c contextual;

  
  public StagingElementUtils(Boolean runCalcs){
    if(runCalcs!=null){
      StagingElementUtils.runCalculations = runCalcs;
    }

    stagingFieldMap = Schema.SObjectType.Staging_Element__c.fields.getMap();
    
    Set<String> unitIgnoreFields = new Set<String>{
      'u_business_register_id__c',
      'u_kau_id__c',
      'u_record_type__c',
      'u_group_top_enterprise__c',
      'u_address_position__c',
      'u_address_status__c',
      'u_business_register_id__c',
      'u_forms_posted_df__c',
      'u_forms_posted_if__c',
      'u_forms_recd_df__c',
      'u_forms_recd_if__c',
      'u_enterprise__c'
    };

    Set<String> responseIgnoreFields = new Set<String>{
      'r_response_extid__c',
      'r_unit_delivery_mode__c',
      'r_status__c',
      'r_delivery_building_name__c',
      'r_delivery_level_number__c',
      'r_delivery_postcode__c',
      'r_delivery_road_name__c',
      'r_delivery_road_number__c',
      'r_delivery_road_number_alpha__c',
      'r_delivery_road_type__c',
      'r_delivery_rural_delivery_number__c',
      'r_delivery_suburb__c',
      'r_delivery_town_or_city__c',
      'r_delivery_unit_number__c'
    };

    Set<String> contactIgnoreFields = new Set<String>{
      'c_collection_instance_code__c',
      'c_firstname__c',
      'c_lastname__c',
      'c_phone__c',
      'c_fax__c',
      'c_other_phone__c',
      'c_email__c',
      'c_title__c',
      'c_salutation__c',
      'c_homephone__c'
    };

    Set<String> contactRoleIgnoreFields = new Set<String>{
      'cr_unit_of_interest_id__c',
      'cr_contact_extid__c'
    };

    stagingFields_Unit = new Set<String>();
    stagingFields_Response = new Set<String>();
    stagingFields_Grouping = new Set<String>();
    stagingFields_Contextual = new Set<String>();
    stagingFields_Workload = new Set<String>();
    stagingFields_Workitem = new Set<String>();
    stagingFields_Contact = new Set<String>();
    stagingFields_ContactRole = new Set<String>();
    for (String fieldName: stagingFieldMap.keySet()) {
      if(fieldName.startsWithIgnoreCase('u_') && !unitIgnoreFields.contains(fieldName.toLowerCase())){
        stagingFields_Unit.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('r_') && !responseIgnoreFields.contains(fieldName.toLowerCase())){
        stagingFields_Response.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('co_')){
        stagingFields_Contextual.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('gr_')){
        stagingFields_Grouping.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('wl_')){
        stagingFields_Workload.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('wi_')){
        stagingFields_Workitem.add(fieldName);
      }else if(fieldName.startsWithIgnoreCase('c_') && !contactIgnoreFields.contains(fieldName)){
        stagingFields_Contact.add(fieldName);  
      }else if(fieldName.startsWithIgnoreCase('cr_') && !contactRoleIgnoreFields.contains(fieldName)){
        stagingFields_ContactRole.add(fieldName);  
      }
    }

    unitRecordTypes = Schema.SObjectType.Unit__c.getRecordTypeInfosByName();
    responseRecordTypes = Schema.SObjectType.Response__c.getRecordTypeInfosByName();
        workItemRecordTypes = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName();
        
  }
  
  public void processStagingElements(Map<Id, Staging_Element__c> stagingElements, Collection_Instance__c collectionInstance){
    if(stagingElements!=null && !stagingElements.isEmpty()){
      //If error occurs during process of the staging element then put it in this map
      Map<Id, Staging_Element__c> failedStagingElements = new Map<Id, Staging_Element__c>();

      Map<String, Unit__c> units = new Map<String, Unit__c>();
      Map<String, Workload__c> workloads = new Map<String, Workload__c>();
      Map<String, Response__c> responses = new Map<String, Response__c>();
      Map<String, Account> accounts = new Map<String, Account>();
      Map<String, Contact> contacts = new Map<String, Contact>();
      Map<String, Contact_Role__c> contactRoles = new Map<String, Contact_Role__c>();
      List<Work_Item__c> workItems = new List<Work_Item__c>();
      List<Work_Item__c> workItems_toUpdate = new List<Work_Item__c>();
      
      Map<String, Unit__c> existingUnits = new Map<String, Unit__c>();
      
      for(Staging_Element__c stagingElement:stagingElements.values()){
        if(stagingElement.U_Unit_of_Interest_Id__c != null)
          existingUnits.put(stagingElement.U_Unit_of_Interest_Id__c, null);

        if(stagingElement.R_Unit_Association__c != null)
          existingUnits.put(stagingElement.R_Unit_Association__c.substringBefore('.'), null);
        
        if(!collectionInstance.Collection_Instance_Code__c.equals(stagingElement.CI_Collection_Instance_Code__c)){
          multipleCollectionInstanceCodeError(stagingElement);
          failedStagingElements.put(stagingElement.Id, stagingElement);
        }
      }

      if(Logger.isEnabled()){
        System.debug('existingUnits = '+existingUnits);
      }

      for(Unit__c unit:[
        select 
          Unit_of_Interest_ID__c,
          Building_Name__c,
          Level_Number__c,
          Unit_Number__c,
          Road_Name__c,
          Road_Number__c,
          Road_Number_Alpha__c,
          Road_Type__c,
          Rural_Delivery_Number__c,
          Suburb__c,
          Town_or_City__c,
          Postcode__c,
          Building_Level_Unit__c,
          Street_Road_PO_Box__c,
          Suburb_Rural_Delivery__c,
          Country__c,
          (select Preferred_Collection_Mode__c, Preferred_Delivery_Mode__c, Care_of__c,
            Contact__c, Contact__r.Company_name__c, Contact__r.Box_Bag_Number__c,
            Contact__r.Building_Level_Unit__c, Contact__r.Building_Name__c, 
            Contact__r.Country__c, Contact__r.Delivery_Service_Type__c,
            Contact__r.Level_Number__c, Contact__r.Mail_Town__c, 
            Contact__r.Postcode__c, Contact__r.Road_Direction__c, Contact__r.Road_Name__c,
            Contact__r.Road_Number__c, Contact__r.Road_Number_Alpha__c, 
            Contact__r.Road_Type__c, Contact__r.Rural_Delivery_Number__c, 
            Contact__r.Suburb__c, Contact__r.Street_Road_PO_Box__c, 
            Contact__r.Suburb_Rural_Delivery__c, Contact__r.Town_or_City__c, Contact__r.Has_Address__c
          from Contact_Roles__r where Primary_Contact__c = true and Collection__c = :collectionInstance.Collection__c limit 1) 
        from Unit__c where Unit_of_Interest_ID__c in :existingUnits.keySet()]){

        if(!String.isBlank(unit.Unit_of_Interest_ID__c)){
          existingUnits.put(unit.Unit_of_Interest_ID__c, unit);
        }
      }

      if(Logger.isEnabled()){
        System.debug('existingUnits = '+existingUnits);
      }

      //Loop through Scope elements
      for(Staging_Element__c stagingElement:stagingElements.values()){
        if(!failedStagingElements.containsKey(stagingElement.Id)){
          
          if(!systemUpdateSettings.File_Load_Workload_Disable__c){
            Workload__c workload = toWorkLoad(stagingElement);
            if(workload != null){
              workloads.put(workload.Workload_ID__c, workload);
            }
          }

          //Proces Unit records
          Unit__c unit = toUnit(stagingElement, collectionInstance);
          if(unit!=null){
            units.put(unit.Unit_of_Interest_ID__c, unit);
          }

          //Process Response records
          String collectionUnitId = null;
          if((stagingElement.R_Mark_in_Required__c || stagingElement.Survey_Unit__c)){
            collectionUnitId = stagingElement.R_Unit_Association__c.substringBefore('.');
          }
          if(stagingElement.Collection_Unit__c){
            collectionUnitId = stagingElement.U_Unit_of_Interest_Id__c;
          }

		  //Bug Fix- 3844 - starts
		  /*
		  Issue: The delivery address details on the response is blank
		  Scenario to reproduce: Upload the response with existing Unit_of_Interest_Id__c
		  Root Cause: In this scenario, the response delivery address details is updated from existing unit details. which does not match with the new address details from the stagging data. 
					  Hence the responses got created without the delivery address details
		  Fix: The response delivery address details is now passed from the unit address details updated by the stagging data. 
		  */

		  //Commented the old logic to get unit address details
          //Unit__c collectionUnit = existingUnits.get(collectionUnitId);
          //if(collectionUnit==null){
            //collectionUnit = units.get(collectionUnitId);
          //}

		  Unit__c collectionUnit = units.get(collectionUnitId);
          if(collectionUnit==null){
            collectionUnit = existingUnits.get(collectionUnitId);
          }        

		  //Fix for the bug - 3844 - ends
		  
         //Bug Fix- 3921 - Contact is not associated to response when a new response is created with existing unit.           
          
          Unit__c existingCollectionUnit = null;
           if(existingUnits != null){
               existingCollectionUnit = existingUnits.get(collectionUnitId);
           }
            
          Response__c responseObj = toResponse(stagingElement, collectionInstance, collectionUnit, existingCollectionUnit);
          if(responseObj!=null){
            responses.put(responseObj.Response_ExtId__c, responseObj);
          }

          Work_Item__c workItem = toWorkitem(stagingElement, collectionInstance);
          if(workItem!=null){
            if(String.isNotBlank(workItem.Id)){
              workItems_toUpdate.add(workItem);
            }else{
              workItems.add(workItem);
            }
          }

          /*Account acc = toAccount(stagingElement);
          if(acc != null){
            accounts.put(acc.Account_External_Id__c,acc);
          }*/

          Contact cont = toContact(stagingElement);
          if(cont != null){
            contacts.put(cont.Legacy_Contact_ID__c,cont);
          }
        }
      }

      if(!workloads.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will upsert '+workloads.size()+' workloads');
        }
        Database.UpsertResult[] workloadUpsertResults = Database.upsert(workloads.values(), Schema.Workload__c.Workload_ID__c, false);
        processUpsertResults(stagingElements, workloadUpsertResults, workloads.values(), 'Workload');
      }

      if(!units.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will upsert '+units.size()+' household units');
        }
        Database.UpsertResult[] unitUpsertResults = Database.upsert(units.values(), Schema.Unit__c.Unit_of_Interest_ID__c, false);
        if(Logger.isEnabled()){
          System.debug('unitUpsertResults5=='+unitUpsertResults);
        }
        processUpsertResults(stagingElements, unitUpsertResults, units.values(), 'Unit');
      }

      /*if(!accounts.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will upsert '+accounts.size()+' accounts');
        }
        Database.UpsertResult[] accUpsertResults = Database.upsert(accounts.values(), Schema.Account.Account_External_Id__c, false);
        if(Logger.isEnabled()){
          System.debug('accUpsertResults5=='+accUpsertResults);
        }
        processUpsertResults(stagingElements, accUpsertResults, accounts.values(), 'Account');
      }*/

      if(!contacts.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will upsert '+contacts.size()+' contacts');
        }
        Database.UpsertResult[] contUpsertResults = Database.upsert(contacts.values(), Schema.Contact.Legacy_Contact_ID__c, false);
        if(Logger.isEnabled()){
          System.debug('contUpsertResults=='+contUpsertResults);
        }
        processContactUpsertResults(stagingElements, contUpsertResults, contacts.values());
      }

	  Map<String, Contact_Role__c> contactRolesWithUnitId = new Map<String, Contact_Role__c>();

      //Contact Roles are processed after contact duplicates are handled
      for(Staging_Element__c stagingElement:stagingElements.values()){
        if(!failedStagingElements.containsKey(stagingElement.Id)){
          Contact_Role__c cr = toContactRole(stagingElement, collectionInstance);
          if(cr != null){
            contactRoles.put(cr.Identifier__c,cr);  
			contactRolesWithUnitId.put(cr.Unit_of_Interest_ID__r.Unit_of_Interest_ID__c,cr); 
          }
        }
      }

      if(!contactRoles.isEmpty()){
		if(Logger.isEnabled()){ System.debug('will upsert '+contactRoles.size()+' contact Roles');}

		Database.UpsertResult[] contRoleUpsertResults = Database.upsert(contactRoles.values(), Schema.Contact_Role__c.Identifier__c, false);

		if(Logger.isEnabled()){ System.debug('contRoleUpsertResults5=='+contRoleUpsertResults);}

		processUpsertResults(stagingElements, contRoleUpsertResults, contactRoles.values(), 'Contact Role');

		/* ECP- 3879 - change starts
		Issue: When contacts are uploaded seperately the response object is empty so none of the related responses are updated with contact and delivery details
		Fix: response object is filled with the responses related to the contact role unit ids
		*/

		 if(responses.isEmpty()){
			if(!contactRolesWithUnitId.isEmpty()){
				List<Response__c> responsesToBeUpdated =[select id,Response_ExtId__c,Survey_Unit__c,Collection_Instance__c ,Unit_of_Interest__c,Unit_of_Interest_ID__c, Collection_Instance__r.Collection_Instance_Code__c 
													 from Response__c  
													 where Unit_of_Interest_ID__c in :contactRolesWithUnitId.keySet()];

				for(Response__c responseItem:responsesToBeUpdated){

					Response__c currentResp = new Response__c();
					currentResp.Response_ExtId__c = responseItem.Response_ExtId__c;
					currentResp.id = responseItem.id;
			
					Unit__c u = new Unit__c();
					u.Unit_of_interest_Id__c = responseItem.Unit_of_Interest_ID__c;
					currentResp.Survey_Unit__r = u;

					Collection_Instance__c ci = new Collection_Instance__c();
					ci.Collection_Instance_Code__c = responseItem.Collection_Instance__r.Collection_Instance_Code__c ;
					currentResp.Collection_Instance__r = ci;
					responses.put(responseItem.Response_ExtId__c, currentResp);
				}
			}
		}

		/* ECP- 3879 - change ends */
    }

      if(!responses.isEmpty()){		
		/* ECP- 3879 - changes start */

		//Assigning the response contact details and delivery address from Contact
		assignResponseDeliveryAdrFromContact(responses.values());

		Database.UpsertResult[] responseAddressUpsertResults = Database.upsert(responses.values(), Schema.Response__c.Response_ExtId__c, false);
        
		System.debug('responseAddressUpsertResults=='+responseAddressUpsertResults);

		processUpsertResults(stagingElements, responseAddressUpsertResults, responses.values(), 'Response');

		/* ECP- 3879 - changes end */

        //Upsert response records with External Id (Response Ext Id)
        if(Logger.isEnabled()){
          System.debug('responseList 1: '+responses.values());
        }
        assignDataFromContactRoleUnit(responses.values());
        if(Logger.isEnabled()){
          System.debug('responseList 2: '+responses.values());
        }
        Database.UpsertResult[] responseUpsertResults = Database.upsert(responses.values(), Schema.Response__c.Response_ExtId__c, false);
        if(Logger.isEnabled()){
          System.debug('responseUpsertResults=='+responseUpsertResults);
        }
        processUpsertResults(stagingElements, responseUpsertResults, responses.values(), 'Response');
      }

      if(!workItems.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will upsert '+workItems.size()+' work items');
        }
        Database.UpsertResult[] workItemUpsertResults = Database.upsert(workItems, Schema.Work_Item__c.Work_Item_ExtId__c, false);
        processUpsertResults(stagingElements, workItemUpsertResults, workItems, 'WorkItem');
      }
      if(!workItems_toUpdate.isEmpty()){
        if(Logger.isEnabled()){
          System.debug('will update '+workItems_toUpdate.size()+' work items');
        }
        Database.SaveResult[] workItemSaveResults = Database.update(workItems_toUpdate, false);
        processSaveResults(stagingElements, workItemSaveResults, workItems_toUpdate, 'WorkItem');
      }

      //Put failed staging elemnts into failed map
      for(Staging_Element__c stagingElement:stagingElements.values()){
        if(stagingElement.Failed__c){
          failedStagingElements.put(stagingElement.Id, stagingElement);
        }
      }
      //remove failed staging elements from scope so they are not deleted
      for(Staging_Element__c failedStagingElement:failedStagingElements.values()){
        stagingElements.remove(failedStagingElement.Id);
      }

      if(!stagingElements.isEmpty()){
        if(Trigger.isExecuting){
          delete [select id from Staging_Element__c where Id in :stagingElements.keySet() or Id in :failedStagingElements.keySet()];
        }else{
          delete stagingElements.values();
        }
      }

      if(!failedStagingElements.isEmpty()){
        if(!Trigger.isExecuting){
          update failedStagingElements.values();
        }
      }
    }
  }
  
  private Unit__c toUnit(Staging_Element__c stagingElement, Collection_Instance__c collectionInstance) {
    if(stagingElement!=null && String.isNotBlank(stagingElement.U_Unit_of_Interest_Id__c)){
      Boolean addressChanged = false;
      Set<String> addressFields = getApiFieldNamesFromFieldSet('Address_Information','Unit__c');

      Unit__c unit = new Unit__c();
      unit.Staging_Element_Id__c = stagingElement.Id;
      //Assign field values based on API Name of the Staging element object
      //All the fields in the Staginig Element are given with a prefix and the same API Name as the base object(like Response, Unit)
      //Eg: Unit of Interest Id field in Staging Element is U_Unit_of_Interest_Id__c and the field on Unit object is Unit_of_Interest_Id__c
      for (String fieldName:stagingFields_Unit) {
        if(stagingElement.get(fieldName)!=null){
          //To assign value to Unit object remove the prefix and get the field value
          unit.put(fieldName.removeStartIgnoreCase('u_'),stagingElement.get(fieldName));
          if(addressFields.contains(fieldName.removeStartIgnoreCase('u_'))){
            addressChanged = true;
          }
        }
      }

      //if true, then process all the fields of the fieldset even if the values are null
      if(addressChanged){
        for(String addressField: addressFields){
          unit.put(addressField, stagingElement.get('U_'+addressField));
        }
      }

      if('Census'.equals(collectionInstance.Collection__r.RecordType.Name)){
        unit.RecordTypeId = unitRecordTypes.get('Household Unit').getRecordTypeId();
      }else if('Social'.equals(collectionInstance.Collection__r.RecordType.Name)){
        unit.RecordTypeId = unitRecordTypes.get('Household Unit').getRecordTypeId();
      }else if('Collections'.equals(collectionInstance.Collection__r.RecordType.Name)){
        unit.RecordTypeId = unitRecordTypes.get('Business Unit').getRecordTypeId();
      }

      //set unit records type for some specific collection code
      //for example set QBAS unit for QBAS collection code
      try{
        String unitRecordTypeName = SystemSettings.getValue('unit.recordType.'+collectionInstance.Collection__r.Collection_Code__c);
        if(String.isNotBlank(unitRecordTypeName)){
          unit.RecordTypeId = unitRecordTypes.get(unitRecordTypeName).getRecordTypeId();
        }
      }catch(SystemSettingsException sse){
        //nothing to do, custom setting does not exist
      }

      if(String.isBlank(unit.RecordTypeId)){
        //set default record type
        unit.RecordTypeId = unitRecordTypes.get(DEFAULT_UNIT_RECORD_TYPE_NAME).getRecordTypeId();
      }

      return unit;
    }
    return null;
  }

  private static List<Artefact__c> private_availableArtefacts = new List<Artefact__c>();
  private static Boolean done_findArtefacts = false;
  private List<Artefact__c> findArtefactsForCollectionId(Id collectionId){
    if(!done_findArtefacts){
      private_availableArtefacts = [
        select Name, Collection_Modes__c,Artefact_Code__c, Collection__c, Delivery_Modes__c
        from Artefact__c 
        where Collection__c = :collectionId
      ];
      done_findArtefacts = true;
    }
    return private_availableArtefacts;
  }


  private static Map<String, Set<String>> private_availableCollectionModes = new Map<String, Set<String>>();
  private static Boolean done_findAvailableCollectionModes = false;
  private Set<String> findAvailableCollectionModes(String artefactCode, Collection_Instance__c collectionInstance){
    Set<String> availableCollectionModes = private_availableCollectionModes.get(artefactCode);
    if(!done_findAvailableCollectionModes){
      List<Artefact__c> artefacts = findArtefactsForCollectionId(collectionInstance.Collection__c);

      for(Artefact__c artefact:artefacts){
        Set<String> collectionModes = new Set<String>();
        if(!String.isBlank(artefact.Collection_Modes__c)){
          collectionModes.addAll(artefact.Collection_Modes__c.split(';'));
        }
        private_availableCollectionModes.put(artefact.Artefact_Code__c, collectionModes);
      }

      availableCollectionModes = private_availableCollectionModes.get(artefactCode);
      done_findAvailableCollectionModes = true;
    }
    return availableCollectionModes;
  }

  private static Map<String, Set<String>> private_availableDeliveryModes = new Map<String, Set<String>>();
  private static Boolean done_findAvailableDeliveryModes = false;
  private Set<String> findAvailableDeliveryModes(String artefactCode, Collection_Instance__c collectionInstance){
    Set<String> availableDeliveryModes = private_availableDeliveryModes.get(artefactCode);
    if(!done_findAvailableDeliveryModes){
      List<Artefact__c> artefacts = findArtefactsForCollectionId(collectionInstance.Collection__c);

      for(Artefact__c artefact:artefacts){
        Set<String> deliveryModes = new Set<String>();
        if(!String.isBlank(artefact.Delivery_Modes__c)){
          deliveryModes.addAll(artefact.Delivery_Modes__c.split(';'));
        }
        private_availableDeliveryModes.put(artefact.Artefact_Code__c, deliveryModes);
      }

      availableDeliveryModes = private_availableDeliveryModes.get(artefactCode);
      done_findAvailableDeliveryModes = true;
    }
    return availableDeliveryModes;
  }

  private String getResponseExternalId(Staging_Element__c stagingElement){
    String responseExtId;
    if(stagingElement!=null){
      if(String.isNotBlank(stagingElement.U_Unit_of_Interest_Id__c) && String.isNotBlank(stagingElement.CI_Collection_Instance_Code__c)){
        responseExtId = stagingElement.CI_Collection_Instance_Code__c+''+stagingElement.U_Unit_of_Interest_Id__c;
      }
      if(stagingElement.R_Mark_in_Required__c && stagingElement.Collection_Unit__c && String.isNotBlank(stagingElement.R_Unit_Association__c) && String.isNotBlank(stagingElement.CI_Collection_Instance_Code__c)){
        responseExtId = stagingElement.CI_Collection_Instance_Code__c+''+stagingElement.R_Unit_Association__c;
      }
      if(String.isNotBlank(stagingElement.A_Instrument_Code__c)){
        responseExtId += stagingElement.A_Instrument_Code__c;
      }
    }
    return responseExtId;
  }

  private Boolean isCreatingResponse(Staging_Element__c stagingElement){
    if(stagingElement.R_Mark_In_Required__c){
      return true;
    }else if(String.isNotBlank(stagingElement.A_Instrument_Code__c)){
      // handle cases where R_Mark_in_Required__c is not provided in sample file
            // but the instructment is provided.  IN this case, set Mark-IN-required to true
            return true;
    }else if(stagingElement.Survey_Unit__c){
      //create response for survey unit
      return true;
    }else{
      return false;
    }

  }
  
  public Response__c toResponse(Staging_Element__c stagingElement, Collection_Instance__c collectionInstance, Unit__c collectionUnit,Unit__c existingCollectionUnit ) {
    String responseExtId = getResponseExternalId(stagingElement);

    if(stagingElement!=null && isCreatingResponse(stagingElement) && String.isNotBlank(responseExtId)){

      Response__c response = new Response__c();
      response.Staging_Element_Id__c = stagingElement.Id;
      response.Response_ExtId__c = responseExtId;
      if(Logger.isEnabled()){
        System.debug('response'+response);
      }
      
      //Assign field values based on API Name of the Staging element object
      for (String fieldName:stagingFields_Response) {
        if(stagingElement.get(fieldName)!=null){
          //To assign value to Unit object remove the prefix and get the field value
          response.put(fieldName.removeStartIgnoreCase('r_'),stagingElement.get(fieldName));
        }
      }
      for(Integer i=0; i<stagingFields_Grouping.size(); i++){
        Integer index = i+1;
        String fieldName = 'GR_'+index+'__c';
        if(stagingElement.get(fieldName)!=null){
          //To assign value to Unit object remove the prefix and get the field value
          response.put(fieldName,stagingElement.get(fieldName));
          if(String.isNotBlank(collectionInstance.Grouping__c)){
            response.put('GR_'+index+'_Label__c',collectionInstance.Grouping__r.get('GR_'+index+'_Label__c'));
          }
        }
      }
      for(Integer i=0; i<stagingFields_Contextual.size(); i++){
        Integer index = i+1;
        String fieldName = 'CO_'+index+'__c';
        if(stagingElement.get(fieldName)!=null){
          //To assign value to Unit object remove the prefix and get the field value
          response.put(fieldName,stagingElement.get(fieldName));
          if(String.isNotBlank(collectionInstance.Contextual_Mappings__c)){
            response.put('CO_'+index+'_Label__c',collectionInstance.Contextual_Mappings__r.get('CO_'+index+'_Label__c'));
          }
        }
      }

      //Assign Recordtype Id
      if(collectionInstance != null && collectionInstance.Collection__r.RecordType.Name.equals('Census')){
        if('Dwelling'.equals(stagingElement.R_Type__c)){
          response.RecordTypeId = responseRecordTypes.get('Census Dwelling').getRecordTypeId();
        }else if('Individual'.equals(stagingElement.R_Type__c)){
          response.RecordTypeId = responseRecordTypes.get('Census Individual').getRecordTypeId();
        }else{
          response.RecordTypeId = responseRecordTypes.get('Canvassing').getRecordTypeId();
        }
      }else if(collectionInstance != null && collectionInstance.Collection__r.RecordType.Name.equals('Collections')){
        response.RecordTypeId = responseRecordTypes.get('Business Response').getRecordTypeId();
      }

      //Assign Collection Instance
      if(String.isNotBlank(stagingElement.CI_Collection_Instance_Code__c)){
        Collection_Instance__c ci = new Collection_Instance__c();
        ci.Collection_Instance_Code__c = stagingElement.CI_Collection_Instance_Code__c;
        response.Collection_Instance__r = ci;
      }
      
      //Assign Artefact/Instrument
      if(String.isNotBlank(stagingElement.A_Instrument_Code__c)){
        String artefactExtId = collectionInstance.Collection__r.Collection_Code__c+stagingElement.A_Instrument_Code__c;
        Artefact__c artefact = new Artefact__c();
        artefact.Artefact_ExtId__c = artefactExtId;
        response.Instrument__r = artefact;
      }

      //Assign Collection Mode and delivery mode from primary contact role if available
      Contact_Role__c primaryContactRole = null;
      if(collectionUnit!=null && collectionUnit.Contact_Roles__r!=null && !collectionUnit.Contact_Roles__r.isEmpty()){
        primaryContactRole = collectionUnit.Contact_Roles__r.get(0);
      }

      //Bug Fix- 3921 - When primay contact is null and if it is an extisitng unit then take the contact role details from existing unit.
	  if (primaryContactRole == null && existingCollectionUnit != null && !existingCollectionUnit.Contact_Roles__r.isEmpty()){     
		primaryContactRole = existingCollectionUnit.Contact_Roles__r.get(0);
	  }

      if(String.isNotBlank(stagingElement.A_Instrument_Code__c) && primaryContactRole!=null){
         if(String.isNotBlank(primaryContactRole.Preferred_Collection_Mode__c)){
          Set<String> availableCollectionModes = findAvailableCollectionModes(stagingElement.A_Instrument_Code__c, collectionInstance);
          if(availableCollectionModes!= NULL && !availableCollectionModes.isEmpty() && availableCollectionModes.contains(primaryContactRole.Preferred_Collection_Mode__c)){
            response.Collection_Mode__c = primaryContactRole.Preferred_Collection_Mode__c;
          }
        }
        if(String.isNotBlank(primaryContactRole.Preferred_Delivery_Mode__c)){
          Set<String> availableDeliveryModes = findAvailableDeliveryModes(stagingElement.A_Instrument_Code__c, collectionInstance);
          if(availableDeliveryModes!= NULL && !availableDeliveryModes.isEmpty() && availableDeliveryModes.contains(primaryContactRole.Preferred_Delivery_Mode__c)){
            response.Unit_Delivery_Mode__c = primaryContactRole.Preferred_Delivery_Mode__c;
          }
        }
      }
      //Assign Collection Mode from collection instance if contact role is not available
      if(String.isBlank(response.Collection_Mode__c) && String.isNotBlank(collectionInstance.Primary_Mode__c)){
        response.Collection_Mode__c = collectionInstance.Primary_Mode__c;
      }
      //Assign Delivery Mode from collection instance if contact role is not available
      if(String.isBlank(response.Unit_Delivery_Mode__c) && String.isNotBlank(collectionInstance.Delivery_Mode__c)){
        response.Unit_Delivery_Mode__c = collectionInstance.Delivery_Mode__c;
      }

      //Assign delivery address from unit and then
      //override with it primary conatct if such exists
      ResponseUtil.setResponseDetailsFromUnit(response, collectionUnit);
      if(primaryContactRole!=null){
        ResponseUtil.setResponseDetailsFromContact(response, primaryContactRole.Contact__r, primaryContactRole.Care_Of__c);
      }

      //Assign Unit
      if(collectionUnit==null){
        collectionUnit = new Unit__c();
        collectionUnit.Unit_of_Interest_Id__c = stagingElement.U_Unit_of_Interest_Id__c;
      }
      if(String.isNotBlank(collectionUnit.Unit_of_Interest_Id__c)){
        Unit__c u = new Unit__c();
        u.Unit_of_interest_Id__c = collectionUnit.Unit_of_Interest_Id__c;
        response.Unit_of_Interest__r = u;
      }
      if(stagingElement.Survey_Unit__c && String.isNotBlank(stagingElement.U_Unit_of_Interest_Id__c)){
        Unit__c u = new Unit__c();
        u.Unit_of_interest_Id__c = stagingElement.U_Unit_of_Interest_Id__c;
        response.Survey_Unit__r = u;
      }

      //Assign Contact
      //if(String.isBlank(response.Contact__c) && response.Unit_of_Interest__r != NULL && collectionUnit!=null && !collectionUnit.Contact_Roles__r.isEmpty()){
            //response.Contact__c = collectionUnit.Contact_Roles__r[0].Contact__c;
        //}

		if(String.isBlank(response.Contact__c) && response.Unit_of_Interest__r != NULL && primaryContactRole!=null){
            response.Contact__c = primaryContactRole.Contact__c;
        }

      return response;
    }
    return null;
  }

  private Workload__c toWorkLoad(Staging_Element__c stagingElement){
    if(stagingElement!=null && String.isNotBlank(stagingElement.WL_Workload_ID__c)){
      Workload__c workLoad = new Workload__c();
      workLoad.Staging_Element_Id__c = stagingElement.Id;
      if(stagingElement.get('Workload_OwnerID__c')!=null){
        workload.ownerId = (Id)stagingElement.get('Workload_OwnerID__c');
      }
      for (String fieldName:stagingFields_Workload) {
        if(stagingElement.get(fieldName) != NULL){
          workLoad.put(fieldName.removeStartIgnoreCase('WL_'),stagingElement.get(fieldName));
        }
      }

      //relationship to collection instance
      if(String.isNotBlank(stagingElement.CI_Collection_Instance_Code__c)){
        Collection_Instance__c ci = new Collection_Instance__c();
        ci.Collection_Instance_Code__c = stagingElement.CI_Collection_Instance_Code__c;
        workLoad.Collection_Instance__r = ci;
      }
      return workLoad;
    }
    return null;
  }

  private Work_Item__c toWorkitem(Staging_Element__c stagingElement, Collection_Instance__c collectionInstance){
    //if markin not required response is not created and then no work items are needed
    if(stagingElement!=null && isCreatingResponse(stagingElement) && String.isNotBlank(stagingElement.WI_Work_Item_Type__c)){
      Work_Item__c workItem = new Work_Item__c();
      workItem.Staging_Element_Id__c = stagingElement.Id;
      if(stagingElement.get('Workload_OwnerID__c') != null){
        workItem.OwnerId = (Id)stagingElement.get('Workload_OwnerID__c');
      }
      
      // no such thing as ext-id on work item, the source system don't give a toss
      // without changing too much logic on this, simply put in some GUID on it
      if(collectionInstance.RecordType.Name=='Census' && singletonWorkitems.contains(stagingElement.WI_Work_Item_Type__c)){
        // with ECP-2180, and ECP-2197, we are filter down the "singleton" logic for census only on file loading of type: canvassing, list leave, and access code

        // this only works for Census initial load; for which, the UOI_ID will be provided
        // however, when Census is reloading the sample with "Birthed" unit, the UOI_ID will be null, in such case, we rely on the SF-ID already exists
        workItem.Work_Item_ExtId__c = (stagingElement.CI_Collection_Instance_Code__c+''+stagingElement.U_Unit_of_Interest_Id__c+''+stagingElement.WI_Work_Item_Type__c).toLowercase().trim();
      }else{
        workItem.Work_Item_ExtId__c = ApexUtility.GUID();  
      }
            //record type has to be mentioned explicitly, when workitem is created. ECP-3600 
            if('Census'.equals(collectionInstance.RecordType.Name)){
        workItem.RecordTypeId =  workItemRecordTypes.get('Census').getRecordTypeId();
      }else if('Social'.equals(collectionInstance.RecordType.Name)){
        workItem.RecordTypeId = workItemRecordTypes.get('Social').getRecordTypeId();
      }else if('Collections'.equals(collectionInstance.RecordType.Name)){
        workItem.RecordTypeId = workItemRecordTypes.get('Business').getRecordTypeId();
      }
            
      for(String fieldName:stagingFields_Workitem) {
        if(stagingElement.get(fieldName) != NULL){
          if('WI_Workitem_ID__c'.equalsIgnoreCase(fieldName)){
            workitem.Id = (Id)stagingElement.get(fieldName);
          }else{
            workItem.put(fieldName.removeStartIgnoreCase('WI_'),stagingElement.get(fieldName));
          }
        }
      }

      if(!String.isBlank(stagingElement.A_Instrument_Code__c)){
        String artefactExtId = collectionInstance.Collection__r.Collection_Code__c+stagingElement.A_Instrument_Code__c;
        Artefact__c artefact = new Artefact__c();
        artefact.Artefact_ExtId__c = artefactExtId;
        workItem.Instrument__r = artefact;
      }
      
      String responseExtId = getResponseExternalId(stagingElement);
      if(!String.isBlank(responseExtId)){
        Response__c response = new Response__c();
        response.Response_ExtId__c = responseExtId;
        workItem.Response__r = response;
      }
      
      if(!String.isBlank(stagingElement.WL_Workload_Id__c)){
        Workload__c workload = new Workload__c();
        workload.Workload_ID__c = stagingElement.WL_Workload_Id__c;
        workItem.Workload__r = workload;
      }

      return workItem;
    }
    return null;
  }

  /*/Account
  private Account toAccount(Staging_Element__c stagingElement){
    if(stagingElement==null || String.isBlank(stagingElement.Account_External_Id__c)){
      return null;
    }
    Account acc = new Account();
    acc.Name = stagingElement.C_FirstName__c+' '+stagingElement.C_LastName__c;
    acc.Account_External_Id__c = stagingElement.Account_External_Id__c;
    return acc;
  }*/

  private Contact toContact(Staging_Element__c stagingElement){
    if(stagingElement == null || String.isBlank(stagingElement.C_Legacy_Contact_ID__c) || String.isBlank(stagingElement.Account_External_Id__c)){
      return null;
    }
    Contact ct = new Contact();
    ct.FirstName = stagingElement.C_FirstName__c;
    ct.LastName = stagingElement.C_LastName__c;
    ct.Phone = stagingElement.C_Phone__c;
    ct.Fax = stagingElement.C_Fax__c;
    ct.OtherPhone = stagingElement.C_Other_Phone__c;
    ct.Email = stagingElement.C_Email__c;
    ct.Title = stagingElement.C_Title__c;
    ct.Salutation = stagingElement.C_Salutation__c;
    ct.HomePhone = stagingElement.C_HomePhone__c;
        ct.Staging_Element_Id__c = stagingElement.Id;
    
    /*if(String.isNotBlank(stagingElement.Account_External_Id__c)){
      Account acc = new Account();
      acc.Account_External_Id__c = stagingElement.Account_External_Id__c;
      ct.Account = acc;
    }*/
    
    for (String fieldName: stagingFields_Contact) {
      if(stagingElement.get(fieldName) != NULL){
        ct.put(fieldName.removeStartIgnoreCase('C_'),stagingElement.get(fieldName));
      }
    }
    return ct;
  }

  private Contact_Role__c toContactRole(Staging_Element__c stagingElement, Collection_Instance__c collectionInstance){
    if(stagingElement == null || stagingElement.C_Legacy_Contact_ID__c == null){
      return null;
    }
    String collectionCode = null;
    
    if(collectionInstance!=null && collectionInstance.Collection__r!=null && !String.isBlank(collectionInstance.Collection__r.Collection_Code__c)){
      collectionCode = collectionInstance.Collection__r.Collection_Code__c;
    }else{
      return null;
    }
    
    String unitOfInterestId = null;
    if(!String.isBlank(stagingElement.CR_Unit_Of_Interest_Id__c)){
      unitOfInterestId = stagingElement.CR_Unit_Of_Interest_Id__c;
    }else if(!String.isBlank(stagingElement.U_Unit_Of_Interest_Id__c)){
      unitOfInterestId = stagingElement.U_Unit_Of_Interest_Id__c;
    }else{
      return null;
    }
    
    String contactExtId = stagingElement.C_Legacy_Contact_ID__c;
    String contactRoleIdentifier = collectionCode+unitOfInterestId+contactExtId;
    
    Contact_Role__c contactRole = new Contact_Role__c();
    contactRole.Identifier__c = contactRoleIdentifier;
    
    Collection__c collection = new Collection__c();
    collection.Collection_Code__c = collectionCode;
    contactRole.Collection__r = collection;
    
    Unit__c unit = new Unit__c();
    unit.Unit_of_Interest_ID__c = unitOfInterestId;
    contactRole.Unit_of_Interest_ID__r = unit;
    
    Contact contact = new Contact();
    contact.Legacy_Contact_ID__c = contactExtId;
    contactRole.Contact__r = contact;
    
    for (String fieldName: stagingFields_ContactRole) {
      if(stagingElement.get(fieldName) != NULL){
        contactRole.put(fieldName.removeStartIgnoreCase('CR_'),stagingElement.get(fieldName));
      }
    }
    contactRole.Staging_Element_Id__c = stagingElement.Id;
    return contactRole;
  }

  //Returns API names of the fields in the fieldset
  private static Map<String, Set<String>> private_apiFieldNames = new Map<String, Set<String>>();
  private Set<String> getApiFieldNamesFromFieldSet(String fieldSetName, String objectApiName){
    Set<String> fieldApis = private_apiFieldNames.get(objectApiName+'-'+fieldSetName);
    if(fieldApis==null){
      Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
      Schema.SObjectType SObjectTypeObj = globalDescribeMap.get(objectApiName);
      Schema.DescribeSObjectResult describeSObjectResultObj = SObjectTypeObj.getDescribe();
      Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
      fieldApis = new Set<String>();
      for(Schema.FieldSetMember fieldSetMemberObj :fieldSetObj.getFields()){
        fieldApis.add(fieldSetMemberObj.getFieldPath().toLowercase());
      }
      private_apiFieldNames.put(objectApiName+'-'+fieldSetName, fieldApis);
    }
    return fieldApis;
  }

  private void processUpsertResults(Map<Id, Staging_Element__c> stagingElements, List<Database.UpsertResult> upsertResults, List<SObject> objects, String objectName){
    for(Integer i=0; i<upsertResults.size(); i++){
      Database.UpsertResult upsertResult = upsertResults.get(i);
      if(!upsertResult.isSuccess()){
        String errorMsg = convertErrorsToString(upsertResult.getErrors());
        if('Workload'.equals(objectName) && errorMsg.contains('DUPLICATE_VALUE') && errorMsg.contains('Workload_ID__c')){
          //do nothing. we have inserted the workload, so ignore the duplicate
        }else if('Contact Role'.equals(objectName) && errorMsg.contains('Foreign key external ID') && errorMsg.contains('Legacy_Contact_ID__c'))
        {
            //do nothing user had provided the duplicate contact in sample file
        }
         else if('Contact'.equals(objectName) && errorMsg.contains('DUPLICATES_DETECTED')){
          //do nothing. we have handled the contact already, so ignore the duplicate
        }
          else{
          SObject failedObject = objects.get(i);
          Id stagingElementId = (Id)failedObject.get('Staging_Element_Id__c');
          Staging_Element__c failedStagingElement = stagingElements.get(stagingElementId);
          if(failedStagingElement!=null){
            if(Trigger.isExecuting){
              failedStagingElement.addError(errorMsg);
            }else{
              setStagingElementError(failedStagingElement, objectName, upsertResult.getErrors());
            }
          }
        }
      }
    }
  }

  private void processContactUpsertResults(Map<Id, Staging_Element__c> stagingElements, List<Database.UpsertResult> upsertResults, List<Contact> contacts){
    List<Contact> dupContacts = new List<Contact>();
        List<Contact> failedContacts = new List<Contact>();
        Map<String,String> stagingElementIds = new Map<String,String>();
    Map<Id,List<Database.Error>> contactErrors = new Map<Id,List<Database.Error>>();
    // since we cannot do the non-fuzzy search, and we will use basic filters to locate existing contact, if possible
    Set<String> lastNames = new Set<String>(), mobiles = new Set<String>(), phones = new Set<String>(), emails = new Set<String>();
        for(Integer i=0; i<upsertResults.size(); i++){
            Contact c = contacts[i];
      Database.UpsertResult upsertResult = upsertResults.get(i);
      if(!upsertResult.isSuccess()){
        Database.Error error = upsertResult.getErrors()[0];
         
        SObject failedObject = contacts.get(i);
        Id stagingElementId = (Id)failedObject.get('Staging_Element_Id__c');
                stagingElementIds.put(c.Legacy_Contact_ID__c,stagingElementId);
        if(error instanceof Database.DuplicateError){
          contactErrors.put(c.Id,upsertResult.getErrors());
          // TODO: to be confirmed by the business whether or not alternative phone (OtherPhone) will be passed through from
          //       the sample file (e.g. QBAS)
          lastNames.add(c.LastName);
          if(String.isNotBlank(c.mobilePhone)){          
           // mobiles.add(c.mobilePhone);
            mobiles.add(PhoneValidationRules.FormatePrefix(c.mobilePhone));
          }
          if(String.isNotBlank(c.phone)){
            //phones.add(c.phone);
            phones.add(PhoneValidationRules.FormatePrefix(c.phone));
          }
          if(String.isNotBlank(c.email)){
            emails.add(c.email);
          }
          //process duplicate contacts
          dupContacts.add(c);
        }else{
          //update staging element record with error
          //processUpsertResults(stagingElements, upsertResults, objects, 'Contact');
          failedContacts.add(c);
        }

               // failedContacts.add(c);
      }
    }
        if(!dupContacts.isEmpty())
        {
            if(Logger.isEnabled()){
        System.debug('calling  duplicateContactsProcessing for  '+dupContacts.size()+' records');
      }
            duplicateContactsProcessing(dupContacts,stagingElements,stagingElementIds,contactErrors,lastNames,mobiles,emails,phones);
        }
        if(!failedContacts.isEmpty())
        {
            if(Logger.isEnabled()){
        System.debug('calling  processUpsertResults for  '+upsertResults.size()+' records');
      }
            processUpsertResults(stagingElements, upsertResults, contacts, 'Contact');
        }
  }

  @TestVisible 
  private void processSaveResults(Map<Id, Staging_Element__c> stagingElements, List<Database.SaveResult> saveResults, List<SObject> objects, String objectName){
    for(Integer i=0; i<saveResults.size(); i++){
      Database.SaveResult saveResult = saveResults.get(i);
      if(!saveResult.isSuccess()){
        SObject failedObject = objects.get(i);
        Id stagingElementId = (Id)failedObject.get('Staging_Element_Id__c');
        Staging_Element__c failedStagingElement = stagingElements.get(stagingElementId);
        if(failedStagingElement!=null){
          setStagingElementError(failedStagingElement, objectName, saveResult.getErrors());
        }
      }
    }
  }
    
    //process duplicate contacts
    private void duplicateContactsProcessing(List<Contact> dupContacts,Map<Id, Staging_Element__c> stagingElements,Map<String,String> stagingElementIds, Map<Id,List<Database.Error>> contactErrors, Set<String> lastNames, Set<String> mobiles, Set<String> emails, Set<String> phones){
       // if(Logger.isEnabled()){
       // System.debug(' dupContacts are '+ dupContacts);
       // }
        Map<String,Contact> existingContacts = new Map<String,Contact>();
        Map<String,Contact> contactMaps = new Map<String,Contact>();
        List<Contact> updateContacts = new List<Contact>();
    List<Contact> failedContacts = new List<Contact>();
    Set<String>keyToDelete = new Set<String>();
         if(Logger.isEnabled()){
       
           
             System.debug(' phones are  '+ phones);
            
             
        }
        if(!dupContacts.isEmpty()){
      for(Contact existingContact: [select id, FirstName, LastName, Phone, Email, MobilePhone, OtherPhone, Legacy_Contact_ID__c from Contact where
        LastName in :lastNames and (MobilePhone in :mobiles or Phone in :phones or Email in :emails) ]){
                    // best effort to find the contact
                    // create a map with fn+ln+phone (etc) to try to find the
                    
                    // since we cannot do fuzzy search on first name, if we found duplicate ln+phone, or ln+email or ln+mobile
                    // we will create a manual task if we found more than 1.
                    // in this case, we will delete the reference if we find more than 1
                    
                    // lastname is complusory field to create new contact
                      if(Logger.isEnabled()){
        System.debug(' existingContact is '+ existingContact);
        }
                    if(String.isNotBlank(existingContact.Phone)){
                        String k = lowerCase(existingContact.lastName) + existingContact.Phone;
                        if(contactMaps.containsKey(k)){keyToDelete.add(k);}
                        else{contactMaps.put(k,existingContact);}
                        // for the full search
                        k = lowerCase(existingContact.firstName) + k;
                        contactMaps.put(k,existingContact);
                    }
                    if(String.isNotBlank(existingContact.OtherPhone)){
                      // even we might not have the otherPhone coming through the sample, we try to dup-match it
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
             if(Logger.isEnabled()){
                 System.debug(' contactMaps keys are '+contactMaps.keySet());}
      
            // remove the duplicate partial keys
            for(String k:keyToDelete){contactMaps.remove(k);} 
            
            // now we have a set of contact, hopfully, we find a match
            // if we have the same contact under different mark-in and the details are different, randomly overwrite
            for(Contact c: dupContacts){
                Contact oldRecord = null;
                // first in first server, no point of trying too hard
                if(String.isNotBlank(c.phone)){
                    String k1 = lowerCase(c.firstName)+lowerCase(c.lastname)+PhoneValidationRules.FormatePrefix(c.phone);
                    String k2 = lowerCase(c.lastname)+PhoneValidationRules.FormatePrefix(c.phone);          
                    // let's try full search
                    if(contactMaps.containsKey(k1)){
                        oldRecord = contactMaps.get(k1);
                    } else if (contactMaps.containsKey(k2)) {
                        // no match on fn+ln+phone, now, only come in here, if the key has no dup
                        oldRecord = contactMaps.get(k2);
                    }
                }
                // todo: to be confirmed with business whether or not we will capture OtherPhone on the sample file, add the OtherPhone matching logic
                if(oldRecord == null && String.isNotBlank(c.mobilePhone)){          
                    String k1 = lowerCase(c.firstName)+lowerCase(c.lastname)+PhoneValidationRules.FormatePrefix(c.mobilePhone);
                    String k2 = lowerCase(c.lastname)+PhoneValidationRules.FormatePrefix(c.mobilePhone);
                    
                    if(contactMaps.containsKey(k1)){
                        oldRecord = contactMaps.get(k1);
                    } else if(contactMaps.containsKey(k2)){
                        oldRecord = contactMaps.get(k2);
                    }
                }
                if(oldRecord == null && String.isNotBlank(c.email)){
                    String k1 = lowerCase(c.firstname)+lowerCase(c.lastname)+lowerCase(c.email);
                    String k2 = lowerCase(c.lastname)+lowerCase(c.email);
                    if(contactMaps.containsKey(k1)){
                        oldRecord = contactMaps.get(k1);
                    } else if(contactMaps.containsKey(k2)){
                        oldRecord = contactMaps.get(k2);
                    }
                }
                String stgId = stagingElementIds.get(c.Legacy_Contact_ID__c);
                
        Staging_Element__c failedStagingElement = stagingElements.get(stgId);
                 if(Logger.isEnabled()){
        System.debug(' duplicateContactsProcessing stgId is '+stgId+' failedStagingElement is '+failedStagingElement.C_LastName__c +' oldRecord is'+oldRecord);
      }
                if(oldRecord != null && oldRecord.get('Legacy_Contact_ID__c') != null){
                  stagingElements.get(stgId).C_Legacy_Contact_ID__c = (String)oldRecord.get('Legacy_Contact_ID__c');
                }else if(oldRecord != null && stagingElements.get(stgId).C_Legacy_Contact_ID__c != null){
                    oldRecord.Legacy_Contact_ID__c = stagingElements.get(stgId).C_Legacy_Contact_ID__c;
                    updateContacts.add(oldRecord);
                }else{
                    if(Logger.isEnabled()){
                        
        System.debug('calling  setStagingElementError from duplicateContactsProcessing for failedStagingElement '+failedStagingElement.C_LastName__c+' and Id '+c.Id);
                        System.debug('contact errors are'+contactErrors.get(c.Id));
      }
          setStagingElementError(failedStagingElement, 'Contact', contactErrors.get(c.Id));
        }
            }
        }
        if(!updateContacts.isEmpty()){update updateContacts;}
    }

  private static String lowerCase(String a){
    return (String.isBlank(a))?'':a.toLowercase();
  }

   //To assign response contact and delivery address
   @TestVisible 
   private void assignResponseDeliveryAdrFromContact(List<Response__c> responses){	
    if(responses!=null && !responses.isEmpty()){	
      Set<String> unitExtIds = new Set<String>();
      Set<String> collectionInstanceCodes = new Set<String>();
      for(Response__c response:responses){
        if(!String.isBlank(response.Survey_Unit__r.Unit_of_interest_Id__c)){
          unitExtIds.add(response.Survey_Unit__r.Unit_of_interest_Id__c);
        }
        if(!String.isBlank(response.Collection_Instance__r.Collection_Instance_Code__c)){
          collectionInstanceCodes.add(response.Collection_Instance__r.Collection_Instance_Code__c);
        }
      }
      
      List<Collection_Instance__c> collectionInstances = [select Collection__r.Collection_Code__c, Collection_Instance_Code__c,Collection__c from Collection_Instance__c where Collection_Instance_Code__c in :collectionInstanceCodes];
      
	  Set<String> collectionIds = new Set<String>();

      if(collectionInstances!=null && !collectionInstances.isEmpty()){
        for(Collection_Instance__c collectionInstance:collectionInstances){
		  collectionIds.add(collectionInstance.Collection__c);
        }
      }

	 List<Unit__c> units = [
        select 
          Unit_of_Interest_ID__c,
          Building_Name__c,
          Level_Number__c,
          Unit_Number__c,
          Road_Name__c,
          Road_Number__c,
          Road_Number_Alpha__c,
          Road_Type__c,
          Rural_Delivery_Number__c,
          Suburb__c,
          Town_or_City__c,
          Postcode__c,
          Building_Level_Unit__c,
          Street_Road_PO_Box__c,
          Suburb_Rural_Delivery__c,
          Country__c,
          (select Preferred_Collection_Mode__c, Preferred_Delivery_Mode__c, Care_of__c,
            Contact__c, Contact__r.Company_name__c, Contact__r.Box_Bag_Number__c,
            Contact__r.Building_Level_Unit__c, Contact__r.Building_Name__c, 
            Contact__r.Country__c, Contact__r.Delivery_Service_Type__c,
            Contact__r.Level_Number__c, Contact__r.Mail_Town__c, 
            Contact__r.Postcode__c, Contact__r.Road_Direction__c, Contact__r.Road_Name__c,
            Contact__r.Road_Number__c, Contact__r.Road_Number_Alpha__c, 
            Contact__r.Road_Type__c, Contact__r.Rural_Delivery_Number__c, 
            Contact__r.Suburb__c, Contact__r.Street_Road_PO_Box__c, 
            Contact__r.Suburb_Rural_Delivery__c, Contact__r.Town_or_City__c, Contact__r.Has_Address__c
          from Contact_Roles__r where Primary_Contact__c = true and Collection__c = :collectionIds limit 1) 
        from Unit__c where Unit_of_Interest_ID__c in :unitExtIds];
	   
		Contact_Role__c primaryContactRole = null;
        Map<String, Unit__c> unitsWithUOIds = new Map<String, Unit__c>();

		for (Unit__c unitItem :units){
			if(!String.isBlank(unitItem.Unit_of_Interest_ID__c)){
			  unitsWithUOIds.put(unitItem.Unit_of_Interest_ID__c, unitItem);
			}
		}

	   for(Response__c currentResponse:responses){
			if(!String.isBlank(currentResponse.Collection_Instance__r.Collection_Instance_Code__c)){

			primaryContactRole = null;
		    
			System.debug('assignResponseDeliveryAdrFromContact => currentResponse.Survey_Unit__r.Unit_of_interest_Id__c '+currentResponse.Survey_Unit__r.Unit_of_interest_Id__c);

			if(currentResponse.Survey_Unit__r!=null && !String.isBlank(currentResponse.Survey_Unit__r.Unit_of_interest_Id__c))
			{
				if(unitsWithUOIds != null ){

					Unit__c cru = unitsWithUOIds.get(currentResponse.Survey_Unit__r.Unit_of_interest_Id__c);

				System.debug('assignResponseDeliveryAdrFromContact => cru '+cru);

					if (cru != null ){

						if(cru.Contact_Roles__r!=null && !cru.Contact_Roles__r.isEmpty()){
							primaryContactRole = cru.Contact_Roles__r.get(0);
						}
						if(primaryContactRole != null){
							currentResponse.Contact__c = primaryContactRole.Contact__c;
							if(!String.isBlank(primaryContactRole.Preferred_Collection_Mode__c))
							{
								currentResponse.Collection_Mode__c = primaryContactRole.Preferred_Collection_Mode__c;
							}
							if(!String.isBlank(primaryContactRole.Preferred_Delivery_Mode__c))
							{
								currentResponse.Unit_Delivery_Mode__c = primaryContactRole.Preferred_Delivery_Mode__c;
							}
				
							System.debug('assignResponseDeliveryAdrFromContact => calling setResponseDetailsFromContact');
							//override the response delivery address and care-of based on the details on this contact role
							ResponseUtil.setResponseDetailsFromContact(currentResponse, primaryContactRole.Contact__r, primaryContactRole.Care_Of__c);
						}
					}
				}
            }
        }
	
	   }
	   }
   }

    @TestVisible private void assignDataFromContactRoleUnit(List<Response__c> responses){
    if(responses!=null && !responses.isEmpty()){
      Set<String> unitExtIds = new Set<String>();
      Set<String> collectionInstanceCodes = new Set<String>();
      for(Response__c response:responses){
        if(!String.isBlank(response.Survey_Unit__r.Unit_of_interest_Id__c)){
          unitExtIds.add(response.Survey_Unit__r.Unit_of_interest_Id__c);
        }
        if(!String.isBlank(response.Collection_Instance__r.Collection_Instance_Code__c)){
          collectionInstanceCodes.add(response.Collection_Instance__r.Collection_Instance_Code__c);
        }
      }
      
      List<Collection_Instance__c> collectionInstances = [select Collection__r.Collection_Code__c, Collection_Instance_Code__c from Collection_Instance__c where Collection_Instance_Code__c in :collectionInstanceCodes];
      Map<String, Collection_Instance__c> ciMap = new Map<String, Collection_Instance__c>();
      Set<String> collectionCodes = new Set<String>();
      if(collectionInstances!=null && !collectionInstances.isEmpty()){
        for(Collection_Instance__c collectionInstance:collectionInstances){
          collectionCodes.add(collectionInstance.Collection__r.Collection_Code__c);
          ciMap.put(collectionInstance.Collection_Instance_Code__c, collectionInstance);
        }
      }


      List<Contact_Role_Unit__c> crUnits = [select 
          Survey_Unit_Link__r.Unit_of_interest_Id__c, 
          Collection_Code__c,
          Contact_Role__r.Contact__c,
          Contact_Role__r.Contact__r.Building_Level_Unit__c, Contact_Role__r.Contact__r.Building_Name__c, 
          Contact_Role__r.Contact__r.Country__c, Contact_Role__r.Contact__r.Delivery_Service_Type__c,
          Contact_Role__r.Contact__r.Level_Number__c, Contact_Role__r.Contact__r.Mail_Town__c, 
          Contact_Role__r.Contact__r.Postcode__c, Contact_Role__r.Contact__r.Road_Direction__c, Contact_Role__r.Contact__r.Road_Name__c,
          Contact_Role__r.Contact__r.Road_Number__c, Contact_Role__r.Contact__r.Road_Number_Alpha__c, 
          Contact_Role__r.Contact__r.Road_Type__c, Contact_Role__r.Contact__r.Rural_Delivery_Number__c, 
          Contact_Role__r.Contact__r.Suburb__c, Contact_Role__r.Contact__r.Street_Road_PO_Box__c, Contact_Role__r.Contact__r.Box_Bag_Number__c,
          Contact_Role__r.Contact__r.Suburb_Rural_Delivery__c, Contact_Role__r.Contact__r.Town_or_City__c, Contact_Role__r.Contact__r.Has_Address__c,
          Contact_Role__r.Care_of__c,
          Contact_Role__r.Unit_of_interest_Id__r.Unit_of_interest_Id__c,
          Contact_Role__r.Preferred_Collection_Mode__c,
          Contact_Role__r.Preferred_Delivery_Mode__c,
          Contact_Role__r.Contact__r.company_name__c
        from Contact_Role_Unit__c
        where   
          Active__c=true and
          Survey_Unit_Link__r.Unit_of_interest_Id__c in :unitExtIds and
          Collection_Code__c in :collectionCodes
      ];
      
      for(Response__c response:responses){
        if(Logger.isEnabled()){
          System.debug('assignContactsFromContactRoleUnit response = '+response+', response.Collection_Instance__r.Collection_Instance_Code__c='+response.Collection_Instance__r.Collection_Instance_Code__c);
        }
        if(!String.isBlank(response.Collection_Instance__r.Collection_Instance_Code__c)){
          String collectionCode = ciMap.get(response.Collection_Instance__r.Collection_Instance_Code__c).Collection__r.Collection_Code__c;
          for(Contact_Role_Unit__c cru:crUnits){
            if(Logger.isEnabled()){
              System.debug('response Survey_Unit__r = '+response.Survey_Unit__r);
              System.debug('response Unit_of_Interest__r = '+response.Unit_of_Interest__r);
              System.debug('response Survey_Unit__r.Unit_of_interest_Id__c = '+response.Survey_Unit__r.Unit_of_interest_Id__c);
              System.debug('response Unit_of_Interest__r.Unit_of_interest_Id__c = '+response.Unit_of_Interest__r.Unit_of_interest_Id__c);
              System.debug('cru.Survey_Unit_Link__r.Unit_of_interest_Id__c = '+cru.Survey_Unit_Link__r.Unit_of_interest_Id__c);
              System.debug('cru.Contact_Role__r.Unit_of_interest_Id__r.Unit_of_interest_Id__c = '+cru.Contact_Role__r.Unit_of_interest_Id__r.Unit_of_interest_Id__c);
              System.debug('collectionCode = '+collectionCode);
              System.debug('cru.Collection_Code__c = '+cru.Collection_Code__c);
            }
            if(response.Survey_Unit__r!=null
              && response.Unit_of_Interest__r!=null
              && response.Survey_Unit__r.Unit_of_interest_Id__c.equals(cru.Survey_Unit_Link__r.Unit_of_interest_Id__c) 
              && response.Unit_of_Interest__r.Unit_of_interest_Id__c.equals(cru.Contact_Role__r.Unit_of_interest_Id__r.Unit_of_interest_Id__c) 
              && collectionCode.equals(cru.Collection_Code__c)
            ){
              response.Contact__c = cru.Contact_Role__r.Contact__c;
              if(!String.isBlank(cru.Contact_Role__r.Preferred_Collection_Mode__c)){response.Collection_Mode__c = cru.Contact_Role__r.Preferred_Collection_Mode__c;}
              if(!String.isBlank(cru.Contact_Role__r.Preferred_Delivery_Mode__c)){response.Unit_Delivery_Mode__c = cru.Contact_Role__r.Preferred_Delivery_Mode__c;}
              // override the response delivery address and care-of based on the details on this contact role
              ResponseUtil.setResponseDetailsFromContact(response, cru.Contact_Role__r.Contact__r, cru.Contact_Role__r.care_of__c);
            }
          }
        }
      }
    }
  }

  //Throw error if staging element collection instance code does not match given collection instance code
  private void multipleCollectionInstanceCodeError(Staging_Element__c stagingElement){
    if(stagingElement!=null){
      String errorMsg = 'Collection Instance Codes do not match. Could be that multiple collection instance codes are present in the dataset.';
      
      if(Trigger.isExecuting){
        stagingElement.CI_Collection_Instance_Code__c.addError(errorMsg);
      }else{
        setStagingElementError(stagingElement, errorMsg, null);
      }
    }
  }
  
  //Assign Errors to Staging Record
  @TestVisible private void setStagingElementError(Staging_Element__c stagingElement, String failedObjectName, List<Database.Error> errors){
    if(Logger.isEnabled()){
      System.debug(LoggingLevel.Error, 'Setting errors '+errors);
    }
    stagingElement.Failed__c = true;
    if(String.isBlank(stagingElement.Errors__c)){
      stagingElement.Errors__c = failedObjectName+' \n'+convertErrorsToString(errors);
    }else{
      stagingElement.Errors__c += '\n\n';
      stagingElement.Errors__c += failedObjectName;
      stagingElement.Errors__c += '\n';
      stagingElement.Errors__c += convertErrorsToString(errors);
    }
    if(Logger.isEnabled()){
      System.debug('Setting failed '+stagingElement.Failed__c+' Setting errors '+stagingElement.Errors__c);
    }
  }

  //Form the Error String
  @TestVisible private String convertErrorsToString(List<Database.Error> errors){
    if(errors != null && !errors.isEmpty()){
      Boolean isFirst = true;
      String errorStr = '';
      for(Database.Error error:errors){
        if(!isFirst){
          errorStr += '\n\n';
        }
        errorStr += DateTime.now().format();
        errorStr += '\n';
        errorStr += error.getStatusCode();
        errorStr += '\n';
        errorStr += error.getFields();
        errorStr += '\n';
        errorStr += error.getMessage();

        isFirst = false;
      }
      return errorStr;
    }
    return null;
  }
}