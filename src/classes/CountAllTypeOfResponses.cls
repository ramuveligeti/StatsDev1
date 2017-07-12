/**
* @description This is an class with invocable method 
               to count all types response count for a collection instance
* @author Steven Zhu
* @date 7.Nov.2016
*/
public class CountAllTypeOfResponses 
{
	@InvocableMethod(label='Count all types of Responses For CollectionInstance' description='This class is used to count all types of responses for a collection instance, so that It can be used in flow')
	public static void count (List<Id> collectionInstanceIds){
		Id collectionInstanceId = collectionInstanceIds[0];
		System.debug('collection instance id is '+collectionInstanceId);

		// RUN BATCH IF NOT in BATCH
		if(!system.isFuture() && !system.isBatch())
		{
			Database.executeBatch(new CountResponsesBatch(collectionInstanceId,true,true,true,true), 2000); 
		}else{
			System.debug('Batch job is already running for: '+collectionInstanceId);
		}
    
    }	
	
}