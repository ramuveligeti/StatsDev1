public class CollectionInstanceClone {
	final Id originalCollectionInstanceId;
	Collection_Instance__c collectionInstance;
	List<ActivityScheduleClone> activitySchedules;
	
	boolean isSocial;

	public CollectionInstanceClone(Collection_Instance__c original) {
		originalCollectionInstanceId = original.Id;
		collectionInstance = cloneCollectionInstance(original);
		
		activitySchedules = new List<ActivityScheduleClone>();
		for(Activity_Schedule__c activitySchedule : queryActivitySchedues(original.Id)) {
			activitySchedules.add(new ActivityScheduleClone(activitySchedule));
		}
		
		isSocial = original.RecordTypeId == Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
	}

	public static Collection_Instance__c cloneCollectionInstance(Collection_Instance__c original) {
		Collection_Instance__c clonedCollectionInstance = new Collection_Instance__c(
			RecordType = original.RecordType,
			RecordTypeId = original.RecordTypeId,
			Collection__c = original.Collection__c,
			Name = original.Name,
			Collection_Instance_Code__c = original.Collection_Instance_Code__c,
			Response_Rate__c = original.Response_Rate__c,
			Grouping__c = original.Grouping__c,
			Contextual_Mappings__c = original.Contextual_Mappings__c,
			Statistical_Weighting__c = original.Statistical_Weighting__c,
			Behavioural_Weighting__c = original.Behavioural_Weighting__c,
			Primary_Mode__c = original.Primary_Mode__c,
			Delivery_Mode__c = original.Delivery_Mode__c,
			Status__c = original.Status__c //'Planned'
		);
		if(original.RecordTypeId == Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId()){
			clonedCollectionInstance.Target_Response_Type__c = original.Target_Response_Type__c;
			if(original.Collection_Number__c != null){
				clonedCollectionInstance.Collection_Number__c = original.Collection_Number__c + 1;
			}
		}
		system.debug('## Cloned CI: ' + clonedCollectionInstance);
		return clonedCollectionInstance;
	}

	List<Activity_Schedule__c> queryActivitySchedues(Id collectionInstanceId) {
		return [
			select Name,Status__c,Scheduled_Date_time__c,Delivery_Mode__c,
				Work_Item_Type__c,Frequency__c,Occurrence__c,Pack__r.Name,
				Output_CSV_Format__r.Name,
				(select Name,Actual_Work_Items_Count__c,Collection__c,
					Completion_Date_time__c,Filter_Criteria__c,
					Filter_Criteria_String__c,Filter_Description__c,Filter_Logic__c,
					Filter_Name__c,QueryString__c,Grouping__c,Scheduled_Date_time__c,
					Status__c
				from Activity_Schedule_Filters__r)
			from Activity_Schedule__c
			where Collection_Instance__c = :collectionInstanceId
		];
	}

	public List<Workload__c> getClonedWorkloads() {
		if (isSocial) {
			list<Workload__c> oldWorkloads = new list<Workload__c>([
				select 	Workload_Type__c, Workload_Status__c, Workload_Priority_Indicator__c, Units_Of_Interest_Report_Household__c, Supervisor__c, 
						Owner_Name__c, OwnerId, Default_Delivery_Mode__c, Default_Address_Type__c, Collection_Instance__c, Area_Unit_Reference__c, 
						Area_Unit_Name__c
						from Workload__c 
						where Collection_Instance__c =: originalCollectionInstanceId]);
			list<Workload__c> clones = new list<Workload__c>();
			for(Workload__c wl : oldWorkloads){
				clones.add(wl.clone(false,true,false,false));
			}
			return clones;
		}
		
		return new Workload__c[]{};
	}

	public Collection_Instance__c getClone() {
		return collectionInstance;
	}

	public List<ActivityScheduleClone> getActivitySchedules() {
		return activitySchedules;
	}

	public String getNewURL() {
		return '/' + collectionInstance.Id;
	}

	public String getOriginalURL() {
		return '/' + originalCollectionInstanceId;
	}

	public Id getId() {
		return collectionInstance.Id;
	}

	public String getRecordType() {
		return collectionInstance.RecordType.Name;
	}

	public List<Activity_Schedule__c> getActivitySchedulesToInsert(Id collectionInstance) {
		List<Activity_Schedule__c> activities = new List<Activity_Schedule__c>();

		for(ActivityScheduleClone activityScheduleClone : activitySchedules) {
			if (!activityScheduleClone.includeInClone) {
				continue;
			}

			Activity_Schedule__c activitySchedule = activityScheduleClone.getActivitySchedule();
			activitySchedule.Collection_Instance__c = collectionInstance;
			activities.add(activitySchedule);
		}

		return activities;
	}

	public List<Activity_Schedule_Filter__c> getFiltersToInsert() {
		List<Activity_Schedule_Filter__c> filters = new List<Activity_Schedule_Filter__c>();

		for(ActivityScheduleClone activitySchedule : activitySchedules) {
			filters.addAll(activitySchedule.getFilters());
		}

		return filters;
	}

	public void rollback() {
		collectionInstance.Id = null;
		for (ActivityScheduleClone activityScheduleClone : activitySchedules) {
			activityScheduleClone.rollback();
		}
	}
}