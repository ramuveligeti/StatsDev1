/* Author: FRONDE. 
 * History: Jun.2016	Created
 *			21.Jun.2016	Change: Only process one CI, the current CI at this point of time. 
 *			27.Jun.2016 Change: Added the Collection_Number to the query CI logic. 
 * Unit tests are included in class: RolloverResponsesControllerTest.
 */
global class RolloverBatchScheduler implements Schedulable{
	
	global static void startRolloverSchedule(String name, Datetime schedule) {
        //Start from developer console. 
        RolloverBatchScheduler rs = new RolloverBatchScheduler();
        String timeForScheduler = schedule.format('s m H d M \'?\' yyyy');
        System.schedule(name, timeForScheduler, rs);        
    }
	
	global void execute(SchedulableContext SC) {
		runRolloverBatch();   
	}

	public void runRolloverBatch(){
		if([select count() from AsyncApexJob where JobType='BatchApex' and (Status = 'Processing' or Status = 'Preparing')] < 5){
			list<Collection_Instance__c> ciList = new list<Collection_Instance__c>([select Collection__c, Collection_Number__c, Current_Wave__c, Planned_Start_Date__c, RecordTypeId 
																					from Collection_Instance__c 
																					where Collection__r.Type__c = 'HLFS'
																					and Collection__r.RecordTypeId =: Schema.SObjectType.Collection__c.getRecordTypeInfosByName().get('Social').getRecordTypeId()
																					//and Status__c = 'Active'
																					and Planned_Start_Date__c <= : system.Today()
																					and (Rollover_Status__c = null or Rollover_Status__c = 'Partial Error')
																					order by Planned_Start_Date__c desc LIMIT 1]);	
			if(ciList.isEmpty()){
				return; // End processing.
			}else{
				Id dwellingRecordType = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
				Collection_Instance__c currentCI = ciList[0];
				Collection_Instance__c cloneFromCI;
				Collection_Instance__c cloneToCI;
				Decimal wave;
				// Rollover 9 weeks in advance. When changing this, be aware that it could generate gaps between weeks. 
				Integer rolloverPeriod = 9;
				try{																		
					// Get CI to clone from. 
					if(currentCI.Current_Wave__c <= (13 - rolloverPeriod)){
						wave = currentCI.Current_Wave__c + rolloverPeriod;
						system.debug('## The CI to get the responses from is the prior CI. Wave : ' + wave);
						cloneToCI = currentCI;
						cloneFromCI=[ select Planned_Start_Date__c  
									  from Collection_Instance__c
									  where Planned_Start_Date__c <: cloneToCI.Planned_Start_Date__c
									  and RecordTypeId =: cloneToCI.RecordTypeId 
									  and Collection__c =: cloneToCI.Collection__c
									  and Collection_Number__c =: (cloneToCI.Collection_Number__c - 1) LIMIT 1];
					}else{
						wave = currentCI.Current_Wave__c + rolloverPeriod - 13;
						system.debug('## The CI to get the responses from is the current CI. Wave : ' + wave);
						cloneFromCI = currentCI;
						cloneToCI = [ select Planned_Start_Date__c  
									  from Collection_Instance__c
									  where Planned_Start_Date__c >: cloneFromCI.Planned_Start_Date__c
									  and RecordTypeId =: cloneFromCI.RecordTypeId 
									  and Collection__c =: cloneFromCI.Collection__c 
									  and Collection_Number__c =: (cloneFromCI.Collection_Number__c + 1) LIMIT 1];
					}
				} catch(exception e){
					system.debug('## No previous CI or Next CI to process rollover from/to');
					return; // End processing. 
				}	
					
				// Assuming there will be less than 50001 records.
				List<Response__c> existingResponses = new List<Response__c>([select Unit_of_Interest__c, RecordTypeId 
																			 from Response__c 
																			 where Collection_Instance__c =: cloneToCI.Id
																			 and Week__c =: wave
																			 and RecordTypeId =: dwellingRecordType]);			
				// List existing Responses to Avoid duplicates. 
				Set<Id> exitingUnitsOfInterestForDwellings = new Set<Id>();
				for(Response__c r: existingResponses){
					exitingUnitsOfInterestForDwellings.add(r.Unit_of_Interest__c); 
				}
				system.debug('## exitingUnitsOfInterestForDwellings: ' + exitingUnitsOfInterestForDwellings);
				// RUN BATCH
				Database.executeBatch(new RolloverBatch(cloneFromCI.Id,cloneToCI.Id,exitingUnitsOfInterestForDwellings,wave.intValue(),false), 2000); 
			}
		}else{
			//schedule again in 5 mins
			RolloverBatchScheduler rs = new RolloverBatchScheduler();
			Datetime dt = Datetime.now().addMinutes(5);
			String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
			Id schedId = System.Schedule('RolloverBatchScheduler',timeForScheduler,rs);
		}
	}
}