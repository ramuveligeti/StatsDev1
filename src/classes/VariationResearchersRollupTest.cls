@isTest
private class VariationResearchersRollupTest {
/*
A unit test should: 
1) Set up all conditions for testing. 
2) Call the method (or Trigger) being tested. 
3) Verify that the results are correct. 
4) Clean up modified records. (Not really necessary on Force.com.) 
*/

    public static Contact contact;
    public static Contact contact2;
    public static Project__c project;
    public static Project__c project2;
    public static Project_Variation__c projectVariation;
    public static Projects_Access__c projectsAccess;
    public static Dataset__c dataset;
    public static Dataset__c dataset2;
    public static Researcher__c researcher;
    public static Researcher__c researcher2;
    public static Researcher__c researcher3;
   
    static void init(){
        //Set up all conditions - Create the parent object (Project__c)
        SmartFactory.FillAllFields = true;
        Map<String, Object> projectValues = new Map<String, Object> {
            'Name' => 'Project_MAA_001', //key identifier
            'Status__c' => 'Initial Approvals Completed',
            'subject__c' => 'Project Title',
            'Project_Summary__c' => 'Project Summary',
            'Application_Type__c' => 'MAA',
            'Contract_Sent_Date__c' => system.today(),
            'Datalab_Access_Provided_Date__c' => system.today(),
            'Signed_Contract_Date__c' => system.today(),
            'Invoice_Raised__c' => true,
            'Objectives_of_the_Research__c' => 'objective',
            'Research_Methodology__c' => 'research',
            'Anticipated_outputs__c' => 'anticipated',
            'Dissemination_Methods__c' => 'dissemination',
            'Data_Requirements__c' => 'data req',
            'Estimated_End_Date__c' => system.today().addDays(30),
            'Project_End_Date__c' => system.today().addDays(30),
            'Wellington__c' => true,
            'Application_Received_Date__c' => system.today(),
            'SM__c' => true,
            'Legal__c' => true,
            'IDI_Senior_Manager__c' => true,
            'DGS__c' => true,
            'GS__c' => true
        };
        project = (Project__c) SmartFactory.createSObject('Project__c', projectValues);
        insert project;

        SmartFactory.FillAllFields = true;
        Map<String, Object> datasetValues = new Map<String, Object> {
            'Name' => 'Dataset Name 1'
        };
        dataset = (Dataset__c) SmartFactory.createSObject('Dataset__c', datasetValues );
        insert dataset;

        SmartFactory.FillAllFields = true;
        Map<String, Object> dataset2Values = new Map<String, Object> {
            'Name' => 'Dataset Name 2'
        };
        dataset2 = (Dataset__c) SmartFactory.createSObject('Dataset__c', dataset2Values );
        insert dataset2;
        
        //ECP-3462-One contact record for each contact- record type is no more required
        //RecordType contactRecordType = [select Id from RecordType where sobjecttype='Contact' and Name='Datalab'];
        
        SmartFactory.FillAllFields = false;
        Map<String, Object> contactValues = new Map<String, Object> {
            'FirstName' => 'Joe',
            'LastName' => 'Bloggs'
        };
        contact = (Contact) SmartFactory.createSObject('Contact', contactValues );
       //ECP-3462-One contact record for each contact- record type is no more required
       //contact.recordtypeid = contactRecordType.Id;
        insert contact;

        SmartFactory.FillAllFields = false;
        Map<String, Object> projectsAccessValues = new Map<String, Object> {
            'Project_Access_End_Date__c' => system.today().addDays(30)
        };
        projectsAccess = (Projects_Access__c) SmartFactory.createSObject('Projects_Access__c', projectsAccessValues );
        projectsAccess.Project__c = project.Id;
        projectsAccess.Dataset__c = dataset.Id;
        insert projectsAccess;

        //Set project's status to 'Project Active (Approved)'
        project2 = [select id from Project__c where Id = :project.Id];
        project2.Status__c = 'Project Active (Approved)';
        update project2;

        contact2 = [select id from Contact where Id = :contact.Id];
        
        SmartFactory.FillAllFields = true;
        Map<String, Object> projectVariationValues = new Map<String, Object> {
            'Name' => 'ProjectVariation_MAA_Test001', //key identifier
            'Application_Received_Date__c' => system.today(),
            'New_Completion_Time__c' => system.today().addDays(31),
            'Number_of_Datasets_Requested__c' => 1,
            'Number_of_Researchers_Included__c' => 1,
            'Reason_for_extension__c' => 'Reason for extension',
            'Status__c' => 'New'//Initials Approvals'
        };
        projectVariation = (Project_Variation__c) SmartFactory.createSObject('Project_Variation__c', projectVariationValues);
        projectVariation.Master_Project__c = project2.Id;
        projectVariation.Main_Contact__c = contact2.Id;
        insert projectVariation;
    }

