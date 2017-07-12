public class UnitTriggerHandler {

	public static void copyUnitFieldsFromOriginUnit(List<Unit__c> units){
		Set<Id> parentUnitIds = new Set<Id>();
		for(Unit__c u:units){
            if(!String.isBlank(u.Created_From_Unit_Id__c)){
				parentUnitIds.add(u.Created_From_Unit_Id__c);
            }
		}
		
		if(!parentUnitIds.isEmpty()){
			Map<Id, Unit__c> parentUnits = new Map<Id, Unit__c>([select Area_Unit_Name__c, Area_Unit_Number__c, PSU_Name__c, PSU_Number__c, Region_Number__c, Region_Name__c, 
	    																Team_Leader_Area_Name__c, Team_Leader_Area_Number__c, Territorial_Authority_Name__c, Territorial_Authority_Number__c
	    															from Unit__c where id in :parentUnitIds]);
			
			for(Unit__c unit:units){
                if(!String.isBlank(unit.Created_From_Unit_Id__c)){
					Unit__c parentUnit = parentUnits.get(unit.Created_From_Unit_Id__c);
					if(parentUnit!=null){
						unit.Area_Unit_Name__c = parentUnit.Area_Unit_Name__c;
						unit.Area_Unit_Number__c = parentUnit.Area_Unit_Number__c;
						unit.PSU_Name__c = parentUnit.PSU_Name__c;
						unit.PSU_Number__c = parentUnit.PSU_Number__c;
						unit.Region_Number__c = parentUnit.Region_Number__c;
						unit.Region_Name__c = parentUnit.Region_Name__c;
						unit.Team_Leader_Area_Name__c = parentUnit.Team_Leader_Area_Name__c;
						unit.Team_Leader_Area_Number__c = parentUnit.Team_Leader_Area_Number__c;
						unit.Territorial_Authority_Name__c = parentUnit.Territorial_Authority_Name__c;
						unit.Territorial_Authority_Number__c = parentUnit.Territorial_Authority_Number__c;
					}
                }
			}
		}
	}
}