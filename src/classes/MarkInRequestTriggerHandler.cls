/**
 * @description Handler class to contain all logic for Mark In Request trigger
 * @author Ram Veligeti
 * @date 1.Oct.2015
 */
public class MarkInRequestTriggerHandler{
	public static Id individualRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
	public static Id dwellingRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();

	@testvisible private boolean processed{get;set;}
	private MarkInRequestTriggerHandler(){
		processed=false;
	}
	private static MarkInRequestTriggerHandler instance;
	public static MarkInRequestTriggerHandler getInstance(){
		if(instance==null){
			instance = new MarkInRequestTriggerHandler();
		} 
		return instance;
	}

	public void processUpdate(Map<Id,Mark_In_Request__c>oMap,Map<Id,Mark_In_Request__c> nMap){
		Mark_In_Request__c[]processList=new Mark_In_Request__c[]{};
		for(Id k: nMap.keySet()){
			if(oMap.get(k).Mark_in_DF_Check__c!=nMap.get(k).Mark_in_DF_Check__c){
				continue;
			}
			if(nMap.get(k).processed__c || nMap.get(k).failed__c){
				continue;
			}
			processList.add(nMap.get(k));
		}
		// ECP-2726: stop future in future error
		if(processList.size()>0 && !system.isFuture()){
			processMarkInRequests(processList);
		}
	}

	// only trigger from "after", so, we have IDs
	public void processMarkInRequests(List<Mark_In_Request__c> newMarkInRequests){
		List<Id> newMarkInIds = new List<Id>();
		Set<String> docIdAccessCode = new Set<String>();
		Mark_In_Request__c[]DFList=new Mark_In_Request__c[]{};
		for(Mark_In_Request__c mi: newMarkInRequests){
			if(!mi.Failed__c){newMarkInIds.add(mi.Id);}
			// added new logic from Eric to handle "first DF" logic
			// attempt to set a unique id to the DF form.
			// if the DF is the first on a response, will try to update the DF record
			if('DF'.equalsIgnoreCase(mi.Form_Type__c)&&String.isBlank(mi.mark_in_df_check__c)){
				DFList.add(mi);
				if(!String.isBlank(mi.access_code__c)){docIdAccessCode.add(mi.access_code__c);}
				if(!String.isBlank(mi.Document_Number__c)){docIdAccessCode.add(mi.Document_Number__c);}
			}
		}
		// doing inline
		// go through the same logic on associating doc-id or access-code
		if(!DFList.isEmpty()){
			Map<String,Id> dacResponseMap = new Map<String,Id>();
			for(DAC_Store__c d: [Select Response__c,document_id__c,Access_Code__c from DAC_Store__c where (document_id__c in :docIdAccessCode or Access_Code__c in :docIdAccessCode) and Response__c != NULL]){
				dacResponseMap.put(d.document_id__c,d.Response__c);
				dacResponseMap.put(d.Access_Code__c,d.Response__c);
			}
			Mark_In_Request__c[]updList=new Mark_In_Request__c[]{};
			// need to suppress insert dup-check on the same batch, or will failed all records
			set<String>dupCheck=new Set<String>();
			for(Mark_In_Request__c mi:DFList){
				Mark_In_Request__c m=new Mark_In_Request__c();
				m.id = mi.id;
				if(!String.isBlank(mi.Document_Number__c)&&dacResponseMap.containsKey(mi.Document_Number__c)){
					String k=dacResponseMap.get(mi.Document_Number__c);
					if(!dupCheck.contains(k)){
						dupCheck.add(k);
						m.mark_in_df_check__c=k;
						updList.add(m);
					}
				} else if(!String.isBlank(mi.access_code__c)&&dacResponseMap.containsKey(mi.Access_Code__c)){
					String k=dacResponseMap.get(mi.Access_Code__c);
					if(!dupCheck.contains(k)){
						dupCheck.add(k);
						m.mark_in_df_check__c=k;
						updList.add(m);
					}
				}
			}
			// don't care about the errors, just update the ones that we need to update
			if(!updList.isEmpty()){Database.update(updList,false);}
		}
		
		processed=true;
		// calling future
		if(Logger.isEnabled()){
		system.debug(LoggingLevel.Info, 'Trigger processing: ' + newMarkInIds.size());
		}
		if(!newMarkInIds.isEmpty()){createResponses(newMarkInIds);}
	}
	
