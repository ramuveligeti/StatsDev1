/**
* @description This class used to Prioritize work item 
* @author Ram Veligeti
* @date 16.Sep.2015
*/
public class WorkItemQueue {
    private static Map<Id,Set<String>> collectionSkillMap = new Map<Id,Set<String>>();
    private static Map<Id,Set<String>> focusCollectionSkillMap = new Map<Id,Set<String>>();
    private static Datetime currentDatetime = system.now();
    private static Id ownerId = userInfo.getUserId();
    private static Id queueId;
	private static Set<String> skills = new Set<String>();

    public static String fetchWorkItem(){
        List<Work_Item__c> workItem = new List<Work_Item__c>();
        String wId;
        //Any existing In Progress work items
        workItem = [Select Id,Response__r.Contact__c,Response__c,Response__r.Unit_of_Interest__c from Work_Item__c where Status__c='In Progress' and Delivery_Mode__c = 'Call' and ownerId = :ownerId order by Call_Back_Time__c limit 1];
        if(!workItem.isEmpty()){
            lockContactAndUnit(workItem[0].Response__r.Contact__c,workItem[0].Response__r.Unit_of_Interest__c);
            return workItem[0].Id;
        }
        
        currentDatetime = system.now();
        //Priority 1: Assigned Scheduled Work Items
        workItem = Database.query(workItemString('','and Call_Back_Time__c!=NULL and Call_Back_Time__c <= :currentDatetime and ownerId = :ownerId','Call_Back_Time__c'));
        if(!workItem.isEmpty()){
            wId = updateWorkItem(workItem[0]);
            if(wId != NULL){return wId;}
        }
        
        //Priority 2: Assigned Work Items
        workItem = Database.query(workItemString('','and Call_Back_Time__c=NULL and ownerId = :ownerId','createdDate'));
        if(!workItem.isEmpty()){
            wId = updateWorkItem(workItem[0]);
            if(wId != NULL){return wId;}
        }
        
        if(Label.Work_Item_Priority_Skills.contains(',')){
            skills.addAll(Label.Work_Item_Priority_Skills.split(','));
        } else {
            skills.add(Label.Work_Item_Priority_Skills);
        }
        //Skillset based
        List<Skillset__c> userSkillsets = [Select   Id, Collection__c, Skill__c, Focus_Start_Date__c, Focus_End_Date__c 
                                           from     Skillset__c 
                                           where    User_Name__c = :UserInfo.getUserId()
                                           and      Training_Completion_Date__c <= :system.now()
                                           and      Skill__c in :skills];
        if(userSkillsets.isEmpty()){
            Throw new FormValidationException('No matching skillsets found. Please contact your Team Lead.');
        }
        
        for(Skillset__c skillset: userSkillsets){
            if(skillset.Focus_Start_Date__c != NULL && skillset.Focus_End_Date__c != NULL && skillset.Focus_Start_Date__c <= system.now() && skillset.Focus_End_Date__c >= system.now()){
                if(focusCollectionSkillMap.containsKey(skillset.Collection__c)){
                    focusCollectionSkillMap.get(skillset.Collection__c).add(skillset.Skill__c);
                } else {
                    focusCollectionSkillMap.put(skillset.Collection__c, new Set<String>{skillset.Skill__c});
                }
            } else {
                if(collectionSkillMap.containsKey(skillset.Collection__c)){
                    collectionSkillMap.get(skillset.Collection__c).add(skillset.Skill__c);
                } else {
                    collectionSkillMap.put(skillset.Collection__c, new Set<String>{skillset.Skill__c});
                }
            }
        }
        
        Work_Item__c wi = queryWorkItem();
        if(wi == NULL){Throw new FormValidationException('No Work Items found. Please contact your Team Lead.');}
        else {
			wId = updateWorkItem(wi);
			while(wId == null && wi != null){
				wi = queryWorkItem();
				if(wi != null){wId = updateWorkItem(wi);}
			}
			if(wId != NULL){return wId;}
			else{Throw new FormValidationException('System could not fetch work item due to load. Please try again.');}
		} 
    }
    
