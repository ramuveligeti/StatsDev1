/**
* @author Joseph Newby
* @date 07.Sep.2015
*/

@isTest 
public class NewWorkItemCSVFormatCX_Test {
	@testSetup
	static void setupData() {
		Extract_Fields__c firstName = new Extract_Fields__c(
			API_Name__c = 'Response__r.Contact__r.FirstName',
			Name = 'First Name',
			Visible_to_Business__c = true,
			Visible_to_Census__c = true,
			Visible_to_Social__c = true,
			/* These fields aren't used. They are left over from an old design. */
			Sequence__c = 1,
			Collection__c = 'Not Used',
			Header__c = 'Not Used',
			Extract_Type__c = 'Not Used'
		);
		
		insert firstName;

		Work_Item_CSV_Format__c csvFormat = new Work_Item_CSV_Format__c(
			name = 'Non-unique Name'
		);
		insert csvFormat;

		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
		insert col;
		Grouping__c grp = new Grouping__c(Collection__c = col.id,GR_1_Label__c = 'G1',Active__c=true);
		insert grp;
		Contextual_Mappings__c ctx = new Contextual_Mappings__c(Collection__c = col.id,CO_1_Label__c = 'C1',Active__c=true);
		insert ctx;

	}

	@isTest
	static void constructor_Should_PopulateColumns() {
		// Assert
		NewWorkItemCSVFormatCX controller = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(new Work_Item_CSV_Format__c()));
		system.assertEquals(false, controller.columns.isEmpty());
	}

	@isTest
	static void constructor_Should_PopulateWorkItemFields() {
		// Assert
 		NewWorkItemCSVFormatCX controller = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(new Work_Item_CSV_Format__c()));
		system.assertEquals(false, controller.workItemFields.isEmpty());
	}
	
	@isTest
	static void save_Given_CSVFormatWithoutAName_Shouldnt_SaveCSVFormat() {
		NewWorkItemCSVFormatCX controller = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(new Work_Item_CSV_Format__c()));
		// Act
		Integer numberOfCSVFormatsBeforeSave = getCurrentNumberOfCSVFormats();

		controller.saveCSVFormat();

		Integer numberOfCSVFormatsAfterSave = getCurrentNumberOfCSVFormats();

		// Assert
		system.assertEquals(numberOfCSVFormatsBeforeSave, numberOfCSVFormatsAfterSave);
	}

	@isTest
	static void save_Given_CSVFormatWithNonUniqueName_Shouldnt_SaveCSVFormat() {
		NewWorkItemCSVFormatCX controller = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(new Work_Item_CSV_Format__c()));
		// Act
		Integer numberOfCSVFormatsBeforeSave = getCurrentNumberOfCSVFormats();

		controller.csvFormat.name = 'Non-unique Name';
		controller.saveCSVFormat();

		Integer numberOfCSVFormatsAfterSave = getCurrentNumberOfCSVFormats();

		// Assert
		system.assertEquals(numberOfCSVFormatsBeforeSave, numberOfCSVFormatsAfterSave);
	}

	@isTest
	static void save_Given_ValidCSVFormat_Should_SaveCSVFormat() {
		NewWorkItemCSVFormatCX controller = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(new Work_Item_CSV_Format__c()));

		// Act
		Integer numberOfCSVFormatsBeforeSave = getCurrentNumberOfCSVFormats();

		NewWorkItemCSVFormatCX c = controller;
		c.csvFormat.name = 'Unique Name';
		PageReference temp = c.saveCSVFormat();

		Integer numberOfCSVFormatsAfterSave = getCurrentNumberOfCSVFormats();

		// Assert
		system.assertNotEquals(numberOfCSVFormatsBeforeSave, numberOfCSVFormatsAfterSave);
	}


	@isTest
	static void selectACollection() {
		SObject[]t=TestDataHelper.selectAllQuery('Work_Item_CSV_Format__c');
		Work_Item_CSV_Format__c csv=(Work_Item_CSV_Format__c)t[0];
		NewWorkItemCSVFormatCX c = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(csv));
		c.csvFormat.Collection__c=null;
		c.collectionSelected();
		boolean foundExtractFields=false,foundGrouping=false,foundContextual=false;
		for(SelectOption so:c.workItemFields){
			foundExtractFields|=so.getLabel().equalsIgnoreCase('first name');
			foundGrouping|=so.getLabel().equalsIgnoreCase('G1');
			foundContextual|=so.getLabel().equalsIgnoreCase('C1');
		}
		system.assert(foundExtractFields);
		system.assert(!foundGrouping);
		system.assert(!foundContextual);
		Collection__c col=[select name from Collection__c];
		c.csvFormat.Collection__c=col.id;
		c.collectionSelected();
		//reset
		foundExtractFields=false;
		for(SelectOption so:c.workItemFields){
			foundExtractFields|=so.getLabel().equalsIgnoreCase('first name');
			foundGrouping|=so.getLabel().equalsIgnoreCase('G1');
			foundContextual|=so.getLabel().equalsIgnoreCase('C1');
		}
		system.assert(foundExtractFields);
		system.assert(foundGrouping);
		system.assert(foundContextual);
	}


	@istest
	static private void testExtractFieldsSelection(){
		ID bizID=Collection__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		ID socID=Collection__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Social').getRecordTypeId();
		ID cenID=Collection__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census').getRecordTypeId();
		// adding additional fields for the test
		Extract_Fields__c[] extractFields = new Extract_Fields__c[]{
			new Extract_Fields__c(
				API_Name__c = 'Response__r.Contact__r.LastName', Name = 'Last Name', Visible_to_Business__c = true, Visible_to_Census__c = false, Visible_to_Social__c = false,
				Sequence__c = 1, Collection__c = 'Not Used', Header__c = 'Not Used', Extract_Type__c = 'Not Used'),
			new Extract_Fields__c(
				API_Name__c = 'Response__r.wave', Name = 'Wave', Visible_to_Business__c = false, Visible_to_Census__c = false, Visible_to_Social__c = true,
				Sequence__c = 1, Collection__c = 'Not Used', Header__c = 'Not Used', Extract_Type__c = 'Not Used'),
			new Extract_Fields__c(
				API_Name__c = 'Response__r.Access_Code__c', Name = 'Access Code', Visible_to_Business__c = false, Visible_to_Census__c = true, Visible_to_Social__c = false,
				Sequence__c = 1, Collection__c = 'Not Used', Header__c = 'Not Used', Extract_Type__c = 'Not Used'),
			new Extract_Fields__c(
				API_Name__c = '', Name = 'Invalid Setting', Visible_to_Business__c = true, Visible_to_Census__c = true, Visible_to_Social__c = true,
				Sequence__c = 1, Collection__c = 'Not Used', Header__c = 'Not Used', Extract_Type__c = 'Not Used')
		};
		insert extractFields;
		
		Collection__c col=[select name from Collection__c];
		SObject[]t=TestDataHelper.selectAllQuery('Work_Item_CSV_Format__c');
		Work_Item_CSV_Format__c csv=(Work_Item_CSV_Format__c)t[0];
		
		NewWorkItemCSVFormatCX ctr = new NewWorkItemCSVFormatCX(new ApexPages.StandardController(csv));

		// null is business type, but no contextual or grouping fields
		ctr.csvFormat.Collection__c=null;
		ctr.collectionSelected();
		system.assertEquals(3, ctr.workItemFields.size(), ctr.workItemFields);
		system.assertEquals('empty', ctr.workItemFields[0].getLabel());
		system.assertEquals('First Name', ctr.workItemFields[1].getLabel());
		system.assertEquals('Last Name', ctr.workItemFields[2].getLabel());
		
		// testing biz
		col.recordtypeid = bizID;
		update col;
		ctr.csvFormat.Collection__c=col.id;
		ctr.collectionSelected();
		// collection contains grouping and contextual fields
		system.assert(ctr.workItemFields.size() >= 3, ''+ctr.workItemFields);
		system.assertEquals('empty', ctr.workItemFields[0].getLabel());
		system.assertEquals('First Name', ctr.workItemFields[1].getLabel());
		system.assertEquals('Last Name', ctr.workItemFields[2].getLabel());

		// testing Social
		col.recordtypeid = socID;
		update col;
		ctr.csvFormat.Collection__c=col.id;
		ctr.collectionSelected();
		system.assert(ctr.workItemFields.size() >= 3, ctr.workItemFields);
		system.assertEquals('empty', ctr.workItemFields[0].getLabel());
		system.assertEquals('First Name', ctr.workItemFields[1].getLabel());
		system.assertEquals('Wave', ctr.workItemFields[2].getLabel());

		// testing census
		col.recordtypeid = cenID;
		update col;
		ctr.csvFormat.Collection__c=col.id;
		ctr.collectionSelected();
		system.assert(ctr.workItemFields.size() >= 3, ctr.workItemFields);
		system.assertEquals('empty', ctr.workItemFields[0].getLabel());
		system.assertEquals('Access Code', ctr.workItemFields[1].getLabel()); // sorting order changed
		system.assertEquals('First Name', ctr.workItemFields[2].getLabel());

	}

	// Helper methods
	static Boolean apexPageContainsMessage(String messageToCheckFor) {
		List<Apexpages.Message> messages = ApexPages.getMessages();

		for(Apexpages.Message message : Messages){
			if (message.getDetail().contains(messageToCheckFor)) {
				return true;
			}
		}

		return false;
	}

	static Integer getCurrentNumberOfCSVFormats() {
		List<Work_Item_CSV_Format__c> csvFormats = [
			SELECT ID
			FROM Work_Item_CSV_Format__c
		];
		
		return csvFormats.size();
	}
}