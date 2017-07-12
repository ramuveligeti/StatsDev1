/**
* @description This is an extension controller for WrapupCodes Page. 
* @author Ram Veligeti
* @date 29.Jun.2015
*/
public class RecordOutcomesExCon {
    public static Boolean Executed = false;
    public Work_Item__c workItem{get;set;}
    public List<SelectOption> coreResults{get;set;}
    public String coreResultSelected{get;set;}
    public List<SelectOption> outcomes{get;set;}
    public String outcomeSelected{get;set;}
    public List<SelectOption> actions{get;set;}
    public String actionSelected{get;set;}
    public List<SelectOption> defaultCallBack{get;set;}
    public String defaultCallBackSelected{get;set;}
    //Key - Concatenate Delivery Mode,Work Item Type,Core Result,Action
    //Value - Default call back time
    public Map<String,Set<String>> wrapupCodeMap = new Map<String,Set<String>>();
    //1st key - combination of Delivery Mode,Work Item Type,Core Result
    //2nd key - outcomes
    //Set<String> - Actions
    public Map<String,Map<String,Set<String>>> multiLayerPicklist = new Map<String,Map<String,Set<String>>>();
    //Key - combination of DeliveryMode and WorkItemtype
    //Set<String> - CoreResults
    public Map<String,Set<String>> coreResultMap = new Map<String,Set<String>>();
    private String delWorkCore;
    private String initialCoreResult,initialOutcome, initialAction;
    //Key - combination of Delivery Mode,Work Item Type,Core Result,Action
    //Value - Follow-up Work Item type
    private Map<String,Set<String>> wrapupCodeFollowup = new Map<String,Set<String>>();
    //Key - combination of Delivery Mode,Work Item Type,Core Result,Action
    //Value - Create Event 
    private Map<String,Boolean> createEventMap = new Map<String,Boolean>();
    private Map<String,Boolean> redirectMap = new Map<String,Boolean>();
    
    
    //Standard controller
    public RecordOutcomesExCon(ApexPages.StandardController stdCont){
        workItem = (Work_Item__c)stdCont.getRecord();
        
        if(!String.isBlank(workItem.Core_Result__c)){
            coreResultSelected = workItem.Core_Result__c;
            coreResultSelected = coreResultSelected.toLowerCase().capitalize();
        }
        
        if(!String.isBlank(workItem.Outcome__c)){
            initialOutcome = workItem.Outcome__c;
        }
        
        if(!String.isBlank(workItem.Action__c)){
            initialAction = workItem.Action__c;
        }
        
        //Loop through custom settings
        for(Wrapup_Codes__c wrapupCode:  Wrapup_Codes__c.getAll().values()){
            //Key- Outcome, Value- Set<Actions>
            Map<String,Set<String>> outcomeAction = new Map<String,Set<String>>();
            //Concatenate Delivery Mode,Work Item Type,Core Result,Action
            String wrapupString = wrapupCode.Delivery_Mode__c+wrapupCode.Work_Item_Type__c+wrapupCode.Core_Result__c+wrapupCode.Outcome__c+wrapupCode.Action__c;
            String wholeWrapupString = wrapupCode.Delivery_Mode__c+wrapupCode.Work_Item_Type__c+wrapupCode.Core_Result__c+wrapupCode.Outcome__c+wrapupCode.Action__c+wrapupCode.Follow_up_Work_Item_Type__c;
            //Concatenate Delivery Mode,Work Item Type,Core Result
            String deliverWorkItemCoreResult = wrapupCode.Delivery_Mode__c+wrapupCode.Work_Item_Type__c+wrapupCode.Core_Result__c;
            //Concatenate Delivery Mode,Work Item Type
            String deliveryWorkItem = wrapupCode.Delivery_Mode__c+wrapupCode.Work_Item_Type__c;
            
            deliverWorkItemCoreResult = deliverWorkItemCoreResult.trim().toLowerCase();
            deliveryWorkItem = deliveryWorkItem.trim().toLowerCase();
            //wrapupCodeMap.put(wrapupString.trim().toLowerCase(),wrapupCode.Default_Call_Back_Time__c);
            createEventMap.put(wholeWrapupString.trim().toLowerCase(),wrapupCode.Create_Event__c);
            redirectMap.put(wholeWrapupString.trim().toLowerCase(),wrapupCode.Create_Event__c);
            
            if(wrapupCodeMap.containsKey(wrapupString.trim().toLowerCase())){
                wrapupCodeMap.get(wrapupString.trim().toLowerCase()).add(wrapupCode.Default_Call_Back_Time__c);
            } else {
                wrapupCodeMap.put(wrapupString.trim().toLowerCase(),new Set<String>{wrapupCode.Default_Call_Back_Time__c});
            }

            if(wrapupCodeFollowup.containsKey(wrapupString.trim().toLowerCase())){
                wrapupCodeFollowup.get(wrapupString.trim().toLowerCase()).add(wrapupCode.Follow_up_Work_Item_Type__c);
            } else {
                wrapupCodeFollowup.put(wrapupString.trim().toLowerCase(),new Set<String>{wrapupCode.Follow_up_Work_Item_Type__c});
            }
            //Form the Multilayer map 
            if(multiLayerPicklist.containsKey(deliverWorkItemCoreResult)){
                outcomeAction = multiLayerPicklist.get(deliverWorkItemCoreResult);
                if(outcomeAction.containsKey(wrapupCode.Outcome__c.toLowerCase())){
                    outcomeAction.get(wrapupCode.Outcome__c.toLowerCase()).add(wrapupCode.Action__c);                
                }else{
                    outcomeAction.put(wrapupCode.Outcome__c.toLowerCase(),new Set<String>{wrapupCode.Action__c});    
                }
            }else{
                outcomeAction.put(wrapupCode.Outcome__c.toLowerCase(),new Set<String>{wrapupCode.Action__c});   
            }
            multiLayerPicklist.put(deliverWorkItemCoreResult,outcomeAction);
            
            if(coreResultMap.containsKey(deliveryWorkItem)){
                coreResultMap.get(deliveryWorkItem).add(wrapupCode.Core_Result__c);
            } else {
                coreResultMap.put(deliveryWorkItem, new Set<String>{wrapupCode.Core_Result__c});
            }
            system.debug('deliveryWorkItem=='+deliveryWorkItem+'=='+wrapupCode.Core_Result__c);
        }
        fetchCoreResult();
        findOutcomes();
    }
    
