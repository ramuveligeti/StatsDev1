/**
* Amendment -  Caterina Cuccurullo 22 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
*/        
@isTest
private class ContactRoleEditorControllerTest {

	@testSetup
	static void testSetup(){
		TestDataHelper.createResponseProperties();
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;
		Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns.Collection_Instance_Code__c='EricTest';
		colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns.Reference_Period__c='201601';
		insert colIns;

		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<201; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c =(i==0?'EN':'GE')+i;
			unitObj.Address_Type__c = null;
			unitObj.Other_Address_Type__c = null;
			unitObj.Rural_Delivery_Number__c = null;
			unitObj.Postcode__c = '1234';
			unitObj.P_O_Box__c = null;
			unitObj.Meshblock_Code__c='11';
			unitObj.DP_ID__c=''+(10000+i);
			units.add(unitObj);
		}
		insert units;
		for(integer i=1; i<201; i++){
			Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, units[0].Id, false);
			resp.recordTypeId=rRT;
			resp.Status__c = 'New';
			resp.Unit_Type__c = null;
			resp.Delivery_Unit_Number__c = null;
			resp.Response_ExtId__c = 'EricTestwhatever'+i;
			resp.Workflow_status__c=null;
			resp.Document_Number__c = null;
			resp.access_code__c=null;
			resp.survey_unit__c = units[i].id;//this is the GEO
			resps.add(resp);
		}
		insert resps;
		
		Contact cnt = new Contact(lastName='TESTING', firstName='Hello');
		insert cnt;
		
		Contact_Role__c role = new Contact_Role__c(Collection__c=col.id, contact__c=cnt.id, Unit_of_Interest_ID__c=units[0].id);
		insert role;
	}

	@isTest
    static void testPageActions() {
    	Contact_Role__c cr=[select id, Collection__c, Contact__c, Unit_of_Interest_ID__c, status__c from Contact_Role__c];
    	
    	Contact_Role_Unit__c[]cru=new Contact_Role_Unit__c[]{};
    	boolean addit=true;
    	// in this test, select half the GEO
    	for(Unit__c u: [select id,Unit_of_Interest_ID__c from Unit__c order by Id]){
    		if(u.Unit_of_Interest_ID__c.startsWith('GE')&&addit){
    			cru.add(new Contact_Role_Unit__c(Contact_Role__c=cr.id,Survey_Unit_Link__c=u.id));
    		}
    		addit=!addit;
    	}
        insert cru;
        
        Test.setCurrentPage(Page.ContactRoleEditorPage);
        Test.startTest();
        // testing pre-selected
        ContactRoleEditorController ctr = new ContactRoleEditorController(new ApexPages.StandardController(cr));
        system.assertEquals(200, ctr.displayUnits.size());
        integer counter=0;
        for(ContactRoleEditorController.Unit u: ctr.displayUnits){counter+=(u.selected)?1:0;}
        system.assertEquals(100, counter);
        
        // now, add all
        for(ContactRoleEditorController.Unit u: ctr.displayUnits){u.selected=true;}
        ctr.save();
        
        cru=[select id from Contact_Role_Unit__c];
        system.assertEquals(200, cru.size());
        
        Test.stopTest();
        
        ctr.cancel();
    }
}