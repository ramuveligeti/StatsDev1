@isTest
private class WorkItemQueryString_Test
{
    @testSetup
    static void setup() {
        SmartFactory.FillAllFields = true;

        Collection__c collection = TestDataHelper.createCollection(true);

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

        insert new Work_Item_CSV_Format__c(
            Name = 'Example Work Item CSV Format',
            Column_Header_1__c = 'Column 1'
        );

        TestDataHelper.createActivitySchedule(collectionInstance.Id, true);
    }

    @isTest
    static void queryFilteringWorkItemsUsingWorkItemTypeAndDeliveryMode() {
        String workItemType = '';
        String deliveryMode = '';
        Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
        Work_Item_CSV_Format__c workItemCSVFormat = [select Id from Work_Item_CSV_Format__c limit 1];
        WorkItemQueryString workItemQueryString = new WorkItemQueryString(workItemCSVFormat.Id, collectionInstance.Id, workItemType, deliveryMode);

        String expected = 'SELECT Id, Status__c FROM Work_Item__c WHERE Status__c = \'New\' AND Collection_Instance__c = \'' + collectionInstance.Id
            + '\' AND Work_Item_Type__c = \'' + workItemType + '\' AND Delivery_mode__c = \'' + deliveryMode + '\'';
        String actual = workItemQueryString.Build();

        System.assertEquals(expected, actual);
    }

    @isTest
    static void queryFilteringWorkItemsUsingActivitySchedule() {
        Activity_Schedule__c activitySchedule = [select Id from Activity_Schedule__c limit 1];
        Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
        Work_Item_CSV_Format__c workItemCSVFormat = [select Id from Work_Item_CSV_Format__c limit 1];
        WorkItemQueryString workItemQueryString = new WorkItemQueryString(workItemCSVFormat.Id, collectionInstance.Id, activitySchedule.Id);

        String expected = 'SELECT Id, Status__c FROM Work_Item__c WHERE Status__c = \'New\' AND Collection_Instance__c = \'' + collectionInstance.Id + '\' AND Activity_Schedule__c = \'' + activitySchedule.Id + '\'';
        String actual = workItemQueryString.Build();

        System.assertEquals(expected, actual);
    }
}