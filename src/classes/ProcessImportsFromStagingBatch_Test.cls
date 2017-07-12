@isTest
private class ProcessImportsFromStagingBatch_Test {

    @TestSetup static void dataSetup(){
        TestDataHelper.createResponseProperties();
    }
    
    @isTest static void testExecute(){
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        collectionInstance.Delivery_Mode__c = 'Email';
        insert collectionInstance;


        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unitObj = new Unit__c ();

        //response will not be created because it is a collection unit
        Staging_Element__c stagingElement4 = TestDataHelper.createStagingElement(false);
        stagingElement4.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement4.U_DP_ID__c = '451';
        stagingElement4.U_Unit_of_Interest_Id__c = '451';
        stagingElement4.R_Access_Code__c = '4';
        stagingElement4.WL_Workload_ID__c = null;
        stagingElement4.WI_Work_Item_ExtId__c = null;
        stagingElement4.C_Legacy_Contact_ID__c =null;
        stagingElement4.CR_Contact_ExtId__c = null;
        stagingElement4.CR_Unit_Of_Interest_Id__c = null;
        stagingElement4.A_Instrument_Code__c = null;
        stagingElement4.R_Mark_in_Required__c = false;
        stagingElement4.Collection_Unit__c = true;
        stagingElement4.Survey_Unit__c = false;
        stagingElement4.R_Unit_Association__c = '451';
        stagingElement4.U_Meshblock_Code__c = '3';
        stagingElement4.U_Building_Name__c = 'Building1';
        stagingElement4.Account_External_Id__c = null;
        stagingElement4.U_Road_Number__c = '124';
        stagingElement4.U_Rural_Delivery_Number__c = null;
        stagingElements.add(stagingElement4);
        
        unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='451';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        unitList.add(unitObj);

        for(integer i=0; i<198; i++){
            Staging_Element__c stagingElement1 = TestDataHelper.createStagingElement(false);
            stagingElement1.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement1.U_DP_ID__c = String.valueOf(i);
            stagingElement1.U_Unit_of_Interest_Id__c = String.valueOf(i);
            stagingElement1.R_Delivery_Rural_Delivery_Number__c = null;
            stagingElement1.A_Instrument_Code__c = 'ACODE';
            stagingElement1.R_Access_Code__c='a'+i;
            stagingElement1.WL_Workload_ID__c = 'wl'+i;
            stagingElement1.WI_Work_Item_ExtId__c = 'wi'+i;
            stagingElement1.C_Legacy_Contact_ID__c = null;
            stagingElement1.CR_Contact_ExtId__c = 'cr'+i;
            stagingElement1.CR_Unit_Of_Interest_Id__c = null;
            stagingElement1.R_Mark_in_Required__c = true;
            stagingElement1.Collection_Unit__c = false;
            stagingElement1.Survey_Unit__c = true;
            stagingElement1.R_Unit_Association__c = '451';
            stagingElement1.U_Meshblock_Code__c = String.valueOf(i);
            stagingElement1.Account_External_Id__c = null;
            stagingElements.add(stagingElement1);

            unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c =String.valueOf(i);
            unitObj.Address_Type__c = '12';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c = '12';
            unitList.add(unitObj);
        }

        //validation will fail on this on for the unit, response will not be created because it is a collection unit
        Staging_Element__c stagingElement2 = TestDataHelper.createStagingElement(false);
        stagingElement2.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement2.U_DP_ID__c = '431';
        stagingElement2.U_Unit_of_Interest_Id__c = '431';
        stagingElement2.U_Rural_Delivery_Number__c = null;
        stagingElement2.U_P_O_Box__c = '12';
        stagingElement2.R_Access_Code__c = '1';
        stagingElement2.WL_Workload_ID__c = null;
        stagingElement2.WI_Work_Item_ExtId__c = null;
        stagingElement2.C_Legacy_Contact_ID__c =null;
        stagingElement2.CR_Contact_ExtId__c = null;
        stagingElement2.CR_Unit_Of_Interest_Id__c = null;
        stagingElement2.A_Instrument_Code__c = null;
        stagingElement2.R_Mark_in_Required__c = false;
        stagingElement2.Collection_Unit__c = true;
        stagingElement2.Survey_Unit__c = false;
        stagingElement2.R_Unit_Association__c = '431';
        stagingElement2.U_Meshblock_Code__c = '0';
        stagingElement2.U_Road_Number__c = 'a';
        stagingElement2.Account_External_Id__c = null;
        stagingElements.add(stagingElement2);
        
        unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='431';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        unitList.add(unitObj);

        

        insert unitList;
        
        insert stagingElements;
        
        
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Name = 'ACODE';
        artefact.Artefact_Code__c = 'ACODE';
        insert artefact;
        List<Artefact__c> artefacts = [select Name, Collection_Modes__c,Artefact_Code__c, Artefact_ExtId__c,Collection__c from Artefact__c where Collection__c = :collectionInstance.Id];
        collectionInstance = [select Collection_Instance_Code__c,Delivery_Mode__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c 
                              from  Collection_Instance__c 
                              where Id = :collectionInstance.Id];
        
        List<Contact> contList = new List<Contact>();
        for(Integer i=0; i<200; i++){
            Contact cnt = TestDataHelper.createContact(false);
            cnt.FirstName = 'fname'+i;
            cnt.LastName = 'lname'+i;
            cnt.email = 'test'+i+'@test.test';
            cnt.Phone = 'phone'+i;
            cnt.Legacy_Contact_ID__c = String.valueOf(i);
            cnt.Address_ID__c = String.valueOf(i);
            cnt.Mobile_Device_Id__c = String.valueOf(i);
            if(i<199){
                cnt.Building_Name__c='Building2';
            }
            contList.add(cnt);
        }
        insert contList;
        List<Contact_Role__c> crlst = new List<Contact_Role__c>();
        for(Integer i=0; i<200; i++){
            Contact_Role__c cr = TestDataHelper.createContactRole(collection.Id, unitList[i].Id, contList[i].Id, false);
            cr.Status__c = 'Active';
            cr.Primary_Contact__c = true;
            cr.Identifier__c = String.valueOf(i);
            cr.Mobile_Device_Id__c = String.valueOf(i);
            cr.Preferred_Delivery_Mode__c = 'Post';
            crlst.add(cr);
        } 
        insert crlst;

        List<Contact> ccc = [Select Id from Contact where Building_Name__c='Building2'];
        system.assertEquals(199, ccc.size());

        List<Staging_Element__c> sts = [select Id from Staging_Element__c];
        System.assertEquals(200, sts.size());

        List<Contact> testContacts_1 = [Select Id from Contact];
        System.assertEquals(200, contList.size());
        System.assertEquals(200, testContacts_1.size());

        test.startTest();
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(collectionInstance.Id);
        Database.executeBatch(instance,200);
        test.stopTest();

        List<Contact> ccc2 = [Select Id from Contact where Building_Name__c='Building2'];
        system.assertEquals(199, ccc2.size());
        
        List<Staging_Element__c> failed = [select Id,Errors__c from Staging_Element__c where Failed__c = true];
        system.debug('Errors__c=='+failed);
        system.assertEquals(1, failed.size(),failed[0].errors__c);
        List<Staging_Element__c> success = [select Id from Staging_Element__c where Failed__c = false];
        system.assertEquals(0, success.size());
        List<Unit__c> unit = [Select Id,(Select ID,Preferred_Delivery_Mode__c from Contact_Roles__r) from Unit__c];
        system.assertEquals(200, unit.size());
        List<Response__c> response = [Select Id,Unit_Delivery_Mode__c from Response__c];
        system.assertEquals(198, response.size());
        List<Response__c> response1 = [Select Id, Unit_Of_Interest__c, Unit_Delivery_Mode__c,Survey_Unit__c from Response__c where Delivery_Building_Name__c='Building2'];
        system.assertEquals(198, response1.size());// override by contact-role, based on collectio-unit... so, all of them
        system.assertNotEquals(response1[0].Unit_Of_Interest__c, response1[0].Survey_Unit__c,response1[0].Unit_Of_Interest__c+'=='+response1[0].Survey_Unit__c);
        //System.assertEquals(response[1].Unit_Delivery_Mode__c,unit[1].Contact_Roles__r[0].Preferred_Delivery_Mode__c,response[0].Unit_Delivery_Mode__c+'=='+unit[0].Contact_Roles__r[0].Preferred_Delivery_Mode__c);
        Collection_Instance__c vCI = [select id, Sample_Size__c from Collection_Instance__c where id=:collectionInstance.id];
        system.assertEquals(198, vCI.sample_size__c); // 198 forms
    }

