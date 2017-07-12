/* @Deprecated, logic is under ProcessBuilder */
public class CensusWorkItemType_WFAction implements WorkitemWorkflowAction{
/*
    // ideally, use this action up-front, and allow for override by further logic
    // a overall map for Census specific work-items
    // 2-level map
    //  first level:  work-item status => second-level
    //  second level: work-item type => workflow status
    Map<String, Map<String, String>> logicMap = new Map<String, Map<String, String>>{
    	'new' => new Map<String,String>{
//    		'replacement questionnaire' => 'Ready for Delivery',
//    		'mail out' => 'Ready for Delivery',
    		'access code' => 'Ready for Delivery',
    		'list leave' => 'Ready for Delivery',
    		'non-response follow-up' => 'Non-Response Visit Scheduled',
    		'replacement questionnaire' => 'Forms Requested'
    	},
    	'in progress' => new Map<String,String>{
    		'non-response follow-up' => 'Non-Response Visit In Progress'
    	},
    	'completed' => new Map<String,String>{
    		'access code' => 'Forms Sent',
    		'replacement questionnaire' => 'Forms Sent',
    		'non-response follow-up' => 'Non Response Visit Completed',
    		'mail out' => 'Forms Sent',
    		'reminder' => 'Reminder Sent'
    	}
    };
    
	public boolean action(final Work_Item__c wi, Response__c r, Map<String,Object>p){
		if(wi==null||wi.response__c==null||String.isBlank(wi.status__c)||String.isBlank(wi.work_item_type__c)){
			return true;//nothing to do here
		}
		Map<String,String>itemTypeMap=logicMap.get(wi.status__c.toLowercase());
		// set the default value on the workflow
		if(itemTypeMap!=null&&itemTypeMap.containsKey(wi.work_item_type__c.toLowerCase())){
			r.workflow_status__c = itemTypeMap.get(wi.work_item_type__c.toLowerCase());
		}	
		// go next as default
		return true;
	}
*/
}