/**
* @description
*	Controller extension for the NewWorkItemCSVFormat visual force page.
*	This controller helps dynamically generate the form for creating Work_Item_CSV_Foramt sObjects.
*	Work_Item_CSV_Format stores column headers for a CSV in fields with the naming convention Column_Header_{Integer}.
*	One of the limitations of this design is if the end user needs more columns on a CSV we will have to add more fields.
*	In an effort to reduce the number of changes this would create this controller helps generate the form.
* @author Joseph Newby
* @date 07.Sep.2015
* Remark Steven Zhu 20161111 ECP 3762 bug remove generic grouping/contextual fields in the picklist when collection is selected 
*/

public class NewWorkItemCSVFormatCX {
	public Work_Item_CSV_Format__c csvFormat { get; private set; }
	public List<WorkItemCSVColumn> columns { get; private set; }
	public List<SelectOption> workItemFields { get; private set; }
	
	// added for ECP-3556, matching the recordtype on the collection
	// possible values are Census, Social, and Collections
	private String collectionType{set;get;}

	public NewWorkItemCSVFormatCX(ApexPages.StandardController controller) {
		csvFormat = new Work_Item_CSV_Format__c();
		columns = getColumns();

		// default is Collections
		// this is to allow the user to create cross-collection CSV format.
		collectionType = 'Collections';

		if(controller.getId() != null){
			csvFormat = (Work_Item_CSV_Format__c) controller.getRecord();
			
			if(csvFormat.collection__c!=null && csvFormat.collection__r.recordtypeid != null ){
				collectionType = csvFormat.collection__r.recordtype.Name;
			}
			
			populateSelectOptionsWithHeaderOptions();

			for (WorkItemCSVColumn column : columns) {
				column.value = (String) csvFormat.get(column.name);
			}
		 
		} else {

			populateSelectOptionsWithHeaderOptions();
		}
	}

	/**
	* @description
	*	Work_Item_CSV_Format__c stores the name of Extract_Fields__c in fields
	*	with the pattern Column_Header_{Integer}__c.
	*	A limitation of this disign is getting the fields to act like a list
	*	so we can generate the HTML in the visualforce page using repeat tag.
	*	If in the future a new column is added we don't want to have to add
	*	more HTML to the visual force page this would cause the page to grow too large.
	* @return
	* @example
	*	 List<WorkItemCSVColumn> columns = getColumns();
	*/
	private List<WorkItemCSVColumn> getColumns() {
		Map<String, Schema.sObjectField> fields = Schema.getGlobalDescribe().get('Work_Item_CSV_Format__c').getDescribe().fields.getMap();

		List<WorkItemCSVColumn> columnsHeaderFields = new List<WorkItemCSVColumn>();

		for (Schema.sObjectField objectField : fields.values()) {
			WorkItemCSVColumn column = WorkItemCSVColumn.Create(objectField);

			if (column != null) {
				columnsHeaderFields.add(column);
			}
		}

		columnsHeaderFields.sort();
		return columnsHeaderFields;
	}

	private void populateSelectOptionsWithHeaderOptions() {
		workItemFields = new List<SelectOption>();

		workItemFields = getWorkItemFields();

		List<SelectOption> groupingFields = getGroupingFields(csvFormat.Grouping__c);

		// Greater than 1 because the first item is just a label. We don't want just the label.
		if (groupingFields.size() > 1) {
			workItemFields.addAll(groupingFields);
		}

		List<SelectOption> contextualMappingFields = getContextualMappingFields(csvFormat.Contextual_Mappings__c);

		// Greater than 1 because the first item is just a label. We don't want just the label.
		if (contextualMappingFields.size() > 1) {
			workItemFields.addAll(contextualMappingFields);
		}
		
	}

	@testvisible private List<SelectOption> getWorkItemFields() {
		//List<Extract_Fields__c> extractFields = Extract_Fields__c.getall().values();
		//To sort field names in picklist
		List<Extract_Fields__c> extractFields = new Extract_Fields__c[]{};
		
		
		// Eric: could have used dynamic SOQL, however, wanting to make sure we have the dependencies reference correctly to make sure
		// any changes to the custom settings will be stopped
		if(collectionType=='Collections'){
			extractFields = [Select Id,Name,API_Name__c from Extract_Fields__c where Visible_to_Business__c = true order by Name];
		} else if (collectionType=='Social') {
			extractFields = [Select Id,Name,API_Name__c from Extract_Fields__c where Visible_to_Social__c = true order by Name];
		} else { // census
			extractFields = [Select Id,Name,API_Name__c from Extract_Fields__c where Visible_to_Census__c = true order by Name];
		}

		List<SelectOption> options = new List<SelectOption>();

		// Allow the user to leave a column header empty.
		SelectOption emptyOption = new SelectOption('empty', 'empty');
		options.add(emptyOption);

		for (Extract_Fields__c extractField : extractFields) {
			if (String.isBlank(extractField.API_Name__c)) {
				continue;
			}
			if(csvFormat.Collection__c==null)
			{
				SelectOption option = new SelectOption(extractField.name, extractField.name);
				options.add(option);
			}else
			{
				//steven zhu generic contextual / generic grouping fields shouldn't be added to the picklist when collection is selected 
				if(!extractField.name.contains('Generic Contextual') && !extractField.name.contains('Generic Grouping') )
				{
					SelectOption option = new SelectOption(extractField.name, extractField.name);
					options.add(option);
				}
			}
		}

		return options;
	}