    //Form core result picklist
    private void fetchCoreResult(){
        coreResults = new List<SelectOption>();
        String delWork = workItem.Delivery_Mode__c+workItem.Work_Item_Type__c;
        system.debug('delWork=='+delWork.trim().toLowerCase());
        coreResults.add(new SelectOption('', '--None--'));
        if(coreResultMap.containsKey(delWork.trim().toLowerCase())){
            for(String cr: coreResultMap.get(delWork.trim().toLowerCase())){
                coreResults.add(new SelectOption(cr.capitalize(),cr.capitalize()));
            }
        }
    }
    
    //Form outcome picklist based on delivery mode, work item type, core result
    public void findOutcomes(){
        outcomes = new List<SelectOption>();
        workItem.Core_Result__c = coreResultSelected;
        
        //populate outcomeSelected if the work item already has the outcome
        if(!String.isBlank(initialOutcome)){
            outcomeSelected = initialOutcome;
            initialOutcome = null;
        }else{
            outcomeSelected = null;
        }
        if(!String.isBlank(workItem.Delivery_Mode__c+workItem.Work_Item_Type__c+workItem.Core_Result__c)){
            delWorkCore = workItem.Delivery_Mode__c+workItem.Work_Item_Type__c+workItem.Core_Result__c;
            delWorkCore = delWorkCore.trim().toLowerCase();
        }
        if(!String.isBlank(delWorkCore) && multiLayerPicklist.containsKey(delWorkCore)){
            outcomes.add(new SelectOption('', '--None--'));
            for(String outcome: multiLayerPicklist.get(delWorkCore).keySet()){
                outcomes.add(new SelectOption(outcome.capitalize(),outcome.capitalize()));
            }
            findActions();
            //findDefaultCallBackTime();
            //findNewCallBackTime();
        }else{
            actions = new List<SelectOption>();
            workItem.Default_Call_Back_Time__c = NULL;
            defaultCallBack = new List<SelectOption>();
            workItem.New_Call_Back_Time__c = NULL;
        }
    }
    
