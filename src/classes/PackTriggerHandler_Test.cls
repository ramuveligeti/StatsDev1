@isTest
private class PackTriggerHandler_Test {
    @isTest static void validateDeliveryModesTest(){
        Collection__c collection = TestDataHelper.createCollection(true);
        Artefact__c artefact = TestDataHelper.createArtefact(collection.Id, false);
        artefact.Delivery_Modes__c = 'Post;Email';
        insert artefact;
        Pack__c pack = TestDataHelper.createPack(collection.Id,false);
        pack.Delivery_Mode__c = 'Email';
        insert pack;
        pack.Delivery_Mode__c = 'Post';
        test.startTest();
        Pack_Contents__c packContents = TestDataHelper.createPackContents(pack.Id,artefact.Id,true);
        update pack;
        test.stopTest();
        Pack_Contents__c pc = [Select Id, Artefact__c, Artefact__r.Delivery_Modes__c from Pack_Contents__c where Id = :packContents.id];
        system.assert(packContents!=null);
        system.assert(pc.Artefact__r.Delivery_Modes__c.contains(pack.Delivery_Mode__c));
    }
}