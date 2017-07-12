/* author: Ram Veligeti
   description: This class is being called in WorkItemsGroupedByCollectionUnit & WorkItesmGroupedByContact page
   WorkItemsGroupedByCollectionUnit - Displays work items related to the same collection unit work items
   WorkItesmGroupedByContact - Displays work items related to the same contact work items
*/
public class WorkItemsGroupedByExCon {
	public List<Work_Item__c> workItemsRelatedToContact{get;set;}
	public List<Work_Item__c> workItemsRelatedToCollectionUnit{get;set;}
	public List<WorkItemWrapper> contactsWrapper{get;set;}
	public List<WorkItemWrapper> collectionUnitsWrapper{get;Set;}
	public Boolean display{get;Set;}
	public Boolean display1{get;Set;}
	public Work_Item__c wi;
    public static Set<Id> selectedWIContacts;
    public static Set<Id> selectedWICollectionUnits;
    public static boolean testb = false;
	//Standard Controller
	public WorkItemsGroupedByExCon(ApexPages.StandardController stdCont){
		wi = (Work_Item__c)stdCont.getRecord();
        List<String> queue = new List<String>{'LBU_Escalation_Queue','CC_Escalation_Queue','CC_Admin_Team_Queue','Supplier_Management_Advisers_Queue'};
        Map<String,Id> queueMap = new Map<String,Id>();

        for(Group q: [Select Id,DeveloperName from Group where DeveloperName in :queue and Type = 'Queue']){
            queueMap.put(q.DeveloperName,q.Id);
        }
		//Query work items for contact
		workItemsRelatedToContact = [Select Id,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c,Unit__c 
									 from Work_Item__c where Delivery_Mode__c = 'Call' and Contact__c != null 
									 and Contact__c = :wi.Contact__c and Id <> :wi.Id and ownerId not in :queueMap.keySet()];
		if(!workItemsRelatedToContact.isEmpty()){
			display = true;
			contactsWrapper = new List<WorkItemWrapper>();
			for(Work_Item__c w : workItemsRelatedToContact){
				contactsWrapper.add(new WorkItemWrapper(w));
			}
		}
		//Query work items for collection unit
		workItemsRelatedToCollectionUnit = [Select Id,Name,Work_Item_Type__c,Collection_Instance_Name__c,Response__c,Unit__c 
											from Work_Item__c where Delivery_Mode__c = 'Call' and Unit__c != null 
											and Unit__c = :wi.Unit__c and Id <> :wi.Id and Id not in :workItemsRelatedToContact  and ownerId not in :queueMap.keySet()];
		if(!workItemsRelatedToCollectionUnit.isEmpty()){
			display1 = true;
			collectionUnitsWrapper = new List<WorkItemWrapper>();
			for(Work_Item__c w : workItemsRelatedToCollectionUnit){
				collectionUnitsWrapper.add(new WorkItemWrapper(w));
			}
		}
	}

	public PageReference recordOutcomes(){
        selectedWIContacts = new Set<Id>();
        selectedWICollectionUnits = new Set<Id>();
        testb = true;
		for(WorkItemWrapper ct : contactsWrapper){
			if (ct.sel){ selectedWIContacts.add(ct.wi.Id);}
		}
		system.debug('selectedWIContacts=='+selectedWIContacts);
		for(WorkItemWrapper ut : collectionUnitsWrapper){
			if (ut.sel){ selectedWICollectionUnits.add(ut.wi.Id);}
		}
		PageReference pg = new PageReference('/apex/BulkRecordOutcomes?id='+wi.Id);
		return pg.setRedirect(false);
	}

	public void interactionLog(){
	
	}
	public class WorkItemWrapper{
		public Boolean sel{get;set;}
		public Work_Item__c wi{get;set;}
		public WorkItemWrapper(Work_Item__c w){
			sel = false;
			wi = w;
		}
	}
}