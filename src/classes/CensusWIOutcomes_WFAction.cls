/* @Deprecated, logic is under ProcessBuilder */
public class CensusWIOutcomes_WFAction implements WorkitemWorkflowAction {
/*
	// go for hardcode, because the tester are doing silly scenarios, and typing rubbish in the subject field
	// cannot cater for every scenario, so, go for explicit scenario
	private static Map<String,Map<String,String>> defaultMap = new Map<String,Map<String,String>>{
		'list leave' => new Map<String,String>{
			'contact, left forms/pack' => 'Forms Sent',
			'contact, left access code' => 'Forms Sent',
			'no contact, left forms/pack' => 'Forms Sent',
			'no contact, left access code' => 'Forms Sent',
			'contact, refusal' => 'Refused',
			'contact: left forms/pack' => 'Forms Sent',
			'contact: left pack/forms' => 'Forms Sent',
			'contact: left pack' => 'Forms Sent',
			'contact: left access code' => 'Forms Sent',
			'contact: refusal' => 'Refused',
			'no contact: unable to contact' => 'Forms Sent',
			'no contact: left forms/pack' => 'Forms Sent',
			'no contact: left pack/forms' => 'Forms Sent',
			'no contact: left pack' => 'Forms Sent',
			'no contact: left access code' => 'Forms Sent'
		},
		'non-response follow-up' => new Map<String,String>{
			'contact, refusal' => 'Refused',
			'contact: refusal' => 'Refused'
		}
	};

	// baed on the wi-type, use this as the default value
	private static Map<String,String> defaultItemTypeWorkflow = new Map<String,String>{
		'list leave' => 'Ready for Delivery',
		'non-response follow-up' => 'Non-Response Visit Scheduled'
	};
	
	public boolean action(final Work_Item__c wi, Response__c r, Map<String,Object>p){
		if(wi==null||p==null||p.isEmpty()||String.isBlank(wi.work_item_type__c)){
			return true;//nothing to do here
		}		
		// outcomes is stored under subject field
		Object o=p.get('task');
		if(o!=null&&!(o instanceof Task)){
			return true;
		}//nothing to do here
		String wit=wi.work_item_type__c.toLowerCase();
		if(o==null){
			// if we don't have any outcome, we will go to the default item-type workflow
			// set to null if we don't have a value, e.g. canvassing, or any rubbish
			if(defaultItemTypeWorkflow.containsKey(wit)){
				r.workflow_status__c = defaultItemTypeWorkflow.get(wit);
			}
			return true;
		}
		String outcome = ((Task)o).subject;
		if(String.isBlank(outcome)){return true;}//nothing to do here, keep current value
		outcome=outcome.toLowerCase();
		Map<String,String>codes=defaultMap.get(wit);
		if(codes!=null&&codes.containsKey(outcome)){
			r.workflow_status__c = codes.get(outcome); 
			return false; // no further actions, value is set
		}

		// keeps current value if no matches on anything
		// including canvassing
		return true;
	}
*/
}