/**
 * @description     Test Data Helper class to generate dummy data for all objects, methods should be added as the
 *                  data model expands to ensure that all creation of dummy data is included here rather than siloed
 *                  in individual testMethods
 * @author          Fronde
 * @date            27.Feb.2015
 *
 * Amendment       ECP-3007  Added assignment of Enquiry_Origin for Work item creation.
  * date            07.Oct.2016
  * 
  */
@isTest
public class TestDataHelper {
    /**
     * @description     Creates a Dummy Unit record
     * @author          Fronde
     * @date            27.02.2015
     * @param           withInsert Should the record be inserted at time of creation
     * @param           workloadId Id of the workload the unit should be created against
     * @return          Unit__c
     */
    public static Unit__c createUnit(Boolean withInsert){
        SmartFactory.FillAllFields = true;

        Map<String, Object> unitValues = new Map<String, Object> {
            'Road_Number__c' => '1234',
            'Road_Name__c' => 'road name',
            'Road_Type__c' => 'Street',
            'Town_or_city__c' => 'town',
            'Postcode__c' => '1234',
            'Other_Address_Type__c' => null,
            'Rural_Delivery_Number__c' => null,
            'P_O_Box__c' => null,
            'Meshblock_Code__c' => '12',
            'NZBN__c' => '12',
            'DP_ID__c' => '12',
            'Mobile_Device_Id__c' => null,
            'Created_From_Unit_Id__c' => null,
            'Easting__c' => '42',
            'Northing__c' => '43',
            'Website__c' => 'abc.com'
        };
        Unit__c unit = (Unit__c) SmartFactory.createSObject('Unit__c', unitValues);

        unit.Mobile_Device_Id__c = null;

        if (withInsert) {
            upsert unit;
        }

        SmartFactory.FillAllFields = true;
        return unit;
    }

    /**
     * @description     Creates a Dummy Workload record
     * @author          Fronde
     * @date            27.02.2015
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Workload__c
     */
    public static Workload__c createWorkLoad(Boolean withInsert){
        SmartFactory.FillAllFields = true;

        Map<String, Object> workLoadValues = new Map<String, Object> {};
        Workload__c workload= (Workload__c)SmartFactory.createSObject('Workload__c', workloadValues);

        if (withInsert) {
            insert workload;
        }

        SmartFactory.FillAllFields = true;
        return workload;
    }

    /**
     * @description     Creates a Dummy Account record
     * @author          Fronde
     * @date            27.02.2015
     * @param           accountName The name of the account to be created
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Account
     */
    public static Account createAccount(String accountName, Boolean withInsert) {
        SmartFactory.FillAllFields = true;

        Map<String, Object> accValues = new Map<String, Object> {
            'Name' => accountName
        };
        Account account = (Account)SmartFactory.createSObject('Account', accValues);

        if (withInsert) {
            insert account;
        }

        SmartFactory.FillAllFields = false;
        return account;
    }

    /**
     * @description     Creates a Dummy Contact record
     * @author          Fronde
     * @date            27.02.2015
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Contact
     */
    //TODO Add Account Id Parameter so that the contact is created associated to an Account
    public static Contact createContact(Boolean withInsert) {
        SmartFactory.FillAllFields = true;

        Map<String, Object> contactValues = new Map<String, Object> {
            'MailingCountry' => 'Viet Nam',
            'OtherCountry' => 'Viet Nam',
            'Address_ID__c' => '10',
            'Box_Bag_Number__c' => NULL,
            'Delivery_Service_Type__c' => NULL,
            'Postcode__c' => '10',
            'Rural_Delivery_Number__c' => NULL,
            'Road_Number__c' => '10',
            'Phone' => '+64 (000) 0000000',
            'HomePhone' => '+64 (000) 0000000',
            'MobilePhone' => '+64 (000) 0000000',
            'Alt_Phone_Ext__c' => NULL,
            'Main_Phone_Ext__c' => NULL,
			'Town_or_City__c' => 'Auckland'
        };

        Contact contact = (Contact)SmartFactory.createSObject('Contact', contactValues);
        if (withInsert) {
            insert contact;
        }

        SmartFactory.FillAllFields = false;
        return contact;
    }
   
    
    /**
     * @description     Select all fields from Contact record
     * @author          Fronde
     * @date            18.05.2015
     * @param           contact Id
     * @return          Contact
     */
    public static Contact[] selectContact(Id contactId){
        Map<String, Schema.SObjectField> fldObjMap = schema.SObjectType.Contact.fields.getMap();
        List<Schema.SObjectField> fldObjMapValues = fldObjMap.values();

        String theQuery = 'SELECT ';
        for(Schema.SObjectField s : fldObjMapValues)
        {
           String theName = s.getDescribe().getName();
           theQuery += theName + ',';
        }

        // Trim last comma
        theQuery = theQuery.subString(0, theQuery.length() - 1);

        
        theQuery += ' FROM Contact';
        if(String.isNotBlank(contactId)){
            theQuery += ' WHERE Id=\''+contactId+'\'';
        }

        return Database.query(theQuery);
    }

