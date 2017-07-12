/*
author:Ram Veligeti
story:ECP-3304
description: This class is scheduled daily at 12 am to execute all the 'activity schedule filter jobs' scheduled for that day
*/
global class ActivityScheduler implements Schedulable{
    global void execute(SchedulableContext sc){
        List<Group> gr =    [Select Id,Name,Type
                                from Group
                                where DeveloperName = 'Unallocated_Phone_Work_Items'
                                and Type = 'Queue'
                            ];
                
        Id OwnerId = (gr.size()>0?gr[0].Id:NULL);
        String query;
        Datetime currentDatetime = system.now().addDays(1);
        List<Activity_Schedule_Filter__c> asfList = [Select Id,
                                                         Scheduled_Date_time__c,
                                                         QueryString__c,
                                                         Activity_Schedule__c,
                                                         Activity_Schedule__r.Collection_Instance_Name__c,
                                                         Activity_Schedule__r.Collection_Instance__c,
                                                         Activity_Schedule__r.Collection_Instance__r.RecordType.Name,
                                                         Immediate_Extract__c 
                                                     from Activity_Schedule_Filter__c 
                                                     where Scheduled_Date_time__c <= :currentDatetime 
                                                     and Status__c = 'Scheduled'];
        system.debug('Activity schedule filter count == ' + asfList.size());
        for(Activity_Schedule_Filter__c asf :asfList){
             //ECP-3816 Activity Scheduler: The activity scheduler is not processed/triggered if the schedule is after the current date(added more condition)
			if(asf.Activity_Schedule__c != NULL && asf.Activity_Schedule__r.Collection_Instance__r.RecordType.Name != NULL && asf.Activity_Schedule__r.Collection_Instance__r.RecordType.Name.equalsIgnoreCase('Census')){
				//Send to mulesoft
				ActivityScheduleExtractClient ase = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Create, asf.Id,3);
				continue;
			}
            CreateWorkItemsBatch cwib = new CreateWorkItemsBatch(asf.QueryString__c,asf.Activity_Schedule__r.Collection_Instance_Name__c,asf.Id,asf.Activity_Schedule__c,OwnerId,asf.Immediate_Extract__c);
            //Calculate minutes between current date time and scheduled date time, to schedule batch apex
            Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((asf.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
            try{
                 //ECP-3816 Activity Scheduler: The activity scheduler is not processed/triggered if the schedule is after the current date(added more condition)
                 if (asf.QueryString__c != NULL && asf.Scheduled_Date_time__c != NULL && asf.Activity_Schedule__c != NULL && asf.Activity_Schedule__r.Collection_Instance_Name__c != NULL && asf.Immediate_Extract__c != NULL){
     				System.scheduleBatch(cwib, 'Create Work Items '+system.now()+asf.Id, mins);
                 }
			}catch(exception e){ApexUtility.RecordErrorLog(e.getMessage(), e.getLineNumber(), 'Create Work Items - Batch Apex', userinfo.getUserId());}
        }
    }
}