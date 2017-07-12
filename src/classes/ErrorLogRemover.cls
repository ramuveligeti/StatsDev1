public class ErrorLogRemover implements Queueable {
	public void execute(QueueableContext sc) {
		//set default value of 30 if settings is null
		Integer timeToLiveDays = SystemSettings.getIntegerValue('errorLog.sync.TTL', 30);

		Datetime cutOffDate = DateTime.now().addDays(-timeToLiveDays);
		List<Error_Log__c> errorLogs = [select Id from Error_Log__c where Process_Name__c='Mobile Sync' and CreatedDate<:cutOffDate];

		if(errorLogs!=null && !errorLogs.isEmpty()){
			delete errorLogs;
		}
	}
}