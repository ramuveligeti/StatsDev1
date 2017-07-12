/** this is the controller behind the Short-URL button
 *  
 *  right after file-loading, if the collection-instance is qualified for short-url.  A request to mulesoft will be invoked.
 * 
 *  logic:
 *  1. check if we already submitted a request to mulesoft
 *  2. scan through the responses under the C.I. and check if we have short-url back already
 *  3. allow user to overrule, with confirmation
 *  4. submit the request to mulesoft
 */
public class ReinitiateShortUrlController {
	public boolean notAllowed{private set; get;}
	public boolean goodToGo{private set; get;}
	public decimal submittedInHours{private set; get;}
	public boolean submitted{private set; get;}
	public boolean receivedShortUrl{private set;get;}
	public boolean onlineSurvey{private set;get;}
	public boolean emptyCollection{private set;get;}
	
	private Id collectionInstanceId;

	public ReinitiateShortUrlController(ApexPages.StandardController std){
		collectionInstanceId = std.getId();
		Collection_Instance__c ci = (Collection_Instance__c)std.getRecord();

		Artefact__c[]cawiInstruments = [ select Id from Artefact__c 
			where Status__c = 'active' and RecordType.Name = 'Instrument'
			and Collection_Modes__c includes ('CAWI') and Collection__r.RecordType.Name = 'Collections'
			and Collection__r.Collection_Code__c = :ci.Collection__r.Collection_Code__c ];
		onlineSurvey = !cawiInstruments.isEmpty();
		
		Response__c[]noURLResp = [select id from Response__c where collection_Instance__c = :collectionInstanceId and Online_Survey_URL__c = null limit 1];
		Response__c[]gotURLResp = [select id from Response__c where collection_Instance__c = :collectionInstanceId and Online_Survey_URL__c != null limit 1];

		submittedInHours = 0;
		if(ci.Short_URL_Request_Timestamp__c!=null){
			long x = system.now().getTime() - ci.Short_URL_Request_Timestamp__c.getTime();
			submittedInHours = (x/1000)/3600;
		}
		// block it
		emptyCollection = noUrlResp.isEmpty() && gotURLResp.isEmpty();// no responses
		notAllowed = noURLResp.isEmpty();// all responses have short-url already, don't do it again
		
		// first submittion
		goodToGo = submittedInHours==0 && gotURLResp.isEmpty();
		
		receivedShortUrl = !gotURLResp.isEmpty();
	}
	
	public void submitShortURLRequest(){
		// allow 3 attempts
		ShortUrlClient.RequestShortUrlInline(collectionInstanceId, (Test.isRunningTest()?3:0));
		submitted = true;
	}
	
	public PageReference backToCollectionInstance(){
		return new PageReference('/'+collectionInstanceId);
	}
}