	//Defined as future method to process it as Asynchronous method
	@future
	public static void createResponses(List<Id> newMarkInIds){
		Set<Id> responseIds = new Set<Id>();
		Set<String> docIdAccessCode = new Set<String>();
		Map<String,Response__c> responseMap = new Map<String,Response__c>();
		Map<String,Id> dacResponseMap = new Map<String,Id>();
		// DacStore id to response map
		Map<Id,Response__c> responseList = new Map<Id,Response__c>();
		Set<String> responseDocAccess = new Set<String>();
		Set<Response__c> responseSet = new Set<Response__c>();
		Map<Id,String>markInDac=new Map<Id,String>();

		//Process the newly created Mark-in requests
		integer processCount=0;
		Mark_In_Request__c[]markInRequests=[Select Id,Document_Number__c,Access_Code__c,Number_of_Occupants__c,Form_Type__c,Response_Mode__c,Failed__c,Failed_Reason__c,Mark_in_DF_Check__c
								from Mark_In_Request__c where Id in :newMarkInIds and Failed__c = false and (Document_Number__c != NULL or Access_Code__c != NULL)];
		for(Mark_In_Request__c mir: markInRequests){
			String docAccess;
			if(mir.Document_Number__c != NULL){docAccess = mir.Document_Number__c;}
			else if(mir.Access_Code__c != NULL){docAccess = mir.Access_Code__c;}
			docAccess = docAccess.trim();
			docIdAccessCode.add(docAccess);
			markInDac.put(mir.id,docAccess);
			if(mir.Form_Type__c != NULL && (mir.Form_Type__c.containsIgnoreCase('IF') || mir.Form_Type__c.containsIgnoreCase('DF'))){
				processCount++;
			}
			if(mir.Number_of_Occupants__c != NULL && mir.Number_of_Occupants__c>0){
				processCount++; // could be double count, who cares
			}
		}
		//if no valid records
		if(processCount==0){
			bulkFailMarkIns(markInRequests,'Form Type is Required for Mark-in / Number of Occupants required for updating Primary response');
			return;
		}
		//Query all the access codes
		for(DAC_Store__c d: [Select Id,Response__c,document_id__c,Access_Code__c from DAC_Store__c 
							where (document_id__c in :docIdAccessCode or Access_Code__c in :docIdAccessCode) and Response__c != NULL]){
			responseIds.add(d.Response__c);
			dacResponseMap.put(d.document_id__c,d.Response__c);
			dacResponseMap.put(d.Access_Code__c,d.Response__c);
		}
		if(dacResponseMap.isEmpty()){
			bulkFailMarkIns(markInRequests,'No DAC records available for the Document id/Access code');
			return;
		}
		//If not Document access codes/Responses found
		if(responseIds.isEmpty()){
			bulkFailMarkIns(markInRequests,'No Response available for the Document id/Access code');
			return;
		}
		//Query primary responses i.e response extId is not null
		Map<Id,Response__c> primaryResponseMap = new Map<Id,Response__c>([Select Id,Unit_of_Interest__c,Collection_Instance__c,Access_Code__c,Document_Number__c,Mark_In__c,Status__c,Response_Mode__c
				from Response__c where Id in :responseIds and Response_ExtId__c != NULL]);
		//If No responses found return
		if(primaryResponseMap.isEmpty()){
			bulkFailMarkIns(markInRequests,'No Primary Responses found');
			return;
		}
		System.SavePoint sp = Database.setSavepoint();		
		Map<id,Response__c>dfMap=new Map<Id,Response__c>();
		//process Mark-In responses
		for(Mark_In_Request__c mi: markInRequests){
			String st=markInDac.get(mi.id);
			if(dacResponseMap.containsKey(st) && primaryResponseMap.containsKey(dacResponseMap.get(st))){
				// process mark in
				if(mi.Form_Type__c != NULL && (mi.Form_Type__c.containsIgnoreCase('IF') || mi.Form_Type__c.containsIgnoreCase('DF'))){
					Response__c resp = new Response__c();
					if(!String.isBlank(mi.Mark_in_DF_Check__c)){
						// updating primary DF, check if we already have it
						if(responseList.get(mi.id)!=null){
							resp = responseList.get(mi.id);
						} else {
							// need to check if we already have a occupancy update in this batch
							if(dfMap.get(mi.Mark_in_DF_Check__c)!=null){
								resp=dfMap.get(mi.Mark_in_DF_Check__c);
							}else{
								resp.id = mi.Mark_in_DF_Check__c;
							}
						}
					} else {
						resp.Unit_of_Interest__c = primaryResponseMap.get(dacResponseMap.get(st)).Unit_of_Interest__c;
						resp.Collection_Instance__c = primaryResponseMap.get(dacResponseMap.get(st)).Collection_Instance__c;
						if(mi.Form_Type__c.containsIgnoreCase('IF')){
							resp.RecordTypeId = individualRecordTypeId;
						} else if(mi.Form_Type__c.containsIgnoreCase('DF')){
							resp.RecordTypeId = dwellingRecordTypeId;
						}
					}
					resp.Mark_In__c = true;
					resp.Status__c = 'Completed';
					resp.Response_Mode__c = mi.Response_Mode__c;
                    resp.Mark_In_Access_Code__c = mi.Access_Code__c;
                    resp.Mark_In_Document_ID__c = mi.Document_Number__c;
					resp.Completed_Date__c=system.today();
					if(resp.id!=null){
						// DF
						if(dfMap.get(resp.id)==null){
							responseList.put(mi.id,resp);
						}
						dfMap.put(resp.id,resp);
					} else {
						// for the IFs
						responseList.put(mi.id,resp);
					}
					updateMarkIns(mi,true,false,NULL);
				}
				// process of occupancy... ideally, it should not be the same record, but you never knows
				if(mi.Number_of_Occupants__c != NULL && mi.Number_of_Occupants__c>0){
					if(responseList.get(mi.id)==null){
						// comes from a different Mark-in-request record, and have to check if we already have a DF mark-in in this batch
						Response__c resp = new Response__c();
						String x = primaryResponseMap.get(dacResponseMap.get(st)).id;// cannot use the record from temp story, override the mark-in
						if(dfMap.get(x)!=null){
							resp=dfMap.get(x);
						}else{
							resp.id=x;
							responseList.put(mi.id,resp);
							dfMap.put(x,resp);
						}
						resp.Number_of_Occupants__c = mi.Number_of_Occupants__c;
					}else{
						responseList.get(mi.id).Number_of_Occupants__c = mi.Number_of_Occupants__c;
					}
					updateMarkIns(mi,true,false,NULL);
				}
				
			} else {
				updateMarkIns(mi,false,true,'No DAC/primary response found');
			}
		}

		//update error/procesed
		// future processing is at 200 records, and potentially multi-IF or DF on the same unit will be across different batch
		// in this case, we will encounter record lockings
		try{
			if(!responseList.isEmpty()){
				// due to the logic in response-trigger to only recalculate the primary DF status once on each transaction
				// doing an upsert not working, split up the insert and update
				Response__c[]insList=new Response__c[]{},updList=new Response__c[]{};
				for(Response__c r:responseList.values()){
					if(r.id!=null){updList.add(r);}
					else{insList.add(r);}
				}
            	// todo: Eric: change to partial commit
                boolean gotIns=false;
				if(!insList.isEmpty()){
					insert insList;
					gotIns=true;
				}
				if(!updList.isEmpty()){
					// enforce a recalculation if we have just processed insert
					if(gotIns){
						ResponseTriggerHandler.Executed=false;
					}
					update updList;
				}
			}
			update markInRequests;
		} catch (system.DmlException dmlEx){
			system.debug(LoggingLevel.Error, 'Received Error: ' + dmlEx.getStackTraceString());
			if(sp!=null){
				Database.rollback(sp);
			}
			// not a lot we can do, if we cannot update or insert responses
			bulkFailMarkIns(markInRequests,'System Error: ' + dmlEx.getMessage());
		}
	}
	
	//Update processed mark-in either success or failure
	private static void updateMarkIns(Mark_In_Request__c m, Boolean processed, Boolean failed, String errorMessage){
		m.Processed__c = processed;
		m.Failed__c = failed;
		m.Failed_Reason__c = errorMessage;
	}
	
	//When all the records fail
	private static void bulkFailMarkIns(List<Mark_In_Request__c> markIns, String errorMessage){
		for(Mark_In_Request__c mir: markIns){
			updateMarkIns(mir,false,true,errorMessage);
		}
		update markIns;
	}
}