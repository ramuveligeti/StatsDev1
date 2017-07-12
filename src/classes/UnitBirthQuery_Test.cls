@isTest
private class UnitBirthQuery_Test {
	static void createCollection(String frequency) {
		Collection__c collection = new Collection__c(
			Collection_Code__c = 'collection_' + frequency,
			Collection__c = frequency
		);
		insert collection;

		List<Collection_Instance__c> collectionInstances = new List<Collection_Instance__c>();
		for (Integer i = 0; i < 6; i++) {
			String referencePeriod = '20160' + (i + 1).format();
			Collection_Instance__c collectionInstance = new Collection_Instance__c(
				Name = 'collection_' + i + '_' + frequency,
				Collection__c = collection.Id,
				Reference_Period__c = referencePeriod,
				Planned_Start_Date__c = DateTime.newInstance(2016, i, 1).date()
			);
			collectionInstances.add(collectionInstance);
		}
		insert collectionInstances;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'unit_' + frequency + '_1'
		);
		insert unit;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = frequency,
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		List<Response__c> responses = new List<Response__c>();
		for (Collection_Instance__c collectionInstance : collectionInstances) {
			Response__c response = new Response__c(
				Collection_Instance__c = collectionInstance.Id,
				Contact__c = contact.Id,
				Unit_of_Interest__c = unit.Id,
				RecordTypeId = business.Id
			);
			responses.add(response);
		}

