/**
* @description This is an extension controller for CreateWorkItems and ScheduleWorkItems Page. 
* @author Ram Veligeti
* @date 1.Apr.2015
*/
public class CreateWorkItemsExCon {
    public static List<Work_Item_Creation_Filters__c> createWorkItemsConfig = Work_Item_Creation_Filters__c.getAll().values();
    public List<filterWrapper> filterWrapperList {get;set;}
    public Integer removeId { get; set; }
    public boolean renderFilterScreen{get;set;}
    public Map<String,Work_Item_Creation_Filters__c> createWorkItemsMap = new Map<String, Work_Item_Creation_Filters__c>();
    public List<Activity_Schedule__c> actSchList = new List<Activity_Schedule__c>();
    public Boolean applyFilters{get;set;}
    public String filterLogic{get;set;}
    public Boolean applyFilterLogic{get;set;}
    public Integer sequence{get;set;}
    public Boolean displayContent{get;set;}
    public List<SelectOption> filterList{get;set;}
    public String preUsedFilter {get;set;}
    public List<SelectOption> filterType{get;set;}
    public String selectedFilter {get;set;}
    public Map<String,Activity_Schedule_Filter__c> filterMap = new Map<String,Activity_Schedule_Filter__c>();
    public List<Activity_Schedule_Filter__c> asFilterList{get;set;}
    public Boolean immediateExtract{get;set;}
    public List<Activity_Schedule_Filter__c> asfList{get;set;}
    public Id editRecordId{get;set;}
    public Activity_Schedule__c actSch{get;set;}
    public Activity_Schedule_Filter__c actSchFilter{get;set;}
    public Boolean filterNameReadOnly{get;set;}
    public List<SelectOption> filters{get;set;}
	public String estimatedWorkItemsCount{get;Set;}
	public String groupingId;

    private List<Integer> filterLogicList = new List<Integer>();
    private Set<Integer> filterLogicSet = new Set<Integer>();
    private Set<String> selectedFilters = new Set<String>();
    private String queryString{get;set;}
    private String filterCriteria;
    private String filterCriteriaString;
	private Map<String, Schema.SObjectField> groupingFieldMap = Schema.SObjectType.Grouping__c.fields.getMap();
	private String groupingFieldNames = ApexUtility.getFieldNamesOfSObject(groupingFieldMap,true);
	private Grouping__c grp = new Grouping__c();
    private String action;
	private String nullAllowedDataTypes = 'Datetime,Date,Decimal,Integer,String';
	private Collection_Instance__c collectionIns;
	private String collectionId;
	private Set<Integer> groupingFilterRowId = new Set<Integer>();
    

    //Standard Controller - Constructor
    //This controller is called from NewActivitySchedule & ActivityScheduleFilters VF page
	//The exception is written to handle Pre-defined filters logic for ActivityScheduleFilters VF page
	//Using the same constructor for two different objects Activity Schedule and Activity Schedule Filters
    public CreateWorkItemsExCon(ApexPages.StandardController stdCont){
        if(stdCont.getRecord().getSObjectType() == Schema.Activity_Schedule__c.SObjectType){
            actSch = (Activity_Schedule__c)stdCont.getRecord();
            collectionIns = [Select Collection__c,Grouping__c,RecordType.Name,Net_Responses__c from Collection_Instance__c where Id = :actSch.Collection_Instance__c];
			collectionId = collectionIns.Collection__c;
			groupingId = collectionIns.Grouping__c;
            initialize();
        }else{
            actSchFilter = (Activity_Schedule_Filter__c)stdCont.getRecord();
            action = ApexPages.currentPage().getParameters().get('action');
			groupingId = actSchFilter.Grouping__c;
			collectionId = actSchFilter.Collection__c;
			//Intializes required methods
            initialize();
			//Actions to be taken on Edit of Activity Schedule Filters
            if(action == 'edit'){
                filterWrapperList = new List<filterWrapper>();
                editRecordId = actSchFilter.Id;
                editFilter();
                applyFilters = true;
            } else { //Actions to be taken on Create
                selectedFilter = 'Custom Filter';
                //fetchExistingFilters();
                //initialize();
                asfList = new List<Activity_Schedule_Filter__c>();
                asFilterList= new List<Activity_Schedule_Filter__c>();
                activateFilters();
            }
        }
    }
    
    //This method called from the controllers to initialize required setup 
    public void initialize(){
        //Query Schedule Date time from Activity Schedule object
        filterList = new List<SelectOption>();
        displayContent =true;
        filterNameReadOnly = false;
        applyFilters = false;
        renderFilterScreen = true;
        applyFilterLogic = false;
        filterWrapperList = new List<filterWrapper>();
        selectFilterType();
        //predefinedFilters();
        fetchFilters();
    }
    
	//Method to form query string for Groupings
	public String queryStringGroupings(String groupingId){
		String groupingQuery = 'select '+groupingFieldNames;
		groupingQuery += ' from Grouping__c where Id = \'';
		groupingQuery += groupingId;
		groupingQuery += '\'';
		return groupingQuery;
	}

