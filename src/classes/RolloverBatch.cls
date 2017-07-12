/* 
 * Author:      FRONDE - stefania.ezquerra@fronde.com
 * Description: Called by Controller for RolloverResponses page. Clones the responses resulting from the query, except the ones with Units inclueded on list "existingDwellings".
 * Test:        Test classes are included in RolloverResponsesControllerTest.
 * History:     07.Jun.2016 - Created.
 *              10.Jun.2016 - Added Suppression - DNI logic. If there is an active Special Arrangement, then the cloned response will have a Suppressed status.
 *              15.Jun.2016 - Added Rollover WorkItem Logic. Clone Interview workitem related to the cloned response. If it doesn't exist (like in case of a suppression 
 *                            that is now inactive) create it. 
 *              16.Jun.2016 - Rollover automation: Added logic to call the Scheduler. 
 *              20.Jun.2016 - Workload Rollover / Creation . WL is unique with key: Type / CollectionInstance / Area_Unit_Reference
 *              24.Jun.2016 - Added Field Sets to be able to control the fields been cloned.
 *              27.Jun.2016 - 75+ suppression logic, CATI - CAPI logic
 *              12.07.2016  - Contact Role rollover.
 */
 
global class RolloverBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global final string query;
    global Collection_Instance__c ci;
    private String errors = '';
    public set<Id> unitsToExclude;  
    public Integer wave;
    public Boolean isManualProcess;
    public Id priorCI; 
    public Boolean testError = false; // error testing
    
    global RolloverBatch(Id priorCI, Id collectionInstanceId, Set<Id> existingDwellings, Integer waveNumber, Boolean manualProcess){
        this.ci = [select Collection__c, Current_Wave__c, Collection_Period__c from Collection_Instance__c where id = : collectionInstanceId];
        this.priorCI = priorCI;
        this.isManualProcess = manualProcess;
        this.unitsToExclude = existingDwellings;
        this.wave = waveNumber;
        
        // Build query
        Id dwellingRecordType = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
        list<Schema.FieldSetMember> responseFieldSet = Schema.SObjectType.Response__c.fieldSets.getMap().get('Response_Rollover_Fields').getFields();
        set<String> fieldsToInclude = new set<String>();   
        for (FieldSetMember f : responseFieldSet) fieldsToInclude.add(f.getFieldPath());
        this.query='select '+ String.join(new List<String>(fieldsToInclude), ',') + ', Unit_of_Interest__r.PSU_Number__c, Unit_of_Interest__r.PSU_Name__c from Response__c '
                            + 'where Rotation_Number_Value__c <= 7'
                            + 'and RecordTypeId = \'' + dwellingRecordType + '\''
                            + 'and Week__c = ' + wave 
                            + 'and Collection_Instance__c = \'' + priorCI + '\'' ;
        // Jun.2016: Not filtering existing responses on the queryString because the Characters limit for a soql query is 20.000. It can easily be reached if the list is not Binded (like the next query.)
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    } 

    global void execute(Database.BatchableContext BC, List<Response__c> scope) {
        // Do Clone.
        system.debug('## Excecute rollover batch for CI: ' + ci); 

        map<Id,Response__c> responseIdMap = new map<Id,Response__c>(scope);                                 // Map to get Scope Ids, to query related workitems.
        map<Id,Work_Item__c> workItemByUnitMap = new map<Id,Work_Item__c>();                                // Map containing workitems per related unit id, for workitem clone, to match to the right response.
        map<Id,Response__c> responseByUnitMap = new map<Id,Response__c>();                                  // Map containing responses by related unit Id, to query Special Arrangements.
        map<Id,Special_Arrangement__c> specialArrangementByUnitMap = new map<Id,Special_Arrangement__c>();  // Map with Special Arrangements by Unit Id, to match it to the responses.
        map<String,Workload__c> workloadByPSUmap = new map<String,Workload__c>();                           // Map of workloads by PSU, only keep the most recent one. 
        map<Id,String> UnitPSUmap = new map<Id,String>();                                                   // All PSU codes related to the responses --> units on the scope.
        map<String,String> pSUmap = new map<String,String>();                                               // PSU codes with their names.
        list<Response__c> responsesToInsert = new list<Response__c>();
        map<String, Workload__c> workloadsToInsert = new map<String, Workload__c>();                                        
        list<Work_Item__c> workItemsToInsert = new list<Work_Item__c>();

        // Query WorkItems - assume one Interview WI per response. Max number of rows is determined by the scope size.
        list<Schema.FieldSetMember> workItemFieldSet = Schema.SObjectType.Work_Item__c.fieldSets.getMap().get('WorkItem_Rollover_Fields').getFields();
        set<String> fieldsToInclude = new set<String>();   
        for (FieldSetMember f : workItemFieldSet) fieldsToInclude.add(f.getFieldPath());
        set<Id> responseIds = responseIdMap.keySet();
        String wiQuery= 'select '+ String.join(new List<String>(fieldsToInclude), ',') + ', Response__r.Unit_of_Interest__c ' +
                        'from Work_Item__c where Work_Item_Type__c = \'Interview\' and Response__c IN : responseIds';
        list<Work_Item__c> workItems = Database.query(wiQuery);
        
        for(Work_Item__c wi : workItems){
            workItemByUnitMap.put(wi.Response__r.Unit_of_Interest__c, wi);
        }
        
        // Query Existing Workloads on current CI. There will be a maximum of around 1700 worloads for type interview.
        list<Workload__c> workloads = new list<Workload__c>([   select  Workload_Status__c, Workload_Priority_Indicator__c, Units_Of_Interest_Report_Household__c, Supervisor__c, 
                                                                        Supervisor_Check_Sign_off__c, Status_Flag__c, Restrict_Hierarchy__c, Owner_Name__c, OwnerId, Name, Default_Delivery_Mode__c, 
                                                                        Default_Address_Type__c, Collection_Instance__c, Area_Unit_Reference__c, Area_Unit_Name__c 
                                                                from Workload__c
                                                                where Collection_Instance__c IN : new set<id> { priorCI,ci.Id }
                                                                and Workload_Type__c = 'Interview'
                                                                order by Collection_Instance__r.Planned_Start_Date__c]);    // we are keeping only the most recent workload.
        for(Workload__c wl : workloads){
            workloadByPSUmap.put(wl.Area_Unit_Reference__c, wl);
        }

        // Create structure to query Units Special Arrangements and meanwhile, filter duplicates.
        for(Response__c r : scope){
            // Using collection unit lookup field to do the mapping, should be the same as survey Unit.
            if(!unitsToExclude.contains(r.Unit_of_Interest__c)){
                responseByUnitMap.put(r.Unit_of_Interest__c, r);
                UnitPSUmap.put(r.Unit_of_Interest__c, r.Unit_of_Interest__r.PSU_Number__c);
                pSUmap.put(r.Unit_of_Interest__r.PSU_Number__c, r.Unit_of_Interest__r.PSU_Name__c);
            }
        }
         
        // Query Suppression Special Arrangements - Asume only one active per unit per collection. If 1 DNI and 1 75+ active at the same time, keep DNI as it's always suppressed.
        Id suppressionSARecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
        list<Special_Arrangement__c> saList = new list<Special_Arrangement__c>([ select Suppression_Type__c, Survey_Unit__c,  Collection__c, Status__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, 
                                                                                        Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c   
                                                                                 from Special_Arrangement__c 
                                                                                 where Survey_Unit__c IN : responseByUnitMap.keySet() 
                                                                                 and Collection__c =: ci.Collection__c 
                                                                                 and RecordTypeId = : suppressionSARecordTypeId
                                                                                 and Suppression_Type__c IN ('Do Not Interview','75+')
                                                                                 and Status__c = 'Active'
                                                                                 order by Suppression_Type__c]); 
        for(Special_Arrangement__c sa : saList){
            specialArrangementByUnitMap.put(sa.Survey_Unit__c,sa);
        }        
        
        // Query Exsisting Contact Roles. 
        list<Contact_Role__c> contactRoles = new list<Contact_Role__c>([select Role__c
                                                                        from Contact_Role__c
                                                                        where Role__c = 'Respondent'
                                                                        and Unit_of_Interest_ID__c IN : responseByUnitMap.keySet()
                                                                        and Collection__c =: ci.Collection__c]);
        /*PROCESSING*/ 
        for(Contact_Role__c c: contactRoles){
            c.Role__c = 'Occupant'; // Set contact roles to Occupant.
        }
        
        for(Response__c r : responseByUnitMap.values()){                            // ResponseByUnitMap is the scope already filtered to avoid duplicates.
            Response__c newResponse = cloneResponse(r,specialArrangementByUnitMap);
            responsesToInsert.add(newResponse);
        }
                 
        if(responsesToInsert.isEmpty()){return;} // Go to finish method.
        Savepoint sp;
        try{
            //Save point to revert all the inserts if any insert fails
            sp = Database.setSavepoint();
            insert responsesToInsert;
            update contactRoles; 
            // After Responses Insertion was successfull, create / clone the necessary Workloads.
            workloadsToInsert = createOrCloneWorkload(responsesToInsert, UnitPSUmap, pSUmap, workloadByPSUmap);
            if(!workloadsToInsert.isEmpty()){   
                insert workloadsToInsert.values();  
                workloadByPSUmap.putAll(workloadsToInsert);         // This will overwrite the old PSU key,value and will replace it with the newly created one, keeping the existing workloads for this CI. 
            }
            
            // After Responses and WorkLoad Insertion was successfull, clone WorkItems. Use workItemByUnitMap.
            for(Response__c r: responsesToInsert){
                if(r.Status__c == 'Suppressed') {continue;} // Suppressed responses don't get WorkItems.
                String correspondingPSU = UnitPSUmap.get(r.Unit_of_Interest__c);
                Work_Item__c newWI;
                system.debug('## workloadByPSUmap final: ' + workloadByPSUmap);
                system.debug('## workItemByUnitMap final: ' + workItemByUnitMap);
                if(workItemByUnitMap.containsKey(r.Unit_of_Interest__c)){
                    newWI = workItemByUnitMap.get(r.Unit_of_Interest__c).clone(false, true, false , false);
                    newWI.Status__c = 'New';
                    newWI.Response__c = r.Id;
                    newWI.Workload__c = workloadByPSUmap.get(correspondingPSU).Id;
                    newWI.OwnerId = workloadByPSUmap.get(correspondingPSU).OwnerId;
                    newWI.RecordTypeId = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
                }else{
                    // If the work item doesn't exist and the response status is loaded, create it. 
                    // Eg: The response was a suppression last quarter and now it's active again.
                    // The fields values are TBD. 15.Jun.2016
                    newWI =new Work_Item__c(Status__c = 'New', 
                                            Response__c = r.Id, 
                                            Work_Item_Type__c = 'Interview',
                                            Workload__c  = workloadByPSUmap.get(correspondingPSU).Id,
                                            OwnerId = workloadByPSUmap.get(correspondingPSU).OwnerId,
                                            RecordTypeId = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get('Social').getRecordTypeId()
                                            //Delivery_Mode__c,Description__c, Origin__c, 
                                            );
                }
                workItemsToInsert.add(newWI);
            } 
            if(!workItemsToInsert.isEmpty()){ insert workItemsToInsert; }
        } catch(exception e){
            //Roll back all the inserts if failed
            database.rollback(sp);
            // Update errors
            errors += '\n ' + e;
        }
    }     
    
    private Response__c cloneResponse(Response__c r, map<Id,Special_Arrangement__c> specialArrangementByUnitMap){
        Response__c newResponse = r.clone(false, true, false , false);
        newResponse.Collection_Instance__c = ci.Id;
        newResponse.Responded_By__c = null;
        newResponse.Contact__c = r.Responded_By__c;
        newResponse.Response_Status_Reason__c = null;
        newResponse.Rotation__c = string.valueof(r.Rotation_Number_Value__c + 1).substringBefore('.');
        newResponse.Status__c = 'Loaded';
        // CATI turns CAPI if 2 consecutive "No Response"
        if(r.Status__c == 'No Response' && r.Collection_Mode__c == 'CATI'){
            if(r.CATI_No_Response_Counter__c == 0){
                // Record first time CATI no response
                newResponse.CATI_No_Response_Counter__c = 1;
            }else{
                // Second time CATI no response
                newResponse.Collection_Mode__c = 'CAPI';
                newResponse.CATI_No_Response_Counter__c = 0;
            } 
        }
        if(r.Status__c != 'No Response' && r.Collection_Mode__c == 'CATI'){ // CODE REVIEW: IT"S ONLY NO RESPONSE THE STATUS WE CHECK?
            r.CATI_No_Response_Counter__c = 0; // clear counter as it only counts if it's 2 times in a row.
        }
        // CAPI - CATI
        if(r.CATI_Indicator__c == true && r.Collection_Mode__c == 'CAPI'){
            newResponse.Collection_Mode__c = 'CATI';
            newResponse.CATI_Indicator__c = false;
        }
        // Suppression logic
        newResponse.Special_Arrangement__c = null;                                                              //asume there is no SA. CODE REVIEW: it seems right to clear this field if there is no active SA.
        String monthString = getMonthStringForSpecialArrangement(ci.Collection_Period__c);
        if(specialArrangementByUnitMap.containsKey(r.Unit_of_Interest__c)){
            Special_Arrangement__c sa = specialArrangementByUnitMap.get(r.Unit_of_Interest__c);
            if( sa.Suppression_Type__c == 'Do Not Interview' || (sa.Suppression_Type__c == '75+' && sa.get(monthString) == true && r.Status__c != 'No Response')){
                newResponse.Special_Arrangement__c = specialArrangementByUnitMap.get(r.Unit_of_Interest__c).Id;
                newResponse.Status__c = 'Suppressed';
                newResponse.Response_Status_Reason__c = specialArrangementByUnitMap.get(r.Unit_of_Interest__c).Suppression_Type__c;
            }       
        }
        
        return newResponse;
    }
            
    private map<String, Workload__c> createOrCloneWorkload(list<Response__c> responsesToInsert, map<Id,String> UnitPSUmap, map<String,String> pSUmap, map<String,Workload__c> workloadByPSUmap){
        map<String, Workload__c> wlToInsert = new map<String, Workload__c>();
        Id ownerId;
        try{
            Group owner = [select Id from Group where Name = 'Unassigned Work' and Type = 'Queue' LIMIT 1];
            ownerId = owner.Id; 
        }catch(exception e){
            system.debug('## UNASSIGNED WORK QUEUE IS MISSING: ' + e);
            ownerId = userInfo.getUserId();
        }
        for(String psu : UnitPSUmap.values()){
            system.debug('## workloadByPSUmap: ' + workloadByPSUmap); 
            if(workloadByPSUmap.containsKey(psu)){
                system.debug('## workloadByPSUmap.get(psu)' + workloadByPSUmap.get(psu));
                // The WL exists. If it's from previous CI, clone it.
                 if(workloadByPSUmap.get(psu).Collection_Instance__c != ci.Id){
                     Workload__c wl = workloadByPSUmap.get(psu).clone(false,true,false,false); 
                     wl.Workload_Status__c = 'Not Started';
                     wl.Collection_Instance__c = ci.Id;
                     wlToInsert.put(wl.Area_Unit_Reference__c,wl);
                     continue;
                 }
            }else if(!wlToInsert.containsKey(psu)){ // Units can have same PSU, only one WL per PSU is created.
                // Create the WL.
                Workload__c wl = new Workload__c(Workload_Status__c = 'Not Started', Workload_Type__c = 'Interview', OwnerId = ownerId, Collection_Instance__c = ci.Id, Area_Unit_Reference__c = psu, Area_Unit_Name__c = pSUmap.get(psu) ); 
                wlToInsert.put(wl.Area_Unit_Reference__c,wl);
            }
        }
        return wlToInsert;
    }
    
    private String getMonthStringForSpecialArrangement(String ciMonth){
        String monthNumber = 'Month_3__c'; // Default to March
        if(ciMonth == 'June'){
            return 'Month_6__c';
        }else if(ciMonth == 'September'){
            return 'Month_9__c';
        }else if(ciMonth == 'December'){
             return 'Month_12__c';
        }
        return monthNumber;
    }
    
    global void finish(Database.BatchableContext BC) {
        Collection_Instance__c collectionInstance = [select Rollover_Status__c, Rollover_Error__c, Collection_Instance_Code__c  from Collection_Instance__c where id = : ci.Id];
        if(isManualProcess){
            if(errors != ''){ 
                // LOG ERROR ON ERROR LOG OBJECT
                Error_Log__c eL = new Error_Log__c(Exception_Message__c = errors, Process_Name__c = 'RolloverBatch, RolloverResponses page.' , Record_Id__c = collectionInstance.Id, User__c = userInfo.getUserId() );
                insert eL;
                collectionInstance.Rollover_Error__c = errors;
                collectionInstance.Rollover_Status__c = 'Partial Error';
            }else {
                collectionInstance.Rollover_Status__c = 'Completed';
                collectionInstance.Rollover_Error__c = null;
            }
            update collectionInstance; 
        }else{
            // SCHEDULER. If job completed, then clear CI for next wave processing. If error for the second time, send email and log error. Clear CI. If not, reschedule.
            if(errors != '' || (Test.isRunningTest() && testError)){ 
                if(collectionInstance.Rollover_Status__c != 'Partial Error'){
                    // First time error.
                    collectionInstance.Rollover_Error__c = errors;
                    collectionInstance.Rollover_Status__c = 'Partial Error';
                    update collectionInstance;
                    // RESCHEDULE
                    RolloverBatchScheduler rs = new RolloverBatchScheduler(); 
                    Datetime dt = Datetime.now().addMinutes(30);
                    String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                    System.Schedule('RolloverBatchSchedulerRetry',timeForScheduler,rs); 
                    return;                                 
                }else{
                    // SEND EMAIL TO ADMIN WITH ERROR
                    SystemSettings__c notificationEmail = SystemSettings__c.getInstance('rolloverBatch.notificationEmail');
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.toAddresses = new String[] { notificationEmail.Value__c };
                    message.subject = 'Rollover Batch Process Scheduler Failed';
                    message.plainTextBody = 'There was an error during the rollover process. The wave number that failed was: ' + wave  
                        + '.\nThe error was logged on the Error Log object and is as follow: \n '
                        + errors
                        + '\n\nCollection Instance Id: '+ collectionInstance.Id
                        + '\n\nCollection Instance Code: '+ collectionInstance.Collection_Instance_Code__c;
                    Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

                    //LOG ERROR
                    Error_Log__c eL = new Error_Log__c(Exception_Message__c = errors, Process_Name__c = 'RolloverBatch, Rollover Scheduler.' , Record_Id__c = collectionInstance.Id, User__c = userInfo.getUserId() );
                    insert eL;
                }
            }
            // Clear values for success and for second time failures.
            collectionInstance.Rollover_Status__c = null;
            collectionInstance.Rollover_Error__c = null;
            update collectionInstance; 
        }
    }
}