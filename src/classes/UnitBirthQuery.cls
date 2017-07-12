public class UnitBirthQuery {
	private static Id businessResponseRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
	private static Collection_Instance__c currentCollectionInstance;
	private static List<Collection_Instance__c> previousFiveCollectionInstances;
	
	// Intend to be used in before trigger
	public static void MarkReponsesAsBirthed(List<Response__c> responses) {
		if(responses!=null && !responses.isEmpty()){
			Set<Id> unitIds = new Set<Id>();
			List<Response__c> businessResponses = new List<Response__c>();
			for (Response__c response:responses) {
				if (response.RecordTypeId==businessResponseRecordTypeId) {
					businessResponses.add(response);
				}
				if(String.isNotBlank(response.Unit_of_Interest__c)){
					unitIds.add(response.Unit_of_Interest__c);
				}
			}
			System.debug('unitIds = '+unitIds);

			if(!businessResponses.isEmpty()){
				if(currentCollectionInstance==null){
					currentCollectionInstance = [select Collection__c, Collection__r.collection_code__c, Planned_Start_Date__c from Collection_Instance__c 
						where Id = :businessResponses[0].Collection_Instance__c
					];
				}
				if(previousFiveCollectionInstances==null){
					integer prevCount = 'AES'.equalsIgnoreCase(currentCollectionInstance.Collection__r.collection_code__c) ? 15 : 5;
					
					previousFiveCollectionInstances = [select Id from Collection_Instance__c 
						where 
							Collection__c = :currentCollectionInstance.Collection__c and 
							Id != :currentCollectionInstance.Id and
							Planned_Start_Date__c < :currentCollectionInstance.Planned_Start_Date__c
						order by Planned_Start_Date__c desc limit :prevCount
					];
				}

				List<AggregateResult> ars = [select Unit_of_Interest__c, count(Id)
					from Response__c 
					where 
						Unit_of_Interest__c != null and
						Unit_of_Interest__c in :unitIds and
						Collection_Instance__c in :previousFiveCollectionInstances
					Group By Unit_of_Interest__c Having count(Id)>0
				];

				Set<Id> existingUnitIds = new Set<Id>();
				for(AggregateResult ar:ars){
					existingUnitIds.add((Id)ar.get('Unit_of_Interest__c'));
				}


				for (Response__c response:businessResponses) {
					response.Birth__c = ((response.Unit_of_Interest__c!=null && !existingUnitIds.contains(response.Unit_of_Interest__c))
						|| (response.Survey_Unit__c!=null && !existingUnitIds.contains(response.Survey_Unit__c)));
				}
			}
		}
	}
}