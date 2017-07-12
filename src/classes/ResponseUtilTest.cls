@isTest
public class ResponseUtilTest{
	
	@testsetup
	private static void setup(){
		TestDataHelper.createResponseProperties();
	}

	@isTest
	private static void testcopy_simple(){
		Contact spider = new Contact(lastName='Parker', firstName='Peter', 
			Building_Level_Unit__c = '123 testing lane',
			Road_number__c='1', Road_name__c='Test Lane', Suburb__c='Testville', Town_Or_City__c='Testtown');
		insert spider;

		Contact spiderTest = [select 
				FirstName,
				LastName,
				Building_Level_Unit__c,
				Building_Name__c,
				Suburb__c,
				Town_Or_City__c,
				Has_Address__c,
				Company_Name__c,
				Box_Bag_Number__c,
				Country__c,
				Delivery_Service_Type__c,
				Level_Number__c,
				Mail_Town__c,
				Postcode__c,
				Road_Direction__c,
				Road_Name__c,
				Road_Number__c,
				Road_Number_Alpha__c,
				Road_Type__c,
				Rural_Delivery_Number__c,
				Street_Road_PO_Box__c,
				Suburb_Rural_Delivery__c
			from Contact where Id = :spider.Id
		];

		System.assert(spiderTest.Has_Address__c);

		Response__c resp = TestDataHelper.createResponse(null, null, null, null, false);
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = null;
		resp.access_code__c=null;
		resp.Delivery_Suburb__c='Eric';
		insert resp;
		
		// no dml in util method
		ResponseUtil.setResponseDetailsFromContact(resp, spiderTest, 'Spiderman');
		update resp; // the method doesn't do any dml
		
		Response__c[] verifiedResps = [select id, contact__c, instrument__c, collection_mode__c, unit_delivery_mode__c, 
			Delivery_Road_Number__c, Delivery_Road_Name__c, Delivery_Suburb__c, care_of__c
			from Response__c];
		system.assertEquals('Spiderman', verifiedResps[0].care_of__c);
		system.assertEquals('Testville', verifiedResps[0].delivery_suburb__c); 
	}


	@isTest
	private static void testcopy_companyName(){
		Contact spider = new Contact(lastName='Parker', firstName='Peter', company_name__c='Marvel', 
			Building_Level_Unit__c = '123 testing lane',
			Road_number__c='1', Road_name__c='Test Lane', Suburb__c='Testville', Town_Or_City__c='Testtown');
		insert spider;

		Contact spiderTest = [select 
				FirstName,
				LastName,
				Building_Level_Unit__c,
				Building_Name__c,
				Suburb__c,
				Town_Or_City__c,
				Has_Address__c,
				Company_Name__c,
				Box_Bag_Number__c,
				Country__c,
				Delivery_Service_Type__c,
				Level_Number__c,
				Mail_Town__c,
				Postcode__c,
				Road_Direction__c,
				Road_Name__c,
				Road_Number__c,
				Road_Number_Alpha__c,
				Road_Type__c,
				Rural_Delivery_Number__c,
				Street_Road_PO_Box__c,
				Suburb_Rural_Delivery__c
			from Contact where Id = :spider.Id
		];
		
		System.assert(spiderTest.Has_Address__c);

		Response__c resp = TestDataHelper.createResponse(null, null, null, null, false);
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever';
		resp.Workflow_status__c=null;
		resp.Document_Number__c = null;
		resp.access_code__c=null;
		resp.Delivery_Suburb__c='Eric';
		insert resp;
		
		ResponseUtil.setResponseDetailsFromContact(resp, spiderTest, 'Spiderman');
		update resp; // the method doesn't do any dml
		
		Response__c[] verifiedResps = [select id, contact__c, instrument__c, collection_mode__c, unit_delivery_mode__c, 
			Delivery_Road_Number__c, Delivery_Road_Name__c, Delivery_Suburb__c, care_of__c
			from Response__c];
		system.assertEquals('Marvel', verifiedResps[0].care_of__c);
		system.assertEquals('Testville', verifiedResps[0].delivery_suburb__c); 
	}
}