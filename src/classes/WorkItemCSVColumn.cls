/**
* @author Joseph Newby
* @date 07.Sep.2015
*/

global class WorkItemCSVColumn implements Comparable {
    public String name  { get; private set; }
    public String label { get; private set; }
    public String value { get; set; }
    public Integer columnNumber { get; private set; }
    
    public static WorkItemCSVColumn Create(Schema.sObjectField objectField) {
        Schema.DescribeFieldResult fieldResult = objectField.getDescribe();
        Boolean isNotColumnField = !fieldResult.name.startsWithIgnoreCase('column_header_');
        
        if(isNotColumnField) {
            return null;
        }

        WorkItemCSVColumn column = new WorkItemCSVColumn();

        column.name = fieldResult.name;
        column.label = fieldResult.label;
        column.columnNumber = getNumberFromColumnName(fieldResult.name);

        return column;
    }
    
    // Compare WorkItemCSVColumn based on the integer at the end of name E.g. column_header_1__c
    global Integer compareTo(Object compareTo) {
        // Cast argument to WorkItemCSVColumn
        WorkItemCSVColumn compareToWorkItemCSVColumn = (WorkItemCSVColumn) compareTo;

        // Set return value to a positive value.
        if (columnNumber > compareToWorkItemCSVColumn.columnNumber) {
            return 1;
        } 
        
        // Set return value to a negative value.
        if (columnNumber < compareToWorkItemCSVColumn.columnNumber) {
            return -1;
        }
        
        // The return value of 0 indicates that both elements are equal.
        return 0;       
    }
    
    @TestVisible
    private static Integer getNumberFromColumnName(String columnName) {
        String columnNumber = columnName
            .toLowerCase()
            .removeStart('column_header_')
            .removeEnd('__c');

        return Integer.valueOf(columnNumber);
    }
}