    /** Test with inserting a researcher for an existing project variation **/
    static testMethod void testInsertIntoProjectsAccess() {
        init();
        Test.startTest();
        
        //Call the trigger - Insert into Researcher__c to trigger the insert action
        SmartFactory.FillAllFields = true;
        Map<String, Object> researcherValues = new Map<String, Object> {
            'Project__c' => project2.Id,
            'Project_Variation__c' => projectVariation.Id,
            'Researcher_End_date__c' => system.today()
        };
        researcher = (Researcher__c) SmartFactory.createSObject('Researcher__c', researcherValues);
        insert researcher;

        //Verify the results - Getting the counts to verify that the field is updated
        projectVariation = [
            SELECT Name, Number_of_Researchers_Included__c
            FROM Project_Variation__c
            WHERE Id = :projectVariation.Id
        ];
        Test.stopTest();
     
        // Verification
        System.assertEquals(1, projectVariation.Number_of_Researchers_Included__c);
    }

    /** Test with updating a researcher for an existing project variation **/
    static testMethod void testUpdateResearcher() {
        init();
     
        SmartFactory.FillAllFields = true;
        Map<String, Object> researcherValues = new Map<String, Object> {
            'Project__c' => project2.Id,
            'Project_Variation__c' => projectVariation.Id,
            'Researcher_End_date__c' => system.today()
        };
        researcher = (Researcher__c) SmartFactory.createSObject('Researcher__c', researcherValues);
        insert researcher;

        Test.startTest();
        //Call the trigger - Update Researcher__c to trigger the update action
        researcher2 = [Select Id from Researcher__c where Id = :researcher.Id];
        researcher2.Researcher_End_Date__c = system.today().addDays(1);
        update researcher2;

        //Verify the results - Getting the counts to verify that the field is updated
        projectVariation = [
            SELECT Name, Number_of_Researchers_Included__c
            FROM Project_Variation__c
            WHERE Id = :projectVariation.Id
        ];
        Test.stopTest();
     
        // Verification
        System.assertEquals(1, projectVariation.Number_of_Researchers_Included__c);
    }
     
    /** Test with deleting from a researcher for an existing project variation **/
    static testMethod void testDeleteFromResearcher() {
        init();
     
        SmartFactory.FillAllFields = true;
        Map<String, Object> researcherValues = new Map<String, Object> {
            'Project__c' => project2.Id,
            'Project_Variation__c' => projectVariation.Id,
            'Researcher_End_date__c' => system.today()
        };
        researcher = (Researcher__c) SmartFactory.createSObject('Researcher__c', researcherValues);
        insert researcher;

        Test.startTest();
        //Call the trigger - Delete from Researcher__c to trigger the delete action
        researcher3 = [Select Id from Researcher__c where Id = :researcher.Id];
        delete researcher3;

        //Verify the results - Getting the counts to verify that the field is updated
        projectVariation = [
            SELECT Name, Number_of_Researchers_Included__c
            FROM Project_Variation__c
            WHERE Id = :projectVariation.Id
        ];
        Test.stopTest();
     
        // Verification
        System.assertEquals(0, projectVariation.Number_of_Researchers_Included__c);
    }
}