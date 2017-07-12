@isTest
public class CaseTriggerTest {

	@TestSetup
	private static void setup(){
		TestDataHelper.createResponseProperties();
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
		insert colIns;
		Unit__c unitObj = TestDataHelper.createUnit(false);
		unitObj.Unit_of_Interest_ID__c ='ERICABCDEF';
		unitObj.Address_Type__c = null;
		unitObj.Other_Address_Type__c = null;
		unitObj.Rural_Delivery_Number__c = null;
		unitObj.Postcode__c = '123';
		unitObj.P_O_Box__c = null;
		unitObj.Meshblock_Code__c='11';
		unitObj.DP_ID__c='12345';
		insert unitObj;
		Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
		resp.Status__c = 'New';
		resp.Unit_Type__c = null;
		resp.Delivery_Unit_Number__c = null;
		resp.Response_ExtId__c = 'EricTestwhatever'; // ramu changed logic to use association
		resp.Workflow_status__c='Eric';
		insert resp;
		Case_Update_Properties__c[] config= new Case_Update_Properties__c[]{
			new Case_Update_Properties__c(name='case.status.closed',value__c='whatever'),
			new Case_Update_Properties__c(name='workitem.status.closed',value__c='whatever')
		};
		insert config;
	}
	
	@isTest
	private static void testSomething(){
		System.debug('creating case');
		Case c = new Case(description='test', origin='what',status='test');
		System.debug('inserting case');
		insert c;
		Response__c rs = [Select Id from Response__c];
		System.debug('creating and inserting wi');
		Work_Item__c wi = TestDataHelper.createWorkItem(null, null, c.Id, rs.Id, null, true);
		System.debug('test calss workItems = '+[select Id, Related_Case__c, Status__c from Work_Item__c where Related_Case__c = :c.Id and Status__c != 'whatever']);
		
		System.debug('changing case status');
		c.status = 'whatever';
		System.debug('updating case');
		update c;
		
		
		Work_Item__c vwi=[select status__c from Work_Item__c where id =:wi.id];
		system.assertEquals('whatever', vwi.status__c);
	}

}