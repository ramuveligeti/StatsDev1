//This class contains a lagrge number of lines. However it is better to keep its all in one place 
//for the reason of supporting multiple versions of the webservice intefface.

@RestResource(urlMapping='/SyncMobile/2.0/*')
global class SyncMobileApi_v2_0 {
    private static final String REFERENCE_ERROR_REGEX_PATTERN = 'Foreign key external ID: .{3,} not found for field .{1,}';
    private static final String REFERENCE_ERROR_TEXT = 'reference-error';
    private static final String ERROR_LOG_PROCESS_NAME = 'Mobile Sync';
    private static final String DNI_TEMP = 'Do Not Interview - Temporary';
    private static final String DNI_PERM = 'Do Not Interview - Permanent';


     //id map for the records <mobile database id, saleforce id>
    @TestVisible private static Map<Long, Id> unitIdMap = new Map<Long, Id>();
    @TestVisible private static Map<Long, Id> responseIdMap = new Map<Long, Id>();
    @TestVisible private static Map<Long, Id> workitemIdMap = new Map<Long, Id>();
    @TestVisible private static Map<Long, Id> contactIdMap = new Map<Long, Id>();

    @TestVisible private static Map<String, Unit__c> errorUnits = new Map<String, Unit__c>();
    @TestVisible private static Map<String, Response__c> errorResponses = new Map<String, Response__c>();
    @TestVisible private static Map<String, Work_Item__c> errorWorkitems = new Map<String, Work_Item__c>();
    @TestVisible private static Map<String, Task> errorTasks = new Map<String, Task>();
    @TestVisible private static Map<String, Contact> errorContacts = new Map<String, Contact>();
    @TestVisible private static Map<String, Contact_Role__c> errorContactRoles = new Map<String, Contact_Role__c>();
    @TestVisible private static Map<String, Event> errorEvents = new Map<String, Event>();

    @TestVisible private static Map<String, Integer> errorSummary = new Map<String, Integer>();

    @TestVisible private static String mobileDeviceId;
    @TestVisible private static Integer mobileDeviceVersionCode;
    @TestVisible private static String mobileDeviceVersionName;

    @TestVisible private static Map<String, SystemSettings__c> systemSettings;

    //@future
    private static void createErrorLog(String msg){
        Error_Log__c errorLog = new Error_Log__c();
        errorLog.Process_Name__c = ERROR_LOG_PROCESS_NAME;
        errorLog.User__c = UserInfo.getUserId();

        System.debug('Mobile Device Version Code: '+mobileDeviceVersionCode);
        System.debug('Mobile Device Version Name: '+mobileDeviceVersionName);
        
        errorLog.Exception_Message__c = '';
        if(mobileDeviceVersionCode!=null){
            errorLog.Exception_Message__c += 'Mobile Device Version Code: '+mobileDeviceVersionCode+'\n';
        }
        if(String.isNotBlank(mobileDeviceVersionName)){
            errorLog.Exception_Message__c += 'Mobile Device Version Name: '+mobileDeviceVersionName+'\n';
        }
        errorLog.Exception_Message__c += msg;

        insert errorLog;
    }

    private static String buildExceptionErrorMessage(String msg, Exception e){
        String errorMsg = '';
        if(e!=null){
            if(String.isNotBlank(msg)){
                errorMsg += msg;
                errorMsg += '\n';
            }
            errorMsg += e.getTypeName()+': '+e.getMessage()+buildExceptionErrorMessage(errorMsg, e.getCause());
        }
        return errorMsg;
    }
    
    @HttpPost
    global static void sync() {
        try{
            systemSettings = SystemSettings__c.getall();
            if(systemSettings==null){
                systemSettings = new Map<String, SystemSettings__c>();
            }
        }catch(Exception e){
            //system setting not found.
            systemSettings = new Map<String, SystemSettings__c>();
        }

        try{
            System.debug(LoggingLevel.INFO,'sync started');
            System.debug(LoggingLevel.INFO,'heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
            
            if(RestContext.request.requestBody != null){
                processRequest(RestContext.request.requestBody.toString());
            }
            System.debug('RestContext.request.requestBody.toString()'+RestContext.request.requestBody.toString());
            System.debug(LoggingLevel.INFO,'completed processing request. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());

            ResponseContainer responseContainer = generateResponseContainer();
            String responseBody = responseContainer.toJson();
            System.debug('responseBody = '+responseBody);
            System.debug(LoggingLevel.INFO,'generated response json. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
            RestContext.response.headers.put('Content-Type', 'application/json');
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(responseBody);
            System.debug(LoggingLevel.INFO,'completed processing response. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());
            
            //if there are errroed items than create error log.
            processErrors();
        }catch(Exception e){
            String errorMsg = buildExceptionErrorMessage(null, e);
            createErrorLog(errorMsg);

            RestContext.response.responseBody = Blob.valueOf(errorMsg);
            RestContext.response.statusCode = 400;
        }
    }

    private static void processErrors(){
        if(errorSummary!=null && !errorSummary.isEmpty()){
            String errorMessage = '';
            for(String key:errorSummary.keySet()){
                errorMessage += key+' '+errorSummary.get(key)+' errors\n';
            }
            createErrorLog(errorMessage);
        }
    }

    @TestVisible
    private static void processRequest(String requestBody){
        System.debug('process request started, requestBody = '+requestBody);
        if(String.isNotBlank(requestBody)){

            RequestContainer requestContainer = (RequestContainer)JSON.deserialize(requestBody, SyncMobileApi_v2_0.RequestContainer.class);
            System.debug('requestContainer = '+requestContainer);
            if(requestContainer!=null){
                mobileDeviceId = requestContainer.deviceId;

                processUser(requestContainer);

                resetExistingMobileDeviceIds(requestContainer);

                processRequestUnits(requestContainer);
                processRequestResponses(requestContainer);
                processRequestWorkitems(requestContainer);
                processRequestTasks(requestContainer);
                processRequestContacts(requestContainer);
                processRequestContactRoles(requestContainer);
                processRequestEvents(requestContainer);
            }
        }
    }

    private static void processUser(RequestContainer requestContainer){
        if(requestContainer.versionCode!=null){
            mobileDeviceVersionCode = requestContainer.versionCode;
            mobileDeviceVersionName = requestContainer.versionName;

            User user = [select 
                    Mobile_App_Version_Code__c, 
                    Mobile_App_Version_Name__c, 
                    Mobile_App_Version_Date__c, 
                    Last_Mobile_Sync__c 
                from User where Id=:UserInfo.getUserId()
            ];
            if(requestContainer.versionName != user.Mobile_App_Version_Name__c){
                user.Mobile_App_Version_Code__c = requestContainer.versionCode;
                user.Mobile_App_Version_Name__c = requestContainer.versionName;
                user.Mobile_App_Version_Date__c = DateTime.now();
            }
            user.Last_Mobile_Sync__c = DateTime.now();
            update user;
        }
    }

    //clear mobile device ids from the existing records to avoid duplication
    //duplication can/will occurr when id counter on the device is reset.
    //this can be cased by user logging out
    private static void resetExistingMobileDeviceIds(RequestContainer requestContainer){
        Set<String> unitMobileIds = new Set<String>();
        List<Unit__c> sfUnits = requestContainer.getSfUnits();
        if(requestContainer.units!=null && !requestContainer.units.isEmpty()){
            for(Unit unit:requestContainer.units){
                if(unit.mId!=null){
                    unitMobileIds.add(generateExtId(unit.mId));
                }
            }
            
            List<Unit__c> units = [select Mobile_Device_Id__c from Unit__c where Mobile_Device_Id__c in :unitMobileIds];
            clearMobileDeviceIds(units);
        }
        
        Set<String> responseMobileIds = new Set<String>();
        if(requestContainer.responses!=null && !requestContainer.responses.isEmpty()){
            for(Response response:requestContainer.responses){
                responseMobileIds.add(generateExtId(response.mId));
            }
            
            List<Response__c> responses = [select Mobile_Device_Id__c from Response__c where Mobile_Device_Id__c in :responseMobileIds];
            clearMobileDeviceIds(responses);  
        }
        
        Set<String> workitemMobileIds = new Set<String>();
        if(requestContainer.workitems!=null && !requestContainer.workitems.isEmpty()){
            for(Workitem workitem:requestContainer.workitems){
                workitemMobileIds.add(generateExtId(workitem.mId));
            }

            List<Work_Item__c> workitems = [select Id, Mobile_Device_Id__c, Response__c, Response__r.Unit_of_Interest__c from Work_Item__c where Mobile_Device_Id__c in :workitemMobileIds];
            clearMobileDeviceIds(workitems);  
        }
        
        Set<String> contactMobileIds = new Set<String>();
        if(requestContainer.contacts!=null && !requestContainer.contacts.isEmpty()){
            for(ContactPerson cont:requestContainer.contacts){
                contactMobileIds.add(generateExtId(cont.mId));
            }

            List<Contact> contacts = [select Mobile_Device_Id__c from Contact where Mobile_Device_Id__c in :contactMobileIds];
            clearMobileDeviceIds(contacts);  
        }
        
        Set<String> contactRoleMobileIds = new Set<String>();
        if(requestContainer.contactRoles!=null && !requestContainer.contactRoles.isEmpty()){
            for(ContactRole contR:requestContainer.contactRoles){
                contactRoleMobileIds.add(generateExtId(contR.mId));
            }

            List<Contact_Role__c> contactRoles = [select Mobile_Device_Id__c from Contact_Role__c where Mobile_Device_Id__c in :contactRoleMobileIds];
            clearMobileDeviceIds(contactRoles);  
        }
        
        Set<String> eventMobileIds = new Set<String>();
        if(requestContainer.events!=null && !requestContainer.events.isEmpty()){
            for(EventItem e:requestContainer.events){
                eventMobileIds.add(generateExtId(e.mId));
            }

            List<Event> events = [select Mobile_Device_Id__c from Event where Mobile_Device_Id__c in :eventMobileIds];
            clearMobileDeviceIds(events);  
        }
    }

    private static void clearMobileDeviceIds(List<SObject> objects){
        for(SObject o:objects){
            o.put('Mobile_Device_Id__c', null);
        }
        update objects;
    }

    @TestVisible
    private static void saveObjects(List<SObject> objects, String saveType){
        Database.DMLOptions options = new Database.DMLOptions();
        Database.SaveResult[] saveResults = null;
        if('insert'.equals(saveType)){
            saveResults = Database.insert(objects, options);
        }else if('update'.equals(saveType)){
            saveResults = Database.update(objects, options);
        }

        System.debug('save objects results: '+saveResults);
        for(integer i=0; i<saveResults.size(); i++){
            SObject obj = objects[i];
            if(saveResults[i].isSuccess()){
                if(obj instanceof Unit__c){
                    Unit__c unit = (Unit__c)obj;
                    if(unit.mId__c!=null){
                        unitIdMap.put(unit.mId__c.longValue(), unit.Id);
                    }
                }else if(obj instanceof Response__c){
                    Response__c response = (Response__c)obj;
                    if(response.mId__c!=null){
                        responseIdMap.put(response.mId__c.longValue(), response.Id);
                    }
                }else if(obj instanceof Work_Item__c){
                    Work_Item__c workitem = (Work_Item__c)obj;
                    if(workitem.mId__c!=null){
                        workItemIdMap.put(workitem.mId__c.longValue(), workitem.Id);
                    }
                }else if(obj instanceof Contact){
                    Contact contact = (Contact)obj;
                    if(contact.mId__c!=null){
                        contactIdMap.put(contact.mId__c.longValue(), contact.Id);
                    }
                }
            }else{
                String errorMessage = generateErrorMessage(saveResults[i].getErrors());

                if(Pattern.matches(REFERENCE_ERROR_REGEX_PATTERN, errorMessage)){
                    errorMessage = REFERENCE_ERROR_TEXT;
                }

                obj.put('Error_Message__c', errorMessage);
                if(obj instanceof Unit__c){
                    Unit__c unit = (Unit__c)obj;
                    if(unit.shell_mId__c!=null && unitIdMap.containsKey(unit.shell_mId__c.longValue())){
                        unit.Shell_Address__c = unitIdMap.get(unit.shell_mId__c.longValue());
                    }
                    if(unit.observed_mId__c!=null && unitIdMap.containsKey(unit.observed_mId__c.longValue())){
                        unit.Related_Observed_Address__c = unitIdMap.get(unit.observed_mId__c.longValue());
                    }
                    errorUnits.put((String)obj.get('Mobile_Device_Id__c'), (Unit__c)obj);
                }else if(obj instanceof Response__c){
                    Response__c response = (Response__c)obj;
                    if(response.uoi_mId__c!=null && unitIdMap.containsKey(response.uoi_mId__c.longValue())){
                        response.Unit_of_Interest__c = unitIdMap.get(response.uoi_mId__c.longValue());
                    }
                    errorResponses.put((String)obj.get('Mobile_Device_Id__c'), response);
                }else if(obj instanceof Work_Item__c){
                    Work_Item__c workitem = (Work_Item__c)obj;
                    if(workitem.resp_mId__c!=null && responseIdMap.containsKey(workitem.resp_mId__c.longValue())){
                        workitem.Response__c = responseIdMap.get(workitem.resp_mId__c.longValue());
                    }
                    errorWorkitems.put((String)obj.get('Mobile_Device_Id__c'), workitem);
                }else if(obj instanceof Task){
                    Task task = (Task)obj;
                    if(task.wi_mId__c!=null && workitemIdMap.containsKey(task.wi_mId__c.longValue())){
                        task.WhatId = workitemIdMap.get(task.wi_mId__c.longValue());
                    }
                    if(task.resp_mId__c!=null && responseIdMap.containsKey(task.resp_mId__c.longValue())){
                        task.Response__c = responseIdMap.get(task.resp_mId__c.longValue());
                    }
                    errorTasks.put((String)obj.get('Mobile_Device_Id__c'), task);
                }else if(obj instanceof Contact){
                    Contact contact = (Contact)obj;
                    errorContacts.put((String)obj.get('Mobile_Device_Id__c'), contact);
                }else if(obj instanceof Contact_Role__c){
                    Contact_Role__c contactRole = (Contact_Role__c)obj;
                    if(contactRole.cnt_mId__c!=null && contactIdMap.containsKey(contactRole.cnt_mId__c.longValue())){
                        contactRole.Contact__c = contactIdMap.get(contactRole.cnt_mId__c.longValue());
                    }
                    if(contactRole.uoi_mId__c!=null && unitIdMap.containsKey(contactRole.uoi_mId__c.longValue())){
                        contactRole.Unit_of_Interest_ID__c = unitIdMap.get(contactRole.uoi_mId__c.longValue());
                    }
                    errorContactRoles.put((String)obj.get('Mobile_Device_Id__c'), contactRole);
                }else if(obj instanceof Event){
                    Event event = (Event)obj;
                    if(event.wi_mId__c!=null && workitemIdMap.containsKey(event.wi_mId__c.longValue())){
                        event.WhatId = workitemIdMap.get(event.wi_mId__c.longValue());
                    }
                    if(event.resp_mId__c!=null && responseIdMap.containsKey(event.resp_mId__c.longValue())){
                        event.Response__c = responseIdMap.get(event.resp_mId__c.longValue());
                    }
                    errorEvents.put((String)obj.get('Mobile_Device_Id__c'), event);
                }
            }
        }
    }

    private static String generateErrorMessage(List<Database.Error> errors){
        String errorMessage = '';
        for(Database.Error error:errors){
            errorMessage += error.getMessage()+' ';
            updateErrorSummary(String.valueOf(error.getStatusCode()));
        }
        return errorMessage;
    }

    private static void updateErrorSummary(String errorIdentifier){
        Integer count = errorSummary.get(errorIdentifier);
        if(count==null){
            count = 0;
        }
        errorSummary.put(errorIdentifier, count+1);
    }

    @TestVisible
    private static void processRequestUnits(RequestContainer requestContainer){
        if(requestContainer.units != null && !requestContainer.units.isEmpty()){
            System.debug('processRequestUnits started');

            Set<Id> unitids = new Set<Id>();
            for(Unit unit:requestContainer.units){
                unitids.add(unit.id);
            }
            Map<Id, Unit__c> existingUnits = new Map<Id, Unit__c>([select Version__c from Unit__c where Id in :unitIds]);

            List<Unit__c> insertUnitList_1 = new List<Unit__c>();
            List<Unit__c> insertUnitList_2 = new List<Unit__c>();
            List<Unit__c> updateUnitList_1 = new List<Unit__c>();
            List<Unit__c> updateUnitList_2 = new List<Unit__c>();
            

            for(Unit__c sfUnit:requestContainer.getSfUnits()){
                if(String.isBlank(sfUnit.Id)){
                    if(sfUnit.shell_mId__c==null && sfUnit.observed_mId__c==null){
                        insertUnitList_1.add(sfUnit);
                    }else{
                        insertUnitList_2.add(sfUnit);
                    }
                }else{
                    Unit__c existingUnit = existingUnits.get(sfUnit.Id);
                    if((sfUnit.Version__c==0 && existingUnit.Version__c==null) || (sfUnit.Version__c == existingUnit.Version__c)){
                        if(sfUnit.shell_mId__c==null && sfUnit.observed_mId__c==null){
                            updateUnitList_1.add(sfUnit);
                        }else{
                            updateUnitList_2.add(sfUnit);
                        }
                    }
                }
            }
            
            if(!insertUnitList_1.isEmpty()){
                System.debug('creating units1');
                saveObjects(insertUnitList_1, 'insert');
                //insertUnits(insertUnitList_1);
            }
            if(!updateUnitList_1.isEmpty()){
                System.debug('updating units1');
                saveObjects(updateUnitList_1, 'update');
                //updateUnits(updateUnitList_1);
            }
            if(!insertUnitList_2.isEmpty()){
                System.debug('creating units2');
                saveObjects(insertUnitList_2, 'insert');
                //insertUnits(insertUnitList_2);
            }
            if(!updateUnitList_2.isEmpty()){
                System.debug('updating units2');
                saveObjects(updateUnitList_2, 'update');
                //updateUnits(updateUnitList_2);
            }

            System.debug('errorUnits = '+errorUnits);
        }
    }

    private static void processRequestResponses(RequestContainer requestContainer){
        if(requestContainer.responses!=null && !requestContainer.responses.isEmpty()){

            Set<Id> responseIds = new Set<Id>();
            for(Response response:requestContainer.responses){
                responseIds.add(response.id);
            }
            Map<Id, Response__c> existingResponses = new Map<Id, Response__c>([select Version__c from Response__c where id in :responseIds]);

            List<Response__c> insertResponseList = new List<Response__c>();
            List<Response__c> updateResponseList = new List<Response__c>();
            for(Response__c response:requestContainer.getSfResponses()){
                if(String.isBlank(response.Id)){
                    response.Response_ExtId__c = ApexUtility.GUID();
                    insertResponseList.add(response);
                }else{
                    Response__c existingResponse = existingResponses.get(response.Id);
                    //System.debug('response.Version__c == existingResponse.Version__c : '+response.Version__c+', '+existingResponse.Version__c+', unit = '+attributes.get('Unit_of_Interest__c'));
                    if((response.Version__c==0 && existingResponse.Version__c==null) || (response.Version__c == existingResponse.Version__c)){
                        //System.debug('saving response '+response);
                        updateResponseList.add(response);
                    }
                }
            }
            if(!insertResponseList.isEmpty()){
                System.debug('creating responses');
                saveObjects(insertResponseList, 'insert');
                //insertResponses(insertResponseList);
            }
            if(!updateResponseList.isEmpty()){
                System.debug('updating responses '+updateResponseList);
                saveObjects(updateResponseList, 'update');
                //updateResponses(updateResponseList);
            }
        }
    }

    private static void processRequestWorkitems(RequestContainer requestContainer){
        if(requestContainer.workitems!=null && !requestContainer.workitems.isEmpty()){
            Set<Id> workitemIds = new Set<Id>();
            for(Workitem workitem:requestContainer.workitems){
                workitemIds.add(workitem.id);
            }

            Map<Id, Work_Item__c> existingWorkitems = new Map<Id, Work_Item__c>([select Version__c from Work_Item__c where Id in :workitemIds]);

            List<Work_Item__c> insertWorkitemList = new List<Work_Item__c>();
            List<Work_Item__c> updateWorkitemList = new List<Work_Item__c>();
            Set<Id> dniWorkItemIds = new Set<Id>();
            for(Work_Item__c workitem:requestContainer.getSfWorkitems()){
                if(String.isBlank(workitem.Id)){
                    workitem.Work_Item_ExtId__c = ApexUtility.GUID();
                    insertWorkitemList.add(workitem);
                }else{
                    Work_Item__c existingWorkitem = existingWorkitems.get(workitem.Id);
                    //System.debug('workitem.Version__c = '+workitem.Version__c+', existingWorkitem.Version__c = '+existingWorkitem.Version__c+', response='+attributes.get('Response__c'));
                    if((workitem.Version__c==0 && existingWorkitem.Version__c==null) || (workitem.Version__c == existingWorkitem.Version__c)){
                        updateWorkitemList.add(workitem);
                    }
                }

                if(String.isNotBlank(workitem.Escalations__c) && workitem.Escalations__c.contains(DNI_PERM)){
                    dniWorkItemIds.add(workitem.Id);
                }else if(String.isNotBlank(workitem.Escalations__c) && workitem.Escalations__c.contains(DNI_TEMP)){
                    dniWorkItemIds.add(workitem.Id);
                }
        }
            
            if(!insertWorkitemList.isEmpty()){
                saveObjects(insertWorkitemList, 'insert');
            }
            if(!updateWorkitemList.isEmpty()){
                saveObjects(updateWorkitemList, 'update');
            }

            System.debug('dniWorkItemIds = '+dniWorkItemIds);
            if(!dniWorkItemIds.isEmpty()){
                processDni(dniWorkItemIds);
            }
            
        }
    }

    private static void processDni(Set<Id> workitemIds){
        if(workitemIds!=null && !workitemIds.isEmpty()){
            Id suppressionRecordTypeId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
            List<Work_Item__c> workitems = [select 
                    Escalations__c, 
                    Response__r.Unit_of_Interest__c,
                    Response__r.Collection_Instance__r.Collection__c
                from Work_Item__c 
                where Id in :workitemIds];
            

            List<Special_Arrangement__c> specialArrangements = new List<Special_Arrangement__c>();
            for(Work_Item__c wi:workitems){
                if(String.isNotBlank(wi.Escalations__c)){
                    if(wi.Escalations__c.contains(DNI_TEMP) || wi.Escalations__c.contains(DNI_PERM)){
                        Special_Arrangement__c specialArrangement = new Special_Arrangement__c();
                        specialArrangement.RecordTypeId = suppressionRecordTypeId;
                        specialArrangement.DNI_Suppression_Approval__c = 'Pending';
                        specialArrangement.Suppression_Type__c = 'Do Not Interview';
                        specialArrangement.Collection__c = wi.Response__r.Collection_Instance__r.Collection__c;
                        specialArrangement.Survey_Unit__c = wi.Response__r.Unit_of_Interest__c;
                        specialArrangement.Unit__c = wi.Response__r.Unit_of_Interest__c;
                        specialArrangement.Rule_Start_Date__c = Date.today();

                        specialArrangements.add(specialArrangement);
                    }
                }
            }
            System.debug('specialArrangements = '+specialArrangements);

            if(!specialArrangements.isEmpty()){
                //This will careate special arrangemets. Start approval process should be in special arrangement trigger
                Database.DMLOptions options = new Database.DMLOptions();
                Database.insert(specialArrangements, options);
            }
        }
    }
    
    private static void processRequestTasks(RequestContainer requestContainer){
        if(requestContainer.tasks!=null && !requestContainer.tasks.isEmpty()){
            List<Task> insertTaskList = new List<Task>();
            for(Task task:requestContainer.getSfTasks()){
                if(String.isBlank(task.Id)){
                    insertTaskList.add(task);
                }
            }
            if(!insertTaskList.isEmpty()){
                saveObjects(insertTaskList, 'insert');
            }
        }
    }

    private static void processRequestContacts(RequestContainer requestContainer){
        System.debug('processing request contacts');
        if(requestContainer.contacts!=null && !requestContainer.contacts.isEmpty()){
            List<Contact> insertContactList = new List<Contact>();
            List<Contact> updateContactList = new List<Contact>();

            Set<Id> contactIds = new Set<Id>();
            for(ContactPerson cont:requestContainer.contacts){
                contactIds.add(cont.id);
            }
            Map<Id, Contact> existingContacts = new Map<Id, Contact>([select Version__c from Contact where Id in :contactIds]);
            
            for(Contact sfContact:requestContainer.getSfContacts()){
                if(String.isBlank(sfContact.Id)){
                    insertContactList.add(sfContact);
                }else{
                    Contact existingSfContact = existingContacts.get(sfContact.Id);
                    if((sfContact.Version__c==0 && existingSfContact.Version__c==null) || (sfContact.Version__c == existingSfContact.Version__c)){
                        updateContactList.add(sfContact);
                    }
                }
            }

            if(!insertContactList.isEmpty()){
                System.debug('inserting contacts: '+insertContactList);
                saveObjects(insertContactList, 'insert');
            }
            if(!updateContactList.isEmpty()){
                System.debug('updating contacts: '+updateContactList);
                saveObjects(updateContactList, 'update');
            }
        }
    }

    private static void processRequestContactRoles(RequestContainer requestContainer){
        if(requestContainer.contactRoles!=null && !requestContainer.contactRoles.isEmpty()){
            List<Contact_Role__c> insertContactRoleList = new List<Contact_Role__c>();
            List<Contact_Role__c> updateContactRoleList = new List<Contact_Role__c>();

            Set<Id> contactRoleIds = new Set<Id>();
            for(ContactRole contRole:requestContainer.contactRoles){
                contactRoleIds.add(contRole.id);
            }
            Map<Id, Contact_Role__c> existingContactRoles = new Map<Id, Contact_Role__c>([select Version__c from Contact_Role__c where Id in :contactRoleIds]);
            
            for(Contact_Role__c sfContactRole:requestContainer.getSfContactRoles()){
                if(String.isBlank(sfContactRole.Id)){
                    insertContactRoleList.add(sfContactRole);
                }else{
                    Contact_Role__c existingSfContactRole = existingContactRoles.get(sfContactRole.Id);
                    //System.debug('sfContactRole.Version__c = '+sfContactRole.Version__c+', existingSfContactRole.Version__c = '+existingSfContactRole.Version__c);
                    if((sfContactRole.Version__c==0 && existingSfContactRole.Version__c==null) || (sfContactRole.Version__c == existingSfContactRole.Version__c)){
                        updateContactRoleList.add(sfContactRole);
                    }
                }
            }

            if(!insertContactRoleList.isEmpty()){
                System.debug('inserting contact roles: '+insertContactRoleList);
                saveObjects(insertContactRoleList, 'insert');
            }
            if(!updateContactRoleList.isEmpty()){
                System.debug('updating contact roles: '+updateContactRoleList);
                saveObjects(updateContactRoleList, 'update');
            }
        }
    }
    
    private static void processRequestEvents(RequestContainer requestContainer){
        if(requestContainer.events!=null && !requestContainer.events.isEmpty()){
            Set<Id> eventIds = new Set<Id>();
            for(EventItem e:requestContainer.events){
                if(String.isNotBlank(e.Id)){
                    eventIds.add(e.Id);
                }
            }
            Map<Id, Event> existingEvents = new Map<Id, Event>([select Version__c from Event where Id in :eventIds]);

            List<Event> insertEventList = new List<Event>();
            List<Event> updateEventList = new List<Event>();
            for(Event sfEvent:requestContainer.getSfEvents()){
                if(String.isBlank(sfEvent.Id)){
                    insertEventList.add(sfEvent);
                }else{
                    Event existingEvent = existingEvents.get(sfEvent.Id);
                    if((sfEvent.Version__c==0 && existingEvent.Version__c==null) || (sfEvent.Version__c == existingEvent.Version__c)){
                        updateEventList.add(sfEvent);
                    }
                }
            }

            if(!insertEventList.isEmpty()){
                saveObjects(insertEventList, 'insert');
            }
            if(!updateEventList.isEmpty()){
                saveObjects(updateEventList, 'update');
            }
        }
    }











    

    @TestVisible
    private static ResponseContainer generateResponseContainer(){
        System.debug('generateResponseContainer started');

        ResponseContainer responseContainer = new ResponseContainer();

        Set<Id> collectionInstanceIds = new Set<Id>();

        List<Workload__c> sfWorkloads = findWorkloads();
        Set<Id> workloadIds = new Set<Id>();
        if(sfWorkloads!=null && !sfWorkloads.isEmpty()){
            responseContainer.workloads = new List<Workload>();
            for(Workload__c sfWorkload:sfWorkloads){
                workloadIds.add(sfWorkload.Id);
                responseContainer.workloads.add(new Workload(sfWorkload));
                collectionInstanceIds.add(sfWorkload.Collection_Instance__c);
            }
        }
        System.debug(LoggingLevel.INFO,'completed responseContainer.workloads. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize());

        Set<Id> responseIds = new Set<Id>();
        Set<Id> workitemIds = new Set<Id>();
        List<Work_Item__c> sfWorkitems = findWorkitems(workloadIds);
        if(sfWorkitems!=null && !sfWorkitems.isEmpty()){
            responseContainer.workitems = new List<Workitem>();
            for(Work_Item__c sfWorkitem:sfWorkitems){
                responseIds.add(sfWorkitem.Response__c);
                workitemIds.add(sfWorkitem.Id);
                responseContainer.workitems.add(new Workitem(sfWorkitem));
            }
        }
        System.debug(LoggingLevel.INFO,'completed responseContainer.workitems. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize()); 

        List<Response__c> sfResponses = findResponses(responseIds);
        responseContainer.responses = new List<Response>();
        if(sfResponses != null && !sfResponses.isEmpty()){
            for(Response__c sfResponse:sfResponses){
                responseContainer.responses.add(new Response(sfResponse));
                collectionInstanceIds.add(sfResponse.Collection_Instance__c);
            }
        }
        System.debug(LoggingLevel.INFO,'completed responseContainer.responses. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize()); 

        Set<Id> unitIds = new Set<Id>();
        for(Response__c r:sfResponses){
            unitIds.add(r.Unit_of_Interest__c);
        }
        System.debug('unitIds: '+unitIds);

        List<Unit__c> sfUnits = findUnits(unitIds);
        if(sfUnits!=null && !sfUnits.isEmpty()){
            responseContainer.units = new List<Unit>();
            for(Unit__c sfUnit:sfUnits){
                responseContainer.units.add(new Unit(sfUnit));
            }
        }
        System.debug(LoggingLevel.INFO,'completed responseContainer.units. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize()); 

        List<Task> tasks = findTasks(workitemIds,responseIds);
        if(tasks!=null && !tasks.isEmpty()){
            responseContainer.tasks = new List<HistoryItem>();
            for(Task sfTask:tasks){
                responseContainer.tasks.add(new HistoryItem(sfTask));
            }
        }
        System.debug(LoggingLevel.INFO,'completed responseContainer.tasks. heap size used: '+Limits.getHeapSize()+', limit heap size: '+Limits.getLimitHeapSize()); 

        List<Event> events = findEvents(workitemIds,responseIds);
        if(events!=null && !events.isEmpty()){
            responseContainer.events = new List<EventItem>();
            for(Event evnt:events){
                responseContainer.events.add(new EventItem(evnt));
            }
        }

        Set<Id> collectionIds = new Set<Id>();
        List<Collection_Instance__c> sfCollectionInstances = findCollectionInstances(collectionInstanceIds);
        if(sfCollectionInstances!=null && !sfCollectionInstances.isEmpty()){
            responseContainer.collectionInstances = new List<CollectionInstance>();
            for(Collection_Instance__c sfCollectionInstance:sfCollectionInstances){
                responseContainer.collectionInstances.add(new CollectionInstance(sfCollectionInstance));
                collectionIds.add(sfCollectionInstance.Collection__c);
            }
        }

        List<Contact_Role__c> sfContactRoles = findContactRoles(unitIds, collectionIds);
        Set<Id> contactIds = new Set<Id>();
        if(sfContactRoles!=null && !sfContactRoles.isEmpty()){
            responseContainer.contactRoles = new List<ContactRole>();
            for(Contact_Role__c sfContactRole:sfContactRoles){
                responseContainer.contactRoles.add(new ContactRole(sfContactRole));
                contactIds.add(sfContactRole.Contact__c);
            }
        }

        List<Contact> sfContacts = findContacts(contactIds);
        if(sfContacts!=null && !sfContacts.isEmpty()){
            responseContainer.contacts = new List<ContactPerson>();
            for(Contact sfContact:sfContacts){
                responseContainer.contacts.add(new ContactPerson(sfContact));
            }
        }

        responseContainer.utils = findUtils();

        System.debug('responseContainer = '+responseContainer);

        return responseContainer;
    }

    private static List<Workload__c> findWorkloads(){
        Id userId = UserInfo.getUserId();

        List<Workload__c> workloads = [select Id, 
                                            LastModifiedDate,
                                            Name, 
                                            Workload_ID__c, 
                                            Area_Unit_Name__c,
                                            Workload_Priority_Indicator__c,
                                            Collection_Instance__c,
                                            (select Response__r.Wave__c,
                                                Response__r.Wave_Start_Date__c,
                                                Response__r.Wave_End_Date__c,
                                                Response__r.Rotation__c
                                                from Work_Items__r limit 1)
                                        from Workload__c 
                                        where OwnerId=:userId and
                                            Collection_Instance__r.Active__c = true];

        return workloads;
    }

    private static List<Work_Item__c> findWorkitems(Set<Id> workloadIds){
        Id userId = UserInfo.getUserId();
        
        //Also maintain formula in the workflow rule IncrementWorkitemVersion in order to update version number
        //do not include Mobile_Device_Id__c into the workflow rule formula. version should not update on this field change
        //Completed_By__c and Completed_Date_Time__c should not update version number.
        List<Work_Item__c> workitems = [select Id,
                                            mId__c,
                                            resp_mId__c,
                                            Version__c,
                                            Response__c,
                                            Description__c, 
                                            Notes__c, 
                                            Outcome__c,  
                                            Status__c,
                                            Work_Item_Type__c,
                                            Starred__c,
                                            Workload__c,
                                            WI_Priority__c,
                                            Action__c,
                                            Completed_By__c,
                                            Completed_Date_Time__c,
                                            Error_Message__c,
                                            Escalations__c
                                        from Work_Item__c 
                                        where OwnerId=:userId and
                                            Response__c != '' and
                                            Response__r.Unit_of_Interest__c != '' and
                                            Workload__c != '' and
                                            Workload__c in :workloadIds and
                                            Mobile_Device_Id__c not in :errorWorkitems.keySet()];
        workitems.addAll(errorWorkitems.values());
        return workitems;
    }

    private static List<Response__c> findResponses(Set<Id> responseIds){
        //Also maintain formula in the workflow rule IncrementResposneVersion in order to update version number
        //do not include Mobile_Device_Id__c into the workflow rule formula. version should not update on this field change
        List<Response__c> responses = [select 
                                        Id,
                                        mId__c,
                                        uoi_mId__c,
                                        Version__c,
                                        Collection_Instance__c,
                                        Occupancy_Status__c,
                                        Occupancy_Status_Reason__c,
                                        Estimated_Number_of_Occupants__c,
                                        Document_Number__c,
                                        Questionnaire_Pack__c,
                                        Number_of_Dwelling_Forms_Received__c,
                                        Number_of_Individual_Forms_Received__c,
                                        Unit_Delivery_Mode__c,
                                        Unit_of_Interest__c,
                                        Notes__c,
                                        Error_Message__c,
                                        Wave_Start_Date__c,
                                        Wave_End_Date__c
                                    from Response__c 
                                    where Id in :responseIds and 
                                      Mobile_Device_Id__c not in :errorResponses.keySet()];

        responses.addAll(errorResponses.values());
        return responses;
    }

    private static List<Unit__c> findUnits(Set<Id> unitIds){
        //Also maintain formula in the workflow rule IncrementUnitVersion in order to update version number
        //do not include Mobile_Device_Id__c into the workflow rule formula. version should not update on this field change
        List<Unit__c> units = [select Id,
                                    mId__c,
                                    shell_mId__c,
                                    observed_mId__c,
                                    Version__c,
                                    Easting__c,
                                    Northing__c,
                                    Address_Type__c, 
                                    Address_Sub_Type__c, 
                                    Building_Name__c, 
                                    Level_Number__c, 
                                    Meshblock_Code__c, 
                                    Notes__c, 
                                    Other_Address_Type__c, 
                                    Postcode__c,
                                    Road_Number__c, 
                                    Road_Number_Alpha__c, 
                                    Road_Name__c, 
                                    Road_Type__c, 
                                    Road_Direction__c,  
                                    Suburb__c, 
                                    Town_or_City__c, 
                                    Unit_Number__c, 
                                    Unit_Type__c,
                                    Requires_Cartesian_Coordinates__c,
                                    Shell_Address__c,
                                    Related_Observed_Address__c,
                                    Error_Message__c,
                                    Unit_of_Interest_ID__c
                                from Unit__c 
                                where Id in :unitIds and 
                                    Mobile_Device_Id__c not in :errorUnits.keySet()];
        
        units.addAll(errorUnits.values());
        return units;
    }

    private static List<Task> findTasks(Set<Id> workitemIds, Set<Id> responseIds){
        List<Task> tasks = [select Id, Subject, Action_Date_Time__c, CreatedDate, WhatId, Type, Response__c, mId__c, wi_mId__c, resp_mId__c, Error_Message__c
           from Task where (WhatId in :workitemIds or response__c in :responseIds) and Mobile_Device_Id__c not in :errorTasks.keySet()];
        tasks.addAll(errorTasks.values());
        return tasks;
    }

    private static List<Util>  findUtils(){
        List<Util> utils = new List<Util>();
        utils.add(new Util('userFirstName', UserInfo.getFirstName()));
        utils.add(new Util('userLastName', UserInfo.getLastName()));

        Profile profile = [select Name from Profile where Id=:UserInfo.getProfileId()];
        String profileName = profile.Name;
        if(systemSettings.containsKey('mobile.profile.mapping.'+profileName)){
            profileName = systemSettings.get('mobile.profile.mapping.'+profileName).Value__c;
        }
        utils.add(new Util('userType', profileName));

        

        List<Mobile_Settings__c> mobileSettings = Mobile_Settings__c.getall().values();
        
        for(Mobile_Settings__c ms:mobileSettings){
           utils.add(new Util(ms.Name, ms.Value__c));
        }
        return utils;
    }

    private static List<Collection_Instance__c> findCollectionInstances(Set<Id> collectionInstanceIds){
        List<Collection_Instance__c> collectionInstances = [select
                                        Id,
                                        Name,
                                        Collection_Instance_Code__c,
                                        Collection__c
                                    from Collection_Instance__c
                                    where Id in :collectionInstanceIds
                                ];
        return collectionInstances;
    }

    private static List<Contact_Role__c> findContactRoles(Set<Id> unitIds, Set<Id> collectionIds){
        List<Contact_Role__c> contactRoles = [select
                                    Version__c,
                                    mId__c,
                                    Mobile_Device_Id__c,
                                    Contact__c,
                                    cnt_mId__c,
                                    Unit_of_Interest_ID__c,
                                    uoi_mId__c,
                                    Primary_Contact__c,
                                    Role__c,
                                    Error_Message__c,
                                    Collection__c
                                from Contact_Role__c 
                                where Mobile_Device_Id__c not in :errorContactRoles.keySet()
                                and Unit_of_Interest_ID__c in :unitIds 
                                and Collection__c in :collectionIds
                                and Status__c = 'Active'
                            ];
        contactRoles.addAll(errorContactRoles.values());
        return contactRoles;
    }

    private static List<Contact> findContacts(Set<Id> contactIds){
        List<Contact> contacts = [select
                            mId__c,
                            Version__c,
                            FirstName,
                            LastName,
                            Email,
                            Phone,
                            MobilePhone,
                            Gender__c,
                            Age__c,
                            Error_Message__c,
                            Best_Time_To_Contact__c,
                            Do_Not_Contact_Days__c
                            from Contact
                            where Id in :contactIds
                            and Mobile_Device_Id__c not in :errorContacts.keySet()
                        ];
        contacts.addAll(errorContacts.values());
        System.debug('errorContacts = '+errorContacts.values());
        return contacts;
    }

    private static List<Event> findEvents(Set<Id> workitemIds, Set<Id> responseIds){
        List<Event> events = [select Id, Version__c, Subject, ActivityDateTime, WhatId, 
                Response__c, mId__c, wi_mId__c, resp_mId__c, Error_Message__c, Reminder__c
           from Event where WhatId in :workitemIds or Response__c in :responseIds]; // and Mobile_Device_Id__c not in :errorTasks.keySet()];
        return events;
    }










    //===================================================================================================================
    //Below are the objects that are used to serialise into JSON and deserialise back.
    @TestVisible
    private static String generateExtId(Long id){
        return mobileDeviceId + UserInfo.getUserId() + id;
    }

    @TestVisible
    private class RequestContainer{
        String deviceId;
        Integer versionCode;
        String versionName;
        List<Unit> units;
        List<Response> responses;
        List<Workitem> workitems;
        List<HistoryItem> tasks;
        List<ContactPerson> contacts;
        List<ContactRole> contactRoles;
        List<EventItem> events;

        public List<Unit__c> getSfUnits(){
            if(units!=null && !units.isEmpty()){
                List<Unit__c> sfUnits = new List<Unit__c>();
                for(Unit unit:units){
                    sfUnits.add(unit.toSfUnit());
                }
                return sfUnits;
            }
            return null;
        }

        public Set<Response__c> getSfResponses(){
            if(responses!=null && !responses.isEmpty()){
                Set<Response__c> sfResponses = new Set<Response__c>();
                for(Response response:responses){
                    sfResponses.add(response.toSfResponse());
                }
                return sfResponses;
            }
            return null;
        }

        public List<Work_Item__c> getSfWorkitems(){
            if(workitems!=null && !workitems.isEmpty()){
                List<Work_Item__c> sfWorkitems = new List<Work_Item__c>();
                for(Workitem workitem:workitems){
                    sfWorkitems.add(workitem.toSfWorkitem());
                }
                return sfWorkitems;
            }
            return null;
        }

        public List<Task> getSfTasks(){
            if(tasks!=null && !tasks.isEmpty()){
                List<Task> sfTasks = new List<Task>();
                for(HistoryItem hi:tasks){
                    sfTasks.add(hi.toSfTask());
                }
                return sfTasks;
            }
            return null;
        }

        public List<Contact> getSfContacts(){
            if(contacts!=null && !contacts.isEmpty()){
                List<Contact> sfContacts = new List<Contact>();
                for(ContactPerson cont:contacts){
                    sfContacts.add(cont.toSfContact());
                }
                return sfContacts;
            }
            return null;
        }

        public List<Contact_Role__c> getSfContactRoles(){
            if(contactRoles!=null && !contactRoles.isEmpty()){
                List<Contact_Role__c> sfContRoles = new List<Contact_Role__c>();
                for(ContactRole contR:contactRoles){
                    sfContRoles.add(contR.toSfContactRole());
                }
                return sfContRoles;
            }
            return null;
        }

        public List<Event> getSfEvents(){
            if(events!=null && !events.isEmpty()){
                List<Event> sfEvents = new List<Event>();
                for(EventItem ei:events){
                    sfEvents.add(ei.toSfEvent());
                }
                return sfEvents;
            }
            return null;
        }
    }

    @TestVisible
    public class ResponseContainer{
        List<CollectionInstance> collectionInstances;
        List<Workload> workloads;
        List<Unit> units;
        List<Response> responses;
        List<Workitem> workitems;
        List<HistoryItem> tasks;
        List<EventItem> events;
        List<Util> utils;
        List<ContactRole> contactRoles;
        List<ContactPerson> contacts;
        
        public String toJson(){
            Map<String, Object> container = toMap();
            String jsonStr = JSON.serialize(container);
            return jsonStr;
        }

        private Map<String, Object> toMap(){
            Map<String, Object> containerMap = new Map<String, Object>();
            if(workloads!=null && !workloads.isEmpty()){
                List<Object> objs = new List<Object>();
                for(Workload workload:workloads){
                    objs.add(workload.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('workloads', objs);
                }
            }
            if(responses!=null && !responses.isEmpty()){
                List<Object> objs = new List<Object>();
                for(Response response:responses){
                    objs.add(response.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('responses', objs);
                }
            }
            if(units!=null && !units.isEmpty()){
                List<Object> objs = new List<Object>();
                for(Unit unit:units){
                    objs.add(unit.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('units', objs);
                }
            }
            if(workitems!=null && !workitems.isEmpty()){
                List<Object> objs = new List<Object>();
                for(Workitem workitem:workitems){
                    objs.add(workitem.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('workitems', objs);
                }
            }
            if(tasks!=null && !tasks.isEmpty()){
                List<Object> objs = new List<Object>();
                for(HistoryItem task:tasks){
                    objs.add(task.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('tasks', objs);
                }
            }
            if(utils!=null && !utils.isEmpty()){
                List<Object> objs = new List<Object>();
                for(Util util:utils){
                    objs.add(util.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('utils', objs);
                }
            }
            if(collectionInstances!=null && !collectionInstances.isEmpty()){
                List<Object> objs = new List<Object>();
                for(CollectionInstance collectionInstance:collectionInstances){
                    objs.add(collectionInstance.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('collectionInstances', objs);
                }
            }
            if(contactRoles!=null && !contactRoles.isEmpty()){
                List<Object> objs = new List<Object>();
                for(ContactRole contactRole:contactRoles){
                    objs.add(contactRole.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('contactRoles', objs);
                }
            }
            if(contacts!=null && !contacts.isEmpty()){
                List<Object> objs = new List<Object>();
                for(ContactPerson contact:contacts){
                    objs.add(contact.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('contacts', objs);
                }
            }
            if(events!=null && !events.isEmpty()){
                List<Object> objs = new List<Object>();
                for(EventItem evnt:events){
                    objs.add(evnt.toMap());
                }
                if(!objs.isEmpty()){
                    containerMap.put('events', objs);
                }
            }

            return containerMap;
        }
    }

    private class Workload{
        String id;
        String name;
        String wlId; 
        String ciId;
        String area;  
        Integer priority; 
        String wave;
        Date startDate;
        Date endDate;
        String rotation;

        public Workload(){}

        public Workload (Workload__c sfWorkload){
            this.id = sfWorkload.Id;
            this.name = sfWorkload.Name;
            this.wlId = sfWorkload.Workload_ID__c;
            this.ciId = sfWorkload.Collection_Instance__c;
            this.area = sfWorkload.Area_Unit_Name__c;
            if(sfWorkload.Workload_Priority_Indicator__c != null){
                this.priority = sfWorkload.Workload_Priority_Indicator__c.intValue();
            }
            if(sfWorkload.Work_Items__r!=null && !sfWorkload.Work_Items__r.isEmpty()){
                this.wave = sfWorkload.Work_Items__r.get(0).Response__r.Wave__c;
                this.startDate = sfWorkload.Work_Items__r.get(0).Response__r.Wave_Start_Date__c;
                this.endDate = sfWorkload.Work_Items__r.get(0).Response__r.Wave_End_Date__c;
                this.rotation = sfWorkload.Work_Items__r.get(0).Response__r.Rotation__c;
            }
        }

        public Map<String, Object> toMap(){
            Map<String, Object> workload = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                workload.put('id', this.id);
            }
            if(String.isNotBlank(this.name)){
                workload.put('name', this.name);
            }
            if(String.isNotBlank(this.wlId)){
                workload.put('wlId', this.wlId);
            }
            if(String.isNotBlank(this.ciId)){
                workload.put('ciId', this.ciId);
            }
            if(String.isNotBlank(this.area)){
                workload.put('area', this.area);
            }
            if(this.priority!=null){
                workload.put('priority', this.priority);
            }
            if(String.isNotBlank(this.wave)){
                workload.put('wave', this.wave);
            }
            if(this.startDate!=null){
                workload.put('startDate', this.startDate);
            }
            if(this.endDate!=null){
                workload.put('endDate', this.endDate);
            }
            if(String.isNotBlank(this.rotation)){
                workload.put('rotation', this.rotation);
            }
            return workload;
        }                                          
    }

    private class Workitem{
        String id;
        Long mId;
        String wlId;
        String type;
        Boolean starred;
        String status;
        Long resp_mId;
        String respId;
        Integer vers;
        String notes;
        String action;
        String outcome;
        String errMsg;
        String complBy;
        DateTime complTime;
        String fromId;
        String escalations;

        public Workitem(){}

        public Workitem(Work_Item__c sfWorkitem){
            this.id = sfWorkitem.Id;
            if(sfWorkitem.mId__c!=null){
                this.mId = sfWorkitem.mId__c.longValue();
            }
            if(sfWorkitem.Version__c != null){
                this.vers = sfWorkitem.Version__c.intValue();
            }
            this.respId = sfWorkitem.Response__c;
            if(sfWorkitem.resp_mId__c!=null){
                this.resp_mId = sfWorkitem.resp_mId__c.longValue();
            }
            this.notes = sfWorkitem.Notes__c;
            this.outcome = sfWorkitem.Outcome__c;
            this.status = sfWorkitem.Status__c;
            this.type = sfWorkitem.Work_Item_Type__c;
            this.starred = sfWorkitem.Starred__c;
            this.wlId = sfWorkitem.Workload__c;
            this.action = sfWorkitem.Action__c;
            this.complBy = sfWorkitem.Completed_By__c;
            this.complTime = sfWorkitem.Completed_Date_Time__c;
            this.errMsg = sfWorkitem.Error_Message__c;
            this.escalations = sfWorkitem.Escalations__c;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> workitem = new Map<String, Object>();

            if(String.isNotBlank(this.id)){
                workitem.put('id', this.id);
            }else if(this.mId!=null){
                workitem.put('mId', this.mId);
            }       

            if(String.isNotBlank(this.errMsg)){
                workitem.put('errMsg', this.errMsg);    
            }
            if(this.vers!=null){
                workitem.put('vers', this.vers);
            }

            if(String.isNotBlank(this.respId)){
                workitem.put('respId', this.respId);
            }else if(this.resp_mId!=null){
                workitem.put('resp_mId', this.resp_mId);
            }

            if(String.isNotBlank(this.notes)){
                workitem.put('notes', this.notes);
            }
            if(String.isNotBlank(this.outcome)){
                workitem.put('outcome', this.outcome);
            }
            if(String.isNotBlank(this.status)){
                workitem.put('status', this.status);
            }
            if(String.isNotBlank(this.type)){
                workitem.put('type', this.type);
            }
            if(this.starred!=null){
                workitem.put('starred', this.starred);
            }
            if(String.isNotBlank(this.wlId)){
                workitem.put('wlId', this.wlId);
            }
            if(String.isNotBlank(this.action)){
                workitem.put('action', this.action);
            }
            if(String.isNotBlank(this.complBy)){
                workitem.put('complBy', this.complBy);
            }
            if(this.complTime!=null){
                workitem.put('complTime', this.complTime);
            }
            if(String.isNotBlank(this.escalations)){
                workitem.put('escalations', this.escalations);
            }
            return workitem;
        }

        public Work_Item__c toSfWorkitem(){
            Work_Item__c sfWorkitem = new Work_Item__c();
            sfWorkitem.Id = this.id;
            sfWorkitem.Mobile_Device_Id__c = generateExtId(this.mId);
            sfWorkitem.mId__c = this.mId;
            sfWorkitem.Work_Item_Type__c = this.type;
            sfWorkitem.Starred__c = this.starred;
            sfWorkitem.Status__c = this.status;
            sfWorkitem.Version__c = vers;
            sfWorkitem.Notes__c = notes;
            sfWorkitem.Action__c = action;
            sfWorkitem.Outcome__c = outcome;
            sfWorkitem.Completed_By__c = complBy;
            sfWorkitem.Completed_Date_Time__c = complTime;
            sfWorkitem.Created_From_Work_Item_Id__c = fromId;
            sfWorkitem.Workload__c = this.wlId;
            sfWorkitem.Escalations__c = this.escalations;

            if(String.isNotBlank(this.respId)){
                sfWorkitem.Response__c = this.respId;
            }else if(this.resp_mId!=null && responseIdMap.containsKey(this.resp_mId)){
                sfWorkitem.Response__c = responseIdMap.get(this.resp_mId);
            }
            sfWorkitem.resp_mId__c = this.resp_mId;

            return sfWorkitem;
        }
    }

    private class Response{
        String id;
        Long mId;
        Long uoi_mId;
        String uId; 
        Integer vers;
        String ciId;
        String qPack;
        String docNum;
        Integer estOccupants;
        String occStatus;
        String occReason;
        String notes;
        Integer dfRec;
        Integer ifRec;
        String uDelMode;
        String errMsg;
        String fromId;
        Date startDate;
        Date endDate;

        public Response(){}

        public Response(Response__c sfResponse){
            this.id = sfResponse.Id;
            if(sfResponse.mId__c != null){
                this.mId = sfResponse.mId__c.longValue();
            }
            if(sfResponse.Version__c != null){
                this.vers = sfResponse.Version__c.intValue();
            }
            if(sfResponse.uoi_mId__c != null){
                this.uoi_mId = sfResponse.uoi_mId__c.longValue();
            }
            this.ciId = sfResponse.Collection_Instance__c;
            this.occStatus = sfResponse.Occupancy_Status__c;
            this.occReason = sfResponse.Occupancy_Status_Reason__c;
            if(sfResponse.Estimated_Number_of_Occupants__c != null){
                this.estOccupants = sfResponse.Estimated_Number_of_Occupants__c.intValue();
            }
            this.docNum = sfResponse.Document_Number__c;
            this.qPack = sfResponse.Questionnaire_Pack__c;
            if(sfResponse.Number_of_Dwelling_Forms_Received__c != null){
                this.dfRec = sfResponse.Number_of_Dwelling_Forms_Received__c.intValue();
            }
            if(sfResponse.Number_of_Individual_Forms_Received__c != null){
                this.ifRec = sfResponse.Number_of_Individual_Forms_Received__c.intValue();
            }
            this.uDelMode = sfResponse.Unit_Delivery_Mode__c;
            this.uId = sfResponse.Unit_of_Interest__c;
            this.notes = sfResponse.Notes__c;
            this.errMsg = sfResponse.Error_Message__c;
            this.startDate = sfResponse.Wave_Start_Date__c;
            this.endDate = sfResponse.Wave_End_Date__c;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> response = new Map<String, Object>();
            
            if(String.isNotBlank(this.id)){
                response.put('id', this.id);
            }else if(this.mId!=null){
                response.put('mId', this.mId);
            }

            if(String.isNotBlank(this.errMsg)){
                response.put('errMsg', this.errMsg);
            }
            if(this.vers!=null){
                response.put('vers', this.vers);
            }
            if(String.isNotBlank(this.ciId)){
                response.put('ciId', this.ciId);
            }
            if(String.isNotBlank(this.occStatus)){
                response.put('occStatus', this.occStatus);
            }
            if(String.isNotBlank(this.occReason)){
                response.put('occReason', this.occReason);
            }
            if(this.estOccupants!=null){
                response.put('estOccupants', this.estOccupants);
            }
            if(String.isNotBlank(this.docNum)){
                response.put('docNum', this.docNum);
            }
            if(String.isNotBlank(this.qPack)){
                response.put('qPack', this.qPack);
            }
            if(this.dfRec!=null){
                response.put('dfRec', this.dfRec);
            }
            if(this.ifRec!=null){
                response.put('ifRec', this.ifRec);
            }
            if(String.isNotBlank(this.uDelMode)){
                response.put('uDelMode', this.uDelMode);
            }

            if(String.isNotBlank(this.uId)){
                response.put('uId', this.uId);
            }else if(this.uoi_mId!=null){
                response.put('uoi_mId', this.uoi_mId);
            }

            if(String.isNotBlank(this.notes)){
                response.put('notes', this.notes);
            }
            if(this.startDate!=null){
                response.put('startDate', this.startDate);
            }
            if(this.endDate!=null){
                response.put('endDate', this.endDate);
            }
            
            return response;
        }

        public Response__c toSfResponse(){
            Response__c sfResponse = new Response__c();
            sfResponse.Id = this.id;
            sfResponse.Mobile_Device_Id__c = generateExtId(this.mId); 
            sfResponse.mId__c = this.mId;
            sfResponse.uoi_mId__c = this.uoi_mId;
            sfResponse.Version__c = this.vers;
            sfResponse.Collection_Instance__c = this.ciId;
            sfResponse.Questionnaire_Pack__c = this.qPack;
            sfResponse.Document_Number__c = this.docNum;
            sfResponse.Estimated_Number_of_Occupants__c = this.estOccupants;
            sfResponse.Occupancy_Status__c = this.occStatus;
            sfResponse.Occupancy_Status_Reason__c = this.occReason;
            sfResponse.Notes__c = this.notes;
            sfResponse.Number_of_Dwelling_Forms_Received__c = this.dfRec;
            sfResponse.Number_of_Individual_Forms_Received__c = this.ifRec;
            sfResponse.Unit_Delivery_Mode__c = this.uDelMode;
            sfResponse.Created_From_Response_Id__c = this.fromId;

            if(String.isNotBlank(this.uId)){
                sfResponse.Unit_of_Interest__c = this.uId;
            }else if(this.uoi_mId!=null && unitIdMap.containsKey(this.uoi_mId)){
                sfResponse.Unit_of_Interest__c = unitIdMap.get(this.uoi_mId);
            }
            return sfResponse;
        }
    }

    private class Unit{
        String id;
        Long mId;
        Integer vers;
        Decimal east;
        Decimal north;
        String addrType;
        String addrSubType;
        String bldName;
        String lvlNum;
        String mbCode;
        String notes;
        String otherAddrType;
        String postcode;
        String roadNum;
        String roadAlpha;
        String roadName;
        String roadType;
        String roadDir;
        String suburb;
        String town;
        String unitNum;
        String unitType;
        Boolean reqCoords;
        String shellId;
        Long shell_mId;
        String observedId;
        Long observed_mId;
        String errMsg;
        String fromId;
        String ref;

        public Unit(){}

        public Unit(Unit__c sfUnit){
            this.id = sfUnit.Id;
            if(sfUnit.mId__c != null){
                this.mId = sfUnit.mId__c.longValue();
            }
            if(sfUnit.Version__c != null){
                this.vers = sfUnit.Version__c.intValue();
            }
            if(sfUnit.Easting__c!=null){
                this.east = Decimal.valueOf(sfUnit.Easting__c);
            }
            if(sfUnit.Northing__c!=null){
                this.north = Decimal.valueOf(sfUnit.Northing__c);
            }
            this.addrType = sfUnit.Address_Type__c;
            this.addrSubType = sfUnit.Address_Sub_Type__c;
            this.bldName = sfUnit.Building_Name__c;
            this.lvlNum = sfUnit.Level_Number__c;
            this.mbCode = sfUnit.Meshblock_Code__c;
            this.notes = sfUnit.Notes__c;
            this.otherAddrType = sfUnit.Other_Address_Type__c;
            this.postcode = sfUnit.Postcode__c;
            this.roadNum = sfUnit.Road_Number__c;
            this.roadAlpha = sfUnit.Road_Number_Alpha__c;
            this.roadName = sfUnit.Road_Name__c;
            this.roadType = sfUnit.Road_Type__c;
            this.roadDir = sfUnit.Road_Direction__c;
            this.suburb = sfUnit.Suburb__c;
            this.town = sfUnit.Town_or_City__c;
            this.unitNum = sfUnit.Unit_Number__c;
            this.unitType = sfUnit.Unit_Type__c;
            this.reqCoords = sfUnit.Requires_Cartesian_Coordinates__c;
            this.shellId = sfUnit.Shell_Address__c;
            if(sfUnit.shell_mId__c != null){
                this.shell_mId = sfUnit.shell_mId__c.longValue();
            }
            this.observedId = sfUnit.Related_Observed_Address__c;
            if(sfUnit.observed_mId__c != null){
                this.observed_mId = sfUnit.observed_mId__c.longValue();
            }
            this.errMsg = sfUnit.Error_Message__c;
            this.ref = sfUnit.Unit_of_Interest_ID__c;
        }   

        public Map<String, Object> toMap(){
            Map<String, Object> unit = new Map<String, Object>();

            if(String.isNotBlank(this.id)){
                unit.put('id', this.id);
            }else if(this.mId!=null){
                unit.put('mId', this.mId);
            }

            if(String.isNotBlank(this.errMsg)){
                unit.put('errMsg', this.errMsg);
            }
            if(this.vers!=null){
                unit.put('vers', this.vers);
            }
            if(this.east!=null){
                unit.put('east', this.east);
            }
            if(this.north!=null){
                unit.put('north', this.north);
            }
            if(String.isNotBlank(this.addrType)){
                unit.put('addrType', this.addrType);
            }
            if(String.isNotBlank(this.addrSubType)){
                unit.put('addrSubType', this.addrSubType);
            }
            if(String.isNotBlank(this.bldName)){
                unit.put('bldName', this.bldName);
            }
            if(String.isNotBlank(this.lvlNum)){
                unit.put('lvlNum', this.lvlNum);
            }
            if(String.isNotBlank(this.mbCode)){
                unit.put('mbCode', this.mbCode);
            }
            if(String.isNotBlank(this.notes)){
                unit.put('notes', this.notes);
            }
            if(String.isNotBlank(this.otherAddrType)){
                unit.put('otherAddrType', this.otherAddrType);
            }
            if(String.isNotBlank(this.postcode)){
                unit.put('postcode', this.postcode);
            }
            if(String.isNotBlank(this.roadNum)){
                unit.put('roadNum', this.roadNum);
            }
            if(String.isNotBlank(this.roadAlpha)){
                unit.put('roadAlpha', this.roadAlpha);
            }
            if(String.isNotBlank(this.roadName)){
                unit.put('roadName', this.roadName);
            }
            if(String.isNotBlank(this.roadType)){
                unit.put('roadType', this.roadType);
            }
            if(String.isNotBlank(this.roadDir)){
                unit.put('roadDir', this.roadDir);
            }
            if(String.isNotBlank(this.suburb)){
                unit.put('suburb', this.suburb);
            }
            if(String.isNotBlank(this.town)){
                unit.put('town', this.town);
            }
            if(String.isNotBlank(this.unitNum)){
                unit.put('unitNum', this.unitNum);
            }
            if(String.isNotBlank(this.unitType)){
                unit.put('unitType', this.unitType);
            }
            if(this.reqCoords!=null){
                unit.put('reqCoords', this.reqCoords);
            }

            if(String.isNotBlank(this.shellId)){
                unit.put('shellId', this.shellId);
            }else if(this.shell_mId!=null){
                unit.put('shell_mId', this.shell_mId);
            }

            if(String.isNotBlank(this.observedId)){
                unit.put('observedId', this.observedId);
            }else if(this.observed_mId!=null){
                unit.put('observed_mId', this.observed_mId);
            }

            if(String.isNotBlank(this.ref)){
                unit.put('ref', this.ref);
            }
            return unit;
        }

        public Unit__c toSfUnit(){
            Unit__c sfUnit = new Unit__c();
            sfUnit.Id = this.id;
            sfUnit.Mobile_Device_Id__c = generateExtId(mId);
            sfUnit.mId__c = this.mId;
            sfUnit.observed_mId__c = this.observed_mId;
            sfUnit.shell_mId__c = this.shell_mId;
            sfUnit.Version__c = this.vers;
            sfUnit.Easting__c = String.valueOf(this.east);
            sfUnit.Northing__c = String.valueOf(this.north);
            sfUnit.Address_Type__c = this.addrType;
            sfUnit.Address_Sub_Type__c = this.addrSubType;
            sfUnit.Building_Name__c = this.bldName;
            sfUnit.Level_Number__c = this.lvlNum;
            sfUnit.Meshblock_Code__c = this.mbCode;
            sfUnit.Notes__c = this.notes;
            sfUnit.Other_Address_Type__c = this.otherAddrType;
            sfUnit.Postcode__c = this.postcode;
            sfUnit.Road_Number__c = this.roadNum;
            sfUnit.Road_Number_Alpha__c = this.roadAlpha;
            sfUnit.Road_Name__c = this.roadName;
            sfUnit.Road_Type__c = this.roadType;
            sfUnit.Road_Direction__c = this.roadDir;
            sfUnit.Suburb__c = this.suburb;
            sfUnit.Town_or_City__c = this.town;
            sfUnit.Unit_Number__c = this.unitNum;
            sfUnit.Unit_Type__c = this.unitType;
            sfUnit.Created_From_Unit_Id__c = this.fromId;

            if(String.isNotBlank(this.shellId)){
                sfUnit.Shell_Address__c = this.shellId;
            }else if(this.shell_mId!=null && unitIdMap.containsKey(this.shell_mId)){
                sfUnit.Shell_Address__c= unitIdMap.get(this.shell_mId);
            }else{
                sfUnit.Shell_Address__c = null;
            }

            if(String.isNotBlank(this.observedId)){
                sfUnit.Related_Observed_Address__c = this.observedId;
            }else if(this.observed_mId!=null && unitIdMap.containsKey(this.observed_mId)){
                sfUnit.Related_Observed_Address__c = unitIdMap.get(this.observed_mId);
            }else{
                sfUnit.Related_Observed_Address__c = null;
            }
            return sfUnit;
        }
    }

    public class HistoryItem{
        public String id;
        public Long mId;
        public String subject;
        public DateTime actTime;
        public String whatId;
        public Long wi_mId;
        public String respId;
        public Long resp_mId;
        public String type;
        public String errMsg;

        public HistoryItem(){

        }

        public HistoryItem(Task sfTask){
            this.id = sfTask.Id;
            if(sfTask.mId__c!=null){
                this.mId = sfTask.mId__c.longValue();
            }
            this.subject = sfTask.Subject;
            
            if(sfTask.Action_Date_Time__c != null){
                this.actTime = sfTask.Action_Date_Time__c;
            }else{
                this.actTime = sfTask.CreatedDate;
            }
            this.whatId = sfTask.WhatId;
            if(sfTask.wi_mId__c!=null){
                this.wi_mId = sfTask.wi_mId__c.longValue();
            }  
            this.type = sfTask.Type;
            this.respId = sfTask.Response__c;
            if(sfTask.resp_mId__c!=null){
                this.resp_mId = sfTask.resp_mId__c.longValue();
            } 
            this.errMsg = sfTask.Error_Message__c;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> history = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                history.put('id', this.id);
            }else if(this.mId!=null){
                history.put('mId', this.mId);
            }

            if(String.isNotBlank(this.subject)){
                history.put('subject', this.subject);
            }
            if(actTime!=null){
                history.put('actTime', this.actTime);
            }

            if(String.isNotBlank(this.whatId)){
                history.put('whatId', this.whatId);
            }else if(this.wi_mId!=null){
                history.put('wi_mId', this.wi_mId);
            }

            if(String.isNotBlank(this.type)){
                history.put('type', this.type);
            }
            if(String.isNotBlank(this.errMsg)){
                history.put('errMsg', this.errMsg);
            }

            if(String.isNotBlank(this.respId)){
                history.put('respId', this.respId);
            }else if(this.resp_mId!=null){
                history.put('resp_mId', this.resp_mId);
            }

            return history;
        }

        public Task toSfTask(){
            Task task = new Task();
            task.Id = this.id;
            task.mId__c = this.mId;
            task.Mobile_Device_Id__c = generateExtId(this.mId);
            task.Subject = this.subject;
            task.Action_Date_Time__c = this.actTime;
            task.Status = 'Completed';
            
            if(String.isNotBlank(this.whatId)){
                task.WhatId = this.whatId;
            }else if(this.wi_mId!=null){
                task.WhatId = workItemIdMap.get(this.wi_mId);
            }
            
            if(String.isNotBlank(this.respId)){
                task.Response__c = this.respId;
            }else if(this.resp_mId!=null){
                task.Response__c = responseIdMap.get(this.resp_mId);
            }

            task.Type = this.type;
            return task;
        }
        
    }

    private class CollectionInstance{
        public String id;
        public String name;
        public String code;

        public CollectionInstance(){}

        public CollectionInstance(Collection_Instance__c sfCollectionInstance){
            this.id = sfCollectionInstance.Id;
            this.name = sfCollectionInstance.Name;
            this.code = sfCollectionInstance.Collection_Instance_Code__c;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> objMap = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                objMap.put('id', this.id);
            }
            if(String.isNotBlank(this.name)){
                objMap.put('name', this.name);
            }
            if(String.isNotBlank(this.code)){
                objMap.put('code', this.code);
            }
            return objMap;
        }
    }

    private class Util{
        public String name;
        public String value;

        public Util(String name, String value){
            this.name = name;
            this.value = value;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> util = new Map<String, Object>();
            util.put('name',name);
            util.put('value',value);
            return util;
        }
    }

    private class ContactRole{
        public String id;
        public Long mId;
        public Integer vers;
        public String cntId;
        public Long cnt_mId;
        public String uId;
        public Long uoi_mId;
        public String colId;
        public Boolean isPrimary;
        public String role;
        public String errMsg;
        
        public ContactRole(){}

        public ContactRole(Contact_Role__c sfContactRole){
            this.id = sfContactRole.Id;
            if(sfContactRole.mId__c!=null){
                this.mId = sfContactRole.mId__c.longValue();
            }
            if(sfContactRole.Version__c!=null){
                this.vers = sfContactRole.Version__c.intValue();
            }
            this.cntId = sfContactRole.Contact__c;
            if(sfContactRole.cnt_mId__c!=null){
                this.cnt_mId = sfContactRole.cnt_mId__c.longValue();
            }
            this.uId = sfContactRole.Unit_of_Interest_ID__c;
            if(sfContactRole.uoi_mId__c!=null){
                this.uoi_mId = sfContactRole.uoi_mId__c.longValue();
            }
            this.isPrimary = sfContactRole.Primary_Contact__c;
            this.role = sfContactRole.Role__c;
            this.errMsg = sfContactRole.Error_Message__c;
            this.colId  = sfContactRole.Collection__c;
        }
        
        public Map<String, Object> toMap(){
            Map<String, Object> objMap = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                objMap.put('id', this.id);
            }else if(mId!=null){
                objMap.put('mId', this.mId);
            }
            
            if(String.isNotBlank(this.cntId)){
                objMap.put('cntId', this.cntId);
            }else if(this.cnt_mId!=null){
                objMap.put('cnt_mId', this.cnt_mId);
            }

            if(String.isNotBlank(this.uId)){
                objMap.put('uId', this.uId);
            }else if(this.uoi_mId!=null){
                objMap.put('uoi_mId', this.uoi_mId);
            }

            if(this.vers!=null){
                objMap.put('vers', this.vers);
            }
            objMap.put('isPrimary', this.isPrimary);
            if(String.isNotBlank(this.role)){
                objMap.put('role', this.role);
            }
            if(String.isNotBlank(this.errMsg)){
                objMap.put('errMsg', this.errMsg);
            }
            if(String.isNotBlank(this.colId)){
                objMap.put('colId', this.colId);
            }

            return objMap;
        } 

        public Contact_Role__c toSfContactRole(){
            Contact_Role__c contactRole = new Contact_Role__c();
            contactRole.Id = this.id;
            contactRole.mId__c = this.mId;
            contactRole.Version__c = this.vers;
            contactRole.Mobile_Device_Id__c = generateExtId(this.mId);
            contactRole.Primary_Contact__c = this.isPrimary;
            contactRole.Role__c = this.role;
            contactRole.Collection__c = this.colId;

            if(String.isNotBlank(this.cntId)){
                contactRole.Contact__c = this.cntId;
            }else if(this.cnt_mId!=null && contactIdMap.containsKey(this.cnt_mId)){
                contactRole.Contact__c = contactIdMap.get(this.cnt_mId);
            }

            if(String.isNotBlank(this.uId)){
                contactRole.Unit_of_Interest_ID__c = this.uId;
            }else if(this.uoi_mId!=null && unitIdMap.containsKey(this.uoi_mId)){
                contactRole.Unit_of_Interest_ID__c = unitIdMap.get(this.uoi_mId);
            }

            contactRole.Unit_of_Interest_ID__c = this.uId;
            contactRole.uoi_mId__c = this.uoi_mId;

            return contactRole;
        }                   
    }

    private class ContactPerson{
        public String id;
        public Integer vers;
        public Long mId;
        public String fName;
        public String lName;
        public String email;
        public String phone;
        public String mobile;
        public String gender;
        public Integer age;
        public String errMsg;
        public String bestContact;
        public String dontContact;

        public ContactPerson(){}

        public ContactPerson(Contact sfContact){
            this.id = sfContact.Id;
            if(sfContact.mId__c!=null){
                this.mId = sfContact.mId__c.longValue();
            }
            if(sfContact.Version__c!=null){
                this.vers = sfContact.Version__c.intValue();
            }
            this.fName = sfContact.FirstName;
            this.lName = sfContact.LastName;
            this.email = sfContact.Email;
            this.phone = sfContact.Phone;
            this.mobile = sfContact.MobilePhone;
            this.gender = sfContact.Gender__c;
            if(sfContact.Age__c!=null){
                this.age = sfContact.Age__c.intValue();
            }
            this.errMsg = sfContact.Error_Message__c;
            this.bestContact = sfContact.Best_Time_To_Contact__c;
            this.dontContact = sfContact.Do_Not_Contact_Days__c;
        }

        public Map<String, Object> toMap(){
            Map<String, Object> objMap = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                objMap.put('id', this.id);
            }else if(this.mId!=null){
                objMap.put('mId', this.mId);
            } 
            
            if(this.vers!=null){
                objMap.put('vers', this.vers);
            }
            if(String.isNotBlank(this.fName)){
                objMap.put('fName', this.fName);
            }
            if(String.isNotBlank(this.lName)){
                objMap.put('lName', this.lName);
            }
            if(String.isNotBlank(this.email)){
                objMap.put('email', this.email);
            }
            if(String.isNotBlank(this.phone)){
                objMap.put('phone', this.phone);
            }
            if(String.isNotBlank(this.mobile)){
                objMap.put('mobile', this.mobile);
            }
            if(String.isNotBlank(this.gender)){
                objMap.put('gender', this.gender);
            }
            if(this.age!=null){
                objMap.put('age', this.age);
            }
            if(String.isNotBlank(this.errMsg)){
                objMap.put('errMsg', this.errMsg);
            }
            if(String.isNotBlank(this.bestContact)){
                objMap.put('bestContact', this.bestContact);
            }
            if(String.isNotBlank(this.dontContact)){
                objMap.put('dontContact', this.dontContact);
            }
            return objMap;
        }

        public Contact toSfContact(){
            Contact contact = new Contact();
            contact.Id = this.id;
            contact.Version__c = this.vers;
            contact.Mobile_Device_Id__c = generateExtId(this.mId);
            contact.mId__c = this.mId;
            contact.FirstName = this.fName;
            contact.LastName = this.lName;
            contact.Email = this.email;
            contact.Phone = this.phone;
            contact.MobilePhone = this.mobile;
            contact.Age__c = this.age;
            contact.Gender__c = this.gender;
            contact.Best_Time_To_Contact__c = this.bestContact;
            contact.Do_Not_Contact_Days__c = this.dontContact;
            return contact;
        }
    }

    private class EventItem{
        public String id;
        public Long mId;
        public Integer vers;
        public Long resp_mId;
        public String respId;
        public DateTime actTime;
        public String subject;
        public String whatId;
        public String errMsg;
        public Long wi_mId;
        public Integer reminder;

        public EventItem(){}

        public EventItem(Event sfEvent){
            this.id = sfEvent.Id;
            if(sfEvent.mId__c!=null){
                this.mId = sfEvent.mId__c.longValue();
            }
            if(sfEvent.Version__c!=null){
                this.vers = sfEvent.Version__c.intValue();
            }
            if(sfEvent.resp_mId__c!=null){
                this.resp_mId = sfEvent.resp_mId__c.longValue();
            }
            this.respId = sfEvent.Response__c;
            this.actTime = sfEvent.ActivityDateTime;
            this.subject = sfEvent.Subject;
            this.whatId = sfEvent.WhatId;
            this.errMsg = sfEvent.Error_Message__c;
            if(sfEvent.wi_mId__c!=null){
                this.wi_mId = sfEvent.wi_mId__c.longValue();
            }
            if(sfEvent.Reminder__c!=null){
            	this.reminder = sfEvent.Reminder__c.intValue();
            }
        }

        public Map<String, Object> toMap(){
            Map<String, Object> objMap = new Map<String, Object>();
            if(String.isNotBlank(this.id)){
                objMap.put('id', this.id);
            }else if(this.mId!=null){
                objMap.put('mId', this.mId);
            }

            if(String.isNotBlank(this.respId)){
                objMap.put('respId', this.respId);
            }else if(this.resp_mId!=null){
                objMap.put('resp_mId', this.resp_mId);
            }

            if(String.isNotBlank(this.whatId)){
                objMap.put('whatId', this.whatId);
            }else if(this.wi_mId!=null){
                objMap.put('wi_mId', this.wi_mId);
            }

            if(this.actTime!=null){
                objMap.put('actTime', this.actTime);
            }
            if(String.isNotBlank(this.subject)){
                objMap.put('subject', this.subject);
            }
            if(String.isNotBlank(this.errMsg)){
                objMap.put('errMsg', this.errMsg);
            }
            if(this.reminder!=null){
                objMap.put('reminder', this.reminder);
            }
            return objMap;
        }

        public Event toSfEvent(){
            Event event = new Event();
            event.Id = this.id;
            event.mId__c = this.mId;
            event.Version__c = this.vers;
            event.Mobile_Device_Id__c = generateExtId(this.mId);
            
            if(String.isNotBlank(this.respId)){
                event.Response__c = this.respId;
            }else if(this.resp_mId!=null && responseIdMap.containsKey(this.resp_mId)){
                event.Response__c = responseIdMap.get(this.resp_mId);
            }
            event.resp_mId__c = this.resp_mId;

            event.ActivityDateTime = this.actTime;
            if(String.isNotBlank(this.subject)){
                event.Subject = this.subject;
            }else{
                event.Subject = 'Appointment';
            }

            if(systemSettings!=null && systemSettings.containsKey('social.event.defaultDuration')){
                event.DurationInMinutes = Integer.valueOf(systemSettings.get('social.event.defaultDuration').Value__c);
            }else{
                event.DurationInMinutes = 60;
            }

            if(String.isNotBlank(this.whatId)){
                event.WhatId = this.whatId;
            }else if(this.wi_mId!=null && workitemIdMap.containsKey(this.wi_mId)){
                event.WhatId = workitemIdMap.get(this.wi_mId);
            }
            event.wi_mId__c = this.wi_mId;
            event.Reminder__c = this.reminder;

            return event;
        }
    }
}