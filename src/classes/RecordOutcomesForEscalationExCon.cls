/* author: Ram Veligeti
 * Story: ECP-1865
 * description: This class is called in RecordOutcomesForEscalation Page. The controller manages escalation outcomes recorded by the Team leads after escalation by CSR's
 * The controller displays fields based on the escalation queue the work item is assigned to. The outcome varies based on the escalation queue and if the team leads could not resolve the
 * issue then they can escalate it to the managers. 
 * The dependent picklist values for Decision,Next step and other actions are managed using custom settings (Escalation Outcomes)
 * 
 * -------------------------------------------------------------------------------------------------------------------------
 * --Change record
 * -------------------------------------------------------------------------------------------------------------------------
 * Date				Developer		UserStory		Change		
 * 13/10/2016		Anna Young		Ecp-3585		Changed checkDependentsOnNextStep to return if decision on work item is null or  blank (was causing a null pointer exception in test data)
 * 25/10/2016		Anna Young		Ecp-3585		Changed fetchDecision so that there is no chance a null value can be passed to outcome.Escalation_Reason__c.containsIgnoreCase, also added a check to checkDependentsOnNextStep
 * 08/12/2016		Steven Zhu	    ECP-3651 and 3773 Changed update response to set extension_past_cut_off__c when approved for extension going over cut off date
 */
public class RecordOutcomesForEscalationExCon{
	public Work_Item__c workItem{get;Set;}
	public String queueOfTheUser{get;Set;}
	public Boolean display{get;Set;}
	public List<SelectOption> decisionSelect{get;Set;}
	public List<SelectOption> nextStepSelect{get;Set;}
	public Map<String,List<Escalation_Outcomes__c>> escalationOutcomeMap;
	public Map<String,Escalation_Outcomes__c> nextStepMap;
	public Boolean renderNextStep{get;Set;}
	public Boolean renderCallBack{get;Set;}
	public Boolean renderExtension{get;Set;}
	public Boolean renderOwner{get;Set;}
	public Task taskObj{get;Set;}
    
    //Standard controller
	public RecordOutcomesForEscalationExCon(ApexPages.StandardController stdCont){
		workItem = (Work_Item__c)stdCont.getRecord();
		escalationOutcomeMap = new Map<String,List<Escalation_Outcomes__c>>();
        //Verify if the user belongs to the team leaders queue
		queueOfTheUser = findQueueOfUser();
        taskObj = new Task();
		System.debug('queueOfTheUser=='+queueOfTheUser);
        //set all the renders to false
		renderNextStep = false;
		renderOwner = false;
		renderCallBack = false;
		renderExtension = false;
        //fetch decision picklist values
		if (queueOfTheUser != NULL){fetchDecision();}
	}
    //Method to fetch decision picklist values
	public void fetchDecision(){
		decisionSelect = new List<SelectOption>();
		decisionSelect.add(new SelectOption('','--None--'));
        //fetch custom setting records and loop through to get the decision and next step picklist values
		for(Escalation_Outcomes__c outcome:  Escalation_Outcomes__c.getAll().values()){
			System.debug('outcome.Owner__c=='+outcome.Owner__c+'=='+queueOfTheUser+'=='+workItem.Delivery_Mode__c+'=='+outcome.Delivery_Mode__c+'=='+outcome.Escalation_Reason__c+'=='+workItem.Escalation_Reason__c);
			if(outcome.Owner__c.containsIgnoreCase(queueOfTheUser) && workItem.Delivery_Mode__c.equalsIgnoreCase(outcome.Delivery_Mode__c) && !String.isBlank(workItem.Escalation_Reason__c) && outcome.Escalation_Reason__c.containsIgnoreCase(workItem.Escalation_Reason__c)){
				if(escalationOutcomeMap.containsKey(outcome.Decision__c)){escalationOutcomeMap.get(outcome.Decision__c).add(outcome);}
				else escalationOutcomeMap.put(outcome.Decision__c,new List<Escalation_Outcomes__c>{outcome});
			}
		}
         
		for(String st:escalationOutcomeMap.keySet()){
			decisionSelect.add(new SelectOption(st,st));
		}
        //get nextstep values based on decision
        fetchNextStep();
        //dependent actions on next step
        checkDependentsOnNextStep();
	}
    
