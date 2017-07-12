/**
* @description   Test class for the CreateWorkItemsExCon Class
* @author        Ram Veligeti
* @date          7.04.2015
*/
@isTest
private class CreateWorkItemsExCon_Test {
    @testSetup static void setupData(){
        Response_API_Properties__c resApi = new Response_API_Properties__c();
        resApi.Name = 'response.status.closed';
        resApi.Value__c = 'Completed';
        Response_API_Properties__c resApi1 = new Response_API_Properties__c();
        resApi1.Name = 'activity.status.closed';
        resApi1.Value__c = 'Completed';
        Response_API_Properties__c resApi2 = new Response_API_Properties__c();
        resApi2.Name = 'error.folder.name';
        resApi2.Value__c = 'API Errors';
        Response_API_Properties__c resApi3 = new Response_API_Properties__c();
        resApi3.Name = 'workitem.status.closed';
        resApi3.Value__c = 'Completed';
        insert new List<Response_API_Properties__c>{resApi,resApi1,resApi2,resApi3};
		                
        Work_Item_Creation_Filters__c cw = new Work_Item_Creation_Filters__c();
        cw.Name = 'Wave';
        cw.Data_Type__c = 'String';
        cw.Field_API__c = 'Wave__c';
        Work_Item_Creation_Filters__c cw1 = new Work_Item_Creation_Filters__c();
        cw1.Name = 'Meshblock Code';
        cw1.Data_Type__c = 'String';
        cw1.Field_API__c = 'Meshblock_Code__c';
        Work_Item_Creation_Filters__c cw2 = new Work_Item_Creation_Filters__c();
        cw2.Name = 'Postcode';
        cw2.Data_Type__c = 'Picklist';
        cw2.Field_API__c = 'Unit_of_Interest__r.Address_Type__c';
        cw2.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw3 = new Work_Item_Creation_Filters__c();
        cw3.Name = 'Birth';
        cw3.Data_Type__c = 'Boolean';
        cw3.Field_API__c = 'Birth__c';
        Work_Item_Creation_Filters__c cw4 = new Work_Item_Creation_Filters__c();
        cw4.Name = 'Actual Start Date';
        cw4.Data_Type__c = 'Date';
        cw4.Field_API__c = 'Collection_Instance__r.Actual_Start_Date__c';
        cw4.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw5 = new Work_Item_Creation_Filters__c();
        cw5.Name = 'Account Managed';
        cw5.Data_Type__c = 'Lookup';
        cw5.Field_API__c = 'Unit_of_Interest__r.Account_Managed__c';
        cw5.Object__c = 'User';
        Work_Item_Creation_Filters__c cw6 = new Work_Item_Creation_Filters__c();
        cw6.Name = 'Created Date';
        cw6.Data_Type__c = 'Datetime';
        cw6.Field_API__c = 'createdDate';
        cw6.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw7 = new Work_Item_Creation_Filters__c();
        cw7.Name = 'Postcode1';
        cw7.Data_Type__c = 'String';
        cw7.Field_API__c = 'Unit_of_Interest__r.Postcode__c';
        cw7.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw8 = new Work_Item_Creation_Filters__c();
        cw8.Name = 'Mailable';
        cw8.Data_Type__c = 'String';
        cw8.Field_API__c = 'Unit_of_Interest__r.Mailable__c';
        cw8.Object__c = 'Unit__c';
        Work_Item_Creation_Filters__c cw9 = new Work_Item_Creation_Filters__c();
        cw9.Name = 'Key';
        cw9.Data_Type__c = 'Boolean';
        cw9.Field_API__c = 'Key__c';
        Work_Item_Creation_Filters__c cw10 = new Work_Item_Creation_Filters__c();
        cw10.Name = 'Behavioural Priority';
        cw10.Data_Type__c = 'Integer';
        cw10.Field_API__c = 'Behavioural_Priority__c';
        Work_Item_Creation_Filters__c cw11 = new Work_Item_Creation_Filters__c();
        cw11.Name = 'Extension Date';
        cw11.Data_Type__c = 'Date';
        cw11.Field_API__c = 'Extension_Date__c';
        Work_Item_Creation_Filters__c cw12 = new Work_Item_Creation_Filters__c();
        cw12.Name = 'Delivery Mode';
        cw12.Data_Type__c = 'Picklist';
        cw12.Field_API__c = 'Collection_Instance__r.Delivery_Mode__c';
		cw12.Object__c = 'Collection_Instance__c';
        insert new List<Work_Item_Creation_Filters__c> {cw,cw1,cw2,cw3,cw4,cw5,cw6,cw7,cw8,cw9,cw10,cw11,cw12};
            
        System_Update__c su = new System_Update__c();
        su.Execute__c = false;
        insert su;

		TestDataHelper.createSystemSettings();
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'extract.filesize', value__c = '1000'),
            new SystemSettings__c(name = 'batchSize.ExtractWorkItems', value__c = '1000')
		};
   	}
    
    @isTest static void newactivityScheduleFiltersTest(){
        Collection__c col = TestDataHelper.createCollection(true);
		Grouping__c grouping = new Grouping__c(
			Collection__c = col.id,
			Active__c = true,
			GR_1_Label__c = 'GR_Label',
			GV1__c = 'GR1,GR2'
		);
		insert grouping;

		Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
			Collection__c = col.id,
			Active__c = true,
			CO_1_Label__c = 'CO_Label'
		);
		insert contextualMapping;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addHours(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        actSch.Output_CSV_Format__c = csvFormat.Id;
        insert actSch;
        Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
        actSchFilter.Filter_Name__c = 'Test';
        actSchFilter.Filter_Description__c = 'Test';
        actSchFilter.Collection__c = col.Id;
        actSchFilter.Filter_Criteria__c = 'Key__c = true AND Birth__c = true';
        actSchFilter.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Birth__c~:~=~:~Boolean~:~true';
        actSchFilter.Filter_Logic__c = '(1 AND 2)';
        insert actSchFilter;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Activity_Schedule_Filter__c asf = new Activity_Schedule_Filter__c();
        test.startTest();
        {
            Test.setCurrentPageReference(new PageReference('Page.OverrideActivityScheduleFilter')); 
			asf.Collection__c = col.Id;
			asf.Grouping__c = grouping.Id;
            ApexPages.StandardController stdController = new ApexPages.StandardController(asf);
            OverrideActivityScheduleFilterExCon oe = new OverrideActivityScheduleFilterExCon(stdController);
            oe.getRedirect();
            
            stdController = new ApexPages.StandardController(actSchFilter);
            oe = new OverrideActivityScheduleFilterExCon(stdController);
            oe.getRedirect();
            Test.setCurrentPageReference(new PageReference('Page.ActivityScheduleFilters')); 
            ApexPages.currentPage().getParameters().put('action','new');
            CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
            cwExCon.actSchFilter.Filter_Name__c = 'Test';
            cwExCon.actSchFilter.Filter_Description__c = 'Test';
            cwExCon.actSchFilter.Collection__c = col.Id;
			cwExCon.actSchFilter.Grouping__c = grouping.Id;
			cwExCon.groupingId = grouping.Id;
			cwExCon.setGroupingFilters();
            //cwExCon.actSchFilter.Filter_Criteria__c = 'Key__c = true AND Unit_of_Interest__r.LBU__c = true';
            //cwExCon.actSchFilter.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Unit_of_Interest__r.LBU__c~:~=~:~Boolean~:~true';
            Integer i = cwExCon.filterWrapperList.size()-1;
            cwExCon.filterWrapperList[i].filterOption = 'Key__c';
            cwExCon.sequence = i+1;
            cwExCon.changeValueDataType();
            cwExCon.filterWrapperList[i].filterOperator = '=';
            cwExCon.filterWrapperList[i].dataType = 'Boolean';
            cwExCon.filterWrapperList[i].value = 'true';
            cwExCon.filterWrapperList[i].sequence = i+1;

            cwExCon.addFilter();
            i = cwExCon.filterWrapperList.size()-1;
            cwExCon.filterWrapperList[i].filterOption = 'Unit_of_Interest__r.Address_Type__c';
            cwExCon.sequence = i+1;
            cwExCon.changeValueDataType();
            cwExCon.filterWrapperList[i].filterOperator = '=';
            cwExCon.filterWrapperList[i].dataType = 'Picklist';
            cwExCon.filterWrapperList[i].value = unitObj.Address_Type__c;
            cwExCon.filterWrapperList[i].sequence = i+1;

            cwExCon.addFilter();
            i = cwExCon.filterWrapperList.size()-1;
            cwExCon.filterWrapperList[i].filterOption = 'GR_1_Label__c';
            cwExCon.sequence = i+1;
            cwExCon.changeValueDataType();
            cwExCon.filterWrapperList[i].filterOperator = '=';
            cwExCon.filterWrapperList[i].dataType = 'Picklist';
            cwExCon.filterWrapperList[i].value = 'GR1';
            cwExCon.filterWrapperList[i].sequence = i+1;
            cwExCon.applyFilterLogicMethod();
            cwExCon.clearFilterLogicMethod();
            cwExCon.saveFilter();
            
            List<Activity_Schedule_Filter__c> a = [Select Id,Filter_Criteria__c from Activity_Schedule_Filter__c];
            system.assertEquals(1,a.size());
            system.assertEquals('Key__c = true AND Unit_of_Interest__r.Address_Type__c = \'12\' AND GR_Label = GR1', a[0].Filter_Criteria__c);
            //cwExCon.editRecordId = a[0].Id;
            //cwExCon.editFilter();
            //cwExCon.deleteFilter();
            //List<Activity_Schedule_Filter__c> a1 = [Select Id from Activity_Schedule_Filter__c];
            //system.assertEquals(a1.size(), 0);
        }
        test.stopTest();
    }
    
    @isTest static void editactivityScheduleFiltersTest(){
        Collection__c col = TestDataHelper.createCollection(true);
		Grouping__c grouping = new Grouping__c(
			Collection__c = col.id,
			Active__c = true,
			GR_1_Label__c = 'GR_Label',
			GV1__c = 'GR1,GR2'
		);
		insert grouping;

		Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
			Collection__c = col.id,
			Active__c = true,
			CO_1_Label__c = 'CO_Label'
		);
		insert contextualMapping;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addHours(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        actSch.Output_CSV_Format__c = csvFormat.Id;
        insert actSch;
        Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
        actSchFilter.Filter_Name__c = 'Test';
        actSchFilter.Filter_Description__c = 'Test';
        actSchFilter.Collection__c = col.Id;
		actSchFilter.Grouping__c = grouping.Id;
        actSchFilter.Filter_Criteria__c = '(TEST Group not equal to testing AND Collection_Instance__r.Delivery_Mode__c = \'Post\') OR (TEST Group not equal to testing AND Extension_Date__c not equal to null)';
        actSchFilter.Filter_Criteria_String__c = 'null~@~GR_1_Label__c~:~=~:~String~:~TEST Group AND GR_1__c~:~!=~:~String~:~testing~@~Collection_Instance__r.Delivery_Mode__c~:~=~:~Picklist~:~Post~@~Extension_Date__c~:~!= null~:~Date~:~null';
        actSchFilter.Filter_Logic__c = '(1 AND 2) OR (1 AND 3)';
        insert actSchFilter;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Activity_Schedule_Filter__c asf = new Activity_Schedule_Filter__c();
        test.startTest();
        {
            Test.setCurrentPageReference(new PageReference('Page.OverrideActivityScheduleFilter')); 
			asf.Collection__c = col.Id;
            ApexPages.StandardController stdController = new ApexPages.StandardController(asf);
            OverrideActivityScheduleFilterExCon oe = new OverrideActivityScheduleFilterExCon(stdController);
            oe.getRedirect();
            stdController = new ApexPages.StandardController(actSchFilter);
            oe = new OverrideActivityScheduleFilterExCon(stdController);
            oe.getRedirect();
            Test.setCurrentPageReference(new PageReference('Page.ActivityScheduleFilters')); 
            ApexPages.currentPage().getParameters().put('action','edit');
            CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
            system.debug('filterWrapperList=='+cwExCon.filterWrapperList);
            cwExCon.actSchFilter.Filter_Name__c = 'Test';
            cwExCon.actSchFilter.Filter_Description__c = 'Test';
            cwExCon.actSchFilter.Collection__c = col.Id;
            //cwExCon.actSchFilter.Filter_Criteria__c = 'Key__c = true AND Unit_of_Interest__r.LBU__c = true';
            //cwExCon.actSchFilter.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Unit_of_Interest__r.LBU__c~:~=~:~Boolean~:~true';
            cwExCon.addFilter();
            Integer i = cwExCon.filterWrapperList.size()-1;
            cwExCon.filterWrapperList[i].filterOption = 'Key__c';
            cwExCon.sequence = i+1;
            cwExCon.changeValueDataType();
            cwExCon.filterWrapperList[i].filterOperator = '=';
            cwExCon.filterWrapperList[i].dataType = 'Boolean';
            cwExCon.filterWrapperList[i].value = 'true';
            cwExCon.filterWrapperList[i].sequence = i+1;
            cwExCon.addFilter();

            i = cwExCon.filterWrapperList.size()-1;
            cwExCon.filterWrapperList[i].filterOption = 'Unit_of_Interest__r.Address_Type__c';
            cwExCon.sequence = i+1;
            cwExCon.changeValueDataType();
            cwExCon.filterWrapperList[i].filterOperator = '=';
            cwExCon.filterWrapperList[i].dataType = 'Picklist';
            cwExCon.filterWrapperList[i].value = unitObj.Address_Type__c;
            cwExCon.filterWrapperList[i].sequence = i+1;
            cwExCon.applyFilterLogicMethod();
            cwExCon.clearFilterLogicMethod();
            cwExCon.saveFilter();
            system.debug('filterWrapperList=='+cwExCon.filterWrapperList);
            List<Activity_Schedule_Filter__c> a = [Select Id,Filter_Criteria__c from Activity_Schedule_Filter__c];
            system.assertEquals(1,a.size());
            system.assertEquals('GR_Label not equal to testing AND Collection_Instance__r.Delivery_Mode__c = \'Post\' AND Extension_Date__c not equal to null AND Key__c = true AND Unit_of_Interest__r.Address_Type__c = \'12\'', a[0].Filter_Criteria__c);
            //cwExCon.editRecordId = a[0].Id;
            //cwExCon.editFilter();
            //cwExCon.deleteFilter();
            //List<Activity_Schedule_Filter__c> a1 = [Select Id from Activity_Schedule_Filter__c];
            //system.assertEquals(a1.size(), 0);
        }
        test.stopTest();
    }

    @isTest static void newActivitySchedule_SelectPredefinedFilter(){
        Collection__c col = TestDataHelper.createCollection(true);
		Grouping__c grouping = new Grouping__c(
			Collection__c = col.id,
			Active__c = true,
			GR_1_Label__c = 'GR_Label',
			GV1__c = 'GR1,GR2'
		);
		insert grouping;

		Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
			Collection__c = col.id,
			Active__c = true,
			CO_1_Label__c = 'CO_Label'
		);
		insert contextualMapping;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Grouping__c = grouping.Id;
        insert colIns;
        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addHours(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        actSch.Output_CSV_Format__c = csvFormat.Id;
        insert actSch;
        Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
        actSchFilter.Filter_Name__c = 'Test';
        actSchFilter.Filter_Description__c = 'Test';
        actSchFilter.Collection__c = col.Id;
		actSchFilter.Grouping__c = grouping.Id;
        actSchFilter.Filter_Criteria__c = '(TEST Group not equal to testing AND Collection_Instance__r.Delivery_Mode__c = \'Post\') OR (TEST Group not equal to testing AND Extension_Date__c not equal to null)';
        actSchFilter.Filter_Criteria_String__c = 'null~@~GR_1_Label__c~:~=~:~String~:~TEST Group AND GR_1__c~:~!=~:~String~:~testing~@~Collection_Instance__r.Delivery_Mode__c~:~=~:~Picklist~:~Post~@~Extension_Date__c~:~!= null~:~Date~:~null';
        actSchFilter.Filter_Logic__c = '(1 AND 2) OR (1 AND 3)';
        insert actSchFilter;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Activity_Schedule_Filter__c asf = new Activity_Schedule_Filter__c();
        
		Test.setCurrentPageReference(new PageReference('Page.OverrideActivityScheduleFilter')); 
		asf.Collection__c = col.Id;
        ApexPages.StandardController stdController = new ApexPages.StandardController(asf);
        OverrideActivityScheduleFilterExCon oe = new OverrideActivityScheduleFilterExCon(stdController);
        oe.getRedirect();
        stdController = new ApexPages.StandardController(actSchFilter);
        oe = new OverrideActivityScheduleFilterExCon(stdController);
        oe.getRedirect();
        Test.setCurrentPageReference(new PageReference('Page.ActivityScheduleFilters')); 
        ApexPages.currentPage().getParameters().put('action','edit');
        CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
        system.debug('filterWrapperList=='+cwExCon.filterWrapperList);
        cwExCon.actSchFilter.Filter_Name__c = 'Test';
        cwExCon.actSchFilter.Filter_Description__c = 'Test';
        cwExCon.actSchFilter.Collection__c = col.Id;
        //cwExCon.actSchFilter.Filter_Criteria__c = 'Key__c = true AND Unit_of_Interest__r.LBU__c = true';
        //cwExCon.actSchFilter.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Unit_of_Interest__r.LBU__c~:~=~:~Boolean~:~true';
        cwExCon.addFilter();
        Integer i = cwExCon.filterWrapperList.size()-1;
        cwExCon.filterWrapperList[i].filterOption = 'Key__c';
        cwExCon.sequence = i+1;
        cwExCon.changeValueDataType();
        cwExCon.filterWrapperList[i].filterOperator = '=';
        cwExCon.filterWrapperList[i].dataType = 'Boolean';
        cwExCon.filterWrapperList[i].value = 'true';
        cwExCon.filterWrapperList[i].sequence = i+1;
        cwExCon.addFilter();

        i = cwExCon.filterWrapperList.size()-1;
        cwExCon.filterWrapperList[i].filterOption = 'Unit_of_Interest__r.Address_Type__c';
        cwExCon.sequence = i+1;
        cwExCon.changeValueDataType();
        cwExCon.filterWrapperList[i].filterOperator = '=';
        cwExCon.filterWrapperList[i].dataType = 'Picklist';
        cwExCon.filterWrapperList[i].value = unitObj.Address_Type__c;
        cwExCon.filterWrapperList[i].sequence = i+1;
        cwExCon.applyFilterLogicMethod();
        cwExCon.clearFilterLogicMethod();
        cwExCon.saveFilter();
        system.debug('filterWrapperList=='+cwExCon.filterWrapperList);
        List<Activity_Schedule_Filter__c> a = [Select Id,Filter_Criteria__c from Activity_Schedule_Filter__c];
        system.assertEquals(1,a.size());
        system.assertEquals('GR_Label not equal to testing AND Collection_Instance__r.Delivery_Mode__c = \'Post\' AND Extension_Date__c not equal to null AND Key__c = true AND Unit_of_Interest__r.Address_Type__c = \'12\'', a[0].Filter_Criteria__c);

		test.startTest();
        {
            ApexPages.StandardController stdController1 = new ApexPages.StandardController(new Activity_Schedule__c(Collection_Instance__c = colIns.Id));
            CreateWorkItemsExCon cwExCon1 = new CreateWorkItemsExCon(stdController1);
            cwExCon1.actSch.Collection_Instance__c = colIns.Id;
            cwExCon1.actSch.Delivery_Mode__c = 'Post';
            cwExCon1.actSch.Work_Item_Type__c = 'Questionnaire';
            cwExCon1.actSch.Scheduled_Date_time__c = system.now().addDays(60);
            cwExCon1.actSch.Frequency__c = 'Weekly';
            cwExCon1.actSch.Occurrence__c = 2;
			cwExCon1.immediateExtract = false;
			cwExCon1.selectedFilter = 'Predefined Filter';
			System.assertEquals(cwExCon1.filterWrapperList.size(),0);
			cwExCon1.activateFilters();
			cwExCon1.preUsedFilter = actSchFilter.Id;
			cwExCon1.scheduleWorkItems();
        }
        test.stopTest();
        List<Activity_Schedule_Filter__c> a1 = [Select Id,Filter_Criteria__c from Activity_Schedule_Filter__c where Id <> :actSchFilter.Id];
        system.assertEquals(2,a1.size());
        system.assertEquals('GR_Label not equal to testing AND Collection_Instance__r.Delivery_Mode__c = \'Post\' AND Extension_Date__c not equal to null AND Key__c = true AND Unit_of_Interest__r.Address_Type__c = \'12\'', a1[0].Filter_Criteria__c);
    }

    @isTest static void newActivityScheduleTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
			Grouping__c grouping = new Grouping__c(
				Collection__c = col.id,
				Active__c = true,
				GR_1_Label__c = 'GR_Label',
				GV1__c = 'GR1,GR2'
			);
			insert grouping;

			Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
				Collection__c = col.id,
				Active__c = true,
				CO_1_Label__c = 'CO_Label'
			);
			insert contextualMapping;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
			colIns.Grouping__c = grouping.Id;
            insert colIns;
            Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
            insert csvFormat;
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
            actSch.Scheduled_Date_time__c = system.now().addHours(60);
            actSch.Frequency__c = 'Weekly';
            actSch.Occurrence__c = 2;
            actSch.Output_CSV_Format__c = csvFormat.Id;
            insert actSch;
            Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
            actSchFilter.Filter_Name__c = 'Test';
            actSchFilter.Filter_Description__c = 'Test';
            actSchFilter.Collection__c = col.Id;
            actSchFilter.Filter_Criteria__c = 'Key__c = true AND Birth__c = true';
            actSchFilter.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Birth__c~:~=~:~Boolean~:~true';
            actSchFilter.Filter_Logic__c = '(1 AND 2)';
            insert actSchFilter;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '12';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c = '12';
            insert unitObj;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp.Wave__c = '12';
            resp.Birth__c = true;
			resp.GR_1_Label__c = 'GR_Label';
			resp.GR_1__c = 'GR1';
            insert resp;
			Work_Item_CSV_Format__c csvFormat1 = new Work_Item_CSV_Format__c(
        		Name = 'Reminder Email FirstNames',
				Column_Header_1__c = 'First Name',
				Grouping__c = grouping.id,
				Contextual_Mappings__c = contextualMapping.id,
				Column_Header_2__c = 'GR_Label',
				Column_Header_3__c = 'CO_Label'
			);

			insert csvFormat1;
            Activity_Schedule__c actSch1 = new Activity_Schedule__c();
        	actSch1.Output_CSV_Format__c = csvFormat.Id;
			actSch1.Collection_Instance__c = colIns.Id;
            PageReference pageRef1 = Page.NewActivitySchedule;
            Test.setCurrentPage(pageRef1);
            
            test.startTest();
            {
                ApexPages.StandardController stdController = new ApexPages.StandardController(actSch1);
                CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
                cwExCon.actSch.Collection_Instance__c = colIns.Id;
                cwExCon.actSch.Delivery_Mode__c = 'Email';
                cwExCon.actSch.Work_Item_Type__c = 'Pre-notification';
                cwExCon.actSch.Scheduled_Date_time__c = system.now().addHours(60);
                cwExCon.actSch.Frequency__c = 'Once';
                cwExCon.actSch.Occurrence__c = 1;
                //cwExCon.saveAndSchedule();
                
                cwExCon.selectedFilter = 'Predefined Filter';
                cwExCon.activateFilters();
                cwExCon.preUsedFilter = actSchFilter.Id;
                cwExCon.showPredefinedFilter();
                
                cwExCon.addFilter();
                Integer i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Unit_of_Interest__r.Address_Type__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Picklist';
                cwExCon.filterWrapperList[i].value = unitObj.Address_Type__c;
                cwExCon.filterWrapperList[i].sequence = i+1;
                
                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Birth__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Picklist';
                cwExCon.filterWrapperList[i].value = 'true';
                cwExCon.filterWrapperList[i].sequence = i+1;

                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Collection_Instance__r.Actual_Start_Date__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].value = '2015-06-03';
                cwExCon.filterWrapperList[i].dateValue = Date.parse('03/06/2015');
                cwExCon.filterWrapperList[i].dataType = 'Date';
                cwExCon.filterWrapperList[i].sequence = i+1;

                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Meshblock_Code__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'String';
                cwExCon.filterWrapperList[i].value = '12';
                cwExCon.filterWrapperList[i].sequence = i+1;

                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Behavioural_Priority__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Integer';
                cwExCon.filterWrapperList[i].value = '12';
                cwExCon.filterWrapperList[i].sequence = i+1;
                
                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Behavioural_Priority__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Integer';
                cwExCon.filterWrapperList[i].value = '13';
                cwExCon.filterWrapperList[i].sequence = i+1;
                
                cwExCon.addFilter();
                userObj = [Select Id,name from user where Id = :userObj.Id];
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'Unit_of_Interest__r.Account_Managed__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Lookup';
                cwExCon.filterWrapperList[i].lookupValue = userObj.Name;
                cwExCon.filterWrapperList[i].sequence = i+1;
				cwExCon.addFilter();
                system.debug('cwExCon=='+cwExCon.filterWrapperList);

                cwExCon.removeId = 9;
                cwExCon.removeSelected();
                cwExCon.removeId = 8;
                cwExCon.removeSelected();
                cwExCon.addFilter();
                i = cwExCon.filterWrapperList.size()-1;
                cwExCon.filterWrapperList[i].filterOption = 'GR_1_Label__c';
                cwExCon.sequence = i+1;
                cwExCon.changeValueDataType();
                cwExCon.filterWrapperList[i].filterOperator = '=';
                cwExCon.filterWrapperList[i].dataType = 'Picklist';
                cwExCon.filterWrapperList[i].value = 'GR1';
                cwExCon.filterWrapperList[i].sequence = i+1;

                cwExCon.applyFilterLogicMethod();
                cwExCon.clearFilterLogicMethod();
				cwExCon.filterLogic = '(1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7 AND 8) OR 9';
                cwExCon.immediateExtract = false;
				cwExCon.scheduleWorkItems();
                
                List<Activity_Schedule_Filter__c> a = [Select Id,Filter_Criteria__c from Activity_Schedule_Filter__c where Id <> :actSchFilter.Id];
                system.assertEquals(1,a.size());
                system.assertEquals('( Key__c = true AND Birth__c = true AND Unit_of_Interest__r.Address_Type__c = \'12\' AND Birth__c = true AND Collection_Instance__r.Actual_Start_Date__c = 2015-06-03 AND Meshblock_Code__c = \'12\' AND Behavioural_Priority__c = 12 AND Behavioural_Priority__c = 13 ) OR GR_Label = GR1', a[0].Filter_Criteria__c);
				List<Activity_Schedule__c> asch = [Select Id,Estimated_Work_Items_Count__c from Activity_Schedule__c];
				System.assertEquals(2,asch.size());
				System.assertEquals('1',asch[1].Estimated_Work_Items_Count__c);
            }
            test.stopTest();
        }
    }

    @isTest static void activityScheduleFiltersTest1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;
        Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.Artefact_Code__c = '321';
        artefact.Delivery_Modes__c = 'Post;Email';
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Status__c = 'Active';
        insert artefact;
        Artefact__c artefact1 = TestDataHelper.createArtefact(col.Id, false);
        artefact1.Artefact_Code__c = '123';
        artefact1.Delivery_Modes__c = 'Post;Email';
        artefact1.Status__c = 'Active';
        artefact1.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
        insert artefact1;
        Artefact__c artefact2 = TestDataHelper.createArtefact(col.Id, false);
        artefact2.Artefact_Code__c = '4321';
        artefact2.Delivery_Modes__c = 'Post';
        artefact2.Status__c = 'Active';
        artefact2.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        insert artefact2;
        Artefact__c artefact3 = TestDataHelper.createArtefact(col.Id, false);
        artefact3.Artefact_Code__c = '1234';
        artefact3.Delivery_Modes__c = 'Post;Email';
        artefact3.Status__c = 'Active';
        artefact3.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
        insert artefact3;
        Pack__c pack = TestDataHelper.createPack(col.Id, true);
        Pack_Contents__c pc = TestDataHelper.createPackContents(pack.Id, artefact.Id, false);
        pc.Number_of_Copies__c = 1;
        insert pc;
        Pack_Contents__c pc1 = TestDataHelper.createPackContents(pack.Id, artefact1.Id, false);
        pc1.Number_of_Copies__c = 1;
        insert pc1;
        Pack_Contents__c pc2 = TestDataHelper.createPackContents(pack.Id, artefact2.Id, false);
        pc2.Number_of_Copies__c = 1;
        insert pc2;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addHours(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        actSch.Output_CSV_Format__c = csvFormat.Id;
        actSch.Pack__c = pack.Id;
        insert actSch;
        actSch = [Select Id,Scheduled_Date_time__c,Frequency__c,Occurrence__c,Collection_Instance_Name__c,Collection_Instance__c,Collection_Instance__r.Collection__c from Activity_Schedule__c where Id = :actSch.Id];
        Activity_Schedule_Filter__c actSchFil = TestDataHelper.createActivityScheduleFilter(actSch.Id, false);
        actSchFil.Status__c = 'Scheduled';
        actSchFil.Scheduled_Date_time__c = system.now()+1;
        actSchFil.Filter_Criteria__c = 'Key__c = true AND Birth__c = true';
        actSchFil.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Birth__c~:~=~:~Boolean~:~true';
        insert actSchFil;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp.Wave__c = '12';
        resp.Birth__c = true;
        insert resp;
        Activity_Schedule__c actSch1 = new Activity_Schedule__c();
		actSch1.Collection_Instance__c = colIns.Id;
        test.startTest();
		//Activity_Schedule_Filter__c actSchFil1 = new Activity_Schedule_Filter__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(actSch1);
        CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
        cwExCon.actSch.Collection_Instance__c = colIns.Id;
        cwExCon.actSch.Delivery_Mode__c = 'Email';
        cwExCon.actSch.Work_Item_Type__c = 'Pre-notification';
        cwExCon.actSch.Scheduled_Date_time__c = system.now().addHours(60);
        cwExCon.actSch.Frequency__c = 'Once';
        cwExCon.actSch.Occurrence__c = 1;
        cwExCon.scheduleWorkItems();   
        cwExCon.applyFilters = false;
        cwExCon.selectedFilter = 'No Filter';
        cwExCon.activateFilters();
        cwExCon.immediateExtract = false;
        cwExCon.scheduleWorkItems();
        
        List<Activity_Schedule_Filter__c> af = [Select Id from Activity_Schedule_Filter__c where Id <> :actSchFil.id];
        system.assertEquals(1,af.size());
        
        List<Activity_Schedule__c> at = [Select Id from Activity_Schedule__c where Id <> :actSch.Id];
        system.assertEquals(1,at.size());
        test.stopTest();
    }
     
    @isTest static void activityScheduleFiltersValidationsTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        insert colIns;
        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;
        Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.Artefact_Code__c = '321';
        artefact.Delivery_Modes__c = 'Post;Email';
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Status__c = 'Active';
        insert artefact;
        Artefact__c artefact1 = TestDataHelper.createArtefact(col.Id, false);
        artefact1.Artefact_Code__c = '123';
        artefact1.Delivery_Modes__c = 'Post;Email';
        artefact1.Status__c = 'Active';
        artefact1.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
        insert artefact1;
        Artefact__c artefact2 = TestDataHelper.createArtefact(col.Id, false);
        artefact2.Artefact_Code__c = '4321';
        artefact2.Delivery_Modes__c = 'Post';
        artefact2.Status__c = 'Active';
        artefact2.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        insert artefact2;
        Artefact__c artefact3 = TestDataHelper.createArtefact(col.Id, false);
        artefact3.Artefact_Code__c = '1234';
        artefact3.Delivery_Modes__c = 'Post;Email';
        artefact3.Status__c = 'Active';
        artefact3.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
        insert artefact3;
        Pack__c pack = TestDataHelper.createPack(col.Id, true);
        Pack_Contents__c pc = TestDataHelper.createPackContents(pack.Id, artefact.Id, false);
        pc.Number_of_Copies__c = 1;
        insert pc;
        Pack_Contents__c pc1 = TestDataHelper.createPackContents(pack.Id, artefact1.Id, false);
        pc1.Number_of_Copies__c = 1;
        insert pc1;
        Pack_Contents__c pc2 = TestDataHelper.createPackContents(pack.Id, artefact2.Id, false);
        pc2.Number_of_Copies__c = 1;
        insert pc2;
        Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
        actSch.Scheduled_Date_time__c = system.now().addHours(60);
        actSch.Frequency__c = 'Weekly';
        actSch.Occurrence__c = 2;
        actSch.Output_CSV_Format__c = csvFormat.Id;
        actSch.Pack__c = pack.Id;
        insert actSch;
        actSch = [Select Id,Scheduled_Date_time__c,Frequency__c,Occurrence__c,Collection_Instance_Name__c,Collection_Instance__c,Collection_Instance__r.Collection__c from Activity_Schedule__c where Id = :actSch.Id];
        Activity_Schedule_Filter__c actSchFil = TestDataHelper.createActivityScheduleFilter(actSch.Id, false);
        actSchFil.Status__c = 'Scheduled';
        actSchFil.Scheduled_Date_time__c = system.now()+1;
        actSchFil.Filter_Criteria__c = 'Key__c = true AND Birth__c = true';
        actSchFil.Filter_Criteria_String__c = 'null~@~Key__c~:~=~:~Boolean~:~true~@~Birth__c~:~=~:~Boolean~:~true';
        insert actSchFil;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ENXXX';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        insert unitObj;
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        resp.Wave__c = '12';
        resp.Birth__c = true;
        insert resp;

        test.startTest();
		//Activity_Schedule_Filter__c actSchFil1 = new Activity_Schedule_Filter__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Activity_Schedule__c(Collection_Instance__c = colIns.Id));
        CreateWorkItemsExCon cwExCon = new CreateWorkItemsExCon(stdController);
        cwExCon.actSch.Collection_Instance__c = colIns.Id;
        cwExCon.actSch.Delivery_Mode__c = null;
        cwExCon.scheduleWorkItems();  
        
        cwExCon.actSch.Delivery_Mode__c = 'Email';
        cwExCon.actSch.Work_Item_Type__c = 'Pre-notification';
        cwExCon.actSch.Frequency__c = 'Once';
        cwExCon.actSch.Scheduled_Date_time__c = system.now().addHours(-60);
        cwExCon.scheduleWorkItems();  
        cwExCon.actSch.Scheduled_Date_time__c = system.now().addHours(60);
        cwExCon.scheduleWorkItems();   
        cwExCon.actSch.Occurrence__c = -1;
        cwExCon.scheduleWorkItems();   
        cwExCon.actSch.Frequency__c = 'Weekly';
        cwExCon.actSch.Occurrence__c = null;
        cwExCon.scheduleWorkItems();   
        cwExCon.actSch.Frequency__c = 'Once';
        cwExCon.actSch.Occurrence__c = 1;
        cwExCon.scheduleWorkItems();   
        cwExCon.applyFilters = false;
        cwExCon.selectedFilter = 'No Filter';
        cwExCon.activateFilters();
        cwExCon.immediateExtract = false;
        cwExCon.scheduleWorkItems();
        
        List<Activity_Schedule_Filter__c> af = [Select Id from Activity_Schedule_Filter__c where Id <> :actSchFil.id];
        system.assertEquals(1,af.size());
        
        List<Activity_Schedule__c> at = [Select Id from Activity_Schedule__c where Id <> :actSch.Id];
        system.assertEquals(1,at.size());
        test.stopTest();
    }

    @isTest static void newActivityScheduleTest12(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
			Grouping__c grouping = new Grouping__c(
				Collection__c = col.id,
				Active__c = true,
				GR_1_Label__c = 'GR_Label',
				GV1__c = 'GR1,GR2'
			);
			insert grouping;

			Contextual_Mappings__c contextualMapping = new Contextual_Mappings__c(
				Collection__c = col.id,
				Active__c = true,
				CO_1_Label__c = 'CO_Label'
			);
			insert contextualMapping;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            colIns.RecordTypeId = Collection_Instance__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collections').getRecordTypeId();
			colIns.Grouping__c = grouping.Id;
            insert colIns;
            Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
            insert csvFormat;
            Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
            artefact.Artefact_Code__c = '321';
            artefact.Delivery_Modes__c = 'Post;Email';
            artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
            artefact.Status__c = 'Active';
            insert artefact;
            Artefact__c artefact1 = TestDataHelper.createArtefact(col.Id, false);
            artefact1.Artefact_Code__c = '123';
            artefact1.Delivery_Modes__c = 'Post;Email';
            artefact1.Status__c = 'Active';
            artefact1.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
            insert artefact1;
            Artefact__c artefact2 = TestDataHelper.createArtefact(col.Id, false);
            artefact2.Artefact_Code__c = '4321';
            artefact2.Delivery_Modes__c = 'Post';
            artefact2.Status__c = 'Active';
            artefact2.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
            insert artefact2;
            Artefact__c artefact3 = TestDataHelper.createArtefact(col.Id, false);
            artefact3.Artefact_Code__c = '1234';
            artefact3.Delivery_Modes__c = 'Post;Email';
            artefact3.Status__c = 'Active';
            artefact3.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
            insert artefact3;
            Pack__c pack = TestDataHelper.createPack(col.Id, true);
            Pack_Contents__c pc = TestDataHelper.createPackContents(pack.Id, artefact.Id, false);
            pc.Number_of_Copies__c = 1;
            insert pc;
            Pack_Contents__c pc1 = TestDataHelper.createPackContents(pack.Id, artefact1.Id, false);
            pc1.Number_of_Copies__c = 1;
            insert pc1;
            Pack_Contents__c pc2 = TestDataHelper.createPackContents(pack.Id, artefact2.Id, false);
            pc2.Number_of_Copies__c = 1;
            insert pc2;
            Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(colIns.Id,false);
            actSch.Scheduled_Date_time__c = system.now().addHours(60);
            actSch.Frequency__c = 'Weekly';
            actSch.Occurrence__c = 2;
            actSch.Output_CSV_Format__c = csvFormat.Id;
            actSch.Pack__c = pack.Id;
            insert actSch;
            Activity_Schedule_Filter__c actSchFil = TestDataHelper.createActivityScheduleFilter(actSch.Id, false);
            actSchFil.Status__c = 'Scheduled';
            actSchFil.Scheduled_Date_time__c = system.now()+1;
            insert actSchFil;
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '12';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c = '12';
            insert unitObj;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
            resp.Wave__c = '12';
            resp.Birth__c = true;
			resp.GR_1_Label__c = 'GR_Label';
			resp.GR_1__c = 'GR1';
            resp.Extension_Date__c = system.today().addDays(2);
            insert resp;
            
            //PageReference pageRef1 = Page.ScheduleWorkItems;
            //Test.setCurrentPage(pageRef1);
            test.startTest();
            {
                ApexPages.StandardController stdController = new ApexPages.StandardController(new Activity_Schedule__c(Collection_Instance__c = colIns.Id));
                CreateWorkItemsExCon cwExCon1 = new CreateWorkItemsExCon(stdController);
                cwExCon1.actSch.Collection_Instance__c = colIns.Id;
                cwExCon1.actSch.Delivery_Mode__c = 'Post';
                cwExCon1.actSch.Work_Item_Type__c = 'Questionnaire';
                cwExCon1.actSch.Scheduled_Date_time__c = system.now().addMinutes(60);
                cwExCon1.actSch.Frequency__c = 'Weekly';
                cwExCon1.actSch.Occurrence__c = 2;
                cwExCon1.actSch.Pack__c = pack.Id;
				cwExCon1.immediateExtract = false;
				cwExCon1.estimateWorkItems();
				System.assertEquals('1',cwExCon1.estimatedWorkItemsCount);
                cwExCon1.scheduleWorkItems();
                actSch = [Select Id,Collection_Instance__c,Pack__c,Output_CSV_Format__c,Work_Item_Type__c,Delivery_Mode__c from Activity_Schedule__c where Id = :actSch.Id];
                resp = [Select Id, Extension_Date__c,Wave__c from Response__c where Id = :resp.Id];
                String queryString = 'Select Id, Collection_Instance__c, Extension_Date__c,Wave__c,Meshblock_Code__c,Unit_of_Interest__r.Address_Type__c,Birth__c from Response__c where (Wave__c=\''+resp.Wave__c+'\' AND Meshblock_Code__c=\''+unitObj.Meshblock_Code__c+'\' AND Unit_of_Interest__r.Address_Type__c=\''+unitObj.Address_Type__c+'\' AND Birth__c=true) AND Collection_Instance__c = \''+colIns.Id+'\'';
                CreateWorkItemsBatch cwib = new CreateWorkItemsBatch(queryString,col.Name,actSchFil.Id,actSch.Id,null,true);
                String cronID = database.executeBatch(cwib);
				Error_log__c el = new Error_log__c();
				el.Process_Name__c = 'Extract Work Item Batch';
				el.Exception_Message__c = 'No Output CSV Format found for the Activit Activity_Schedule__c (Record Id:'+actSch.Id+')';
				insert el;
				cwib.sendActivityScheduleConfirmationEmail('Extract Work Item Batch',new List<Error_Log__c>{el});
            }
            test.stopTest();
            //List<Error_Log__c> el =[Select Id,Exception_Message__c from Error_Log__c];
            
            List<Activity_Schedule_Filter__c> asf = [Select Id,Actual_Work_Items_Count__c from Activity_Schedule_Filter__c where Activity_Schedule__c = :actSch.Id];
            system.assertEquals(asf.size(),1);
            List<Work_Item__c> wi = [Select Id,Pack__c,Call_Back_Time__c from Work_Item__c];
            //system.debug('el[0].Exception_Message__c=='+el[0].Exception_Message__c);
            //system.assertEquals(pack.Id,wi[0].Pack__c);
			//System.assertEquals(resp.Extension_Date__c.addDays(1),wi[0].Call_Back_Time__c);
			List<Activity_Schedule__c> asch = [Select Id,Estimated_Work_Items_Count__c from Activity_Schedule__c];
			System.assertEquals(asch[0].Id,actSch.Id,asch);
			System.assertEquals(String.valueOf(wi.size()),asch[1].Estimated_Work_Items_Count__c);
        }
    }  
}