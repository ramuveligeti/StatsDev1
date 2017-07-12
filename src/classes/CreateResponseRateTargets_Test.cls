@isTest
private class CreateResponseRateTargets_Test{
    @isTest static void createGroupings(){
        Grouping_Settings__c gs = new Grouping_Settings__c();
        gs.Name = 'CCODE';
        gs.Standard_Fields__c = 'Wave__c,Key__c';
        insert gs;
        Collection__c col = TestDataHelper.createCollection(false);
        col.Collection_Code__c = 'CCODE';
        insert col;
		Grouping__c gr = TestDataHelper.createGroupings(col.Id, false);
        gr.GR_1_Label__c = 'Accomodation Type';
        gr.GV1__c = 'Hotel,Motel';
        gr.GR_2_Label__c = 'Region';
        gr.GV2__c = 'Auckland';
        insert gr;
        Contextual_Mappings__c cm = TestDataHelper.createContextualMappings(col.Id, true);
        Response_Rate__c responseRate = TestDataHelper.createResponseRate(col.Id,gr.Id,true);
        responseRate = [Select id,Grouping__c,Grouping__r.Active__c,Collection__r.Collection_Code__c,Active__c from Response_Rate__c where Id = :responseRate.Id];
        test.startTest();
        {
            ApexPages.StandardController stdCont = new ApexPages.StandardController(responseRate);
            CreateResponseRateTargets cig = new CreateResponseRateTargets(stdCont);
            cig.getDynamicSection();
            cig.response.Wave__c = '6';
            cig.response.Key__c = true;
            cig.grouping.GV1__c ='Hotel';
            cig.inputRRT.Target_Percentage__c=100;
            cig.inputRRT.measure__c='Value';
            cig.save();
        }
        test.stopTest();
        Response_Rate_Target__c ci = [Select Id,Target_Value__c,Target_Name__c,Target_Percentage__c from Response_Rate_Target__c];
        system.assert(ci.Target_Value__c.contains('6-true-Hotel-Auckland'));
        system.assert(ci.Target_Name__c.contains('Wave-Key-Accomodation Type-Region'));
        system.assertEquals(100, ci.Target_Percentage__c);
    }
}