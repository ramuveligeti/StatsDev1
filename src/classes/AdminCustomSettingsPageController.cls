/** using without sharing, so we don't have to give users the "customize application" permission
*/
public without sharing class AdminCustomSettingsPageController {

    public static final set<String> adminUpdatableSettings = new set<String>{
        'CnL.workitem.queue', 
        'fileMergeClient.notificationEmail', 
        'shortUrlClient.notificationEmail', 
        'workItemExtract.notificationEmail', 
        'rolloverBatch.notificationEmail',
        'zeacom.blocking.duration'
    };


    public SystemSettings__c[] editableCustomSettings {get; private set;}
    public boolean readonly {get;set;}
    
    public AdminCustomSettingsPageController(){
        editableCustomSettings = new SystemSettings__c[]{};
        for(String s: adminUpdatableSettings){
            SystemSettings__c c = SystemSettings__c.getInstance(s);
            if(c!=null){ editableCustomSettings.add(c); }
        }
        readonly = true;
    }
    
    public void edit(){readonly = false;}
    public void cancel(){readonly = true;}
    
    public void save(){
        try{
            update editableCustomSettings;
            readonly = true;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
    }
}