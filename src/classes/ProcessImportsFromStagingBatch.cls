/**
* @description   This class is called from ProcessStagingElementsExCon to Process Staging Element records to Create Units and Responses
* @author      Ram Veligeti
* @date    24.07.2015
*/
global class ProcessImportsFromStagingBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global final string Query;
    global Collection_Instance__c collectionInstance;
    private Map<String, SystemSettings__c> systemSettings;
    global Set<String> uniqueContact;
    global Map<String,String> contactExtIdMap;

    //Controller
    global ProcessImportsFromStagingBatch(Id collectionInstanceId){
        collectionInstance = [select
                Collection_Instance_Code__c,
                Collection__c,
                RecordType.Name,
                Sample_Size__c,
                Collection__r.Collection_Code__c,
                Collection__r.RecordType.Name,
                Primary_Mode__c,
                Delivery_Mode__c,
                Grouping__c,
                Grouping__r.GR_1_Label__c,
                Grouping__r.GR_2_Label__c,
                Grouping__r.GR_3_Label__c,
                Grouping__r.GR_4_Label__c,
                Grouping__r.GR_5_Label__c,
                Grouping__r.GR_6_Label__c,
                Grouping__r.GR_7_Label__c,
                Grouping__r.GR_8_Label__c,
                Grouping__r.GR_9_Label__c,
                Grouping__r.GR_10_Label__c,
                Contextual_Mappings__c,
                Contextual_Mappings__r.CO_1_Label__c,
                Contextual_Mappings__r.CO_2_Label__c,
                Contextual_Mappings__r.CO_3_Label__c,
                Contextual_Mappings__r.CO_4_Label__c,
                Contextual_Mappings__r.CO_5_Label__c,
                Contextual_Mappings__r.CO_6_Label__c,
                Contextual_Mappings__r.CO_7_Label__c,
                Contextual_Mappings__r.CO_8_Label__c,
                Contextual_Mappings__r.CO_9_Label__c,
                Contextual_Mappings__r.CO_10_Label__c,
                Contextual_Mappings__r.CO_11_Label__c,
                Contextual_Mappings__r.CO_12_Label__c,
                Contextual_Mappings__r.CO_13_Label__c,
                Contextual_Mappings__r.CO_14_Label__c,
                Contextual_Mappings__r.CO_15_Label__c
            from Collection_Instance__c
            where Id = :collectionInstanceId
        ];

        systemSettings = SystemSettings__c.getAll();

        //Query Staging Elements
        Map<String,SObjectField> stagingfieldMap = Staging_Element__c.sObjectType.getDescribe().fields.getMap();
        String stagingFieldNames = ApexUtility.getFieldNamesOfSObject(stagingfieldMap, true);
        
        query = 'select '
            + stagingFieldNames
            + ' from Staging_Element__c where Failed__c = false and CI_Collection_Instance_Code__c = \''
            + collectionInstance.Collection_Instance_Code__c
            + '\' order by R_Unit_Association__c, Collection_Unit__c desc';
        
        uniqueContact = new Set<String>();
        contactExtIdMap = new Map<String,String>();

    }

    //Start
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    //Execute
    global void execute(Database.BatchableContext BC, List<Staging_Element__c> scope) {
        System.debug('Started processing batch');
        Map<Id, Staging_Element__c> stagingElements = new Map<Id, Staging_Element__c>();
        for(Staging_Element__c stagingElement:scope){
            assignLegacyContactId(stagingElement);
            stagingElements.put(stagingElement.Id, stagingElement);
        }
        // flag to turn on trigger calculations
        Boolean runCalculations = true;
        StagingElementUtils staginElementUtils = new StagingElementUtils(runCalculations);
        staginElementUtils.processStagingElements(stagingElements, collectionInstance);
    }

    //Finish
    global void finish(Database.BatchableContext BC){

        // Request an external system to generate a Short URL based on the collection code.
        // Do it first, so we can do it inline, instead of future
        // future is not allowed under a batch job
        try {
            Collection_Instance__c instanceWithCode = [
                select Collection_Instance_Code__c, Collection__r.Collection_Code__c
                from Collection_Instance__c
                where Id = :collectionInstance.Id
            ];
            
            List<Artefact__c> instruments = [
                select Id
                from Artefact__c 
                where Status__c = 'active'
                and RecordType.Name = 'Instrument'
                and Collection_Modes__c includes ('CAWI')
                and Collection__r.RecordType.Name = 'Collections'
                and Collection__r.Collection_Code__c = :instanceWithCode.Collection__r.Collection_Code__c
            ];
            
            if (!instruments.isEmpty()) {
                ShortUrlClient.RequestShortUrlInline(collectionInstance.Id, 0);
            }
        }
        catch(Exception e) {
        }

        // logic added by Eric for response rate reporting
        // at the end of the processing, update the total batchsize

        // was going to use a stateful variable to track the batch size, however
        // we allow reloading, and also we allow updates of sample details
        // in such case, the update size could varies... as a result, the total batch size based
        // on the batch load is incorrect

        // this is very ugly... however, until we have a way to separate logic on census and business
        
        if(collectionInstance.RecordType.Name.equalsIgnoreCase('census')){
            // with census, total size is the number of primary dwelling response
            // for now... we don't care about census
        } else {
            // this is business survey instance
            // RUN BATCH
            Database.executeBatch(new CountResponsesBatch(collectionInstance.Id,true,true,true,true), 2000); 
        
        }
        
    }

    /**
    * @description this method handles duplicate contact records in the sample file. I
                    It doesn't handle de-dup logic in salesforce. It is just about avoid duplicate records from sample file
    * @param stagingElement 
    */
    private void assignLegacyContactId(Staging_Element__c stagingElement){
        if(String.isNotBlank(stagingElement.C_FirstName__c) && String.isNotBlank(stagingElement.C_LastName__c)){
            Boolean contains = false;
            String email = (stagingElement.C_FirstName__c+stagingElement.C_LastName__c+stagingElement.C_Email__c).trim().toLowerCase();
            String phone = (stagingElement.C_FirstName__c+stagingElement.C_LastName__c+stagingElement.C_Phone__c).trim().toLowerCase();
            String otherPhone = (stagingElement.C_FirstName__c+stagingElement.C_LastName__c+stagingElement.C_Other_Phone__c).trim().toLowerCase();

            //Duplicate contact check
            if((String.isNotBlank(stagingElement.C_Email__c) && uniqueContact.contains(email)) ||
                (String.isNotBlank(stagingElement.C_Phone__c) && uniqueContact.contains(phone)) ||
                (String.isNotBlank(stagingElement.C_Other_Phone__c) && uniqueContact.contains(otherPhone))){
                contains = true;
                if(contactExtIdMap.containsKey(email)){
                    stagingElement.C_Legacy_Contact_ID__c = contactExtIdMap.get(email);
                }else if(contactExtIdMap.containsKey(phone)){
                    stagingElement.C_Legacy_Contact_ID__c = contactExtIdMap.get(phone);
                }else if(contactExtIdMap.containsKey(otherPhone)){
                    stagingElement.C_Legacy_Contact_ID__c = contactExtIdMap.get(otherPhone);
                }
            }

            if(!contains){
                stagingElement.C_Legacy_Contact_ID__c = ApexUtility.GUID();
                stagingElement.Account_External_Id__c = ApexUtility.GUID();
                 if(Logger.isEnabled()){
                System.debug('For contact first name, last name,company,phone and email = '+stagingElement.C_FirstName__c+','+stagingElement.C_LastName__c+','+stagingElement.C_Company_Name__c+','+stagingElement.C_Phone__c+'and'+stagingElement.C_Email__c); 
                System.debug('Legacy contact ID'+stagingElement.C_Legacy_Contact_ID__c);
                System.debug('Account External Id'+stagingElement.Account_External_Id__c);
                }
                if(String.isNotBlank(stagingElement.C_Email__c)){
                    uniqueContact.add(email);
                    contactExtIdMap.put(email,stagingElement.C_Legacy_Contact_ID__c);
                }
                if(String.isNotBlank(stagingElement.C_Phone__c)){
                    uniqueContact.add(phone);
                    contactExtIdMap.put(phone,stagingElement.C_Legacy_Contact_ID__c);
                }
                if(String.isNotBlank(stagingElement.C_Other_Phone__c)){
                    uniqueContact.add(otherPhone);
                    contactExtIdMap.put(otherPhone,stagingElement.C_Legacy_Contact_ID__c);
                }
            }
        }
    }
}