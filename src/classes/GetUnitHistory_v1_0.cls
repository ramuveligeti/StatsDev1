@RestResource(urlMapping='/GetUnitHistory/1.0/*')
global class GetUnitHistory_v1_0 {

	@HttpPost
	global static void sync() {  
		ResponseContainer responseContainer = new ResponseContainer();

		if(RestContext.request.requestBody!=null && String.isNotBlank(RestContext.request.requestBody.toString())){
			if(Logger.isEnabled()){
				System.debug('RestContext.request.requestBody = '+RestContext.request.requestBody.toString());
			}
			RequestContainer requestContainer = (RequestContainer)System.JSON.deserialize(RestContext.request.requestBody.toString(), GetUnitHistory_v1_0.RequestContainer.class);
			if(Logger.isEnabled()){
				System.debug('requestContainer = '+requestContainer);
			}

			List<Id> workItemIds = requestContainer.whatId;
			if(workItemIds==null || workItemIds.isEmpty()){
				workItemIds = requestContainer.workItemIds;
			}

			if(workItemIds!=null && !workItemIds.isEmpty()){
				List<Work_Item__c> workItems = [select Response__r.Unit_of_Interest__c from Work_Item__c where Id in :workItemIds];
				if(Logger.isEnabled()){
					System.debug('Found workitems: '+workitems.size());
				}
				//unitID, list work item ids
				Map<Id, Set<Id>> unitIdsToWorkItemIdsMap = new Map<Id, Set<ID>>();
				for(Work_Item__c workItem:workItems){
					Set<Id> unitWorkitemIds = null;
					if(unitIdsToWorkItemIdsMap.containsKey(workItem.Response__r.Unit_of_Interest__c)){
						unitWorkitemIds = unitIdsToWorkItemIdsMap.get(workItem.Response__r.Unit_of_Interest__c);
					}else{
						unitWorkitemIds = new Set<Id>();
					}
					unitWorkitemIds.add(workItem.Id);
					unitIdsToWorkItemIdsMap.put(workItem.Response__r.Unit_of_Interest__c, unitWorkitemIds);
				}
				if(Logger.isEnabled()){
					System.debug('unitIdsToWorkItemIdsMap: '+unitIdsToWorkItemIdsMap);
				}

				Map<Id, Work_Item__c> historicalWorkitems = new Map<Id, Work_Item__c>([select 
						Response__r.Unit_of_Interest__c,
						Response__r.Wave_Start_Date__c,
						Notes__c
					from 
						Work_Item__c 
					where 
						Response__r.Unit_of_Interest__c in :unitIdsToWorkItemIdsMap.keySet() and
						Id not in :workItemIds
				]);
				if(Logger.isEnabled()){
					System.debug('historicalWorkitems: '+historicalWorkitems.size());
				}


				List<Task> historicalTasks = [select 
						WhatId,
						Subject, 
						Action_Date_Time__c, 
						CreatedDate, 
						Type
					from Task where WhatId in :historicalWorkitems.keySet()
				];
				if(Logger.isEnabled()){
					System.debug('historicalTasks: '+historicalTasks.size());
				}

				Map<Id, List<Task>> unitIdToTasksMap = new Map<Id, List<Task>>();
				for(Task task:historicalTasks){
					Id unitId = historicalWorkitems.get(task.WhatId).Response__r.Unit_of_Interest__c;
					
					List<Task> tasks = null;
					if(unitIdToTasksMap.containsKey(unitId)){
						tasks = unitIdToTasksMap.get(unitId);
					}else{
						tasks = new List<Task>();
					}
					tasks.add(task);

					unitIdToTasksMap.put(unitId, tasks);
				}
				if(Logger.isEnabled()){
					System.debug('unitIdToTasksMap = '+unitIdToTasksMap);
				}

				Map<Id, List<Work_Item__c>> unitIdToWorkitemsMap = new Map<Id, List<Work_Item__c>>();
				for(Work_Item__c wi:historicalWorkitems.values()){
					if(String.isNotBlank(wi.Notes__c) && wi.Response__r.Wave_Start_Date__c!=null){
						Id unitId = wi.Response__r.Unit_of_Interest__c;
						
						List<Work_Item__c> unitWorkitems = null;
						if(unitIdToWorkitemsMap.containsKey(unitId)){
							unitWorkitems = unitIdToWorkitemsMap.get(unitId);
						}else{
							unitWorkitems = new List<Work_Item__c>();
						}
						unitWorkitems.add(wi);

						unitIdToWorkitemsMap.put(unitId, unitWorkitems);
					}
				}
				if(Logger.isEnabled()){
					System.debug('unitIdToWorkitemsMap = '+unitIdToWorkitemsMap);
				}
				
				if(!unitIdToTasksMap.isEmpty()){
					for(Id unitId:unitIdToTasksMap.keySet()){
						Container c = new Container();
						c.workItemIds = unitIdsToWorkItemIdsMap.get(unitId);
						c.tasks = convert(unitIdToTasksMap.get(unitId));
						List<Work_Item__c> historyItems = unitIdToWorkitemsMap.get(unitId);
						if(Logger.isEnabled()){
							System.debug('historyItems = '+historyItems);
						}
						c.historyWorkItems = convert(historyItems);
						if(Logger.isEnabled()){
							System.debug('Container = '+c);
						}
						responseContainer.container.add(c);
					}
				}
			}
		}

		String json = responseContainer.toJson();
		if(Logger.isEnabled()){
			System.debug('response json = '+json);
		}
		RestContext.response.responseBody = Blob.valueOf(json);
		RestContext.response.headers.put('Content-Type', 'application/json; charset="utf-8"');
		RestContext.response.statusCode = 200;
	}

	private static List<HistoryItem> convert(List<Task> tasks){
		List<HistoryItem> historyItems = new List<HistoryItem>();
		if(tasks!=null && !tasks.isEmpty()){
			for(Task task:tasks){
				HistoryItem historyItem = new HistoryItem(task);
				historyItems.add(historyItem);
			}
		}
		return historyItems;
	}

	private static List<Workitem> convert(List<Work_Item__c> workitems){
		List<Workitem> historyWorkitems = new List<Workitem>();
		if(workitems!=null && !workitems.isEmpty()){
			for(Work_Item__c wi:workitems){
				Workitem historyItem = new Workitem(wi);
				historyWorkitems.add(historyItem);
			}
		}
		return historyWorkitems;
	}

	private class RequestContainer{
		public List<String> workItemIds;
		public List<String> whatId;
	}

	@TestVisible
	private class ResponseContainer{
		public List<Container> container = new List<Container>();

		public String toJson(){
			Map<String, Object> mapp = toMap();
			String jsonStr = JSON.serialize(mapp);
			return jsonStr;
		}

		public Map<String, Object> toMap(){
			Map<String, Object> responsetContainerMap = new Map<String, Object>();
			if(container!=null){
				List<Object> objs = new List<Object>();
				for(Container con:container){
					objs.add(con.toMap());
				}
				responsetContainerMap.put('container', objs);
			}
			return responsetContainerMap;
		}
	}

	private class Container{
		public Set<Id> workItemIds;
		public List<HistoryItem> tasks;
		public List<Workitem> historyWorkItems;

		public Map<String, Object> toMap(){
			Map<String, Object> containerMap = new Map<String, Object>();
			if(workItemIds!=null && !workItemIds.isEmpty()){
				containerMap.put('workItemIds', workItemIds);
			}
			if(tasks!=null && !tasks.isEmpty()){
				List<Object> objs = new List<Object>();
				for(HistoryItem task:tasks){
					objs.add(task.toMap());
				}
				if(!objs.isEmpty()){
					containerMap.put('tasks', objs);
				}

				List<Object> objsHI = new List<Object>();
				for(Workitem historyWorkItem:historyWorkItems){
					objsHI.add(historyWorkItem.toMap());
				}
				if(!objsHI.isEmpty()){
					containerMap.put('historyWorkItems', objsHI);
				}
			}
			return containerMap;
		}
	}

	public class HistoryItem{
		public String subject;
		public DateTime actTime;
		public String type;

		public HistoryItem(Task sfTask){
			this.subject = sfTask.Subject;
			if(sfTask.Action_Date_Time__c != null){
				this.actTime = sfTask.Action_Date_Time__c;
			}else{
				this.actTime = sfTask.CreatedDate;
			}
			this.type = sfTask.Type;
		}

		public Map<String, Object> toMap(){
			Map<String, Object> history = new Map<String, Object>();

			if(String.isNotBlank(this.subject)){
				history.put('subject', this.subject);
			}
			if(actTime!=null){
				history.put('actTime', this.actTime);
			}
			if(String.isNotBlank(this.type)){
				history.put('type', this.type);
			}

			return history;
		}
	}

	private class Workitem{
		String id;
		String notes;
		DateTime waveStartDate;

		public Workitem(){}

		public Workitem(Work_Item__c sfWorkitem){
			this.id = sfWorkitem.Id;
			this.notes = sfWorkitem.Notes__c;
			this.waveStartDate = sfWorkitem.Response__r.Wave_Start_Date__c;
		}

		public Map<String, Object> toMap(){
			Map<String, Object> workitem = new Map<String, Object>();

			if(String.isNotBlank(this.id)){
				workitem.put('id', this.id);
			}
			if(String.isNotBlank(this.notes)){
				workitem.put('notes', this.notes);
			}
			if(this.waveStartDate!=null){
				workitem.put('waveStartDate', this.waveStartDate);
			}
			return workitem;
		}
	}
}