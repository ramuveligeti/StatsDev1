@isTest 
public class GenericsObjectSelectOptionFactory_Test {
    
    @testSetup
    static void setup() {
        insert new Grouping__c(
        	GR_1_Label__c = 'Grouping Label 1'
        );
    }
    
    @isTest
    static void querySelectOptionFields() {
        // Arrange
        Grouping__c grouping = [select id from Grouping__c limit 1];
        List<String> fieldsToSelect = new List<String> { '_label__c' };
        GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, fieldsToSelect);
        
        // Act
        List<SelectOption> groupingSelectOptions = factory.querySelectOptionFields('Grouping');

        // Assert
        System.assertEquals(4, groupingSelectOptions.size());
    }

	@isTest
    static void getsObjectsFieldNames_Given_Grouping_Returns_ListOf10FieldStrings() {
        // Arrange
        Grouping__c grouping = [select id from Grouping__c limit 1];
        List<String> fieldsToSelect = new List<String> { '_label__c' };
        GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, fieldsToSelect);
        
        // Act
        List<String> fields = factory.getsObjectsFieldNames();

        // Assert
        System.assertEquals(10, fields.size());
    }
    
    @isTest
    static void createSelectListWithTitle_Returns_ListOf3SelectOptions() {
        // Arrange
        Grouping__c grouping = [select id from Grouping__c limit 1];
        List<String> fieldsToSelect = new List<String> { '_label__c' };
        GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, fieldsToSelect);
        
        // Act
        List<SelectOption> sectionTitleSelectionOptions = factory.createSelectOptionSectionTitle('Grouping');

        // Assert
        System.assertEquals(3, sectionTitleSelectionOptions.size());
    }
    
    @isTest
    static void generateDatabaseQueryString() {
        // Arrange
        Grouping__c grouping = [select id from Grouping__c limit 1];
        List<String> fieldsToSelect = new List<String> { '_label__c' };
        GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, fieldsToSelect);
        List<String> fields = new List<String> { 'GR_1_Label__c' };
        String expectedQuery = 'select GR_1_Label__c from Grouping__c where id = \'' + grouping.id + '\'';
            
        // Act
        String query = factory.generateDatabaseQueryString(fields);

        // Assert
        System.assertEquals(expectedQuery, query);
    }
    
    @isTest
    static void createSelectOptionsFromFieldsOnsObject() {
        // Arrange
        Grouping__c grouping = [select id, GR_1_Label__c from Grouping__c limit 1];
        List<String> fieldsToSelect = new List<String> { '_label__c' };
        GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, fieldsToSelect);
        List<String> fields = new List<String> { 'GR_1_Label__c' };
        
        // Act
        List<SelectOption> options = factory.createSelectOptionsFromFieldsOnsObject(grouping, fields);
		SelectOption grLabel1 = options.get(0);

        // Assert
        System.assertEquals('Grouping Label 1', grLabel1.getLabel());
    }
}