    /**
     * @description     Creates a Dummy Task record
     * @author          Fronde
     * @date            27.02.2015
     * @param           whatId the Id of the associated object
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Task
     */
    public static Task createTask(Id whatId, Boolean withInsert) {
        SmartFactory.FillAllFields = false;

        Map<String, Object> tsValues = new Map<String, Object> {
            'whatId' => whatId
        };
        Task task = (Task) SmartFactory.createSObject('Task',tsValues);

        if (withInsert) {
            insert task;
        }

        SmartFactory.FillAllFields = false;
        return task;
    }

    /**
     * @description     Creates a Dummy Event record
     * @author          Fronde
     * @date            27.02.2015
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Event
     */
    public static Event createEvent(Boolean withInsert) {
        SmartFactory.FillAllFields = false;
        Map<String, Object> evtValues = new Map<String, Object> {
            'Subject' => 'test event subject',
            'StartDateTime' => Datetime.now(),
            'EndDateTime' => Datetime.now()
        };
        Event event = (Event) SmartFactory.createSObject('Event', evtValues);

        if (withInsert) {
            insert event;
        }

        SmartFactory.FillAllFields = false;
        return event;
    }

    /**
     * @description     Creates a Dummy Event record
     * @author          Fronde
     * @date            27.02.2015
     * @param           whatId the Id of the associated object
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Event
     */
    public static Event createEvent(Id whatId, Boolean withInsert) {
        SmartFactory.FillAllFields = false;

        Map<String, Object> evtValues = new Map<String, Object> {
            'Subject' => 'test event subject',
            'StartDateTime' => Datetime.now(),
            'EndDateTime' => Datetime.now(),
            'whatId' => whatId
        };
        Event event = (Event) SmartFactory.createSObject('Event', evtValues);
        if (withInsert) {
            insert event;
        }

        SmartFactory.FillAllFields = false;
        return event;
    }

    /**
     * @description     Creates a Dummy User record
     * @author          Fronde
     * @date            27.02.2015
     * @param           usernameEmail Username and email for the dummy record
     * @param           profileName Name of the profile to associate the user with
     * @param           withInsert Should the record be inserted at time of creation
     * @return          User
     */
    public static User createUser(String usernameEmail, String profileName, Boolean withInsert) {
        User u = new User();
        Profile p = [SELECT Id FROM profile WHERE name=:profileName];
        u.username = usernameEmail;
        u.email = usernameEmail;
        u.lastName = usernameEmail;
        u.firstName = usernameEmail;
        String alias = usernameEmail;
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_NZ';
        u.emailEncodingKey = 'ISO-8859-1';
        u.timeZoneSidKey = 'Pacific/Auckland';
        u.profileId = p.Id;
        if (withInsert) {
            insert u;
        }
        return u;
    }

    /**
     * @description     Creates a Test Collection Record
     * @author          G. Knight
     * @date            27.02.2015
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Collection__c
     */
    public static Collection__c createCollection(Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> colValues = new Map<String, Object> {
                                                'Help_for_Survey_Participants__c' => null,
                                                'Browse_for_Statistics__c' => null
                                        };
        Collection__c collection = (Collection__c) SmartFactory.createSObject('Collection__c', colValues);
        if (withInsert) {
            insert collection;
        }
        SmartFactory.FillAllFields = true;
        return collection;
    }