    //This method is called from ScheduleWorkItems VF Page
    //Method creates record in Activity Schedule Filter Object
    //And schedules batch job based on the Scheduled Date time from Activity Schedule
    public pageReference scheduleWorkItems(){
        //actSch = [Select Id,Frequency__c,Occurrence__c,Scheduled_Date_time__c,Collection_Instance_Name__c from Activity_Schedule__c where Id = :activityScheduleId];
        if(validateFilterScreen() && validateFilterLogic()){
            Savepoint sp;
            try{
                sp = Database.setSavepoint();
                if(actSch.Delivery_Mode__c == NULL || actSch.Collection_Instance__c == NULL || actSch.Work_Item_Type__c == NULL || actSch.Scheduled_Date_time__c == NULL || actSch.Frequency__c == NULL){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Required fields are missing'));
                    return null;
                }
                if(actSch.Scheduled_Date_time__c < system.now()){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Scheduled Date time must be greater than Current Date time'));
                    return null;
                }
                if(actSch.Occurrence__c <=0 || actSch.Occurrence__c == NULL){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Occurrence must be greater than 0'));
                    return null;
                }
                if(selectedFilter == 'Custom Filter' && actSch.Filter_Name__c == NULL){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide filter name'));
                    return null;
                }
                if(actSch.Output_CSV_Format__c == NULL && immediateExtract){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Please provide value for Output CSV Format'));
                    return null;
                }

                actSch.Status__c = 'Scheduled';
                actSch.QueryString__c = queryString;
                actSch.Filter_Criteria__c = filterCriteria;
                actSch.Filter_Criteria_String__c = filterCriteriaString;
                actSch.Filter_Logic__c = filterLogic;
				actSch.Estimated_Work_Items_Count__c = estimatedWorkItemsCount;
                upsert actSch;
                System.debug('actSch=='+actSch);
                                            
                asFilterList = new List<Activity_Schedule_Filter__c>();
                for(integer i=1;i<=actSch.Occurrence__c;i++){
                    //Capture the filter details in Activity Schedule filter object
                    Activity_Schedule_Filter__c actSchFilter = new Activity_Schedule_Filter__c();
                    actSchFilter.QueryString__c = queryString;
                    actSchFilter.Filter_Criteria__c = filterCriteria;
                    actSchFilter.Filter_Criteria_String__c = filterCriteriaString;
                    actSchFilter.Filter_Logic__c = filterLogic;
                    actSchFilter.Activity_Schedule__c = actSch.Id;
                    actSchFilter.Scheduled_Date_time__c = actSch.Scheduled_Date_time__c;
					actSchFilter.Immediate_Extract__c = immediateExtract;
                    actSchFilter.Status__c = 'Scheduled';
                    
                    asFilterList.add(actSchFilter);
                    
                    if(actSch.Frequency__c.equalsIgnoreCase('Daily')){
                        actSch.Scheduled_Date_time__c = actSch.Scheduled_Date_time__c.addDays(1);
                    }
                    if(actSch.Frequency__c.equalsIgnoreCase('Weekly')){
                        actSch.Scheduled_Date_time__c = actSch.Scheduled_Date_time__c.addDays(7);
                    }
                    if(actSch.Frequency__c.equalsIgnoreCase('Fortnightly')){
                        actSch.Scheduled_Date_time__c = actSch.Scheduled_Date_time__c.addDays(14);
                    }
                    if(actSch.Frequency__c.equalsIgnoreCase('Monthly')){
                        actSch.Scheduled_Date_time__c = actSch.Scheduled_Date_time__c.addMonths(1);
                    }
                }
                
                if(!asFilterList.isEmpty()){
                    insert asFilterList;
                }
                system.debug('asFilterList=='+asFilterList);
                List<Group> gr =	[Select Id,Name,Type
                                     from Group
                                     where DeveloperName = 'Unallocated_Phone_Work_Items'
                                     and Type = 'Queue'
                                    ];
                
                Id OwnerId = (gr.size()>0?gr[0].Id:NULL);
                //Modified this logic as part of ECP-3304
				List<Activity_Schedule_Filter__c> aList = new List<Activity_Schedule_Filter__c>();
				asFilterList = [Select Id,Activity_Schedule__r.Collection_Instance__r.RecordType.Name,Scheduled_Date_time__c,Immediate_Extract__c from Activity_Schedule_Filter__c where Id in :asFilterList];
                for(Activity_Schedule_Filter__c asf: asFilterList){
					if(asf.Scheduled_Date_time__c.date() < System.today().addDays(1)){
						if(asf.Activity_Schedule__r.Collection_Instance__r.RecordType.Name.equalsIgnoreCase('Census')){
							//Send to mulesoft
							ActivityScheduleExtractClient.submitRequestAsync('Create', asf.Id,0);
							continue;
						}
						//Calculate minutes between current date time and scheduled date time, to schedule batch apex
						Integer mins = Integer.valueOf(Math.Floor(Decimal.valueOf((asf.Scheduled_Date_time__c.getTime() - system.now().getTime()))/ (1000.0*60.0)));
						//Schedule Batch Apex
						CreateWorkItemsBatch cwib = new CreateWorkItemsBatch(queryString,actSch.Collection_Instance_Name__c,asf.Id,actSch.Id,OwnerId,asf.Immediate_Extract__c);
						asf.Schedule_Job_Id__c = System.scheduleBatch(cwib, 'Create Work Items '+system.now()+asf.Id, mins);
						aList.add(asf);
					}
                }
                
                if(!aList.isEmpty()){update aList;}

                return new PageReference('/'+actSch.Id);
            }catch (exception e){
                actSch.Id = null;
                Database.rollback(sp);
				System.debug('e==='+e.getMessage());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
                return null;
            }
        }else{
            return null;
        }
    }
    
    //Get the filter values from Custom setting to form a picklist 
    public void fetchFilters() {
        filters = new List<SelectOption>();
        createWorkItemsConfig.sort();
        filters.add(new SelectOption('','--None--'));
        for(Work_Item_Creation_Filters__c st: createWorkItemsConfig){
            //system.debug('st.Field_API__c==='+st.Field_API__c+'=='+st.Name);
            filters.add(new SelectOption(st.Field_API__c,st.Name));
            createWorkItemsMap.put(st.Field_API__c,st);
        }
		//System.debug('groupingId=='+groupingId);
		//This method create filters for grouping
		assignGroupingFilters(groupingId);
    }

	//Assing grouping filters from grouping record
	public void assignGroupingFilters(String grpId){
		//Fetch grouping labels from Collection Instance 
		//Add the labels to filter options
		if(String.isNotBlank(grpId)){
			SelectOption blankOption = new SelectOption('', '');
			blankOption.setDisabled(true);

			String sectionTitle = '--- Groupings ---';
			SelectOption titleOption = new SelectOption(sectionTitle, sectionTitle);
			titleOption.setDisabled(true);
			filters.add(blankOption);
			filters.add(titleOption);
			filters.add(blankOption);
			String groupingQuery = queryStringGroupings(grpId);
			grp = Database.query(groupingQuery);
			for(String grFldName: groupingFieldNames.split(',')){
				if(grFldName.containsIgnoreCase('GR_') && grp.get(grFldName) != NULL){
					filters.add(new SelectOption(grFldName,(String)grp.get(grFldName)));
				}
			}
		}
	}

