@isTest
private class CollectionResponseRateCustomSettingTest {
    
    @TestSetup
    private static void setup(){
		Collection__c col = TestDataHelper.createCollection(false);
		col.Name = 'EricTest';
		col.Collection_Code__c = 'EricTDD';
		insert col;
		
		
		Grouping_Settings__c config=new Grouping_Settings__c(name='ECP_SYSTEM',Standard_Fields__c='Wave__c,Key__c,Birth__c,Mark_In__c');
		insert config;
    }
    
    
    @isTest
    private static void uiTest(){
    	Collection__c c=[select id, Collection_Code__c from Collection__c];
    	CollectionResponseRateCustomSettingCtrl ctr = new CollectionResponseRateCustomSettingCtrl(new ApexPages.StandardController(c));
    	
    	system.assertEquals(4,ctr.availableFields.size());
    	
    	Grouping_Settings__c[]v=[select name,Standard_Fields__c from Grouping_Settings__c where name='EricTDD'];
    	system.assertEquals(0,v.size());
    	
    	ctr.availableFields[0].selected=true;
    	ctr.save();
    	
    	v=[select name,Standard_Fields__c from Grouping_Settings__c where name='EricTDD'];
    	system.assertEquals(1,v.size());
    	system.assertEquals('Wave__c',v[0].Standard_Fields__c);


    	ctr.availableFields[0].selected=false;
    	ctr.availableFields[3].selected=true;
    	ctr.save();

    	v=[select name,Standard_Fields__c from Grouping_Settings__c where name='EricTDD'];
    	system.assertEquals(1,v.size());
    	system.assertEquals('Mark_In__c',v[0].Standard_Fields__c);
    }

    @isTest
    private static void uiTes2(){
    	Grouping_Settings__c s=new Grouping_Settings__c(name='EricTDD', Standard_Fields__c='Key__c');
    	insert s;
    	Collection__c c=[select id, Collection_Code__c from Collection__c];
    	CollectionResponseRateCustomSettingCtrl ctr = new CollectionResponseRateCustomSettingCtrl(new ApexPages.StandardController(c));
    	
    	system.assert(ctr.availableFields[1].selected);
    	
    	ctr.availableFields[0].selected=true;
    	ctr.save();
    	
    	Grouping_Settings__c[]v=[select name,Standard_Fields__c from Grouping_Settings__c where name='EricTDD'];
    	system.assertEquals(1,v.size());
    	system.assertEquals('Wave__c,Key__c',v[0].Standard_Fields__c);


    }
}