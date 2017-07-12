/**
* @author Joseph Newby
* @date 14.Sep.2015
* Remark		 Steven Zhu 20160908 ECP 3323 post out file name format change
				 Steven Zhu 20161103 ECP 3720, fixed unit test someone hacked... getRowData now return correct grouping/contextual value 
*Amendment       Caterina Cuccurullo 27-04-2017 ECP-3839
                 changed CreateDocumentName so that document name now shows Scheduled Run Datetime not System.Now which
                 is the datetime it was scheduled.   
*/

@isTest
public class ExtractWorkItemsActivitiesBatch_Test {
	static String WorkItemType = 'Reminder';
	static String DeliveryMode = 'Email';
	static String ExtractType = 'Post';
    static DateTime ScheduleDate = System.now();
    //static String AuthorID = '00517000001bqbX' ;
	static String ExtractFieldName = 'First Name';
	static String ExtractAPIName = 'Response__r.Contact__r.FirstName';
	static String CSVFormatName = 'Reminder Email FirstNames';
	static String DocumentFolder = Label.Work_Item_Extracts_Document_Folder;
	static String ContactFirstName = 'Joe Thiemo Cassius Jonatan Theodor Thoma';

	@testSetup
	static void setupData() {
		System_Update__c config = System_Update__c.getInstance();
		config.Debug_Enabled__c = true;
		upsert config;

		SmartFactory.FillAllFields = true;

		Collection__c collection = TestDataHelper.createCollection(true);

		Grouping__c grouping = new Grouping__c(
			Collection__c = collection.id,
			GR_1_Label__c = 'GR_Label'
		);
		insert grouping;

		Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
			Collection__c = collection.id,
			CO_1_Label__c = 'CO_Label'
		);
		insert contextualMapping;

		Date startDate = system.today();
		Date endDate = startDate.addDays(10);
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Planned_Start_Date__c = startDate;
		collectionInstance.Planned_End_Date__c = endDate;
		collectionInstance.Extension_Cut_off_Date__c = endDate.addDays(-1);
		collectionInstance.Actual_Start_Date__c = system.today().addDays(2);
		collectionInstance.Actual_End_Date__c = system.today().addDays(9);
		collectionInstance.Actual_Close_Off__c = system.today().addDays(8);
		collectionInstance.Collection_Instance_Priority__c = 9;
		collectionInstance.Behavioural_Weighting__c = 70;
		collectionInstance.Statistical_Weighting__c = 30;
		insert collectionInstance;

		Extract_Fields__c firstName = new Extract_Fields__c(
			Name = ExtractFieldName,
			Header__c = ExtractFieldName,
			Extract_Type__c = ExtractType,
			API_Name__c = ExtractAPIName,
			Collection__c = collection.Name,
			Sequence__c = 1
		);

		insert firstName;

		Contact contact = TestDataHelper.createContact(false);
		contact.FirstName = ContactFirstName;
		insert contact;

		Unit__c unit = TestDataHelper.createUnit(false);
		//unit.CO_1_Label__c = 'CO_Label';
		//unit.CO_1__c = 'Example of contextual mapping';
		insert unit;

		List<Response_API_Properties__c> responseAPIProperties = new List<Response_API_Properties__c>();

		Response_API_Properties__c responseStatusClosed = new Response_API_Properties__c(
			Name = 'response.status.closed',
			Value__c = 'Completed'
		);

		responseAPIProperties.add(responseStatusClosed);

		Response_API_Properties__c workItemStatusClosed = new Response_API_Properties__c(
			Name = 'workitem.status.closed',
			Value__c = 'Completed'
		);

		responseAPIProperties.add(workItemStatusClosed);

		insert responseAPIProperties;

