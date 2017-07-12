/**
* @description   This class is called from AlterSkillsetForUser page to create/modify skillsets for User
* @author        Ram Veligeti
* @date          28.08.2015
*/
public class AlterSkillsetForUserCon {
    public Skillset__c skillset{get;set;}
    public List<Skillset__c> skillsets{get;set;}
    public Boolean displayList{get;set;}
    public String removeId{get;set;}
    public Boolean displaySave{get;set;}
    public Integer removeListId{get;set;}
    
    //Constructor
    public AlterSkillsetForUserCon(ApexPages.StandardController stdCont){
        skillset = (Skillset__c)stdCont.getRecord();
        displayList = false;
    }
    
    //Method to query related Skillsets of the User
    public void queryRelatedSkills(){
        if(String.isNotBlank(skillset.User_Name__c)){
            skillsets = [Select Id, Name, Collection__c, Skillset_Ext_Id__c, Focus_Start_Date__c, Focus_End_Date__c, Skill__c, Training_Completion_Date__c, User_Name__c from Skillset__c where User_Name__c = :skillset.User_Name__c order by createddate];
            system.debug('skillsets1=='+skillsets);
            if(skillsets.isEmpty()){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'No Skillsets assigned for this user'));
                displayList = true;
                displaySave = false;
                return;
            } else {
                displaySave = true;
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select User'));
            displayList = false;
            return;
        }
        displayList = true;
    }
    
    //Delete skillset
    public void deleteSkillset(){
        try{
            if(removeListId != NULL){
                skillsets.remove(removeListId);
            	if(String.isNotBlank(removeId)){
                    Skillset__c skillset = new Skillset__c(Id=(ID)removeId);
                    delete skillset;
                }
            }
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            return;
        }
    }
    
    //Add skillset
    public void assignNewSkill(){
        for(Skillset__c skill: skillsets){
            if(skill.Collection__c == NULL || skill.Training_Completion_Date__c == NULL || skill.Skill__c == NULL){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Collection, Skill and Training Completion Date cannot be NULL'));
                return;
            }
        }
        Skillset__c newSkill = new Skillset__c();
        newSkill.User_Name__c = skillset.User_Name__c;
        newSkill.Training_Completion_Date__c = system.now();
        skillsets.add(newSkill);
        displaySave = true;
    }
    
    //Save skillset
    public PageReference save(){
        try{
            Map<String,Skillset__c> newSkillsets = new Map<String,Skillset__c>();
            List<Skillset__c> upsertSkillsets = new List<Skillset__c>();
            if(!skillsets.isEmpty()){
                system.debug('skillsets=='+skillsets);
                for(Skillset__c skill: skillsets){
                    if(skill.Training_Completion_Date__c > skill.Focus_Start_Date__c || skill.Training_Completion_Date__c > skill.Focus_End_Date__c){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Focus Start Date and Focus End Date should be greater than Target Completion Date'));
                        return null;
                    }
                    if(skill.Focus_Start_Date__c != NULL && skill.Focus_End_Date__c == NULL){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Focus End Date cannot be blank when Focus Start Date is provided'));
                        return null;
                    }
                    if(skill.Focus_Start_Date__c == NULL && skill.Focus_End_Date__c != NULL){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Focus Start Date cannot be blank when Focus End Date is provided'));
                        return null;
                    }
                    if(skill.Focus_Start_Date__c > skill.Focus_End_Date__c){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Focus Start Date cannot be greater than Focus End Date'));
                        return null;
                    }
                    if(skill.User_Name__c != NULL && skill.Collection__c != NULL && skill.Training_Completion_Date__c != NULL && skill.Skill__c != NULL){
                        skill.Id = null;
                        skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
                        if(newSkillsets.containsKey(skill.Skillset_Ext_Id__c)){
                            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'This user already has one of the newly assigned skill and Collection. Please change your selection.'));
                            return null;
                        }
                        newSkillsets.put(skill.Skillset_Ext_Id__c,skill);
                    }
                }
                if(!newSkillsets.isEmpty()){
                	upsertSkillsets = newSkillsets.values();
                    upsert upsertSkillsets Skillset_Ext_Id__c;
                }
            }
            return new PageReference('/'+ Skillset__c.sObjectType.getDescribe().getKeyPrefix());
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            return null;
        }
    }
    
    public PageReference cancel(){
        return new PageReference('/'+ Skillset__c.sObjectType.getDescribe().getKeyPrefix());
    }
}