@RestResource(urlMapping='/SyncMobile/3.0/*')
global with sharing class SyncMobileApi_v3_0 {
	
	@HttpPost
    global static void sync() {
    	if(Logger.isEnabled()){
	    	System.debug('sync started');
	        System.debug('heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
	    }
        String deviceId = RestContext.request.params.get('device_id');
        if(String.isNotBlank(deviceid)){
        	List<Mobile_Sync_Staging__c> existingSyncStaging = [
        		select Job_Id__c 
    			from Mobile_Sync_Staging__c 
    			where 
	    			Mobile_App_Installation_Id__c=:deviceid and
	    			OwnerId=:UserInfo.getUserId()
			];
			delete existingSyncStaging;

        	Mobile_Sync_Staging__c mobileSyncStaging = new Mobile_Sync_Staging__c();
        	mobileSyncStaging.Status__c = 'New';
	        mobileSyncStaging.Mobile_App_Installation_Id__c = deviceid;
	        insert mobileSyncStaging;

	        List<Attachment> attachments = SyncMobileProcess_v3_0.generateAttachments(mobileSyncStaging.Id, 'Request_', null, RestContext.request.requestBody.toString());
			insert attachments;
	        
	        if(Logger.isEnabled()){
	        	System.debug('RestContext.request.requestBody.toString()'+RestContext.request.requestBody.toString());
	        	System.debug('completed processing request. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
	        }

	        PostResponse postResponse = new PostResponse();
	        RestContext.response.headers.put('Content-Type', 'application/json; charset="utf-8"');
	        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(postResponse));
	        RestContext.response.statusCode = 202;
	        
	        if(Logger.isEnabled()){
	        	System.debug('completed processing response. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
	        }

	        SyncMobileProcess_v3_0 mobileSyncProcess = new SyncMobileProcess_v3_0(mobileSyncStaging.Id);
	        mobileSyncStaging.Job_Id__c = System.enqueueJob(mobileSyncProcess);
	        update mobileSyncStaging;
        }else{
        	RestContext.response.headers.put('Content-Type', 'application/json; charset="utf-8"');
        	RestContext.response.statusCode = 400;
		    RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Device id was not provided"}');
        }   
    }

    @HttpGet
    global static void getResults() {
    	RestContext.response.headers.put('Content-Type', 'application/json; charset="utf-8"');
    	String deviceid = RestContext.request.params.get('device_id');
    	if(String.isNotBlank(deviceid)){
    		try{
	    		Mobile_Sync_Staging__c mobileSyncStaging = [
	    			select Job_Id__c, Status__c
	    			from Mobile_Sync_Staging__c 
	    			where 
	    			Mobile_App_Installation_Id__c=:deviceid and
	    			OwnerId=:UserInfo.getUserId()
    			];

    			if(Logger.isEnabled()){
    				System.debug('found mobile sync staging record');
    			}

	    		if(mobileSyncStaging.Status__c.equals('Completed')){
	    			List<Attachment> attachments = [
	    				select Name, Body 
	    				from Attachment 
		    			where 
		    				ParentId=:mobileSyncStaging.Id and
		    				Name like 'Response_%'
		    			order by Name asc
	    			];
	    			if(Logger.isEnabled()){
	    				System.debug('found attachments '+attachments.size());
	    			}
	    			RestContext.response.statusCode = 200;
		            RestContext.response.responseBody = Blob.valueOf(SyncMobileProcess_v3_0.generateJson(attachments));
    			}else{
					List<AsyncApexJob> jobs = [select Status from AsyncApexJob where ID =: mobileSyncStaging.Job_Id__c];
					if(jobs!=null && jobs.size()==1){
						AsyncApexJob job = jobs.get(0);
						if(job.Status.equals('Failed')){
				            RestContext.response.statusCode = 500;
				            RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Job has failed"}');
		    			}else if(job.Status.equals('Aborted')){
				            RestContext.response.statusCode = 500;
				            RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Job has been aborted"}');
		    			}else{
		    				if(Logger.isEnabled()){
		    					System.debug('job is still in progress');
		    				}
				            RestContext.response.statusCode = 202;
				            RestContext.response.responseBody = Blob.valueOf('{"status":"in progress"}');
		    			}
					}
				} 
	    	}catch(System.QueryException e){
	            RestContext.response.statusCode = 400;
	            RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Failed to find existing process for provided device id '+deviceid+'"}');
	    	}

		}else{
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Device id was not provided"}');
		}
    }

    private class PostResponse{
    	Integer waitTimeInterval = 5000;
    }
}