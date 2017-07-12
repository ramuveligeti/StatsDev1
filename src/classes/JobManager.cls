global class JobManager implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		//Remove old sync logs
		ID jobID_SyncLogRemove = System.enqueueJob(new ErrorLogRemover());
		
		//process social workloads, e.g. change owner from user to queue once complete
		//and inteview end date is older than 7 days
		ID jobID_WorkloadOwnerChange = System.enqueueJob(new SocialWorkloadProcessor());

		//Remove old Mobile Sync Staging records
		ID jobID_MobileSyncStagingRemove = System.enqueueJob(new MobileSyncStagingRemover());
	}
}