    /**
     * @description     Creates a Test Collection Instance Record
     * @author          G. Knight
     * @date            27.02.2015
     * @param           collectionId the Id of the associated collection
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Collection_Instance__c
     */
    public static Collection_Instance__c createCollectionInstance(Id collectionId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> ciValues = new Map<String, Object> {
                                                'Collection__c' => collectionId,
                                                    'Target_Response_Type__c' => null
                                        };
        Collection_Instance__c collectionInstance = (Collection_Instance__c)SmartFactory.createSObject('Collection_Instance__c', ciValues);
        collectionInstance.Planned_Start_Date__c = system.today().addDays(-10);
        collectionInstance.Planned_End_Date__c = system.today().addDays(100);
        collectionInstance.Extension_Cut_off_Date__c = system.today().addDays(50);
        collectionInstance.Actual_Start_Date__c = system.today().addDays(2);
        collectionInstance.Actual_End_Date__c = system.today().addDays(90);
        collectionInstance.Actual_Close_Off__c = system.today().addDays(8);
        collectionInstance.Collection_Instance_Priority__c = 9;
        collectionInstance.Behavioural_Weighting__c = 70;
        collectionInstance.Statistical_Weighting__c = 30;
        collectionInstance.Batch_Job_ID__c=null;
        collectionInstance.Reference_Period__c = '201803';
        if (withInsert) {
            insert collectionInstance;
        }
        SmartFactory.FillAllFields = true;
        return collectionInstance;
    }

    /**
     * @description     Creates a Test Artefact Record
     * @author          G. Knight
     * @date            27.02.2015
     * @param           collectionId the Id of the associated collection
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Artefact__c
     **/
    public static Artefact__c createArtefact(Id collectionId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> artefactValues = new Map<String, Object> {
                                                'Collection__c' => collectionId
                                        };
        Artefact__c artefact = (Artefact__c)SmartFactory.createSObject('Artefact__c', artefactValues);
        if (withInsert) {
            insert artefact;
        }
        SmartFactory.FillAllFields = true;
        return artefact;
    }

    public static Response_Rate__c createResponseRate(Id collectionId, Id groupingId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> responseRateValues = new Map<String, Object> {
                                                'Collection__c' => collectionId,
                                                    'Grouping__c' => groupingId,
                                                    'Active__c' => true
                                        };
        Response_Rate__c responseRate = (Response_Rate__c)SmartFactory.createSObject('Response_Rate__c', responseRateValues);
        if (withInsert) {
            insert responseRate;
        }
        SmartFactory.FillAllFields = true;
        return responseRate;
    }

    /**
     * @description     Creates a Test Staging Element Record
     * @author          S. Yakovlev
     * @date            24.03.2015
     * @param           collectionInstanceCode the External Id of the associated collection instance
     * @param           dpid the External Id of the associated unit of interets instance
     * @return          Staging_Element__c
     */
    public static Staging_Element__c createStagingElement(Boolean withInsert) {

        SmartFactory.FillAllFields = true;
        Map<String, Object> imValues = new Map<String, Object> {
                                                'U_Postcode__c' => '1234',
                                                    'R_Delivery_Postcode__c' => '1234',
                                                    'U_Road_Number__c' => '42',
                                                    'R_Delivery_Road_Number__c' => '42',
                                                    'U_NZBN__c' => '12',
                                                    'U_Rural_Delivery_Number__c' => null,
                                                    'U_P_O_Box__c' => null,
                                                    'U_KAU_Id__c' => null,
                                                    'R_Delivery_Rural_Delivery_Number__c'=> null,
                                                    'C_Address_Id__c' => '12',
                                                    'C_Box_Bag_Number__c' => null,
                                                    'C_Postcode__c' => '12',
                                                    'C_Rural_Delivery_Number__c'=> null,
                                                    'C_Delivery_Service_Type__c'=> '12',
                                                    'C_Road_Number__c'=> null,
                                                    'C_Unit_Number__c'=> null,
                                                    'C_Unit_Type__c' => null,
                                                    'C_Road_Name__c' => null,
                                                    'C_Address_ID__c'=> null,
                                                    'U_Other_Address_Type__c' => null,
                                                    'WI_Work_Item_Type__c' => 'Address canvassing',
                                                    'U_Website__c' => 'test.com',
                                                    'R_Unit_Delivery_Mode__c' => null
                                        };
        Staging_Element__c stagingElement = (Staging_Element__c)SmartFactory.createSObject('Staging_Element__c', imValues);
        stagingElement.workload_ownerid__c = null;
        stagingElement.wi_workitem_id__c=null;
        if (withInsert) {
            insert stagingElement;
        }
        SmartFactory.FillAllFields = true;
        return stagingElement;
    }