	//Set grouping filters on selection of grouping record on Activity Schedule filter page
	public void setGroupingFilters(){
		if(actSchFilter.Grouping__c != null){
			groupingId =(String)actSchFilter.Grouping__c;
			fetchFilters();
		}else{
			groupingId = null;
			fetchFilters();
		}

		if(filterWrapperList.isEmpty()){return;}
		for(integer i=filterWrapperList.size()-1; i>=0; i--){
			if(filterWrapperList[i].filterOption != NULL && filterWrapperList[i].filterOption.containsIgnoreCase('GR_')){
				filterWrapperList.remove(i);
			}
		}
		restructureFilterWrapperList();
	}

    //Add function to generate more rows on Filter Screen
    public void addFilter(){
        if(validateFilterScreen()){
            //system.debug('filterLogic=='+filterLogic);
            for(filterWrapper fw: filterWrapperList){
                fw.andOperator = 'AND';
            }
            
            filterWrapper fw = new filterWrapper();
            fw.uniqueId = filterWrapperList.size();
            fw.sequence = filterWrapperList.size()+1;
            fw.dataType = null;
            fw.ci = new Collection_Instance__c();
            filterWrapperList.add(fw);

			//Filter logic sequence is automatically formed if the user doesn't click on 'Add Filter Logic' link
            if(!applyFilterLogic){
                filterLogicSet.add(fw.sequence);
                filterLogicList.clear();
                filterLogicList.addAll(filterLogicSet);
                filterLogic = String.join(filterLogicList,' AND ');
                system.debug('filterLogicSet=='+filterLogicSet+'=='+filterLogicList+'=='+filterLogic);
            }
        }
    }
    
    //Clear filter logic
    public void clearFilterLogicMethod(){
        applyFilterLogic = false;
        filterLogicList.clear();
        filterLogicSet.clear();
        
        for(integer i=0; i<filterWrapperList.size(); i++){
            filterLogicSet.add(filterWrapperList[i].sequence);
        }
        filterLogicList.addAll(filterLogicSet);
        filterLogic = String.join(filterLogicList,' AND ');
    }

    //Remove function to remove rows from Filter Screen
    public void removeSelected(){
        filterWrapperList.remove(removeId);
		restructureFilterWrapperList();
    }

	void restructureFilterWrapperList(){
        filterLogicList.clear();
        filterLogicSet.clear();
        for(integer i=0; i<filterWrapperList.size(); i++){
            filterWrapperList[i].uniqueId = i;
            filterWrapperList[i].sequence = i+1;
            if(filterWrapperList.size()-1 == i){
                filterWrapperList[i].andOperator = Null;
            }
            filterLogicSet.add(filterWrapperList[i].sequence);
        }

        //Form the filter logic 
        if(!applyFilterLogic){
            filterLogicList.addAll(filterLogicSet);
            filterLogic = String.join(filterLogicList,' AND '); 
        }
	}
    
