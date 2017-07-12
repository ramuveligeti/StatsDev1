public class DeleteDACforCollectInstController {

	
    public Boolean showDACDeleteButton{get; private set;}
    public Boolean showDACCancelButton{get;private set;}

	@testVisible
	private Collection_Instance__c collectionInstance;

	
	public DeleteDACforCollectInstController(ApexPages.StandardController controller) {
		showDACDeleteButton = true;
		showDACCancelButton = true;
		//String collectionInsatnceId = ApexPages.currentPage().getParameters().get('id');
		String collectionInsatnceId = controller.getId();
		if(!String.isBlank(collectionInsatnceId)){
			List<Collection_Instance__c> collectionInstances = [select Name, Collection_Instance_Code__c, Status__c from Collection_Instance__c where Id = :collectionInsatnceId];
			if(collectionInstances != null && !collectionInstances.isEmpty()){
				this.collectionInstance = collectionInstances.get(0);
				if('Active'.equals(collectionInstance.Status__c)){
					ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Active collection instance cannot have its DAC Store records deleted');
					ApexPages.addMessage(msg);
					showDACDeleteButton = false;
				}else{
					ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Are you sure you want to delete all the DAC Store records for this collection instance "'+collectionInstance.Name+'" xx');
					ApexPages.addMessage(msg);
				}
			}else{
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No collection instance exists with Id '+collectionInsatnceId);
				ApexPages.addMessage(msg);
				showDACDeleteButton = false;
			}
		}else{
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No collection instance Id was provided');
			ApexPages.addMessage(msg);
				showDACDeleteButton = false;
		}
	}

	
      
   public PageReference deleteDACStore(){
		DeleteStagingElemetsBatch stagingElemBatch = new DeleteStagingElemetsBatch(collectionInstance);
		BatchScheduler stagingElemBatchScheduler = new BatchScheduler(stagingElemBatch);
		stagingElemBatchScheduler.runBatchable();

		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Collection instance and its all related data will be deleted in the background'));
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The results will be sent to '+UserInfo.getUserEmail()));
		
		showDACDeleteButton = false;
		showDACCancelButton = false;

		return null;
	}
	

	public PageReference cancel(){
		if(collectionInstance!=null && !String.isBlank(collectionInstance.Id)){
			return new PageReference('/'+collectionInstance.Id);
		}else{
			return new PageReference('/');
		}
	}
}