public class TaskTriggerHandler {
    public static Boolean isProcessed=false;
/* brain logic moved to ProcessBuilder
    public void calculateWorkflowStatus(Task[] ins) {
        // collate the set of work-item id
        set<id> wiIds = new set<Id> ();
        for (Task t : ins) {
            if (t.whatid != null && t.whatid.getSobjectType() == Schema.Work_Item__c.SObjectType) {
                wiIds.add(t.WhatId);
            }
        }
        //reuse existing logic to calculate st
        if (!wiIds.isEmpty()) {
            WorkItemTriggerHandler.setResponseWorkflowStatus(wiIds);
        }
    }
*/

    public void associate_Response_Unit_Contact(Task[] ins) {
        // collate the set of work-item id
        set<id> wiIds = new set<Id> (), caseIds = new set<Id> ();
        List<Task> tsList = new List<Task> ();
        for (Task t : ins) {
            // if the who id is a contact, copy it to another field for reports
            if(t.whoid!=null&&t.whoid.getSobjectType() == Schema.Contact.SObjectType){
                t.System_Contact__c=t.whoid;
            }
            if (t.whatid == null) { continue; }
            if (t.whatid.getSobjectType() == Schema.Work_Item__c.SObjectType) {
                wiIds.add(t.WhatId);
                tsList.add(t);
            } else if (t.whatid.getSobjectType() == Schema.Case.SObjectType) {
                caseIds.add(t.whatid);
                tsList.add(t);
            }
        }
        if (!wiIds.isEmpty()) {
            Map<Id, Work_Item__c> wiMap = new Map<Id, Work_Item__c> ([
                Select Id, Response__c, Response__r.Recordtype.Name, Response__r.Unit_of_Interest__c, Response__r.Unit_of_Interest__r.Name, 
                    Response__r.Survey_Unit__c, Response__r.Survey_Unit__r.Unit_of_Interest_ID__c, Response__r.Survey_Unit__r.Name 
                from Work_Item__c where Id in :wiIds]);
            for (Task ts : tsList) {
                if (wiMap.containsKey(ts.WhatId) && wiMap.get(ts.WhatId).Response__c != NULL 
                    && ( wiMap.get(ts.WhatId).Response__r.Recordtype.Name == 'Census Dwelling' ||
                        wiMap.get(ts.WhatId).Response__r.Recordtype.Name == 'Business Response')) {
                    
                    ts.Response__c = wiMap.get(ts.WhatId).Response__c;
                    ts.Survey_Unit_ID__c = wiMap.get(ts.WhatId).Response__r.Survey_Unit__r.Unit_of_Interest_ID__c;
                    ts.Survey_Unit__c = wiMap.get(ts.WhatId).Response__r.Survey_Unit__r.Name;
                    ts.Collection_Unit__c = wiMap.get(ts.WhatId).Response__r.Unit_of_Interest__c;
                }
            }
        }
        if (!caseIds.isEmpty()) {
            Map<Id, Case> caseMap = new Map<Id, Case> ([
                Select Id, Response__c, Response__r.Recordtype.Name, Response__r.Unit_of_Interest__c, Response__r.Unit_of_Interest__r.Name, 
                    Response__r.Survey_Unit__c, Response__r.Survey_Unit__r.Unit_of_Interest_ID__c, Response__r.Survey_Unit__r.Name
                from Case where Id in :caseIds]);
            for (Task ts : tsList) {
                if (caseMap.containsKey(ts.WhatId) && caseMap.get(ts.WhatId).Response__c != NULL 
                    && ( caseMap.get(ts.WhatId).Response__r.Recordtype.Name == 'Census Dwelling' ||
                        caseMap.get(ts.WhatId).Response__r.Recordtype.Name == 'Business Response') ) {
                    
                    ts.Response__c = caseMap.get(ts.WhatId).Response__c;
                    ts.Survey_Unit_ID__c = caseMap.get(ts.WhatId).Response__r.Survey_Unit__r.Unit_of_Interest_ID__c;
                    ts.Survey_Unit__c = caseMap.get(ts.WhatId).Response__r.Survey_Unit__r.Name;
                    ts.Collection_Unit__c = caseMap.get(ts.WhatId).Response__r.Unit_of_Interest__c;
                    ts.whatid = caseMap.get(ts.WhatId).Response__c;
                }
            }
        }
    }

    //@author: Ramu Veligeti
    //Date: 14/03/2015
    //ECP-2298
    //To add notes on Work Item from last 3 comments of the Task 
    public void updateWINotes(List<Task> newTasks) {
        Set<Id> wIds = new Set<Id> ();
        for (Task ts : newTasks) {
            if (ts.Outcome__c != NULL && ts.whatid.getSobjectType() == Schema.Work_Item__c.SObjectType) {
                wIds.add(ts.WhatId);
            }
        }

        if (wIds.isEmpty()) { return; }

        List<Work_Item__c> wi = [Select Id,Notes__c, (Select Id,Description,CreatedBy.Name,createdDate from Tasks where Outcome__c != NULL Order by LastModifiedDate desc) from Work_Item__c where Id in :wIds];

        for (Work_Item__c w: wi){
            String notes;
            Integer i=0;
            for (Task t: w.Tasks){
                if (t.Description == NULL){ continue; }
                i++;
                if(i >5){break;}
                if (notes == NULL){ notes = formatNotesFromComments(t);} 
                else { notes += formatNotesFromComments(t); }
            }
            if (notes != NULL){ w.Notes__c = notes; }
        }
        update wi;
    }

