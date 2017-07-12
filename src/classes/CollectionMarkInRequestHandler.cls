// this class handles the mark-in logic on non-census mark-in
// based on the combination of CollectionCode + ReferencePeriod + UOI_ID (frame) + InstrumentCode
//
// design decision
// 1. using before trigger to validate, and filter processing logic
// 2. using after trigger to process the responses
// 
// Amendment ECP-3278
// Date      14 September 2016
// Author    Caterina Cuccurullo
// Description: Address Tick and Complaint Tick assignment on the Response Object.
// 
public class CollectionMarkInRequestHandler {

	// used in befor trigger, validate, and find the corresponding response-EXTID
	public void validateMarkInRequests(Collection_Mark_In_Request__c[]requests){
		// locate the collection instance code, based on collection-code, and reference-period
		Set<String>collectionCodes=new Set<String>(), referencePeriods=new Set<String>();
		Collection_Mark_In_Request__c[]newMarkIns=new Collection_Mark_In_Request__c[]{};
		for(Collection_Mark_In_Request__c r:requests){
			// stop from reprocessing
			// the validation should have done in before trigger, but then, too much repeat code
			// doing validation in after-trigger.  But make sure it doesn't get reprocessed
			if(!r.processed__c&&!r.failed__c){
				if(String.isNotBlank(r.Collection_Code__c) && String.isNotBlank(r.Reference_Period__c)){
					collectionCodes.add(r.Collection_Code__c);
					referencePeriods.add(r.Reference_Period__c);
					newMarkIns.add(r);
				}else{
					// error on missing info
					r.failed__c = true;
					r.failed_reason__c = 'Incomplete request: missing info';
				}
			}
		}
		
		if(newMarkIns.isEmpty()){
			//everything already processed, or failed
			return;
		}

		// now, we have to find the collection-reference-code			
		Collection_Instance__c[]instances=[select id, collection_instance_code__c, collection__c, collection__r.collection_code__c, reference_period__c
			from Collection_Instance__c where collection__r.collection_code__c in :collectionCodes and reference_period__c in :referencePeriods];

		if(instances.isEmpty()){
			//  error for all incomplete requests
			for(Collection_Mark_In_Request__c r:newMarkIns){
				r.failed__c=true;
				r.failed_reason__c = 'Unknown collection-code + reference';
			}
			return;
		}
		
		// with the combination of collection-code and reference-period, may pick up unwanted collection-instances
		Map<String,Collection_Instance__c>collectionInstanceMap=new Map<String,Collection_Instance__c>();
		for(Collection_Instance__c ci: instances){
			collectionInstanceMap.put(ci.collection__r.collection_code__c+ci.Reference_Period__c,ci);
		}
		
		// go through each request, and see if it has a ci, if not error it,
		// pair up each request with a ci
		// not using map, have to prepare for duplicate requests
		ID[]pendingProcessingIDs=new ID[]{};
		String[]pendingResponseExtIDs=new String[]{};
		for(Collection_Mark_In_Request__c r:newMarkIns){
			if(collectionInstanceMap.containsKey(r.collection_code__c+r.reference_period__c)){
				Collection_Instance__c ci = collectionInstanceMap.get(r.collection_code__c+r.reference_period__c);
				String key=ci.Collection_Instance_Code__c + r.Unit_Of_Interest_ID__c;
				if(String.isNotBlank(r.Instrument_Code__c)){
					key+=r.Instrument_Code__c;
				}
				// set up details for the "second round" of after trigger
				r.Response_ExtID__c = key;
			} else {
				r.failed__c=true;
				r.failed_reason__c='Unknown collection-code + reference';
			}
		}
		
	}

// after trigger logic
	public void processMarkIns(Collection_Mark_In_Request__c[] requests){
		
		Collection_Mark_In_Request__c[]failedMarkIns=new Collection_Mark_In_Request__c[]{},
			pendingRequests=new Collection_Mark_In_Request__c[]{};
		Set<String>respExtIds=new Set<String>();
		for(Collection_Mark_In_Request__c p: requests){
			if(p.processed__c || p.failed__c){
				// do nothing
			} else if (String.isNotBlank(p.Response_ExtID__c)){
				// will process this.  Have to clone the mark-in request, as we cannot update the record inside the trigger
				// added Complaint_Tick ECP-3278//
				pendingRequests.add(new Collection_Mark_In_Request__c(id=p.id, Response_ExtID__c=p.Response_ExtID__c,
					Response_mode__c=p.Response_Mode__c, Complaint_Tick__c=p.Complaint_Tick__c,Image_Url__c = p.Image_Url__c,
					Address_Tick__c=p.Address_Tick__c, Building_Level_Unit__c=p.Building_Level_Unit__c,
					Street_Road_POBox__c=p.Street_Road_POBox__c, Suburb_Rural_Delivery__c=p.Suburb_Rural_Delivery__c,
					Town_City__c=p.Town_City__c,First_Name__c=p.First_Name__c,
					Last_Name__c=p.Last_Name__c,Email__c=p.Email__c,
					Mobile_Number__c=p.Mobile_Number__c,Phone_Number__c=p.Phone_Number__c));
				respExtIds.add(p.Response_ExtID__c);
			}
		}
		
		if(pendingRequests.isEmpty()){
			return;// everything processed or failed, or don't have respones-ext-id
		}
		
		// we are ready to find the response
		Map<String,Response__c>responses=new Map<String,Response__c>();
		for(Response__c r:[select id, Response_ExtId__c, unit_of_interest__c, survey_unit__c,
			collection_code__c, Collection_Instance__c, Collection_Instance__r.Collection__c
			from Response__c where Response_ExtId__c in :respExtIds]){
			responses.put(r.Response_ExtId__c,r);
		}
		// now go through each mark-in requests
		Map<Id,Response__c>markinResponses=new Map<Id,Response__c>();
		Map<String,Response__c>markInRespMap=new Map<String,Response__c>();
		
		//a set of Mark-in requests that will be used for future processing
		Set<Id>futureProcessingRequests=new Set<Id>();
		
		// get a list of unit id for consolidation processing
		Set<ID>unitIds=new Set<ID>(), collectionIds=new Set<ID>(), collectionInstanceIds=new set<Id>();
		for( Collection_Mark_In_Request__c p: pendingRequests){
			if(responses.containsKey(p.Response_ExtID__c)){
				Response__c r=responses.get(p.Response_ExtID__c);
				r.mark_in__c=true;
				r.response_mode__c=p.response_mode__c;
                
                //Changes made for Sybase defect - #ECP-3872
                //To check the image_url not null before updating its value
                if(p.Image_URL__c!=null){
					r.Completed_Response_Link__c=p.Image_URL__c;
                }
				
				// todo: adr-tick, contact details - need to future that
				// in order to future, we need to have a map of IDs.... Mark-In-ID => Response-ID (or we can soql responses based on ext-id on mark-in)
				if(p.address_tick__c || hasRespondentDetails(p)){
                    // add in here assignment of A & C tick  ECP_3278//
                    r.Address_Tick__c = p.Address_Tick__c;
                    r.Complaint_Tick__c = p.Complaint_Tick__c; 
					futureProcessingRequests.add(p.id);
				}
				
				unitIds.add(r.survey_unit__c); // add both collection-unit, and survey-unit, could be different
				collectionIds.add(r.Collection_Instance__r.Collection__c);
				collectionInstanceIds.add(r.Collection_Instance__c);
				p.processed__c=true;
				markinResponses.put(r.id, r);
				markInRespMap.put(r.Response_ExtId__c,r);
			} else {
				p.failed__c=true;
				p.failed_reason__c='Cannot match to a response';
			}
		}
		
		Set<ID>surveyUnitIds=new Set<ID>(), saIds=new Set<ID>();
		// get all special arrangement that belongs to the collections and have UOI-ID
		for( Special_Arrangement__c sa: [select id, Consolidated_Unit__c, collection__r.collection_code__c, survey_unit__c
			from Special_Arrangement__c where recordtype.name = 'Consolidation'
			and Consolidated_Unit__c in :unitIds and collection__c in :collectionIds] ){
				// find survey units that are related to mark-in responses
				surveyUnitIds.add(sa.Survey_Unit__c);
				saIds.add(sa.id);
		}
		if(!surveyUnitIds.isEmpty()){
			// fetch all suppressed responses
			for(Response__c r: [select id, unit_of_interest__r.Unit_Of_Interest_id__c, Collection_Instance__r.Collection_Instance_Code__c,
				instrument__c,instrument__r.artefact_Code__c,
				special_arrangement__c, special_arrangement__r.Consolidated_Unit__c, special_arrangement__r.Consolidated_Unit__r.Unit_Of_Interest_id__c
				from Response__c where collection_instance__c in :collectionInstanceIds and status__c='Suppressed'
				and mark_in__c=false and survey_unit__c in :surveyUnitIds and special_arrangement__c in :saIds ] ){
				// for each suupressed response, find the corresponding response that has just marked in
				String k=r.Collection_Instance__r.Collection_Instance_Code__c + r.special_arrangement__r.Consolidated_Unit__r.Unit_Of_Interest_id__c;
				if(r.instrument__c!=null){
					k+=r.instrument__r.artefact_Code__c;
				}
				if(markInRespMap.containsKey(k)){
					// found a matching consolidated response, mark-in this response
					r.mark_in__c=true;
					r.status__c='Completed';
					r.response_status_reason__c='Consolidated Collection';
					markinResponses.put(r.id, r);
				}
			}
		}
		
		// not doing partial commit, as we cannot trace the responses back to the request
		update pendingRequests;
		update markinResponses.values();
/*
		Response__c[]updList=markinResponses.values();
		Database.SaveResult[] dbResults = Database.update(updList, false);
		integer i=0;
		for(Database.SaveResult r: dbResults){
			if(!r.isSuccess()){
			  // hmmmm, need a way to reverse the response back to the mark-in request.... 	
			  // cannot do that for the suppressed one
			}
			i++;
		}
*/
		
		if(!futureProcessingRequests.isEmpty()){
			processContacts(futureProcessingRequests);
		}
	}

	@future (callout=true)
	private static void processContacts(set<Id> requestIds){
		RespondentContactHandler.processContactRequests(requestIds);
	} 

	private boolean hasRespondentDetails(Collection_Mark_In_Request__c req){
		// not going to check all the fields
		// if we have firstName and/or lastName, return true
		// if we have 1 of the 3 lines of address, return true
		// defer most of the null check to the address handling.  For now, these are the criteria to update respondent
		return ( String.isNotBlank(req.First_Name__c) || String.isNotBlank(req.Last_Name__c) ||
			String.isNotBlank(req.Building_Level_Unit__c) || String.isNotBlank(req.Street_Road_POBox__c) || String.isNotBlank(req.Street_Road_POBox__c)
		);
	}

}