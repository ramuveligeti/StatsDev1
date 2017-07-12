/**
* @description Batch Apex to Create Work Items. This is called from CreateWorkItemsExCon class
* @author Ram Veligeti
* @date 2.Apr.2015
*Remark		 Steven Zhu 20160912 ECP 3323 post out file name format change
 * -------------------------------------------------------------------------------------------------------------------------
 * --Change record
 * -------------------------------------------------------------------------------------------------------------------------
 * Date				Developer		UserStory		Change		
 * 02-Nov-2016		Anna Young		Bug ECP-3705(from 2947)	Added a check to the execute function to ensure callbacks and follow up flags  are only added to work items if the delivery mode is call
 * 	
 *
*/
global class CreateWorkItemsBatch implements Database.Batchable<sObject>,Database.stateful{
	static final Map<String,String> collectionType_workItemType_map = new Map<String,String>{
		'Census' => 'Census',
		'Social' => 'Social',
		'Collections' => 'Business'
	};

    global final String Query;
    global final Id OwnerId;
    //global final Set<Id> Activities;
    global Activity_Schedule__c schs;
    global final Id ActivityScheduleFilterId, ActivityScheduleId;
    global Boolean BatchFailed = false;
    global Boolean immediateExtract = false;
    global Integer ActualWorkItemsCount;
    
    global ID workitemRecordTypeID;

    //Constructor
    global CreateWorkItemsBatch(String q, String c, Id asfId, Id actSch, Id oId, Boolean ie){
        system.debug('q=='+q);
        Query = q;
        ActivityScheduleFilterId = asfId;
        ActivityScheduleId = actSch;
        OwnerId = oId;
        ActualWorkItemsCount = 0;
        immediateExtract = ie;
        
        if(String.isNotBlank(ActivityScheduleId)){
        	Activity_Schedule__c[] act=[select collection_instance__r.collection__r.recordtype.Name from Activity_Schedule__c where id = :ActivityScheduleId];
        	if(act!=null && act.size()>0){
        		String collectionRecordType = act[0].collection_instance__r.collection__r.recordtype.Name;
        		String rt = collectionType_workItemType_map.get(collectionRecordType);
        		if( String.isNotBlank(rt)){
        			workitemRecordTypeID = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get(rt).getRecordTypeId();
        		} // else, default to profile master recordtype
        	} else {
        		// default it to the profile master recordtype
        	}
        }
    }
    
    //Start
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    //Execute
    global void execute(Database.BatchableContext BC, List<Response__c> scope){
        try{
            List<Work_Item__c> workItemList = new List<Work_Item__c>();
            String errormsgs;
            //Creating Work Items
			//Calling this query in execute and not in constructor because the user might want to change any of the activity schedule values after scheduling
			//So we want to get the latest values at run time
            schs=[Select Id, Work_Item_Type__c,Delivery_Mode__c,Pack__c from Activity_Schedule__c where Id = : ActivityScheduleId]; //in :Activities];
            if(schs != NULL){
				for(Response__c rs: scope){ //Loop through Response records
                    Work_Item__c wi = new Work_Item__c();
                    wi.Activity_Schedule__c = schs.Id;
                    wi.Response__c = rs.Id;
                    wi.Work_Item_Type__c = schs.Work_Item_Type__c;
                    wi.Delivery_mode__c = schs.Delivery_Mode__c;
                    wi.Pack__c = schs.Pack__c; //ECP-2340
                    wi.status__c='New';
                    if(workitemRecordTypeID != null){
                    	wi.recordtypeid = workitemRecordTypeID;
                    }
                    if(rs.Extension_Date__c != null && rs.Extension_Date__c >= System.today()){
                      
                         if(schs.Delivery_Mode__c.containsIgnoreCase('Call'))
                         {
                            wi.Follow_up__c = true;
                        	wi.Call_Back_Time__c = rs.Extension_Date__c.addDays(1); //ECP-2947  
                         }
                    } 
                    if(schs.Delivery_Mode__c.containsIgnoreCase('Call') && OwnerId!=NULL){
                        wi.OwnerId = OwnerId; // Assign the Ownership to Queue
                    }

                    workItemList.add(wi);
            }
        }

        //Process the List of records
        if(!workItemList.isEmpty()){
            Database.SaveResult[] lsr = Database.insert(workItemList,false);
            Integer recordid = 0;
            //Process the Failure Records to capture in Error Log Object
            for (Database.SaveResult SR : lsr) {
                if (!SR.isSuccess()) {
                    errormsgs += 'Work Item:' + workItemList[recordid].Response__c + ', '+workItemList[recordid].Activity_Schedule__c+', ' + SR.getErrors()[0].getMessage() + '\n';
                }else{ActualWorkItemsCount++;}
                recordid++;
            }
        }

        //Insert in Error Log
        if (errormsgs!=NULL && errormsgs.length() > 0) {
            ApexUtility.RecordErrorLog(errormsgs, NULL, 'Create Work Items - Batch Apex', userinfo.getUserId());
        }
        }catch(exception e){
            //Error logging
            ApexUtility.RecordErrorLog(e.getMessage(), e.getLineNumber(), 'Create Work Items - Batch Apex', userinfo.getUserId());
            if(ActivityScheduleFilterId != NULL){
                Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c(Id=ActivityScheduleFilterId);
                actSchFilter.Status__c = 'Failed';
                actSchFilter.Completion_Date_time__c = system.now();
                update actSchFilter;
            }
            BatchFailed = true;
        }
    }

    //Final Actions
    global void finish(Database.BatchableContext BC){
        if(!String.isEmpty(ActivityScheduleFilterId) && schs != NULL && !BatchFailed){
            schs = [Select Id,Name,Filter_Name__c,Collection_Instance__r.RecordType.Name,Collection_Instance__c,Work_Item_Type__c,Delivery_mode__c,Output_CSV_Format__c,Status__c,Scheduled_Date_time__c,CreatedByID from Activity_Schedule__c where Id = :schs.Id];
            System_Update__c su = System_Update__c.getOrgDefaults();
            su.Execute__c = true;
            update su;

            Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c(Id=ActivityScheduleFilterId);
            actSchFilter.Status__c = 'Completed';
            actSchFilter.Actual_Work_Items_Count__c = ActualWorkItemsCount;
            actSchFilter.Completion_Date_time__c = system.now();
            update actSchFilter;

            List<Activity_Schedule_Filter__c> activitySchFilterList = [ Select  Id, Status__c, Activity_Schedule__r.Status__c
            from    Activity_Schedule_Filter__c
            where   Activity_Schedule__c = :schs.Id];
            List<String> asfStatus = new List<String>();

            for(Activity_Schedule_Filter__c asf: activitySchFilterList){
                if(asf.Status__c!='Scheduled'){
                    asfStatus.add(asf.Status__c);
                }
            }
            if(asfStatus.size()==activitySchFilterList.size()){
                schs.Status__c = 'Completed';
                update schs;
            } else if(activitySchFilterList[0].Activity_Schedule__r.Status__c != 'Executed'){
                schs.Status__c = 'Executed';
                update schs;
            }
            su.Execute__c = false;
            update su;

            if(!immediateExtract){return;}
            if(schs.Output_CSV_Format__c != NULL){
				if(!schs.Collection_Instance__r.RecordType.Name.equalsIgnoreCase('Census')){
					ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(schs,false);
                    //ECP-3764, batch size which was hardcoded as 2000 was updated as configurable value and reduced to 1000, to fix CPU limit error
                    integer batchSize = SystemSettings.getIntegerValue('batchSize.ExtractWorkItems');
					String asyncJobId = Database.executeBatch(batch,batchSize);
				}
            } else {
                Error_log__c el = new Error_log__c();
                el.Process_Name__c = 'Extract Work Item Batch';
                el.Exception_Message__c = 'No Output CSV Format found for the Activit Activity_Schedule__c (Record Id:'+schs.Id+')';
                insert el;
                sendActivityScheduleConfirmationEmail('Extract Work Item Batch',new List<Error_Log__c>{el});
            }
        }
    }
    @testVisible 
    private void sendActivityScheduleConfirmationEmail(String processName, List<Error_log__c> errors) {
        SystemSettings__c notificationEmail = SystemSettings__c.getInstance('workItemExtract.notificationEmail');

        if (notificationEmail == null || String.isBlank(notificationEmail.Value__c)) {
            return;
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { notificationEmail.Value__c };

        if (!errors.isEmpty()) {
            message.subject = processName + ' failed to extract';
            // something fucked up call fronde
            String errorMessage = '';
            for(Error_log__c error : errors){
                if (String.isNotBlank(error.Exception_Message__c)) {
                    errorMessage += '\n' + error.Exception_Message__c;
                }
            }

            message.plainTextBody = 'The system failed to create a work item extract csv for ' + processName + '.\nA partial extract may have been generated.\nThe errors are listed below:\n' + errorMessage;
        }
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.sendEmail(messages);
    }
}