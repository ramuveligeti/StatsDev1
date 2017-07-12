/**
* @description   Test class for the ExtractWorkItemsActivitiesExCon, ExtractWorkItemsActivitiesBatchHelper and ExtractWorkItemsActivitiesBatch Class
* @author        Ram Veligeti
* @date          22.04.2015
*/
@isTest(SeeAllData=false)
private class ExtractWorkItemActivitiesExCon_Test {
    @testSetup 
    static void setupData(){
        TestDataHelper.createResponseProperties();
        Extract_Fields__c wia=new Extract_Fields__c(API_Name__c='Name',Header__c='Name',Sequence__c=1,Collection__c='EricTest',Name='EricTest',Extract_Type__c='Post');
        insert new Extract_Fields__c[]{wia};

        Work_Item_CSV_Format__c csvFormat=new Work_Item_CSV_Format__c(Name='ETEST',Column_Header_1__c='Name');
        insert csvFormat;

    Collection__c col=TestDataHelper.createCollection(false);
    col.Name='EricTest';
    col.Collection_Code__c='EricTest';
    insert col;
    Collection_Instance__c colIns=TestDataHelper.createCollectionInstance(col.Id,false);
    colIns.Collection_Instance_Code__c='EricTest';
    colIns.recordtypeid=Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
    insert colIns;
    Unit__c unitObj=TestDataHelper.createUnit(false);
    unitObj.Unit_of_Interest_ID__c ='ERICABCDEF';
    unitObj.Address_Type__c=null;
    unitObj.Other_Address_Type__c=null;
    unitObj.Rural_Delivery_Number__c=null;
    unitObj.Postcode__c='123';
    unitObj.P_O_Box__c=null;
    unitObj.Meshblock_Code__c='11';
    unitObj.DP_ID__c='12345';
    insert unitObj;
    Response__c resp=TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
    resp.Status__c='New';
    resp.Unit_Type__c=null;
    resp.Delivery_Unit_Number__c=null;
    resp.Response_ExtId__c='EricTestwhatever'; // ramu changed logic to use association
    resp.Workflow_status__c='Eric';
    insert resp;
    Work_Item__c wi=TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
    wi.Work_Item_ExtId__c='TEST1';
    wi.Delivery_Mode__c='TEST1';
    wi.Work_Item_Type__c='List leave';
    wi.Status__c='New';
    insert wi;
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'extract.filesize', value__c = '1000')
		};
    }

// only a coverage test, as all the logic on extract are tested in ExtractWorkItemsActivitiesBatch_Test.cls
  @isTest
  static void testCoverage(){
    Collection_Instance__c ci =[select id,Collection__c from Collection_Instance__c];
    Work_Item_CSV_Format__c csv=[select name from Work_Item_CSV_Format__c];
    ExtractWorkItemsActivitiesExCon c = new ExtractWorkItemsActivitiesExCon(new ApexPages.StandardController(ci));
    c.activitySchedule.Work_Item_Type__c='List leave';
    c.activitySchedule.Delivery_mode__c='TEST1';
    c.activitySchedule.Output_CSV_Format__c=csv.id;
    c.activitySchedule.Scheduled_Date_time__c = System.now().addMinutes(2);
    Test.startTest();
    c.extractCSV();
    Test.stopTest();
  }

	@isTest
  static void testCoverage1(){
    Collection_Instance__c ci =[select id,Collection__c from Collection_Instance__c];
    Work_Item_CSV_Format__c csv=[select name from Work_Item_CSV_Format__c];
    Activity_Schedule__c actSch = TestDataHelper.createActivitySchedule(ci.Id,false);    
    actSch.Scheduled_Date_time__c = system.now().addHours(60);
    actSch.Frequency__c = 'Weekly';
    actSch.Occurrence__c = 2;
    actSch.Output_CSV_Format__c = csv.Id;
    insert actSch;
    Test.startTest();
	ExtractWorkItemsActivitiesExCon c = new ExtractWorkItemsActivitiesExCon(new ApexPages.StandardController(ci));
    c.selectActSchId = actSch.Id;
    c.activitySchedule.Output_CSV_Format__c=csv.id;
    c.activitySchedule.Scheduled_Date_time__c = System.now().addMinutes(2);
    c.extractCSV();
    Test.stopTest();
  }

}