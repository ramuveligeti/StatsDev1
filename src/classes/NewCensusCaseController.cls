/**
 * this controller is used by Census field test only
 *
 * the business process for Census Field Test Call Centre
 * 1. incoming calls only
 * 2. CSR will search for the address
 * 3. CSR will open the Response record based on the address
 * 4. CSR will create a new case from here, and launch as primary tab
 */
public class NewCensusCaseController {

	private Response__c primaryDwellingResponse{set;get;}
	public Id caseId{get;private set;}
	
	public NewCensusCaseController(ApexPages.StandardController std){
		primaryDwellingResponse = (Response__c)std.getRecord();
	}

	public void newCase(){
		Case c = new Case(Response__c=primaryDwellingResponse.id,
			Collection_Instance__c=primaryDwellingResponse.Collection_Instance__c);
		insert c;
		caseId=c.id;
	}
}