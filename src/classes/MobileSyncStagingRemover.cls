public class MobileSyncStagingRemover implements Queueable {
	public void execute(QueueableContext sc) {
		Integer timeToLiveDays = SystemSettings.getIntegerValue('mobileSyncStaging.TTL', 1);

		Datetime cutOffDate = DateTime.now().addDays(-timeToLiveDays);
		List<Mobile_Sync_Staging__c> mobileSyncStagingList = [select Id from Mobile_Sync_Staging__c where CreatedDate<:cutOffDate];

		if(mobileSyncStagingList!=null && !mobileSyncStagingList.isEmpty()){
			delete mobileSyncStagingList;
		}
	}
}