/**
* @description   Custom Controller called from ExtractWorkItemsActivities VF Page
* @author        Ram Veligeti
* @date          21.04.2015
* Remark		 Steven Zhu 20160908 ECP 3323 post out file name format change
*/
public class ExtractWorkItemsActivitiesExCon {
    public Collection_Instance__c collectionInstance{get;set;}
    public Activity_Schedule__c activitySchedule{get;set;}
    public Map<String, Extract_Fields__c> extractFieldsConfig = Extract_Fields__c.getAll();
    public Id asyncJobId{get;set;}
    public Boolean warningMessage{get;set;}
    public Boolean displayExtractCsvButton{get;set;}
    public String extractOption{get;set;}
    public List<SelectOption> extracts{get;set;}
    private String extractType;
    private String selectedMode;
    private Set<String> surveys = new Set<String>();
    private Set<String> collections = new Set<String>();
    private Map<Id,Activity_Schedule__c> actSchMap;
    public SelectOption[]schedules{get;private set;}
    public String selectActSchId{get;set;}
    
    //Constructor
    public ExtractWorkItemsActivitiesExCon(ApexPages.StandardController stdCont){
        collectionInstance = (Collection_Instance__c) stdCont.getRecord();
    
        //Used only to get the picklist fields on VF page
        activitySchedule = new Activity_Schedule__c();
		activitySchedule.Collection_Instance__c = collectionInstance.Id;
        extracts = new List<SelectOption>();
        
        displayExtractCsvButton = true;
        actSchMap = new Map<Id,Activity_Schedule__c>([select Id,Name,Filter_Name__c,Delivery_Mode__c,Status__c,Work_Item_Type__c,Occurrence__c,Frequency__c from Activity_Schedule__c where Collection_Instance__c=:collectionInstance.id]);
        schedules=new SelectOption[]{new SelectOption('','--None--')};
        for(Activity_Schedule__c sch: actSchMap.values()){
            schedules.add(new SelectOption(sch.id, sch.Name + ' - ' + sch.Work_Item_Type__c + ' - ' + sch.Delivery_Mode__c + ' - ' + sch.status__c));
        }
    }
    
    //Method to execute Batch Apex
    public PageReference extractCSV(){
        if(activitySchedule.Output_CSV_Format__c != null){
            Work_Item_CSV_Format__c csv = [Select Id,Collection__c from Work_Item_CSV_Format__c where Id = :activitySchedule.Output_CSV_Format__c];
            if(csv.Collection__c!=collectionInstance.Collection__c){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select a CSV which belongs to same Collection'));
				return null;
            }
        }
        if(activitySchedule.Scheduled_Date_time__c < system.now()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Scheduled Date time must be greater than Current Date time'));
            return null;
        }
        if(activitySchedule.Frequency__c=='Fortnightly' && collectionInstance.RecordType.Name=='Census'){
        	activitySchedule.Frequency__c.addError('Fortnightly not supported for Census');
        	return null;
        }
		
        if(selectActSchId != NULL){
			Activity_Schedule__c actSch = actSchMap.get(selectActSchId);
			actSch.Output_CSV_Format__c = activitySchedule.Output_CSV_Format__c;
			actSch.Occurrence__c = activitySchedule.Occurrence__c;
			actSch.Frequency__c = activitySchedule.Frequency__c;
			actSch.Collection_Instance__c = collectionInstance.Id;
            actSch.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c;
            activitySchedule = actSch;
        }


        if(collectionInstance.RecordType.Name.equalsIgnoreCase('Census')){
        	
        	ExtractWorkItemsActivitiesBatch extractBatch = new ExtractWorkItemsActivitiesBatch(activitySchedule,false);
        	executeMuleSoftForCensus(activitySchedule, extractBatch);
        }else{
        	if(activitySchedule.Scheduled_Date_time__c != null && activitySchedule.Scheduled_Date_time__c.date() < System.today().addDays(1)){
        		Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((activitySchedule.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
                ExtractWorkItemsActivitiesBatch extractBatch = new ExtractWorkItemsActivitiesBatch(activitySchedule,true);
                System.scheduleBatch(extractBatch, 'Extract Work Items '+system.now()+activitySchedule.Id, mins);
        	}
        }

        displayExtractCsvButton = true;

        return new PageReference('/'+activitySchedule.Collection_Instance__c);

        //ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.INFO, 'Batch Job has been Successfully Submitted. Please navigate to \'' + Label.Work_Item_Extracts_Document_Folder + '\' Documents Folder to view Extracted CSV.'));
        //return null;
    }
    
    public void executeMuleSoftForCensus(Activity_Schedule__c activitySchedule,ExtractWorkItemsActivitiesBatch batch){
        if(collectionInstance.RecordType.Name.equalsIgnoreCase('Census')){
            // create a new Extact_Scheudle__c record
            Extract_Schedule__c es = batch.createNewExtractSchedule(activitySchedule);
            insert es;
            
            // kick off the mulesoft client, run async
            //ActivityScheduleExtractClient.submitRequestAsync('Extract', es.Id, 0);

			//Schedule mulesoft client
			ActivityScheduleExtractClient aceClient = new ActivityScheduleExtractClient(ActivityScheduleExtractClient.Mode.Extract, es.Id, 0);
			String jobID = aceClient.schedule();
        }
    }
}