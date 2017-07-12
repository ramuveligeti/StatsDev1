global class BatchScheduler implements Schedulable {
	
	private final Database.Batchable<sObject> batchable;

	@testVisible
	private Boolean unitTestsForceCauseSchedule = false;

	public BatchScheduler(Database.Batchable<sObject> batchable){
		this.batchable = batchable;
	}

	global void execute(SchedulableContext sc) {
		runBatchable();
	}

	public void runBatchable(){
		Integer curentApexJobCount = [SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')];
		if(curentApexJobCount<5 && !unitTestsForceCauseSchedule){
			Database.executebatch(batchable);
		}else{
			//schedule this same schedulable class again in 5 mins
		   BatchScheduler bScheduler = new BatchScheduler(batchable);
		   Datetime dt = Datetime.now().addMinutes(5);
		   String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
		   Id schedId = System.Schedule('BatchScheduler '+timeForScheduler,timeForScheduler,bScheduler);
		}
	}
}