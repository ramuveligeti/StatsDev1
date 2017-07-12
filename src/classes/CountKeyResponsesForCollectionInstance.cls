/**
* @description This is an class with invocable method 
               to count key response count for a collection instance
* @author Steven Zhu
* @date 13.Oct.2016
*/
public class CountKeyResponsesForCollectionInstance 
{
	@InvocableMethod(label='Count Key and Net key Responses For CollectionInstance' description='This class is used to count Key and Net Key responses for a collection instance, so that It can be used in flow')
	public static void count (List<Id> collectionInstanceIds){
		Id collectionInstanceId = collectionInstanceIds[0];
		System.debug('collection instance id is '+collectionInstanceId);

		// RUN BATCH
		Database.executeBatch(new CountResponsesBatch(collectionInstanceId,false,false,true,true), 2000); 
    
    }	
	
}