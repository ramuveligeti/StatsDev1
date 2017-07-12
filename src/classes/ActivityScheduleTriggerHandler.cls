//@author: Ram Veligeti
//@date: 19/01/2016
//description: This class is called from ActivityScheduleTrigger
public class ActivityScheduleTriggerHandler {

    //When Activity Schedule filters (Scheduled datetime, Frequency, Occurrence) are updated then the Activity Schedule Jobs are deleted and recreated with the new filter criteria
    //Only jobs with Scheduled status are deleted
    public static void beforeUpdate_UpdateActivityScheduleFilter(Map<Id, Activity_Schedule__c> newActivityScheduleMap, Map<Id, Activity_Schedule__c> oldActivityScheduleMap) {
        Map<Id, Activity_Schedule__c> asMap = new Map<Id, Activity_Schedule__c> ();
        for (Activity_Schedule__c activitySchedule : newActivityScheduleMap.values()) {
            if (activitySchedule.Frequency__c != oldActivityScheduleMap.get(activitySchedule.id).Frequency__c ||
                activitySchedule.Occurrence__c != oldActivityScheduleMap.get(activitySchedule.id).Occurrence__c ||
                activitySchedule.Scheduled_Date_time__c != oldActivityScheduleMap.get(activitySchedule.id).Scheduled_Date_time__c) {
                if (activitySchedule.Scheduled_Date_time__c < System.now()) {
                    activitySchedule.Scheduled_Date_time__c.addError('Schedule Date time must be in future');
                    return;
                }
                asMap.put(activitySchedule.Id, activitySchedule);
            }
        }

        if (asMap.isEmpty()) { return; }

        Set<Id> cronId = new Set<Id> ();

        //Query scheduled jobs for the Schedule job id
        List<Activity_Schedule_Filter__c> asfList = [Select Id, Schedule_Job_Id__c, Scheduled_Date_time__c from Activity_Schedule_Filter__c where Activity_Schedule__c in :asMap.values() and Status__c = 'Scheduled'];
        for (Activity_Schedule_Filter__c asf : asfList) {
            cronId.add(asf.Schedule_Job_Id__c);
        }

        //if (cronId.isEmpty()) { return; }

        for (String jobId : cronId) {
            try { //Abort scheduled jobs
                System.abortJob(jobId);
            } catch(exception e) {
                system.debug('Job doesn\'t exist, It might have been deleted or executed');
            }
        }

        //The scheduled job might have got executed while executing this process. So quering it again to get the actual scheduled jobs list
        List<Activity_Schedule_Filter__c> asfListNew = [Select Id, Schedule_Job_Id__c, Scheduled_Date_time__c from Activity_Schedule_Filter__c where Activity_Schedule__c in :asMap.values() and Status__c = 'Scheduled'];
        delete asfListNew;

        List<Activity_Schedule_Filter__c> actSchFilterList = new List<Activity_Schedule_Filter__c> ();

        for (Activity_Schedule__c actSch : newActivityScheduleMap.values()) {
            if (actSch.Frequency__c == NULL) actSch.Frequency__c = 'Once';
            if (actSch.Occurrence__c == NULL) actSch.Occurrence__c = 1;

            Datetime scheduleDatetime = actSch.Scheduled_Date_time__c;
            Map<Datetime, Id> actSchFilterDatetimeMap = new Map<Datetime, Id> ();
            Map<Id, Id> asyncJobMap = new Map<Id, Id> ();

            for (integer i = 1; i <= actSch.Occurrence__c; i++) {
                //Capture the filter details in Activity Schedule filter object
                Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
                actSchFilter.Activity_Schedule__c = actSch.Id;
                actSchFilter.QueryString__c = actSch.QueryString__c;
                actSchFilter.Scheduled_Date_time__c = scheduleDatetime;
                actSchFilter.Status__c = 'Scheduled';
                actSchFilterList.add(actSchFilter);

                if (actSch.Frequency__c == 'Daily') {
                    scheduleDatetime = scheduleDatetime.addDays(1);
                }
                if (actSch.Frequency__c == 'Weekly') {
                    scheduleDatetime = scheduleDatetime.addDays(7);
                }
                if (actSch.Frequency__c == 'Fortnightly') {
                    scheduleDatetime = scheduleDatetime.addDays(14);
                }
                if (actSch.Frequency__c == 'Monthly') {
                    scheduleDatetime = scheduleDatetime.addMonths(1);
                }
            }
        }
        if(Logger.isEnabled()){
        	System.debug('Creating filters: '+actSchFilterList.size());
        }
        if (!actSchFilterList.isEmpty()) {
            insert actSchFilterList;
        }

        List<Group> gr = [Select Id, Name, Type
                          from Group
                          where DeveloperName = 'Unallocated_Phone_Work_Items'
                          and Type = 'Queue'
                         ];

        Id OwnerId = (gr.size() > 0 ? gr[0].Id : NULL);
        for (Activity_Schedule_Filter__c asf : actSchFilterList) {
            if (asf.QueryString__c != NULL && asf.Scheduled_Date_time__c != NULL && asf.Activity_Schedule__c != NULL && asf.Scheduled_Date_time__c.date() < System.today().addDays(1)) {
                //Calculate minutes between current date time and scheduled date time, to schedule batch apex
                Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((asf.Scheduled_Date_time__c.getTime() - system.now().getTime())) / (1000.0 * 60.0)));
                system.debug('minss==' + mins + '==' + asf.Scheduled_Date_time__c.getTime() + '==' + system.now().getTime());
                Boolean immediateExtract = (asMap.get(asf.Activity_Schedule__c).Output_CSV_Format__c!=null?true:false);
                //Schedule Batch Apex
                CreateWorkItemsBatch cwib = new CreateWorkItemsBatch(asf.QueryString__c, asf.Collection_Instance_Name__c, asf.Id, asMap.get(asf.Activity_Schedule__c).Id, OwnerId, immediateExtract);
                asf.Schedule_Job_Id__c = System.scheduleBatch(cwib, 'Create Work Items ' + system.now() + asf.Id, mins);
            }
        }

        if (!actSchFilterList.isEmpty()) {
            update actSchFilterList;
        }
    }
}