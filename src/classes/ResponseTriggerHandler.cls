/**
 * @description Handler class to contain all logic for response trigger
 * @author S. Yakovlev
 * @date 26.Mar.2015
 */

public with sharing class ResponseTriggerHandler {
	
	public static Boolean Executed = false, dacExecuted = false;
	public static Boolean workItemsExecuted = false;
	public static Map<String, Response_API_Properties__c> responseApiProperties = Response_API_Properties__c.getAll();
	public static Id individualRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
	public static Id dwellingRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
	public static Id canvassingRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Canvassing').getRecordTypeId();
	public static Id businessRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
	public static Id resId;
	// reverse mark-in has to be an update trigger, otherwise, it cannot be reverse
	// this is a conversion of "Reverse mark-in Updat Status" process-builder flow
	public static void beforeUpdate_setResponseStatus(Map<Id, Response__c> oldMap, Map<Id, Response__c> newMap){
		// this trigger does not handle "mark-in at creation" scenario, as we don't have a previous status
		if(newMap!=null&&oldMap!=null){
			Set<Id>ids=new Set<Id>(),wlIds=new Set<Id>();
			for(Response__c r: newMap.values()){
				// Mark_In__c has changed
				if (r.Mark_In__c!=oldMap.get(r.Id).Mark_In__c){
					ids.add(r.id);
				}
			}
			if(ids.isempty()){return;}
			for(Id rid: ids){
				if(newMap.get(rid).Mark_In__c){
					// record old-status for mark-in
					newMap.get(rid).Previous_status__c=oldMap.get(rid).Status__c;
					newMap.get(rid).Previous_status_reason__c=oldMap.get(rid).Response_Status_Reason__c;
					newMap.get(rid).Previous_Occupancy_Status__c = oldMap.get(rid).Occupancy_Status__c;
				}else{
					// reset the status value to previous value
					newMap.get(rid).Status__c=(String.isBlank(newMap.get(rid).Previous_Status__c))?'No Response':newMap.get(rid).Previous_Status__c;
					newMap.get(rid).Response_Status_Reason__c=newMap.get(rid).Previous_status_reason__c;
					newMap.get(rid).Occupancy_Status__c = newMap.get(rid).Previous_Occupancy_Status__c;
				}
			}
		} 
	}
	
	//Assign record type based on target response type on collection instance
	public static void assignRecordType(List<Response__c> newResponses){
		Map<Id,List<Response__c>> responseMap = new Map<Id,List<Response__c>>();
		for(Response__c res: newResponses){
			resId = res.RecordTypeId;
			if(res.Collection_Instance__c!=NULL){
				if(responseMap.containsKey(res.Collection_Instance__c)) responseMap.get(res.Collection_Instance__c).add(res);
				else responseMap.put(res.Collection_Instance__c,new List<Response__c>{res});
			}
		}
		
		if(responseMap.isEmpty()){return;}
		
		List<Collection_Instance__c> ciList = [Select Id,Target_Response_Type__c from Collection_Instance__c where Id in :responseMap.keySet()];
		
		for(Collection_Instance__c ci: ciList){
			for(Response__c res: responseMap.get(ci.Id)){
				if(ci.Target_Response_Type__c != NULL&&String.isNotBlank(res.Mobile_Device_Id__c)){
					//We might need to change this in future, for other surveys
					if(ci.Target_Response_Type__c.containsIgnorecase('Canvassing')) res.RecordTypeId = canvassingRecordTypeId;
					else if(ci.Target_Response_Type__c.containsIgnorecase('Census')) res.RecordTypeId = dwellingRecordTypeId;
					else if(ci.Target_Response_Type__c.containsIgnorecase('Business')) res.RecordTypeId = businessRecordTypeId;
				}
			}
		}
	}

	// When the response was completed then set all its work items to completed
	public static void completeWorkItemsForCompletedResponses(Map<Id, Response__c> oldResponses, Map<Id, Response__c> newResponses){
		// part of ECP-3575, this logic is no longer applicable to Census Dwelling Forms, auto workitem completion is fully based on Response_Summary_status__c, not status__c.
		// however, for Census Canvassing Response, still based on status__c.
		
		ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		
		if(newResponses != null && oldResponses != null){
			Set<Id> completedResponseIds = new Set<Id>();
			Response_API_Properties__c responseStatus = responseApiProperties.get('response.status.closed');
			String responseStatusClosed = responseStatus != null ? responseStatus.Value__c : '';
			Response_API_Properties__c workItemStatus = responseApiProperties.get('workitem.status.closed');
			String workItemStatusClosed = workItemStatus != null ? responseStatus.Value__c : '';

			for(Response__c res: newResponses.values()){
				if( res.recordtypeid != dfID  // exclude Census DF from this logic
					&& String.isNotBlank(res.Status__c) && res.Status__c != oldResponses.get(res.Id).Status__c 
					&& res.Status__c.equals(responseStatusClosed)){
					completedResponseIds.add(res.Id);
				}
			}

			List<Work_Item__c> workItemsToUpdate = new List<Work_Item__c>();
			workItemsToUpdate = [Select Id,Response__c,Status__c from Work_Item__c where Response__c in :completedResponseIds and Status__c <> 'Completed'];

			for(Work_Item__c workItem:workItemsToUpdate){
				Response__c newResponse = newResponses.get(workItem.Response__c);

				if(!String.isBlank(newResponse.Status__c) && newResponse.Status__c.equals(responseStatusClosed)){
					workItem.Status__c = workItemStatusClosed;
				}
			}

			if(!workItemsToUpdate.isEmpty()){
				update workItemsToUpdate;
			}
		}
	}
	
	private static boolean nullOrEmpty(Map<Id,Response__c>m){return m==null||m.isEmpty();}
	private static boolean nullOrFalse(Boolean b){return b==null||!b;}

	// To update dwelling responses when Individual responses are created, modified, deleted or undeleted
	// this is census specific logic
	public static void afterUpdateDwellingResponses(Map<Id, Response__c> oldResponses, Map<Id, Response__c> newResponses){
		if(nullOrEmpty(oldResponses)&&nullOrEmpty(newResponses)){return;}
		if(ResponseTriggerHandler.Executed){return;}// don't run again
		Set<Id>censusRecordTyps=new Set<Id>{individualRecordTypeId,dwellingRecordTypeId};
		Response_API_Properties__c statusClosed = responseApiProperties.get('response.status.closed');
		String responseStatusClosed = statusClosed != null ? statusClosed.Value__c : '';
		
		boolean isUpdateTrigger=!oldResponses.isEmpty()&&!newResponses.isEmpty();
		Set<Id> unitSet = new Set<Id>(), ciSet = new Set<Id>();
		//collect the responses in to a list based on the event fired
		Map<Id,Response__c>responses=(nullOrEmpty(newResponses))?oldResponses:newResponses;
		for(Response__c resp: responses.values()){
			// not census recordtype, or status not closed
			if(!censusRecordTyps.contains(resp.recordtypeid)){continue;}
			// if update, only if status chagned, or number-occupants
			// insert, delete, undelete all in
			if(!isUpdateTrigger || oldResponses.get(resp.Id).Status__c != resp.Status__c || oldResponses.get(resp.id).Number_of_Occupants__c!=resp.Number_of_Occupants__c){
				unitSet.add(resp.Unit_of_Interest__c);
				ciSet.add(resp.Collection_Instance__c);
			}
		}
		if(unitSet.isEmpty()){return;}		
		// logic:
		//  1. based on all the unit collected, go find the responses (DF & IF)
		//	 - depends on batch size, this may go over 10000, use a soql-forloop
		//  2. create memory map of all the DF & IF per unit/per ci
		// note: this is after trigger... so, we can go to Salesforce and ask for the records again
		Map<String,Response__c[]>ifStore=new Map<String,Response__c[]>(),dfStore=new Map<String,Response__c[]>(),
			paperIfStore=new Map<String,Response__c[]>(),paperDFStore=new Map<String,Response__c[]>();
		set<id>wiIds=new set<id>();
		for(Response__c res: [Select Id, Response_ExtId__c, Mark_In__c, Status__c, RecordTypeId, Unit_of_Interest__c, Collection_Instance__c, 
				Number_of_Occupants__c, Number_of_Dwelling_Forms_Received__c, Number_of_Individual_Forms_Received__c, Occupancy_Status__c,
				workflow_status__c, Unit_of_Interest__r.address_type__c, Response_Mode__c
				from Response__c where Unit_of_Interest__c in :unitSet and Collection_Instance__c in :ciSet
				and	RecordTypeId in :censusRecordTyps]){
			String key=String.valueOf(res.Collection_Instance__c)+String.valueOf(res.Unit_of_Interest__c);
			Response__c[]temp=(res.recordTypeId==dwellingRecordTypeId)?dfStore.get(key):ifStore.get(key);
			if(temp==null){
				temp=new Response__c[]{};
			}
			temp.add(res);
			if(res.recordTypeId==dwellingRecordTypeId){			
				dfStore.put(key,temp);
			}else{
				ifStore.put(key,temp);
			}
		}
				
		// now we have "all" the df+if on each unit, let's do some math
		Response__c[]primaryDFs=new Response__c[]{};
		set<id>completedDFs=new set<id>();
		for(String k: dfStore.keySet()){
			// until mark-in has finalised, assume we "udpate" the primary DF form
			Response__c[]DFs=dfStore.get(k),IFs=ifStore.get(k);
			// cannot continue if there are no DF
			if(DFs==null){continue;}
			Response__c primaryDF=null;
			for(Response__c df:DFs){
				// only primary df has the external-id set (set during file loading)
				if(!String.isBlank(df.Response_ExtId__c)){primaryDF=df;break;}
			}
			// cannot continue if we have no primary DF
			if(primaryDF==null){continue;}
			// only if the response status is closed, or mark-in than we count it
			integer completedDF=0,completedIF=0,paperDF=0,paperIF=0;
			if(IFs==null){IFs=new Response__c[]{};}
			// count DFs
			for(Response__c df:DFs){
				if(responseStatusClosed.equals(df.Status__c)||!nullOrFalse(df.Mark_In__c)){
					completedDF++;
					if('paper'.equalsIgnoreCase(df.Response_Mode__c)||'post'.equalsIgnoreCase(df.Response_Mode__c)){paperDF++;}
				}
			}
			// count IFs
			for(Response__c indf:IFs){
				if(responseStatusClosed.equals(indf.Status__c)||!nullOrFalse(indf.Mark_In__c)){
					completedIF++;
					if('paper'.equalsIgnoreCase(indf.Response_Mode__c)||'post'.equalsIgnoreCase(indf.Response_Mode__c)){paperIF++;}
				}
			}
			primaryDF.Number_of_Dwelling_Forms_Received__c=completedDF;
			primaryDF.Number_of_Individual_Forms_Received__c=completedIF;
			primaryDF.Number_of_Paper_Dwelling_Forms__c=paperDF;
			primaryDF.Number_of_Paper_Individual_Forms__c=paperIF;
			// we will not update the number_of_occupants as part of this... it comes through differently
			// this is ECP-1390 logic, setting the status on the primary response
			Decimal occupants = primaryDF.Number_of_Occupants__c==null?0:primaryDF.Number_of_Occupants__c;
			/*if(primaryDF.Number_of_Occupants__c!=null&&primaryDF.Number_of_Occupants__c>0){ //Commented by Ramu Veligeti for ECP-3908 on 09-Aug-17
				if(primaryDF.Number_of_Occupants__c<=completedIF && completedDF>0){
					primaryDF.Response_Summary_Status__c='Completed';
					markDFStatuses(primaryDF, 'Completed');
					completedDFs.add(primaryDF.id);*/
				if(occupants<=completedIF && completedDF>0){ //Added by Ramu Veligeti for ECP-3908 on 09-Aug-17;
					primaryDF.Response_Summary_Status__c='Completed';
					markDFStatuses(primaryDF, 'Completed');
					completedDFs.add(primaryDF.id);
				}else if(completedIF==0 && completedDF>0){
					primaryDF.Response_Summary_Status__c='Partial - DF'; //Added by Ramu Veligeti for ECP-3908 on 09-Aug-17; If Dwelling forms received but no Individual forms then set to Partial - DF
					//primaryDF.Response_Summary_Status__c='Partial'; //Commented by Ramu Veligeti for ECP-3908 on 09-Aug-17
					markDFStatuses(primaryDF, 'Partial');
					// ECP-3575 - remove partial logic on updating outstanding workitems
					//completeOrPartilDFs.add(primaryDF.id);
				}else if(completedDF==0 && completedIF>0){ //Added else by Ramu Veligeti for ECP-3908 on 09-Aug-17; If Individual forms recevied but no Dwelling forms set to Partial - No DF
					primaryDF.Response_Summary_Status__c='Partial - No DF';
					markDFStatuses(primaryDF, 'Partial');
				}else{
					primaryDF.Response_Summary_Status__c='No Response';
				}
			/*}else{ //Commented by Ramu Veligeti for ECP-3908 on 09-Aug-17
				// set to partial if we don't know the number of occupant
				if(completedDF==0&&completedIF==0){
					primaryDF.Response_Summary_Status__c='No Response';
				} else {
					primaryDF.Response_Summary_Status__c='Partial';  
					markDFStatuses(primaryDF, 'Partial');
					// ECP-3575 - remove partial logic on updating outstanding workitems
					//completeOrPartilDFs.add(primaryDF.id);
				}
			}*/
			
			Work_Item__c wi=new work_item__c(Response__c=primaryDF.id);
			if(primaryDF.work_items__r.size()>0){
				wi=primaryDF.work_items__r[0];
			}
			wi.Response__r=primaryDF;
			primaryDFs.add(primaryDF);
		}//for loop
		if(!primaryDFs.isEmpty()){
			ResponseTriggerHandler.Executed = true;
			update primaryDFs;			
		}
		if(!completedDFs.isEmpty()){
			// ECP-2360 - complete all the opened work-items if any IF has been received
			Work_item__c[]workItemsToComplete = [Select Id,Response__c,Status__c from Work_Item__c where Response__c in :completedDFs and Status__c in ('New','In Progress')];
			for(Work_Item__c wi:workItemsToComplete){
				wi.status__c = 'Completed';
			}
			update workItemsToComplete;
		}
	}
	
	// added as part of ECP-2176
	// logic: mark workflow-status to completed on partial or completed response-summary-status
	//		reset the occupancy status, as we are getting forms
	private static void markDFStatuses(Response__c df, String unitStatus){
		if(String.isNotBlank(unitStatus)){
			df.workflow_status__c = unitStatus;
		}
		df.Occupancy_Status__c='Occupied';
		df.Occupancy_Status_Reason__c=null;
	}
	
	public static void copyResponseFieldsFromOriginResponse(List<Response__c> responses){
		Set<Id> parentResponseIds = new Set<Id>();
		for(Response__c r:responses){
			if(!String.isBlank(r.Created_From_Response_Id__c)){
				parentResponseIds.add(r.Created_From_Response_Id__c);
			}
		}
		
		if(!parentResponseIds.isEmpty()){
			Map<Id, Response__c> parentResponses = new Map<Id, Response__c>([select Wave__c from Response__c where Id in :parentResponseIds]);
			
			for(Response__c response:responses){
				if(!String.isBlank(response.Created_From_Response_Id__c)){
					Response__c parentResponse = parentResponses.get(response.Created_From_Response_Id__c);
					if(parentResponse!=null){
						response.Wave__c = parentResponse.Wave__c;
					}
				}
			}
		}
	}		
	
	public static void updateDAC(List<Response__c> newResponses){
		if(newResponses!=null && !newResponses.isEmpty()){
			Map<String, Id> documentResponseMap = new Map<String, Id>();
			
		  /* List<id> responseIds = new List<id>();
			for(Response__c newResponse:newResponses){
			 responseIds.add(newResponse.id);  
			}						
			 List<Response__c> updatedResponses = [select RecordTypeId,CreatedBy.Alias,Document_Number__c,access_code__c,Unit_of_Interest__c, unit_of_Interest__r.address_type__c from Response__c 
								 				 where id IN :responseIds];
			*/
		   
			for(Response__c newResponse:newResponses){
				if(String.isNotBlank(newResponse.Document_Number__c)){
					Set<String> documetIds = convert(newResponse.Document_Number__c);
					for(String documetId:documetIds){
						documentResponseMap.put(documetId, newResponse.Id);
					}
				}
			   /* else
				{											
					if(newResponse.CreatedBy.Alias.equals('auser')){ 
						DACAllocator.allocateDAC(newResponse, true);
				 }
				}
			  */
			}

			List<Dac_Store__c> dacStore = [select Document_ID__c, Response__c 
				from Dac_Store__c 
				where Document_ID__c in :documentResponseMap.keySet()
			];

			List<Dac_Store__c> dacStoreToUpdate = new List<Dac_Store__c>();
			for(Dac_Store__c dac:dacStore){
				Id expectedResponseId = documentResponseMap.get(dac.Document_ID__c);
				Id currentResponseId = dac.Response__c;
				if(expectedResponseId != currentResponseId){
					dac.Response__c = expectedResponseId;	 
					dacStoreToUpdate.add(dac);
				}
			}

			if(!dacStoreToUpdate.isEmpty()){
				update dacStoreToUpdate;
			}

			List<Dac_Store__c> dacStoreToClearCandidates = [select Document_ID__c, Response__c from Dac_Store__c 
				where Response__c in :newResponses
			];
			List<Dac_Store__c> dacStoreToClear = new List<Dac_Store__c>();
			for(Dac_Store__c dac:dacStoreToClearCandidates){
				if(!documentResponseMap.containsKey(dac.Document_ID__c)){
					dac.Response__c = null;
					dacStoreToClear.add(dac);
				
				}
			}
			if(!dacStoreToClear.isEmpty()){
				update dacStoreToClear;
			}
		}
	}

	//used in before insert and before update to clean up comma separated number fields
	public static void cleanUpDocumentAndAccessNumbers(List<Response__c> responses){
		if(responses!=null && !responses.isEmpty()){
			Set<String> docNums = new Set<String>();
			for(Response__c response:responses){
				if(String.isNotBlank(response.Document_Number__c)){
					Set<String> numSet = convert(response.Document_Number__c);
					docNums.addAll(numSet);
					response.Document_Number__c = convert(numSet);
				}
			}


			Map<String, String> dacMap = new Map<String, String>();
			for(Dac_Store__c dac:[select  Document_ID__c, Access_Code__c from Dac_Store__c 
				where Document_ID__c in :docNums
			]){
				dacMap.put(dac.Document_ID__c, dac.Access_Code__c);
			}
			for(Response__c response:responses){
				Set<String> docs = new Set<String>();
				Set<String> codes = new Set<String>();
				String lastDocNum = null;
				String lastAccessCode = null;

				if(String.isNotBlank(response.Document_Number__c)){
					docs = convert(response.Document_Number__c);
					for(String doc:docs){
						if(dacMap.containsKey(doc)){
							codes.add(dacMap.get(doc));
							
							lastDocNum = doc;
							lastAccessCode = dacMap.get(doc);
						}
					}
				}
				
				response.Access_Code__c = convert(codes);
				response.Access_Code_Extract__c = lastAccessCode;
				response.Document_Number_Extract__c = lastDocNum;
			}
		}
	}

	public static Set<String> convert(String nums){
		Set<String> numSet = new Set<String>();
		if(String.isNotBlank(nums)){
			List<String> docNumbersList = nums.split(',');
			for(String docNumber:docNumbersList){
				if(String.isNotBlank(docNumber)){
					numSet.add(docNumber.trim());
				}
			}
		}
		return numSet;
	}

	public static String convert(Set<String> numSet){
		if(numSet!=null && !numSet.isEmpty()){
			String nums = '';
			for(String docNumber:numSet){
				nums += ','+docNumber;
			}
			nums = nums.substring(1);
			return nums;
		}
		return null;
	}

	//Complete some workitems depending on the unit status
	public static void completeWorkitemsForUnitStatus(Map<Id, Response__c> oldResponses, Map<Id, Response__c> newResponses){
		Set<Id> responseIds = new Set<Id>();
		for(Response__c newResponse:newResponses.values()){
			Response__c oldResponse = null;
			if(oldResponses!=null){
				oldResponse = oldResponses.get(newResponse.Id);
			}

			if(newResponse.RecordTypeId.equals(dwellingRecordTypeId)){
				if('Refused'.equals(newResponse.Workflow_Status__c) || 'Forms Sent'.equals(newResponse.Workflow_Status__c)){
					if(Logger.isEnabled()){
						System.debug('oldResponse: '+oldResponse);
						System.debug('newResponse: '+newResponse);
					}
					if(oldResponse!=null && !newResponse.Workflow_Status__c.equals(oldResponse.Workflow_Status__c)){
						responseIds.add(newResponse.Id);
					}
				}
			}
		}

		if(!responseIds.isEmpty()){
			Set<String> workItemStatuses = new Set<String>{'New', 'In Progress', 'Pending'};
			Id censusWorkItemRecordTypeId = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();

			List<Work_Item__c> workitems = [
				select Status__c 
				from Work_Item__c 
				where 
					RecordTypeId = :censusWorkItemRecordTypeId and
					Response__c in :responseIds and 
					Work_Item_Type__c='Non-response follow-up' and
					Status__c in :workItemStatuses
			];

			if(workitems!=null && !workitems.isEmpty()){
				for(Work_Item__c workitem:workitems){
					workitem.Status__c='Completed';
				}
				update workitems;
			}
		}
	}
}