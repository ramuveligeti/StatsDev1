@isTest
private class DeleteFromStagingBatchTest {
    
    @testSetup
    private static void setup(){
    	Collection__c collection = TestDataHelper.createCollection(false);
		collection.Collection_Code__c = 'CCODE';
		insert collection;
		
		Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
		collectionInstance.Collection_Instance_Code__c = 'TESTME111';
		insert collectionInstance;

    	//setup 1000 records for batch test, 200 per batch
    	Staging_Element__c[]ses=new Staging_Element__c[]{};
    	for(integer i=0;i<1000;i++){
    		ses.add(new Staging_Element__c(CI_Collection_Instance_Code__c='TESTME111', Failed__c=(Math.mod(i,2)==0), Errors__c='Test Failed'));
    	}
    	insert ses;
    }
    
    
    @isTest
    private static void testBatch(){
    	Collection_Instance__c ci = [select Collection_Instance_Code__c from Collection_Instance__c where Collection_Instance_Code__c='TESTME111'];
    	Staging_Element__c[] ses = [select id from Staging_ELement__c where CI_Collection_Instance_Code__c='TESTME111'];
    	system.assertEquals(1000,ses.size());    	
    	Test.startTest();
        String j=Database.executeBatch(new DeleteFromStagingBatch(ci), 1000);
    	Test.stopTest();
    	ses=[select id from Staging_ELement__c where CI_Collection_Instance_Code__c='TESTME111'];
    	system.assertEquals(500,ses.size());    	
    }
}