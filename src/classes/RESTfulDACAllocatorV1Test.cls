@isTest
Private class RESTfulDACAllocatorV1Test {    
    public static void setup(){	
		DAC_Store__c[]dacs=new DAC_Store__c[]{
            new DAC_Store__c(document_id__c='7773', access_code__c='ZZZ3', allocation_status__c = 'Unallocated', Is_Non_Private_Dwelling__c = true),  
            new DAC_Store__c(document_id__c='7774', access_code__c='ZZZ4', allocation_status__c = 'Unallocated',Is_Non_Private_Dwelling__c = false)                   		
           };
		insert dacs;   
    }
    
	@isTest static void testAllocateDAC() {	
        setup();
       	User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
		system.runAs(userObj){
			Collection__c col = TestDataHelper.createCollection(false);
			col.Name = 'Census';
			col.Collection_Code__c = 'Census';
			insert col;
			Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
			Contact cnt = TestDataHelper.createContact(true);
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.Unit_of_Interest_ID__c ='ecp2616';
			unitObj.Address_Type__c = 'Non-private dwelling';
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '123';
			unitObj.P_O_Box__c = null;
			insert unitObj;
			Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
			resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			insert resp;   	
	    
        List<Response__c> response = [Select Id, Name, document_number__c from Response__c where Id =: resp.Id];
        test.startTest();        
		RestRequest req = new RestRequest();
        req.addHeader('Content-Type', 'application/json'); 
        req.requestURI = '/services/apexrest/RESTfulDACAllocator/1.0/'; 
        req.httpMethod = 'POST'; 
		req.requestBody = Blob.valueOf('{"responseID": "'+response[0].Name+'"}'); 
        RestResponse res = new RestResponse();   
        RestContext.request=req;
        RestContext.response=res; 
        RESTfulDACAllocatorV1.allocateDAC(response[0].Name);
        test.stopTest();  
        system.assertEquals(1, response.size());
        Dac_Store__c dac = [select allocation_status__c from Dac_Store__c where document_id__c = '7773'];
        system.assertEquals('Allocated', dac.allocation_status__c); 
        }
	}
    @isTest 
	static void testAllocateDAC_2() {       
        setup();
		RestContext.request = new RestRequest();
		RestContext.request.requestBody = Blob.valueOf('{"responseID": "R1000095955"}');

		 String result = RESTfulDACAllocatorV1.allocateDAC('R1000095955');
         List<Response__c> response = [Select Id, Name, document_number__c from Response__c where Name =: 'R1000095955'];
         system.assertEquals(0, response.size());
         system.assertEquals('No Response Found', result);
	}
}