    //form Action picklist based on outcome
    public void findActions(){
        actions = new List<SelectOption>();
        
        //populate actionSelected if the work Item already has the Action
        if(!String.isBlank(initialAction)){
            actionSelected = initialAction;
            initialAction = null;
        }else{
            actionSelected = null;
        }
        if(!String.isBlank(delWorkCore) && !String.isBlank(outcomeSelected) && multiLayerPicklist.containsKey(delWorkCore) && multiLayerPicklist.get(delWorkCore).containsKey(outcomeSelected.toLowerCase())){
            actions.add(new SelectOption('', '--None--'));
            for(String action: multiLayerPicklist.get(delWorkCore).get(outcomeSelected.toLowerCase())){
                actions.add(new SelectOption(action.capitalize(),action.capitalize()));
            }
            
            //If only one picklist values is available then pre-populate it
            if(actions.size()==2){
                actions.remove(0);
                actionSelected = actions[0].getValue();
            }
            findDefaultCallBackTime();
            //findNewCallBackTime();
        }else{
            workItem.Default_Call_Back_Time__c = NULL;
            defaultCallBack = new List<SelectOption>();
            workItem.New_Call_Back_Time__c = NULL;
        }
    }
    
    //find Default Call Back time and set New Call back Time
    public void findDefaultCallBackTime(){
        defaultCallBack = new List<SelectOption>();
        String workItemWrapup = workItem.Delivery_Mode__c+workItem.Work_Item_Type__c+workItem.Core_Result__c+outcomeSelected+actionSelected;
        defaultCallBack.add(new SelectOption('', '--None--'));
        if(wrapupCodeMap.containsKey(workItemWrapup.trim().toLowerCase())){
            for(String callBack: wrapupCodeMap.get(workItemWrapup.trim().toLowerCase())){
                defaultCallBack.add(new SelectOption(callBack.capitalize(),callBack.capitalize()));
            }
            
            if(defaultCallBack.size()==2){
                defaultCallBack.remove(0);
                defaultCallBackSelected = defaultCallBack[0].getValue();
            }
            findNewCallBackTime();
        } else {
            workItem.New_Call_Back_Time__c = NULL;
        }
    }
    
    public void findNewCallBackTime(){
        workItem.Default_Call_Back_Time__c = null;
        workItem.New_Call_Back_Time__c = null;
        List<String> callBacks = new List<String>();
        String workItemWrapup = workItem.Delivery_Mode__c+workItem.Work_Item_Type__c+workItem.Core_Result__c+outcomeSelected+actionSelected;
        
        if(wrapupCodeMap.containsKey(workItemWrapup.trim().toLowerCase()) && String.isNotBlank(defaultCallBackSelected)){
            workItem.Default_Call_Back_Time__c = defaultCallBackSelected;
            //If Day after set extension date is selected, Get Response Extension Date to calculate call back time
            if(workItem.Default_Call_Back_Time__c.containsIgnoreCase('Day after set extension date') && workItem.Response_Extension_Date__c != NULL){
                workItem.New_Call_Back_Time__c = Datetime.newInstance(workItem.Response_Extension_Date__c.addDays(1), Time.newInstance(0, 0, 0, 0));
            } else if(!workItem.Default_Call_Back_Time__c.containsIgnoreCase('N/A') && !workItem.Default_Call_Back_Time__c.containsIgnoreCase('Day after set extension date')){
                callBacks = workItem.Default_Call_Back_Time__c.split(' ');
                //If days
                if(callBacks[1].toLowerCase().contains('day')){
                    workItem.New_Call_Back_Time__c = system.now().addDays(Integer.valueOf(callBacks[0]));
                }
                
                //If Hours
                if(callBacks[1].toLowerCase().contains('hour')){
                    workItem.New_Call_Back_Time__c = system.now().addHours(Integer.valueOf(callBacks[0]));
                }
                
                //If Mins
                if(callBacks[1].toLowerCase().contains('min')){
                    workItem.New_Call_Back_Time__c = system.now().addMinutes(Integer.valueOf(callBacks[0]));
                }
            }
        } else {
            workItem.New_Call_Back_Time__c = null;
        }
    }
    
