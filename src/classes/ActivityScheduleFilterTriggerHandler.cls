/**
* @description Handler class for Activity Schedule Filter object
* @author Ram Veligeti
* @date 5.May.2015
* Remark		 Steven Zhu 20160908 ECP 3323 post out file name format change
*/
public class ActivityScheduleFilterTriggerHandler {
    /**
    * @description This method is called on After Update. Aborts the Scheduled jobs
    * @param actSchFilterNew, is the Map of trigger.new values
    */
    public static void afterUpdate_AbortScheduledJob(Map<Id,Activity_Schedule_Filter__c> actSchFilterNew, Map<Id,Activity_Schedule_Filter__c> actSchFilterOld){
        System_Update__c su = System_Update__c.getOrgDefaults();
        try{
            Set<Id> cronId = new Set<Id>();
            Set<Id> actSchId = new Set<Id>();
            for(Activity_Schedule_Filter__c actSchFil: actSchFilterNew.values()){
                if(actSchFil.Status__c == 'Inactive' && actSchFilterOld.get(actSchFil.Id).Status__c != actSchFil.Status__c && actSchFil.Schedule_Job_Id__c != NULL){
                    cronId.add(actSchFil.Schedule_Job_Id__c);
                    actSchId.add(actSchFil.Activity_Schedule__c);
                }
            }
            
            if(!cronId.isEmpty()){
                for(String jobId: cronId){
                    try{
                        System.abortJob(jobId);
                    } catch (exception e){
                        system.debug('Job doesn\'t exist, It might have been deleted or executed');
                    }
                }
                
                List<Activity_Schedule_Filter__c> activityScheduleFilter = [Select Id, Status__c, Activity_Schedule__c from Activity_Schedule_Filter__c where Activity_Schedule__c in :actSchId];
                Map<Id,List<Activity_Schedule_Filter__c>> actSchMap = new Map<Id,List<Activity_Schedule_Filter__c>>();
                
                for(Activity_Schedule_Filter__c asf: activityScheduleFilter){
                    if(actSchMap.containsKey(asf.Activity_Schedule__c)){
                        actSchMap.get(asf.Activity_Schedule__c).add(asf);
                    } else {
                        actSchMap.put(asf.Activity_Schedule__c, new List<Activity_Schedule_Filter__c>{asf});
                    }
                }
                su.Execute__c = true;
                update su;
                
                List<Activity_Schedule__c> activityScheduleList = new List<Activity_Schedule__c>();
                for(Id ActivityScheduleId:actSchMap.keySet()){
                    Set<Id> asfSet = new Set<Id>();
                    for(Activity_Schedule_Filter__c asf: actSchMap.get(ActivityScheduleId)){
                        if(asf.Status__c != 'Scheduled'){
                            asfSet.add(asf.Id);
                        }
                    }
                    
                    if(asfSet.size()==actSchMap.get(ActivityScheduleId).size()){
                        Activity_Schedule__c actSch = new Activity_Schedule__c(Id=ActivityScheduleId);
                        actSch.Status__c = 'Completed';
                        activityScheduleList.add(actSch);
                    }
                }
                
                if(!activityScheduleList.isEmpty()){
                    update activityScheduleList;
                }
                su.Execute__c = false;
                update su;
            }
        }catch(exception e){
            su.Execute__c = false;
            update su;
            Throw new FormValidationException(e.getMessage());
        }
    }
    
