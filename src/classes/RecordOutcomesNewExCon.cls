/**
* @description This is an Extension controller for RecordOutcomesNew VF Page
               Outcomes are captured by CSR based on the result of a call. All the outcome actions are captured as Tasks on the workitem.
               If the outcome is escalation it will be assigned to a queue based on various parameters
               Please look in to stories ECP-2298,2375 for more info
* @author Ram Veligeti
* @date 17.Sep.2015
*/
public class RecordOutcomesNewExCon {
    public Work_Item__c workItem{get;set;}
    public Work_Item__c wi{get;set;}
    public List<SelectOption> outcomes{get;set;}
    public String newWorkItemOutcomes = 'Advised Data Sent,Scheduled Appointment,Scheduled Follow-up';//Advised Data Sent,
    public String adminEscalations = 'Business Structural Changes,AOS Change of Ownership';
    public String rmaEscalations = 'Feedback';
    public String completeWIOutcomes = 'Call Successful,Cannot Locate a Number,Data Taken Over The Phone - PDF/Paper,Data Taken Over The Phone - Online,Sent Replacement Questionnaire,Advised Data Sent,No Further Action Required';
    public String pendingWIOutcomes = 'Scheduled Appointment,Scheduled Follow-up,Escalated,Sent Replacement Questionnaire,Advised Data Sent,Online Survey Technical Enquiry';
    public String setExtensionDateWorkItemTypes = 'Non-response follow-up,Courtesy contact';
    public String setExtensionDateOutcomes = 'Sent Replacement Questionnaire,Scheduled Follow-up,No Further Action Required,Online Survey Technical Enquiry';
    public String dataTakenOverPhoneOutcomes = 'Data Taken Over The Phone - PDF/Paper,Data Taken Over The Phone - Online';
    public Boolean callBackRendered{get;set;}
    public Boolean callBackRequired{get;set;}
    public Boolean escalationRequired{get;set;}
    public Boolean extensionRequired{get;set;}
    public Boolean displayRO{get;set;}
    public Boolean renderExtesionDate{get;set;}
    public Boolean partialData{get;set;}
    public Boolean displayPartialData{get;set;}
    public Task taskObj{get;set;}
    public String contactNotes{get;Set;}
    public Boolean refreshParentTab{get;Set;}
    static final String ESCALATED =  'Escalated';

    public List<Work_Item__c> workItemsRelatedToContact{get;set;}
    public List<Work_Item__c> workItemsRelatedToCollectionUnit{get;set;}
    public List<WorkItemWrapper> contactsWrapper{get;set;}
    public List<WorkItemWrapper> collectionUnitsWrapper{get;Set;}
    //public List<WorkItemWrapper> selectedContactsWrapper{get;set;}
    //public List<WorkItemWrapper> selectedCollectionUnitsWrapper{get;Set;}
    public Work_Item__c[] selectedWorkItems{get;set;}
    public Boolean display{get;set;}
    public Boolean display1{get;Set;}
    public static Set<Id> selectedWIContacts;
    public static Set<Id> selectedWICollectionUnits;
    public Boolean includeParentWorkItem{get;Set;}
	public Id businessRecordTypeId = Work_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business').getRecordTypeId();
    
