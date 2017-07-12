public with sharing class WorkItemTriggerHandler {
    public static boolean executed = false;
    public static boolean workflowExecuted = false;


	 //Steven zhu top level handler for handleing after update trigger
	public static void AfterUpdateHandler(Map<Id, Work_Item__c> workItems, Map<Id, Work_Item__c> oldWorkItems)
	{
		Set<ID>wiIDs=new Set<ID>();
		Set<Id> workItemIds = new Set<Id>();
        Set<Id> workLoadIds = new Set<Id>();
       
        for(Work_Item__c wi: workItems.values()){
            if((!oldWorkItems.isEmpty() && wi.Status__c != oldWorkItems.get(wi.Id).Status__c || oldWorkItems.isEmpty()) && wi.Status__c == 'Completed'){
                workItemIds.add(wi.Id);
            }
			if(!String.isBlank(wi.Workload__c)){
                workLoadIds.add(wi.Workload__c);
            }
			if(wi.status__c=='Completed'){
				wiIDs.add(wi.id);
			}
			if(!oldWorkItems.isEmpty()){
				if(wi.Workload__c != oldWorkItems.get(wi.Id).Workload__c && !String.isBlank(oldWorkItems.get(wi.Id).Workload__c)){
                    workLoadIds.add(oldWorkItems.get(wi.Id).Workload__c);
                }
			}
        }
		
		updateWorkLoadStatus(workLoadIds);
		setResponseToInProgress(wiIDs);
	}

	 //Steven zhu top level handler for handleing after insert trigger
	public static void AfterInsertHandler(Map<Id, Work_Item__c> workItems, Map<Id, Work_Item__c> oldWorkItems)
	{
		
		Set<Id> workItemIds = new Set<Id>();
        Set<Id> workLoadIds = new Set<Id>();
       
        for(Work_Item__c wi: workItems.values()){
            if((!oldWorkItems.isEmpty() && wi.Status__c != oldWorkItems.get(wi.Id).Status__c || oldWorkItems.isEmpty()) && wi.Status__c == 'Completed'){
                workItemIds.add(wi.Id);
            }
			if(!String.isBlank(wi.Workload__c)){
                workLoadIds.add(wi.Workload__c);
            }
			
			if(!oldWorkItems.isEmpty()){
				if(wi.Workload__c != oldWorkItems.get(wi.Id).Workload__c && !String.isBlank(oldWorkItems.get(wi.Id).Workload__c)){
                    workLoadIds.add(oldWorkItems.get(wi.Id).Workload__c);
                }
			}
        }

		updateWorkLoadStatus(workLoadIds);
	}

	public static void BeforeUpdateHandler(Map<Id, Work_Item__c> workItems, Map<Id, Work_Item__c> oldWorkItems)
	{
		Set<Id> workLoadIds = new Set<Id>();
		
        for(Work_Item__c wi: workItems.values()){
			//validate work items
			if(!isWorkItemTypeValid(wi.Work_Item_Type__c)){
                String errorMsg = 'Invalid workitem type '+wi.Work_Item_Type__c+'. Valid workitem types are: '+getValidWorkitemTypesString();
                wi.Work_Item_Type__c.addError(errorMsg);
            }

            if((oldWorkItems.isEmpty() && wi.Workload__c != NULL) || (!oldWorkItems.isEmpty() && oldWorkItems.get(wi.Id).Workload__c != wi.Workload__c && wi.Workload__c != NULL)){
                workLoadIds.add(wi.Workload__c);
            }

            setWorkitemCompletedBy(oldWorkItems.get(wi.Id), wi);
        }

		updateOwner(workItems.keySet(), workLoadIds);
	 
	}
	
	public static void BeforeInsertHandler(List<Work_Item__c> workitems, Map<Id, Work_Item__c> oldWorkItems)
	{
		Set<Id> workLoadIds = new Set<Id>();
		Set<Id> workItemIds = new Set<Id>();
		Set<ID>responseIds=new Set<ID>();
    	Set<String>deliveryModeFilters=new Set<String>{'Call','Email'};
    	Work_item__c[]filteredList=new Work_Item__c[]{};

        for(Work_Item__c wi: workItems){
			workItemIds.add(wi.id);
			//validate work items
			if(!isWorkItemTypeValid(wi.Work_Item_Type__c)){
                String errorMsg = 'Invalid workitem type '+wi.Work_Item_Type__c+'. Valid workitem types are: '+getValidWorkitemTypesString();
                wi.Work_Item_Type__c.addError(errorMsg);
            }

            if((oldWorkItems.isEmpty() && wi.Workload__c != NULL) || (!oldWorkItems.isEmpty() && oldWorkItems.get(wi.Id).Workload__c != wi.Workload__c && wi.Workload__c != NULL)){
                workLoadIds.add(wi.Workload__c);
            }

			if(deliveryModeFilters.contains(wi.Delivery_Mode__c)&&wi.Response__c!=null){
    			responseIds.add(wi.Response__c);
    			filteredList.add(wi);
    		}

            setWorkitemCompletedBy(oldWorkItems.get(wi.Id), wi);
        }

		updateOwner(workItemIds,workLoadIds);
		beforeInsert_setContactOnWorkItem(filteredList,responseIds);

	}

	 /**
    * @description This Method is called from AferterUpdate and AfterInsert handler to update response status to inprogress
    * @author Steven zhu
    * @date 13/10/2016
    */
	private static void setResponseToInProgress(Set<ID>wiIDs)
	{
		Set<String> applicableTypes= new Set<String>{'Questionnaire', 'Access Code'};
		
		if(wiIDs.isEmpty()){return;}
		Map<Id,Response__c>updResps=new Map<Id,Response__c>();
		for( Work_item__c wi: [select id, Response__c, Response__r.id, Response__r.status__c
			from Work_Item__c
			where id in:wiIDs and work_item_type__c in :applicableTypes 
			and Response__r.Collection_Instance__r.Collection__r.recordtype.Name!='Census' // non-census collection
			and Response__r.status__c = 'Loaded' // stil loaded
			]){
			wi.Response__r.status__c='In Progress';
			updResps.put(wi.Response__c, wi.Response__r);
		}
		if(!updResps.isEmpty()){
			update updResps.values();
		}
	}

	private static void setWorkitemCompletedBy(Work_Item__c oldWorkItem, Work_Item__c newWorkItem){
		if(newWorkItem!=null && 'Completed'.equals(newWorkItem.Status__c)){
			if(oldWorkItem==null || !oldWorkItem.Status__c.equals(newWorkItem.Status__c)){
				newWorkItem.Completed_By__c = UserInfo.getUserId();
				newWorkItem.Completed_Date_Time__c = Datetime.now();
			}
		}
	}
    
    /**
    * @description TThis Method is called from AferterUpdate and AfterInsert handler to Update Status on Work Load based on Work Items status
     * @author Steven zhu
    * @date 13/10/2016
    */
    private static void updateWorkLoadStatus(Set<Id> workLoadIds){
		system.debug(loggingLevel.Info, 'DML limits: ' + system.Limits.getDMLRows());
        
        if(workLoadIds.isEmpty()){return;}
        Workload__c[]queryWorkLoads = new Workload__c[]{};
        Map<Id,Workload__c>nMap=new Map<Id,Workload__c>([select id, (select id from Work_items__r where status__c='New' limit 1) from Workload__c where id in:workLoadIds]),
        	ipMap=new Map<Id,Workload__c>([select id, (select id from Work_items__r where status__c='In Progress' limit 1) from Workload__c where id in:workLoadIds]),
        	cMap=new Map<Id,Workload__c>([select id, (select id from Work_items__r where status__c='Completed' limit 1) from Workload__c where id in:workLoadIds]);
        for(Id x:workLoadIds){
        	Workload__c nw=nMap.get(x),ipw=ipMap.get(x),cw=cMap.get(x);
        	integer n=(nw!=null)?nw.Work_Items__r.size():0,
        		ip=(ipw!=null)?ipw.Work_Items__r.size():0,
        		c=(cw!=null)?cw.Work_Items__r.size():0;
			Workload__c temp=new Workload__c(id=x);
			temp.Workload_Status__c=null;//default
			if(ip==0&&c==0&&n>0){temp.Workload_Status__c='Not Started';}
			else if(c>0&&ip==0&&n==0){temp.Workload_Status__c='Complete';}
			else if(c>0||n>0||ip>0){temp.Workload_Status__c='In Progress';}
			queryWorkLoads.add(temp);
        }
        if(!queryWorkLoads.isEmpty()){
            update queryWorkLoads;
        }
    }
    
     /**
    * @description This Method is called from BeforeUpdate and BeforeInsert handler to update owner of Work Items to work load's owner
     * @author Steven zhu
    * @date 13/10/2016
    */
    private static void updateOwner(Set<Id> workItemIds,Set<Id> workLoadIds)
	{
		system.debug(loggingLevel.Info, 'DML limits: ' + system.Limits.getDMLRows());
                
        if(!workLoadIds.isEmpty()){
            Map<Id,Workload__c> workLoads = new Map<Id,WorkLoad__c>([Select Id,OwnerId from Workload__c where Id in :workLoadIds]);
            for(Work_Item__c wi: [select Id, ownerId,Workload__c from Work_Item__c where id in :workItemIds and Workload__c in :workLoadIds]){
                wi.OwnerId = workLoads.get(wi.Workload__c).OwnerId;
			}
        } 
    }
    
	/**
    * @description This Method is called from BeforeInsert handler to set the contact on a workitem if contact is populated on the response
     * @author Steven zhu
    * @date 13/10/2016
    */
    private static void beforeInsert_setContactOnWorkItem(Work_item__c[] filteredList, Set<ID> responseIds)
	{
    	
		system.debug(logginglevel.INFO, filteredList);
    	if(filteredList.isEmpty()){return;}
    	Map<Id,Response__c>responseMap=new Map<Id,Response__c>([select id, contact__c from Response__c where id in:responseIds]);
    	for(Work_Item__c wi: filteredList){
    		if(responseMap.containsKey(wi.Response__c)){
    			wi.contact__c = responseMap.get(wi.Response__c).contact__c;
    		}
    	}
    	// only used in Before Insert, no DML
    }
        
    public static Boolean isWorkItemTypeValid(String newWorkItemType){
        Set<String> validWorkitemTypes = getValidWorkitemTypes();
        return validWorkitemTypes.contains(newWorkItemType);
    }

    private static Set<String> workitemTypes;
    public static Set<String> getValidWorkitemTypes(){
        if(workitemTypes == null){
            System.debug('retrieving work item types');
            Schema.DescribeFieldResult workitemTypeField = Work_Item__c.Work_Item_Type__c.getDescribe();
            List<Schema.PicklistEntry> workitemTypesList = workitemTypeField.getPicklistValues();

            workitemTypes = new Set<String>();
            for(Schema.PicklistEntry workitemType:workitemTypesList){
                workitemTypes.add(workitemType.getValue());
            } 
        }
        return workitemTypes;
    }

    private static String validWorkitemTypesStr_private;
    public static String getValidWorkitemTypesString(){
        if(validWorkitemTypesStr_private == null){
            validWorkitemTypesStr_private = '';
            for(String validType:getValidWorkitemTypes()){
                validWorkitemTypesStr_private += validType+', ';
            }
            validWorkitemTypesStr_private = validWorkitemTypesStr_private.removeEnd(', ');
        }
        return validWorkitemTypesStr_private;
    }
}