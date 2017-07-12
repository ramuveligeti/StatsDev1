@isTest
private class SpecialArrangementTriggerHandlerTest {
	public static Collection__c collection;
	public static list<Unit__c> units; 				
    public static list<Special_Arrangement__c> dniSAs; 					

    public static void setup(integer numberOfSA){
    	if(numberOfSA < 1){
    		system.debug('Error: number of sas must be 1 or higher');
    		return;
    	} 
    	collection = TestDataHelper.createCollection(false);
        collection.Name = 'HLFS';
        collection.Collection_Code__c = 'test';
    	collection.RecordTypeId = Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        insert collection;   
        units = new List<Unit__c>();
        Id houseHoldRecordType = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Household Unit').getRecordTypeId();
        for(integer i=0;i<numberOfSA;i++){
            Unit__c unit = TestDataHelper.createUnit(false);
            unit.RecordTypeId = houseHoldRecordType;
            unit.Unit_of_Interest_ID__c ='EN' + i;
            unit.Address_Type__c = null;
            unit.Other_Address_Type__c = null;
			unit.PSU_Number__c = String.valueOf(i + 1);
			unit.DP_ID__c='100' + i;
            unit.Rural_Delivery_Number__c = null;
            unit.Postcode__c = '1234';
            unit.P_O_Box__c = null;
            units.add(unit);
        }
        insert units;
        dniSAs = new List<Special_Arrangement__c>();
        Id saRecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
        for(integer i=0;i<numberOfSA;i++){
			Special_Arrangement__c dniSA = new Special_Arrangement__c(	RecordTypeId = saRecordTypeId,
																		Collection__c = collection.Id, 
																		DNI_Suppression_Approval__c = 'Pending',
																		Survey_Unit__c = units[i].Id, 
																		Suppression_Type__c = 'Do Not Interview',
																		Rule_Start_Date__c = system.today(),
																		Rule_End_Date__c=null);	
			dniSAs.add(dniSA);
        }
			
    }
    
    @isTest static void testApprovalSubmit(){
    	setup(3);
		test.startTest();
		insert dniSAs;
		test.stopTest();   
		list<Special_Arrangement__c> sas = new list<Special_Arrangement__c>([select id from Special_Arrangement__c where id IN : (new Map<Id,Special_Arrangement__c>(dniSAs)).keySet() ]);
		for(Special_Arrangement__c sa: sas){
			System.assertEquals(true, Approval.isLocked(sa.Id));
		}
    }
}