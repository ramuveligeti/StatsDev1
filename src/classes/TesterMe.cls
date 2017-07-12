@isTest
private class TesterMe {

	
	@testsetup
	private static void setup(){
		TestDataHelper.createResponseProperties();
		insert new System_Update__c(SetupOwnerId=UserInfo.getOrganizationId(), Execute__c=false);
		
		insert new SystemSettings__c[]{
			new SystemSettings__c(name = 'CnL.workitem.queue', value__c = 'C_L_Escalation_Queue'),
			new SystemSettings__c(name = 'CnL.workitem.dupcontacttype', value__c = 'Update Respondent Details'),
			new SystemSettings__c(name = 'CnL.workitem.addressticktype', value__c = 'Update Respondent Details'),
			new SystemSettings__c(name = 'business.markin.process.contact', value__c = 'True')
		};
        
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTest';
        col.recordtypeid = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		insert col;

		Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
        artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
        artefact.Artefact_Code__c='EL001';
        artefact.Status__c = 'Active';
        insert artefact;
				
		Collection_Instance__c colIns1 = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns1.Collection_Instance_Code__c='EricTest1';
		colIns1.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns1.Collection_Period__c=null;
		colIns1.Reference_Period__c='202010';
		colIns1.Return_Date__c=system.today().addDays(40);
        colIns1.Planned_Start_Date__c = system.today().addDays(2);
        colIns1.Planned_Close_Off__c = system.today().addDays(3);
		Collection_Instance__c colIns2 = TestDataHelper.createCollectionInstance(col.Id,false);
		colIns2.Collection_Instance_Code__c='EricTest2';
		colIns2.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
		colIns2.Collection_Period__c=null;
		colIns2.Reference_Period__c='202011';
		colIns2.Return_Date__c=system.today().addDays(40);
        colIns2.Planned_Start_Date__c = system.today().addDays(2);
        colIns2.Planned_Close_Off__c = system.today().addDays(3);
		Collection_Instance__c[]instances=new Collection_Instance__c[]{colIns1,colIns2};
		insert instances;

		Unit__c[]units=new Unit__c[]{};
		Response__c[]resps=new Response__c[]{};
		Id uRT = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
		Id rRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();

		for(integer i=0; i<100; i++){
			Unit__c unitObj = TestDataHelper.createUnit(false);
			unitObj.recordtypeid=uRT;
			unitObj.Unit_of_Interest_ID__c ='EricTest'+i;
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
		for(integer x=0; x<2; x++){
			for(integer i=0; i<100; i++){
				Response__c resp = TestDataHelper.createResponse(instances[x].Id, null, null, units[i].Id, false);
				resp.recordTypeId=rRT;
				resp.Status__c = 'New';
				resp.Unit_Type__c = null;
				resp.Delivery_Unit_Number__c = null;
				resp.Workflow_status__c=null;
				resp.Document_Number__c = null;
				resp.access_code__c=null;
				resp.collection_mode__c = 'SCER';
				resp.contact__c = null;
				resp.survey_unit__c = units[i].id;
				resp.instrument__c=artefact.id;
				resp.Response_ExtId__c = 'EricTest'+(x+1)+'EricTest'+i+'EL001'; // append instrument code
				resps.add(resp);
			}
		}
		insert resps;
	}
		
	@istest
	private static void test_ManualContactUpdates(){
		SystemSettings__c s = SystemSettings__c.getInstance('business.markin.process.contact');
		s.value__c = 'False';
		update s;
		
		Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
		for(integer i=0; i<10; i++){
			Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
			m.Collection_Code__c='EricTest';
			m.Reference_Period__c='202011';
			m.instrument_code__c='EL001';
			m.unit_of_interest_id__c='EricTest'+i;
			m.address_tick__c = (Math.mod(i,2)==0);
            m.Complaint_Tick__c = false;
			m.first_name__c = 'Rob';
			m.last_name__c = 'Gilmore'+i;
			m.phone_number__c = '09555444'+i;
			m.mobile_number__c = '02188866' +i;
			m.email__c = 'rob'+i+'@me.com';
			m.country__c = 'NZ';
			m.town_city__c = 'Nowhere';
			m.Building_Level_Unit__c = '123 test lane';
			markins.add(m);
		}

		Test.startTest();
		insert markins;
		Test.stopTest();
        
		
		Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
		system.assertEquals(10,vmis.size());
		String[]respExtsWI=new String[]{}, respExtsNoWi=new String[]{};
		for(integer x=0; x<10; x++){
			system.assert(vmis[x].processed__c); // even failed
			system.assertEquals(Math.mod(x,2)==0, vmis[x].address_tick__c);
			if(vmis[x].address_tick__c){
				respExtsWI.add(vmis[x].response_extid__c);
			} else {
				respExtsNoWi.add(vmis[x].response_extid__c);
			}
		}
        
		
	//	String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
           
		Work_Item__c[] manualContactWI = [select id from Work_Item__c where 
        //                                work_item_type__c = :a and   ECP-3278 AddressTick workitem creation 
                                          response__r.response_extid__c in :respExtsNoWi];
		system.assertEquals(5, manualContactWI.size());  // manually contact handling

		Work_Item__c[] cnlWI = [select id from Work_Item__c where 
        //                        work_item_type__c = :a and           ECP-3278 AddressTick workitem creation 
                                response__r.response_extid__c in :respExtsWI];
		// we added address to all mark-in
		// address tick and contact are handling separately, so, each response has 2 work-item
		system.assertEquals(10, cnlWI.size());
	}
}