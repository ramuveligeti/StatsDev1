global class FileMergeClient implements Schedulable{
	private static Integer retryLimit = 3;
	private static Integer delayBeforeRetryInMinutes = 5;
	private String collectionInstanceCode;
	private String[] documentIds;
	private Integer retryCount;

	public FileMergeClient(String collectionInstanceCode, String[] documentIds, Integer retryCount) {
		this.retryCount = retryCount;
		this.documentIds = documentIds;
		this.collectionInstanceCode = collectionInstanceCode;
	}
	
	global void execute(SchedulableContext context) {
		submitFileMergeRequest_async(collectionInstanceCode, documentIds, retryCount);
	}
	
	@future(callout=true)
	public static void submitFileMergeRequest_async(String collectionInstanceCode, String[] documentIds, Integer retryCount) {
		submitFileMergeRequest(collectionInstanceCode, documentIds, retryCount);
	}
	
	public static void submitFileMergeRequest(String collectionInstanceCode, String[] documentIds, Integer retryCount) {
		if(documentIds!=null && !documentIds.isEmpty()){
			Map<String,String> queryParams = null;

			List<RequestContainer> containerList = new List<RequestContainer>();
			for(String documentId:documentIds){
				containerList.add(new RequestContainer(collectionInstanceCode, documentId));
			}
			String requestBodyJSON = JSON.serialize(containerList);
			System.debug('requestBodyJSON = '+requestBodyJSON);

			//
			HttpRequest request = MulesoftConnector.getConnection('FileMerge', queryParams, requestBodyJSON, requestBodyJSON, MulesoftConnector.SignatureHash.WithBodyHash);
			request.setHeader('Accept', 'application/json');

			// remote service is fire and forget, not checking any response body
			Http http = new Http();
			
			try {
				System.debug('request endpoint = '+request.getEndpoint());
				System.debug('request body = '+request.getBody());
				HTTPResponse response = http.send(request);
				System.debug('Status Code: ' + response.getStatusCode()+', response body: '+response.getBody());
				checkForRetry(response.getStatusCode(), collectionInstanceCode, documentIds, retryCount);
			}
			catch (Exception e) {
				System.debug('Exception: '+e);
				checkForRetry(408, collectionInstanceCode, documentIds, retryCount);
			}
		}else{
			sendFailureEmail(collectionInstanceCode, documentIds, retryCount);
			return;
		}
	}
	
	public static void checkForRetry(Integer httpStatusCode,String collectionInstanceCode, String[] documentIds, Integer retryCount) {
		if (httpStatusCode != 200) {
			if (retryCount < RetryLimit) {
				scheduleForRetry(collectionInstanceCode, documentIds, Datetime.now(), retryCount);
			}
			else {
				sendFailureEmail(collectionInstanceCode, documentIds, retryCount);
			}
		}
	}
	
	public static Boolean sendFailureEmail(String collectionInstanceCode, String[] documentIds, Integer retryAttempts) {
		String plainTextBody = 'Salesforce was unable to connect with Mulesoft while trying to kick off the file merge' 
			+ '.\nThe request was attempted '
			+ retryAttempts
			+ ' times before sending this email.'
			+ '\n\nCollection Insance Code: '+collectionInstanceCode;
		
		if(documentIds!=null && !documentIds.isEmpty()){
			plainTextBody += '\n\n List of document-ids: ';
			for (String x: documentIds){ 
				plainTextBody += '\n';
				plainTextBody += x;
			}
		} else {
			plainTextBody += '\n\n Missing document-Ids for sending request to Mulesoft';
		}
		
        return ApexUtility.sendEmail(SystemSettings__c.getInstance('fileMergeClient.notificationEmail'), // recipients
        	'File Merge Request Failed', plainTextBody, // subject, body
        	null, null, null, false); // targetObjectId, templateName, whatId, saveAsActivity
	}

	public static String scheduleForRetry(String jobname, String collectionInstanceCode, String[] documentIds, Datetime now, Integer retryCount) {
		retryCount++;
		FileMergeClient job = new FileMergeClient(collectionInstanceCode, documentIds, retryCount);
		String tenMinutesFromNow = sheduleStartString(now);
		return system.schedule(jobname, tenMinutesFromNow, job);
	}
	
	public static String scheduleForRetry(String collectionInstanceCode, String[] documentIds, Datetime now, Integer retryCount) {
		String dateStr = now.year()+'-'+now.month()+'-'+now.day()+'T'+now.hour()+'-'+now.minute()+'-'+now.second()+'-'+now.millisecond();
		return scheduleForRetry('Retry_Failed_FileMergeRequest-'+dateStr, collectionInstanceCode, documentIds, now, retryCount);
	}
	
	public static String sheduleStartString(Datetime dt) {
		Datetime theFuture = dt.addMinutes(DelayBeforeRetryInMinutes);
		return '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
	}
	
	@testVisible
	private class RequestContainer{
		private String collectionInstanceCode;
		private String documentId;

		public RequestContainer(String collectionInstanceCode, String documentId){
			this.collectionInstanceCode = collectionInstanceCode;
			this.documentId = documentId;
		}
	}
}