		insert responses;
	}

	@isTest
	static void mark_response_as_birthed_when_no_previous_CI() {
		System.debug('mark_response_as_birthed_when_no_previous_CI___________________________________________________________________');
		Collection__c collection = [
			select Id
			from Collection__c
			limit 1
		];
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Collection__c = collection.Id,
			Reference_Period__c = '201608'
		); 
		insert collectionInstance;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet'
		);
		insert unit;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = 'blogs',
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		Response__c responseUnderTest = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			Birth__c = false,
			RecordTypeId = business.Id
		);
		
		List<Response__c> responses = new List<Response__c> {
			responseUnderTest
		};
		
		UnitBirthQuery.MarkReponsesAsBirthed(responses);
		
		System.assert(responseUnderTest.Birth__c);
	}

	@testSetup
	static void setup() {
		TestDataHelper.createResponseProperties();
		
		// 'Monthly', 'Quarterly', 'Annually', 'Every 2 years', 'Every 3 years', 'Every 5 years'
		createCollection('Monthly');
		createCollection('Quarterly');
		
		insert new SystemSettings__c(name='migration.inprogress', value__c='False');
	}
	
	@isTest
	static void mark_response_as_not_birthed() {
	   	System.debug('mark_response_as_not_birthed___________________________________________________________________');
		Response__c response = [
			select Collection_Instance__c, Unit_of_Interest_ID__c, Birth__c, 
			Survey_Unit__c, Survey_Unit__r.Unit_of_Interest_ID__c,
			Unit_of_Interest__c, Unit_of_Interest__r.Unit_of_Interest_ID__c,
			RecordTypeId
			from Response__c
			limit 1
		];
		System.debug('response=='+response);
		List<Response__c> responses = new List<Response__c> {
			response
		};
		
		UnitBirthQuery.MarkReponsesAsBirthed(responses);
		
		System.assertEquals(True, response.Birth__c);
	}
	
	@isTest
	static void mark_response_as_birthed() {
		System.debug('mark_response_as_birthed___________________________________________________________________');
		Collection__c collection = [
			select Id
			from Collection__c
			limit 1
		];
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Collection__c = collection.Id,
			Reference_Period__c = '201608'
		); 
		insert collectionInstance;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet'
		);
		insert unit;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = 'blogs',
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		Response__c responseUnderTest = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			Birth__c = false,
			RecordTypeId = business.Id
		);
		
		List<Response__c> responses = new List<Response__c> {
			responseUnderTest
		};
		
		UnitBirthQuery.MarkReponsesAsBirthed(responses);
		
		System.assert(responseUnderTest.Birth__c);
	}

	// This test is where as a sresult of a testers finding that the birthing calculation was
	// checking the unit id against response in different collections.
	@isTest
	static void collections_dont_conflict_causing_unchecked_birthing() {
		System.debug('collections_dont_conflict_causing_unchecked_birthing___________________________________________________________________');
		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		Contact contact = [
			select Id
			from Contact
			limit 1
		];
		
		Unit__c unit = [
			select Id
			from Unit__c
			limit 1
		];
		
		Collection_Instance__c monthlyCollectionInstance = [
			select Id
			from Collection_Instance__c
			where Collection__r.Collection_Code__c = 'collection_Monthly'
			limit 1
		];
		
		Response__c monthlyClone = new Response__c(
			Collection_Instance__c = monthlyCollectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			RecordTypeId = business.Id
		);
		
		Collection_Instance__c quarterlyCollectionInstance = [
			select Id
			from Collection_Instance__c
			where Collection__r.Collection_Code__c = 'collection_Quarterly'
			limit 1
		];
		
		Response__c querterlyClone = new Response__c(
			Collection_Instance__c = quarterlyCollectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			RecordTypeId = business.Id
		);
		
		insert new List<Response__c> {
			monthlyClone,
			querterlyClone
		};
		
		Response__c querterlyCloneAfterInsert = [
			select Birth__c
			from Response__c
			where Id = :querterlyClone.Id
		];
		
		System.assert(querterlyCloneAfterInsert.Birth__c);
	}

	@isTest
	static void only_go_back_6_collection_instances() {
		System.debug('only_go_back_6_collection_instances___________________________________________________________________');
		
		List<Collection_Instance__c> quarterlyInstances = [
			select Name, Collection__r.Collection_Code__c, Reference_Period__c
			from Collection_Instance__c
			where Collection__r.Collection_Code__c = 'collection_Quarterly'
			order by Planned_Start_Date__c desc
		];
		System.debug('quarterlyInstances=='+quarterlyInstances);
		Collection_Instance__c newestInstance = quarterlyInstances.get(0);
		Collection_Instance__c oldestInstance = quarterlyInstances.get(quarterlyInstances.size() - 1);
		System.debug('newestInstance=='+newestInstance.Name);
		System.debug('oldestInstance=='+oldestInstance.Name);
		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'unit_for_the_1st_and_6th_response'
		);
		insert unit;
		
		Response__c oldestResponse = [
			select Contact__c, Unit_of_Interest__c, RecordTypeId
			from Response__c
			where Collection_Instance__c = :oldestInstance.Id
			limit 1
		];
		oldestResponse.Unit_of_Interest__c = unit.Id;
		update oldestResponse;
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Name = 'collection_7' ,
			Collection__c = quarterlyInstances.get(0).Collection__c,
			Reference_Period__c = '201512',
			Planned_Start_Date__c = DateTime.newInstance(2016, 12, 1).date()
		);
		insert collectionInstance;
		Response__c clone = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = oldestResponse.Contact__c,
			Unit_of_Interest__c = unit.Id,
			RecordTypeId = oldestResponse.RecordTypeId
		);
		
		insert clone;
		
		Response__c cloneAfterInsert = [
			select Birth__c
			from Response__c
			where Id = :clone.Id
		];
		
		System.assert(cloneAfterInsert.Birth__c);
	}

	@isTest
	static void only_go_back_5_collection_instances() {
		System.debug('only_go_back_5_collection_instances___________________________________________________________________');
		
		List<Collection_Instance__c> quarterlyInstances = [
			select Name, Collection__r.Collection_Code__c, Reference_Period__c
			from Collection_Instance__c
			where Collection__r.Collection_Code__c = 'collection_Quarterly'
			order by Planned_Start_Date__c desc
		];
		System.debug('quarterlyInstances=='+quarterlyInstances);
		Collection_Instance__c newestInstance = quarterlyInstances.get(0);
		Collection_Instance__c oldestInstance = quarterlyInstances.get(quarterlyInstances.size() - 1);
		System.debug('newestInstance=='+newestInstance.Name);
		System.debug('oldestInstance=='+oldestInstance.Name);
		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'unit_for_the_1st_and_6th_response'
		);
		insert unit;
		
		Response__c oldestResponse = [
			select Contact__c, Unit_of_Interest__c, RecordTypeId
			from Response__c
			where Collection_Instance__c = :oldestInstance.Id
			limit 1
		];
		oldestResponse.Unit_of_Interest__c = unit.Id;
		update oldestResponse;
		
		Response__c clone = new Response__c(
			Collection_Instance__c = newestInstance.Id,
			Contact__c = oldestResponse.Contact__c,
			Unit_of_Interest__c = unit.Id,
			RecordTypeId = oldestResponse.RecordTypeId
		);
		
		insert clone;
		
		Response__c cloneAfterInsert = [
			select Birth__c
			from Response__c
			where Id = :clone.Id
		];
		
		System.assert(!cloneAfterInsert.Birth__c);
	}

	@isTest
	static void data_load_responses_with_the_same_survey_unit() {
		List<Response__c> responses = [
			select Contact__c, Unit_of_Interest__c, RecordTypeId, Collection_Instance__c
			from Response__c
			where Collection_Instance__r.Collection__r.Collection_Code__c = 'collection_Quarterly'
		];
		
		Response__c template = responses.get(0);
		
		Unit__c surveyUnit = new Unit__c(
			Unit_of_Interest_ID__c = 'duplicate_survey_unit'
		);
		insert surveyUnit;
		
		Response__c clone1 = new Response__c(
			Collection_Instance__c = template.Collection_Instance__c,
			Contact__c = template.Contact__c,
			Unit_of_Interest__c = surveyUnit.Id,
			Survey_Unit__c = surveyUnit.Id,
			RecordTypeId = template.RecordTypeId
		);
		Response__c clone2 = new Response__c(
			Collection_Instance__c = template.Collection_Instance__c,
			Contact__c = template.Contact__c,
			Unit_of_Interest__c = surveyUnit.Id,
			Survey_Unit__c = surveyUnit.Id,
			RecordTypeId = template.RecordTypeId
		);
		
		insert new List<Response__c> { clone1, clone2 };
		
		Response__c clone1AfterInsert = [
			select Birth__c
			from Response__c
			where Id = :clone1.Id
		];
		
		Response__c clone2AfterInsert = [
			select Birth__c
			from Response__c
			where Id = :clone2.Id
		];
		
		System.assert(clone1AfterInsert.Birth__c);
		System.assert(clone2AfterInsert.Birth__c);
	}
	
	/*
	 * This test will check that when a data loader is split into multipul batchs
	 * that it marks responses in the 2nd batch as birthed correctly.
	 * I know that the batch size is 200 so I insert 201 and responses.
	 * They all have the same unit so I expect that to 201st response, response under test, should be marked as birthed.
	 */
	@isTest
	static void birth_collection_instances_that_appear_across_batches() {
		System.debug('birth_collection_instances_that_appear_across_batches___________________________________________________________________');
		Collection__c collection = [
			select Id
			from Collection__c
			limit 1
		];
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Collection__c = collection.Id,
			Reference_Period__c = '201608'
		); 
		insert collectionInstance;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet'
		);
		insert unit;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = 'blogs',
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		List<Response__c> responses = new List<Response__c> ();
		
		for (Integer index = 0; index < 200; index++) {
			Response__c response = new Response__c(
				Collection_Instance__c = collectionInstance.Id,
				Contact__c = contact.Id,
				Unit_of_Interest__c = unit.Id,
				Birth__c = false,
				RecordTypeId = business.Id
			);
			responses.add(response);
		}
		
		Response__c responseUnderTest = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			Birth__c = false,
			RecordTypeId = business.Id
		);
		responses.add(responseUnderTest);
		
		insert responses;
		
		responseUnderTest = [
			select Birth__c
			from Response__c
			where Id = :responseUnderTest.Id
		];
		
		System.assert(responseUnderTest.Birth__c);
	}

	@isTest
	static void birth_collection_instances_that_appear_across_batches_collectionUnit() {
		System.debug('birth_collection_instances_that_appear_across_batches___________________________________________________________________');
		Collection__c collection = [
			select Id
			from Collection__c
			limit 1
		];
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Collection__c = collection.Id,
			Reference_Period__c = '201608'
		); 
		insert collectionInstance;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet'
		);
		insert unit;
		Unit__c unit1 = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet1'
		);
		insert unit1;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = 'blogs',
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		List<Response__c> responses = new List<Response__c> ();
		
		for (Integer index = 0; index < 200; index++) {
			Response__c response = new Response__c(
				Collection_Instance__c = collectionInstance.Id,
				Contact__c = contact.Id,
				Unit_of_Interest__c = unit.Id,
				Birth__c = false,
				RecordTypeId = business.Id
			);
			responses.add(response);
		}
		
		Response__c responseUnderTest = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit1.Id,
			Survey_Unit__c = unit.Id,
			Birth__c = false,
			RecordTypeId = business.Id
		);
		responses.add(responseUnderTest);
		
		insert responses;
		
		responseUnderTest = [
			select Birth__c
			from Response__c
			where Id = :responseUnderTest.Id
		];
		
		System.assert(responseUnderTest.Birth__c);
	}

	@isTest
	static void birth_collection_instances_that_appear_across_batches_surveyUnit() {
		System.debug('birth_collection_instances_that_appear_across_batches___________________________________________________________________');
		Collection__c collection = [
			select Id
			from Collection__c
			limit 1
		];
		
		Collection_Instance__c collectionInstance = new Collection_Instance__c(
			Collection__c = collection.Id,
			Reference_Period__c = '201608'
		); 
		insert collectionInstance;

		Unit__c unit = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet'
		);
		insert unit;
		Unit__c unit1 = new Unit__c(
			Unit_of_Interest_ID__c = 'doesnt_exist_yet1'
		);
		insert unit1;

		Contact contact = new Contact(
			FirstName = 'Joe',
			LastName = 'blogs',
			Phone = '+64 (000) 0000000',
			HomePhone = '+64 (000) 0000000',
			MobilePhone = '+64 (000) 0000000'
		);
		insert contact;

		RecordType business = [
			select Name
			from RecordType
			where SobjectType = 'Response__c'
			and Name = 'Business Response'
			limit 1
		];
		
		List<Response__c> responses = new List<Response__c> ();
		
		for (Integer index = 0; index < 200; index++) {
			Response__c response = new Response__c(
				Collection_Instance__c = collectionInstance.Id,
				Contact__c = contact.Id,
				Unit_of_Interest__c = unit.Id,
				Birth__c = false,
				RecordTypeId = business.Id
			);
			responses.add(response);
		}
		
		Response__c responseUnderTest = new Response__c(
			Collection_Instance__c = collectionInstance.Id,
			Contact__c = contact.Id,
			Unit_of_Interest__c = unit.Id,
			Survey_Unit__c = unit1.Id,
			Birth__c = false,
			RecordTypeId = business.Id
		);
		responses.add(responseUnderTest);
		
		insert responses;
		
		responseUnderTest = [
			select Birth__c
			from Response__c
			where Id = :responseUnderTest.Id
		];
		
		System.assert(responseUnderTest.Birth__c);
	}

}