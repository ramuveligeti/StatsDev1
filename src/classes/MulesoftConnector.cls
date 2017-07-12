/** util class for handling the connection to mulesoft
 * no unit test on this, this is tested under ZeacomClientTest, and ShortUrlClientTest, plus anyother new mulesoft client
*/
public with sharing class MulesoftConnector {

	public enum SignatureHash {WithBodyHash, WithoutBodyHash}

	static public HttpRequest getConnection(String serviceName, Map<String,String>urlParams, String body, String signatureString, SignatureHash hashIndicator) {
		HttpRequest request = new HttpRequest();

		Webservice_Settings__c urlConfig = [
			select Endpoint__c, Private_Key__c, Public_Key__c, Method__c, Content_Type__c
			from Webservice_Settings__c
			where Name = :serviceName
		];
		
		String endpoint = urlConfig.Endpoint__c + '?api-key=' + urlConfig.Public_Key__c;
		if(urlParams != null && !urlParams.isEmpty()){
			for(String k: urlParams.keyset()){
				if(String.isNotBlank(urlParams.get(k))){
					String temp = '&'+k+'='+EncodingUtil.urlEncode(urlParams.get(k),'UTF-8');
					endpoint+=temp;
				}
			}
		}
		
		System.debug(endpoint);
		
		MulesoftHashGenerator hashGenerator = new MulesoftHashGenerator(urlConfig.Private_Key__c, urlConfig.Public_Key__c);
		request.setEndpoint(endpoint);

		// normally, the x-signature is related to the body.  however, if the body is missing, relying on the client to populate that
		if(String.isNotBlank(body)){
	        request.setBody(body);
			request.setHeader('Content-Length', '' + body.length());
		}
		
		request.setMethod(urlConfig.Method__c);
		request.setHeader('Content-Type', urlConfig.Content_Type__c);
		
		String xdt = hashGenerator.xdatetime();
		String xs = null;
		if(hashIndicator!=null && hashIndicator == SignatureHash.WithoutBodyHash){
			xs = hashGenerator.xSignatureWithoutBodyHash(signatureString, xdt);
		} else {
			xs = hashGenerator.xSignature(signatureString, xdt);
		}
		
system.debug('datetime: ' + xdt);
system.debug('hash: ' + xs);

        request.setHeader('x-signature', xs);
        request.setHeader('x-datetime', xdt);
		
		return request;
	}   
}