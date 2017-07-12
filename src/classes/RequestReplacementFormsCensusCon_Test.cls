@isTest
private class RequestReplacementFormsCensusCon_Test {
    @testSetup static void setupData(){
        TestDataHelper.createResponseProperties();
    }

    @isTest static void testMethod1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
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
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
            resp.Status__c = 'No Response';
            resp.Instrument__c = artefact.Id;
			insert resp;
			resp = [Select Id,Response__c.Instrument__c,Response__c.Collection_Instance__r.Collection__c from Response__c where Id = :resp.Id];

            test.startTest();
            ApexPages.StandardController stdCont = new ApexPages.StandardController(resp);
            
            RequestReplacementFormsCensusCon rrf = new RequestReplacementFormsCensusCon(stdCont);
            rrf.cancel();
            rrf.createWorkItems();
            List<Work_Item__c> wi = [Select Id from Work_Item__c];
            system.assertEquals(0, wi.size());
            system.assertEquals(null, rrf.selectedDeliveryMode);
            rrf.selectedDeliveryMode = 'Post';
            rrf.createWorkItems();
            system.assertEquals(false, rrf.InstrumentsWrapperList[0].sel);
            system.assertEquals(false, rrf.InstrumentsWrapperList[1].sel);
            system.assertEquals(false, rrf.CollateralWrapperList[0].sel);
            List<Work_Item__c> wi1 = [Select Id from Work_Item__c];
            system.assertEquals(0, wi1.size());
            rrf.InstrumentsWrapperList[0].sel = true;
            rrf.InstrumentsWrapperList[0].copies = -1;
            rrf.createWorkItems();
            List<Work_Item__c> wi2 = [Select Id from Work_Item__c];
            system.assertEquals(0, wi2.size());
            rrf.InstrumentsWrapperList[0].sel = true;
            rrf.InstrumentsWrapperList[0].copies = 1;
            rrf.InstrumentsWrapperList[1].sel = true;
            rrf.InstrumentsWrapperList[1].copies = 1;
            rrf.CollateralWrapperList[0].sel = true;
            rrf.CollateralWrapperList[0].copies = -1;
            rrf.createWorkItems();
            List<Work_Item__c> wi3 = [Select Id from Work_Item__c];
            system.assertEquals(0, wi3.size());
            rrf.CollateralWrapperList[0].sel = true;
            rrf.CollateralWrapperList[0].copies = 1;
            rrf.CollateralWrapperList[1].sel = true;
            rrf.CollateralWrapperList[1].copies = 1;
            rrf.selectedPack = pack.Id;
            rrf.createWorkItems();
            List<Work_Item__c> wi4 = [Select Id, Instrument__c,Num_of_requested_forms__c from Work_Item__c];
            system.assertEquals(4, wi4.size());
            Work_Item__c wi5 = [Select Id, Instrument__c,Pack__c,Num_of_requested_forms__c from Work_Item__c where Instrument__c = :artefact.Id];
            system.assertEquals(2, wi5.Num_of_requested_forms__c);
            system.assertEquals(pack.Id,wi5.Pack__c);
            Work_Item__c wi6 = [Select Id, Instrument__c,Pack__c,Num_of_requested_forms__c from Work_Item__c where Instrument__c = :artefact1.Id];
            system.assertEquals(2, wi6.Num_of_requested_forms__c);
            system.assertEquals(pack.Id,wi6.Pack__c);
            Work_Item__c wi7 = [Select Id, Instrument__c,Pack__c,Num_of_requested_forms__c from Work_Item__c where Instrument__c = :artefact2.Id];
            system.assertEquals(2, wi7.Num_of_requested_forms__c);
            system.assertEquals(pack.Id,wi7.Pack__c);
            Work_Item__c wi8 = [Select Id, Instrument__c,Pack__c,Num_of_requested_forms__c from Work_Item__c where Instrument__c = :artefact3.Id];
            system.assertEquals(1, wi8.Num_of_requested_forms__c);
            system.assertEquals(NULL,wi8.Pack__c);
            test.stopTest();
        }        
    }
}