		Response__c response = TestDataHelper.createResponse(collectionInstance.Id, contact.Id, null, unit.Id, false);
		response.GR_1_Label__c = 'GR_Label';
		response.GR_1__c = 'Example of grouping';
		response.CO_1_Label__c = 'CO_Label';
		response.CO_1__c = 'Example of contextual mapping';
		insert response;

		Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
			Name = CSVFormatName,
			Column_Header_1__c = ExtractFieldName
		);

		insert csvFormat;

		Integer numberOfWorkItemsToInsert = 1;
		insertWorkItemTestData(numberOfWorkItemsToInsert, response.Id);
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'extract.filesize', value__c = '1000'),
			new SystemSettings__c(name = 'workItemExtract.notificationEmail', value__c = 'test@test.test')
		};
	}

	static List<Work_Item__c> insertWorkItemTestData(Integer numberOfWorkItemsToInsert, Id responseId) {
		SmartFactory.FillAllFields = true;

		List<Work_Item__c> workItems = new List<Work_Item__c>();

		for(Integer index = 0; index < numberOfWorkItemsToInsert; index++) {
			Work_Item__c workItem = TestDataHelper.createWorkItem(null, null, null, responseId, null, false);
			workItem.Work_Item_ExtId__c = generateRandomString(20) + index;
			workItem.Delivery_Mode__c = DeliveryMode;
			workItem.Work_Item_Type__c = WorkItemType;
			workItems.add(workItem);
		}

		insert workItems;

		return workItems;
	}

	static String generateRandomString(Integer len) {
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String randStr = '';
		while (randStr.length() < len) {
		   Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
		   randStr += chars.substring(idx, idx+1);
		}
		return randStr;
	}

	@isTest
	static void getRowData() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id, Grouping__c, Contextual_Mappings__c
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];
		Grouping__c grouping = [select id from Grouping__c limit 1];

		Contextual_Mappings__c contextualMapping = [select id from Contextual_Mappings__c limit 1];

		csvFormat.Grouping__c = grouping.id;
		csvFormat.Contextual_Mappings__c = contextualMapping.id;

		csvFormat.Column_Header_2__c = 'GR_Label';
		csvFormat.Column_Header_3__c = 'CO_Label';

		update csvFormat;

		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
		asch.Collection_Instance__c = collectionInstance.Id;
		asch.Occurrence__c = 1;
		asch.Frequency__c = 'Daily';
		asch.Scheduled_Date_time__c = DateTime.now();

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,true);

		// Act
		List<sObject> objs = Database.query(batch.query);
		Work_Item__c workItem = (Work_Item__c) objs.get(0);
		String rowData = batch.getRowData(workItem, batch.columnMetadata);

		// Assert
		System.assertEquals('"Joe Thiemo Cassius Jonatan Theodor Thoma","Example of grouping","Example of contextual mapping"', rowData);
	}

	@isTest
	static void createLabelMap_Given_Grouping_Params_Returns_Map_Grouping_Labels() {
		// Arrange
		Grouping__c grouping = [select id from Grouping__c limit 1];

		List<String> fieldsToSelect = new List<String>{'_label__c'};

		// Act
		Map<String, String> labelMaps = ExtractWorkItemsActivitiesBatch.createLabelMap(grouping.Id, 'Grouping__c', fieldsToSelect);

		// Assert
		System.assertEquals(1, labelMaps.size());
	}

	@isTest
	static void createLabelMap_Given_Contextual_Mapping_Params_Returns_Map_Contextual_Mapping_Labels() {
		// Arrange
		Contextual_Mappings__c contextualMapping = [select id from Contextual_Mappings__c limit 1];

		List<String> fieldsToSelect = new List<String>{'_label__c'};

		// Act
		Map<String, String> labelMaps = ExtractWorkItemsActivitiesBatch.createLabelMap(contextualMapping.Id, 'Contextual_Mappings__c', fieldsToSelect);

		// Assert
		System.assertEquals(1, labelMaps.size());
	}

	@isTest
	static void constructor_Should_CreateColumnMetadata() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];

		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);

		// Assert
		//System.assertNotEquals(null, batch.columnMetadata);
	}

	@isTest
	static void execute_Should_SaveASingleFile() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];

		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);
		// Act
		Test.startTest();
		Database.executeBatch(batch, 100);
		Test.stopTest();

		List<Document> csvDocuments = [
			SELECT Id
			FROM Document
		];

		// Assert
		System.assertEquals(1, csvDocuments.size());
	}

	@isTest
	static void execute_Should_CorrectlyFormatFileContents() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];
        
      //   User currentOwner = new User();
        // insert currentOwner;
     
		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;
       // asch.CreatedByID =   system.runAs(currentOwner);

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);

		// Act
		Test.startTest();
		Database.executeBatch(batch);
		Test.stopTest();

		Document csvDocument = [
			SELECT Body
			FROM Document
			LIMIT 1
		];
		String fileContents = csvDocument.Body.toString().remove('\n');

		// Assert
		System.assertEquals('First Name"Joe Thiemo Cassius Jonatan Theodor Thoma"', fileContents);
	}

	@isTest
	static void execute_Should_UpdateWorkItemStatusToCompleted() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];

		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);

		// Act
		Test.startTest();
		Database.executeBatch(batch);
		Test.stopTest();

		Work_Item__c workItem = [
			SELECT Status__c
			FROM Work_Item__c
			LIMIT 1
		];

		// Assert
		System.assertEquals('Completed', workItem.status__c);
	}

	@isTest
	static void getFieldValueFromWorkItem_Returns_FirstName_WrappedInQuotes() {
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];

		// Response__r.Contact__r.FirstName
		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);

		Work_Item__c workItem = [
			SELECT Id, Response__r.Contact__r.FirstName
			FROM Work_Item__c
			LIMIT 1
		];

		// Act
		String firstName = ExtractWorkItemsActivitiesBatch.getFieldValueFromWorkItem(workItem, ExtractAPIName);

		// Assert
		System.assertEquals('"' + ContactFirstName + '"', firstName);

	}

	  @isTest
    static void createDocumentName_Returns_FormatedDocumentName() {
        // Arrange
        String collectioInstanceCode = 'AG2016';
        string workItemTypeForTest = 'b e';
        string deliveryModeForTest =  'c f';  
        datetime scheduleDateForTest = System.now();
        string activityScheduleForTest='AS-123';
		string activityScheduleFilterForTest='Birth';
     //   String expectedCSVDocumentName = 'A_Email_Reminder_' + todaysDate.format('yyyyMMddHHmmss');
         string expectedCSVStart = 'AG2016_AS-123_Birth';
         // Act
        String csvDocumentName = ExtractWorkItemsActivitiesBatch.CreateDocumentName(collectioInstanceCode, workItemTypeForTest, deliveryModeForTest,scheduleDateForTest, activityScheduleForTest,activityScheduleFilterForTest);

        // Assert - using timestamp.... could fail
        // System.assertEquals(expectedCSVDocumentName, csvDocumentName);
        system.assertNotEquals(null, csvDocumentName);
        //check that the start of the string reads collectionName_mode_workItem
        system.assertEquals(expectedCSVStart, csvDocumentName.substring(0,19));
    }

	@isTest
	static void getContextualMappingFieldValueOrEmptyString_Given_LabelsHaveTheSameValue_Returns_ContextualMappingValue() {
		// Arrange
		Map<String, String> contextualMappingsLabels = new Map<String, String> {
			'label' => 'CO_1_Label__c'
		};

		Response__c response = new Response__c(
			CO_1_Label__c = 'label',
			CO_1__c = 'value'
		);

		/*
		Unit__c unit = new Unit__c(
			CO_1_Label__c = 'label',
			CO_1__c = 'value'
		);
		*/
		String labelValue = 'label';	

		// Act
		String fieldValue = ExtractWorkItemsActivitiesBatch.getContextualMappingFieldValueOrEmptyString(contextualMappingsLabels, response, labelValue);

		// Assert
		System.assertEquals('value', fieldValue);
	}

	@isTest
	static void getGroupingFieldValueOrEmptyString_Given_LabelsHaveTheSameValue_Returns_GroupingValue() {
		// Arrange
		Map<String, String> groupingLabels = new Map<String, String> {
			'label' => 'GR_1_Label__c'
		};

		Response__c response = new Response__c(
			GR_1_Label__c = 'label',
			GR_1__c = 'value'
		);

		String labelValue = 'label';

		// Act
		String fieldValue = ExtractWorkItemsActivitiesBatch.getGroupingFieldValueOrEmptyString(groupingLabels, response, labelValue);

		// Assert
		System.assertEquals('value', fieldValue);
	}

	@isTest
	static void getGroupingFieldValueOrEmptyString_Given_LabelsDontTheSameValue_Returns_EmptyString() {
		// Arrange
		Map<String, String> groupingLabels = new Map<String, String> {
			'label' => 'GR_1_Label__c'
		};

		Response__c response = new Response__c(
			GR_2_Label__c = 'label',
			GR_2__c = 'value'
		);

		String labelValue = 'label';

		// Act
		String fieldValue = ExtractWorkItemsActivitiesBatch.getGroupingFieldValueOrEmptyString(groupingLabels, response, labelValue);

		// Assert
		System.assertEquals('', fieldValue);
	}

	// This test is just for coverage
	@isTest
	static void castObjectToString() {
		// Arrange
		Object nullObject = null;
		Object stringObject = '';
		Object decimalObject = 1.1;
		Object dateTimeObject = Datetime.newInstance(1960, 2, 17);
		Object dateObject = Date.newInstance(1960, 2, 17);

		// Act
		List<String> strings = new List<String> {
			ExtractWorkItemsActivitiesBatch.castObjectToString(nullObject),
			ExtractWorkItemsActivitiesBatch.castObjectToString(stringObject),
			ExtractWorkItemsActivitiesBatch.castObjectToString(decimalObject),
			ExtractWorkItemsActivitiesBatch.castObjectToString(dateObject),
			ExtractWorkItemsActivitiesBatch.castObjectToString(dateTimeObject)
		};

		// Assert
		System.assertNotEquals(null, strings);
	}

	// Work in progress
	@isTest
	static void OrderBy_Removing_Duplicate_Field_Names() {
		// OrderBy(String soqlQuery, Work_Item_CSV_Format__c workItemCSVFormat, Map<String, String> columnMetadata)
		String query = 'select Response__r.First__c, Response__r.Second__c, Response__r.Third__c, Response__r.Fourth__c, Response__r.Fifth__c from object';

		Map<String, String> columnMetadata = new Map<String, String> {
			'first' => 'Response__r.First__c',
			'second' => 'Response__r.Second__c',
			'third' => 'Response__r.Third__c',
			'fourth' => 'Response__r.Fourth__c',
			'fifth' => 'Response__r.Fifth__c'
		};


		Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
			Order_By_1__c = 'first',
			Order_By_2__c = 'second',
			Order_By_3__c = 'third',
			Order_By_4__c = 'fourth',
			Order_By_5__c = 'first'
		);

		String expected = 'Response__r.First__c ASC,Response__r.Second__c ASC,Response__r.Third__c ASC,Response__r.Fourth__c ASC';
		String actual = ExtractWorkItemsActivitiesBatch.OrderByString(query, csvFormat, columnMetadata);

		System.assertEquals(expected, actual);
	}

	@isTest
	static void OrderBy_Removing_Missing_Fields_From_OrderBy() {
		String query = 'select Response__r.First__c, Response__r.Second__c, Response__r.Third__c, Response__r.Fourth__c from object';

		Map<String, String> columnMetadata = new Map<String, String> {
			'first' => 'Response__r.First__c',
			'second' => 'Response__r.Second__c',
			'third' => 'Response__r.Third__c',
			'fourth' => 'Response__r.Fourth__c',
			'fifth' => 'Response__r.Fifth__c'
		};

		Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
			Order_By_1__c = 'first',
			Order_By_2__c = 'second',
			Order_By_3__c = 'third',
			Order_By_4__c = 'fourth',
			Order_By_5__c = 'fifth'
		);

		String expected = 'Response__r.First__c ASC,Response__r.Second__c ASC,Response__r.Third__c ASC,Response__r.Fourth__c ASC';
		String actual = ExtractWorkItemsActivitiesBatch.OrderByString(query, csvFormat, columnMetadata);

		System.assertEquals(expected, actual);
	}

	@isTest
	static void OrderBy() {
		String query = 'select Response__r.First__c, Response__r.Second__c, Response__r.Third__c, Response__r.Fourth__c, Response__r.Fifth__c from object';

		Map<String, String> columnMetadata = new Map<String, String> {
			'first' => 'Response__r.First__c',
			'second' => 'Response__r.Second__c',
			'third' => 'Response__r.Third__c',
			'fourth' => 'Response__r.Fourth__c',
			'fifth' => 'Response__r.Fifth__c'
		};

		Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
			Order_By_1__c = 'first',
			Order_By_2__c = 'second',
			Order_By_3__c = 'third',
			Order_By_4__c = 'fourth',
			Order_By_5__c = 'fifth'
		);
		String expected = 'Response__r.First__c ASC,Response__r.Second__c ASC,Response__r.Third__c ASC,Response__r.Fourth__c ASC,Response__r.Fifth__c ASC';
		String actual = ExtractWorkItemsActivitiesBatch.OrderByString(query, csvFormat, columnMetadata);

		System.assertEquals(expected, actual);
	}

	@isTest
	static void testCreateNewExtractSchedule(){
		// Arrange
		Collection_Instance__c collectionInstance = [
			SELECT Id, Name, Collection__c
			FROM Collection_Instance__c
			LIMIT 1
		];

		Work_Item_CSV_Format__c csvFormat = [
			SELECT Id
			FROM Work_Item_CSV_Format__c
			LIMIT 1
		];

		// Response__r.Contact__r.FirstName
		Activity_Schedule__c asch = new Activity_Schedule__c();
		asch.Output_CSV_Format__c = csvFormat.Id;
		asch.Work_Item_Type__c = WorkItemType;
		asch.Delivery_Mode__c = DeliveryMode;
        asch.Scheduled_Date_time__c = System.now();
		asch.Collection_Instance__c = collectionInstance.Id;

		ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(asch,false);

		Extract_Schedule__c es = batch.createNewExtractSchedule(asch);

		System.assertEquals(es.Collection_Instance_Id__c, collectionInstance.Id);
		System.assertEquals(es.Activity_Schedule_Id__c, asch.Id);
	}
}