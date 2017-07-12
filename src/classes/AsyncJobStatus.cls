/**
* @description This is the controller class for AysncJobStatus component
* @author Ram Veligeti
* @date 30.Apr.2015
*/
public class AsyncJobStatus {
    public String jobId{get;set;}
    public String recordId{get;set;}
    public String status{get;set;}
    public String completionProgress{get;set;}
    public Boolean renderPoller{get;set;}
    public String errorDetails{get;set;}
    
    public AsyncJobStatus(){
        statusMethod(true,'Queuing...','0% Complete',null);
    }
    
    public void progress(){
        try{
            AsyncApexJob async = [Select Id,JobItemsProcessed,NumberOfErrors,Status,TotalJobItems, ExtendedStatus from AsyncApexJob where Id = :jobId];
            system.debug('async==='+async);
            if(async.Status == 'Completed'){
                statusMethod(false,async.Status,'100% Complete',null);
                return;
            }
            
            if(async.Status == 'Failed'){
                statusMethod(false,async.Status,'0% Complete',async.ExtendedStatus);
                return;
            }

            if(async.Status != 'Completed' && async.TotalJobItems>0){
                completionProgress = String.valueOf(Math.round(((async.JobItemsProcessed*1.0)/async.TotalJobItems)*100))+'% Complete';
                statusMethod(true,async.Status,completionProgress,null);
                return;
            }
            
            statusMethod(true,async.Status,'0% Complete',null);
        } catch(Exception e){
            statusMethod(false,'Async Job Failed','0% Complete',e.getMessage());
        }
    }
    
    private void statusMethod(Boolean poller, String jobStatus, String progress,String errDet){
        renderPoller = poller;
        status = jobStatus;
        completionProgress = progress;
        errorDetails = errDet;
    }
    
    public pageReference finish(){
        return new PageReference('/'+recordId); 
    }
}