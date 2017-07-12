/* @Deprecated, logic is under ProcessBuilder */
public class CensusUnitStatus_WFAction implements WorkitemWorkflowAction {
/*
	private static Set<String>lockDownStatus=new Set<String>{
		'refused', 'completed'
	};
	
	public boolean action(final Work_Item__c wi, Response__c r, Map<String,Object>p){
		if(wi==null||wi.response__c==null||String.isBlank(wi.response__r.Workflow_Status__c)){
			// go to next action, nothing to do here
			return true;
		}
		if(lockDownStatus.contains(wi.response__r.Workflow_Status__c.trim().toLowerCase())){
			return false; // no need to go any further, we are in locked down
		}
		return true;
	}
*/
}