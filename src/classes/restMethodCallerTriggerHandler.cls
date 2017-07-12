/**
 * @description Developed for user story CAI-39 because mulesoft was unable to invoke Salesforce Restful APIs
 * If Mulesoft is ever able to successfully invoke Restful APIs then this class should be removed
 * 
 * @author Anna Young
 * @date 11.11.2016
 * 
 * 
**/
public class restMethodCallerTriggerHandler {
    public void processUpdate(Rest_Method_Caller__c restMethodCaller){
        if (restMethodCaller.run_rest_method__c)
        {
            string json = restMethodCaller.rest_request_body__c;
             RestContext.request = new RestRequest();
    RestContext.request.requestBody = Blob.valueOf(json);

    SocialRESTfulSyncInterfaceV1.upsertSocialDetails();   
           restMethodCaller.run_rest_method__c =false; 
            restMethodCaller.rest_request_body__c ='';
        }
        
    }
}