    //Method to set the Value field based on the Option Selected
    public void changeValueDataType(){
        String fOption = filterWrapperList[sequence-1].filterOption;
		resetFilterVariables();
		if(String.isBlank(fOption)){return;}

        //filterWrapperList[sequence-1].filterOperator = NULL;
        filterWrapperList[sequence-1].operators = new List<SelectOption>();
        filterWrapperList[sequence-1].operators.add(new SelectOption('','--None--'));
        filterWrapperList[sequence-1].operators.add(new SelectOption('=','equals'));
        filterWrapperList[sequence-1].operators.add(new SelectOption('!=','not equal to'));
		if(fOption.containsIgnoreCase('GR_')){
			List<SelectOption> filterOpertors = assignFilterOperators('String');
			filterWrapperList[sequence-1].dataType = 'String';
			//Forming the grouping value API from grouping label. Eg: GR_1_Label__c to GV1__c
			String groupingValApi = 'GV'+fOption.split('_')[1]+'__c'; 
			String gropuingVal = (String)grp.get(groupingValApi);
			if(String.isNotBlank(gropuingVal)){
				filterWrapperList[sequence-1].dataType = 'Picklist';
				filterWrapperList[sequence-1].picklistOptions = fetchGroupingPicklistValues(gropuingVal);
			}
			//System.debug('sequence=='+(sequence-1));
			groupingFilterRowId.add(sequence-1);
			return;
		}
        //system.debug('createWorkItemsMap=='+createWorkItemsMap+'=='+fOption+'=='+groupingFilterRowId);
        List<SelectOption> filterOpertors = assignFilterOperators(createWorkItemsMap.get(fOption).Data_Type__c);
        if(filterOpertors.size()>0){
            filterWrapperList[sequence-1].operators.addAll(filterOpertors);
        }
        
        if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('String')){
            filterWrapperList[sequence-1].dataType = 'String';
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Decimal') || createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Integer')){
            filterWrapperList[sequence-1].dataType = 'String';
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Lookup')){
            filterWrapperList[sequence-1].dataType = 'Lookup';
            filterWrapperList[sequence-1].operators.remove(2); //remove not equal to
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Boolean')){
            filterWrapperList[sequence-1].dataType = 'Boolean';
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Date')){
            filterWrapperList[sequence-1].dataType = 'Date';
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Datetime')){
            filterWrapperList[sequence-1].dataType = 'Datetime';
        } else if(createWorkItemsMap.get(fOption).Data_Type__c.equalsignorecase('Picklist')){
            filterWrapperList[sequence-1].dataType = 'Picklist';
            String apiName;
            
            //Check if the API Name contains references to other object fields like Unit_of_Interest__r.Address_Type__c
            //Fetch only field API Name from the string
            //Assign to fOption directly if '.' is not found
            if(fOption.contains('.')){
                List<String> apiList = fOption.split('\\.');
                apiName = apiList[apiList.size()-1];
            } else {
                apiName = fOption;
            }
            
            //Fetch the picklist values for the field based on the Object and API Name of the field
            filterWrapperList[sequence-1].picklistOptions = ApexUtility.getPicklistValues(createWorkItemsMap.get(fOption).Object__c,apiName,true);
        }else{
            filterWrapperList[sequence-1].dataType = NULL;
        }
        
        filterWrapperList[sequence-1].value = null;
		//System.debug('filterWrapperList345=='+filterWrapperList);
    }

	//Reset filter variables
	private void resetFilterVariables(){
		filterWrapperList[sequence-1].operators = new List<SelectOption>();			
		filterWrapperList[sequence-1].dataType = null;
		filterWrapperList[sequence-1].picklistOptions = new List<SelectOption>();
		filterWrapperList[sequence-1].value = null;
		filterWrapperList[sequence-1].dateValue = null;
		filterWrapperList[sequence-1].datetimeValue = null;
		filterWrapperList[sequence-1].ci = new Collection_Instance__c();
	}
    
	//Assign filter operators based on datatype
    public List<SelectOption> assignFilterOperators(String dataType){
        List<SelectOption> operatorList = new List<SelectOption>();
        if(dataType.equalsignorecase('Datetime') || dataType.equalsignorecase('Date') || dataType.equalsignorecase('Decimal') || dataType.equalsignorecase('Integer')){
            operatorList.add(new SelectOption('>','greater than'));
            operatorList.add(new SelectOption('<','less than'));
            operatorList.add(new SelectOption('>=','greater or equal'));
            operatorList.add(new SelectOption('<=','less or equal'));
			operatorList.add(new SelectOption('= null','is null'));
			operatorList.add(new SelectOption('!= null','is not null'));
        } else if(dataType.equalsignorecase('String')){
            operatorList.add(new SelectOption('like','contains'));
            operatorList.add(new SelectOption('not like','does not contain'));
            operatorList.add(new SelectOption('starts','starts with'));
			operatorList.add(new SelectOption('= null','is null'));
			operatorList.add(new SelectOption('!= null','is not null'));
        }
        
        return operatorList;
    }

	//create picklist values from grouping val. Eg: Hotel,Motel
	private List<SelectOption> fetchGroupingPicklistValues(String grpVal){
		List<SelectOption> groupingValues = new List<SelectOption>();
		groupingValues.add(new SelectOption('','--None--'));
		for(String st: grpVal.split(',')){
			groupingValues.add(new SelectOption(st,st));
		}
		return groupingValues;
	}

    //Add filter logic
    public void applyFilterLogicMethod(){
        applyFilterLogic = true;
    }
    
    //To validate Filter screen
    private Boolean validateFilterScreen(){
        //system.debug('actSch=='+actSch);
        //if(actSch != NULL) validations();
        if(applyFilters){
            if(filterWrapperList.isEmpty() && preUsedFilter == NULL && selectedFilter == 'Predefined Filter'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please select predefined filter'));
                return false;
            }
            //system.debug('filterWrapperList12=='+filterWrapperList);
            for(filterWrapper fw: filterWrapperList){
                if(fw.dataType == 'Date' && fw.ci.Planned_Start_Date__c != NULL){
                    fw.datetimeValue = fw.ci.Planned_Start_Date__c;
                    fw.value = fw.datetimeValue.format('yyyy-MM-dd');
                }
                
                if(fw.dataType == 'Datetime' && fw.ci.Planned_Close_Off__c != NULL){
                    fw.value = fw.ci.Planned_Close_Off__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                }
                
                if(fw.dataType == 'Lookup'){
                    String query = 'Select Id from '+createWorkItemsMap.get(fw.filterOption).Object__c+' where Name = \''+fw.lookupValue+'\'';
                    //system.debug('query=='+query);
                    try{
                        List<SObject> obj = Database.query(query);
                        if(!obj.isEmpty()){
                            fw.value = (String)obj[0].get('Id');
                        } else {
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'No data found for '+createWorkItemsMap.get(fw.filterOption).Name+' with the given value '+fw.lookupValue));
                            return false;
                        }
                    } catch (exception e){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Error in the lookup value: '+e.getMessage()));
                        return false;
                    }
                }
                
                //system.debug('createWorkItemsMap==='+fw.dataType+'=='+nullAllowedDataTypes.containsIgnoreCase(fw.dataType)+'=='+fw.value+'=='+fw.filterOperator);
				if(!String.isEmpty(fw.dataType) && nullAllowedDataTypes.containsIgnoreCase(fw.dataType) && !String.isEmpty(fw.value) && fw.filterOperator.containsIgnoreCase('null')){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'You cannot provide value if the filter operator equals \'is null\' or \'is not null\''));
                    return false;
				}

				if(String.isEmpty(fw.filterOption) || String.isEmpty(fw.filterOperator)){
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide Filter, Operator and Value'));
					return false;
				}
				
				if(String.isEmpty(fw.value) && !fw.filterOperator.containsIgnoreCase('null')){
					//system.debug('fw.filterOption=='+fw.filterOption+'=='+fw.value+'=='+fw.sequence);
					//Provide error message on Page if the values are NULL
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide Filter, Operator and Value'));
					return false;
				}

                //Custom Setting value with data type Decimal must be validated against the Value provided on VF page
                if(!fw.filterOption.containsIgnoreCase('GR_') && createWorkItemsMap.get(fw.filterOption).Data_Type__c.equalsIgnoreCase('Decimal') && !fw.filterOperator.containsIgnoreCase('null')){
                    //Provide error message on Page if the value is not Decimal
                    try{
                        //Verify the value provided is Decimal
                        Decimal dec = Decimal.valueOf(fw.value);
                    }catch(exception e){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide only Decimal value for '+createWorkItemsMap.get(fw.filterOption).Name));
                        return false;
                    }
                }
                //Custom Setting value with data type Integer must be validated against the Value provided on VF page
                if(!fw.filterOption.containsIgnoreCase('GR_') && createWorkItemsMap.get(fw.filterOption).Data_Type__c.equalsIgnoreCase('Integer') && !fw.filterOperator.containsIgnoreCase('null')){
                    //Provide error message on Page if the value is not Integer
                    try{
                        //Verify the value provided is Integer
                        Integer Intg = Integer.valueOf(fw.value);
                    }catch(exception e){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide only Integer value for '+createWorkItemsMap.get(fw.filterOption).Name));
                        return false;
                    }
                }
            }
        }
        return true;
    }

	String parseFilterLogic(String filterLogic){
        if(filterLogic.containsAny('()')){
            filterLogic = filterLogic.replace('(','( ');
            filterLogic = filterLogic.replace(')',' )');
        }
		String hiddenFilterLogic;
		for(String st: filterLogic.split(' ')){
			try {	        
				Integer i = Integer.valueOf(st);
				if (hiddenFilterLogic!=null){
					hiddenFilterLogic += ' x'+i+'x';
				}else{
					hiddenFilterLogic = 'x'+i+'x';
				}
			}catch (exception e){
				if (hiddenFilterLogic!=null){
					hiddenFilterLogic += ' '+st;
				}else{
					hiddenFilterLogic = st;
				}
			}
		}
		return hiddenFilterLogic;
	}

    //To validate filter logic provided
    public Boolean validateFilterLogic(){
        String cntString;
        
        Id responseCanvassing_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Canvassing').getRecordTypeId();
        Id responseCensusDwelling_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
        Id responseCensusIndividual_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
        Id responseBusiness_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Business Response').getRecordTypeId();
        Id responseDwelling_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
        Id responseIndividual_rt_id = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();

        String responseRecordTypeIds = '(';
        responseRecordTypeIds += '\''+responseCanvassing_rt_id+'\', ';
        responseRecordTypeIds += '\''+responseCensusDwelling_rt_id+'\', ';
        responseRecordTypeIds += '\''+responseBusiness_rt_id+'\', ';
        responseRecordTypeIds += '\''+responseDwelling_rt_id+'\', ';
        responseRecordTypeIds += '\''+responseIndividual_rt_id+'\'';
        responseRecordTypeIds += ')';
       
        
        if(applyFilters){
            if(filterWrapperList.isEmpty() && String.isBlank(filterLogic) && selectedFilter == 'Custom Filter'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please check your Filter Logic: Add at least one filter condition'));
                return false;
            }
            String whereClause;
            if(filterWrapperList.isEmpty() && preUsedFilter != NULL && selectedFilter == 'Predefined Filter'){
                fetchPredefinedFilter();
				validateFilterScreen();
            }

            if(filterLogic != NULL){
                //system.debug('filterLogic=='+filterLogic);
                //String hiddenFilterLogic = filterLogic;
                //Filter logic pattern eg: 1 AND 2 AND (3 OR 4) AND 5
                //Suffix all the digits with 'x' as there are chances of having digits in the values entered by the user in the VF page eg: Wave__c = 12
                //If there are any numbers available in the String then replace method might replace them in the WhereClause
                //Its unlikely to have 1x , 2x kind of values. Final stirng looks like 1x AND 2x AND (3x OR 4x) AND 5x 
                /*Pattern p = Pattern.compile('(\\d+)');
                Matcher m = p.matcher( hiddenFilterLogic );
                system.debug('m===='+m);
                Set<String> intx = new Set<String>();
                
                //Using Pattern and Matcher to find digits in the filterLogic
                //Loop through the digits found and suffix them with 'x'
                if(m.find()) {
                    do {
                        if(!intx.contains(m.group())){
                            system.debug('m.group()=='+m.group());
                            intx.add(m.group());
                            hiddenFilterLogic = hiddenFilterLogic.replaceFirst(m.group(),m.group()+'x');
                            system.debug('hiddenFilterLogic=='+hiddenFilterLogic);
                        }
                    } while(m.find());
                }*/
                
                //Building the WhereClause
                //whereClause = hiddenFilterLogic;
				whereClause = parseFilterLogic(filterLogic);
				System.debug('whereClause123=='+whereClause);
				String filterClause = whereClause;
                //system.debug('filterWrapperList=='+filterWrapperList);
                filterCriteriaString = NULL;
                for(filterWrapper fw: filterWrapperList){
                    if(fw.filterOption == NULL || fw.filterOperator == NULL){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide proper filter options'));
                        return false;
                    }
                    
                    if(fw.lookupValue == NULL && (fw.value == NULL && !fw.filterOperator.containsIgnoreCase('null'))){
						ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please provide value'));
						return false;
					}

                    if(fw.dataType == 'Lookup'){
	                    filterCriteriaString += '~@~'+fw.filterOption+'~:~'+fw.filterOperator+'~:~'+fw.dataType+'~:~'+fw.lookupValue;
                    }else if(fw.filterOption.containsIgnoreCase('GR_')){
						filterCriteriaString += '~@~'+formatGroupingFilterCriteriaString(fw.filterOption,fw.filterOperator,fw.value);
					}else{
                        filterCriteriaString += '~@~'+fw.filterOption+'~:~'+fw.filterOperator+'~:~'+fw.dataType+'~:~'+(String.isBlank(fw.value)?null:fw.value);
                    }

                    //system.debug('fw=='+fw.filterOption+'=='+fw.filterOperator+'=='+fw.value+'==='+whereClause+'=='+filterCriteriaString);
					String filterCriteriaGroupingString;
                    if(whereClause.contains(String.valueOf(fw.sequence))){
                        //Format the options to suit the 'Where' clause
						String fieldValueString;
						//In case of gropuing filter, The actual filter selection would be like 'Accommodation Type' = 'Hotel' 
						//format the grouping fields to form a condition like (GR_1_Label__c = Accommodation Type AND GR_1__c = Hotel)
						if(fw.filterOption.containsIgnoreCase('GR_')){
							fieldValueString = formatGroupingFieldValueString(fw.filterOption,fw.filterOperator,fw.value);
							System.debug('fieldValueString=='+fieldValueString);
							filterCriteriaGroupingString = (String)grp.get(fw.filterOption)+' '+fw.filterOperator+' '+fw.value;
							filterClause = filterClause.replace('x'+String.valueOf(fw.sequence)+'x', filterCriteriaGroupingString);
						} else if(fw.dataType == 'Lookup'){
	                        fieldValueString = formatFieldValueString(fw.filterOption,fw.filterOperator,fw.value);
							String fieldLookupValueString = formatFieldValueString(fw.filterOption,fw.filterOperator,fw.lookupValue);
							filterClause = filterClause.replace('x'+String.valueOf(fw.sequence)+'x', fieldLookupValueString);
						} else {
	                        fieldValueString = formatFieldValueString(fw.filterOption,fw.filterOperator,fw.value);
							filterClause = filterClause.replace('x'+String.valueOf(fw.sequence)+'x', fieldValueString);
						}
                        
                        //Replace the filter logic with the field API Name and Value to form the 'where' clause for the Query
                        whereClause = whereClause.replace('x'+String.valueOf(fw.sequence)+'x', fieldValueString);
                    } else {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please check your Filter Logic:'));
                        return false;
                    }
                    selectedFilters.add(fw.filterOption);
                }            
                filterCriteria = filterClause.replaceAll('!=', 'not equal to');
            }
            //Forming the Select Query fields
            String queryFields = 'Id,Extension_Date__c ';
            for(String st: selectedFilters) {
                if(!queryFields.containsIgnoreCase(st))queryFields += ','+st;
            }
            
            if(actSch == NULL && actSchFilter != NULL){
                queryString =   'Select '
                                + queryFields
                                + ' from Response__c where ('
                                + whereClause
                                + ') and RecordtypeId in '+responseRecordTypeIds;
				cntString = 'Select Count() from Response__c where (' 
                                + whereClause
                                + ') and RecordtypeId in '+responseRecordTypeIds;
            } else {
                //Final query stirng to pass into Batch apex
                queryString =   'Select '
                                + queryFields
                                + ' from Response__c where ('
                                + whereClause
                                + ') AND Collection_Instance__c = \''
                                + actSch.Collection_Instance__c
                                + '\' and RecordtypeId in '+responseRecordTypeIds;
				cntString = 'Select Count() from Response__c where (' 
                                + whereClause
                                + ') AND Collection_Instance__c = \''
                                + actSch.Collection_Instance__c
                                + '\' and RecordtypeId in '+responseRecordTypeIds;
            }
            //system.debug('queryString=='+queryString);
        } else {
            //Final query stirng to pass into Batch apex
            queryString =   'Select Id, Extension_Date__c '
                            + 'from Response__c where '
                            + 'Collection_Instance__c = \''
                            + actSch.Collection_Instance__c
                            + '\' and RecordtypeId in '+responseRecordTypeIds;
			cntString = 'Select Count() from Response__c where ' 
                            + 'Collection_Instance__c = \''
                            + actSch.Collection_Instance__c
                            + '\' and RecordtypeId in '+responseRecordTypeIds;
            actSch.Filter_Name__c = 'No Filter';
        }
        system.debug('queryString1=='+queryString);
        try{
            //Verifying the filter logic by executing the query
			//Also checking the count of the records to update estimated workitem count	
			System.debug('aaa=='+Limits.getQueryRows()+'=='+collectionIns);	
			if(collectionIns != null && collectionIns.RecordType.Name.equalsIgnoreCase('Census')){
				estimatedWorkItemsCount = 'N/A';
				return true;
			}else{
                
				 //steven zhu updated this logic to use the net_response_c field of collection instance rather than doing SOQL query again.
				if(collectionIns != null)
				{				
					if(String.isNotEmpty(String.valueOf(collectionIns.Net_Responses__c)) && collectionIns.Net_Responses__c > 0)
                    {
                        System.debug('estimatedWorkItemsCount=='+collectionIns.Net_Responses__c);
                        estimatedWorkItemsCount = String.valueOf(collectionIns.Net_Responses__c);
                        return true;
                    }
				}
				
				Integer count = Database.countQuery(cntString+' Limit '+(Limits.getLimitQueryRows()-1000));

				Integer queryCount = Limits.getQueryRows();
				
						
				if(count == Limits.getLimitQueryRows()-1000){
					estimatedWorkItemsCount = String.valueOf(count)+'+';
				} else {
					estimatedWorkItemsCount = String.valueOf(count);
				}
                System.debug('query Count=='+queryCount+' SOQL query APEX limit count=='+queryCount+ 'estimatedWorkItemsCount=='+estimatedWorkItemsCount);
			
	            return true;
			}
            
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please check your Filter Logic: '+e.getMessage()));
            return false;
        }
    }
    
    //Method to format the field, operator and value for the where clause based on the datatype
    private String formatFieldValueString(String filterOption, String filterOperator, String value){
		if(filterOperator.containsIgnoreCase('null')){
			return filterOption+' '+filterOperator; 
		}
        if(createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('String') ||
           createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Picklist') ||
           createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Lookup')){
               if(filterOperator == 'like'){
                   return filterOption+' '+filterOperator+' \'%'+value+'%\'';
               }else if(filterOperator == 'not like'){
                   return ' (NOT '+filterOption+' like \'%'+value+'%\')';
               } else if(filterOperator == 'starts'){
                   return filterOption+' '+' like \''+value+'%\'';
               } else {
                   return filterOption+' '+filterOperator+' \''+value+'\'';
               }
        } else if(createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Decimal') || 
                  createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Integer') ||
                  createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Boolean') ||
                  createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Date') ||
                  createWorkItemsMap.get(filterOption).Data_Type__c.containsIgnoreCase('Datetime')){
            return filterOption+' '+filterOperator+' '+value;
        }
        return null;
    }

	//Form filterCriteria for grouping filter
	private String formatGroupingFieldValueString(String filterOption, String filterOperator, String value){
		if(grp != null){
			System.debug('grp.get(filterOption)=='+grp.get(filterOption));
			String labelString = filterOption+' = \''+grp.get(filterOption)+'\'';
			String valueString = getFieldApiOfValue(filterOption)+' '+filterOperator+' \''+value+'\'';
			return '('+labelString+' AND '+valueString+')';
		}
		return null;
	}

	//Form filterCriteriaString for grouping filter
	private String formatGroupingFilterCriteriaString(String filterOption, String filterOperator, String value){
		if(grp != null){
			String labelString = filterOption+'~:~=~:~String~:~'+grp.get(filterOption);
			String valueString = getFieldApiOfValue(filterOption)+'~:~'+filterOperator+'~:~String~:~'+value;
			return labelString+' AND '+valueString;
		}
		return null;
	}

	//Form grouping value field api 
	private String getFieldApiOfValue(String filterOption){
		return filterOption.remove('_Label');
	}
    
	//to fetch predefined filters from Activity Schedule filter object
    public void predefinedFilterCriteria(){
        //system.debug('filterList=='+filterList+'=='+aSch.Collection_Instance__r.Collection__c);
        if(filterList.isEmpty()){
            if(actSch.Collection_Instance__c == NULL){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please provide Collection Instance'));
                return;
            }

            //Collection_Instance__c collectionIns = [Select Collection__c,Grouping__c from Collection_Instance__c where Id = :actSch.Collection_Instance__c];

			//Query all the predefined filters. Fetch only filters that match the grouping of the collection instance or grouping = null
            List<Activity_Schedule_Filter__c> asf = [Select    Id,Filter_Name__c,Filter_Logic__c,Filter_Criteria_String__c,Filter_Criteria__c,QueryString__c,Filter_Description__c
                                                    from      Activity_Schedule_Filter__c 
                                                    where     Collection__c = :collectionIns.Collection__c
													and		  (Grouping__c = null or Grouping__c = :collectionIns.Grouping__c)];
            
            filterList.add(new SelectOption('','--None--'));
            for(Activity_Schedule_Filter__c a: asf){
                if(a.Filter_Criteria__c != NULL){
                    filterList.add(new SelectOption(a.Id,a.Filter_Name__c));
                    filterMap.put(a.Id,a);
                }
            }
        }
    }
    
	//Filter types
    public void selectFilterType(){
        filterType = new List<SelectOption>();
        filterType.add(new SelectOption('No Filter','No Filter'));
        filterType.add(new SelectOption('Predefined Filter','Predefined Filter'));
        filterType.add(new SelectOption('Custom Filter','Custom Filter'));
    }
    
	//This method is called when Predefined filter is choosen and 'Copy to custom filter' button clicked from newActivitySchedule page
    public void showPredefinedFilter(){
        if(filterWrapperList.isEmpty() && preUsedFilter == NULL){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please select predefined filter'));
            return;
        }
        applyFilters = true;
        selectedFilter = 'Custom Filter';
        filterNameReadOnly = false;
        filterWrapperList.clear();
        fetchPredefinedFilter();
    }
    
	//to parse selected predefined filter
    private void fetchPredefinedFilter(){
        if(filterMap.containsKey(preUsedFilter)){
            actSch.Filter_Name__c = filterMap.get(preUsedFilter).Filter_Name__c;
            actSch.Filter_Description__c = filterMap.get(preUsedFilter).Filter_Description__c;
            formFilterWrapperFromString(filterMap.get(preUsedFilter).Filter_Criteria_String__c,filterMap.get(preUsedFilter).Filter_Logic__c);
        }
    }
    
	//Parse filter string
    private filterWrapper parseFilterWrapperString(String s, Integer seq){
        filterWrapper fw = new filterWrapper();
		List<SelectOption> fwOperators = new List<SelectOption>();
		fw.sequence = seq;
		fw.uniqueId = seq-1;
        fw.andOperator = 'AND';
        fw.operators = new List<SelectOption>();
        fw.operators.add(new SelectOption('','--None--'));
        fw.operators.add(new SelectOption('=','equals'));
        fw.operators.add(new SelectOption('!=','not equal to'));

		//Process grouping related filters in this loop
		//Grouping filter is identified by checking if it contains 'GR_'
		if(s.containsIgnoreCase('GR_')){
			//Groupings are generally captured as two condition statements
			//Eg:(GR_1_Label__c~:~=~:~String~:~TEST Group AND GR_1__c~:~=~:~String~:~testing)
			//To parse through this string we have to first break it on 'AND'
			List<String>grpFilter = s.split('AND');
			//The first condition i.e GR_1_Label__c~:~=~:~String~:~TEST Group
			//get the GR_1_Label__c
			fw.filterOption = grpFilter[0].split('~:~')[0];
			//Form the grouping value API using filterOption i.e. GV1__c
			String groupingValApi = 'GV'+fw.filterOption.split('_')[1]+'__c';
			//Get the value from the grouping record Eg:Hotel,Motel 
			String gropuingVal = (String)grp.get(groupingValApi);
			fw.dataType = 'String';
			//Get the grouping value 'testing' from the second part of the condition i.e GR_1__c~:~=~:~String~:~testing
			fw.value = grpFilter[1].split('~:~')[3];
			//Get the filterOperator '=' from the second part of the condition i.e GR_1__c~:~=~:~String~:~testing
			fw.filterOperator = grpFilter[1].split('~:~')[1];

			if(String.isNotBlank(gropuingVal)){
				fw.dataType = 'Picklist';
				//Form picklist values from grouping value Eg:Hotel,Motel
				fw.picklistOptions = fetchGroupingPicklistValues(gropuingVal);
			}
			//Get filter operators
		    fwOperators = assignFilterOperators(fw.dataType);
			if(fwOperators.size()>0){
				fw.operators.addAll(fwOperators);
			}
			return fw;
		}

		//Parse filters other than grouping
		//Eg:Collection_Instance__r.Delivery_Mode__c~:~=~:~Picklist~:~Post
        List<String> sg = s.split('~:~');
        //system.debug('sg==='+sg);
        fw.filterOption = sg[0];
        fw.filterOperator = sg[1];
        String dataType;
		//Get the datatype of the filterOption
        if(createWorkItemsMap.get(fw.filterOption).Data_Type__c.containsIgnoreCase('Decimal') || createWorkItemsMap.get(fw.filterOption).Data_Type__c.containsIgnoreCase('Integer')){
            dataType = createWorkItemsMap.get(fw.filterOption).Data_Type__c;
        }else{
            dataType = sg[2];
        }
        fw.dataType = sg[2];
        fw.value = sg[3];
        fw.ci = new Collection_Instance__c();
		if(fw.value=='null'){fw.value = null;}
        fwOperators = assignFilterOperators(dataType);
        if(fwOperators.size()>0){
            fw.operators.addAll(fwOperators);
        }
        if(fw.dataType == 'Lookup'){
            fw.lookupValue = fw.value;
            fw.operators.remove(2); //remove not equal to
        } else if(fw.dataType == 'Datetime' && fw.value != null){
            String dt = fw.value.replace('T',' ').replace('Z','');
            fw.ci.Planned_Close_Off__c = Datetime.valueOf(dt);
        } else if(fw.dataType == 'Date' && fw.value !=null){
	        fw.ci.Planned_Start_Date__c = Date.valueOf(fw.value);
        } else if(fw.dataType == 'Picklist'){
            String apiName;
            
            //Check if the API Name contains references to other object fields like Unit_of_Interest__r.Address_Type__c
            //Fetch only field API Name from the string
            //Assign to fOption directly if '.' is not found
            if(fw.filterOption.contains('.')){
                List<String> apiList = fw.filterOption.split('\\.');
                apiName = apiList[apiList.size()-1];
            } else {
                apiName = fw.filterOption;
            }
            //system.debug('fw.filterOption=='+fw.filterOption+'=='+createWorkItemsMap.get(fw.filterOption).Object__c);
            //Fetch the picklist values for the field based on the Object and API Name of the field
            fw.picklistOptions = ApexUtility.getPicklistValues(createWorkItemsMap.get(fw.filterOption).Object__c,apiName,true);
        }
        return fw;
    }
    
	//This method parse the complex filter criteria string to from the filter wrapper object
	//The stirng comprises of various filters seperated using '~@~'
	//Each filter contains information of filterAPI,filterOperator,dataType,filterValue
	//And they are seperated using '~:~'
	//Eg: Unit_of_Interest__r.LBU__c~:~=~:~Boolean~:~false~@~Unit_of_Interest__r.Mailable__c~:~=~:~Picklist~:~Yes
    private void formFilterWrapperFromString(String fString, String fLogic){
        //Seperating filters by spliting '~@~'
		List<String> fs = fString.split('~@~');
        if(fs.size()>1){
            filterLogic = fLogic;
            Set<String> orFlString = new Set<String>();
            String fl = fLogic;
            //system.debug('fl=='+fl);
			//Remove any ( ) from the filter logic. Eg the filter logic might look like (1 AND 2) OR (1 AND 3)
            if(fl.containsAny('()')){
                fl = fl.replace('(','');
                fl = fl.replace(')','');
            }
            //system.debug('fl1=='+fl);
			//If OR exists in the filter logic then applyfilterlogic
            if(fl.containsIgnoreCase('OR')){applyFilterLogic = true;}
            else {applyFilterLogic = false;}
			//Split the string on OR
            for(String st :fl.split('OR')){
                orFlString.add(st.trim());
            }
            system.debug('orFlString=='+orFlString);

            for(String o : orFlString){
                for(String st :o.split('AND')){
                    filterLogicSet.add(Integer.valueOf(st.trim()));
                }
            }
        }
        //system.debug('fs=='+fs);
        integer i =1;
		//Loop through all the filters
        for(String s: fs){
            if(s!=null && s!='null' && s!=''){
                //system.debug('s==='+s);
				//Parse through filters to form filterWrapper object and add to list
                filterWrapperList.add(parseFilterWrapperString(s,i));
                i++;
            }
        }
        filterWrapperList[filterWrapperList.size()-1].andOperator = null;
    }
    
	//This method works based on the filteroption selected
	//Custom Filter - provides option to add new filters using filters picklist
	//Predefined Filter - These are saved filters on Activity Schedule fiter object, The user can select the relevant filter instead of creating a new one
	//No Filter - This is used to create work items for all the Responses of the collection instance
    public void activateFilters(){
        if(selectedFilter == 'Custom Filter'){
            resetVariables();
            if(action == NULL){
                actSch.Filter_Name__c = NULL;
                actSch.Filter_Description__c = NULL;
            }
            applyFilters = true;
            filterNameReadOnly = false;
            addFilter();
        } else if(selectedFilter == 'Predefined Filter'){
            resetVariables();
            actSch.Filter_Name__c = null;
            actSch.Filter_Description__c = null;
            predefinedFilterCriteria();
            applyFilters = true;   
        } else if(selectedFilter == 'No Filter'){
            resetVariables();
            actSch.Filter_Name__c = null;
            actSch.Filter_Description__c = null;
            applyFilters = false;
        } 
    }
    
    private void resetVariables(){
        preUsedFilter = null;
        filterWrapperList = new List<filterWrapper>();
        filterLogic = null;
    }
    
	//This method is called on newActivityScheduleFilter page to save pre-defined filters
    public PageReference saveFilter(){
        if(String.isBlank(actSchFilter.Filter_Name__c) || String.isBlank(actSchFilter.Filter_Description__c) || actSchFilter.Collection__c == NULL){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Required fields are missing'));
            return null;
        }
        if(!validateFilterScreen() || !validateFilterLogic()){
            return null;
        }
        actSchFilter.Filter_Criteria__c = filterCriteria;
        actSchFilter.Filter_Criteria_String__c = filterCriteriaString;
        actSchFilter.Filter_Logic__c = filterLogic;
        upsert actSchFilter;
        if(action == 'edit'){ return new PageReference('/'+actSchFilter.Collection__c);}
        return new PageReference('/'+actSchFilter.Id);
    }
    
	//This method is called when Activity Schedule filter is edited
	//This fetches the filter criteria string from the record and parse it to display the filters
    public void editFilter(){
        filterWrapperList.clear();
        actSchFilter = [Select Id,Collection__c,Filter_Name__c,Grouping__c,Filter_Criteria_String__c,Filter_Description__c,Filter_Criteria__c,Filter_Logic__c from Activity_Schedule_Filter__c where id = :editRecordId];
        //Method to form the filter wrapper
		formFilterWrapperFromString(actSchFilter.Filter_Criteria_String__c,actSchFilter.Filter_Logic__c);
    }

	public void estimateWorkItems(){
		if(!validateFilterScreen() || !validateFilterLogic()){return;}
	}
    
    //Wrapper for Filter Screen
    public class filterWrapper{
        public String filterOption{get;set;}
        public String filterOperator{get;set;}
        public List<SelectOption> operators{get;set;}
        public String value{get;set;}
        public String lookupValue{get;set;}
        public Collection_Instance__c ci{get;set;}
        public Date dateValue{get;set;}
        public Datetime datetimeValue{get;set;}
        public String dataType{get;set;}
        public list<SelectOption> picklistOptions{get;set;}
        public Integer uniqueId{get;set;}
        public String andOperator{get;set;}
        public Integer sequence{get;set;}
    }
}