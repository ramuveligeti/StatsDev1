/* @Deprecated, logic is under ProcessBuilder */
public class CensusAccountType_WFAction implements WorkitemWorkflowAction {
/*
	private static Set<String>outOfScopeTypes=new Set<String>{
		'commercial','under construction','empty section','shell','alias','address not found'
	};
	
	public boolean action(final Work_Item__c wi, Response__c r, Map<String,Object>p){
		if(wi==null||wi.response__c==null||wi.response__r.unit_of_interest__c==null||String.isBlank(wi.response__r.unit_of_interest__r.Address_Type__c)){
			// go to next action, nothing to do here
			return true;
		}
		if(outOfScopeTypes.contains(wi.response__r.unit_of_interest__r.Address_Type__c.trim().toLowerCase())){
			r.workflow_status__c='Out of Scope';
			return false; // no need to go any further
		}
		// go next as default
		r.workflow_status__c=null; // default value, the next action may change it
		return true;
	}
*/
}