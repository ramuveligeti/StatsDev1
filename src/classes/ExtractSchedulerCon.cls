/**
* @author Ram Veligeti
* @stroy ECP-2197,2663
* @description To schedule extract work items by creating records in Extract Scheduler object.
*				These extracts will be processed on that day and time through ExtractScheduler job
* @Amendmet Caterina Cuccurullo 27-04-2017 ECP-3839 replaced System.today().addDays(1)  to System.now()).date().addDays(1) 
*               to get date time value in  local time zone.  
*/
public class ExtractSchedulerCon {
    public Activity_Schedule__c actSch{get;set;}
	
	public ExtractSchedulerCon(){
		actSch = new Activity_Schedule__c();
    }
    /**
    * @description - To create Extract Scheduler record with SOQL String,CSV Header and Scheduled Date time
    */
    public void Save(){
        if(actSch.Output_CSV_Format__c != null){
            Work_Item_CSV_Format__c csv = [Select Id,Collection__c from Work_Item_CSV_Format__c where Id = :actSch.Output_CSV_Format__c];
            if(csv.Collection__c!=null){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select a CSV which doesn\'t belong to a Collection'));
				return;
            }
        }
        if(actSch.Scheduled_Date_time__c < system.now()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Scheduled Date time must be greater than Current Date time'));
            return;
        }

        System.debug('**C*Before code ExtractWorkItemsActivitiesBatch');  
        ExtractWorkItemsActivitiesBatch batch = new ExtractWorkItemsActivitiesBatch(actSch,true);

		
        //Changed to using system.now to see if that solves the date zone problem 
     	//	if(actSch.Scheduled_Date_time__c != null && actSch.Scheduled_Date_time__c.date() < System.today().addDays(1)){ //17-08-2016 00:00:00
           	if(actSch.Scheduled_Date_time__c != null && actSch.Scheduled_Date_time__c.date() < (System.now()).date().addDays(1)){ //17-08-2016 00:00:00
            //Calculate minutes between current date time and scheduled date time, to schedule batch apex
            Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((actSch.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
            system.debug('mins = ' + mins + ' actsch.id = '+ actSch.Id );
                System.scheduleBatch(batch, 'Extract Work Items '+system.now()+actSch.Id, mins);
		}
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Batch Job has been successfully submitted.'));
    }
    
	public PageReference cancel(){
		return new PageReference('/home/home.jsp');
	}
}