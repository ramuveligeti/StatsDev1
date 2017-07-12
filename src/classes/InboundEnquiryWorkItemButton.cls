/**
 * new controller for the new Work-Item button on the Response object
 */
public with sharing class InboundEnquiryWorkItemButton {
	private Id respId{get;set;}
	private String wiType{get;set;}
	private String wiMode{get;set;}
    private String wiEnqOrig{get;set;}
   	public Work_Item__c wi{get;set;}
  	//public InboundEnquiryWorkItemButton(ApexPages.StandardController std){
	public InboundEnquiryWorkItemButton(){
		respId=ApexPages.currentPage().getParameters().get('rid');
		wiType=ApexPages.currentPage().getParameters().get('type');
		if(String.isBlank(wiType)){wiType='Inbound Enquiry'; }
		wiMode=ApexPages.currentPage().getParameters().get('mode');
        if(String.isBlank(wiMode)){wiMode='Call';}	
        wiEnqOrig=ApexPages.currentPage().getParameters().get('mode');
        wiEnqOrig = '';
        }

	public PageReference createWorkItem(){
		if(!String.isBlank(respId)){
			wi=new Work_Item__c(Work_Item_Type__c=wiType, Delivery_Mode__c=wiMode,
                                Enquiry_Origin__c=wiEnqOrig,Response__c=respId,status__c='In Progress');
			insert wi;
			wi=[select name from Work_Item__c where id=:wi.id];
			return new PageReference('/'+wi.id);
		}
		return null;
	}
}