    //@description: When Schedule date time is change the existing job will be aborted and a new job will be scheduled based on the new datetime
    //@date: 18/01/2016
    //@author: Ram Veligeti
    public static void beforeUpdate_ModifyScheduleDatetime(Map<Id,Activity_Schedule_Filter__c> actSchFilterNew, Map<Id,Activity_Schedule_Filter__c> actSchFilterOld){
        List<Activity_Schedule_Filter__c> asfList = new List<Activity_Schedule_Filter__c>();
        Set<Id> actSchId = new Set<Id>();
        for(Activity_Schedule_Filter__c actSchFil: actSchFilterNew.values()){
            if(actSchFil.Status__c != 'Scheduled' && actSchFilterOld.get(actSchFil.Id).Scheduled_Date_time__c != actSchFil.Scheduled_Date_time__c){
                actSchFil.addError('You cannot modify schedule datetime.');
            }
            
            if(actSchFil.Scheduled_Date_time__c != NULL && actSchFil.QueryString__c != NULL && actSchFil.Status__c == 'Scheduled' && actSchFilterOld.get(actSchFil.Id).Scheduled_Date_time__c != actSchFil.Scheduled_Date_time__c && actSchFil.Schedule_Job_Id__c != NULL){
                asfList.add(actSchFil);
                actSchId.add(actSchFil.Activity_Schedule__c);
            }
        }
        
        if(asfList.isEmpty()){return;} 
        
        Map<Id,Activity_Schedule__c> actSchMap = new Map<Id,Activity_Schedule__c>([Select Id,Collection_Instance__c,Pack__c,Output_CSV_Format__c,Work_Item_Type__c,Delivery_Mode__c from Activity_Schedule__c where Id in :actSchId]);
        List<Group> gr =    [Select Id,Name,Type
                             from Group
                             where DeveloperName = 'Unallocated_Phone_Work_Items'
                             and Type = 'Queue'
                            ];
        
        Id OwnerId = (gr.size()>0?gr[0].Id:NULL);
        for(Activity_Schedule_Filter__c actSchFil: asfList){
            try{
                if(!test.isRunningTest()){
                    System.abortJob(actSchFil.Schedule_Job_Id__c);      
                }
				if(actSchFil.Scheduled_Date_time__c.date() < System.today().addDays(1)){
					Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((actSchFil.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
					Boolean immediateExtract = (actSchMap.get(actSchFil.Activity_Schedule__c).Output_CSV_Format__c!=null?true:false);
					CreateWorkItemsBatch cwib = new CreateWorkItemsBatch(actSchFil.QueryString__c,actSchFil.Collection_Instance_Name__c,actSchFil.Id,actSchMap.get(actSchFil.Activity_Schedule__c).Id,OwnerId,immediateExtract);
					actSchFil.Schedule_Job_Id__c = System.scheduleBatch(cwib, 'Create Work Items '+system.now()+actSchFil.Id, mins);
				}
            }catch (exception e){
                Throw new FormValidationException(e.getMessage());
            }
        }
    }

	/**
	* @description: For Census, extracts happens at the mulesoft end. So we need to send the request to mulesoft if the 'Immediate' checkbox is checked while
	*				creating activity schedules
	* @param actSchFilNew - New Activity schedule filters
	* @param actSchFilterOld - Old Activity Schedule filters
	*/
	public static void executeMuleSoftClientForCensus(List<Activity_Schedule_Filter__c> actSchFilNew, List<Activity_Schedule_Filter__c> actSchFilterOld){
		// this is integration, cannot handle bulk...
				
		// only work off the first record.  And only if it belongs to a census collection
		if(actSchFilterOld[0].Status__c != actSchFilNew[0].Status__c && actSchFilNew[0].Status__c == 'Completed' && actSchFilNew[0].Immediate_Extract__c){
			//Send to mulesoft
			// ActivityScheduleExtractClient ase = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Extract, asf.Id,3);
			// we cannot pass the ASF-ID to the client, it will kick off another Creation.

			// We need to create the Extract_Schedule record, and pass the id to the mulesoft client.
			Activity_Schedule_Filter__c filter = [select id, name, Activity_Schedule__c, Activity_Schedule__r.Name, Activity_Schedule__r.Collection_Instance__r.recordtypeid,
				Activity_Schedule__r.Work_Item_Type__c,Activity_Schedule__r.Delivery_Mode__c, Activity_Schedule__r.Collection_Instance__c,
				Activity_Schedule__r.Scheduled_Date_time__c, Activity_Schedule__r.Filter_Name__c, Activity_Schedule__r.Frequency__c,
				Activity_Schedule__r.Output_CSV_Format__c from Activity_Schedule_Filter__c where id =:actSchFilNew[0].Id ];
			
			ID rtid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
			
			// check if this is census
			if(filter.Activity_Schedule__r.Collection_Instance__r.recordtypeid == rtid){
				// call the constructor to create all the soql, extract mapping, etc
				ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(filter.Activity_Schedule__r,false);
				// create a new Extact_Scheudle__c record
				Extract_Schedule__c es = batch.createNewExtractSchedule(filter.Activity_Schedule__r);
				insert es;
				
				// kick off the mulesoft client, run async
				//ActivityScheduleExtractClient.submitRequestAsync('Extract', es.Id, 0);

				//Schedule mulesoft client
				ActivityScheduleExtractClient aceClient = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Extract, es.Id, 0);
				String jobID = aceClient.schedule();
			}
		}
		
	}
}