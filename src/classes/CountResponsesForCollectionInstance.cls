/**
* @description This is an class with invocable method 
               to count net sample size, key response count, net key response count for a collection instance
* @author Steven Zhu
* @date 06.Oct.2016
*/
public class CountResponsesForCollectionInstance 
{
	@InvocableMethod(label='Count Responses For CollectionInstance' description='This class is used to count responses for a collection instance, so that It can be used in flow')
	public static void count (List<Id> collectionInstanceIds){
		Id collectionInstanceId = collectionInstanceIds[0];
		System.debug('collection instance id is '+collectionInstanceId);

		// RUN BATCH
		Database.executeBatch(new CountResponsesBatch(collectionInstanceId,false,true,true,true), 2000); 
    
    }
	
}