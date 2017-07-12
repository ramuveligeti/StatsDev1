public class WorkItemQueryString {
    final Id workItemCSVFormat;
    final Id collectionInstance;
    final Id activitySchedule;
    final String workItemType;
    final String deliveryMode;

    public WorkItemQueryString(Id workItemCSVFormat, Id collectionInstance, Id activitySchedule) {
        this.workItemCSVFormat = workItemCSVFormat;
        this.collectionInstance = collectionInstance;
        this.activitySchedule = activitySchedule;
    }

    public WorkItemQueryString(Id workItemCSVFormat, Id collectionInstance, String workItemType, String deliveryMode) {
        this.workItemCSVFormat = workItemCSVFormat;
        this.collectionInstance = collectionInstance;
        this.workItemType = workItemType;
        this.deliveryMode = deliveryMode;
    }

    public String build() {
        String whereFilter = buildWhere();
        return 'SELECT Id, Status__c FROM Work_Item__c ' + whereFilter;
    }

    private String buildWhere() {
        String whereFilter = 'WHERE Status__c = \'New\' AND Collection_Instance__c = \'' + collectionInstance + '\' ';

        if (activitySchedule != null) {
            return whereFilter + 'AND Activity_Schedule__c = \'' + activitySchedule + '\'';
        }

        return whereFilter  + 'AND Work_Item_Type__c = \'' + workItemType + '\' AND Delivery_mode__c = \'' + deliveryMode + '\'';
    }
}