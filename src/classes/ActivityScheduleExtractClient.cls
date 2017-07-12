global class ActivityScheduleExtractClient implements Schedulable{

	private static Integer retryLimit = 3;
	private static Integer delayBeforeRetryInMinutes = 5;
	private Integer retryCount;
	private ID scheduleID;
	private Mode mode;

	private static Activity_Schedule_Filter__c actSchFilter;
	private static Activity_Schedule_Filter__c getActivityScheduleFilter(Id id){
		if(actSchFilter==null && id.getSobjectType() == Schema.Activity_Schedule_Filter__c.SObjectType){
			actSchFilter = [
				select  QueryString__c, Activity_Schedule__c, Work_Item_Type__c, Delivery_Mode__c, Activity_Schedule__r.Name, 
					Activity_Schedule__r.Scheduled_Date_time__c, Activity_Schedule__r.Frequency__c
				from Activity_Schedule_Filter__c 
				where Id =:id
			];
		}
		return actSchFilter;
	}

	private static Extract_Schedule__c extSch;
	private static Extract_Schedule__c getExtractSchedule(Id id){
		if(extSch==null && id.getSobjectType() == Schema.Extract_Schedule__c.SObjectType){
			extSch = [
				select SOQL_String__c, CSV_Header__c, File_Name__c, Field_Mapping__c, Scheduled_Date_time__c, Frequency__c
				from Extract_Schedule__c 
				where Id =: id
			];
		}
		return extSch;
	}

	public enum Mode{
		Create,
		Extract
	}

	

	public ActivityScheduleExtractClient (Mode mode, Id scheduleID, Integer retryCount) {
		// requestId can either be ActivityScheduleFilterId, or ExtractSchedule
		this.mode = mode;
		this.ScheduleID = scheduleID;
		this.retryCount = retryCount;
		//submitRequestAsync(mode.name(), scheduleID, retryCount);

		actSchFilter = getActivityScheduleFilter(scheduleID);
		extSch = getExtractSchedule(scheduleID);
	}

	public String schedule(){
		Datetime startDateTime;
		String frequency;
		String name;

		actSchFilter = getActivityScheduleFilter(scheduleID);
		extSch = getExtractSchedule(scheduleID);

		if(actSchFilter != null) {
			startDateTime = actSchFilter.Activity_Schedule__r.Scheduled_Date_time__c;
			frequency = actSchFilter.Activity_Schedule__r.Frequency__c;
			name = actSchFilter.Activity_Schedule__r.Name;
		}else if(extSch != null){
			startDateTime = extSch.Scheduled_Date_time__c;
			frequency = extSch.Frequency__c;
			name = extSch.Scheduled_Date_time__c.format();
		}
		 
				
		// Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
		System.debug('startDateTime = '+startDateTime+', frequency = '+frequency+', name = '+name+', user = '+UserInfo.getUserName());

		String sch = startDateTime.second()+' '+startDateTime.minute()+' '+startDateTime.hour()+' ';

		if(frequency==null || frequency=='Once'){
			sch += 	startDateTime.day()+' '+startDateTime.month()+' ? '+startDateTime.year();
		}else if(frequency == 'Daily'){
			sch += '* * ? *';
		}else if(frequency == 'Weekly'){
			Map<String, Integer> weekdays = new Map<String, Integer>();
			weekdays.put('Sunday', 1);
			weekdays.put('Monday', 2);
			weekdays.put('Tuesday', 3);
			weekdays.put('Wednesday', 4);
			weekdays.put('Thursday', 5);
			weekdays.put('Friday', 6);
			weekdays.put('Saturday', 7);

			String weekDay = startDateTime.format('EEEE');
			Integer weekDayInt =  weekdays.get(weekDay);

			sch += '? * '+weekDayInt+' *';
		}else if(frequency == 'Monthly'){
			sch += startDateTime.day()+' * ? *';
		}

		System.debug('Schedule cron: '+sch);
		String jobID = System.schedule('Extract workitems: '+name, sch, this);
		return jobID;
	}

	global void execute(SchedulableContext context) {
		//submitRequest(mode, scheduleID, retryCount);
		submitRequestAsync(mode.name(), scheduleID, retryCount);
	}



	// scheduleID is a Salesforce-id that can either be ActivityScheudleFilter, or ExtractSchedule
	public static void submitRequest(Mode mde, String scheduleID, Integer retryCount) {
		if(String.isNotBlank(scheduleID)){
			actSchFilter = getActivityScheduleFilter(scheduleID);
			extSch = getExtractSchedule(scheduleID);

			Id censusRecordTypeId = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
			
			RequestBody req= new RequestBody();
			String envName = SystemSettings.getValue('environment.name');
			if(envName.equals('prod')){
				Organization org = [select IsSandbox from Organization];
				if(org.IsSandbox){
					//Environment name is set to prod in the sandbox. This can be result of refresh.
					throw new SystemSettingsException('environment.name is set to "prod" in the sandbox');
				}
			}

			req.environmentName = envName;
			req.workItemFields = new Map<String, String>();
			req.mode = mde.name();
			req.upsertObjectType = 'Work_Item__c';
			if(mde.equals(Mode.Create)){
				req.workItemFields.put('Status__c', 'New');
				req.batchSize = SystemSettings.getIntegerValue('batchSize.activitySchedule');
			}else if(mde.equals(Mode.Extract)){
				req.workItemFields.put('Status__c', 'Completed');
				req.batchSize = SystemSettings.getIntegerValue('batchSize.extract');
			}

			System.debug('actSchFilter '+actSchFilter);
			System.debug('extSch '+extSch);

			Decimal runCount = 0;

			if(actSchFilter != null) {
				req.soqlString = actSchFilter.QueryString__c;
				req.queryObjectType = 'Response__c';
				req.workItemFields.put('Activity_Schedule__c', actSchFilter.Activity_Schedule__c);
				req.workItemFields.put('Work_Item_Type__c', actSchFilter.Work_Item_Type__c);
				req.workItemFields.put('Delivery_Mode__c', actSchFilter.Delivery_Mode__c);
				req.workItemFields.put('RecordTypeId', censusRecordTypeId);
				req.externalId = actSchFilter.Id;
			} else if(extSch != null){
				req.soqlString = extSch.SOQL_String__c;
				req.queryObjectType = 'Work_Item__c';
				req.extractHeader = extSch.CSV_Header__c;
				req.fieldMapping = extSch.Field_Mapping__c;
				req.extractFileName = extSch.File_Name__c;
			}

			String requestBodyJSON = JSON.serialize(req);
			//System.debug('requestBodyJSON = '+requestBodyJSON);

			Map<String,String> queryParams = null;
			HttpRequest request = MulesoftConnector.getConnection('ActivityScheduleExtract', queryParams, requestBodyJSON, requestBodyJSON, MulesoftConnector.SignatureHash.WithBodyHash);
			request.setHeader('Accept', 'application/json');

			// remote service is fire and forget, not checking any response body
			Http http = new Http();
			
			try {
				if(Logger.isEnabled()){
					System.debug('request: '+request);
					System.debug('request body: '+request.getBody());
				}
				HTTPResponse response = http.send(request);
				if(Logger.isEnabled()){
					System.debug('Status Code: ' + response.getStatusCode()+', response body: '+response.getBody());
				}
				checkForRetry(mde, response.getStatusCode(), scheduleID, retryCount);
			}
			catch (Exception e) {
				System.debug('Exception: '+e + ', ' + e.getStackTraceString());
				checkForRetry(mde, 408, scheduleID, retryCount);
			}
		}else{
			sendFailureEmail(scheduleID, retryLimit);
			return;
		}
	}

	@future(callout=true)
	public static void submitRequestAsync(String modeStr, String scheduleId, Integer retryCount) {
		Mode mde;
		for (Mode m: Mode.values()) {
			if (m.name().equals(modeStr)) {
				mde = m;
				break;
			}
		}
		submitRequest(mde, scheduleId, retryCount);
	}

	@testVisible
	public class RequestBody{
		public String environmentName {set;get;}
		public String soqlString {set;get;}
		public String mode{set;get;}
		public Integer batchSize{set;get;}
		public String queryObjectType{set;get;}
		public String upsertObjectType{set;get;}
		public String externalId {set;get;}
		public String extractFileName {set;get;}
		public String fieldMapping {set;get;}
		public String extractHeader {set;get;}
		public Map<String,String> workItemFields{set;get;}
	}

	public static void checkForRetry(Mode mode, Integer httpStatusCode, String scheduleId, Integer retryCount) {
		if (httpStatusCode != 200) {
			if (retryCount < RetryLimit) {
				scheduleForRetry(mode, scheduleId, Datetime.now(), retryCount);
			}
			else {
				sendFailureEmail(scheduleId, retryCount);
			}
		}
	}

	public static Boolean sendFailureEmail(String scheduleId, Integer retryAttempts) {
		String plainTextBody = 'Salesforce was unable to connect with Mulesoft while trying to kick off the activity-schedule/extract on this id: ' + scheduleId 
			+ '.\nThe request was attempted '
			+ retryAttempts
			+ ' times before sending this email.';
							
		return ApexUtility.sendEmail(SystemSettings__c.getInstance('fileMergeClient.notificationEmail'), // recipients
			'ActivitySchdule/Extract Request Failed', plainTextBody, // subject, body
			null, null, null, false); // targetObjectId, templateName, whatId, saveAsActivity
	}

	public static String scheduleForRetry(String jobname, Mode mode, String scheduleId, Datetime now, Integer retryCount) {
		retryCount++;
		ActivityScheduleExtractClient job = new ActivityScheduleExtractClient(mode, scheduleId, retryCount);
		String tenMinutesFromNow = sheduleStartString(now);
		return system.schedule(jobname, tenMinutesFromNow, job);
	}

	public static String scheduleForRetry(Mode mode, String scheduleId, Datetime now, Integer retryCount) {
		String dateStr = now.year()+'-'+now.month()+'-'+now.day()+'T'+now.hour()+'-'+now.minute()+'-'+now.second()+'-'+now.millisecond();
		return scheduleForRetry('Retry_Failed_ActSchExtRequest-'+dateStr, mode, scheduleId, now, retryCount);
	}

	public static String sheduleStartString(Datetime dt) {
		Datetime theFuture = dt.addMinutes(DelayBeforeRetryInMinutes);
		return '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
	}
}