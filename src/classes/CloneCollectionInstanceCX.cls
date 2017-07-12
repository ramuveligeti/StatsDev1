public class CloneCollectionInstanceCX {
	CollectionInstanceClone collectionInstance;

	public CloneCollectionInstanceCX(ApexPages.StandardController controller) {
		collectionInstance = new CollectionInstanceClone((Collection_Instance__c) controller.getRecord());
	}

	public Collection_Instance__c getCollectionInstanceClone() {
		return collectionInstance.getClone();
	}
	
	public List<ActivityScheduleClone> getActivityScheduleClones() {
		return collectionInstance.getActivitySchedules();
	}
	
	public String getRecordType() {
		return collectionInstance.getRecordType();
	}

	public Boolean getIsCensus() {
		return 'census'.equalsIgnoreCase(getRecordType());
	}

	public Boolean getIsCollections() {
		return 'collections'.equalsIgnoreCase(getRecordType());
	}

	public Boolean getIsSocial() {
		return 'social'.equalsIgnoreCase(getRecordType());
	}

	public PageReference save() {
		Collection_Instance__c ci = collectionInstance.getClone();
		insert ci;
		insert collectionInstance.getActivitySchedulesToInsert(collectionInstance.getId());
		insert collectionInstance.getFiltersToInsert();
		// Clone Workloads for social. 
		list<Workload__c> workloadClones = collectionInstance.getClonedWorkloads(); 
		for(Workload__c w: workloadClones){
			w.Collection_Instance__c = ci.Id;
		}
		insert workloadClones;
		return new PageReference(collectionInstance.getNewURL());
	}

	public PageReference cancel() {
		return new PageReference(collectionInstance.getOriginalURL());
	}
}