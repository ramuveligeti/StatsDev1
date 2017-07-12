// this is a custom controller to centralise the business logic for census.
// this is an extension to ECP-1513.  
//  - With mobile sync, we have a solution in place to update unit-status using Work-item as trigger
//  - this doesn't work correct for Contact Centre, and they tend to update one piece of information at a time
//
// this story will re-use the workflow actions that were created for 1513\
public class CensusCallCentreUpdateController {
    
    private String responseId{set;get;}
    private String caseId{set;get;}
    private Work_Item__c lastModifiedWI{set;get;}
    private Task lastOutcome{set;get;}

    public Response__c response{set;get;}
    public Unit__c unit{get;set;}

    public boolean displayPage {private set;get;}
    public boolean readonly{private set;get;}
    
    // reuse the action classes that was created for ECP-1513
    // the order determine the hierarchy of processing logic
    /* workflow logic has moved to ProcessBuilder
    private WorkitemWorkflowAction[]actions=new WorkitemWorkflowAction[]{
    	new CensusUnitStatus_WFAction(), // block off refusal from being updated
    	new CensusAccountType_WFAction(), // should be address-type, typo
    	new CensusResponseSummary_WFAction(),
    	new CensusOccupancy_WFAction(),
    	new CensusWIOutcomes_WFAction(),
    	new CensusWorkItemType_WFAction()
    };
    */
    
    public CensusCallCentreUpdateController(ApexPages.StandardController std){
    	caseId = std.getId();
    	Case record = (Case) std.getRecord();
    	displayPage = record.Response__c!=null;
    	if(displayPage){
	    	response = record.Response__r;
	    	unit = record.Response__r.Unit_of_Interest__r;
	    	readonly = (response.workflow_status__c=='Refused'||response.workflow_status__c=='Completed');
	    	lastModifiedWI = [select name,work_item_type__c,status__c from Work_Item__c where Response__c = :response.id order by lastModifiedDate desc limit 1];
	    	Task[] ts = [select subject from Task where whatid = :lastModifiedWI.id order by lastModifiedDate limit 1];
	    	if(ts.size()>0){lastOutcome=ts[0];}
    	}
    }
    
    public PageReference save(){
		/* brain logic has been migrated to ProcessBuilder
		Work_Item__c wi=new Work_Item__c(Response__c=response.id, work_item_type__c=lastModifiedWI.work_Item_type__c);
		wi.Response__r=response;
		boolean nextAction=true;
		for(Integer i=0; nextAction&&i<actions.size();i++){
			nextAction=actions[i].action(wi,response,new Map<String,Object>{'task'=>lastOutcome});
		}
		*/
		// update the response__r object on the corresponding
		update unit;
		update response;
		return backToCase();
    }
    
    public PageReference backToCase(){
		return new PageReference('/'+caseId);
    }
}