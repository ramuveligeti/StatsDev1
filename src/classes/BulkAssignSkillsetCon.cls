/**
* @description   This class is called from BulkAssignSkillset page to bulk create skillsets for User
* @author        Ram Veligeti
* @date          01.09.2015
*/
public class BulkAssignSkillsetCon {
    public SelectOption[] allUsers{get;set;}
    public SelectOption[] selectedUsers{get;set;}
    public SelectOption[] allCollections{get;set;}
    public SelectOption[] selectedCollections{get;set;}
    public SelectOption[] allSkills{get;set;}
    public SelectOption[] selectedSkills{get;set;}
    public Skillset__c skill{get;set;}
    
    //Constructor
    public BulkAssignSkillsetCon(Apexpages.StandardController stdCont){
    	skill = (Skillset__c)stdCont.getRecord();
        skill.Training_Completion_Date__c = system.now();
        User[] users = [Select Id, Name from User where IsActive=true];
        selectedUsers = new List<SelectOption>();
        allUsers = new List<SelectOption>();
        for(User u: users){
            allUsers.add(new SelectOption(u.Id,u.Name));
        }
        
        Collection__c[] collections = [Select Id,Name from Collection__c where Status__c = 'Active'];
        selectedCollections = new List<SelectOption>();
        allCollections = new List<SelectOption>();
        for(Collection__c c: collections){
            allCollections.add(new SelectOption(c.Id,c.Name));
        }
        
        selectedSkills= new List<SelectOption>();
        allSkills = new List<SelectOption>();
        allSkills = ApexUtility.getPicklistValues('Skillset__c', 'Skill__c',false);        
    }
    
    //Save method
    public PageReference save(){
        try{
            if(selectedUsers.isEmpty() || selectedCollections.isEmpty() || selectedSkills.isEmpty() || skill.Training_Completion_Date__c==NULL){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Missing data in required fields'));
                return null;
            }
            
            Map<String,Skillset__c> upsertSkillsets = new Map<String,Skillset__c>();
            Set<String> skillsetExtIds = new Set<String>();
            List<Skillset__c> newSkillsets = new List<Skillset__c>();
            for(SelectOption su: selectedUsers){
                for(SelectOption sc: selectedCollections){
                    for(SelectOption ss: selectedSkills){
                        Skillset__c skillset = new Skillset__c();
                        skillset.User_Name__c = su.getValue();
                        skillset.Collection__c = sc.getValue();
                        skillset.Skill__c = ss.getValue();
                        skillset.Training_Completion_Date__c = skill.Training_Completion_Date__c;
                        skillset.Skillset_Ext_Id__c = skillset.User_Name__c+''+skillset.Collection__c+''+skillset.Skill__c;
                        /*/If number of records to insert exceed limits
                        if(newSkillsets.size() > Limits.getLimitDMLRows()){
                            upsert newSkillsets Skillset_Ext_Id__c;
                            newSkillsets.clear();
                        }*/
                        skillsetExtIds.add(skillset.Skillset_Ext_Id__c);
                        newSkillsets.add(skillset);
                    }
                }
            }
            
            List<Skillset__c> existingSkillsets = [Select Id from Skillset__c where Skillset_Ext_Id__c in :skillsetExtIds];
            
            if(!existingSkillsets.isEmpty()){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'One of the user already has one of the assigned Skill and Collection. Please change your selection.'));
                return null;
            }
            
            if(!newSkillsets.isEmpty()){
                upsert newSkillsets Skillset_Ext_Id__c;
            }
            return new PageReference('/'+ Skillset__c.sObjectType.getDescribe().getKeyPrefix());
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            return null;
        }
    }
    
    //Cancel
    public PageReference cancel(){
        return new PageReference('/'+ Skillset__c.sObjectType.getDescribe().getKeyPrefix());
    }
}