    @isTest static void testExecute_ContactAssign_PreferredDeliveryMode(){
        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unitObj = new Unit__c ();
        for(integer i=0; i<200; i++){
            Staging_Element__c stagingElement1 = TestDataHelper.createStagingElement(false);
            stagingElement1.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement1.U_DP_ID__c = String.valueOf(i);
            stagingElement1.U_Unit_of_Interest_Id__c = String.valueOf(i);
            stagingElement1.R_Delivery_Rural_Delivery_Number__c = null;
            stagingElement1.A_Instrument_Code__c = 'ACODE';
            stagingElement1.R_Access_Code__c='a'+i;
            stagingElement1.WL_Workload_ID__c = 'wl'+i;
            stagingElement1.WI_Work_Item_ExtId__c = 'wi'+i;
            stagingElement1.C_Legacy_Contact_ID__c = null;
            stagingElement1.CR_Contact_ExtId__c = 'cr'+i;
            stagingElement1.CR_Unit_Of_Interest_Id__c = null;
            stagingElement1.R_Mark_in_Required__c = true;
            stagingElement1.Collection_Unit__c = true;
            stagingElement1.Survey_Unit__c = true;
            stagingElement1.R_Unit_Association__c = String.valueOf(i);
            stagingElement1.U_Meshblock_Code__c = String.valueOf(i);
            stagingElement1.Account_External_Id__c = null;
            stagingElements.add(stagingElement1);

            unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c =String.valueOf(i);
            unitObj.Address_Type__c = '12';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            unitObj.Meshblock_Code__c = '12';
            unitList.add(unitObj);
        }
        
        insert unitList;
        
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        collectionInstance.Delivery_Mode__c = 'Email';
        insert collectionInstance;
        
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Name = 'ACODE';
        artefact.Artefact_Code__c = 'ACODE';
        artefact.Delivery_Modes__c = 'Post; Email';
        insert artefact;
        List<Artefact__c> artefacts = [select Name, Collection_Modes__c,Artefact_Code__c, Artefact_ExtId__c,Collection__c from Artefact__c where Collection__c = :collectionInstance.Id];
        collectionInstance = [select Collection_Instance_Code__c,Delivery_Mode__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c 
                              from  Collection_Instance__c 
                              where Id = :collectionInstance.Id];
        
        List<Contact> contList = new List<Contact>();
        for(integer i=0;i<200;i++){
            Contact cnt = TestDataHelper.createContact(false);
            cnt.FirstName = 'fname'+i;
            cnt.LastName = 'lname'+i;
            cnt.email = 'test'+i+'@test.test';
            cnt.Phone = 'phone'+i;
            cnt.Legacy_Contact_ID__c = String.valueOf(i);
            cnt.Address_ID__c = String.valueOf(i);
            cnt.Mobile_Device_Id__c = String.valueOf(i);
            contList.add(cnt);
        }
        insert contList;
        List<Contact_Role__c> crlst = new List<Contact_Role__c>();
        for(integer i=0;i<200;i++){
            Contact_Role__c cr = TestDataHelper.createContactRole(collection.Id,unitList[i].Id,contList[i].Id,false);
            cr.Status__c = 'Active';
            cr.Primary_Contact__c = true;
            cr.Identifier__c = String.valueOf(i);
            cr.Mobile_Device_Id__c = String.valueOf(i);
            cr.Preferred_Delivery_Mode__c = 'Post';
            crlst.add(cr);
        }
        insert crlst;

        insert stagingElements;

        test.startTest();
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(collectionInstance.Id);
        Database.executeBatch(instance,200);
        test.stopTest();
        
        List<Staging_Element__c> success = [select Id from Staging_Element__c where Failed__c = false];
        system.assertEquals(0, success.size());
        List<Unit__c> unit = [Select Id,(Select ID,Preferred_Delivery_Mode__c from Contact_Roles__r where Primary_Contact__c = true) from Unit__c];
        system.assertEquals(200, unit.size());
        List<Response__c> response = [Select Id,Unit_Delivery_Mode__c from Response__c];
        system.assertEquals(200, response.size());
        System.assertEquals(response[1].Unit_Delivery_Mode__c, unit[1].Contact_Roles__r[0].Preferred_Delivery_Mode__c);

        Response__c rs = [Select ID,Contact__c,Unit_of_Interest__c from Response__c where Id = :response[1].id];
        Unit__c ut = [Select Id,(Select ID,Preferred_Delivery_Mode__c,Contact__c from Contact_Roles__r where Primary_Contact__c = true) from Unit__c where Id = :rs.Unit_of_Interest__c];
        System.assertEquals(rs.Contact__c, ut.Contact_Roles__r[0].Contact__c);
    }

