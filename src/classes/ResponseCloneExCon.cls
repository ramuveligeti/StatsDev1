/**
* @description This is an extension controller for ResponseClone Page. 
* @author Ram Veligeti
* @date 26.Jun.2015
*/
public class ResponseCloneExCon {
	public static Map<String,Response_Settings__c> responseSettings = Response_Settings__c.getAll();
	public Unit__c unitOfInterestObj{get;set;}
	public Boolean renderContent{get;set;}
	public List<workItemWrapper> workItemWrapperList{get;set;}
	public List<Work_Item__c> workItemList = new List<Work_Item__c>();
	public Map<String,Id> workLoadMap = new Map<String,Id>();
	private Response__c response = new Response__c();
	private Response__c newResponse = new Response__c();
	private Id unitOfInterestRecordTypeId;
	
	//Standard Controller
	public ResponseCloneExCon(ApexPages.StandardController stdCont){
		//Get response summary record
		response = (Response__c)stdCont.getRecord();
		system.debug('response.Collection_Instance__r.Collection__r.Collection_Code__c=='+response.Collection_Instance__r.Collection__r.Collection_Code__c);
		//Validate if the Collection is eligible for cloning response summary
		if(responseSettings.containsKey(response.Collection_Instance__r.Collection__r.Collection_Code__c) && 
		   responseSettings.get(response.Collection_Instance__r.Collection__r.Collection_Code__c).Enable_Clone__c &&
		   responseSettings.get(response.Collection_Instance__r.Collection__r.Collection_Code__c).RecordType_Name_for_Clone__c == response.RecordType.Name
		  ){
			   //Render VF page only when custom setting exist
			   renderContent = true;
			   createNewUnit();
			   queryWorkItems();
		   } else {
			   renderContent = false;
			   ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,Label.Response_Summary_Clone_Settings_doesn_t_have_this_collection));
		   }
	}
	
	//Method to create a clone of Response and its related objects (Work Item, Response, Unit of Interest)
	public PageReference cloneResponse(){
		Savepoint sp;
		try{
			//Save point to revert all the inserts if any insert fails
			sp = Database.setSavepoint();
			
			insert unitOfInterestObj;

			createNewResponse();
			createNewWorkItems();
			
			//return to cloned Response
			PageReference pg = new PageReference('/'+newResponse.Id);
			return pg;
		} catch(exception e){
			//Roll back all the inserts if failed
			database.rollback(sp);
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,e.getMessage()));
			return null;
		}
	}
	
	//Create Unit of Interest based on the Address of the cloned Response UOI
	private void createNewUnit(){
		unitOfInterestObj = new Unit__c();
		unitOfInterestObj.Level_Number__c = response.Unit_of_Interest__r.Level_Number__c;
		unitOfInterestObj.Building_Name__c = response.Unit_of_Interest__r.Building_Name__c;
		unitOfInterestObj.Unit_Number__c = response.Unit_of_Interest__r.Unit_Number__c;
		unitOfInterestObj.Road_Number__c = response.Unit_of_Interest__r.Road_Number__c;
		unitOfInterestObj.Road_Number_Alpha__c = response.Unit_of_Interest__r.Road_Number_Alpha__c;
		unitOfInterestObj.Road_Name__c = response.Unit_of_Interest__r.Road_Name__c;
		unitOfInterestObj.Road_Type__c = response.Unit_of_Interest__r.Road_Type__c;
		unitOfInterestObj.Rural_Delivery_Number__c = response.Unit_of_Interest__r.Rural_Delivery_Number__c;
		unitOfInterestObj.Suburb__c = response.Unit_of_Interest__r.Suburb__c;
		unitOfInterestObj.Town_or_City__c = response.Unit_of_Interest__r.Town_or_City__c;
		unitOfInterestObj.Postcode__c = response.Unit_of_Interest__r.Postcode__c;
		unitOfInterestObj.Address_Type__c = response.Unit_of_Interest__r.Address_Type__c;
		unitOfInterestObj.Other_Address_Type__c = response.Unit_of_Interest__r.Other_Address_Type__c;
		unitOfInterestObj.Meshblock_Code__c = response.Unit_of_Interest__r.Meshblock_Code__c;
		unitOfInterestObj.Address_Sub_Type__c = response.Unit_of_Interest__r.Address_Sub_Type__c;
		unitOfInterestObj.Unverified__c = true;
		unitOfInterestObj.Shell_Address__c = response.Unit_of_Interest__r.Shell_Address__c;
		unitOfInterestObj.Related_Observed_Address__c = response.Unit_of_Interest__r.Related_Observed_Address__c;
		unitOfInterestObj.RecordTypeId = response.Unit_of_Interest__r.RecordTypeId;

		unitOfInterestObj.PSU_Number__c = response.Unit_of_Interest__r.PSU_Number__c;
		unitOfInterestObj.PSU_Name__c = response.Unit_of_Interest__r.PSU_Name__c;
		unitOfInterestObj.Region_Number__c = response.Unit_of_Interest__r.Region_Number__c;
		unitOfInterestObj.Region_Name__c = response.Unit_of_Interest__r.Region_Name__c;
		unitOfInterestObj.Territorial_Authority_Number__c = response.Unit_of_Interest__r.Territorial_Authority_Number__c;
		unitOfInterestObj.Territorial_Authority_Name__c = response.Unit_of_Interest__r.Territorial_Authority_Name__c;
		unitOfInterestObj.Team_Leader_Area_Number__c = response.Unit_of_Interest__r.Team_Leader_Area_Number__c;
		unitOfInterestObj.Team_Leader_Area_Name__c = response.Unit_of_Interest__r.Team_Leader_Area_Name__c;
		unitOfInterestObj.Area_Unit_Number__c = response.Unit_of_Interest__r.Area_Unit_Number__c;
		unitOfInterestObj.Area_Unit_Name__c = response.Unit_of_Interest__r.Area_Unit_Name__c;
	}
	
	private void createNewResponse(){
		newResponse.Unit_of_Interest__c = unitOfInterestObj.Id;
        //ecp-2616 added the related assignment to be able to access the Address Type in DACAllocator.
		newResponse.Unit_of_Interest__r = unitOfInterestObj;
		newResponse.Collection_Instance__c = response.Collection_Instance__c;
		newResponse.Type__c = response.Type__c;
		newResponse.RecordTypeId = response.RecordTypeId;
		newResponse.Instrument__c = response.Instrument__c;
		newResponse.Unit_Delivery_Mode__c = response.Unit_Delivery_Mode__c;
		newResponse.Wave__c = response.Wave__c;
		newResponse.Status__c = 'No response';
		// from file loading, the logic is that this is a combination of the CollectionInstance.code + Unit.FrameId
		// as this is a birth, we do not have a frame id... hence we will be using the SF-ID
		newResponse.Response_ExtId__c = response.Collection_Instance__r.Collection__r.Collection_Code__c + '-' + ApexUtility.GUID();

		// added by Eric on 2016-07-11
		// tidy up all the new changes since we touch this class in June 2015
		newResponse.Unit_Association__c = unitOfInterestObj.Id;
       
        DACAllocator.allocateDAC(newResponse, false);
        
		insert newResponse; // the DAC store will be updated in the trigger of response    
		
	}
	
	private void createNewWorkItems(){
		List<Work_Item__c> newWorkItemObjList = new List<Work_Item__c>();
		
		//Capture all the selected Work Items
		for(workItemWrapper wiw: workItemWrapperList){
			if(wiw.selected){
				Work_Item__c wi = new Work_Item__c();
				wi.Delivery_Mode__c = wiw.deliveryMode;
				wi.Work_Item_Type__c = wiw.workItemType;
				wi.Response__c = newResponse.Id;
				if(String.isNotBlank(wiw.workLoad) && workLoadMap.containsKey(wiw.workLoad)){
					wi.Workload__c = workLoadMap.get(wiw.workLoad);
				}
				wi.Status__c = 'New';
				newWorkItemObjList.add(wi);
			}
		}
		
		if(!newWorkItemObjList.isEmpty()){
			insert newWorkItemObjList;
		}
	}
	
	//Query WorkItems on Response Object
	private void queryWorkItems(){
		workItemList = [Select Id,Name,Work_Item_Type__c,Workload__c,Workload__r.Name,Delivery_Mode__c from Work_Item__c where Response__c = :response.Id];
		workItemWrapperList = new List<workItemWrapper>();
		Set<String> uniqueComb = new Set<String>();
		
		//Get the combination of Delivery Mode and Work Item type
		for(Work_Item__c wi: workItemList){
			uniqueComb.add((String.isBlank(wi.Delivery_Mode__c)?' ':wi.Delivery_Mode__c)+'~'+(String.isBlank(wi.Work_Item_Type__c)?' ':wi.Work_Item_Type__c)+'~'+(String.isBlank(wi.Workload__r.Name)?' ':wi.Workload__r.Name));
			if(String.isNotBlank(wi.Workload__r.Name)){
				workLoadMap.put(wi.Workload__r.Name,wi.Workload__c);
			}
		}
		
		//Add the combination to wrapper
		for(String st: uniqueComb){
			String deliveryMode = st.split('~')[0];
			String workItemType = st.split('~')[1];
			String workLoad = st.split('~')[2];
			workItemWrapperList.add(new workItemWrapper(false,deliveryMode,workItemType,workLoad));
		}
	}
	
	//Wrapper for WorkItem Screen
	public class workItemWrapper{
		public boolean selected{get;set;}
		public String deliveryMode{get;set;}
		public String workItemType{get;set;}
		public String workLoad{get;set;}
		public workItemWrapper(Boolean sel, String d, String w, String wl){
			selected = sel;
			deliveryMode = d;
			workItemType = w;
			workLoad = wl;
		}
	}
}