    //Save Method
    public PageReference Save(){
        Savepoint sp;
        try{
            if(String.isBlank(coreResultSelected) || String.isBlank(outcomeSelected) || String.isBlank(actionSelected) || String.isBlank(defaultCallBackSelected)){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Provide values for Core Result, Outcome, Action and Default Call Back Time'));
                return null;
            }
            Executed = true;
            sp = Database.setSavepoint();
            workItem.Outcome__c = outcomeSelected.capitalize();
            workItem.Action__c = actionSelected.capitalize();
            workItem.Status__c = 'Completed';
            update workItem;
            
            List<Work_Item__c> callBackWorkItemList = new List<Work_Item__c>();
            List<Event> callBackEventList = new List<Event>();

            String workItemWrapup = workItem.Delivery_Mode__c+workItem.Work_Item_Type__c+workItem.Core_Result__c+workItem.Outcome__c+workItem.Action__c;
            String redirectId;
            workItemWrapup = workItemWrapup.trim().toLowerCase();
            //Assign the Follow up work Item type
            for(String followupWorkItem: wrapupCodeFollowup.get(workItemWrapup.toLowerCase())){
                system.debug('followupWorkItem=='+followupWorkItem);
                if(String.isNotBlank(followupWorkItem)){
                    String followup = workItemWrapup+followupWorkItem;
                    Work_Item__c callBackWorkItem = workItem.clone(false,true,false,false);
                    callBackWorkItem.Work_Item_Type__c = followupWorkItem.capitalize();
                    callBackWorkItem.Status__c = 'New';
                    callBackWorkItem.Work_Item_ExtId__c = NULL;
                    callBackWorkItem.Default_Call_Back_Time__c = NULL;
                    callBackWorkItem.Core_Result__c = NULL;
                    callBackWorkItem.Outcome__c = NULL;
                    callBackWorkItem.Action__c = NULL;
                    callBackWorkItem.New_Call_Back_Time__c = NULL;
                    callBackWorkItem.Notes__c = NULL;
                    callBackWorkItem.Activity_Schedule__c = NULL;
                    callBackWorkItem.Call_Back_Time__c = workItem.New_Call_Back_Time__c;
                    callBackWorkItem.Create_Event__c = createEventMap.get(followup.toLowerCase());
                    callBackWorkItem.Redirect__c = redirectMap.get(followup.toLowerCase());
                    callBackWorkItemList.add(callBackWorkItem);
                }
            }
            
            if(!callBackWorkItemList.isEmpty()){
                insert callBackWorkItemList;
            }
            
            for(Work_Item__c callBackWorkItem: callBackWorkItemList){
                String followup = workItemWrapup+callBackWorkItem.Work_Item_Type__c;
                //If Create Event on the custom settings is true
                if(createEventMap.get(followup.toLowerCase()) && workItem.New_Call_Back_Time__c != NULL){
                    Event callBackEvent = new Event();
                    callBackEvent.WhatId = callBackWorkItem.Id;
                    callBackEvent.Subject = callBackWorkItem.Work_Item_Type__c.capitalize()+' '+callBackWorkItem.Delivery_Mode__c.capitalize();
                    callBackEvent.ActivityDateTime = workItem.New_Call_Back_Time__c;
                    callBackEvent.StartDateTime = workItem.New_Call_Back_Time__c;
                    callBackEvent.DurationInMinutes = 60; //Default duration
                    callBackEvent.EndDateTime = callBackEvent.StartDateTime.addMinutes(callBackEvent.DurationInMinutes);
                    callBackEventList.add(callBackEvent);
                }
            }
            
            if(!callBackEventList.isEmpty()){
                insert callBackEventList;
            }
            
            for(Work_Item__c wi: callBackWorkItemList){
                if(wi.Redirect__c){
                    redirectId = wi.Id;
                }
            }
            
            if(!callBackWorkItemList.isEmpty()){
                return new PageReference('/'+redirectId);
            } else {
                return new PageReference('/'+workItem.Id);
            }
        }catch(exception e){
            Database.rollback(sp);
            Executed = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,e.getMessage()));
            return null;
        }
    }
}