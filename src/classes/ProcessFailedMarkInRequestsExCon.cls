/**
 * @description This method is a controller for ProcessFailedMarkInRequests
 * @author Ram Veligeti
 * @date 6.Oct.2015
 * @updated by Karthik on 22.Jul.2016
 */
public class ProcessFailedMarkInRequestsExCon Implements Schedulable {
    //Process failed records
    public void execute(){
        try{
         processFailedMarkInRequest();
         ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'Failed Mark-in records processed successfully.'));
        }catch(exception e){ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,e.getMessage()));}
    }
    public void execute(SchedulableContext sc){
        processFailedMarkInRequest(); 
        String scheduleFurther = SystemSettings.getValue('ScheduleFailedMarkInRequest', 'False');
        if(scheduleFurther == 'True'){
			//schedule this same schedulable class again in 30 mins
		   ProcessFailedMarkInRequestsExCon markinScheduler = new ProcessFailedMarkInRequestsExCon();
           Integer duration = Integer.valueOf(SystemSettings.getValue('ScheduleFailedMarkInRequest.duration', '30'));
		   Datetime dt = Datetime.now().addMinutes(duration);
		   String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
		   Id schedId = System.Schedule('FailedMarkInRequestsProcessScheduler '+timeForScheduler, timeForScheduler, markinScheduler);
		}
    }       
    private void processFailedMarkInRequest(){
       List<Mark_In_Request__c> failedMarkInRequests =  [Select Id,Failed__c from Mark_In_Request__c where Failed__c = true order by lastmodifieddate limit 3000];
       for(Mark_In_Request__c mir: failedMarkInRequests){mir.failed__c = false;}
       if(!failedMarkInRequests.isEmpty()){update failedMarkInRequests;}  
    }

}