@isTest
private class UnitTriggerHandlerTest{
    
    static testMethod void testCopyUnitFieldsFromOriginUnit(){
    	Unit__c parentUnit = TestDataHelper.createUnit(false);
    	parentUnit.Area_Unit_Name__c = 'TestAreaUnitName';
		parentUnit.Area_Unit_Number__c = '123';
		parentUnit.PSU_Name__c = 'TestPSUName';
		parentUnit.PSU_Number__c = '234';
		parentUnit.Region_Number__c = '345';
		parentUnit.Region_Name__c = 'TestRegionName';
		parentUnit.Team_Leader_Area_Name__c = 'TestTeamLeaderAreaName';
		parentUnit.Team_Leader_Area_Number__c = '456';
		parentUnit.Territorial_Authority_Name__c = 'TestTerritorialAuthorityName';
		parentUnit.Territorial_Authority_Number__c = '567';
		insert parentUnit;
		
		Unit__c unit = TestDataHelper.createUnit(false);
		unit.Created_From_Unit_Id__c = parentUnit.Id;
		
		List<Unit__c> units = new List<Unit__c>();
		units.add(unit);
		
		UnitTriggerHandler.copyUnitFieldsFromOriginUnit(units);
		
		System.assertEquals('TestAreaUnitName', unit.Area_Unit_Name__c);
		System.assertEquals('123', unit.Area_Unit_Number__c);
		System.assertEquals('TestPSUName', unit.PSU_Name__c);
		System.assertEquals('234', unit.PSU_Number__c);
		System.assertEquals('345', unit.Region_Number__c);
		System.assertEquals('TestRegionName', unit.Region_Name__c);
		System.assertEquals('TestTeamLeaderAreaName', unit.Team_Leader_Area_Name__c);
		System.assertEquals('456', unit.Team_Leader_Area_Number__c);
		System.assertEquals('TestTerritorialAuthorityName', unit.Territorial_Authority_Name__c);
		System.assertEquals('567', unit.Territorial_Authority_Number__c);
    }
    
    static testMethod void testCreateNewUnitFromOriginUnit(){
    	Unit__c parentUnit = TestDataHelper.createUnit(false);
		parentUnit.Unit_of_Interest_ID__c = '1';
    	parentUnit.Area_Unit_Name__c = 'TestAreaUnitName';
		parentUnit.Area_Unit_Number__c = '123';
		parentUnit.PSU_Name__c = 'TestPSUName';
		parentUnit.PSU_Number__c = '234';
		parentUnit.Region_Number__c = '345';
		parentUnit.Region_Name__c = 'TestRegionName';
		parentUnit.Team_Leader_Area_Name__c = 'TestTeamLeaderAreaName';
		parentUnit.Team_Leader_Area_Number__c = '456';
		parentUnit.Territorial_Authority_Name__c = 'TestTerritorialAuthorityName';
		parentUnit.Territorial_Authority_Number__c = '567';
		insert parentUnit;
		
		Unit__c unit = TestDataHelper.createUnit(false);
		unit.Unit_of_Interest_ID__c = '2';
		unit.Created_From_Unit_Id__c = parentUnit.Id;
		insert unit;
		
		Unit__c testUnit = [select Area_Unit_Name__c, Area_Unit_Number__c, PSU_Name__c, PSU_Number__c, Region_Number__c, Region_Name__c, 
	    				Team_Leader_Area_Name__c, Team_Leader_Area_Number__c, Territorial_Authority_Name__c, Territorial_Authority_Number__c
	    			from Unit__c where id = :unit.Id];
		
		System.assertEquals('TestAreaUnitName', testUnit.Area_Unit_Name__c);
		System.assertEquals('123', testUnit.Area_Unit_Number__c);
		System.assertEquals('TestPSUName', testUnit.PSU_Name__c);
		System.assertEquals('234', testUnit.PSU_Number__c);
		System.assertEquals('345', testUnit.Region_Number__c);
		System.assertEquals('TestRegionName', testUnit.Region_Name__c);
		System.assertEquals('TestTeamLeaderAreaName', testUnit.Team_Leader_Area_Name__c);
		System.assertEquals('456', testUnit.Team_Leader_Area_Number__c);
		System.assertEquals('TestTerritorialAuthorityName', testUnit.Territorial_Authority_Name__c);
		System.assertEquals('567', testUnit.Territorial_Authority_Number__c);
    }
    
}