    //Standard controller
    //Since we are using same controller for differenct pages, we have to make sure that when this controller is called it should not fire all the 
    //functionality for all the pages. This Controller is called from WorkItemsGroupedBy,BulkRecordOutcomes,BulkInteractionLog,RecordOutcomesNew VF pages.
    //using redirect parameter to check if this is being called from WorkItemsGroupedBy page. If Redirect is null then it is coming from WorkItemsGroupedBy page
    //From other pages we are passing different redirect parameters. Eg: BulkInteractionLog Page - bulkInteraction
    public RecordOutcomesNewExCon(ApexPages.StandardController stdCont){
        String redirect = ApexPages.currentPage().getParameters().get('redirect');
        workItem = (Work_Item__c)stdCont.getRecord();
        taskObj = new Task();

        //BulkInteractionLog Page
        if(redirect=='bulkInteraction'){return;}

        system.debug('redirect=='+redirect);
        contactsWrapper = new List<WorkItemWrapper>();
        collectionUnitsWrapper = new List<WorkItemWrapper>();
        selectedWorkItems = new Work_Item__c[]{};
        refreshParentTab = true;
        
        //set includeParentWorkitem to true so primary work item is selected by default
        includeParentWorkItem = true;
        
        //WorkItemGroupedBy Page
        if(redirect==null && workItem.recordTypeId == businessRecordTypeId){
            //Neha added condition for story 2659
            List<String> queue=null;
            if(workItem.Work_Item_Type__c=='Tick - Complaints'){
                queue = new List<String>{'Tick_Complaints'};
                }else{
            		queue = new List<String>{'Unallocated_Phone_Work_Items'};
                }
            Map<Id,String> queueMap = new Map<Id,String>();
                        
            for(Group q: [Select Id,DeveloperName from Group where DeveloperName in :queue and Type = 'Queue']){
                queueMap.put(q.Id,q.DeveloperName);
            }
            //Query work items for contact
            workItemsRelatedToContact = [Select Id,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c,Unit__c, Outcome__c,Escalated__c 
                                         from Work_Item__c where Delivery_Mode__c = 'Call' and Contact__c != null and Status__c in ('New','Pending')
                                         and Response__r.RecordType.Name = 'Business Response' and Contact__c = :workItem.Contact__c and Id <> :workItem.Id 
                                         and ownerId in :queueMap.keySet()];
            if(!workItemsRelatedToContact.isEmpty()){
                display = true;
                for(Work_Item__c w : workItemsRelatedToContact){
                    contactsWrapper.add(new WorkItemWrapper(w));
                }
            }
            //Query work items for collection unit
            workItemsRelatedToCollectionUnit = [Select Id,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c,Unit__c,Outcome__c,Escalated__c 
                                                from Work_Item__c where Delivery_Mode__c = 'Call' and Unit__c != null and Status__c in ('New','Pending')
                                                and Response__r.RecordType.Name = 'Business Response' and Unit__c = :workItem.Unit__c and Id <> :workItem.Id 
                                                and Id not in :workItemsRelatedToContact and ownerId in :queueMap.keySet()];
            
            if(!workItemsRelatedToCollectionUnit.isEmpty()){
                display1 = true;
                for(Work_Item__c w : workItemsRelatedToCollectionUnit){
                    collectionUnitsWrapper.add(new WorkItemWrapper(w));
                }
            }
        }

        wi = new Work_Item__c();
        if (workItem.Contact__c!=NULL){
            wi.Contact__c = workItem.Contact__c;
            contactNotes = workItem.Contact__r.Notes__c;
        }
        if(!String.isBlank(workItem.Approval_Status__c)  && workItem.Approval_Status__c.containsIgnoreCase('Pending Approval')){
            displayRO = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Awaiting for Approval.You cannot record outcomes.'));
            return;
        }
        displayRO = true;
        getOutcomes();
    }

    //Outcomes picklist is formed based on workitem's delivery mode and work item type
    //These values are stored in 'Record outcomes' custom setting
    public void getOutcomes(){
        outcomes = new List<SelectOption>();
        List<Record_Outcomes__c> outcome = [Select Id,Outcomes__c from Record_Outcomes__c where Delivery_Mode__c = :workItem.Delivery_Mode__c and Work_Item_Type__c = :workItem.Work_Item_Type__c];

        if(outcome.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Custom Settings not defined for the Delivery Mode:'+workItem.Delivery_Mode__c+' and Work Item Type:'+workItem.Work_Item_Type__c+'. Please contact your System Administrator.'));
            displayRO = false;
            return;
        }

        outcomes.add(new SelectOption('','--None--'));
        if(outcome[0].Outcomes__c.contains(',')){
            for(String st: outcome[0].Outcomes__c.split(',')){
                outcomes.add(new SelectOption(st,st));
            }
        } else if(outcome[0].Outcomes__c != NULL){
            outcomes.add(new SelectOption(outcome[0].Outcomes__c,outcome[0].Outcomes__c));
        }
    }

