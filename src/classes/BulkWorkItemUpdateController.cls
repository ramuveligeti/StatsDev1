/** Controller for BulkWorkItemUpdate.page
 *
 *  This comes from story ECP-1494.  Original idea is to allow more dynamic nature to support bulkd update of work-items
 *  this is last minute phase-1, and Eric is taking the easy approach
 *  Remark: Steven Zhu 20161010: update SOQL query select field list bug ECP-3678 realted to ECP-3339 story
			Steven Zhu 20161104  ECP3747, handling multi-select none option selected null error bug
 */
public with sharing class BulkWorkItemUpdateController {
/* could have done a generic solution, however, running out of time, will reconsider this in phase-2
    private static Map<String,String> filters=new Map<String,String>{
        'Work Item Type'=>'work_item_type__c',
        'Status'=>'status__c',
        'Wave'=>'response__r.wave__c',
        'Key'=>'response__r.key__c'
    };
*/

    public Collection_Instance__c record{get;private set;}
    public SelectOption[]schedules{get;private set;}
    public SelectOption[]outcomes{get;private set;}
	public SelectOption[]instrumentCodes{get;private Set;}
	public SelectOption[]waveOptions{get;private Set;}
	public SelectOption[]opfOptions{get;private Set;}
	public SelectOption[]opoOptions{get;private Set;}
	public SelectOption[]dmOptions{get;private Set;}
	public SelectOption[]wisOptions{get;private Set;}
	public SelectOption[]witOptions{get;private Set;}

	
    public boolean isCensus{get;private set;}
    // cannot use owner fields, as it becomes complusory input
    public String inputUser{get;set;}
    public String inputQueue{get;set;}
    public String inputStatus{get;set;}
    // have to use input for checkboxes
    public String filterFU{get;set;}
    public String filterLBU{get;set;}
    public String filterKey{get;set;}
	public List<String> filterAS{get;set;}
    public List<String> filterDM{get;set;}
    public List<String> filterWIT{get;set;}
	public List<String> filterWIS{get;set;}
    public List<String> filterIC{get;set;}
    public String filterWave{get;set;}
	public String filterOpf{get;set;}
    public String filterOpo{get;set;}
	public String filterES{get;set;}

    public SelectOption[]activeUsers{get;private set;}
    public SelectOption[]activeQueues{get;private set;}
    public SelectOption[]yesno{get;private set;}
    public Id batchId{get;private set;}
    public boolean batched{get;private set;}
    private Integer priorityFactor{get;set;}
    public String priorityFactorInput{get;set;}
	private boolean priorityOverride{get;private set;}
	public String inputPriorityOverride{get;set;}
	private Datetime inputCallBackTime{get;set;}
    

    // taking easy approach here
    // fields that we can use for bulk update
    //  - Activity_Schedule
    //  - work-item-type
    //  - work-item-status
    //  - wave
    //  - key
    // census specific
    //  - work-load

    // fields that can be updated
    //  - status
    //  - ownerid
    //  - outcome
    public Work_Item__c dummyFilter{get;private set;}
    public Response__c dummyRFilter{get;private set;}

    public List<GroupingWrap> groupingWraps{get; private set;}
    public Response__c dummyResponse_StartDate{get; set;} //only used as date placeholder and to have datepicker input field
    public Response__c dummyResponse_EndDate{get; set;} //only used as date placeholder and to have datepicker input field
	public Work_Item__c dummyWI_StartDate {get;set;}
	public Work_Item__c dummyWI_EndDate {get;set;}
	public Work_Item__c dummyWI_InputCallBackTime {get;set;}
    
    
    public BulkWorkItemUpdateController(ApexPages.StandardController std){
        String x=ApexPages.currentPage().getParameters().get('isCensus');
        x=(x==null)?'':x.trim();
        isCensus=Boolean.valueOf(x);
        record=(Collection_Instance__c)std.getRecord(); 
        // init values for input
        dummyFilter=new Work_Item__c();
        dummyRFilter=new Response__c();

        schedules=newPickList();
		instrumentCodes = newPickList();
		waveOptions = newPickList();
		dmOptions = newPickList();
		wisOptions = newPickList();
		witOptions = newPickList();

        if(record.id!=null){
            for(Activity_Schedule__c sch: [select Name,Delivery_Mode__c,Status__c,Work_Item_Type__c,
                (select filter_Criteria__c from Activity_Schedule_Filters__r)
                from Activity_Schedule__c where Collection_Instance__c=:record.id]){
                schedules.add(new SelectOption(sch.id, sch.Name + ' - ' + sch.Work_Item_Type__c + ' - ' + sch.Delivery_Mode__c + ' - ' + sch.status__c));
            }

			for (AggregateResult ar: [select Wave__c wave from Response__c  where Collection_Instance__c=:record.id and Wave__c <> '' group by Wave__c ]){
				String NameString = (String)ar.get('wave');
				waveOptions.add(new SelectOption(NameString, NameString));
			}

			Set<String> instrumentCodesList = New Set<String>();
			for (Response__c res: [select Instrument_Name__c from Response__c where Collection_Instance__c=:record.id and Instrument_Name__c <> '']){
				
				if(!instrumentCodesList.contains(res.Instrument_Name__c))
					instrumentCodesList.add(res.Instrument_Name__c);	
			}
			For(String s :instrumentCodesList)
			{
				instrumentCodes.add(new SelectOption(s, s));
			}
        }
		

        outcomes=newPickList(new String[]{'Pending','In Progress','Closed'});
        yesno=newPicklist(new String[]{'Yes','No'});
		opfOptions=newPicklist(new String[]{' > 1'});

		dmOptions = PrepareSelectOptions(Work_Item__c.Delivery_Mode__c.getDescribe());
		wisOptions = PrepareSelectOptions(Work_Item__c.Status__c.getDescribe());
		witOptions = PrepareSelectOptions(Work_Item__c.Work_Item_Type__c.getDescribe());

        activeQueues=newPickList();
        activeUsers=newPickList();
        for(Group q: [Select DeveloperName from Group where Type = 'Queue' order by DeveloperName]){
            activeQueues.add(new SelectOption(q.id,q.DeveloperName));
        }    
        for(User u: [Select Name from User where isActive =:true order by Name]){
            activeUsers.add(new SelectOption(u.id,u.Name));
        }
        batched=false;
        
        dummyResponse_StartDate = new Response__c();
        dummyResponse_EndDate = new Response__c();
		dummyWI_StartDate = new Work_Item__c();
		dummyWI_EndDate = new Work_Item__c();
		dummyWI_InputCallBackTime = new Work_Item__c();

        //Determine all available grouping field labels and values
        //Collection_Instance__c ci = [select Grouping__c from Collection_Instance__c where Id=:record.Id];
        groupingWraps = new List<GroupingWrap>();
        if(String.isNotBlank(record.Grouping__c)){
            Grouping__c grouping = [select 
                    GR_1_Label__c, GV1__c,
                    GR_2_Label__c, GV2__c,
                    GR_3_Label__c, GV3__c,
                    GR_4_Label__c, GV4__c,
                    GR_5_Label__c, GV5__c,
                    GR_6_Label__c, GV6__c,
                    GR_7_Label__c, GV7__c,
                    GR_8_Label__c, GV8__c,
                    GR_9_Label__c, GV9__c,
                    GR_10_Label__c, GV10__c
                from Grouping__c where Id=:record.Grouping__c
            ];
            for(Integer i=1; i<11; i++){
                String label = (String)grouping.get('GR_'+i+'_Label__c');
                String value = (String)grouping.get('GV'+i+'__c');
                String fieldName = 'GR_'+i+'__c';
                if(String.isNotBlank(label) && String.isNotBlank(value)){
                    groupingWraps.add(new GroupingWrap(fieldName, label, value));
                }
            }
        }
    }

    public PageReference save(){
        if(!String.isBlank(inputUser)&&!String.isBlank(inputQueue)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can only choose a user or a queue, not both'));
            return null;
        }
        String soql='select id, status__c, ownerId, Response__c, call_back_time__c from Work_Item__c WHERE response__r.Collection_Instance__c = \''+ record.id + '\' ';
        // go through first filter object, work-item
        String[]whereClauses=new String[]{};

        String[]apis=new String[]{'workload__c','OwnerId'};
        for(String f:apis){
            String x = genWhereClause('',f,dummyFilter.get(f));
            if(x!=null){whereClauses.add(x);}
        }
		if(filterDM!=null && filterDM.size()>0){whereClauses.add(genWhereClause('','Delivery_Mode__c',filterDM));}
		if(filterWIT!=null && filterWIT.size()>0){whereClauses.add(genWhereClause('','work_item_type__c',filterWIT));}
		if(filterWIS!=null && filterWIS.size()>0){whereClauses.add(genWhereClause('','status__c',filterWIS));}
		if(filterAS!=null && filterAS.size()>0){whereClauses.add(genWhereClause('','activity_schedule__c',filterAS));}
		if(filterIC!=null && filterIC.size()>0){whereClauses.add(genWhereClause('','Instrument_Code__c',filterIC));}

		

        apis=new String[]{'response_summary_status__c','status__c','Collection_Mode__c'};
        for(String f:apis){
            String x = genWhereClause('Response__r.',f,dummyRFilter.get(f));
            if(x!=null){whereClauses.add(x);}
        }

		if(!String.isBlank(filterWave)){whereClauses.add(genWhereClause('Response__r.','Wave__c',filterWave));}
        // cannot use the boolean value to determine the soql, need to support n/a
        // so, explicitly set
        if(!String.isBlank(filterFU)){whereClauses.add(genWhereClause('','follow_up__c',filterFU=='Yes'));}
		if(!String.isBlank(filterES)){whereClauses.add(genWhereClause('','Escalated__c',filterES=='Yes'));}
		if(!String.isBlank(filterOpo)){whereClauses.add(genWhereClause('Response__r.','Overall_Priority_Override__c',filterOpo=='Yes'));}
        if(!String.isBlank(filterKey)){whereClauses.add(genWhereClause('Response__r.','Key__c',filterKey=='Yes'));}
        if(!String.isBlank(filterLBU)){whereClauses.add(genWhereClause('Response__r.Unit_Of_Interest__r.','LBU__c',filterLBU=='Yes'));}

		//for filter overall priority factor, because filter value '> 1' using genWhereClauseValue
		if(!String.isBlank(filterOpf)){
			whereClauses.add(genWhereClauseValue('Response__r.','Overall_Priority_Factor__c',filterOpf));
		}
        
        if(dummyResponse_StartDate.Extension_Date__c!=null){
            whereClauses.add('Response__r.Extension_Date__c >= '+format(dummyResponse_StartDate.Extension_Date__c));
        }    
        if(dummyResponse_EndDate.Extension_Date__c!=null){
            whereClauses.add('Response__r.Extension_Date__c <= '+format(dummyResponse_EndDate.Extension_Date__c));
        }
		 if(dummyWI_StartDate.Call_Back_Time__c!=null){
            whereClauses.add('Call_Back_Time__c >= '+format(dummyWI_StartDate.Call_Back_Time__c));
        }    
        if(dummyWI_EndDate.Call_Back_Time__c!=null){
            whereClauses.add('Call_Back_Time__c <= '+format(dummyWI_EndDate.Call_Back_Time__c));
        }

        for(GroupingWrap grw:groupingWraps){
            if(grw.selectedOption!=null && grw.selectedOption.size() > 0){
                whereClauses.add(genWhereClause('Response__r.',grw.grFieldName,grw.selectedOption));
            }
        }
        
        system.debug('whereClauses1: ' + whereClauses);

        if(whereClauses.size()<2){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must provide at least 2 filters'));
            return null;
        }

system.debug('whereClauses2: ' + whereClauses);

        // taking shortcut, only do 'AND' condition
        for(integer i=0;i<whereClauses.size();i++){
			String value = whereClauses.get(i);
			if(value != null)
			{
				soql+=' AND ';
				soql+=whereClauses.get(i);
			}
        }
        
        system.debug('soql = '+soql);
        
        // now work on the new values
        Id ownerId=null;
        if(!String.isBlank(inputUser)){ownerId=inputUser;}
        if(!String.isBlank(inputQueue)){ownerId=inputQueue;}
		if(dummyWI_InputCallBackTime.Call_Back_Time__c != null)
		{
			inputCallBackTime = dummyWI_InputCallBackTime.Call_Back_Time__c;
		}
		if(!String.isBlank(inputPriorityOverride)){priorityOverride=(boolean)(inputPriorityOverride=='Yes');}
        if(String.isBlank(inputStatus)&&String.isBlank(ownerId) && priorityFactorInput==null && inputCallBackTime ==null && String.isBlank(inputPriorityOverride)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must update something'));
            return null;
        }

        BulkWorkItemUpdateBatch batch = null;

		if(String.isNotBlank(inputPriorityOverride) && String.isBlank(priorityFactorInput)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must set Overall Priority Factor if set Overall Priority Override'));
            return null;
        }

		if(String.isNotBlank(inputPriorityOverride) && String.isNotBlank(priorityFactorInput) && !priorityOverride && priorityFactorInput != '1' )
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must set Overall Priority Factor to 1 if set Overall Priority Override to No'));
            return null;
		}

		try
		{
			System.debug('priorityFactorInput='+priorityFactorInput);
			System.debug('priorityOverride='+inputPriorityOverride);
			if(String.isNotBlank(priorityFactorInput))
			{
				priorityFactor = Integer.valueOf(priorityFactorInput);
				if(priorityFactor<1 || priorityFactor>99999){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Priority Factor should be between 1 and 99999'));
						return null;
				}
			}
               
        } catch (System.TypeException ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Priority Factor must be a number between 1 and 99999'));
                return null;
        }

        if(String.isNotBlank(inputPriorityOverride))
		{
			batch = new BulkWorkItemUpdateBatch(soql, inputStatus, ownerId, priorityFactor, priorityOverride, inputCallBackTime);
		}else if(String.isNotBlank(priorityFactorInput)){

            batch = new BulkWorkItemUpdateBatch(soql, inputStatus, ownerId, priorityFactor, inputCallBackTime);
            
        }else{
            batch = new BulkWorkItemUpdateBatch(soql,inputStatus,ownerId,inputCallBackTime);
        }
        
        // trigger the batch process using the soql, and the two update can go into the contructor
        
        batchId = Database.executeBatch(batch,2000);
        batched=true;
        return null;
    }

    public PageReference cancel(){
        return new PageReference('/'+record.id);
    }
    
    private SelectOption[] newPickList(){
        return new SelectOption[]{new SelectOption('','--None--')};
    }
    private SelectOption[] newPickList(String[] v){
        SelectOption[]x=newPickList();
        for(String o:v){x.add(new SelectOption(o,o));}
        return x;
    }

	//create list of selectoptions from a picklist field
	public List<SelectOption> PrepareSelectOptions(Schema.DescribeFieldResult F)
	{       
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','--None--'));
		List<Schema.PicklistEntry> Ple = F.getPicklistValues();
		for(Schema.PicklistEntry p : ple)
		{               
			options.add(new SelectOption(p.getValue(),p.getlabel()));
		}
		return options; 
	}
    
    private String genWhereClause(String prefix, String field, Object value){
        if(value == null) {
            return null;
        }

        if(value instanceof String) {
            return prefix + field + ' = \'' + value + '\' ';
        }

        if( value instanceof Boolean ){
            // don't care if it's false, exclude from filter
            return prefix + field + ' = ' + (Boolean)value;
        }
        
        return null;
    }

	//Added this for producing criteria with in () when selected multiple options
	private String genWhereClause(String prefix, String field, List<String> values){
        if(values == null) {
            return null;
        }
		
		string valueString = '';
		for(String s :values)
		{
			
			//if values contains empty string meaning none option selected, dont do anything in this case to avoid soql errors
			if(String.isBlank(s)){return null;}
		    if(valueString.length() > 0) valueString += ',';
			valueString +=  '\'' + s + '\'';
		}

        if(String.isBlank(valueString)){return null;}
        return prefix + field + ' in (' + valueString + ') ';
        
    }

	//added this for producing criteria with value contains operator already-works with integer override priority factor
	private String genWhereClauseValue(String prefix, String field, String valueWithOperator)
	{
		if(valueWithOperator == null) {
            return null;
        }
		return prefix + field + valueWithOperator;
	}
    
    private String format(Date dte){
        if(dte!=null){
            Datetime dt = datetime.newInstance(dte.year(), dte.month(),dte.day());
            return dt.format('yyyy-MM-dd');
        }
        return null;
    }
	 private String format(Datetime dt){
        if(dt!=null){
            return dt.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
        return null;
    }


    public class GroupingWrap{
        public List<SelectOption> options{get; set;}
        public List<String> selectedOption{get; set;}
        public String label {get; set;}
        public String grFieldName;
        
        public GroupingWrap(String grFieldName, String label, String valuesStr){
            this.label = label;
            this.grFieldName = grFieldName;
            this.options = convert(valuesStr);
            this.selectedOption = null;
        }

        private List<SelectOption> convert(String str){
            List<SelectOption> ops = new List<SelectOption>();
            
            if(String.isNotBlank(str)){
                SelectOption none = new SelectOption('', '--None--');
                ops.add(none);

                List<String> values = str.split(',');
                for(String val:values){
                    SelectOption op = new SelectOption(val.trim(), val.trim());
                    ops.add(op);
                }
            }
            return ops;
        }
    }
}