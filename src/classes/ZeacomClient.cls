/**
* @author Joseph Newby
* @date 21.Sep.2015
*
* @description This class wraps around calls to the Zeacom webservice.
* ECP-1561 requires a way of putting a Call Center Customer Service Representative
* on a work break with different messages to do with the reason they are on the break,
* these will be the name of real world activities like reviewing a case before calling about it.
* Zeacom has two end points we will need to accomplish this: Set Worktime and Agent Status.
* We could have just put the code for the calls in the class that will use them
* but moving it into another class will let us create a mock of this class for testing
* with out having access to the live webserivce (which at this point we don't).
*/

public class ZeacomClient {
    @TestVisible
    static final Integer DefaultDuration = 0;
    static final Boolean DefaultOnWorkTime = true;
    
    /** future wrapper 
     */
    @future(callout = true)
    public static void setWorktime(String agentLine, String reason, Integer duration, Boolean onWorkTime){
    	setWorktimeInline(agentLine,reason,duration,onWorkTime);
    }

    /**
    * @description A worktime is used to block incoming calls to a representative while they
    * carry out a task. In our situation we use it when they are handling outbound calls.
    *
    * this is future because we cannot do the "callout" prior to any DML in the main logic
    *
    * @param agentLine The extension that the Call Center Customer Service Representative is associated with.
    * @param reason The reason the Representative is on the break. E.g. reviewing a case before calling. This is visible to their manager.
    * @param duration (Optional Default: 0) The duration in seconds the worktime will last. A value of 0 will cause the time to count up instead of down.
    * @param onWorkTime (Optional Default: true) Set the worktime to the specified status on (true) or off (false).
    */
    public static void setWorktimeInline(String agentLine, String reason, Integer duration, Boolean onWorkTime) {
/*
        HttpRequest request = new HttpRequest();

        Webservice_Settings__c zeacom = [
            select Endpoint__c, Private_Key__c, Public_Key__c
            from Webservice_Settings__c
            where Name = 'zeacom'
        ];

        String endpoint = zeacom.Endpoint__c + 'setworktime?api-key=' + zeacom.Public_Key__c;
        
        System.debug(endpoint);

        MulesoftHashGenerator hashGenerator = new MulesoftHashGenerator(zeacom.Private_Key__c, zeacom.Public_Key__c);

        request.setEndpoint(endpoint);

        String requestBodyJSON = CreateRequestBodyJSON(agentLine, reason, duration, onWorkTime);
        request.setBody(requestBodyJSON);

        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'text/json');
        request.setHeader('Content-Length', '' + requestBodyJSON.length());
        request.setHeader('x-signature', hashGenerator.xSignature(requestBodyJSON));
        request.setHeader('x-datetime', hashGenerator.xdatetime());
*/
		Map<String,String>queryParams = null;
        String requestBodyJSON = CreateRequestBodyJSON(agentLine, reason, duration, onWorkTime);
		HttpRequest request = MulesoftConnector.getConnection('zeacom', queryParams, requestBodyJSON, requestBodyJSON, MulesoftConnector.SignatureHash.WithBodyHash);
        request.setHeader('Accept', 'text/json');

        // no response body from the remote service
        // when running test, just skip the rest
        if (Test.isRunningTest()) {
            return;
        }

        // remote service is fire and forget, not checking any status return
        Http http = new Http();
        HTTPResponse response = http.send(request);

        System.debug(response.getStatusCode());
        System.debug(response.getBody());
    }

    static String CreateRequestBodyJSON(String agentLine, String reason, Integer duration, Boolean onWorkTime) {
        Map<String, Object> requestBodyMap = new Map<String, Object>();

        requestBodyMap.put('agentLine', agentLine);
        requestBodyMap.put('reason', reason);
        requestBodyMap.put('duration', duration);
        requestBodyMap.put('onWorkTime', onWorkTime);

        return JSON.serialize(requestBodyMap);
    }
}