    //Based on the selected outcomes the actions will take place
    //Few outcomes need further information to capture, the below method enables those fields based on outcome
    public void setCallback(){
        callBackRequired = false;
        callBackRendered = false;
        escalationRequired = false;
        displayPartialData = false;
        renderExtesionDate = false;
        taskObj.Escalation_Reason__c = NULL;
        taskObj.New_Call_Back_Time__c = NULL;
        workItem.Response__r.Extension_Date__c = NULL;

        if(String.isBlank(taskObj.Outcome__c)){
            escalationRequired = false;
            callBackRequired = false;
            callBackRendered = false;
            return;
        }

        if(newWorkItemOutcomes.containsIgnoreCase(taskObj.Outcome__c)){
            callBackRequired = true;
            callBackRendered = true;
            escalationRequired = false;
        }

        if(dataTakenOverPhoneOutcomes.containsIgnoreCase(taskObj.Outcome__c)){//.containsIgnoreCase('Data Taken Over The Phone')){
            displayPartialData = true;
            callBackRequired = false;
            callBackRendered = true;
        }

        if((workItem.Work_Item_Type__c.equalsIgnoreCase('Non-response follow-up') || workItem.Work_Item_Type__c.equalsIgnoreCase('Inbound Enquiry')) && taskObj.Outcome__c.equalsIgnoreCase('Sent Replacement Questionnaire')){
            if (workItem.Response_Extension_Date__c != NULL){
        
                taskObj.New_Call_Back_Time__c = Datetime.newInstance(workItem.Response_Extension_Date__c.addDays(1), Time.newInstance(0, 0, 0, 0));
            }
            callBackRequired = true;
            callBackRendered = true;
            escalationRequired = false;
            renderExtesionDate = true;
        }

        if(workItem.Work_Item_Type__c.equalsIgnoreCase('Courtesy contact') && taskObj.Outcome__c.equalsIgnoreCase('Sent Replacement Questionnaire')){
        
            renderExtesionDate = true;
            callBackRequired = false;
            callBackRendered = false;
            escalationRequired = false;
        }

		

        if(taskObj.Outcome__c.containsIgnoreCase('Advised Data Sent') && (workItem.Work_Item_Type__c.equalsIgnoreCase('Non-response follow-up') || workItem.Work_Item_Type__c.equalsIgnoreCase('Inbound Enquiry'))){
            taskObj.New_Call_Back_Time__c = system.now().addDays(4);
        }
		
        //if inbound enquiry work item type and outcome is no futher action required, need to be able to set an extension date
		if( workItem.Work_Item_Type__c.equalsIgnoreCase('Inbound Enquiry') && taskObj.Outcome__c.equalsIgnoreCase('No further action required'))
		{
			renderExtesionDate = true;
          
		}
        
        if(taskObj.Outcome__c.containsIgnoreCase('Escalated')){
            escalationRequired = true;
            callBackRequired = false;
            callBackRendered = false;
        }

        if(taskObj.Outcome__c.containsIgnoreCase('Scheduled Follow-up')){
            extensionRequired=false;
            renderExtesionDate = true;
            if(workItem.Response_Extension_Date__c != NULL){
                
                taskObj.New_Call_Back_Time__c = Datetime.newInstance(workItem.Response_Extension_Date__c.addDays(1), Time.newInstance(0, 0, 0, 0));
            }
        }

		if(taskObj.Outcome__c.containsIgnoreCase('Online Survey Technical Enquiry')){
            
			taskObj.New_Call_Back_Time__c = Datetime.now().addHours(1);
            callBackRequired = true;
            callBackRendered = true;
            escalationRequired = false;
            renderExtesionDate = true;
        }
    }

    //If escalated, and the reason for esacalation is 'Extension' then extension date need to be set
    public void setExtensionDate(){
        if(taskObj.Outcome__c.containsIgnoreCase('Escalated')){
            escalationRequired = true;
            callBackRequired = false;
            extensionRequired = false;
            renderExtesionDate = false;

            if(taskObj.Escalation_Reason__c.containsIgnoreCase('Extension')){
                extensionRequired = true;
                renderExtesionDate = true;
                workItem.Response__r.Extension_Date__c = workItem.Response_Extension_Date__c;
            }
        }
    }

    //If the contact is changed then fetch the notes of the contact
    public void fetchContactNotes(){
        if (wi.Contact__c != NULL){
            contactNotes = [Select Notes__c from Contact where Id = :wi.Contact__c].Notes__c;
        }else{
            contactNotes = null;
        }
    }

