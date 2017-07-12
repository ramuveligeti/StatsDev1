/**
* Amendment -  Caterina Cuccurullo 22 August 2016
* User Story - ECP - 3022
*              Replaced reference of RecordType - 'Enterprise Unit'  with  'Business Unit'
*
* Amendment -  Caterina Cuccurullo 15 & 27 September 2016
* User Story - ECP - 3278
*              Mark In Address Tick work Item creation moved to Process Builder 
*              Create Custom Setting Work Item Settings they are required by  Flow -Create Work item
*              Amended some expected results these have been commented.  
*              Removed test for creation of Contact Work item as nolonger require contact work items to be created Bug ECP-3624  
*             
* Amendment -  Caterina Cuccurullo 20 October 2016
* User Story - ECP - 3237
*              Create & update contact role relationship with unit when recording actual respondent in Collection Markin Request
*/        
@isTest
private class CollectionMarkInRequestHandlerTest {

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
      //ECP-3278 Create Custom Setting Work Item Settings they are required by  Flow -Create Work item    
        insert new Work_Item_Settings__c[]{
            new Work_Item_Settings__c(AddressQueue__c = 'C_L_Escalation_Queue', AddressWorkItemType__c = 'Update Respondent Details',
                                    ComplaintQueue__c = 'Tick_Complaints',ComplaintWorkItemType__c = 'Tick - Complaints')        
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
            m.complaint_tick__c = (Math.mod(i,2)==0);
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
        
       
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
    
       
        Work_Item__c[] manualContactWI = [select id from Work_Item__c where work_item_type__c = :a and                
                                          response__r.response_extid__c in :respExtsNoWi];
    //Removed Bug 3624 nolonger require contact work items to be created    
   //     system.assertEquals(5, manualContactWI.size());  // manually contact handling 

        Work_Item__c[] cnlWI = [select id from Work_Item__c where 
                               work_item_type__c = :a and             // ECP-3278 AddressTick workitem creation check removed
                                response__r.response_extid__c in :respExtsWI];
        // we added address to all mark-in
        // address tick and contact are handling separately, so, each response has 2 work-item
        system.assertEquals(5, cnlWI.size());     
    }

