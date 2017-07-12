/* 
 * Author:  	FRONDE - stefania.ezquerra@fronde.com
 * Description: Controller for RolloverResponses page. Clones the responses from the previous period. Only Dwellings, rotations between 1 and 7 unless duplicated. 
 * 				The cloning process happens on a batch process: RolloverBatch.
 * History:		07.Jun.2016 - Created.
 */

public with sharing class RolloverResponsesController {

	@TestVisible
	private Collection_Instance__c ci {get;set;}
	public Boolean showSelectWave {get;set;}
	public Boolean showStartButton {get;set;}
	public Boolean showFailedValidation {get;set;}
	public Boolean showProcessing {get;set;}
	public Boolean showComplete {get;set;}
	public Boolean showResults {get;set;}
	public Result result {get;set;}
	public String validationMessages {get;set;} 
	public Integer numberOfResponsesToClone {get;set;}
	public Integer numberOfExistingResponses {get;set;}
	public List<SelectOption> waves {get;set;}
	public String selectedWave {get;set;}
	public List<Response__c> responsesToBeCloned {get;set;}
	public String asyncJobId{get;set;} 
	public Collection_Instance__c priorCI; // For batch process
	public String collectionInstanceStatus{get;set;} // Used to get updates.
	public Set<Id> exitingUnitsOfInterestForDwellings {get;set;} // Used to avoid duplicates
	public Id dwellingRecordType;
	
	public static string MESSAGE_ROLLOVER_INPROGRESS {get {return 'The Rollover process was previously fired. It\'s currently in progress.';}}
	public static string MESSAGE_ROLLOVER_NOTFOUND {get {return 'The previous Collection Instance was not found. Please check there is a previous Collection Instance from where to clone the Responses. The Planned Start Date needs to be prior to the current Planned Start Date.';}}
	public static string MESSAGE_NO_RESPONSES_FOUND {get {return 'No responses to clone were found for the selected wave on the previous Collection Instance.';}}
	
	public RolloverResponsesController(ApexPages.StandardController stdController) {
		this.ci=(Collection_Instance__c)stdController.getRecord();
		showSelectWave = true;
		showStartButton = false; 
		showProcessing = false;
		showComplete = false;
		showResults = false;
		showFailedValidation = false;
		waves = new list<SelectOption>{new SelectOption('','')};
		for(Integer i=1; i <14; i++){
			string wave = string.valueOf(i);
			waves.add(new SelectOption(wave,wave));
		}
	}
	
	public pageReference onWaveChange(){
		showSelectWave = false;
		system.debug('## Selected wave: ' + selectedWave);
		if(ci.Rollover_Status__c != 'Completed' && ci.Rollover_Status__c != 'Partial Error' && ci.Rollover_Status__c != null){
			//batch already fired, in progress.
			showFailedValidation = true;
			validationMessages = MESSAGE_ROLLOVER_INPROGRESS;
		} else{
			showStartButton = true;
			try{
				priorCI= [select Planned_Start_Date__c,Collection_Number__c  
						  from Collection_Instance__c
						  where Planned_Start_Date__c <: ci.Planned_Start_Date__c
						  and RecordTypeId =: ci.RecordTypeId 
						  and Collection__c =: ci.Collection__c 
						  and Collection_Number__c =: (ci.Collection_Number__c - 1) LIMIT 1];
				
				dwellingRecordType = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
				// Assuming there will be less than 50001 records.
				List<Response__c> existingResponses = new List<Response__c>([select Unit_of_Interest__c, RecordTypeId 
																			 from Response__c 
																			 where Collection_Instance__c =: ci.Id
																			 and Wave__c =: selectedWave
																			 and RecordTypeId =: dwellingRecordType]);
				numberOfExistingResponses = existingResponses.size();
				
				// Avoid duplicates on first try and also on retry after a partial error.
				exitingUnitsOfInterestForDwellings = new Set<Id>();
				for(Response__c r: existingResponses){
					exitingUnitsOfInterestForDwellings.add(r.Unit_of_Interest__c);
				}
				system.debug('## exitingUnitsOfInterestForDwellings: ' + exitingUnitsOfInterestForDwellings);
				
				responsesToBeCloned = new List<Response__c>([select Unit_of_Interest__c 
															 from Response__c 
															 where Rotation_Number_Value__c <= 7 
															 and RecordTypeId =: dwellingRecordType 
															 and Wave__c = : selectedWave
															 and Unit_of_Interest__c NOT IN :exitingUnitsOfInterestForDwellings  // list binded. Not counting against number of chars allowed.
															 and Collection_Instance__c = :priorCI.Id]);
									 
				numberOfResponsesToClone = responsesToBeCloned.size();
				if(numberOfResponsesToClone < 1){
					showStartButton = false;
					showFailedValidation = true;
					validationMessages = MESSAGE_NO_RESPONSES_FOUND;
				}
			} catch (exception e){
				// prior collection instance not found. 
				showStartButton = false;
				showFailedValidation = true;
				validationMessages = MESSAGE_ROLLOVER_NOTFOUND;
			}	
		}
		return null;	
	}

	public pageReference startRollover() { 
		showComplete = false;
		showResults = false; 
		Integer selectedWaveInt = Integer.valueOf(selectedWave);
		asyncJobId=Database.executeBatch(new RolloverBatch(priorCI.Id,ci.Id,exitingUnitsOfInterestForDwellings,selectedWaveInt,true), 2000);  
 
		ci.Rollover_Status__c = asyncJobId;  
		ci.Rollover_Error__c = null;
		try {
			update ci; 
			showProcessing = true;
			showStartButton = false;
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'There was an issue updating the Opportunity but the batch process was fired: ' + e));
		}
		return null;
	}


	public PageReference checkProgress() {		
		if(result == null) result = new Result(0,0, null);
		Collection_Instance__c collectionInstance = [select Rollover_Status__c, Rollover_Error__c from Collection_Instance__c where id = : ci.Id]; // Cannot query parent and child together, salesforce limits exception.
		// Query responses already created.  		
		List<Response__c> responses = new List<Response__c>([select Name  
															 from Response__c 
															 where RecordTypeId =: dwellingRecordType 
															 and Wave__c = : selectedWave
															 and Collection_Instance__c =: ci.Id]);
		result.created = responses.size() - numberOfExistingResponses;
		result.toBeCreated = numberOfResponsesToClone - (responses.size() - numberOfExistingResponses);
		result.errors = collectionInstance.Rollover_Error__c;	
		
		// Show responses.
		showResults = true;
		
		//check if completed
		if(collectionInstance.Rollover_Status__c != 'Completed' && collectionInstance.Rollover_Status__c != 'Partial Error'){	
			return null; 
		}
		else{
			if (collectionInstance.Rollover_Status__c == 'Completed') {
				system.debug('## Batch completed');	
				collectionInstanceStatus = 'Completed';
				showProcessing = false;
				showComplete = true;
			}else{	
				// check if partial error
				if (collectionInstance.Rollover_Status__c == 'Partial Error') {
					system.debug('## Batch completed, partial error');
					collectionInstanceStatus = 'Partial Error';	
					showProcessing = false;
					showComplete = true; 
				}else {
					system.debug('## ERROR: Unknown rollover status');
				}
			}	
			//Clear Status values for next scheduled run.
			collectionInstance.Rollover_Status__c = null;
			collectionInstance.Rollover_Error__c = null;
			update collectionInstance;		
			return null;
		}
	}

	public PageReference changeWaveSelection(){
		showFailedValidation = false;
		showSelectWave = true;
		showStartButton = false;
		return null;
	}

	// Future proof to report on several items. 
    public class Result {
    	public integer created {get;set;}
    	public integer toBeCreated {get;set;}
    	public string errors {get;set;}
    	
    	public Result(integer created, integer toBeCreated, string errors ) {
    		this.created = created;
    		this.toBeCreated = toBeCreated;
    		this.errors = errors;
    	}
    }
	
}