    //Page validations for Recordoutcomes
    public Boolean validations(){
        if(String.isBlank(taskObj.Outcome__c)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Outcome cannot be null'));
            return false;
        }

        if(dataTakenOverPhoneOutcomes.containsIgnoreCase(taskObj.Outcome__c) && partialData && taskObj.New_Call_Back_Time__c == NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call Back Time must be provided if Data taken over the phone is partial'));
            return false;
        }

        if(dataTakenOverPhoneOutcomes.containsIgnoreCase(taskObj.Outcome__c) && !partialData && taskObj.New_Call_Back_Time__c != NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call Back Time is required only if Data taken over the phone is partial'));
            return false;
        }

        if(taskObj.New_Call_Back_Time__c < system.now()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call Back Time must be in future'));
            return false;
        }

        if(taskObj.New_Call_Back_Time__c != NULL && workItem.Response__r.Extension_Date__c != NULL && taskObj.New_Call_Back_Time__c.getTime() < Datetime.newInstance(workItem.Response__r.Extension_Date__c, Time.newInstance(0, 0, 0, 0)).addDays(1).getTime()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Call Back Date must be next day of Extension Date'));
            return false;
        }

        if(workItem.Response__r.Extension_Date__c!= NULL && workItem.Response__r.Extension_Date__c < system.today()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Set Extension Date must be in future'));
            return false;
        }

        if(taskObj.Outcome__c.containsIgnoreCase('Escalated') && taskObj.Escalation_Reason__c.containsIgnoreCase('Extension') && workItem.Response__r.Extension_Date__c <= workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Set Extension Date must be greater than Extension Cut-off Date'));
            return false;
        }

        if(setExtensionDateOutcomes.containsIgnoreCase(taskObj.Outcome__c) && taskObj.Escalation_Reason__c == NULL && workItem.Response__r.Extension_Date__c > workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Set Extension Date must be less than Extension Cut-off Date'));
            return false;
        }
        return true;
    }

