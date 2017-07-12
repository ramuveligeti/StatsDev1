/**
* @author Ram Veligeti
* @story ECP-2663,2197
* @description 
* Remark		 Steven Zhu 20160908 ECP 3323 post out file name format change
* Amendment      Caterina Cuccurullo 27-04-2017 ECP-3839  add '=' to filter from Extract Schedule. 
*                added schedule_job_id__c = null so that it only selects jobs that haven't run yet.
*                added Scheduled_Date_time__c & CreatedByID  to list of fields to send to ExtractWorkItemsActivitiesBatch  
*                as its used to create the Document Name.      
*/
global class ExtractScheduler implements Schedulable {
	/**
	 * @description Executes the scheduled Apex job. 
	 * @param sc contains the job ID
	 */ 
	global void execute(SchedulableContext sc) {
		Datetime nextDatetime = system.now().addDays(1);
        system.debug ('nextDatetime = ' + nextDatetime);
		List<Extract_Schedule__c> es = [Select Id,
                                        Collection_Type__c,
                                        Output_CSV_Format__c,
                                        Collection_Instance_Id__c,
                                        Work_Item_Type__c,
                                        Delivery_Mode__c,
                                        Activity_Schedule_Id__c,
                                        Scheduled_Date_time__c, 
                                        CreatedByID
                                        from Extract_Schedule__c 
                                        where Scheduled_Date_time__c <= :nextDatetime
                                        //Caterina 28-4-2017 added this extra condition so we get just those that haven't been scheduled
                                        and schedule_job_id__c = null];
		for(Extract_Schedule__c e: es){
			if(e.Collection_Type__c.equalsIgnoreCase('Business')){
				Activity_Schedule__c aSch;
				if(e.Activity_Schedule_Id__c == null){
					aSch = new Activity_Schedule__c();
					aSch.Work_Item_Type__c = e.Work_Item_Type__c;
					aSch.Delivery_Mode__c = e.Delivery_Mode__c;
					aSch.Collection_Instance__c = e.Collection_Instance_Id__c;
					aSch.Output_CSV_Format__c = e.Output_CSV_Format__c;
                    //added passing Scheduled_Date_time__c as its used to create the Document Name
                    aSch.Scheduled_Date_time__c = e.Scheduled_Date_time__c;
				}else{
					aSch = [Select Id,Name,Filter_Name__c,Work_Item_Type__c,Delivery_Mode__c,Collection_Instance__c from Activity_Schedule__c where Id = :e.Activity_Schedule_Id__c];
				}
                system.debug ('Before ExtractWorkItemsActivitiesBatch = ');
				ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(aSch,false);
				//Calculate minutes between current date time and scheduled date time, to schedule batch apex
				system.debug('ID of Extract job e.ID = ' + e.ID);
				system.debug ('Value of e.Scheduled_Date_time__c.getTime() = ' + e.Scheduled_Date_time__c.getTime());
                system.debug ('Value of system.now().getTime() = ' + system.now().getTime());
                Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((e.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
               // added condition - if minutes calculated to negative then extract job is not scheduled
                if (mins < 0){
                   system.debug ('mins  negative this job will not be scheduled, ID =  ' + e.Id + 'mins = ' + mins);                  
                }
                else e.Schedule_Job_Id__c = System.scheduleBatch(batch, 'Extract Work Items '+system.now()+e.Id, mins); 
				
               // e.Schedule_Job_Id__c = System.scheduleBatch(batch, 'Extract Work Items '+system.now()+e.Id, mins);
			}else if(e.Collection_Type__c.equalsIgnoreCase('Census')){
				//Send to mulesoft
				ActivityScheduleExtractClient ase = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Extract, e.Id,3);
			}
		}

		if(!es.isEmpty()){update es;}
	}
}