    //method to fetch nextstep values based on decision 
    public void fetchNextStep(){
        if(String.isBlank(workItem.Decision__c)) {        
			renderNextStep = false;
			renderCallBack = false;
			renderCallBack = false;
			renderExtension = false;
			renderOwner = false;
			return;
		}
        if(workItem.Decision__c.equalsIgnoreCase('Approved') || workItem.Decision__c.equalsIgnoreCase('Referred to CSR for follow-up')){
            workItem.Next_Step__c = null;
            workItem.Call_Back_Time__c = null;
            workItem.Response__r.Extension_Date__c = null;
        }
		nextStepSelect = new List<SelectOption>();
		nextStepMap = new Map<String,Escalation_Outcomes__c>();
		nextStepSelect.add(new SelectOption('','--None--'));
		renderNextStep = false;
		renderOwner = false;
		renderCallBack = false;
		renderExtension = false;
		System.debug('selectedDecision=='+workItem.Decision__c+'=='+escalationOutcomeMap);
		if (escalationOutcomeMap.containsKey(workItem.Decision__c)){
			for(Escalation_Outcomes__c st: escalationOutcomeMap.get(workItem.Decision__c)){
                if(String.isNotBlank(st.Next_Step__c)){
                    renderNextStep = true;
                    nextStepSelect.add(new SelectOption(st.Next_Step__c,st.Next_Step__c));
                }
                if(String.isNotBlank(st.Next_Step__c) || String.isNotBlank(st.Decision__c)){
                    String decisionNextStep =st.Decision__c+''+st.Next_Step__c;
                    nextStepMap.put(decisionNextStep.trim(),st);
                }
			}
		}
        checkDependentsOnNextStep();
	}
    
	//On selecting next step check for further actions
	public void checkDependentsOnNextStep(){
        
  
       if (String.isBlank(workItem.Decision__c) || String.isBlank(workItem.Escalation_Reason__c)) return;
       
       //if(String.isBlank(workItem.Next_Step__c) && String.isBlank(workItem.Decision__c)) return;
         
        String decisionNextStep =workItem.Decision__c+''+workItem.Next_Step__c;
        
		if(workItem.Decision__c.equalsIgnoreCase('Referred to CSR for follow-up')){renderOwner = true;}
       
        if(nextStepMap.containsKey(decisionNextStep.trim())){
            renderCallBack = nextStepMap.get(decisionNextStep.trim()).Call_Back__c;
            renderExtension = nextStepMap.get(decisionNextStep.trim()).Extension__c;
        }
        
        if(workItem.Escalation_Reason__c.equalsIgnoreCase('Extension (Beyond Extension Cut-off Date)') &&  workItem.Decision__c.equalsIgnoreCase('Approved')){
			if( workItem.Requested_Extension_Date__c == null){
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Work item does not have a requested extension date set'));
				return;
			}
            workItem.New_Call_Back_Time__c = workItem.Requested_Extension_Date__c.addDays(1);
        }
	}
    