    /**
     * @description     Creates a Test Activity Schedule Instance Record
     * @author          R. Veligeti
     * @date            7.04.2015
     * @param           collectionInstanceId the Id of the associated Collection Instance
     * @param           workItemTypeId the Id of the associated Work Item Type
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Activity_Schedule__c
     */
    public static Activity_Schedule__c createActivitySchedule(Id collectionInstanceId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> asValues = new Map<String, Object> {
            'Collection_Instance__c' => collectionInstanceId,
                'Occurrence__c'      => 1
        };

        Activity_Schedule__c activitySchedule = (Activity_Schedule__c)SmartFactory.createSObject('Activity_Schedule__c', asValues);
        activitySchedule.Scheduled_Date_time__c = system.now().addDays(10);
        if (withInsert) {
            insert activitySchedule;
        }
        SmartFactory.FillAllFields = true;
        return activitySchedule;
    }

    /**
     * @description     Creates a Test Response Instance Record
     * @author          R. Veligeti
     * @date            7.04.2015
     * @param           collectionInstanceId the Id of the associated Collection Instance
     * @param           contactId the Id of the associated Contact
     * @param           contactRoleId the Id of the associated Contact Role
     * @param           unitOfInterestId the Id of the associated Unit of Interest
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Response__c
     */
    public static Response__c createResponse(Id collectionInstanceId, Id contactId, Id contactRoleId, Id unitOfInterestId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;

        Map<String, Object> resValues = new Map<String, Object> {
            'Collection_Instance__c' => collectionInstanceId,
            'Contact__c' => contactId,
            'Unit_of_Interest__c' => unitOfInterestId,
            'Behavioural_Priority__c' => 9,
            'Statistical_Priority__c' => 9,
            'Delivery_Rural_Delivery_Number__c' => NULL,
            'Mobile_Device_Id__c'=>null,
            'Extension_Date__c' => system.today(),
            'Created_From_Response_Id__c' => null,
            'Overall_Priority_Factor__c' => 1
        };

        Response__c response = (Response__c)SmartFactory.createSObject('Response__c', resValues);
        response.Access_Code__c = null;
        response.Response_ExtId__c = null;
        response.Delivery_Rural_Delivery_Number__c = null;
        response.Delivery_Postcode__c = '12';
        response.Delivery_Road_Number__c = '12';
        response.Unit_Priority__c = 1;
        response.Box_Bag_Number__c = null;
        response.Delivery_Service_Type__c = null;
        response.Mobile_Device_Id__c=null;
        response.Extension_Date__c = null;

        if (withInsert) {
            insert response;
        }

        SmartFactory.FillAllFields = true;
        return response;
    }

    /**
     * @description     Creates a Test Work Load Instance Record
     * @author          R. Veligeti
     * @date            9.04.2015
     * @param           collectionInstanceId the Id of the associated Collection Instance
     * @param           modeId the Id of the associate Mode
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Workload__c
     */
    public static Workload__c createWorkLoad(Id collectionInstanceId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wlValues = new Map<String, Object> {
                'Collection_Instance__c' => collectionInstanceId,
                'Workload_ID__c' => NULL
        };
        Workload__c workLoad = (Workload__c)SmartFactory.createSObject('Workload__c',wlValues);
        if (withInsert) {
            insert workLoad;
        }
        SmartFactory.FillAllFields = true;
        return workLoad;
    }

