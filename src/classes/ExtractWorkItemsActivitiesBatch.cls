/**
* @description   Batch Apex to extract all the work items for a specific outbound event and Save as a CSV file under documents
* @author		Joseph Newby
* @date		  10.Sep.2015
* Remark		 Steven Zhu 20160908 ECP 3323 post out file name format change
				 Steven Zhu 20160915 ECP 3323 file name datetime string format change added _ between date and time
				 Steven Zhu	20161103 ECP 3720 fixing issue related to grouping/contexual field extract in file format
				 Steven Zhu 20161111 ECP 3762 bug related to duplicate fields (CO, GR) in SOQL query
*Amendment       Caterina Cuccurullo 27-04-2017  & 04-05-2017 ECP-3839
                 changed CreateDocumentName so that document name now shows Scheduled Run Datetime not System.Now which
                 is the datetime it was scheduled. Removed**>Assigned the Author of the Document to the Extract Schedule Author**


*/
global class ExtractWorkItemsActivitiesBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
   	global final String query;
	global final Id collectionInstanceId,csvFormatId;
	global final String workItemType,deliveryMode;
    global final datetime scheduleDate;
    global final String DocumentAuthorID;
	global Collection_Instance__c collectionInstance;
	global String csvDocumentName;
	global Folder csvFolder;
	global Map<String, String> columnMetadata;
	global List<String> rows;
	global List<String> fieldMapping;
	global Integer documentsCreated;
	global List<String> documentLinks;
	global List<Id> documentIds;
	global Activity_Schedule__c activitySchedule;
	global boolean invokeFileMerge;

	@TestVisible private Map<String, String> groupingLabels;
	@TestVisible private Map<String, String> contextualMappingLabels;
	@TestVisible private static Map<String, SystemSettings__c> systemSettings = SystemSettings__c.getall();

	// 4.9 MB limit, 100 kb padding to prevent over flow of 5MB.
	global Integer csvMemorySizeLimit = Integer.valueOf(systemSettings.get('extract.filesize').Value__c);
	global Integer csvCurrentSizeInMemory = 0;

	global ExtractWorkItemsActivitiesBatch(Activity_Schedule__c actSch, Boolean createExtracts) {
		documentIds = new List<Id>();
		activitySchedule = actSch;
		// This number is appended to the end of the document name.
		documentsCreated = 1;
		documentLinks = new List<String>();
		this.collectionInstanceId = actSch.Collection_Instance__c;
		this.workItemType = actSch.Work_Item_Type__c;
		this.deliveryMode = actSch.Delivery_Mode__c;
		this.csvFormatId = actSch.Output_CSV_Format__c;
        this.scheduleDate = actSch.Scheduled_Date_time__c;
      //  this.DocumentAuthorID = actSch.CreatedByID;

		// These are the fields like Column_Header_1 that hold the names of custom settings that hold the path
		// to work item fields like Response__r.Contact__r.FirstName.
		List<Schema.sObjectField> workItemCSVFormatFields = Schema.getGlobalDescribe().get('Work_Item_CSV_Format__c').getDescribe().fields.getMap().values();

		// Create the query that will get all the Column Header values from the CSV Format a user wants to use.
		String workItemCSVFormatQuery = createWorkItemCSVFormatQuery(csvFormatId, workItemCSVFormatFields);

		sObject workItemCSVFormat = Database.query(workItemCSVFormatQuery);

		// Groupings and Contextual Mappings are linked to a collection.
		// The groupings or contextual mappings in the CSV Format might come from a collection that doesn't
		// match the collection instance we are processsing, in which case we will leave the columns blank in the resulting CSV.

		// This CSV Format was set up with groupings fields we store the grouping for extraction in extraction.
		List<String> fieldsToSelect = new List<String>{'_label__c'};

		groupingLabels = new Map<String, String>();
		contextualMappingLabels = new Map<String, String>();

		if (workItemCSVFormat.get('Grouping__c') != null) {
			Id groupingId = (Id) workItemCSVFormat.get('Grouping__c');
			groupingLabels = createLabelMap(groupingId, 'Grouping__c', fieldsToSelect);
		}

		// This CSV Format was set up with contextual mapping fields we store the contextual mappings for extraction in extraction.
		if (workItemCSVFormat.get('Contextual_Mappings__c') != null) {
			Id contextualMappingId = (Id) workItemCSVFormat.get('Contextual_Mappings__c');
			contextualMappingLabels = createLabelMap(contextualMappingId, 'Contextual_Mappings__c', fieldsToSelect);
		}

		// Get all values out of a formats column header fields and add them to simple object for column name and the value
		// value in this case is the path to a field on the work item we talked about above e.g. Response__r.Contact__r.FirstName.
		List<WorkItemCSVColumn> workItemCSVColumns = createWorkItemCSVColumnsList((Work_Item_CSV_Format__c) workItemCSVFormat, workItemCSVFormatFields);

		// Convert the WorkItemCSVColumn objects into a key value pair for we can loop over it later.
		// Column Label => Path to field on work item.
		columnMetadata = createColumnMetadata(workItemCSVColumns);

		// Concatinate a string of all values in the column metadata map.
		// Returns string like => ', Response__r.Contact__r.FirstName, Response__r.Contact__r.LastName'
		String fieldsQueryString = createWorkItemFieldsSelectQuery(columnMetadata);
		String groupingQuery = getGroupSelectQueryFromWorkItemResponse(columnMetadata);
		String contextualMappingsQuery = getContextualMappingsSelectQueryFromWorkItemResponse(columnMetadata);

		String whereClause;
		if(activitySchedule.Id != NULL) {
			whereClause = 'AND Activity_Schedule__c = \'' + activitySchedule.Id + '\'';
		}
		else{
			whereClause = 'AND Work_Item_Type__c = \'' + workItemType + '\' AND Delivery_mode__c = \'' + deliveryMode + '\'';
		}

		/*String queryString =
		'SELECT Id, Status__c' + fieldsQueryString + ', ' + groupingQuery + ', ' + contextualMappingsQuery
		+ ' FROM Work_Item__c'
		+ ' WHERE Status__c = \'New\''
		+ ' AND Collection_Instance__c = \'' + collectionInstanceId + '\''
		+ whereClause;*/
         String queryString =
            'SELECT Id, Status__c' + fieldsQueryString;
         
		if(String.isNotBlank(groupingQuery)){
             queryString +=  ', ' + groupingQuery; 
        }

        if(String.isNotBlank(contextualMappingsQuery)){
             queryString +=  ', ' + contextualMappingsQuery;
        }

        if(String.isNotBlank(collectionInstanceId)){
            queryString +=
           	' FROM Work_Item__c'
            + ' WHERE Status__c = \'New\''
            + ' AND Collection_Instance__c = \'' + collectionInstanceId + '\' '
            + whereClause;
        }else {
            queryString +=
             ' FROM Work_Item__c'
            + ' WHERE Status__c = \'New\''
            + ' AND Response_Record_Type__c = \'Business Response\' '
            + whereClause;
        }

		String orderByClause = OrderByString(queryString, (Work_Item_CSV_Format__c) workItemCSVFormat, columnMetadata);

		if (String.isNotBlank(orderByClause)) {
			queryString += ' Order by ' + orderByClause;
		}

		query = queryString;

		// Creates an empty list of strings to assign to rows.
		// It also adds the column names as the first string in the list.
		// Rows become the string body of the csv when it is saved in execute or finish.
		rows = createCSVRowsWithColumnHeaders(columnMetadata.keySet());
		fieldMapping = columnMetadata.values();
		csvCurrentSizeInMemory = rows[0].length();

		// This is a hack to mack sure when we loop over the columnMetadata values
		// later grouping and contextual columns have a value.
		// If we do this earlier then we run the risk of screwing up the query logic.
		// There is probably a better way to do this but I'm tired and can't see one.
		for (String key : columnMetadata.keySet()) {
			String value = columnMetadata.get(key);

			if (String.isBlank(value)) {
				columnMetadata.put(key, key);
			}
		}

		/*/get Activty schedule name
		Activity_Schedule__c a = [
			SELECT Name
			FROM Activity_Schedule__c
			WHERE Id = :activitySchedule.Id
		];*/
		//szhu moving this initialisation of invokeFileMerge flag here not in conditional block
		//because for cross collection extract, if this is not initialised attemp to de-reference a null object error in finish method occurs
		invokeFileMerge = false;

		if(String.isNotBlank(collectionInstanceId)){
			collectionInstance = [
			SELECT Name,
				Collection_Instance_Code__c,
				Collection__r.Autosend_to_Mailhouse__c, 
				Collection__r.Sensitive_Data_Merge__c,
				RecordType.Name 
			FROM Collection_Instance__c
			WHERE Id = :collectionInstanceId
			];

			// check for the file-merge criterias
			// we have to restricted sensitive file-merge to specific work-item-type
			
			if(collectionInstance.Collection__r.Sensitive_Data_Merge__c){
				// this is for sensitive data merge, assumption is that only a few workitem types are reuqired
				invokeFileMerge = 'Questionnaire'.equalsIgnoreCase(workItemType)
					|| 'Replacement questionnaire'.equalsIgnoreCase(workItemType)
					|| 'Access code'.equalsIgnoreCase(workItemType);
			}

			// This should output something similar to Collection_Name_Work_Item_Type_Delivery_Mode_14/03/2015_
			// TODO add in activity schedule name
			csvDocumentName = CreateDocumentName(collectionInstance.Collection_Instance_Code__c, workItemType, deliveryMode, scheduleDate,(activitySchedule.Name!=NULL?activitySchedule.Name:Null),(activitySchedule.Filter_Name__c!=NULL?activitySchedule.Filter_Name__c:Null));
		}else{
			// This should output something similar to Collection_Name_Work_Item_Type_Delivery_Mode_14/03/2015_
			// TODO add in activity schedule name
			csvDocumentName = CreateDocumentName('AllCollectionInstances', workItemType, deliveryMode, scheduleDate,(activitySchedule.Name!=NULL?activitySchedule.Name:Null),(activitySchedule.Filter_Name__c!=NULL?activitySchedule.Filter_Name__c:Null));
		}

		// This gets executed only when creating extracts using ExtractWorkItemsActivities or ExtractScheduler pages
		// We avoid this when the request is coming from ExtractScheduler class and CreateWorkItemsBatch
		// This code create Extract Schedule records, if the extract is a recurring extract
		if(createExtracts){
			List<Extract_Schedule__c> esList = new List<Extract_Schedule__c>();
			for(integer i=1;i<=activitySchedule.Occurrence__c;i++){
				if(activitySchedule.Scheduled_Date_time__c != null && activitySchedule.Scheduled_Date_time__c.date() >= System.today().addDays(1)){
					Extract_Schedule__c es = createNewExtractSchedule(activitySchedule);
					esList.add(es);                 
				}

				if(activitySchedule.Frequency__c.equalsIgnoreCase('Daily')){
					activitySchedule.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c.addDays(1);
				}
				if(activitySchedule.Frequency__c.equalsIgnoreCase('Weekly')){
					activitySchedule.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c.addDays(7);
				}
				if(activitySchedule.Frequency__c.equalsIgnoreCase('Fortnightly')){
					activitySchedule.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c.addDays(14);
				}
				if(activitySchedule.Frequency__c.equalsIgnoreCase('Monthly')){
					activitySchedule.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c.addMonths(1);
				}
                //Added document name creation in here so that multipule schedules show the actual scheduled date as part of the file name - Caterina C 1 May 2017
                 if(activitySchedule.Frequency__c.containsNone('Once')){
                    if(String.isNotBlank(collectionInstanceId)){
                       csvDocumentName = CreateDocumentName(collectionInstance.Collection_Instance_Code__c, workItemType, deliveryMode, activitySchedule.Scheduled_Date_time__c,(activitySchedule.Name!=NULL?activitySchedule.Name:Null),(activitySchedule.Filter_Name__c!=NULL?activitySchedule.Filter_Name__c:Null));
                    }else{
			// This should output something similar to AllCollectionInstances_Work_Item_Type_Delivery_Mode_27/04/2017_
			           csvDocumentName = CreateDocumentName('AllCollectionInstances', workItemType, deliveryMode, activitySchedule.Scheduled_Date_time__c,(activitySchedule.Name!=NULL?activitySchedule.Name:Null),(activitySchedule.Filter_Name__c!=NULL?activitySchedule.Filter_Name__c:Null));
                         }
                 }
                }
        
			insert esList;
		}
		// The place the CSV Documents will be saved to.
		csvFolder = [
		SELECT Id
		FROM Folder
		WHERE Name = 'ECP Extracts'
		LIMIT 1
		];
	}

	public Extract_Schedule__c createNewExtractSchedule(Activity_Schedule__c activitySchedule){
		Extract_Schedule__c es = new Extract_Schedule__c();
		es.Activity_Schedule_Id__c = activitySchedule.Id;
		es.Scheduled_Date_time__c = activitySchedule.Scheduled_Date_time__c;
		es.Frequency__c = activitySchedule.Frequency__c;
		es.CSV_Header__c = String.join(rows, ', ').removeEnd(', ');
		es.Field_Mapping__c = String.join(fieldMapping, ', ').removeEnd(', ');
		es.File_Name__c = csvDocumentName;
		es.SOQL_String__c = query;
		es.Work_Item_Type__c = workItemType;
		es.Delivery_Mode__c = deliveryMode;
		es.Collection_Instance_Id__c = collectionInstanceId;
		es.Output_CSV_Format__c = csvFormatId;
		es.Collection_Type__c = ((String.isBlank(collectionInstanceId) || collectionInstance.RecordType.Name=='Collections')?'Business':collectionInstance.RecordType.Name);
		return es;
	}

	@TestVisible
	static String OrderByString(String soqlQuery, Work_Item_CSV_Format__c workItemCSVFormat, Map<String, String> metadata) {
		Set<String> clauses = new Set<String>();
		clauses.add(formatOrderByString(soqlQuery, metadata.get(workItemCSVFormat.Order_By_1__c), workItemCSVFormat.Order_By_1_Sort__c));
		clauses.add(formatOrderByString(soqlQuery, metadata.get(workItemCSVFormat.Order_By_2__c), workItemCSVFormat.Order_By_2_Sort__c));
		clauses.add(formatOrderByString(soqlQuery, metadata.get(workItemCSVFormat.Order_By_3__c), workItemCSVFormat.Order_By_3_Sort__c));
		clauses.add(formatOrderByString(soqlQuery, metadata.get(workItemCSVFormat.Order_By_4__c), workItemCSVFormat.Order_By_4_Sort__c));
		clauses.add(formatOrderByString(soqlQuery, metadata.get(workItemCSVFormat.Order_By_5__c), workItemCSVFormat.Order_By_5_Sort__c));
		// check for case first asc and first desc being in the set.
		clauses.remove('');
		return String.join(new List<String> (clauses), ',');
	}

	static String formatOrderByString(String soqlQuery, String field, String sortDirection) {
		if (String.isBlank(field)) {
			return '';
		}

		if (!soqlQuery.containsIgnoreCase(field)) {
			return '';
		}

		if ('DESC'.equalsIgnoreCase(sortDirection)) {
			return field + ' DESC';
		}

		return field + ' ASC';
	}

	// Batch implementation methods.

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Work_Item__c> workItems) {
		try {
			for (Work_Item__c workItem : workItems) {
				String row = getRowData(workItem, columnMetadata);

				rows.add(row);
				csvCurrentSizeInMemory += (row.length() + 1); // added '\n' in the size

				if (csvCurrentSizeInMemory >= csvMemorySizeLimit) {
					SaveCSVDocument();
					rows.clear();
					csvCurrentSizeInMemory = 0;
					// added special handling logic for mulesoft
					if(invokeFileMerge){
						// this will create a new "rows" object, with the header
						rows = createCSVRowsWithColumnHeaders(columnMetadata.keySet());
						csvCurrentSizeInMemory = rows[0].length();
					}
				}
				workItem.Status__c = 'Completed';
			}
			update workItems;
		}
		catch (exception e) {
			List<String> errorMessageValues = new String[] { String.valueOf(e.getLineNumber()), e.getMessage() };

			Error_log__c errorLog = new Error_log__c(
				Exception_Message__c = String.format('Line: {0}. {1}', errorMessageValues),
				Process_Name__c = 'Extract Work Items Activities - Batch Apex',
				User__c = userinfo.getUserId(),
				Record_Id__c = BC.getJobId()
			);

			insert errorLog;
		}
	}

	global void finish(Database.BatchableContext BC) {
        //documentIds = new List<ID>();
		SaveCSVDocument();
		
		System.debug('invokeFileMerge = '+invokeFileMerge+', workItemType = '+workItemType);
		if(invokeFileMerge) {
			// calling file-merge
			// 1. autosend-to-mailhouse
			// 2. sensitive merge, but only for the specific workitem types
			Datetime now = DateTime.now();
			String dateStr = now.year()+'-'+now.month()+'-'+now.day()+'T'+now.hour()+'-'+now.minute()+'-'+now.second()+'-'+now.millisecond();
			FileMergeClient.scheduleForRetry('Schedule_FileMergeRequest-'+dateStr, collectionInstance.Collection_Instance_Code__c, documentIds, now.addMinutes(-3), -1);
		}

		List<Error_log__c> errors = [
			SELECT Process_Name__c, Exception_Message__c
			FROM Error_log__c
			WHERE Record_Id__c = :BC.getJobId()
		];

		if (activitySchedule.Id != null) {
			Activity_Schedule__c activitySchedule = [
				SELECT Name
				FROM Activity_Schedule__c
				WHERE Id = :activitySchedule.Id
			];

			sendActivityScheduleConfirmationEmail(activitySchedule.name + ' activity schedule', errors);
		} else {
			sendActivityScheduleConfirmationEmail('Ad hoc work item extract', errors);
		}
		
	}

	void sendActivityScheduleConfirmationEmail(String processName, List<Error_log__c> errors) {
		SystemSettings__c notificationEmail = SystemSettings__c.getInstance('workItemExtract.notificationEmail');

		if (notificationEmail == null || String.isBlank(notificationEmail.Value__c)) {
			return;
		}

		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.toAddresses = new String[] { notificationEmail.Value__c };

		if (errors.isEmpty()) {
			message.subject = processName + ' has completed successfully';
			String fileURLs = '';
			for(String documentLink : documentLinks) {
				if (String.isNotBlank(documentLink)) {
					fileURLs += '\n' + documentLink;
				}
			}
			message.plainTextBody = processName + ' has finished extracting at ' + Datetime.now().format('hh:mm a') + '.\n\nFile(s) can be found at:\n' + fileURLs;
		}
		else {
			message.subject = processName + ' failed to extract';
			// something fucked up call fronde
			String errorMessage = '';
			for(Error_log__c error : errors){
				if (String.isNotBlank(error.Exception_Message__c)) {
					errorMessage += '\n' + error.Exception_Message__c;
				}
			}

			message.plainTextBody = 'The system failed to create a work item extract csv for ' + processName + '.\nA partial extract may have been generated.\nThe errors are listed below:\n' + errorMessage;
		}
		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
		Messaging.sendEmail(messages);
	}

	// The code in this was originally part of execute.
	// I was unable to test the logic for grouping and contextual mappings
	// columns while it was still in the execute.
	@TestVisible
	String getRowData(Work_Item__c workItem, Map<String, String> columnMetadata) {

		// Eric: this is seriously hacking.  However, there is no other way to work out if a field has been selected..
		// cannot check null, give out the same "SObject row was retrieved via SOQL without querying the requested field: Work_Item__c.Response__r"
		// cannot check length, same error 
		boolean runGrouping = true;
		try{
			system.debug(workItem.Response__r);
		} catch (system.SObjectException ex){
			// we don't have Response__r object under workitem in the soql query
			runGrouping = false;
		}
		
		List<String> rowCells = new List<String>();

		for (String apiName : columnMetadata.values()) {

			if (String.isBlank(apiName)) {
				continue;
			}

			String cellFromWorkItem = getFieldValueFromWorkItemWithDefaultOfEmptyString(workItem, apiName);

			if (String.isNotBlank(cellFromWorkItem) && !cellFromWorkItem.equalsIgnoreCase('""')) {
				rowCells.add(cellFromWorkItem);
				continue;
			}
						
			// assume if we don't have the Response__r object, then we don't need to do any grouping or contextual
			if ( runGrouping ){
				String cellFromGrouping = getGroupingFieldValueOrEmptyString(groupingLabels, workItem.Response__r, apiName);
	
				if (String.isNotBlank(cellFromGrouping)) {
					rowCells.add('"' + cellFromGrouping + '"');
					continue;
				}
	
				String cellFromContextualMapping = getContextualMappingFieldValueOrEmptyString(contextualMappingLabels, workItem.Response__r, apiName);
	
				if (String.isNotBlank(cellFromContextualMapping)) {
					rowCells.add('"' + cellFromContextualMapping + '"');
					continue;
				}
			}

			String blankCell = '""';
			rowCells.add(blankCell);
		}

		return  String.join(rowCells, ',');
	}

	// Methods involved in class set up in the constructor.

	@TestVisible
	public static String createWorkItemCSVFormatQuery(Id csvFormatId, List<Schema.sObjectField> workItemCSVFormatFields) {
		List<String> queryFields = new List<String>();

		for (Schema.sObjectField objectField : workItemCSVFormatFields) {
			Schema.DescribeFieldResult fieldResult = objectField.getDescribe();

			Boolean isColumnHeaderField = fieldResult.name.startsWithIgnoreCase('column_header_');
			Boolean isOrderByField = fieldResult.name.startsWithIgnoreCase('order_by');

			if (isColumnHeaderField || isOrderByField) {
				queryFields.add(fieldResult.name);
			}
		}

		return 'SELECT Name, Grouping__c, Contextual_Mappings__c,' + String.join(queryFields, ',') + ' FROM Work_Item_CSV_Format__c WHERE Id = \'' + csvFormatId + '\' LIMIT 1';
	}

	@TestVisible
	static List<WorkItemCSVColumn> createWorkItemCSVColumnsList(Work_Item_CSV_Format__c workItemCSVFormat, List<Schema.sObjectField> workItemCSVFormatFields) {
		List<WorkItemCSVColumn> columnsHeaderFields = new List<WorkItemCSVColumn>();

		for (Schema.sObjectField objectField : workItemCSVFormatFields) {
			WorkItemCSVColumn column = WorkItemCSVColumn.Create(objectField);

			if (column != null) {
				column.value = String.valueOf(workItemCSVFormat.get(column.name));
				columnsHeaderFields.add(column);
			}
		}

		columnsHeaderFields.sort();
		return columnsHeaderFields;
	}

	@TestVisible
	static Map<String, String> createColumnMetadata(List<WorkItemCSVColumn> workItemCSVColumns) {
		Map<String, String> columns = new Map<String, String>();

		for (WorkItemCSVColumn csvColumn : workItemCSVColumns) {
			if (String.isBlank(csvColumn.value)) {
				continue;
			}
			columns.put(csvColumn.value, '');
		}

		for (Extract_Fields__c extractField : [SELECT Name, API_Name__c FROM Extract_Fields__c WHERE Name in :columns.keySet()]) {
			columns.put(extractField.name, extractField.API_Name__c);
		}

		return columns;
	}

	@TestVisible
	static String createWorkItemFieldsSelectQuery(Map<String, String> columns) {
		Set<String> fieldsRemoveDupes = new Set<String>(columns.values());

		List<String> fields = new List<String>();
		for (String field : fieldsRemoveDupes) {
			if (String.isBlank(field)) {
				continue;
			}

			fields.add(field);
		}

		// If the list contains one string it'll have a trailing ','
		String fieldsQueryString = String.join(fields, ', ').removeEnd(', ');

		if (!String.isBlank(fieldsQueryString)) {
			fieldsQueryString = ', ' + fieldsQueryString;
		}

		return fieldsQueryString;
	}

	@TestVisible
	static Map<String, String> createLabelMap(Id objId, String tableName, List<String> fieldsToSelect) {
		GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory(tableName, objId, fieldsToSelect);

		List<String> fields = factory.getsObjectsFieldNames();
		String objectQuery = factory.generateDatabaseQueryString(fields);

		sObject obj = Database.query(objectQuery);

		Map<String, String> labelsMap = new Map<String, String>();

		List<Schema.sObjectField> objectFields = Schema.getGlobalDescribe().get(tableName).getDescribe().fields.getMap().values();

		for (Schema.sObjectField objectField : objectFields) {
			Schema.DescribeFieldResult fieldResult = objectField.getDescribe();

			// Prevent the code from grabbing fields that we didn't query.
			Boolean isNotLabelField = !fieldResult.name.containsIgnoreCase('_Label');

			if (isNotLabelField) {
				continue;
			}


			String labelValue = (String) obj.get(fieldResult.name);

			if (String.isBlank(labelValue)) {
				continue;
			}

			labelsMap.put(labelValue, fieldResult.name);
		}

		return labelsMap;
	}

	// TODO: merge getGroupSelectQueryFromWorkItemResponse and getContextualMappingsSelectQueryFromWorkItemUnit
	// Make a generic method.

	// In order to include grouping data in an extract we need to select
	// the response on the work item. The response includes fields like GR_1__c that hold the values for
	// GR_1_Label__c. The labels match the Labels stored on the grouping we have linked to our
	// CSV Format record.
	@TestVisible
	static String getGroupSelectQueryFromWorkItemResponse(Map<String, String> columnMetadata) {
		List<Schema.sObjectField> responseFields = Schema.getGlobalDescribe().get('Response__c').getDescribe().fields.getMap().values();
		Set<String> fieldsAlreadyInSelect= new Set<String>(columnMetadata.values());

		List<String> queryFields = new List<String>();
		for (Schema.sObjectField objectField : responseFields) {
			Schema.DescribeFieldResult fieldResult = objectField.getDescribe();

			Boolean isGroupingField = fieldResult.name.startsWithIgnoreCase('GR_');

			if (isGroupingField) {
				if(!fieldsAlreadyInSelect.contains('Response__r' + '.' + fieldResult.name))
				{
					queryFields.add('Response__r' + '.' + fieldResult.name);
				}
			}
		}

		return String.join(queryFields, ',');
	}

	// In order to include contextual mappings data in an extract we need to select
	// the Response__r on the work item. The response includes fields like CO_1__c that hold the values for
	// CO_1_Label__c. The labels match the Labels stored on the contextual mapping we have linked to our
	// CSV Format record.
	@TestVisible
	static String getContextualMappingsSelectQueryFromWorkItemResponse(Map<String, String> columnMetadata) {
		List<Schema.sObjectField> responseFields = Schema.getGlobalDescribe().get('Response__c').getDescribe().fields.getMap().values();
		Set<String> fieldsAlreadyInSelect= new Set<String>(columnMetadata.values());

		List<String> queryFields = new List<String>();

		for (Schema.sObjectField objectField : responseFields) {
			Schema.DescribeFieldResult fieldResult = objectField.getDescribe();

			
			Boolean isContextualMappingField = fieldResult.name.startsWithIgnoreCase('CO_');
			if(!fieldsAlreadyInSelect.contains('Response__r' + '.' + fieldResult.name))
			{
				if (isContextualMappingField) {
					queryFields.add('Response__r' + '.' + fieldResult.name);
				}
			}
			
		}

		return String.join(queryFields, ',');
	}

    @TestVisible
    static String createDocumentName(String collectionInstanceCode, String workItemType, String deliveryMode, datetime scheduleDate, string activityScheduleNumber, string activityScheduleFilter) {
      //  DateTime todaysDate = System.now();
        DateTime RunDate = scheduleDate;
        List<String> nameComponents = new List<String>();

       if(activityScheduleNumber != null)
		{
			// [Collection Instance Code][Activity Schedule Number][FilterNumber][Datetime]
			// To do if filter name is empty what to be used?
			nameComponents.add(collectionInstanceCode.capitalize());
			nameComponents.add(activityScheduleNumber.capitalize());
			nameComponents.add(activityScheduleFilter.capitalize());
		//	nameComponents.add(todaysDate.format('yyyyMMdd_HHmmss'));
            nameComponents.add(RunDate.format('yyyyMMdd_HHmmss'));

		}else
		{
			// [Collection Instance Code][Delivery Mode][Work item type][Datetime][Activity Schedule Number][FileNumber]
			nameComponents.add(collectionInstanceCode.capitalize());
			nameComponents.add(deliveryMode.capitalize());
			nameComponents.add(workItemType.capitalize());
			//	nameComponents.add(todaysDate.format('yyyyMMdd_HHmmss'));
            nameComponents.add(RunDate.format('yyyyMMdd_HHmmss'));
		}

        // Collection name, work item type, or delivery mode could have spaces in them so we remove it.
        return String.join(nameComponents, '_').replace(' ', '_');
    }

    @TestVisible
    static List<String> createCSVRowsWithColumnHeaders(Set<String> headers) {
        String columnHeaders = '';

        for (String header : headers) {
            columnHeaders += header + ', ';
        }

        List<String> csvRows = new List<String>();
        csvRows.add(columnHeaders.removeEnd(', '));

        return csvRows;
    }

	// Methods used in execute and finish.

	@TestVisible
	static String getGroupingFieldValueOrEmptyString(Map<String, String> labels, Response__c response, String labelValue) {
		try {
			String fieldName = labels.get(labelValue);

			if (String.isBlank(fieldName)) {
				return '';
			}

			String responseLabelValue = (String) response.get(fieldName);

			if (String.isBlank(responseLabelValue)) {
				return '';
			}

			if (labelValue.equalsIgnoreCase(responseLabelValue)) {
				String valueFieldName = fieldName.remove('_Label');
				return (String) response.get(valueFieldName);
			}
		}
		catch (exception e) {}

		return '';
	}

	@TestVisible
	static String getContextualMappingFieldValueOrEmptyString(Map<String, String> labels, Response__c response, String labelValue) {
		try {
			String fieldName = labels.get(labelValue);

			if (String.isBlank(fieldName)) {
				return '';
			}

			String responseLabelValue = (String) response.get(fieldName);

			if (String.isBlank(responseLabelValue)) {
				return '';
			}

			if (labelValue.equalsIgnoreCase(responseLabelValue)) {
				String valueFieldName = fieldName.remove('_Label');
				return (String) response.get(valueFieldName);
			}
		}
		catch (exception e) {}

		return '';
	}

	/**
	* Depending on permissions dynamically grabbing field values can cause run time errors
	* that fall silent. This will cause CSVs with missing rows being generated and that status
	* on work items not being updated.
	* This method helps catch these errors and provides a default value.
	* It is better to have create a full CSV with missing cells than half a CSV.
	*/
	static String getFieldValueFromWorkItemWithDefaultOfEmptyString(Work_Item__c workItem, String apiName) {
		try {
			return getFieldValueFromWorkItem(workItem, apiName);
		}
		catch (exception e) {
			return '';
		}
	}

	@TestVisible
	static String getFieldValueFromWorkItem(Work_Item__c workItem, String apiName) {
		sObject record = workItem;
		List<String> components = apiName.split('\\.');

		if (components.isEmpty()) {
			return null;
		}

		for (String component : components) {
			if (!component.contains('__r')) {
				Object recordfield = record.get(component);
				String value = castObjectToString(recordfield);

				if (String.isBlank(value)) {
					return null;
				}
				//In case of text area all the new lines and quotes are removed
				return value.replace('\'', '').replaceAll('\n', '');
			}

			record = record.getSobject(component);
		}

		return null;
	}

	@TestVisible
	static String castObjectToString(Object o) {
		if(o == null) {
			return null;
		}

		if(o instanceof String || o instanceof Integer || o instanceof Long || o instanceof Boolean){
			String s = String.valueOf(o);
			return s != null ? '"' + s + '"': '""';
		}

		if (o instanceof Decimal) {
			Decimal d = (Decimal) o;
			return d != null ? '"' + String.valueOf(d.setScale(2)) + '"': '""';
		}

		if (o instanceof Date) {
			Date d = (Date) o;
			return d != null ? '"' + d.format() + '"' : '""';
		}

		if (o instanceof Datetime) {
			Datetime d = (Datetime) o;
			String format  = 'dd/MM/yyyy hh:mm:ss';
			return d != null ? '"' + d.format(format) + '"' : '""';
		}

		return null;
	}

	void SaveCSVDocument() {
		String csvBody = '';

		if (!rows.isEmpty()) {
			csvBody = String.join(rows, '\n');
		}

		String name = csvDocumentName + '_' + documentsCreated;

		Document csvDocument = new Document(
			AuthorId = UserInfo.getUserId(),
		//  AuthorId = DocumentAuthorID ,
			Name = name,
			FolderId = csvFolder.Id,
			Body = Blob.valueOf(csvBody),
			ContentType = 'application/csv',
			Type = 'csv'
		);

		insert csvDocument;
		// Create a link to the file.
		String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + csvDocument.id;
		documentLinks.add(fullFileURL);
		documentIds.add(csvDocument.id);
		documentsCreated += 1;
	}
}