    @isTest static void testMethodRetail(){
        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        Staging_Element__c stagingElement = TestDataHelper.createStagingElement(false);
        stagingElement.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement.U_DP_ID__c = '421';
        stagingElement.U_Unit_of_Interest_Id__c = '';
        stagingElement.R_Access_Code__c = '2';
        stagingElement.A_Instrument_Code__c = 'ACODE';
        stagingElement.WL_Workload_ID__c = null;
        stagingElement.WI_Work_Item_ExtId__c = null;
        stagingElement.C_Legacy_Contact_ID__c =null;
        stagingElement.CR_Contact_ExtId__c = null;
        stagingElement.CR_Unit_Of_Interest_Id__c = null;
        stagingElement.R_Mark_in_Required__c = true;
        stagingElement.Collection_Unit__c = true;
        stagingElement.Survey_Unit__c = false;
        stagingElement.R_Unit_Association__c = '421';
        stagingElement.U_Meshblock_Code__c = '1';
        stagingElement.U_Building_Name__c = 'Building1';
        stagingElement.R_Response_ExtId__c = null;
        stagingElement.Account_External_Id__c = null;
        stagingElements.add(stagingElement);
        
        for(integer i=0; i<99; i++){
            Staging_Element__c stagingElement3 = TestDataHelper.createStagingElement(false);
            stagingElement3.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement3.U_DP_ID__c = String.valueOf(i);
            stagingElement3.U_Unit_of_Interest_Id__c = '';
            stagingElement3.R_Access_Code__c = '3'+i;
            stagingElement3.WL_Workload_ID__c = null;
            stagingElement3.WI_Work_Item_ExtId__c = null;
            stagingElement3.C_Legacy_Contact_ID__c =null;
            stagingElement3.CR_Contact_ExtId__c = null;
            stagingElement3.CR_Unit_Of_Interest_Id__c = null;
            stagingElement3.A_Instrument_Code__c = null;
            stagingElement3.R_Mark_in_Required__c = false;
            stagingElement3.Collection_Unit__c = false;
            stagingElement3.Survey_Unit__c = true;
            stagingElement3.R_Unit_Association__c = '421';
            stagingElement3.U_Meshblock_Code__c = '2'+i;
            stagingElement3.Account_External_Id__c = null;
            stagingElements.add(stagingElement3);
        }

        Staging_Element__c stagingElement1 = TestDataHelper.createStagingElement(false);
        stagingElement1.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement1.U_DP_ID__c = '421';
        stagingElement1.U_Unit_of_Interest_Id__c = '';
        stagingElement1.R_Access_Code__c = '6';
        stagingElement1.A_Instrument_Code__c = 'ACODE';
        stagingElement1.WL_Workload_ID__c = null;
        stagingElement1.WI_Work_Item_ExtId__c = null;
        stagingElement1.C_Legacy_Contact_ID__c =null;
        stagingElement1.CR_Contact_ExtId__c = null;
        stagingElement1.CR_Unit_Of_Interest_Id__c = null;
        stagingElement1.R_Mark_in_Required__c = true;
        stagingElement1.Collection_Unit__c = true;
        stagingElement1.Survey_Unit__c = false;
        stagingElement1.R_Unit_Association__c = '421.1';
        stagingElement1.U_Meshblock_Code__c = '1';
        stagingElement1.U_Building_Name__c = 'Building2';
        stagingElement1.R_Response_ExtId__c = null;
        stagingElement1.Account_External_Id__c = null;
        stagingElements.add(stagingElement1);
        
        for(integer i=0; i<99; i++){
            Staging_Element__c stagingElement2 = TestDataHelper.createStagingElement(false);
            stagingElement2.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement2.U_DP_ID__c = '400'+i;
            stagingElement2.U_Unit_of_Interest_Id__c = '';
            stagingElement2.R_Access_Code__c = '4'+i;
            stagingElement2.WL_Workload_ID__c = null;
            stagingElement2.WI_Work_Item_ExtId__c = null;
            stagingElement2.C_Legacy_Contact_ID__c =null;
            stagingElement2.CR_Contact_ExtId__c = null;
            stagingElement2.CR_Unit_Of_Interest_Id__c = null;
            stagingElement2.A_Instrument_Code__c = null;
            stagingElement2.R_Mark_in_Required__c = false;
            stagingElement2.Collection_Unit__c = false;
            stagingElement2.Survey_Unit__c = true;
            stagingElement2.R_Unit_Association__c = '421.1';
            stagingElement2.U_Meshblock_Code__c = '3'+i;
            stagingElement2.Account_External_Id__c = null;
            stagingElements.add(stagingElement2);
        }
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        collectionInstance.Delivery_Mode__c = 'Post';
        insert collectionInstance;
        
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Name = 'ACODE';
        artefact.Artefact_Code__c = 'ACODE';
        insert artefact;
        List<Artefact__c> artefacts = [select Name, Collection_Modes__c,Artefact_Code__c, Artefact_ExtId__c,Collection__c from Artefact__c where Collection__c = :collectionInstance.Id];
        collectionInstance = [select Collection_Instance_Code__c,Delivery_Mode__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c 
                              from  Collection_Instance__c 
                              where Id = :collectionInstance.Id];


        insert stagingElements;

        test.startTest();
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(collectionInstance.Id);
        Database.executeBatch(instance,200);
        test.stopTest();
        
        List<Staging_Element__c> failed = [select Id,Errors__c from Staging_Element__c where Failed__c = true];
        system.debug('Errors__c=='+failed);
        system.assertEquals(0, failed.size());
        List<Staging_Element__c> success = [select Id from Staging_Element__c where Failed__c = false];
        system.assertEquals(0, success.size());
        List<Unit__c> unit = [Select Id from Unit__c];
        system.assertEquals(199, unit.size());
        List<Response__c> response = [Select Id,Unit_Delivery_Mode__c from Response__c];
        system.assertEquals(200, response.size());
        System.assertEquals(response[0].Unit_Delivery_Mode__c,collectionInstance.Delivery_Mode__c);
        List<Response__c> response3 = [Select Id from Response__c where Delivery_Building_Name__c='Building1' and Mark_in_Required__c=true]; 
        system.assertEquals(1, response3.size());
        List<Response__c> response4 = [Select Id from Response__c where Delivery_Building_Name__c='Building2' and Mark_in_Required__c=true];
        system.assertEquals(1, response4.size());
        List<Response__c> response1 = [Select Id from Response__c where Mark_in_Required__c=false];
        system.assertEquals(198, response1.size());
        
        Collection_Instance__c vCI = [select id, Sample_Size__c from Collection_Instance__c where id=:collectionInstance.id];
        system.assertEquals(2, vCI.sample_size__c); // only 2 forms
    }
    
