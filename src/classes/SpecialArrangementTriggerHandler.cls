public with sharing class SpecialArrangementTriggerHandler {
	public static Boolean firstRun = false;
	public void onAfterInsert(list<Special_Arrangement__c> saNew){
    	// Submit for approval If recordType suppression and type Do Not Interview.
		submitDNIForApproval(saNew);
	}
	
	public void submitDNIForApproval(list<Special_Arrangement__c> saList){
		list<Approval.ProcessSubmitRequest> reqToSubmitForApproval = new list<Approval.ProcessSubmitRequest>();
		
		Id suppressionRTid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
		for(Special_Arrangement__c sa: saList){
			if(sa.RecordTypeId == suppressionRTid && sa.Suppression_Type__c == 'Do Not Interview'){
				// Submit for approval. 
				Approval.ProcessSubmitRequest  request = new Approval.ProcessSubmitRequest ();
		        request.setObjectId(sa.Id);
		        request.setSubmitterId(sa.OwnerId);
		        reqToSubmitForApproval.add(request);
			}
		}
		if(reqToSubmitForApproval.isEmpty()){return;}
		list<Approval.ProcessResult> results =  Approval.process(reqToSubmitForApproval);
		// Notify on errors.
		for(Approval.ProcessResult r:results){
			if(!r.isSuccess()){
				//Database.Error[] error = r.getErrors(); 
				system.debug('## Error on submiting approval request: ' + r.getErrors());
				// Email? TBD.
			}
		}
	}
}