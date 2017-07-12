/*author: Ram Veligeti
Date: 12/04/16
*description: This class is called in WorkItemsQueueView page. It fetches and displays all the work items that are waiting for assignment in the below order
1.Any existing In Progress work items
2.Assigned & Scheduled Work Items where callback time < current time
3.Assigned Work Items  where callback time = null
4.appointment & follow-up & skillset based workitems from Unallocated phone work items queue where callback time <= current time
6.work items based on workitem priority from Unallocated phone work items queue
7.appointment and followup assigned work items where callback time > current time
*/
public class WorkItemsQueueView {
    public List<Work_Item__c> workItems{get;Set;}
    public Integer refreshIntervalInSec{get;Set;}
    //Standard controller
    public WorkItemsQueueView(){
		refreshIntervalInSec = 15;
    }

    //Method to fetch all the related work items
    public List<Work_Item__c> getWIs(){
        List<Work_Item__c> workItems1 = new List<Work_Item__c>();
        //Unallocated phone work items queue id
        Id queueId = [Select Id from Group where Type = 'Queue' and DeveloperName = 'Unallocated_Phone_Work_Items'].Id;
        //Query to fetch In progress work items
        List<Work_Item__c> wi0 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c
                                  from Work_Item__c where Status__c = 'In Progress' and Delivery_Mode__c = 'Call' and Response__r.RecordType.Name = 'Business Response' 
                                  and OwnerId !=:queueId and Owner.Type='User' order by Call_Back_Time__c ASC NULLS LAST, Name ASC limit 100];
        if(!wi0.isEmpty()){workItems1.addAll(wi0);}
        //Query to fetch all appointment and followup assigned work items where callback time <= current time
        List<Work_Item__c> wi1 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Response__r.RecordType.Name = 'Business Response' 
                                  and (Appointment__c = true or Follow_up__c = true) and Call_Back_Time__c!= NULL and Call_Back_Time__c<= :System.now() and OwnerId !=:queueId and Owner.Type='User' 
								  order by Call_Back_Time__c ASC,createdDate, Name ASC limit 100];
        if(!wi1.isEmpty()){workItems1.addAll(wi1);}
        //Query to fetch all assigned work items where callback time <= current time or callback time is null
        List<Work_Item__c> wi2 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Response__r.RecordType.Name = 'Business Response' and (Call_Back_Time__c<= :System.now() or Call_Back_Time__c = null)
                                  and Appointment__c = false and Follow_up__c = false and OwnerId !=:queueId  and Owner.Type='User' and Escalated__c = false order by Call_Back_Time__c ASC NULLS LAST,createdDate, Name ASC limit 100];
        if(!wi2.isEmpty()){workItems1.addAll(wi2);}
        //Query to fetch appointment & follow-up & skillset based workitems from Unallocated phone work items queue where callback time <= current time
        List<Work_Item__c> wi3 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Call_Back_Time__c<= :System.now()
                                  and (Appointment__c = true or Follow_up__c = true) and Call_Back_Time__c!= NULL and OwnerId=:queueId and Response__r.RecordType.Name = 'Business Response' 
                                  Order by Appointment__c desc,Follow_up__c desc,Call_Back_Time__c ASC,WI_Priority__c DESC,createdDate ASC, Name ASC limit 100];
        if(!wi3.isEmpty()){workItems1.addAll(wi3);}
        //Query to fetch work items based on workitem priority from Unallocated phone work items queue
        List<Work_Item__c> wi7 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Call_Back_Time__c = NULL
                                  and Appointment__c = false and Follow_up__c = false and OwnerId=:queueId and Response__r.RecordType.Name = 'Business Response' 
                                  Order by WI_Priority__c DESC NULLS LAST, createdDate ASC, Name ASC limit 100];
        if(!wi7.isEmpty()){workItems1.addAll(wi7);}
		Datetime callBackToday = Datetime.newInstance(System.today(),Time.newInstance(23,59,59,0));
        //Query to fetch all appointment and followup assigned work items where callback time > current time
        List<Work_Item__c> wi4 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Response__r.RecordType.Name = 'Business Response' 
                                  and Call_Back_Time__c > :System.now() and (OwnerId =:queueId or Owner.Type='User')
								  order by Call_Back_Time__c ASC,Appointment__c desc,Follow_up__c desc,WI_Priority__c DESC NULLS LAST,createdDate, Name ASC limit 100];
        if(!wi4.isEmpty()){workItems1.addAll(wi4);}
        /*/Query to fetch all assigned work items where callback time > current time
        List<Work_Item__c> wi5 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Response__r.RecordType.Name = 'Business Response' and Call_Back_Time__c > :System.now()
                                  and Appointment__c = false and Follow_up__c = false and OwnerId !=:queueId  and Owner.Type='User' order by Call_Back_Time__c ASC NULLS LAST,createdDate limit 100];
        if(!wi5.isEmpty()){workItems1.addAll(wi5);}
        //Query to fetch appointment & follow-up & skillset based workitems from Unallocated phone work items queue where callback time > current time
        List<Work_Item__c> wi6 = [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Call_Back_Time__c,Response__r.Overall_Priority__c,
                                  Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Response__r.Name,Work_Item_Type__c,Response_Overall_Priority_Factor__c 
                                  from Work_Item__c where Status__c in ('New','Pending') and Delivery_Mode__c = 'Call' and Call_Back_Time__c > :System.now()
                                  and (Appointment__c = true or Follow_up__c = true) and Call_Back_Time__c!= NULL and OwnerId=:queueId and Response__r.RecordType.Name = 'Business Response' 
                                  Order by Call_Back_Time__c ASC,Appointment__c desc,Follow_up__c desc, createdDate ASC limit 100];
        if(!wi6.isEmpty()){workItems1.addAll(wi6);}*/
		return workItems1;
    }

	//This method is called from WorkItemStreamingAPI VF page.
	//Used to query workItem received from cometd. When a work item is updated or created cometd will give the Workitem Id
    @RemoteAction
    public static Work_Item__c fetchWorkItem(String workItemId){
		Id queueId = [Select Id from Group where Type = 'Queue' and DeveloperName = 'Unallocated_Phone_Work_Items'].Id;
        return [Select Id,name,Status__c,Collection_Instance_Name__c,OwnerId,Owner.FirstName,Owner.LastName,UoI_Number__c,Unit__c,LBU__c,Key__c,Birth__c,Response__c,Response__r.Name,Call_Back_Time__c,
                       Response_Statisical_Priority__c,Response_Behavioual_Priority__c,Appointment__c,Follow_up__c,CreatedDate,WI_Priority__c,Work_Item_Type__c,Response_Overall_Priority_Factor__c,Response__r.Overall_Priority__c 
                       from Work_Item__c where Id = :workItemId and (OwnerId =:queueId or Owner.Type='User')];
    }
}