    @isTest static void testMethodAgSplit(){
        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        Staging_Element__c stagingElement = TestDataHelper.createStagingElement(false);
        stagingElement.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement.U_DP_ID__c = '421';
        stagingElement.U_Unit_of_Interest_Id__c = '';
        stagingElement.R_Access_Code__c = '2';
        stagingElement.WL_Workload_ID__c = null;
        stagingElement.WI_Work_Item_ExtId__c = null;
        stagingElement.C_Legacy_Contact_ID__c =null;
        stagingElement.CR_Contact_ExtId__c = null;
        stagingElement.CR_Unit_Of_Interest_Id__c = null;
        stagingElement.A_Instrument_Code__c = null;
        stagingElement.R_Mark_in_Required__c = false;
        stagingElement.Collection_Unit__c = true;
        stagingElement.Survey_Unit__c = false;
        stagingElement.R_Unit_Association__c = '421';
        stagingElement.U_Meshblock_Code__c = '1';
        stagingElement.U_Building_Name__c = 'Building1';
        stagingElement.R_Response_ExtId__c = null;
        stagingElement.Account_External_Id__c = null;
        stagingElements.add(stagingElement);
        
        for(integer i=0; i<99; i++){
            Staging_Element__c stagingElement3 = TestDataHelper.createStagingElement(false);
            stagingElement3.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement3.U_DP_ID__c = String.valueOf(i);
            stagingElement3.U_Unit_of_Interest_Id__c = '';
            stagingElement3.R_Access_Code__c = '3'+i;
            stagingElement3.A_Instrument_Code__c = 'ACODE';
            stagingElement3.WL_Workload_ID__c = null;
            stagingElement3.WI_Work_Item_ExtId__c = null;
            stagingElement3.C_Legacy_Contact_ID__c =null;
            stagingElement3.CR_Contact_ExtId__c = null;
            stagingElement3.CR_Unit_Of_Interest_Id__c = null;
            stagingElement3.R_Mark_in_Required__c = true;
            stagingElement3.Collection_Unit__c = false;
            stagingElement3.Survey_Unit__c = true;
            stagingElement3.R_Unit_Association__c = '421';
            stagingElement3.U_Meshblock_Code__c = '3'+i;
            stagingElement3.Account_External_Id__c = null;
            stagingElements.add(stagingElement3);
        }

        Staging_Element__c stagingElement1 = TestDataHelper.createStagingElement(false);
        stagingElement1.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement1.U_DP_ID__c = '421';
        stagingElement1.U_Unit_of_Interest_Id__c = '';
        stagingElement1.R_Access_Code__c = '2';
        stagingElement1.WL_Workload_ID__c = null;
        stagingElement1.WI_Work_Item_ExtId__c = null;
        stagingElement1.C_Legacy_Contact_ID__c =null;
        stagingElement1.CR_Contact_ExtId__c = null;
        stagingElement1.CR_Unit_Of_Interest_Id__c = null;
        stagingElement1.A_Instrument_Code__c = null;
        stagingElement1.R_Mark_in_Required__c = false;
        stagingElement1.Collection_Unit__c = true;
        stagingElement1.Survey_Unit__c = false;
        stagingElement1.R_Unit_Association__c = '421.1';
        stagingElement1.U_Meshblock_Code__c = '1';
        stagingElement1.U_Building_Name__c = 'Building2';
        stagingElement1.R_Response_ExtId__c = null;
        stagingElement1.Account_External_Id__c = null;
        stagingElements.add(stagingElement1);
        
        for(integer i=0; i<99; i++){
            Staging_Element__c stagingElement2 = TestDataHelper.createStagingElement(false);
            stagingElement2.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement2.U_DP_ID__c = '400'+i;
            stagingElement2.U_Unit_of_Interest_Id__c = '';
            stagingElement2.R_Access_Code__c = '4'+i;
            stagingElement2.A_Instrument_Code__c = 'ACODE';
            stagingElement2.WL_Workload_ID__c = null;
            stagingElement2.WI_Work_Item_ExtId__c = null;
            stagingElement2.C_Legacy_Contact_ID__c =null;
            stagingElement2.CR_Contact_ExtId__c = null;
            stagingElement2.CR_Unit_Of_Interest_Id__c = null;
            stagingElement2.R_Mark_in_Required__c = true;
            stagingElement2.Collection_Unit__c = false;
            stagingElement2.Survey_Unit__c = true;
            stagingElement2.R_Unit_Association__c = '421.1';
            stagingElement2.U_Meshblock_Code__c = '2'+i;
            stagingElement2.Account_External_Id__c = null;
            stagingElements.add(stagingElement2);
        }

        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        insert collectionInstance;
        
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Name = 'ACODE';
        artefact.Artefact_Code__c = 'ACODE';
        insert artefact;
        List<Artefact__c> artefacts = [select Name, Collection_Modes__c,Artefact_Code__c, Artefact_ExtId__c,Collection__c from Artefact__c where Collection__c = :collectionInstance.Id];
        collectionInstance = [select Collection_Instance_Code__c,Delivery_Mode__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c 
                              from  Collection_Instance__c 
                              where Id = :collectionInstance.Id];

        insert stagingElements;

        test.startTest();
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(collectionInstance.Id);
        Database.executeBatch(instance,200);
        test.stopTest();
        
        List<Staging_Element__c> failed = [select Id,Errors__c from Staging_Element__c where Failed__c = true];
        system.debug('Errors__c=='+failed);
        system.assertEquals(0, failed.size());
        List<Staging_Element__c> success = [select Id from Staging_Element__c where Failed__c = false];
        system.assertEquals(0, success.size());
        List<Unit__c> unit = [Select Id from Unit__c];
        system.assertEquals(199, unit.size());
        List<Response__c> response = [Select Id from Response__c];
        system.assertEquals(198, response.size());
        List<Response__c> response1 = [Select Id from Response__c where Delivery_Building_Name__c='Building1' and Unit_of_Interest__r.Unit_of_Interest_ID__c = '421' and Mark_in_Required__c=true];
        system.assertEquals(99, response1.size());
        List<Response__c> response2 = [Select Id from Response__c where Delivery_Building_Name__c='Building2' and Unit_of_Interest__r.Unit_of_Interest_ID__c = '421' and Mark_in_Required__c=true];
        system.assertEquals(99, response2.size());
    }
    
