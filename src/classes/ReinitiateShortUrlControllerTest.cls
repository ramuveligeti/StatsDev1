/**
* Amendment -  Caterina Cuccurullo 22 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
*/
@isTest
private class ReinitiateShortUrlControllerTest {
    
    @testsetup
    private static void setup(){
		insert new SystemSettings__c(name = 'shortUrlClient.notificationEmail', value__c = 'joseph.newby@fronde.com');
        
        insert new Webservice_Settings__c(
            Name = 'ShortUrlGenerator',
            Endpoint__c = 'www.example.com/',
            Method__c = 'GET',
            Content_Type__c = 'application/x-www-form-urlencoded',
            Private_Key__c = 'abc',
            Public_Key__c = 'cba'
        );

		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;

		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Artefact_Code__c='EL001';
        artefact.Status__c = 'Active';
        artefact.Collection_Modes__c = 'CAWI;CATI';
        insert artefact;
				
		Collection_Instance__c colIns1 = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns1.Collection_Instance_Code__c='EricTest1';
		colIns1.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns1.Collection_Period__c=null;
		colIns1.Reference_Period__c='202010';
		colIns1.Return_Date__c=system.today().addDays(40);
        colIns1.Planned_Start_Date__c = system.today().addDays(2);
        colIns1.Planned_Close_Off__c = system.today().addDays(3);
		insert colIns1;
    }
    
    private static void createResponses(Collection_Instance__c colIns1, Artefact__c artefact, boolean populateShortURLs){
    	Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<5; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=0; i<5; i++){
			Response__c resp = TestDataHelper.createResponse(colIns1.Id, null, null, units[i].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.collection_mode__c = 'SCER';
			resp.contact__c = null;
			resp.survey_unit__c = units[i].id;
			resp.instrument__c=artefact.id;
			resp.Response_ExtId__c = 'EricTest'+i+'EricTest'+i+'EL001'; // append instrument code
			resp.Online_Survey_URL__c=populateShortURLs?'http://a.com':null;
			resps.add(resp);
		}
		insert resps;
    }
    
    @isTest
    private static void testEmptyCollection(){
    	Test.setCurrentPage(Page.ReinitiateShortUrl);
    	Collection_Instance__c ci = [select id, Short_URL_Request_Timestamp__c, Name, 
    		Collection__c, Collection__r.Name, Collection_Instance__c.Collection__r.Collection_Code__c 
    		from Collection_Instance__c];
    	ReinitiateShortUrlController ctr = new ReinitiateShortUrlController(new ApexPages.StandardController(ci));
    	
    	system.assert(ctr.onlineSurvey);
    	system.assert(ctr.emptyCollection);
    	
    	
    	// keep sf happy
    	ctr.backToCollectionInstance();
    }
    
    @isTest
    private static void testNonCawiCollection() {
    	Artefact__c a = [select id from Artefact__c];
    	a.Collection_Modes__c = 'CATI';
    	update a;
    	
    	Test.setCurrentPage(Page.ReinitiateShortUrl);
    	Collection_Instance__c ci = [select id, Short_URL_Request_Timestamp__c, Name, 
    		Collection__c, Collection__r.Name, Collection_Instance__c.Collection__r.Collection_Code__c 
    		from Collection_Instance__c];
    	ReinitiateShortUrlController ctr = new ReinitiateShortUrlController(new ApexPages.StandardController(ci));
    	
    	system.assert(!ctr.onlineSurvey);
    	system.assert(ctr.emptyCollection);    	
    }
    
    @isTest
    private static void testResponses_withShortURLs(){
    	Artefact__c a = [select id from Artefact__c];
    	Collection_Instance__c ci = [select id, Short_URL_Request_Timestamp__c, Name, 
    		Collection__c, Collection__r.Name, Collection_Instance__c.Collection__r.Collection_Code__c 
    		from Collection_Instance__c];
    	ci.Short_URL_Request_Timestamp__c = system.now() - 3; // number of days

    	createResponses(ci, a, true);// populate with short-urls
    	
    	Test.setCurrentPage(Page.ReinitiateShortUrl);
    	ReinitiateShortUrlController ctr = new ReinitiateShortUrlController(new ApexPages.StandardController(ci));
    	
    	system.assert(ctr.onlineSurvey);
    	system.assert(!ctr.emptyCollection);
    	
    	system.assertEquals(ctr.submittedInHours, 72);
    	system.assert(ctr.notAllowed);
    	system.assert(ctr.receivedShortUrl);

    }


    @isTest
    private static void testResponses_neverSubmittedBefore(){
    	Artefact__c a = [select id from Artefact__c];
    	Collection_Instance__c ci = [select id, Short_URL_Request_Timestamp__c, Name, 
    		Collection__c, Collection__r.Name, Collection_Instance__c.Collection__r.Collection_Code__c 
    		from Collection_Instance__c];

    	createResponses(ci, a, false);// not populate with short-urls
    	
    	Test.setCurrentPage(Page.ReinitiateShortUrl);
    	ReinitiateShortUrlController ctr = new ReinitiateShortUrlController(new ApexPages.StandardController(ci));
    	    	
    	system.assertEquals(ctr.submittedInHours, 0);
    	system.assert(ctr.goodToGo);
    	system.assert(!ctr.receivedShortUrl);

		// submit shortURL
    	Test.startTest();
    	ctr.submitShortURLRequest();
    	system.assert(ctr.submitted);
    	Test.stopTest();
    }
    
}