    //method to check if the current user belongs to any of the team leader or manager queues
	public String findQueueOfUser(){
		display = false;
		Set<Id> groupIds = new Set<Id>();
        Set<Id> publicGroups = new Set<Id>();
		String gDevName;
        //Loop through all the queues
		//for(Group q: [Select Id,DeveloperName,RelatedId,(Select UserOrGroupId,Group.Type from GroupMembers) from Group where Id = :WorkItem.Queue_Id__c and Type = 'Queue']){
            //loop through all the queue members like users,roles,groups
			for(GroupMember gm: [Select UserOrGroupId, Group.Type, Group.DeveloperName, Group.RelatedId from GroupMember where GroupId = :WorkItem.Queue_Id__c and Group.Type = 'Queue']){
                gDevName = gm.Group.DeveloperName;
				//get all groupId's
				//if(gm.Group.Type == 'Regular'){groupIds.add(gm.UserOrGroupId);}
				System.debug('gm.UserOrGroupId=='+gm.UserOrGroupId);
                //check if the current user Id matches with any of the users in the queue
				if(gm.UserOrGroupId == UserInfo.getUserId()){
					display = true;
					return gm.Group.DeveloperName;
                }else if(String.valueOf(gm.UserOrGroupId).startsWithIgnoreCase('00G')){
                    groupIds.add(gm.UserOrGroupId);
                }
			}
       
        //}
        for(Group q: [Select Id, Type, RelatedId, DeveloperName from Group where Id in :groupIds]){
        	//check if the current user role matches with roles in the queue
			if(q.Type == 'Role' && q.RelatedId  == UserInfo.getUserRoleId() && q.RelatedId != null && UserInfo.getUserRoleId() != null){
				display = true;
				return gDevName;
			}else if(q.Type == 'Regular') publicGroups.add(q.Id);
        }
        //loop through all group members of the groups in the queue		
        for(GroupMember gm: [Select Id,Group.DeveloperName,UserOrGroupId,Group.Type from GroupMember where GroupId in :publicGroups]){
            //check if the current user matches with the group members 
			if(gm.UserOrGroupId == UserInfo.getUserId()){
				display = true;
				return gDevName;
			}
		}
		return null;
	}
    