    @isTest static void testMethodAOS(){
        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
         for(integer i=0; i<200; i++){
             Staging_Element__c stagingElement = TestDataHelper.createStagingElement(false);
             stagingElement.CI_Collection_Instance_Code__c = 'CICODE';
             stagingElement.U_DP_ID__c = '421'+i;
             stagingElement.U_Unit_of_Interest_Id__c = '';
             stagingElement.R_Access_Code__c = '2'+i;
             stagingElement.A_Instrument_Code__c = 'ACODE';
             stagingElement.WL_Workload_ID__c = null;
             stagingElement.WI_Work_Item_ExtId__c = null;
             stagingElement.C_Legacy_Contact_ID__c =null;
             stagingElement.CR_Contact_ExtId__c = null;
             stagingElement.CR_Unit_Of_Interest_Id__c = null;
             stagingElement.R_Mark_in_Required__c = true;
             stagingElement.Collection_Unit__c = true;
             stagingElement.Survey_Unit__c = true;
             stagingElement.R_Unit_Association__c = '421'+i;
             stagingElement.U_Meshblock_Code__c = '1'+i;
             stagingElement.U_Building_Name__c = 'Building1'+i;
             stagingElement.R_Response_ExtId__c = null;
             stagingElement.Account_External_Id__c = null;
             stagingElements.add(stagingElement);
         }
        
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        insert collectionInstance;
        
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Name = 'ACODE';
        artefact.Artefact_Code__c = 'ACODE';
        insert artefact;
        List<Artefact__c> artefacts = [select Name, Collection_Modes__c,Artefact_Code__c, Artefact_ExtId__c,Collection__c from Artefact__c where Collection__c = :collectionInstance.Id];
        collectionInstance = [select Collection_Instance_Code__c,Delivery_Mode__c, Grouping__c,Contextual_Mappings__c, Collection__r.Collection_Code__c, RecordType.Name,Collection__r.Id,Primary_Mode__c 
                              from  Collection_Instance__c 
                              where Id = :collectionInstance.Id];

        insert stagingElements;

        test.startTest();
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(collectionInstance.Id);
        Database.executeBatch(instance,200);
        test.stopTest();
        
        List<Staging_Element__c> failed = [select Id,Errors__c from Staging_Element__c where Failed__c = true];
        system.debug('Errors__c=='+failed);
        system.assertEquals(0, failed.size());
        List<Staging_Element__c> success = [select Id from Staging_Element__c where Failed__c = false];
        system.assertEquals(0, success.size());
        List<Unit__c> unit = [Select Id from Unit__c];
        system.assertEquals(200, unit.size());
        List<Response__c> response = [Select Id from Response__c where Mark_in_Required__c=true];
        system.assertEquals(200, response.size());
        Collection_Instance__c vCI = [select id, Sample_Size__c from Collection_Instance__c where id=:collectionInstance.id];
        system.assertEquals(200, vCI.sample_size__c); 
    }

