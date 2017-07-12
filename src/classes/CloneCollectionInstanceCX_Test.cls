@isTest
private class CloneCollectionInstanceCX_Test {
    static CloneCollectionInstanceCX controller() {
        return controller('Collections');
    }
    
    static CloneCollectionInstanceCX controller(string recordTypeName) {
        Collection__c collection = new Collection__c();
        insert collection;

        Date today = system.today();
        
        RecordType recordType = [
            select Name
            from RecordType
            where Name = :recordTypeName
            and SobjectType ='Collection_Instance__c'
            limit 1
        ];

        insert new Collection_Instance__c(
            Collection__c = collection.Id,
            Target_Response_Type__c = null,
            Collection_Instance_Priority__c = 9,
            Behavioural_Weighting__c = 70,
            Statistical_Weighting__c = 30,
            Batch_Job_ID__c = null,
            Collection_Number__c = 1,
            Reference_Period__c = '201803',
            Planned_Start_Date__c = today.addDays(-10),
            Planned_End_Date__c = today.addDays(100),
            Extension_Cut_off_Date__c = today.addDays(9),
            Actual_Start_Date__c = today.addDays(2),
            Actual_End_Date__c = today.addDays(90),
            Actual_Close_Off__c = today.addDays(8),
            Return_date__c = today.addDays(85),
            RecordTypeId = recordType.Id
        );
        
        Collection_Instance__c collectionInstance = [
            Select 
                RecordType.Id,
                RecordType.Name,
                Collection__c,
                Name,
                Collection_Instance_Code__c,
                Response_Rate__c,
                Grouping__c,
                Contextual_Mappings__c,
                Statistical_Weighting__c,
                Behavioural_Weighting__c,
                Primary_Mode__c,
                Collection_Number__c,
                Delivery_Mode__c,
                Status__c,
                Target_Response_Type__c
            From Collection_Instance__c
            where RecordType.Name = :recordTypeName
            Limit 1
        ];
        
        Activity_Schedule__c activitySchedule = TestDataHelper.createActivitySchedule(collectionInstance.Id, true);
        Activity_Schedule_Filter__c filter = TestDataHelper.createActivityScheduleFilter(activitySchedule.Id, false);
        filter.Status__c = 'Scheduled';
        insert filter;
        ApexPages.StandardController standardController = new ApexPages.StandardController(collectionInstance);
        return new CloneCollectionInstanceCX(standardController);
    }
    
    @isTest
    static void getCollectionInstanceClone() {
        CloneCollectionInstanceCX controller = controller();
        Collection_Instance__c collectionInstance = controller.getCollectionInstanceClone();
        System.assert(collectionInstance != null);
    }
    
    @isTest
    static void getActivityScheduleClones() {
        CloneCollectionInstanceCX controller = controller();
        List<ActivityScheduleClone> activityScheduleClone = controller.getActivityScheduleClones();
        System.assert(!activityScheduleClone.isEmpty());
    }

    @isTest
    static void getRecordType() {
        CloneCollectionInstanceCX controller = controller();
        String recordType = controller.getRecordType();
        System.assertEquals('Collections', recordType);
    }

    @isTest
    static void getIsCensus() {
        CloneCollectionInstanceCX controller = controller('Census');
        System.assert(controller.getIsCensus());
    }

    @isTest
    static void getIsCollections() {
        CloneCollectionInstanceCX controller = controller('Collections');
        System.assert(controller.getIsCollections());
    }

    @isTest
    static void getIsSocial() {
        CloneCollectionInstanceCX controller = controller('Social');
        System.assert(controller.getIsSocial());
    }

    @isTest
    static void save() {
        CloneCollectionInstanceCX controller = controller();
        Collection_Instance__c collectionInstance = controller.getCollectionInstanceClone();
        collectionInstance.name = 'Cloned_Collection_Instance_1';
        PageReference pageReference = controller.save();
        System.assert(pageReference != null);
    }

    @isTest
    static void cancel() {
        CloneCollectionInstanceCX controller = controller();
        PageReference redirectHome = controller.cancel();
        System.assert(redirectHome != null);
    }
    
    @isTest
    static void markActivityScheduelForCloning() {
        CloneCollectionInstanceCX controller = controller();
        List<ActivityScheduleClone> activitySchedules = controller.getActivityScheduleClones();
        
        for (ActivityScheduleClone clone : activitySchedules) {
            Activity_Schedule__c activitySchedule = clone.getActivitySchedule();
            activitySchedule.Scheduled_Date_time__c = Datetime.now().addDays(1);
            clone.includeInClone = true;
        }
        Collection_Instance__c collectionInstance = controller.getCollectionInstanceClone();
        collectionInstance.name = 'Cloned_Collection_Instance_1';
        PageReference pageReference = controller.save();
        System.assert(pageReference != null);
    }
    
    @isTest static void testWorkloadClone(){
    	Collection__c collection = new Collection__c();
        insert collection;
    	Collection_Instance__c ci = new Collection_Instance__c(
            Collection__c = collection.Id,
            Target_Response_Type__c = null,
            Collection_Instance_Priority__c = 9,
            Behavioural_Weighting__c = 70,
            Collection_Number__c = 1, 
            Statistical_Weighting__c = 30,
            Batch_Job_ID__c = null,
            Reference_Period__c = '201803',
            Planned_Start_Date__c = system.today().addDays(-10),
            RecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Social').getRecordTypeId()
        );
        insert ci;
        insert new Workload__c(Collection_Instance__c = ci.Id, Area_Unit_Reference__c = '222', Area_Unit_Name__c = 'Remuera');
		test.startTest();
		PageReference page = new PageReference('CloneCollectionInstance?id=' + ci.Id);
        Test.setCurrentPage(page);
		ApexPages.StandardController standardController = new ApexPages.StandardController(ci);
        CloneCollectionInstanceCX controller = new CloneCollectionInstanceCX(standardController);
        controller.save();
        test.stopTest();
        // check the workload was cloned
		System.assertEquals(2,[select count() from Workload__c]);
		// check the collection number is sequential
		list<Collection_Instance__c> clone = new list<Collection_Instance__c>([Select Collection__c, Target_Response_Type__c, Collection_Instance_Priority__c, Behavioural_Weighting__c, Collection_Number__c From Collection_Instance__c]);
		system.debug('## CI: ' + clone );
		System.assertEquals(1,[Select count() From Collection_Instance__c where Collection_Number__c = 2]);
		
    } 
}