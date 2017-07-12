@isTest
private class AsyncJobStatusTest {
    @isTest static void progressTest(){
        AsyncJobStatus asj = new AsyncJobStatus();
        //asj.jobId = async.Id;
        asj.progress();
        asj.finish();
    }
}