    private static String updateWorkItem(Work_Item__c wi){
        List<Work_Item__c> wiList = [Select Id,Status__c,OwnerId,Response__r.Contact__c,Response__c,Response__r.Unit_of_Interest__c 
                                     from Work_Item__c 
                                     where Id = :wi.Id 
                                     and Response__r.Contact__r.Assigned__c = false 
                                     and Response__r.Unit_of_Interest__r.Assigned__c = false FOR UPDATE];
        if(wiList.isEmpty()){return null;}
        wiList[0].Status__c = 'In Progress'; 
        wiList[0].OwnerId = userInfo.getUserId();

        lockContactAndUnit(wiList[0].Response__r.Contact__c,wiList[0].Response__r.Unit_of_Interest__c);
        update wiList[0];
        return wiList[0].Id;
    }
    
    private static void lockContactAndUnit(Id contactId,Id unitId){
        try{
			if(contactId != NULL){
				Contact ct = [Select Id,Assigned__c from Contact where Id = :contactId FOR UPDATE];
				ct.Assigned__c = true;
				update ct;
			}
        
			if(unitId != NULL){
				Unit__c unit = [Select Id,Assigned__c from Unit__c where Id = :unitId FOR UPDATE];
				unit.Assigned__c = true;
				update unit;
			}
		}catch(exception e){system.debug('Contact and Unit locked');}
    }
    