    private String formatNotesFromComments(Task ts){
        String st;
        st = ts.CreatedBy.Name+' '+ts.CreatedDate.format('dd-MM-yyyy HH:mm:ss')+' :-';
        st+='\n';
        st+='\n';
        st+=ts.description;
        st+='\n';
        st+='________________________________________________________________________________';
        st+='\n';
        st+='\n';
        return st;
    }

    //author:Ram Veligeti
    //Story:ECP-2923
    //this method is called when recorded outcomes on an escalated task. If there are multi work items created as part of bulk record outcomes
    //then this method will update all the related tasks outcomes as well. If the task is escalated to Managers then a follow up task
    //would be created and existing task will be closed
    public void beforeUpdate_feedbackEscalationOutcome(List<Task> newTasks, Map<Id,Task> oldTasks){
        if(TaskTriggerHandler.isProcessed) return;
        List<Task> tasks = new List<Task>();
        Set<String> multiEscFeedbackIds = new Set<String>();
        Map<String,Task> taskMap = new Map<String,Task>();
        Set<Id> processedTaskIds = new Set<Id>();
        Map<String,Task> followupTaskMap = new Map<String,Task>();
        Map<String,String> extIdMap = new Map<String,String>();
        for(Task ts: newTasks){
            if(String.isNotBlank(ts.Decision__c) && (oldTasks.get(ts.Id).Decision__c == null || (oldTasks.get(ts.Id).Decision__c != null && oldTasks.get(ts.Id).Decision__c <> ts.Decision__c))){
                if(String.isNotBlank(ts.Multi_Escalate_Feedback_Id__c)){
                    multiEscFeedbackIds.add(ts.Multi_Escalate_Feedback_Id__c);
                    taskMap.put(ts.Multi_Escalate_Feedback_Id__c,ts);
                    processedTaskIds.add(ts.Id);
                }
                if(ts.Decision__c.equalsIgnoreCase('Unresolved') && String.isNotBlank(ts.Next_Step__c) && !ts.Next_Step__c.equalsIgnoreCase('No further action required')){
                    task t = createTask(ts);
                    t.Primary_Task__c = true;
                    t.Multi_Escalate_Feedback_Id__c = ApexUtility.GUID();
                    tasks.add(t);
                    if(String.isNotBlank(ts.Multi_Escalate_Feedback_Id__c)){
	                    extIdMap.put(ts.Multi_Escalate_Feedback_Id__c,t.Multi_Escalate_Feedback_Id__c);
                        followupTaskMap.put(ts.Multi_Escalate_Feedback_Id__c,ts);
                    }
                }
                ts.Status = 'Completed';
                TaskTriggerHandler.isProcessed = true;  
            }
        }
        if(!multiEscFeedbackIds.isEmpty()){
            List<Task> tsList = [Select Id,WhatId,WhoId,Escalation_Reason__c,Feedback_Type__c,Decision__c,Next_Step__c,Multi_Escalate_Feedback_Id__c,Description from Task where Multi_Escalate_Feedback_Id__c in :multiEscFeedbackIds and Id not in :processedTaskIds];
            for(Task ts:tsList){
                ts.Decision__c = taskMap.get(ts.Multi_Escalate_Feedback_Id__c).Decision__c;
                ts.Next_Step__c = taskMap.get(ts.Multi_Escalate_Feedback_Id__c).Next_Step__c;
                ts.Description = taskMap.get(ts.Multi_Escalate_Feedback_Id__c).Description;
                ts.Primary_Task__c = false;
                ts.Status = 'Completed';
                if(followupTaskMap.containsKey(ts.Multi_Escalate_Feedback_Id__c)){
                    task nts = createTask(ts);
                    nts.Multi_Escalate_Feedback_Id__c = extIdMap.get(ts.Multi_Escalate_Feedback_Id__c);
	                tasks.add(nts);
                }
            }
            if(!tsList.isEmpty()){tasks.addAll(tsList);}
        }
        if(!tasks.isEmpty()){upsert tasks;}
    }
    
    public Task createTask(task ts){
        Task t = new Task();
        t.Subject =  'Escalate-'+ts.Decision__c+'-'+ts.Next_Step__c;
        t.Escalated__c = true;
        t.Escalated_by__c = UserInfo.getUserId();
        t.Feedback_Type__c = ts.Feedback_Type__c;
        t.Escalation_Reason__c = ts.Escalation_Reason__c;
        t.Status = 'Open';
        t.WhatId = ts.WhatId;
        t.WhoId = ts.WhoId;
        return t;
    }
}