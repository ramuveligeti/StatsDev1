/**
* @description   Test class for the CollectionInstanceFlowCC Class
* @author        Ram Veligeti
* @date          26.Mar.2015
*/
@isTest
private class CollectionInstanceFlowCC_Test{
    
    @isTest static void methodOne(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
            test.startTest();
            PageReference pageRef = Page.CollectionInstanceFlow;
            Test.setCurrentPage(pageRef);            
            //ApexPages.currentPage().getParameters().put('Id', col.Id);
            ApexPages.StandardController stdController = new ApexPages.StandardController(col);
            CollectionInstanceFlowCC cc = new CollectionInstanceFlowCC(stdController);
            String colInstId = cc.getcollectionInstanceId();
            cc.getFinishLocation();
            test.stopTest();
        }
    }
}