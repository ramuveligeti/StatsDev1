public class ActivityScheduleClone {
    final Activity_Schedule__c activitySchedule;
    List<Activity_Schedule_Filter__c> activityScheduleFilters;
    public Boolean includeInClone { get; set; }

    public ActivityScheduleClone(Activity_Schedule__c original) {
        includeInClone = false;

        activitySchedule = new Activity_Schedule__c(
            Status__c = 'Scheduled',
            Scheduled_Date_time__c = original.Scheduled_Date_time__c,
            Delivery_Mode__c = original.Delivery_Mode__c,
            Work_Item_Type__c = original.Work_Item_Type__c,
            Frequency__c = original.Frequency__c,
            Occurrence__c = original.Occurrence__c,
            Pack__c = original.Pack__c,
            Output_CSV_Format__c = original.Output_CSV_Format__c
        );

        // We want the user to set these dates manually.
        // Automating this step is out of scope at this point.
        activitySchedule.Scheduled_Date_time__c = null;
        activityScheduleFilters = new List<Activity_Schedule_Filter__c>();
        for (Activity_Schedule_Filter__c activityScheduleFilter : original.Activity_Schedule_Filters__r) {
            Activity_Schedule_Filter__c filterClone = activityScheduleFilter.clone();
            filterClone.Status__c = 'Scheduled';
            activityScheduleFilters.add(filterClone);
        }
    }

    public List<Activity_Schedule_Filter__c> getFilters() {
        if (!includeInClone) {
            return new List<Activity_Schedule_Filter__c>();
        }

        if (!wasInserted()) {
            return new List<Activity_Schedule_Filter__c>();
        }

        List<Activity_Schedule_Filter__c> filters = new List<Activity_Schedule_Filter__c>();

        for(Activity_Schedule_Filter__c filter : activityScheduleFilters) {
            filter.Activity_Schedule__c = activitySchedule.Id;
            filters.add(filter);
        }

        return filters;
    }

    public Activity_Schedule__c getActivitySchedule() {
        return activitySchedule;
    }

    public Boolean wasInserted() {
        return activitySchedule.Id != null;
    }

    public void rollback() {
        activitySchedule.Id = null;
        for(Activity_Schedule_Filter__c filter : activityScheduleFilters) {
            filter.Id = null;
        }
    }
}