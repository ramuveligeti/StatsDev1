public class ProcessStagingElementsExCon {
    @TestVisible
    private final Collection_Instance__c ci;
    @TestVisible private Map<String, SystemSettings__c> systemSettings;
    public String asyncJobId { get; set; }
    // The extension constructor initializes the private member
    // variable ci by using the getRecord method from the standard
    // controller.
    public ProcessStagingElementsExCon(ApexPages.StandardController stdController) {
        ci = (Collection_Instance__c) stdController.getRecord();
        systemSettings = SystemSettings__c.getall();
    }

    public void processStagingElements() {
        if (!hasPendingJob()) {
            //if the process is not running then start it
            asyncJobId = Database.executeBatch(new ProcessImportsFromStagingBatch(ci.Id), Integer.valueOf(systemSettings.get('fileUploadBatchSize').Value__c));
            postProcessing();
        }
    }

    public void deleteStagingElements() {
        if (!hasPendingJob()) {
            //if the process is not running then start it
            asyncJobId = Database.executeBatch(new DeleteFromStagingBatch(ci), Integer.valueOf(systemSettings.get('fileUploadBatchSize').Value__c));
            postProcessing();
        }
    }

    private void postProcessing() {
        ci.batch_job_id__c = asyncJobId;
        update ci;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Batch process successfully started.'));
    }

    private boolean hasPendingJob() {
        if (String.isBlank(ci.batch_job_id__c)) { return false; }
        List<String> runningJobStatuses = new List<String>{'Holding','Queued','Preparing','Processing'};
        AsyncApexJob[] batchJob = [select status from AsyncApexJob where id = :ci.batch_job_id__c and Status in :runningJobStatuses];
        if (!batchJob.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Batch process is already running.'));
            return true;
        }
        return false;
    }
}