/*author: Ram Veligeti
  description: This class is used in InteractionLog component. The component is called in InteractionLog VF and BulkInteractionLog VF pages
  InteractionLog VF: This is used in recording tasks on Individual Work Item. This page has been overriden the standard Interaction log page.
  BulkInteractionLog VF: This is used for recording tasks for bulk work itmes that are selected on the 'Outstanding Work Items' screen on the right side of the console
  stories: ECP-2751,2582
*/
public class InteractionLogExCon {
    public Task ts{get;set;}
    public Work_Item__c workItem{get;set;}
    public Boolean refreshParentTab{get;Set;}
    public String dataTakenOverPhoneOutcomes = 'Data Taken Over The Phone - PDF/Paper';

    public InteractionLogExCon(ApexPages.StandardController stdCont){
        workItem = (Work_Item__c)stdCont.getRecord();
        ts = new Task();
    }
    
    //Called on Save button. This method creates task(s) based on the VF page it is called from
    public PageReference save(){
        Savepoint sp;
        try{
            sp = Database.setSavepoint();
            Boolean updateResp = false;
            if(!validations()) return null;
            refreshParentTab = true;

            if(!ts.Subject__c.equalsIgnoreCase('Feedback')){
                ts.Feedback_Type__c = null;
            }

            Response__c resp = new Response__c(Id= workItem.Response__c);
            if(dataTakenOverPhoneOutcomes.containsIgnoreCase(ts.Subject__c)){
                resp.Status__c = 'On Hold';
                resp.Response_Status_Reason__c = 'Data Received'; //picklist value doesn't exist
                updateResp = true;
            }

            if (ts.Subject__c.equalsIgnoreCase('Grant Extension') && workItem.Response__r.Extension_Date__c != NULL){
                resp.Extension_Date__c = workItem.Response__r.Extension_Date__c;
                updateResp = true;
            }
            if(updateResp) update resp;

            ts.Subject = ts.Subject__c;
            ts.WhatId = workItem.Id;
            if(ts.Escalated__c && ts.Subject__c.equalsIgnoreCase('Feedback')){
                ts.Subject = 'Escalate-'+ts.Subject;
                ts.Status = 'Open';
                ts.Escalated_By__c = UserInfo.getUserId();
                ts.Escalation_Reason__c = ts.Subject__c;
                ts.Primary_Task__c = true;
            }
            else {ts.Status = 'Completed';}
            ts.WhoId = workItem.Contact__c;

            System.debug('ts=='+ts.WhatId);
            upsert ts;
            clear();
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
    public Boolean validations(){
        System.debug('ts.Subject__c=='+ts.Subject__c+'=='+ts.Feedback_Type__c+'=='+workItem.Response__r.Extension_Date__c);
        if(String.isBlank(ts.Subject__c)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'You must select subject'));
            return false;
        }
        if(ts.Subject__c.equalsIgnoreCase('Feedback') &&  ts.Feedback_Type__c== NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Feedback Type:You must enter a value'));
            return false;
        }
        if(ts.Subject__c.equalsIgnoreCase('Grant Extension') &&  workItem.Response__r.Extension_Date__c== NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date:You must enter a value'));
            return false;
        }
        if(ts.Subject__c.equalsIgnoreCase('Grant Extension') &&  workItem.Response__r.Extension_Date__c!= NULL && workItem.Response__r.Extension_Date__c < system.today()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date must be in future'));
            return false;
        }
        if(ts.Subject__c.equalsIgnoreCase('Grant Extension') && workItem.Response__r.Extension_Date__c > workItem.Response__r.Collection_Instance__r.Extension_Cut_off_Date__c){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Extension Date must be less than Collection Instance Extension Cut-off Date'));
            return false;
        }
        return true;
    }

    //Clear for InteractionsLog vf
    public void clear(){
        ts = new Task();
    }
}