    //Save work item
    //there are different combinational scenarios to consider before saving work items
    //IF conditions that you see below represents combination of different scenarios
    //you can find the excel sheet inthe story with the different combinations and what needs to be done on save 
    //the combination includes the user belongs to which team & what outcomes are recorded 
	public PageReference save(){
        SavePoint sp;
		List<String> queue = new List<String>{'LBU_Escalation_Queue','CC_Escalation_Queue','CC_Admin_Team_Queue','Supplier_Management_Advisers_Queue','Managers_Escalation_Queue','Unallocated_Phone_Work_Items'};
		Map<String,Id> queueMap = new Map<String,Id>();
        String decisionNextStep =workItem.Decision__c+''+workItem.Next_Step__c;
        String escalatedReason = workItem.Escalation_Reason__c;
		Boolean updateResp = false;
		System_Update__c su = System_Update__c.getOrgDefaults();
        try{
            sp = Database.setSavepoint();
            su.Execute__c = true;
            update su;
            for(Group gr: [Select Id,DeveloperName from Group where Type = 'Queue' and DeveloperName in :queue]){
                queueMap.put(gr.DeveloperName,gr.Id);
            }
            
            Response__c resp = new Response__c(Id=workItem.Response__c);
			if(workItem.Escalation_Reason__c.equalsIgnoreCase('Extension (Beyond Extension Cut-off Date)') && workItem.Decision__c.equalsIgnoreCase('Approved')){
				
				if( workItem.Requested_Extension_Date__c == null){
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Work item does not have a requested extension date set'));
					return null;
				}
				if(workItem.New_Call_Back_Time__c.date() < workItem.Requested_Extension_Date__c.addDays(1)){
					ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call back date must be next day of Extension Date'));
					return null;
				}
                resp.Extension_Date__c = workItem.Requested_Extension_Date__c;
				
				if(resp.Extension_Date__c > workItem.response__r.Collection_Instance__r.Extension_Cut_off_Date__c && !resp.Extension_Past_Cut_Off__c )
				{	
					resp.Extension_Past_Cut_Off__c = true;
					System.debug('updated past cut off flag');
				}
				updateResp = true;
            }
            
            if(nextStepMap.containsKey(decisionNextStep.trim())){
                if(nextStepMap.get(decisionNextStep.trim()).Call_back__c){
					if(workItem.New_Call_Back_Time__c < System.now()){
						ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call back time must be in future'));
						return null;
					}
                    workItem.call_Back_Time__c = workItem.New_Call_Back_Time__c;
                }
                if(nextStepMap.get(decisionNextStep.trim()).Extension__c){
					if( workItem.Response__r.Extension_Date__c < System.today()){
						ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension date must be in future'));
						return null;
					}
                    resp.Extension_Date__c = workItem.Response__r.Extension_Date__c;
                    updateResp = true;
                }
                if(String.isNotBlank(nextStepMap.get(decisionNextStep.trim()).Response_Status__c)){
                    updateResp = true;
                    resp.Status__c = nextStepMap.get(decisionNextStep.trim()).Response_Status__c;
                }
                
                if(String.isNotBlank(nextStepMap.get(decisionNextStep.trim()).Response_Status_Reason__c)){
                    updateResp = true;
                    resp.Response_Status_Reason__c = nextStepMap.get(decisionNextStep.trim()).Response_Status_Reason__c;
                }
                
                if(String.isNotBlank(nextStepMap.get(decisionNextStep.trim()).Assign_to__c) && queueMap.containsKey(nextStepMap.get(decisionNextStep.trim()).Assign_to__c)){
                    workItem.OwnerId = queueMap.get(nextStepMap.get(decisionNextStep.trim()).Assign_to__c);
					workItem.Queue_Id__c = queueMap.get(nextStepMap.get(decisionNextStep.trim()).Assign_to__c);
                }
                
                if(String.isNotBlank(nextStepMap.get(decisionNextStep.trim()).Status__c)){
                    workItem.Status__c = nextStepMap.get(decisionNextStep.trim()).Status__c;
                }

				if((String.isNotBlank(nextStepMap.get(decisionNextStep.trim()).Assign_to__c) && nextStepMap.get(decisionNextStep.trim()).Assign_to__c.equalsIgnoreCase('Unallocated_Phone_Work_Items')) || workItem.Decision__c.equalsIgnoreCase('Referred to CSR for follow-up')){
                    workItem.Escalated__c = false;
                    //When a Team Lead resolved the escalation, the Escalated is being unticked 
                    //but the Escalation reason field is to be cleared and CSR should not receives an error message when trying to record an outcome. ECP-3650                   
                    workItem.Escalation_Reason__c = '';
					workItem.Approval_Status__c = null;
				}
                //selecting any Decision and/or Next Steps that are effectively "Schedule Follow-up", the Follow-up tick-box has to be ticked.ECP-3650
                if(String.isNotBlank(workItem.Decision__c) && String.isNotBlank(workItem.Next_Step__c) && workItem.Next_Step__c.equalsIgnoreCase('Schedule Follow-Up')){
                    workItem.Escalated__c = false;                  
                    workItem.Follow_up__c = true;                   
                    workItem.Escalation_Reason__c = '';
					workItem.Approval_Status__c = null;  
				}               
            }
            update workItem;
            taskObj.Status = 'Completed';
			if(String.isNotBlank(workItem.Next_Step__c)){taskObj.Subject = workItem.Decision__c+'-'+workItem.Next_Step__c;}
            else taskObj.Subject = workItem.Decision__c;
            taskObj.WhatId = workItem.Id;
            taskObj.New_Call_Back_Time__c = workItem.New_Call_Back_Time__c;
            taskObj.Decision__c = workItem.Decision__c;
            //escalation reason should be captured form workitem while creating a task, Since it has to be cleared for ECP-3650, we are storing in a string and used in below line - ECP-3540
            taskObj.Escalation_Reason__c = escalatedReason;
            taskObj.Next_Step__c = workItem.Next_Step__c;
            insert taskObj;
            if(updateResp){update resp;}            
            su.Execute__c = false;
            update su;
            return new PageReference('/'+workItem.Id);
        }catch(exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
			Database.rollback(sp);
			return null;
        }
	}
}