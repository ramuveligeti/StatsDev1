@isTest
private class RequestReplacementFormsCon_Test {
      @testSetup static void setupData(){
            TestDataHelper.createResponseProperties();

            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Bussiness';
            col.Collection_Code__c = 'Bussiness';
            insert col;

            Artefact__c artefact = TestDataHelper.createArtefact(col.Id, false);
            artefact.Artefact_Code__c = '321';
            artefact.Delivery_Modes__c = 'Post;Email';
            artefact.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
            insert artefact;

            Artefact__c artefact1 = TestDataHelper.createArtefact(col.Id, false);
            artefact1.Artefact_Code__c = '123';
            artefact1.Delivery_Modes__c = 'Post;Email';
            artefact1.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Collateral').getRecordTypeId();
            insert artefact1;

            Artefact__c artefact2 = TestDataHelper.createArtefact(col.Id, false);
            artefact2.Artefact_Code__c = '4321';
            artefact2.Delivery_Modes__c = 'Post';
            artefact2.RecordTypeId = Artefact__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Instrument').getRecordTypeId();
            insert artefact2;

            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            colIns.Status__c='Active';
            insert colIns;

            Pack__c pack1 = TestDataHelper.createPack(col.Id, false);
            pack1.Name = 'pack1';
            pack1.Replaceable__c = true;
            pack1.Delivery_Mode__c = 'Post';
            insert pack1;

            Pack_Contents__c pc1 = TestDataHelper.createPackContents(pack1.Id, artefact.Id, true);
            Pack_Contents__c pc2 = TestDataHelper.createPackContents(pack1.Id, artefact1.Id, true);
            Pack_Contents__c pc3 = TestDataHelper.createPackContents(pack1.Id, artefact2.Id, true);

            Pack__c pack2 = TestDataHelper.createPack(col.Id, false);
            pack2.Name = 'pack2';
            pack2.Replaceable__c = true;
            pack2.Delivery_Mode__c = 'Post';
            insert pack2;

            Pack__c pack3 = TestDataHelper.createPack(col.Id, false);
            pack3.Name = 'pack3';
            pack3.Replaceable__c = true;
            pack3.Delivery_Mode__c = 'Email';
            insert pack3;

            Pack__c pack4 = TestDataHelper.createPack(col.Id, false);
            pack4.Name = 'pack4';
            pack4.Replaceable__c = true;
            pack4.Delivery_Mode__c = 'Post';
            insert pack4;

            Pack__c pack5 = TestDataHelper.createPack(col.Id, false);
            pack5.Name = 'pack5';
            pack5.Replaceable__c = true;
            pack5.Delivery_Mode__c = 'Post';
            insert pack5;

            Pack__c pack6 = TestDataHelper.createPack(col.Id, false);
            pack6.Name = 'pack6';
            pack6.Replaceable__c = true;
            pack6.Delivery_Mode__c = 'Post';
            insert pack6;

            Pack__c pack7 = TestDataHelper.createPack(col.Id, false);
            pack7.Name = 'pack7';
            pack7.Replaceable__c = true;
            pack7.Delivery_Mode__c = 'Post';
            insert pack7;



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

            Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp1.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
            resp1.Status__c = 'No Response';
            resp1.Instrument__c = artefact2.Id;
            insert resp1;
      }

      @isTest static void testContructor_1(){
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Contact Id was not provided')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testContructor_2(){
            ApexPages.currentPage().getParameters().put('cid', '1234567');

            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Contact was not found for id 1234567')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testContructor_3(){
            Contact contact = new Contact();
            contact.LastName = 'test_42';
            contact.Email = 'test_42@test.test';
            contact.Phone = '+64 (000) 00000042';
            contact.HomePhone = '+64 (000) 0000042';
            contact.MobilePhone = '+64 (000) 0000042';
            insert contact;

            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Contact is not assosiated with Active Collection Instance')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testContructor_4(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            Boolean b = false;
            System.debug('controller.ciSelectOptions = '+controller.ciSelectOptions);
            for(SelectOption option:controller.ciSelectOptions){
                  if(option.getValue().equals(collectionInstance.Id)){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testOnCollectionInstanceChange_1(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            
            System.assertEquals(3, controller.dmSelectOptions.size());
            System.assertEquals(2, controller.responses.size());
      }

      @isTest static void testOnDeliveryModeChange_1(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();
            
            System.assertEquals(6, controller.packs.size());
            System.assert(controller.getHasResponses());
            System.assert(controller.getHasPacks());
            System.assert(controller.getHasActiveCollectionIntance());
            System.assert(controller.getHasSelectedCollectionInstance());
            System.assert(controller.getHasSelectedDeliveryMode());
            System.assert(controller.getHasReplaceables());
      }

      @isTest static void testCancel_1(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            PageReference page = controller.cancel();

            System.assertEquals('/'+contact.Id, page.getUrl());
      }

      @isTest static void testCreateWorkItems_1(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();

            controller.createWorkItems();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Please select at least one unit response')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testCreateWorkItems_2(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();
            for(RequestReplacementFormsCon.ResponseWrapper r:controller.responses){
                  r.sel = true;
            }

            controller.createWorkItems();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Please select at least one pack')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testCreateWorkItems_3(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();
            for(RequestReplacementFormsCon.ResponseWrapper r:controller.responses){
                  r.sel = true;
            }

            controller.createWorkItems();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Please select at least one pack')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testCreateWorkItems_4(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();

            System.assertEquals(6, controller.packs.size());

            for(RequestReplacementFormsCon.ResponseWrapper r:controller.responses){
                  r.sel = true;
            }
            for(RequestReplacementFormsCon.PackWrapper p:controller.packs){
                  p.sel = true;
            }

            controller.createWorkItems();
            Boolean b = false;
            for(Apexpages.Message msg:ApexPages.getMessages()){
                  if (msg.getDetail().contains('Cannot select more than five packs')){
                        b = true;
                  }
            }
            System.assert(b); 
      }

      @isTest static void testCreateWorkItems_5(){
            Contact contact = [select Id from Contact limit 1];
            ApexPages.currentPage().getParameters().put('cid', contact.Id);

            Collection_Instance__c collectionInstance = [select Id from Collection_Instance__c limit 1];
            RequestReplacementFormsCon controller = new RequestReplacementFormsCon();
            controller.selectedCollectionInstance = collectionInstance.Id;
            controller.onCollectionInstanceChange();
            controller.selectedDeliveryMode = 'Post';
            controller.onDeliveryModeChange();

            System.assertEquals(6, controller.packs.size());

            for(RequestReplacementFormsCon.ResponseWrapper r:controller.responses){
                  r.sel = true;
            }
            for(RequestReplacementFormsCon.PackWrapper p:controller.packs){
                  if(p.pack.Name.equals('pack1')){
                        p.sel = true;
                  }
            }

            PageReference page = controller.createWorkItems();
            System.assertEquals('/'+contact.Id, page.getUrl());

            List<Response__c> responses = [select Id from Response__c];
            Set<Id> responseIds = new Set<Id>();
            for(Response__c r:responses){
                  responseIds.add(r.Id);
            }

            List<Work_Item__c> workitems = [select Id, Response__c, Work_Item_Type__c, Delivery_Mode__c, Contact__c from Work_Item__c];
            System.assertEquals(2, workitems.size());

            for(Work_Item__c w:workitems){
                  System.assert(responseIds.contains(w.Response__c));
                  System.assertEquals('Replacement questionnaire', w.Work_Item_Type__c); 
                  System.assertEquals('Post', w.Delivery_Mode__c); 
                  System.assertEquals(contact.Id, w.Contact__c); 
            }
      }
}