	public PageReference saveCSVFormat() {
		// CSV Format requires a name.
		if(csvFormat.name == null) {
			ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.Error, Label.Work_Item_CSV_Format_Missing_Name_Error);
			ApexPages.addmessage(msg);
			return null;
		}

		// CSV Format requires it's name to be unique.
		Boolean filenameIsUnique = csvFormatFilenameIsUnique(csvFormat.name);
		if (!filenameIsUnique) {
			ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.Error, Label.Work_Item_CSV_Format_Duplicate_Name_Error);
			ApexPages.addmessage(msg);
			return null;
		}

		for (WorkItemCSVColumn column : columns) {
			if (column.value == null) {
				continue;
			}

			Boolean columnIsEmpty = column.value.containsIgnoreCase('empty');

			if (columnIsEmpty) {
				csvFormat.put(column.name, null);
				continue;
			}

			csvFormat.put(column.name, column.value);
		}

		// This controller uses a lot of generic programing.
		// I've opted out of that type of programming here because of time constraints.
		if (String.isNotEmpty(csvFormat.Order_By_1__c) && csvFormat.Order_By_1__c.containsIgnoreCase('empty')) {
			csvFormat.Order_By_1__c = null;
		}
		if (String.isNotEmpty(csvFormat.Order_By_2__c) && csvFormat.Order_By_2__c.containsIgnoreCase('empty')) {
			csvFormat.Order_By_2__c = null;
		}
		if (String.isNotEmpty(csvFormat.Order_By_3__c) && csvFormat.Order_By_3__c.containsIgnoreCase('empty')) {
			csvFormat.Order_By_3__c = null;
		}
		if (String.isNotEmpty(csvFormat.Order_By_4__c) && csvFormat.Order_By_4__c.containsIgnoreCase('empty')) {
			csvFormat.Order_By_4__c = null;
		}
		if (String.isNotEmpty(csvFormat.Order_By_5__c) && csvFormat.Order_By_5__c.containsIgnoreCase('empty')) {
			csvFormat.Order_By_5__c = null;
		}

		upsert csvFormat;

		ApexPages.Message createdMessage = new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Work_Item_CSV_Format_Saved);
		ApexPages.addmessage(createdMessage);

		return new PageReference('/' + csvFormat.id);
	}

	public PageReference collectionSelected() {

		if(csvFormat.Collection__c==null){
			csvFormat.Grouping__c = null;
			csvFormat.Contextual_Mappings__c = null;
			
			// reset to default if collection is missing, assume this is for Business
			collectionType = 'Collections';
		} else {

			Collection__c[] selectedCollections = [select recordtype.name, name from Collection__c where id = :csvFormat.Collection__c];
			if(selectedCollections.isEmpty() || selectedCollections[0].recordtypeid == null ){
				collectionType = 'Collections';
			} else {
				collectionType = selectedCollections[0].recordtype.name;
			}

			List<Grouping__c> groupings = [
				select id
				from Grouping__c
				where collection__c = :csvFormat.Collection__c
				And Active__c = :true
				order by lastmodifieddate desc
				limit 1
			];

			if (!groupings.isEmpty()) {
				Grouping__c grouping = groupings.get(0);
				csvFormat.Grouping__c = grouping.id;
			}
			else {
				csvFormat.Grouping__c = null;
			}

			List<Contextual_Mappings__c> contextualMappings = [
				select id
				from Contextual_Mappings__c
				where collection__c = :csvFormat.Collection__c
				And Active__c = :true
				order by lastmodifieddate desc
				limit 1
			];

			if (!contextualMappings.isEmpty()) {
				Contextual_Mappings__c contextualMapping = contextualMappings.get(0);
				csvFormat.Contextual_Mappings__c = contextualMapping.id;
			}
			else {
				csvFormat.Contextual_Mappings__c = null;
			}
		}

		populateSelectOptionsWithHeaderOptions();
		return null;
	}

	private Boolean csvFormatFilenameIsUnique(String filenameToCheckFor) {
		try {
			Work_Item_CSV_Format__c csvFormatVerified = [
				SELECT ID
				FROM Work_Item_CSV_Format__c
				WHERE name = :filenameToCheckFor
				LIMIT 1
			];

			return csvFormatVerified.id==csvFormat.id;
		}
		// If there isn't a record with a matching name a System.QueryException will be thrown.
		catch (QueryException e) {
			return true;
		}
	}

	private List<SelectOption> getGroupingFields(id groupingId) {
		if (groupingId == null) {
			return new list<SelectOption>();
		}

		GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', groupingId, new List<String> {'_label__c'});
		return factory.querySelectOptionFields('Grouping');
	}

	private List<SelectOption> getContextualMappingFields(id contextualMappingId) {
		if (contextualMappingId == null) {
			return new list<SelectOption>();
		}

		GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Contextual_Mappings__c', contextualMappingId, new List<String> {'_label__c'});
		return factory.querySelectOptionFields('Contextual Mapping');
	}
}