    @isTest static void testAssignDataFromContactRoleUnit(){
        Collection__c collection = TestDataHelper.createCollection(true);

        Id ciRecordTypeId = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Collections').getRecordTypeId();
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        collectionInstance.RecordTypeId = ciRecordTypeId;
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        List<Contact> contacts = TestDataHelper.selectContact(TestDataHelper.createContact(true).Id);
        Contact contact = contacts.get(0);
        
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, false);
        contactRole.Preferred_Collection_Mode__c = 'test collection mode';
        contactRole.Preferred_Delivery_Mode__c = 'test delivery mode';
        insert contactRole;

        Contact_Role_Unit__c cru = new Contact_Role_Unit__c();
        cru.Survey_Unit_Link__c = unit.Id;
        cru.Contact_Role__c = contactRole.Id;
        insert cru;

        Staging_Element__c se = new Staging_Element__c();
        se.Collection_Unit__c = true;
        se.Survey_Unit__c = true;
        se.CI_Collection_Instance_Code__c = collectionInstance.Collection_Instance_Code__c;
        se.U_Unit_of_Interest_Id__c = unit.Unit_of_Interest_ID__c;
        se.R_Response_ExtId__c = 'zzz';
        se.R_Unit_Association__c = unit.Unit_of_Interest_ID__c;
        insert se;