    //Actions performed on Save of Recordoutcomes
    public void workItemActions(){
        List<String> queue = new List<String>{'LBU_Escalation_Queue','CC_Escalation_Queue','CC_Admin_Team_Queue','Supplier_Management_Advisers_Queue','Unallocated_Phone_Work_Items'};
        Map<String,Id> queueMap = new Map<String,Id>();

        for(Group q: [Select Id,DeveloperName from Group where DeveloperName in :queue and Type = 'Queue']){
            queueMap.put(q.DeveloperName,q.Id);
        }

        //Work item status is set to 'Pending' or 'Completed' based on outcome
        if (completeWIOutcomes.containsIgnoreCase(taskObj.Outcome__c)){
            workItem.Status__c = 'Completed';
            workItem.OwnerId = UserInfo.getUserId();
            if(pendingWIOutcomes.containsIgnoreCase(taskObj.Outcome__c) && (workItem.Work_Item_Type__c.containsIgnoreCase('Non-response follow-up') || workItem.Work_Item_Type__c.equalsIgnoreCase('Inbound Enquiry'))){
                workItem.Status__c = 'Pending';
                workItem.ownerId = (queueMap.containsKey('Unallocated_Phone_Work_Items')?queueMap.get('Unallocated_Phone_Work_Items'):null);
            }
        }else{
            workItem.Status__c = 'Pending';
            workItem.ownerId = (queueMap.containsKey('Unallocated_Phone_Work_Items')?queueMap.get('Unallocated_Phone_Work_Items'):null);
        }

        workItem.Escalated__c = false;
        workItem.Escalated_By__c = null;
        workItem.Escalation_Notes__c = null;
        workItem.Escalation_Reason__c = NULL;
        workItem.Outcome__c = taskObj.Outcome__c;
        workItem.New_Call_Back_Time__c = taskObj.New_Call_Back_Time__c;
        workItem.Call_Back_Time__c = taskObj.New_Call_Back_Time__c;
        workItem.Follow_up__c = (workItem.New_Call_Back_Time__c!=NULL && !workItem.Outcome__c.containsIgnoreCase('Scheduled Appointment'))?true:false;
        workItem.Appointment__c = workItem.Outcome__c.containsIgnoreCase('Scheduled Appointment')?true:false;

        Boolean updateResp = false;
        Response__c resp = new Response__c(Id= workItem.Response__c);
        //If new extension date is provided
        if(setExtensionDateOutcomes.containsIgnoreCase(taskObj.Outcome__c) && workItem.Response__r.Extension_Date__c != NULL &&
            workItem.Response__r.Extension_Date__c <= workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c &&
            workItem.Response__r.Extension_Date__c != workItem.Response_Extension_Date__c){
            resp.Extension_Date__c = workItem.Response__r.Extension_Date__c;
            updateResp = true;
        }
        
        //If outcomes is related to 'data taken over phone'
        if(taskObj.Outcome__c.containsIgnoreCase('Data Taken Over The Phone - PDF/Paper')){
            resp.Status__c = 'On Hold';
            resp.Response_Status_Reason__c = 'Data Received'; //picklist value doesn't exist
            updateResp = true;
        }
        if (updateResp) update resp;

        //As part of workItem assignment, we block the assignment of any workitem belong to the same contact and unit, until the CSR finish working on this workitem
        //When workItem is firt assigned to CSR, we update assigned__c flag on contact and unit to true, so that any other CSR will not get workitems related to the same contact and unit
        //So we make assigned__c false to allow other workitems to get assigned
        if(workItem.Response__r.Contact__c != NULL){
            Contact ct = new Contact(Id = workItem.Response__r.Contact__c);
            ct.Assigned__c = false;
            update ct;
        }

        if(workItem.Response__c != NULL && workItem.Response__r.Unit_of_Interest__c != NULL){
            Unit__c unit = new Unit__c(Id=workItem.Response__r.Unit_of_Interest__c);
            unit.Assigned__c = false;
            update unit;
        }

        //If Escalated
        if(taskObj.Outcome__c.containsIgnoreCase('Escalated') && String.isNotBlank(taskObj.Escalation_Reason__c)){
            taskObj.Escalated__c = true;
            taskObj.Escalated_By__c = userInfo.getUserId();
            workItem.Escalated__c = true;
            workItem.Escalated_By__c = userInfo.getName();
            workItem.Escalation_Notes__c = taskObj.Description;
            workItem.Escalation_Reason__c = taskObj.Escalation_Reason__c;

            if(workItem.Response__r.Unit_of_Interest__r.LBU__c){
                workItem.OwnerId = queueMap.get('LBU_Escalation_Queue');
                workItem.Queue_Id__c = queueMap.get('LBU_Escalation_Queue');
            } else if(taskObj.Escalation_Reason__c.containsIgnoreCase('Extension') && workItem.Response__r.Extension_Date__c != NULL && workItem.Response__r.Extension_Date__c > workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c){
                workItem.Requested_Extension_Date__c  = workItem.Response__r.Extension_Date__c;
                workItem.OwnerId = (workItem.Response__r.Unit_of_Interest__r.LBU__c?queueMap.get('LBU_Escalation_Queue'):queueMap.get('CC_Escalation_Queue'));
                workItem.Queue_Id__c = workItem.OwnerId;
                workItem.Approval_Status__c = 'Pending Approval';
            } else if(adminEscalations.containsIgnoreCase(taskObj.Escalation_Reason__c)){
                workItem.OwnerId = queueMap.get('CC_Admin_Team_Queue');
                workItem.Queue_Id__c = queueMap.get('CC_Admin_Team_Queue');
            } else if(rmaEscalations.containsIgnoreCase(taskObj.Escalation_Reason__c)){
                workItem.OwnerId = queueMap.get('Supplier_Management_Advisers_Queue');
                workItem.Queue_Id__c = queueMap.get('Supplier_Management_Advisers_Queue');
            } else if(!workItem.Response__r.Unit_of_Interest__r.LBU__c && !adminEscalations.containsIgnoreCase(taskObj.Escalation_Reason__c)){
                workItem.OwnerId = queueMap.get('CC_Escalation_Queue');
                workItem.Queue_Id__c = queueMap.get('CC_Escalation_Queue');
            }
        }

        //Update notes to the selected  contact
        if(contactNotes != null && wi.Contact__c != null){
            Contact ct = new Contact(Id=wi.Contact__c);
            ct.Notes__c = contactNotes;
            update ct;
        }

        //Update notes on response's collectoin unit
        if(workItem.Response__r.Unit_of_Interest__r.Notes__c != null){
            Unit__c ut = new Unit__c(Id=workItem.Response__r.Unit_of_Interest__c);
            ut.Notes__c = workItem.Response__r.Unit_of_Interest__r.Notes__c;
            update ut;
        }

        //create task
        String subject = taskObj.Outcome__c;
        if(taskObj.Outcome__c == 'Escalated'){subject +='-'+taskObj.Escalation_Reason__c;}
        taskObj.Status = 'Completed';
        taskObj.Subject = subject;
        taskObj.WhatId = workItem.Id;
        taskObj.WhoId = wi.Contact__c;
        //insert taskObj;

        //update workItem;
        List<Work_Item__c> wiList = new List<Work_Item__c>();
        Set<Work_Item__c> wiSet = new Set<Work_Item__c>();
        List<Task> taskList = new List<Task>();
        Set<Task> taskSet = new Set<Task>();
        if (selectedWorkItems.size()>0 && includeParentWorkItem){
            refreshParentTab = true;
            wiSet.add(workItem);
            taskSet.add(taskObj);
        }else if (selectedWorkItems.size()>0 && !includeParentWorkItem){
            refreshParentTab = false;
        }else{
            wiSet.add(workItem);
            taskSet.add(taskObj);
            refreshParentTab = false;
        }
        selectedWIContacts = new Set<Id>();
        selectedWICollectionUnits = new Set<Id>();
        //This is for reocording bulk outcomes for workitems selected from the outstanding workitems page
        for(Work_Item__c wi : selectedWorkItems){
            if(wi.id != workItem.id)
			{				
				wiSet.add(updateWorkItem(wi.Id));
			}
            taskSet.add(createTask(taskObj,wi.Id));
        }
        /*system.debug('selectedWIContacts=='+selectedWIContacts);
        for(WorkItemWrapper ut : selectedCollectionUnitsWrapper){
            wiList.add(updateWorkItem(ut.wi.Id));
            taskList.add(createTask(taskObj,ut.wi.Id));
        }*/
        if(!wiSet.isEmpty())wiList.addAll(wiSet);
        if(!taskSet.isEmpty())taskList.addAll(taskSet);
        if(!wiList.isEmpty())update wiList;
        if(!taskList.isEmpty())insert taskList;
    }
    