    @istest
    private static void test_contactValidationError(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            m.first_name__c = 'Rob';
            m.last_name__c = 'Gilmore'+i;
            m.phone_number__c = '09555444'+i;
            m.mobile_number__c = '02188866' +i;
            m.email__c = 'rob'+i+'@me.com';
            m.country__c = 'NZ';
            m.town_city__c = 'Nowhere'; // will failed validation without address line
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); 
            respExtsWI.add(vmis[x].response_extid__c);
        }
      
     
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
        Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and   
                                response__r.response_extid__c in :respExtsWI];
        system.assertEquals(10, cnlWI.size()); // address error, even we have auto-contact processing
    }


    @istest 
    private static void test_Error_MarkIn_unknownCI(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='20201'+((Math.mod(i,2)==0)?'2':'1'); // even will fail
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c];
        system.assertEquals(10,vmis.size());
        for(integer x=0; x<10; x++){
            system.assertEquals(Math.mod(x,2)==0, vmis[x].failed__c); // even failed
        }
    }

    @istest
    private static void test_Error_MarkIn_unknownAll(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            if(Math.mod(i,2)==0){
                m.Collection_Code__c='EricXXX';//unknown collection
                m.Reference_Period__c='202010'; 
            } // odd record have missing info request
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c];
        system.assertEquals(10,vmis.size());
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].failed__c); // all failed
        }
    }

    
    @istest
    private static void test_SingleCI_MarkIn(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        Set<Integer>x=new Set<Integer>{5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95};
        for(integer i=0; i<100; i++){
            if(x.contains(i)){
                Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
                m.Collection_Code__c='EricTest';
                m.Reference_Period__c='202010';
                m.instrument_code__c='EL001';
                m.unit_of_interest_id__c='EricTest'+i;
                m.Response_Mode__c='Magic';
                m.Image_Url__c = 'http://test.co/EricTest'+i;
                markins.add(m);
            }
        }
        
        Test.startTest();
        insert markins;
        Test.stopTest();
        
        // checks the respones
        integer i=0;
        for(Response__c r: [select mark_in__c, Response_ExtID__c, Completed_Response_link__c from Response__c where collection_instance__r.collection_instance_code__c='EricTest1' order by Id]){
            if(x.contains(i)){
                system.assert(r.mark_in__c, 'record: '+ i + ': '+r);
                system.assertNotEquals(null, r.Completed_Response_Link__c, 'record '+ i+ ' contain null image link');           
            } else {
                system.assert(!r.mark_in__c, 'record: '+ i + ': '+r);
            }
            i++;
        }
        
        // verifies the markin requests
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, response_mode__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(19,vmis.size());
        for(i=0; i<19; i++){
            system.assert(vmis[i].processed__c); // all success
            system.assertEquals('Magic',vmis[i].response_mode__c);
        }
    }


    @istest
    private static void test_SingleCI_MixError(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        Set<Integer>x=new Set<Integer>{5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95};
        Set<Integer>y=new Set<Integer>{3,8,13,18,23,28,33,38,43,48,53,58,63,68,73,78,83,88,93,98};
        for(integer i=0; i<100; i++){
            if(x.contains(i)){
                Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
                m.Collection_Code__c='EricTest';
                m.Reference_Period__c='202010';
                m.instrument_code__c='EL001';
                m.unit_of_interest_id__c='EricTest'+i;
                markins.add(m);
            }

            if(y.contains(i)){
                Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
                m.Collection_Code__c='EricTest';
                m.Reference_Period__c='202010';
                m.instrument_code__c='EL003'; // invalid instrument, cannot find response, but will fail markin
                m.unit_of_interest_id__c='EricTest'+i;
                markins.add(m);
            }
        }
        
        Test.startTest();
        insert markins;
        Test.stopTest();
        
        // checks the respones
        integer i=0;
        for(Response__c r: [select mark_in__c, Response_ExtID__c from Response__c where collection_instance__r.collection_instance_code__c='EricTest1' order by Id]){
            if(x.contains(i)){
                system.assert(r.mark_in__c, 'record: '+ i + ': '+r);                
            } else {
                system.assert(!r.mark_in__c, 'record: '+ i + ': '+r);
            }
            i++;
        }

        // verifies the markin requests
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(39,vmis.size());
        for(i=0; i<39; i++){
            if(Math.mod(i,2)==0){
                system.assert(vmis[i].failed__c); // no match for response
            } else {
                system.assert(vmis[i].processed__c); // find response by instrument
            }
        }
        
    }

    @istest
    private static void test_TwoCIs_MarkIn(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        Set<Integer>x=new Set<Integer>{5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95};
        Set<Integer>y=new Set<Integer>{3,8,13,18,23,28,33,38,43,48,53,58,63,68,73,78,83,88,93,98};
        for(integer i=0; i<200; i++){ // 200 responses
            if(i<100 && x.contains(i)){
                Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
                m.Collection_Code__c='EricTest';
                m.Reference_Period__c='202010';
                m.instrument_code__c='EL001';
                m.unit_of_interest_id__c='EricTest'+i;
                markins.add(m);
            }

            // second 100th responses on a different CI
            if(i>=100 && y.contains(i-100)){
                Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
                m.Collection_Code__c='EricTest';
                m.Reference_Period__c='202011'; // two different CI
                m.instrument_code__c='EL001'; 
                m.unit_of_interest_id__c='EricTest'+(i-100);
                markins.add(m);
            }
        }

        Collection_Mark_In_Request__c m1=new Collection_Mark_In_Request__c();
        m1.Collection_Code__c='EricTest';
        m1.Reference_Period__c='202011';
        m1.instrument_code__c='EL001'; 
        m1.unit_of_interest_id__c='EricFailed1'; // no such unit
        markins.add(m1);

        Collection_Mark_In_Request__c m2=new Collection_Mark_In_Request__c();
        m2.Collection_Code__c='EricFail'; // no such collection
        m2.Reference_Period__c='202011';
        m2.instrument_code__c='EL001'; 
        m2.unit_of_interest_id__c='EricTest1';
        markins.add(m2);

        Collection_Mark_In_Request__c m3=new Collection_Mark_In_Request__c();
        m3.Collection_Code__c='EricTest';
        m3.Reference_Period__c='202011';
        m3.instrument_code__c='EL003';  // no such instrument
        m3.unit_of_interest_id__c='EricTest1'; 
        markins.add(m3);

        Test.startTest();
        insert markins;
        Test.stopTest();

        // verifies the markin requests
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(42,vmis.size());
        for(integer i=0; i<39; i++){
            system.assert(vmis[i].processed__c, vmis[i]); // all success across two CIs
        }
        for(integer i=39; i<42; i++){
            system.assert(vmis[i].failed__c, vmis[i]); // manual fail
        }
        
        // checks the respones
        integer i=0;
        for(Response__c r: [select mark_in__c, Response_ExtID__c from Response__c where collection_instance__r.collection_instance_code__c='EricTest1' order by Id]){
            if(x.contains(i)){
                system.assert(r.mark_in__c, 'record: '+ i + ': '+r);                
            } else {
                system.assert(!r.mark_in__c, 'record: '+ i + ': '+r);
            }
            i++;
        }
        i=0;
        for(Response__c r: [select mark_in__c, Response_ExtID__c from Response__c where collection_instance__r.collection_instance_code__c='EricTest2' order by Id]){
            if(y.contains(i)){
                system.assert(r.mark_in__c, 'record: '+ i + ': '+r);                
            } else {
                system.assert(!r.mark_in__c, 'record: '+ i + ': '+r);
            }
            i++;
        }

    }

    @istest
    private static void testSASuppressed(){
        Collection__c col=[select id from Collection__c];
        Unit__c[]units=[select id from unit__c order by id];
        Response__c[]resps=[select id from response__c order by id];
        // two lots of special arrangements, only one set will be suppressed
        Map<integer,integer>consolidation=new Map<integer,integer>{
            51=>55,52=>55,53=>55,54=>55};
        Special_Arrangement__c[] sas=new Special_Arrangement__c[]{};        
        for(integer x:consolidation.keySet()){
            Id rt = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Consolidation').getRecordTypeId();
            Special_Arrangement__c sa=new Special_Arrangement__c(Collection__c=col.id, Survey_Unit__c=units[x].id,recordtypeid=rt,
                Rule_Start_Date__c=system.today(),Rule_End_Date__c=null,Month_4__c=true,Consolidated_Unit__c=units[consolidation.get(x)].id);
            sas.add(sa);
        }
        insert sas;
        
        SpecialArrangementProcessor ap = new SpecialArrangementProcessor('EricTest2');
        ap.autoProcessing();

        Response__c[]vR=[select id, status__c, mark_in__c, Response_status_reason__c from response__c order by Id];
        for(integer x: new integer[]{51,52,53,54,55,155}){
            system.assertEquals('New', vR[x].status__c);
        }
        for(integer x: new integer[]{151,152,153,154}){
            system.assertEquals('Suppressed', vR[x].status__c);
        }

        Collection_Mark_In_Request__c m3=new Collection_Mark_In_Request__c();
        m3.Collection_Code__c='EricTest';
        m3.Reference_Period__c='202011';
        m3.instrument_code__c='EL001';  
        m3.unit_of_interest_id__c='EricTest55';  // consolidated response
        
        Test.startTest();
        insert m3;
        Test.stopTest();
        
        vR=[select id, mark_in__c, Response_status_reason__c from response__c order by Id];
        for(integer x: new integer[]{51,52,53,54,55}){
            system.assert(!vR[x].mark_in__c, x+': '+vR[x]);
        }
        for(integer x: new integer[]{155}){
            system.assert(vR[x].mark_in__c, x+': '+vR[x]);
        }
        for(integer x: new integer[]{151,152,153,154}){
            system.assert(vR[x].mark_in__c, x+': '+vR[x]);
            system.assertEquals('Consolidated Collection', vR[x].Response_status_reason__c);
        }
        
        
    }

       
    @istest
    private static void test_AddressTick(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            m.address_tick__c = (Math.mod(i,2)==0);
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
         
        
        String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
               
        
        Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsNoWi];
    
        system.assertEquals(0, noWI.size());

        Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
        system.assertEquals(5, cnlWI.size());
    }
 
    

    @istest
    private static void test_NewContacts(){
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Happy';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555444'+i;
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
       
        String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
        Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
        system.assertEquals(0, noWI.size());

        Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and   response__r.response_extid__c in :respExtsWI];
        system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt];
        for(Response__c r: wiContacts){
            system.assertNotEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }

    }

    @istest
    private static void test_ExistingContacts(){
                
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Happy', lastname='Gilmore'+i, phone='09555444'+i));
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Happy';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555444'+i;
                m.mobile_number__c = '02188866' +i;
                m.email__c = 'rob'+i+'@me.com';
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
        
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
        
      Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
      system.assertEquals(5, noWI.size());

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and  response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id] ){
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    }

    @istest
    private static void test_DupContactsMatching(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Rachel', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='rob'+i+'@me.com'));
            // will be matched for exact dup 
            cnts.add(new Contact(firstname='Rob', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone = '02188866'+i, email='rob'+i+'@me.com'));
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202010';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                // will success under exact match fn+ln+phone
                m.address_tick__c = false;
                m.first_name__c = 'Rob';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555444'+i;
                m.mobile_number__c = '02188866' +i;
                m.email__c = 'rob'+i+'@me.com';
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExactMatch=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); 
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExactMatch.add(vmis[x].response_extid__c);
            }
        }
        
   
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
       
      Work_Item__c[] dupWIs = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExactMatch];
        // all match based on exact spelling of firstname
      system.assertEquals(5, dupWIs.size()); //ECP-3278 was 0 changed to 5, creation of Address tick WI now done in Process Builder on Collection Markin Request

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiExactMatchContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExactMatch order by Id];
        integer i=1;
        for(Response__c r: wiExactMatchContacts){
            system.assertEquals(cnts[i].id, r.Responded_by__c);
            i+=2;//alternative contact for Rob
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        

    }


    @istest
    private static void test_DupContactsNoMatch(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Rachel', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='rob'+i+'@me.com'));
            // will not be matched for exact dup, plus multiple lastname matches
            cnts.add(new Contact(firstname='Robert', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone = '02188866'+i, email='rob'+i+'@me.com'));
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                // will success under exact match fn+ln+phone
                m.address_tick__c = false;
                m.first_name__c = 'Rob';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555444'+i;
                m.mobile_number__c = '02188866' +i;
                m.email__c = 'rob'+i+'@me.com';
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtsNoWi=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); 
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtsNoWi.add(vmis[x].response_extid__c);
            }
        }
        
        
        String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
        Work_Item__c[] dupWIs = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsNoWi];
        system.assertEquals(10, dupWIs.size()); //ECP-3278 was 5 changed to 10, creation of Address tick WI now done in Process Builder on Collection Markin Request

        Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
        system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsNoWi order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        

    }


    @istest
    private static void test_ExistingContacts_matchPhoneLastname(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Robert', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02188866'+i)); // contact for matching phone
        }
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Duppy', lastname='Gilmore'+i, phone='09555333'+i, mobilePhone='02177755'+i)); 
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Rob';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555444'+i;
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
 
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
      Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
      system.assertEquals(5, noWI.size());  //ECP-3278 was 0 changed to 5, creation of Address tick WI now done in Process Builder on Collection Markin Request

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c, 'count: '+i);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id limit 5] ){  // only checks the first 5 records
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    }


    @istest
    private static void test_ExistingContacts_matchMobileExact(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Robert', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02188866'+i)); // second contact for matching mobile
        }
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Duppy', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02177755'+i)); 
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Robert';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555666'+i; // not match on ln+phone
                m.mobile_number__c = '02188866' +i; // will match on ln+mobile
                m.email__c = 'rob'+i+'@me.com';
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
 
    
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
      Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
      system.assertEquals(5, noWI.size()); //ECP-3278 was 0 changed to 5, creation of Address tick WI now done in Process Builder on Collection Markin Request

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c, 'count: '+i);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id limit 5] ){  // only checks the first 5 records
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    }

    @istest
    private static void test_ExistingContacts_matchMobileLastname(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Robert', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02188866'+i)); // second contact for matching mobile
        }
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Duppy', lastname='Gilmore'+i, phone='09555444'+i, mobilePhone='02177755'+i)); 
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Rob';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555666'+i; // not match on ln+phone
                m.mobile_number__c = '02188866' +i; // will match on ln+mobile
                m.email__c = 'rob'+i+'@me.com';
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
    
        
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
      Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
      system.assertEquals(5, noWI.size()); //ECP-3278 was 0 changed to 5, creation of Address tick WI now done in Process Builder on Collection Markin Request

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c, 'count: '+i);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id limit 5] ){  // only checks the first 5 records
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    }

    @istest
    private static void test_ExistingContacts_matchEmailExact(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Robert', lastname='GILMORE'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='rob'+i+'@me.com')); // second contact for matching email
        }
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Duppy', lastname='GILMORE'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='da'+i+'@me.com')); 
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.complaint_tick__c = false;
                m.first_name__c = 'Robert';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555666'+i; // not match on ln+phone
                m.mobile_number__c = '02188867' +i; // not match on ln+mobile
                m.email__c = 'rob'+i+'@me.com'; // will match on email
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        
 
        
      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
   //  Removed Contact work items no longer required Bug ECP-3624    
   //   Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
   //   system.assertEquals(0, noWI.size());

       Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
       system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c, 'count: '+i);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id limit 5] ){  // only checks the first 5 records
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    }

    @istest
    private static void test_ExistingContacts_matchEmailLastname(){
        Contact[] cnts=new Contact[]{};
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Robert', lastname='GILMORE'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='rob'+i+'@me.com')); // second contact for matching email
        }
        for(integer i=0; i<5; i++){
            cnts.add(new Contact(firstname='Duppy', lastname='GILMORE'+i, phone='09555444'+i, mobilePhone='02188866'+i, email='da'+i+'@me.com')); 
        }
        insert cnts;
        
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
        for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest'+i;
            if(i>4){
                m.address_tick__c = true;               
            } else {
                m.address_tick__c = false;
                m.first_name__c = 'Rob';
                m.last_name__c = 'Gilmore'+i;
                m.phone_number__c = '09555666'+i; // not match on ln+phone
                m.mobile_number__c = '02188867' +i; // not match on ln+mobile
                m.email__c = 'rob'+i+'@me.com'; // will match on email
                m.country__c = 'NZ';
                m.town_city__c = 'Nowhere';
                m.Building_Level_Unit__c = '123 test lane';
            }
            markins.add(m);
        }

        Test.startTest();
        insert markins;
        Test.stopTest();
        
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c, address_tick__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(10,vmis.size());
        String[]respExtsWI=new String[]{}, respExtCnt=new String[]{};
        for(integer x=0; x<10; x++){
            system.assert(vmis[x].processed__c); // even failed
            system.assertEquals(x>4, vmis[x].address_tick__c);
            if(x>4){
                respExtsWI.add(vmis[x].response_extid__c);
            } else {
                respExtCnt.add(vmis[x].response_extid__c);
            }
        }
        

      String a = SystemSettings__c.getInstance('CnL.workitem.addressticktype').value__c;
      Work_Item__c[] noWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtCnt];
      system.assertEquals(5, noWI.size()); //ECP-3278 was 0 changed to 5, creation of Address tick WI now done in Process Builder on Collection Markin Request

      Work_Item__c[] cnlWI = [select id from Work_Item__c where work_item_type__c = :a and response__r.response_extid__c in :respExtsWI];
      system.assertEquals(5, cnlWI.size());
        
        Response__c[] wiNoContacts = [select id, Responded_By__c from Response__c where response_extid__c in :respExtsWI order by Id];
        for(Response__c r: wiNoContacts){
            system.assertEquals(null, r.Responded_by__c);
        }
        
        Response__c[] wiContacts = [select id, Responded_By__c, Responded_by__r.id, Responded_by__r.firstname, Responded_by__r.lastname,
            Responded_by__r.phone, Responded_by__r.email, Responded_by__r.mobilePhone
            from Response__c where response_extid__c in :respExtCnt order by Id];
        for(integer i=0; i<5; i++){
            system.assertEquals(cnts[i].id, wiContacts[i].Responded_by__c, 'count: '+i + cnts[i] + '\n' + wiContacts[i].Responded_by__r);
        }
        
        for (Contact c: [select Building_Level_Unit__c from Contact order by id limit 5] ){  // only checks the first 5 records
            // overwrite by address in mark-in, was null when created
            system.assertEquals('123 test lane', c.Building_Level_Unit__c);
        }
        
    } 
    //Tests for Contact Role ECP-3237    
    @istest
    private static void test_InsertContactRoleNewContact(){
       SystemSettings__c s = SystemSettings__c.getInstance('business.markin.process.contact');
       s.value__c = 'True'; 
       update s;
            
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
       // for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest1';
            m.address_tick__c = false;
            m.complaint_tick__c = false;
            m.first_name__c = 'Alice';
            m.last_name__c = 'Wonderland';
            m.phone_number__c = '09555444';
            m.mobile_number__c = '02188866';
            m.email__c = 'alice@me.com';
            m.country__c = 'NZ';
            m.town_city__c = 'Nowhere';
            m.Building_Level_Unit__c = '123 test lane';
            markins.add(m);
    //    }

        Test.startTest();
        insert markins;
        Test.stopTest();
          
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(1,vmis.size()); 
               
        system.assert(vmis[0].processed__c); // markin successful  
        for (Contact c: [select lastname from Contact order by id] ){
            // Check that the new contact was created 
            system.assertEquals('Wonderland', c.lastname);
        }
        for (Contact_Role__c cr: [select contact__r.lastname, Primary_Contact__c, Unit_of_Interest_ID__r.Unit_of_Interest_ID__c from Contact_Role__c order by id] ){
            // Check that the new Contact Role was created 
            system.assertEquals('Wonderland', cr.contact__r.lastname );
            system.assertEquals(true,cr.primary_contact__c);
            system.assert(cr.primary_contact__c);
            system.assertEquals('EricTest1',cr.Unit_of_Interest_ID__r.Unit_of_Interest_ID__c);
        }  
         
      }
    
      @istest
      private static void test_InsertContactRoleExistContact(){
        SystemSettings__c s = SystemSettings__c.getInstance('business.markin.process.contact');
        s.value__c = 'True'; 
        update s;
         
         //add in the Contact that is eventually going to be added as the Contact Role 
         Contact[] cnts=new Contact[]{};
           cnts.add(new Contact(firstname='Sarah', lastname='Lee', phone='04555444', email ='SarahL@gmail.com' ));                
         insert cnts;
            
        Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
       // for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202011';
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest1';
            m.address_tick__c = false;
            m.complaint_tick__c = false;
            m.first_name__c = 'Sarah';
            m.last_name__c = 'Lee';
            m.phone_number__c = '04555444';
            m.email__c = 'SarahL@gmail.com';
            markins.add(m);
    //    }

        Test.startTest();
        insert markins;
        Test.stopTest();
          
        Collection_Mark_In_Request__c[]vmis=[select processed__c, failed__c, response_extid__c from Collection_Mark_In_Request__c order by Id];
        system.assertEquals(1,vmis.size()); 
               
        system.assert(vmis[0].processed__c); // markin successful  
        
        // Check that the new contact was created 
        for (Contact c: [select lastname from Contact order by id] ){
            system.assertEquals('Lee', c.lastname);
        }
        // Check that the new Contact Role was created   
        for (Contact_Role__c cr: [select contact__r.lastname, Primary_Contact__c, Unit_of_Interest_ID__r.Unit_of_Interest_ID__c from Contact_Role__c order by id] ){
            system.assertEquals('Lee', cr.contact__r.lastname );
        //    system.assertEquals(true,cr.primary_contact__c);
            system.assert(cr.primary_contact__c);
            system.assertEquals('EricTest1',cr.Unit_of_Interest_ID__r.Unit_of_Interest_ID__c);
        }  
       }
     
 // 
  @isTest static void test_ContactRoleNotPrimary(){
       //The contact role exists but its not the primary contact 
        SystemSettings__c s = SystemSettings__c.getInstance('business.markin.process.contact');
        s.value__c = 'True'; 
        update s;
      
           Contact[] cnts=new Contact[]{};
           cnts.add(new Contact(firstname='fname1', lastname='lname1', phone='04555444', email ='test1@test.test' ));                
           insert cnts;
           Contact cnt = [Select Id from Contact where lastname='lname1'];
           
         
            Collection__c col = [Select Id from Collection__c where Collection_Code__c = 'EricTest'];
            Unit__c unit = [Select Id, Unit_of_Interest_ID__c from Unit__c where Unit_of_Interest_ID__c = 'EricTest1'];
         
             List<Contact_Role__c> crlst = new List<Contact_Role__c>();
            // for(integer i=0;i<10;i++){
             //   Contact_Role__c cr = TestDataHelper.createContactRole(col.Id, unit.Id,contList[i].Id,false);
                Contact_Role__c cr = TestDataHelper.createContactRole(col.Id, unit.Id,cnt.Id,false);
                cr.Status__c = 'Active';
                cr.Role__c ='Respondent';
                cr.Primary_Contact__c = false;
                cr.Identifier__c = String.valueOf(1);
                cr.Mobile_Device_Id__c = String.valueOf(1);
                crlst.add(cr);
           //  } 
                    
             insert crlst; 
                             
           /*check we successfully added into contact role*/
            List<Contact_Role__c> crlstnew = [Select Id  from Contact_Role__c where Primary_Contact__c = false ];
            system.assertEquals(1,crlstnew.size());
        
            /*now create the Collection Markin request that will create the contact Role as well as long as it doesn't fail*/           
             Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
      //   for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202010'; 
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest1';
            m.address_tick__c = false;
            m.complaint_tick__c = false;
            m.first_name__c = 'fname1' ;
            m.last_name__c = 'lname1';
            m.phone_number__c = '041111111';
            m.email__c = 'test1@test.test';
            markins.add(m);
         // }              
                 
         Test.startTest();
         insert markins;
         Test.stopTest();
         Collection_Mark_In_Request__c[]vmis=[select Collection_Code__c, first_name__c, 
                                             processed__c, failed__c, 
                                             response_extid__c 
                                             from Collection_Mark_In_Request__c order by Id];
        system.assertEquals('EricTest',vmis[0].Collection_Code__c);
        system.assertEquals('fname1',vmis[0].first_name__c);
        system.assertEquals(1,vmis.size()); 
        system.assert(vmis[0].processed__c); // markin successful 
         
        //now check the contact role has been updated
        Contact_Role__c[]crol=[select contact__r.lastname, Primary_Contact__c, Unit_of_Interest_ID__r.Unit_of_Interest_ID__c, status__c  
                                 from Contact_Role__c order by id Limit 1];                       
                      
            system.assertEquals(1,crol.size()); 
            system.assertEquals('Active',crol[0].status__c);
            system.assert(crol[0].primary_contact__c);
            system.assertEquals('lname1', crol[0].contact__r.lastname);
            system.assertEquals('EricTest1',crol[0].Unit_of_Interest_ID__r.Unit_of_Interest_ID__c); 
        
        }
 
  @isTest static void test_ContactRoleInactive(){
       //The contact role exists but its not Active 
        SystemSettings__c s = SystemSettings__c.getInstance('business.markin.process.contact');
        s.value__c = 'True'; 
        update s;
       
        Contact[] cnts=new Contact[]{};
        cnts.add(new Contact(firstname='Terry', lastname='Tramper', phone='04555444', email ='test1@test.test' ));                
        insert cnts;
        Contact cnt = [Select Id from Contact where lastname='Tramper'];
           
         
        Collection__c col = [Select Id from Collection__c where Collection_Code__c = 'EricTest'];
        Unit__c unit = [Select Id, Unit_of_Interest_ID__c from Unit__c where Unit_of_Interest_ID__c = 'EricTest1'];
         
       List<Contact_Role__c> crlst = new List<Contact_Role__c>();
          // for(integer i=0;i<10;i++){
          //   Contact_Role__c cr = TestDataHelper.createContactRole(col.Id, unit.Id,contList[i].Id,false);
             Contact_Role__c cr = TestDataHelper.createContactRole(col.Id, unit.Id,cnt.Id,false);
             cr.Status__c = 'Inactive';
             cr.Role__c ='Respondent';
             cr.Primary_Contact__c = false;
             cr.Identifier__c = String.valueOf(1);
             cr.Mobile_Device_Id__c = String.valueOf(1);
             crlst.add(cr);
         //  } 
                    
             insert crlst; 
                             
           /*check we successfully added into contact role*/
            List<Contact_Role__c> crlstnew = [Select Id  from Contact_Role__c where Primary_Contact__c = false ];
            system.assertEquals(1,crlstnew.size());
          //  system.debug('crlstnew item 1: '+ crlstnew[0]); 
            /*now create the Collection Markin request that will create the contact Role as well as long as it doesn't fail*/           
             Collection_Mark_In_Request__c[]markins=new Collection_Mark_In_Request__c[]{};
      //   for(integer i=0; i<10; i++){
            Collection_Mark_In_Request__c m=new Collection_Mark_In_Request__c();
            m.Collection_Code__c='EricTest';
            m.Reference_Period__c='202010'; 
            m.instrument_code__c='EL001';
            m.unit_of_interest_id__c='EricTest1';
            m.address_tick__c = false;
            m.complaint_tick__c = false;
            m.first_name__c = 'Terry' ;
            m.last_name__c = 'Tramper';
            m.phone_number__c = '041111111';
            m.email__c = 'test1@test.test';
            markins.add(m);
         // }              
                 
         Test.startTest();
         insert markins;
         Test.stopTest();
            
      
        Collection_Mark_In_Request__c[]vmis=[select Collection_Code__c, first_name__c, 
                                             processed__c, failed__c, 
                                             response_extid__c 
                                             from Collection_Mark_In_Request__c order by Id];
        system.assertEquals('EricTest',vmis[0].Collection_Code__c);
        system.assertEquals('Terry',vmis[0].first_name__c);
        system.assertEquals(1,vmis.size()); 
        system.assert(vmis[0].processed__c); // markin successful 
       
            
        //now check the contact role has been updated to Active & primary
        Contact_Role__c[]crol=[select contact__r.lastname, Primary_Contact__c, Unit_of_Interest_ID__r.Unit_of_Interest_ID__c, status__c  
                                 from Contact_Role__c  order by id Limit 1];                           
                            
            system.assertEquals(1,crol.size()); 
            system.assertEquals('Active',crol[0].status__c);
            system.assert(crol[0].primary_contact__c);
            system.assertEquals('Tramper', crol[0].contact__r.lastname);
            system.assertEquals('EricTest1',crol[0].Unit_of_Interest_ID__r.Unit_of_Interest_ID__c); 
                  
        }
}