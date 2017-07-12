/* @description: This class is called from DeleteActivityScheduleVF page
 * @author: Ram Veligeti
 * @date: 14/01/2016
 **/

public class DeleteActivitySchedule {
    public Activity_Schedule__c actSch{get;set;}
    public Boolean warningWI{get;set;}
    public DeleteActivitySchedule(ApexPages.StandardController stdCont){
        actSch = (Activity_Schedule__c)stdCont.getRecord();
        warningWI = false;
    }
    
    public void deleteActionMethod(){
        List<Work_Item__c> wiList = [Select Id,Status__c from Work_Item__c where Activity_Schedule__c = :actSch.Id and Status__c != 'New' limit 1];
        if(!wiList.isEmpty()){
            warningWI = true;
        }else{
            warningWI = false;
        }
    }

    public PageReference deletionOfWorkItemsAndActivityScheduleFilters(){
        actSch.Status__c = 'Deleted';
        update actSch;
        DeleteActivityScheduleWIBatch asWI = new DeleteActivityScheduleWIBatch(actSch);
        Database.executeBatch(asWI);
        return new PageReference('/'+actSch.Collection_Instance__c);
    }
}