/**
* @description   Problem: Console doesn't allow a related list to be used in a sub tab if it's already in use by the primary tab.
*				 Solution: Create a new visual force page that overrides the link that would normally open a work item in a sub tab and instead redirect to a primary tab.
* @author		Joseph Newby
* @date		  28.09.2015
*/
public class ResponseWorkItemListCX {
	public List<Work_Item__c> workItems { get; private set; }
	
	public ResponseWorkItemListCX(ApexPages.StandardController stdController) {
		Response__c response = (Response__c) stdController.getRecord();
		workItems = new Work_Item__c[]{};
		if(response!=null){
			workItems = [ select Name, Work_Item_Type__c, Delivery_Mode__c, Status__c
				from Work_Item__c where Response__c = :response.id limit 1000 ];
		}
	}
}