    private static Work_Item__c queryWorkItem(){
        List<Work_Item__c> workItem = new List<Work_Item__c>();
        queueId = [Select Id from Group where Type = 'Queue' and DeveloperName = 'Unallocated_Phone_Work_Items'].Id;
        
        //Priority 3: Appointment Work Items for Focused Skills
        if(!focusCollectionSkillMap.isEmpty()){
            system.debug('www=='+workItemString(getSkillQueryString(focusCollectionSkillMap),'and Appointment__c = true and ownerId = \''+queueId+'\' and Call_Back_Time__c <= :currentDatetime','Call_Back_Time__c ASC NULLS LAST, WI_Priority__c DESC, createdDate ASC'));
            workItem = Database.query(workItemString(getSkillQueryString(focusCollectionSkillMap),'and Appointment__c = true and ownerId = \''+queueId+'\' and Call_Back_Time__c <= :currentDatetime','Call_Back_Time__c ASC NULLS LAST, WI_Priority__c DESC, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }
        
        //Priority 4: Appointment Work Items for Non-Focused Skills
        if(!collectionSkillMap.isEmpty()){
            workItem = Database.query(workItemString(getSkillQueryString(collectionSkillMap),'and Appointment__c = true and ownerId = \''+queueId+'\' and Call_Back_Time__c <= :currentDatetime','Call_Back_Time__c ASC NULLS LAST, WI_Priority__c DESC, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }

        //Priority 5: Follow-up Work Items for Focused Skills
        if(!focusCollectionSkillMap.isEmpty()){
            workItem = Database.query(workItemString(getSkillQueryString(focusCollectionSkillMap),'and Follow_up__c = true and ownerId = \''+queueId+'\' and Call_Back_Time__c <= :currentDatetime','Call_Back_Time__c ASC NULLS LAST, WI_Priority__c DESC, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }
        
        //Priority 6: Follow-up Work Items for Non-Focused Skills
        if(!collectionSkillMap.isEmpty()){
            workItem = Database.query(workItemString(getSkillQueryString(collectionSkillMap),'and Follow_up__c = true and ownerId = \''+queueId+'\' and Call_Back_Time__c <= :currentDatetime','Call_Back_Time__c ASC NULLS LAST, WI_Priority__c DESC, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }
        
        //Priority 7: Focused Collections with Priority
        if(!focusCollectionSkillMap.isEmpty()){
            workItem = Database.query(workItemString(getSkillQueryString(focusCollectionSkillMap),'and Appointment__c = false and Follow_up__c = false and ownerId = \''+queueId+'\'','WI_Priority__c DESC NULLS LAST, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }
        
        //Priority 8: Non-Focused Collections with Priority
        if(!collectionSkillMap.isEmpty()){
            workItem = Database.query(workItemString(getSkillQueryString(collectionSkillMap),'and Appointment__c = false and Follow_up__c = false and ownerId = \''+queueId+'\'','WI_Priority__c DESC NULLS LAST, createdDate ASC'));
            if(!workItem.isEmpty()){return workItem[0];}
        }
        return null;
    }
    
    //Skills- Phone, Key, LBU
    //Phone - Work Item Delivery Mode = Call
    //Key - Work Item's Response's Key = true
    //LBU - WOrk Item's Response's Unit's LBU = true
    private static String getSkillQueryString(Map<Id,Set<String>> skillMap){
        String skillQueryString;
        for(Id colId: skillMap.keySet()){
            String skillQuery;
			Set<String> csrSkills = skillMap.get(colId);
			Set<String> phoneKeySkills = new Set<String>{'Phone','Key'};
			Set<String> phoneLBUSkills = new Set<String>{'Phone','LBU'};
			Set<String> keyLBUSkills = new Set<String>{'Key','LBU'};

			if(csrSkills.equals(skills)){
				skillQuery = 'Delivery_Mode__c = \'Call\'';
			}else if(csrSkills.equals(phoneKeySkills)){
				skillQuery = 'Response__r.Unit_of_Interest__r.LBU__c = false';
			}else if(csrSkills.equals(phoneLBUSkills)){
				skillQuery = 'Response__r.Key__c = false or (Response__r.Key__c = true and Response__r.Unit_of_Interest__r.LBU__c = true)';
			}else if(csrSkills.equals(keyLBUSkills)){
				skillQuery = '(Response__r.Unit_of_Interest__r.LBU__c = true or Response__r.Key__c = true)';
			}else if(csrSkills.equals(new Set<String>{'Phone'})){
				skillQuery = 'Response__r.Unit_of_Interest__r.LBU__c = false and Response__r.Key__c = false';
			}else if(csrSkills.equals(new Set<String>{'Key'})){
				skillQuery = 'Response__r.Key__c = true and Response__r.Unit_of_Interest__r.LBU__c = false';
			}else if(csrSkills.equals(new Set<String>{'LBU'})){
				skillQuery = 'Response__r.Unit_of_Interest__r.LBU__c = true';
			}
            
            if(String.isNotBlank(skillQuery)){
                if(String.isNotBlank(skillQueryString)){skillQueryString += ' or (Response__r.Collection_Instance__r.Collection__c = \''+colId+'\' and (';}
                else{skillQueryString = '(Response__r.Collection_Instance__r.Collection__c = \''+colId+'\' and (';}
                
                skillQueryString += skillQuery+'))';
            }
        }
        return String.isBlank(skillQueryString)?'':' and ('+skillQueryString+')';
    }
    
    private static String workItemString(String skillQueryString,String additionalWhereClause,String orderBy){
        return 'Select Id, WI_Priority__c, Response__r.Contact__c, Response__r.Contact__r.Assigned__c, Response__c, Response__r.Unit_of_Interest__c, Response__r.Unit_of_Interest__r.Assigned__c from Work_Item__c where (Status__c = \'New\' or Status__c = \'Pending\') and Delivery_Mode__c = \'Call\' and Response__r.RecordType.Name = \'Business Response\' and Response__r.Contact__r.Assigned__c = false and Response__r.Unit_of_Interest__c != NULL and Response__r.Unit_of_Interest__r.Assigned__c = false '+skillQueryString+' '+additionalWhereClause+' order by '+orderBy+',Name ASC limit 1';
    }
}