    //Save workitem,task,contact,unit notes
    public PageReference save(){
        SavePoint sp;
        try{
            //Validations
            if (!validations()){
                refreshParentTab = false;
                return null;
            } else {
                refreshParentTab = true;
            }
            
            sp = Database.setSavepoint();
            //Actions
            workItemActions();
            System.debug('before agentIsFinished');
            agentIsFinished();
            System.debug('after agentIsFinished');
            
            /*if(!contactsWrapper.isEmpty() || !collectionUnitsWrapper.isEmpty()){
                return null;
            }*/
            if (selectedWorkItems.size()>0 && !includeParentWorkItem){
                System.debug('IN includeParentWorkItem');
                PageReference pg = new PageReference('/apex/WorkItemsGroupedBy?id='+workItem.Id);
                return pg.setRedirect(true);
            } else if(selectedWorkItems.size()>0 && includeParentWorkItem){
                return null;            
            } else {
                PageReference pg = new PageReference('/'+workItem.Id);
                return pg.setRedirect(true);
            }
        }catch(exception e){
            System.debug('Error: '+e.getLineNumber()+'--'+e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            Database.rollback(sp);
            return null;
        }
    }
    
    //Update Work item
    public Work_Item__c updateWorkItem(Id wId){
        Work_Item__c wi = new Work_Item__c(Id=wId);
        wi.Status__c = workItem.Status__c;
        wi.Escalated__c = workItem.Escalated__c;
        wi.Escalated_By__c = workItem.Escalated_By__c;
        wi.Escalation_Notes__c = workItem.Escalation_Notes__c;
        wi.Escalation_Reason__c = workItem.Escalation_Reason__c;
        wi.Outcome__c = workItem.Outcome__c;
        wi.New_Call_Back_Time__c = workItem.New_Call_Back_Time__c;
        wi.Call_Back_Time__c = workItem.Call_Back_Time__c;
        wi.Follow_up__c = workItem.Follow_up__c;
        wi.Appointment__c = workItem.Appointment__c;
        wi.OwnerId = workItem.OwnerId;
        //ECP-3729 - Unable to use escalation outcome button(Queue_ID was not mapped earlier which blocks to escalate the secondary workitems)
        wi.Queue_Id__c = workItem.Queue_Id__c;
        wi.Approval_Status__c = workItem.Approval_Status__c;
        wi.Requested_Extension_Date__c = workItem.Requested_Extension_Date__c;
        return wi;
    }
    
    //Create task
    public Task createTask(Task ts,Id wId){
        Task cloneTask = ts.clone(false,true,false,false);
        cloneTask.WhatId = wId;
        return cloneTask;
    }

    /*
    * Update the status of the CSR as they complete the work item.
    */
    public void agentIsWritingOutcomes() {
        // this is called at page init, we can do inline callout
        boolean inlineCallout = true;
        CSRActionRecorder.startRecordingOutcome(workItem.Id, DateTime.now(), inlineCallout);
    }

    private void agentIsFinished() {
        CSRActionRecorder.finishRecordingOutcome(workItem.Id, DateTime.now());
    }
    
    //Called from record outcomes button from WorkItemsGroupedBy VF page
    public PageReference recordOutcomes(){
        if(!checkIfSelected()) return null;
        PageReference pg = new PageReference('/apex/BulkRecordOutcomes?id='+workItem.Id+'&redirect=bulkRecordOutcome');
        return pg.setRedirect(false);
    }

    //Called from Interaction log button from WorkItemsGroupedBy VF page
    public PageReference interactionLog(){
        if(!checkIfSelected()) return null;
        
        PageReference pg = new PageReference('/apex/BulkInteractionLog?id='+workItem.Id+'&redirect=bulkInteraction');
        return pg.setRedirect(false);
    }

    //Check if atleast one workitem is selected to reocord outcomes or interaction log from WorkItemsGroupedBy VF page
    public Boolean checkIfSelected(){
        if (workItem.Status__c == 'Completed' && includeParentWorkItem){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Primary Work Item is completed. You cannot take any action on primary work item.'));
            return false;
        }
        //Add this to allow primary work item to be selected for record outcome
        if (includeParentWorkItem){
            selectedWorkItems.add(workItem);
        }
        
        //selectedContactsWrapper = new List<WorkItemWrapper>();
        //selectedCollectionUnitsWrapper = new List<WorkItemWrapper>();
        for(WorkItemWrapper ct : contactsWrapper){
            if (ct.sel){
                //selectedContactsWrapper.add(ct);
                selectedWorkItems.add(ct.wi);
            }
        }
        system.debug('selectedWIContacts=='+selectedWIContacts);
        for(WorkItemWrapper ut : collectionUnitsWrapper){
            if (ut.sel){
                //selectedCollectionUnitsWrapper.add(ut);
                selectedWorkItems.add(ut.wi);
            }
        }
        
        if (selectedWorkItems.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select atleast one Work Item'));
            return false;
        }
        //this is to make sure we dont record outcomes on any work items that was Escalated.
        boolean escalatedWIExists = false;
        String escalatedWorkItems = '';
        //this is to make sure we dont record outcomes on any work items that was Escalated.
        for(Work_Item__c wi : selectedWorkItems)
        {
            //ECP-3650-updated the if condition with Escalated__c instead of outcome__c 
            if(wi.Escalated__c != null && wi.Escalated__c)
            {
                if(!escalatedWIExists)
                {
                    escalatedWIExists = true;
                }
                if (escalatedWorkItems.length()>0) escalatedWorkItems += ',';
            	escalatedWorkItems += wi.Name; 
            }
        }
        if(escalatedWIExists)
        {
        	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,('Awaiting for approval for the following work item(s):' + escalatedWorkItems +' You cannot record outcomes')));
            return false;
        }
        return true;
    }

    //Cancel button for BulkRecordoutcomes
    public PageReference cancelBulk(){
        boolean inlineCallout = true;
        CSRActionRecorder.cancelRecordingOutcome(workItem.Id, DateTime.now(), inlineCallout); 
        PageReference pg = new PageReference('/apex/WorkItemsGroupedBy?id='+workItem.Id);
        return pg.setRedirect(true);
    }
    
    public PageReference cancel(){
        boolean inlineCallout = true;
        CSRActionRecorder.cancelRecordingOutcome(workItem.Id, DateTime.now(), inlineCallout);
        PageReference pg = new PageReference('/'+workItem.Id);
        return pg.setRedirect(true);
    }

    public PageReference saveInteractionLog(){
        Savepoint sp;
        try{
            sp = Database.setSavepoint();
            Boolean updateResp = false;
            if(validationsInteractionLog()){
                refreshParentTab = true;
            }else return null;

            if(!taskObj.Subject__c.equalsIgnoreCase('Feedback')){
                taskObj.Feedback_Type__c = null;
            }

            Response__c resp = new Response__c(Id= workItem.Response__c);
            if(taskObj.Subject__c.containsIgnoreCase('Data Taken Over The Phone - PDF/Paper')){
                resp.Status__c = 'On Hold';
                resp.Response_Status_Reason__c = 'Data Received'; //picklist value doesn't exist
                updateResp = true;
            }

            if (taskObj.Subject__c.equalsIgnoreCase('Grant Extension') && workItem.Response__r.Extension_Date__c != NULL){
                resp.Extension_Date__c = workItem.Response__r.Extension_Date__c;
                updateResp = true;
            }
            if(updateResp) update resp;

            List<Task> taskList = new List<Task>();
            Set<Task> taskSet = new Set<Task>();
            taskObj.Subject = taskObj.Subject__c;
            taskObj.WhatId = workItem.Id;
            taskObj.Status = 'Completed';
            taskObj.WhoId = workItem.Contact__c;
            taskObj.Multi_Escalate_Feedback_Id__c = ApexUtility.GUID();
            if(taskObj.Escalated__c && taskObj.Subject__c.equalsIgnoreCase('Feedback')){
                taskObj.Subject = 'Escalate-'+taskObj.Subject;
                taskObj.Status = 'Open';
                taskObj.Escalated_By__c = UserInfo.getUserId();
                taskObj.Escalation_Reason__c = taskObj.Subject__c;
            }

            System.debug('taskObj=='+taskObj.WhatId);
            //This is for creating tasks for the bulk work items that were selected
            try{
                for(Work_Item__c wi: selectedWorkItems){
                    taskSet.add(createTask(taskObj,wi.Id));
                }
            }catch(exception e){}
            if(includeParentWorkItem){
                refreshParentTab = true;
                for(Task ts:taskSet){
                    if(ts.WhatId == taskObj.WhatId){ts.Primary_Task__c = true;}
                }
                taskList.addAll(taskSet);
            }else{
                refreshParentTab = false;
                taskList.addAll(taskSet);
                taskList[0].Primary_Task__c = true;
            }

            if(!taskList.isEmpty()){upsert taskList;}
            if (!includeParentWorkItem){
                PageReference pg = new PageReference('/apex/WorkItemsGroupedBy?id='+workItem.Id);
                return pg.setRedirect(true);
            }
            return null;
        }catch(exception e){
            System.debug('Error: '+e.getLineNumber()+'--'+e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            refreshParentTab = false;
            Database.rollback(sp);
            return null;
        }
    }
    
    //Page validations
    public Boolean validationsInteractionLog(){
        System.debug('ts.Subject__c=='+taskObj.Subject__c+'=='+taskObj.Feedback_Type__c);
        if(taskObj.Subject__c.equalsIgnoreCase('Feedback') &&  taskObj.Feedback_Type__c== NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Feedback Type:You must enter a value'));
            return false;
        }
        if(taskObj.Subject__c.equalsIgnoreCase('Grant Extension') &&  workItem.Response__r.Extension_Date__c== NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date:You must enter a value'));
            return false;
        }
        if(taskObj.Subject__c.equalsIgnoreCase('Grant Extension') &&  workItem.Response__r.Extension_Date__c!= NULL && workItem.Response__r.Extension_Date__c < system.today()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date must be in future'));
            return false;
        }
        if(taskObj.Subject__c.equalsIgnoreCase('Grant Extension') &&  workItem.Response__r.Extension_Date__c!= NULL && workItem.Response__r.Extension_Date__c < system.today()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date must be in future'));
            return false;
        }
        if(taskObj.Subject__c.equalsIgnoreCase('Grant Extension') && workItem.Response__r.Extension_Date__c > workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date must be less than Collection Instance Extension Cut-off Date'));
            return false;
        }
        return true;
    }

    //Cancel for bulkinteractionslog vf
    public PageReference cancelInteractionLog(){
        PageReference pg = new PageReference('/apex/WorkItemsGroupedBy?id='+workItem.Id);
        return pg.setRedirect(true);
    }

    //Clear for InteractionsLog vf
    public void clear(){
        taskObj = new Task();
    }

    //Wrapper class which provides the workitems related to contacts and collection units
    public class WorkItemWrapper{
        public Boolean sel{get;set;}
        public Work_Item__c wi{get;set;}
        public WorkItemWrapper(Work_Item__c w){
            sel = false;
            wi = w;
        }
    }
}