    /**
     * @description     Creates a Test Work Item Instance Record
     * @author          R. Veligeti
     * @date            9.04.2015
     * @param           activityScheduleId the Id of the associated Activity Schedule
     * @param           colInstanceInstModeId the Id of the associated Collection Instance Instrument Mode
     * @param           contactId the Id of the associated Contact
     * @param           modeId the Id of the associated Mode
     * @param           caseId the Id of the associated Case
     * @param           responseId the Id of the associated Response
     * @param           workLoadId the Id of the associated Work Load
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Response__c
     */
    public static Work_Item__c createWorkItem(Id activityScheduleId, Id contactId, Id caseId, Id responseId, Id workLoadId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Activity_Schedule__c' => activityScheduleId,
                'Contact__c' => contactId,
                'Related_Case__c' => caseId,
                'Response__c' => responseId,
                'Workload__c' => workLoadId,
                'Mobile_Device_Id__c'=>null,
                'Created_From_Work_Item_Id__c' => null,
                'Work_Item_Type__c' => 'Address canvassing'
        };

        Work_Item__c workItem = (Work_Item__c)SmartFactory.createSObject('Work_Item__c', wiValues);
        workItem.Mobile_Device_Id__c=null;
        WorkItem.Enquiry_Origin__c = null;
		workItem.recordTypeId = Work_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business').getRecordTypeId();
        if (withInsert) {
            insert workItem;
        }
        SmartFactory.FillAllFields = true;
        return workItem;
    }

    /**
     * @description     Creates a Test Activity Schedule Filter Instance Record
     * @author          R. Veligeti
     * @date            6.05.2015
     * @param           activityScheduleId the Id of the associated Activity Schedule
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Activity_Schedule_Filter__c
     */
    public static Activity_Schedule_Filter__c createActivityScheduleFilter(Id activityScheduleId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Activity_Schedule__c' => activityScheduleId,
                'Scheduled_Date_time__c' => System.now().addDays(10)
        };

        Activity_Schedule_Filter__c actSch = (Activity_Schedule_Filter__c)SmartFactory.createSObject('Activity_Schedule_Filter__c', wiValues);
        if (withInsert) {
            insert actSch;
        }
        SmartFactory.FillAllFields = true;
        return actSch;
    }

    /**
     * @description     Creates a Test Pack Instance Record
     * @author          R. Veligeti
     * @date            23.07.2015
     * @param           activityScheduleId the Id of the associated Activity Schedule
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Pack__c
     */
    public static Pack__c createPack(Id collectionId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Collection__c' => collectionId
        };

        Pack__c pack = (Pack__c)SmartFactory.createSObject('Pack__c', wiValues);
        if (withInsert) {
            insert pack;
        }
        SmartFactory.FillAllFields = true;
        return pack;
    }

    public static Pack_Contents__c createPackContents(Id packId, Id artefactId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Pack__c' => packId,
                    'Artefact__c'=> artefactId,
                    'Number_of_Copies__c'=> 1
        };

        Pack_Contents__c packCon = (Pack_Contents__c)SmartFactory.createSObject('Pack_Contents__c', wiValues);
        if (withInsert) {
            insert packCon;
        }
        SmartFactory.FillAllFields = true;
        return packCon;
    }

    public static Grouping__c createGroupings(Id collectionId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Collection__c' => collectionId,
                    'Active__c'=> true
        };

        Grouping__c grouping = (Grouping__c)SmartFactory.createSObject('Grouping__c', wiValues);
        if (withInsert) {
            insert grouping;
        }
        SmartFactory.FillAllFields = true;
        return grouping;
    }

    public static Contextual_Mappings__c createContextualMappings(Id collectionId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
                'Collection__c' => collectionId,
                    'Active__c'=> true
        };

        Contextual_Mappings__c context = (Contextual_Mappings__c)SmartFactory.createSObject('Contextual_Mappings__c', wiValues);
        if (withInsert) {
            insert context;
        }
        SmartFactory.FillAllFields = true;
        return context;
    }

    public static Skillset__c createSkillset(Id collectionId, Id userId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> skValues = new Map<String, Object> {
            'Collection__c' => collectionId,
                'User_Name__c' => userId
        };

        Skillset__c skill = (Skillset__c)SmartFactory.createSObject('Skillset__c', skValues);
        if (withInsert) {
            insert skill;
        }
        SmartFactory.FillAllFields = true;
        return skill;
    }

    public static Mark_In_Request__c createMarkInRequest(Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> mirValues = new Map<String, Object> {};

        Mark_In_Request__c markInRequest = (Mark_In_Request__c)SmartFactory.createSObject('Mark_In_Request__c', mirValues);
        markInRequest.Mark_in_DF_Check__c=null;
        if (withInsert) {
            insert markInRequest;
        }
        SmartFactory.FillAllFields = true;
        return markInRequest;
    }

    public static DAC_Store__c createDac(Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> dacValues = new Map<String, Object> {};

        DAC_Store__c dac = (DAC_Store__c)SmartFactory.createSObject('DAC_Store__c', dacValues);
        if (withInsert) {
            insert dac;
        }
        SmartFactory.FillAllFields = true;
        return dac;
    }

    public static Case createCase(Id collectionInstanceId,Boolean withInsert){
        SmartFactory.FillAllFields = true;

        Map<String, Object> caseValues = new Map<String, Object> {
                                                'Collection_Instance__c' => collectionInstanceId
                                        };
        Case cs= (Case)SmartFactory.createSObject('Case', caseValues);
        if (withInsert) {
            insert cs;
        }
        SmartFactory.FillAllFields = true;
        return cs;
    }

    /**
     * @description     Creates a Test Contact Role Instance Record
     * @author          R. Veligeti
     * @date            19.05.2015
     * @param           collectionId the Id of the associated Collection
     * @param           unitOfInterestId the Id of the associated Unit of Interest
     * @param           contactId the Id of the associated Contact
     * @param           withInsert Should the record be inserted at time of creation
     * @return          Contact_Role__c
     */
    public static Contact_Role__c createContactRole(Id collectionId, Id unitOfInterestId, Id contactId, Boolean withInsert) {
        SmartFactory.FillAllFields = true;
        Map<String, Object> wiValues = new Map<String, Object> {
            'Collection__c' => collectionId,
            'Unit_of_Interest_ID__c' => unitOfInterestId,
            'Contact__c' => contactId
        };

        Contact_Role__c contRole = (Contact_Role__c)SmartFactory.createSObject('Contact_Role__c', wiValues);
        if (withInsert) {
            insert contRole;
        }
        SmartFactory.FillAllFields = true;
        return contRole;
    }

    /**
     * @description     Creates a Custom Settings
     * @author          S. Yakovlev
     * @date            15.04.2015
     */
    public static void createResponseProperties() {
        List<Response_API_Properties__c> props = new List<Response_API_Properties__c>();

        Response_API_Properties__c p1 = new Response_API_Properties__c();
        p1.Name = ' activity.status.closed';
        p1.Value__c = 'Completed';
        props.add(p1);

        Response_API_Properties__c p2 = new Response_API_Properties__c();
        p2.Name = 'error.folder.name';
        p2.Value__c = 'API Errors';
        props.add(p2);

        Response_API_Properties__c p3 = new Response_API_Properties__c();
        p3.Name = 'response.status.closed';
        p3.Value__c = 'Completed';
        props.add(p3);

        Response_API_Properties__c p4 = new Response_API_Properties__c();
        p4.Name = 'workitem.status.closed';
        p4.Value__c = 'Completed';
        props.add(p4);

        insert props;
    }

    /**
     * @description     Creates a Custom Settings
     * @author          S. Yakovlev
     * @date            17.03.2016
     */
    public static void createSystemSettings() {
        List<SystemSettings__c> ss = new List<SystemSettings__c>();

        SystemSettings__c s1 = new SystemSettings__c();
        s1.Name = 'errorLog.sync.TTL';
        s1.Value__c = '30';
        ss.add(s1);

        SystemSettings__c s2 = new SystemSettings__c();
        s2.Name = 'social.event.defaultDuration';
        s2.Value__c = '60';
        ss.add(s2);

        SystemSettings__c s3 = new SystemSettings__c();
        s3.Name = 'workItemExtract.notificationEmail';
        s3.Value__c = 'test@test.test';
        ss.add(s3);

        insert ss;
    }

    /**
     * @description     Creates a Custom Settings for Wrapup Codes
     * @author          R. Veligeti
     * @date            02.07.2015
     */
    public static void createWrapupCodes(){
        List<Wrapup_Codes__c> wrapupCodesList = new List<Wrapup_Codes__c>();

        Wrapup_Codes__c wc = new Wrapup_Codes__c();
        wc.Name = '1';
        wc.Delivery_Mode__c = 'Call';
        wc.Work_Item_Type__c = 'Pre-notification';
        wc.Core_Result__c = 'No Contact made';
        wc.Outcome__c = 'Call back required';
        wc.Action__c = 'Send email';
        wc.Default_Call_Back_Time__c = '1 day';
        wc.Create_Event__c = true;
        wc.Follow_up_Work_Item_Type__c = 'Pre-notification';
        wrapupCodesList.add(wc);

        Wrapup_Codes__c wc1 = new Wrapup_Codes__c();
        wc1.Name = '2';
        wc1.Delivery_Mode__c = 'Call';
        wc1.Work_Item_Type__c = 'Pre-notification';
        wc1.Core_Result__c = 'No Contact made';
        wc1.Outcome__c = 'Call back required';
        wc1.Action__c = 'Send fax';
        wc1.Default_Call_Back_Time__c = '1 hour';
        wc1.Create_Event__c = true;
        wc1.Follow_up_Work_Item_Type__c = 'Pre-notification';
        wrapupCodesList.add(wc1);

        Wrapup_Codes__c wc2 = new Wrapup_Codes__c();
        wc2.Name = '3';
        wc2.Delivery_Mode__c = 'Call';
        wc2.Work_Item_Type__c = 'Pre-notification';
        wc2.Core_Result__c = 'No Contact made';
        wc2.Outcome__c = 'Call back not required';
        wc2.Action__c = 'Send fax';
        wc2.Default_Call_Back_Time__c = 'Day after set extension date';
        wc2.Create_Event__c = true;
        wc2.Follow_up_Work_Item_Type__c = 'Pre-notification';
        wrapupCodesList.add(wc2);

        Wrapup_Codes__c wc3 = new Wrapup_Codes__c();
        wc3.Name = '4';
        wc3.Delivery_Mode__c = 'Call';
        wc3.Work_Item_Type__c = 'Pre-notification';
        wc3.Core_Result__c = 'No Contact made';
        wc3.Outcome__c = 'Call back required';
        wc3.Action__c = 'Send post';
        wc3.Default_Call_Back_Time__c = '1 min';
        wc3.Create_Event__c = true;
        wc3.Follow_up_Work_Item_Type__c = 'Pre-notification';
        wrapupCodesList.add(wc3);

        insert wrapupCodesList;
    }

    public static void createDataSet(){
        TestDataHelper.createSystemSettings();

        System_Update__c su = System_Update__c.getOrgDefaults();
        su.Execute__c = true;
        upsert su;

        TestDataHelper.createResponseProperties();
        Collection__c collection = TestDataHelper.createCollection(true);

        Collection_Instance__c collectionInstance = TestDataHelper.createCollectionInstance(collection.Id, false);
        collectionInstance.Status__c = 'Active';
        insert collectionInstance;

        Unit__c unit = TestDataHelper.createUnit(true);
        Contact contact = TestDataHelper.createContact(true);
        Response__c response = TestDataHelper.createResponse(collectionInstance.Id, null, null, unit.Id, true);
        Workload__c workload = TestDataHelper.createWorkLoad(collectionInstance.Id, true);
        Work_Item__c workItem = TestDataHelper.createWorkItem(null, null, null, response.Id, workLoad.Id, true);
        Contact_Role__c contactRole = TestDataHelper.createContactRole(collection.Id, unit.Id, contact.Id, true);
        Task task = TestDataHelper.createTask(workItem.Id, true);
        Event event = TestDataHelper.createEvent(workItem.Id, true);
    }

    public static SObject[] selectAllQuery(String obj){
        Schema.sObjectType o = Schema.getGlobalDescribe().get(obj);
        Map<String, Schema.SObjectField>fm = o.getDescribe().fields.getMap();
        String[]fapi=new String[]{};
        for (Schema.SObjectField f:fm.values()) {
            fapi.add(f.getDescribe().name);
        }
        String qstr = 'SELECT '+String.join(fapi,',')+' FROM ' + obj+' limit 1';
        return Database.query(qstr);
    }
}