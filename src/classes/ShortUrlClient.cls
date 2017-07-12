global class ShortUrlClient implements Schedulable {
    static Integer RetryLimit = 3;
    static Integer DelayBeforeRetryInMinutes = 5;
    String collectionInstanceCode;
    Integer retryCount;
    
    public ShortUrlClient(String collectionInstanceCode, Integer retryCount) {
        this.collectionInstanceCode = collectionInstanceCode;
        this.retryCount = retryCount;
    }
    
    global void execute(SchedulableContext context) {
    	// have to be future in a schedule context
        RequestShortUrl(collectionInstanceCode, retryCount);
    }
    
    
    @future(callout = true)
    public static void RequestShortUrl(Id collectionInstance, Integer retryCount) {
    	RequestShortUrlInline(collectionInstance, retryCount);
    }
    
    public static void RequestShortUrlInline(String collectionInstance, Integer retryCount) {
		Map<String,String> queryParams = new Map<String,String>{'collectionInstance-Id' => collectionInstance};
		HttpRequest request = MulesoftConnector.getConnection('ShortUrlGenerator', queryParams, null, collectionInstance, MulesoftConnector.SignatureHash.WithoutBodyHash);
		// additional header for this client
        request.setHeader('Accept', 'text/json');

        // no response body from the remote service

        // remote service is fire and forget, not checking any status return
        Http http = new Http();
        
        try {
            HTTPResponse response = http.send(request);
            system.debug('Status Code: ' + response.getStatusCode());
            checkForRetry(response.getStatusCode(), collectionInstance, retryCount);
        }
        catch (Exception e) {
            checkForRetry(408, collectionInstance, retryCount);
        }
    }
    
    public static void checkForRetry(Integer httpStatusCode, String collectionInstance, Integer retryCount) {
        if (httpStatusCode != 200) {
            if (retryCount < RetryLimit) {
                ScheduleForRetry(collectionInstance, Datetime.now(), retryCount);
            } else {
                SendFailureEmail(collectionInstance, retryCount);
            }
        } else {
        	// update collection-instance to record the successful request timestamp
        	Collection_Instance__c ci = new Collection_instance__c(id=collectionInstance, short_url_request_timestamp__c = system.now());
        	update ci;
           SendSuccsessEmail(collectionInstance);
        }
    }
    
    public static Boolean SendSuccsessEmail(String collectionInstance) {        
        Collection_instance__c[]ci=[select collection_instance_code__c from collection_Instance__c where id = :collectionInstance];
        String plainTextBody = 'Salesforce has successfully generated all Short URLs for Collection Instance: "' 
                                + ((ci.size()>0)?ci[0].collection_instance_code__c:collectionInstance)
             					+ '".';
        return ApexUtility.sendEmail(SystemSettings__c.getInstance('shortUrlClient.notificationEmail'), // recipients
          'Short URL Generation S', plainTextBody, // subject, body
          null, null, null, false); // targetObjectId, templateName, whatId, saveAsActivity
    }
    
    public static Boolean SendFailureEmail(String collectionInstance, Integer retryAttempts) {        
        Collection_instance__c[]ci=[select collection_instance_code__c from collection_Instance__c where id = :collectionInstance];
        String plainTextBody = 'Salesforce was unable to connect with Mulesoft while trying to generate a short URL for collection instance: "' 
            + ((ci.size()>0)?ci[0].collection_instance_code__c:collectionInstance)
            + '".\nThe request was attempted '
            + retryAttempts
            + ' times before sending this email.';
            
        return ApexUtility.sendEmail(SystemSettings__c.getInstance('shortUrlClient.notificationEmail'), // recipients
        	'Short URL Generation Failed', plainTextBody, // subject, body
        	null, null, null, false); // targetObjectId, templateName, whatId, saveAsActivity
    }
    
    public static String ScheduleForRetry(String collectionInstance, Datetime now, Integer retryCount) {
        retryCount++;
        ShortUrlClient shortUrlClient = new ShortUrlClient(collectionInstance, retryCount);
        String tenMinutesFromNow = SheduleStartString(now);
        return system.schedule('Retry_Failed_Short_Url_Generation_' + collectionInstance + tenMinutesFromNow.replace(' ', '_'), tenMinutesFromNow, shortUrlClient);
    }
    
    public static String SheduleStartString(Datetime dt) {
        Datetime theFuture = dt.addMinutes(DelayBeforeRetryInMinutes);
        return '0 ' + theFuture.minute() + ' ' + theFuture.hour() + ' ' + theFuture.day() + ' ' + theFuture.month() + ' ? ' + theFuture.year();
    }
}