        Collection_Instance__c ci = [select Collection_Instance_Code__c, 
                                            Collection__r.Collection_Code__c,
                                            RecordType.Name,
                                            Primary_Mode__c,
                                            Delivery_Mode__c,
                                            Grouping__c,
                                            Contextual_Mappings__c
                                    from Collection_Instance__c where Id=:collectionInstance.Id];
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(ci.Id);
        Test.startTest();
        Database.executeBatch(instance,200);
        test.stopTest();

        Response__c response = [select Contact__c, Collection_Mode__c, Unit_Delivery_Mode__c from Response__c limit 1];
        System.assertEquals(contact.Id, response.Contact__c);
        System.assertEquals('test collection mode', response.Collection_Mode__c);
        System.assertEquals('test delivery mode', response.Unit_Delivery_Mode__c);
    }

    @isTest static void duplicateContactTestWithLegacyId(){
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        collectionInstance.Delivery_Mode__c = 'Email';
        insert collectionInstance;

        Contact ct = TestDataHelper.createContact(false);
        ct.firstname = 'xyz';
        ct.lastName = 'zyx';
        ct.phone = '123456789';
        ct.Legacy_Contact_ID__c = '987654';
        insert ct;

        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unitObj = new Unit__c ();

        //response will not be created because it is a collection unit
        Staging_Element__c stagingElement4 = TestDataHelper.createStagingElement(false);
        stagingElement4.CI_Collection_Instance_Code__c = 'CICODE';
        stagingElement4.U_DP_ID__c = '451';
        stagingElement4.U_Unit_of_Interest_Id__c = '451';
        stagingElement4.R_Access_Code__c = '4';
        stagingElement4.WL_Workload_ID__c = null;
        stagingElement4.WI_Work_Item_ExtId__c = null;
        stagingElement4.C_Legacy_Contact_ID__c =null;
        stagingElement4.C_FirstName__c ='xyz';
        stagingElement4.C_LastName__c = 'zyx';
        stagingElement4.C_Phone__c = '123456789';
        stagingElement4.CR_Contact_ExtId__c = null;
        stagingElement4.CR_Unit_Of_Interest_Id__c = null;
        stagingElement4.A_Instrument_Code__c = null;
        stagingElement4.R_Mark_in_Required__c = true;
        stagingElement4.Collection_Unit__c = true;
        stagingElement4.Survey_Unit__c = false;
        stagingElement4.R_Unit_Association__c = '451';
        stagingElement4.U_Meshblock_Code__c = '3';
        stagingElement4.U_Building_Name__c = 'Building1';
        stagingElement4.Account_External_Id__c = null;
        stagingElement4.U_Road_Number__c = '124';
        stagingElement4.U_Rural_Delivery_Number__c = null;
        insert stagingElement4;
        
        unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='451';
        unitObj.Address_Type__c = '12';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        unitObj.Meshblock_Code__c = '12';
        unitList.add(unitObj);
        insert unitList;

        Collection_Instance__c ci = [select Collection_Instance_Code__c, 
                                            Collection__r.Collection_Code__c,
                                            RecordType.Name,
                                            Primary_Mode__c,
                                            Delivery_Mode__c,
                                            Grouping__c,
                                            Contextual_Mappings__c
                                    from Collection_Instance__c where Id=:collectionInstance.Id];
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(ci.Id);
        Test.startTest();
        Database.executeBatch(instance,200);
        test.stopTest();
        Contact_Role__c cr = [select contact__c from Contact_Role__c limit 1];
        System.assertEquals(ct.Id, cr.contact__c);
    }

    @isTest static void duplicateContactTestWithOutLegacyId(){
        Collection__c collection = TestDataHelper.createCollection(false);
        collection.Collection_Code__c = 'CCODE';
        insert collection;

        Grouping__c gr = TestDataHelper.createGroupings(collection.Id, true);
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(collection.Id, true);
        
        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Collection_Instance_Code__c = 'CICODE';
        collectionInstance.Grouping__c = gr.Id;
        collectionInstance.Contextual_Mappings__c = cm.Id;
        collectionInstance.Delivery_Mode__c = 'Email';
        insert collectionInstance;

        Contact ct = TestDataHelper.createContact(false);
        ct.firstname = 'xyz';
        ct.lastName = 'zyx';
        ct.phone = '123456789';
        ct.Legacy_Contact_ID__c = null;
        insert ct;

        List<Staging_Element__c> stagingElements = new List<Staging_Element__c>();
        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unitObj = new Unit__c ();

        for(integer i=0; i<200; i++){
            Staging_Element__c stagingElement4 = TestDataHelper.createStagingElement(false);
            stagingElement4.CI_Collection_Instance_Code__c = 'CICODE';
            stagingElement4.U_DP_ID__c = '451';
            stagingElement4.U_Unit_of_Interest_Id__c = '451';
            stagingElement4.R_Access_Code__c = '4'+i;
            stagingElement4.WL_Workload_ID__c = null;
            stagingElement4.WI_Work_Item_ExtId__c = null;
            stagingElement4.C_Legacy_Contact_ID__c =null;
            stagingElement4.C_FirstName__c ='xyz';
            stagingElement4.C_LastName__c = 'zyx';
            stagingElement4.C_Phone__c = '123456789';
            stagingElement4.CR_Contact_ExtId__c = null;
            stagingElement4.CR_Unit_Of_Interest_Id__c = null;
            stagingElement4.A_Instrument_Code__c = null;
            stagingElement4.R_Mark_in_Required__c = true;
            stagingElement4.Collection_Unit__c = true;
            stagingElement4.Survey_Unit__c = false;
            stagingElement4.R_Unit_Association__c = '451'+i;
            stagingElement4.U_Meshblock_Code__c = '3'+i;
            stagingElement4.U_Building_Name__c = 'Building1'+i;
            stagingElement4.Account_External_Id__c = null;
            stagingElement4.U_Road_Number__c = '124';
            stagingElement4.U_Rural_Delivery_Number__c = null;
            stagingElements.add(stagingElement4);
        }
        insert stagingElements;
        
        Collection_Instance__c ci = [select Collection_Instance_Code__c, 
                                            Collection__r.Collection_Code__c,
                                            RecordType.Name,
                                            Primary_Mode__c,
                                            Delivery_Mode__c,
                                            Grouping__c,
                                            Contextual_Mappings__c
                                    from Collection_Instance__c where Id=:collectionInstance.Id];
        ProcessImportsFromStagingBatch instance = new ProcessImportsFromStagingBatch(ci.Id);
        Test.startTest();
        Database.executeBatch(instance,200);
        test.stopTest();
        Contact_Role__c cr = [select contact__c from Contact_Role__c limit 1];
        System.assertEquals(ct.Id, cr.contact__c);
    }

}