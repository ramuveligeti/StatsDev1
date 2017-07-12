/**
* @author Joseph Newby
* @date 08.Sep.2015
*/

@isTest 
public class WorkItemCSVColumn_Test {
    
    static WorkItemCSVColumn getColumnHeader1() {
		Map<String, Schema.sObjectField> fields = Schema.getGlobalDescribe().get('Work_Item_CSV_Format__c').getDescribe().fields.getMap();

        for (Schema.sObjectField objectField : fields.values()) {
            WorkItemCSVColumn column = WorkItemCSVColumn.Create(objectField);
            
            if (column == null) {
                continue;
            }

            if (column.columnNumber == 1) {
                return column;
            }
        }
        
        return null;
    }

    static WorkItemCSVColumn getColumnHeader2() {
		Map<String, Schema.sObjectField> fields = Schema.getGlobalDescribe().get('Work_Item_CSV_Format__c').getDescribe().fields.getMap();

        for (Schema.sObjectField objectField : fields.values()) {
            WorkItemCSVColumn column = WorkItemCSVColumn.Create(objectField);
            
            if (column == null) {
                continue;
            }

            if (column.columnNumber == 2) {
                return column;
            }
        }
        
        return null;
    }

	@isTest
    static void getNumberFromColumnName_Returns_ColumnNumber() {
        Integer columnNumber = WorkItemCSVColumn.getNumberFromColumnName('Column_Header_19__c');
        
		System.assertEquals(19, columnNumber);
    }
    
    @isTest
    static void compareTo_ColumnHeader2_Is_Greater_Than_ColumnHeader1() {
        // Arrange
		WorkItemCSVColumn columnHeader1 = getColumnHeader1();
		WorkItemCSVColumn columnHeader2 = getColumnHeader2();
        
        // Act
        Integer compareInt = columnHeader2.compareTo(columnHeader1);

        // Assert
        System.assertEquals(1, compareInt);
    }
    
    @isTest
    static void compareTo_ColumnHeader1_Is_Less_Than_ColumnHeader2() {
        // Arrange
		WorkItemCSVColumn columnHeader1 = getColumnHeader1();
		WorkItemCSVColumn columnHeader2 = getColumnHeader2();
        
        // Act
        Integer compareInt = columnHeader1.compareTo(columnHeader2);

        // Assert
        System.assertEquals(-1, compareInt);
    }
    
    @isTest
    static void compareTo_ColumnHeader1_Is_Equal_To_ColumnHeader1() {
        // Arrange
		WorkItemCSVColumn columnHeader1 = getColumnHeader1();
		WorkItemCSVColumn columnHeader1_dup = getColumnHeader1();
        
        // Act
        Integer compareInt = columnHeader1.compareTo(columnHeader1_dup);

        // Assert
        System.assertEquals(0, compareInt);
    }
}