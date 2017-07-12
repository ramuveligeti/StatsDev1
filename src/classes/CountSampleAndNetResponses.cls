/**
* @description This is an class with invocable method 
               to count sample / net sample size for a collection instance
* @author Steven Zhu
* @date 13.Oct.2016
*/
public class CountSampleAndNetResponses
{
    @InvocableMethod(label='Count Sample and Net Responses For CollectionInstance' description='This class is used to count sample net responses for a collection instance, so that It can be used in flow')
    public static void count (List<Id> collectionInstanceIds){
        Id collectionInstanceId = collectionInstanceIds[0];
        System.debug('collection instance id is '+collectionInstanceId);

        // RUN BATCH
        //Changed by Neha Chandra
        //earlier this class was just calculating Sample an Net Response, but during fix of bug 3765 relaized it should calculate net keys as well
        Database.executeBatch(new CountResponsesBatch(collectionInstanceId,true,true,true,false), 2000); 
        
    
    }   
    
}