global class CountResponsesBatch implements Database.Batchable<SObject>, Database.Stateful {
	
	global Collection_Instance__c collectionInstance;
	global final Boolean countNetResponse;
	global final Boolean countNetKeyResponse;
	global final Boolean countKeyResponse;
	global final Boolean countSampleSize;
	global final string query;

	global integer totalSampleResponse=0;
	global integer totalNetResponse=0;
	global integer totalNetKeyResponse=0;
	global integer totalKeyResponse=0;

	global CountResponsesBatch(Id collectionInstanceId, Boolean countSampleSize, Boolean countNetResponse, Boolean countNetKeyResponse, Boolean countKeyResponse) {
		this.countSampleSize = countSampleSize;
		this.countNetResponse = countNetResponse;
		this.countNetKeyResponse = countNetKeyResponse;
		this.countKeyResponse = countKeyResponse;


		collectionInstance =  [select
				Id,
				Sample_Size__c,
				Net_Responses__c,
				Keys_Sample_Size__c,
				Net_Keys__c
			from Collection_Instance__c
			where Id = :collectionInstanceId
		];

		query = 'select id,Response_Status_Reason__c,Mark_in_Required__c,Key__c from Response__c where Collection_Instance__c=\'' + collectionInstanceId + '\'';
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(query);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<Response__c> scope) {
		for(Response__c resp:scope)
		{
			if(countSampleSize && resp.Mark_in_Required__c == true)
			{
				totalSampleResponse++;
			}
			if(countNetResponse && resp.Response_Status_Reason__c != 'Out of Scope')
			{
				totalNetResponse++;
			}
			if(countNetKeyResponse && resp.Response_Status_Reason__c != 'Out of Scope' && resp.Key__c == true)
			{
				totalNetKeyResponse++;
			}
			if(countKeyResponse && resp.Key__c == true)
			{
				totalKeyResponse++;
			}
		}

	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
		if(countSampleSize)
		{
			system.debug('Sample_Size__c size is: ' + totalSampleResponse);
			collectionInstance.Sample_Size__c = totalSampleResponse;
		}

		if(countNetResponse)
		{
			system.debug('Net_Responses__c size is: ' + totalNetResponse);
			collectionInstance.Net_Responses__c = totalNetResponse;
		}

		if(countNetKeyResponse)
		{
			system.debug('Net_Keys__c size is: ' + totalNetKeyResponse);
			collectionInstance.Net_Keys__c = totalNetKeyResponse;
		}

		if(countKeyResponse)
		{
			system.debug('Keys_Sample_Size__c size is: ' + totalKeyResponse);
			collectionInstance.Keys_Sample_Size__c = totalKeyResponse;
		}

		update collectionInstance;


	}
}