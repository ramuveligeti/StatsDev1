/* @Deprecated, logic is under ProcessBuilder */
public class CensusOccupancy_WFAction implements WorkitemWorkflowAction {
/*
    Set<String>unoccupiedTypes=new Set<String>{
        'unoccupied - residents away', 'unoccupied - vacant dwelling', 'unoccupied - empty dwelling'
    };
    
    public boolean action(final Work_Item__c wi, Response__c r, Map<String,Object>p){
        if(wi==null||wi.response__c==null||String.isBlank(wi.response__r.Occupancy_Status__c)){
            // go to next action, nothing to do here
            return true;
        }
        if(unoccupiedTypes.contains(wi.response__r.Occupancy_Status__c.trim().toLowerCase())){
            r.workflow_status__c='Unoccupied';
            return false; // no need to go any further
        }
        // go next as default
        r.workflow_status__c=null; // default value, the next action may change it
        return true;
    }
*/    
}