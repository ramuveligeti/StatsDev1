// This class generates a list of select options
// for a given sObject and fields filtered on name.
public class GenericsObjectSelectOptionFactory {

    private String sObjectName;
    private Id sObjectId;
    private List<String> fieldsToSelect;
   
   /**
    * @description This class generates a list of selection options for a given sObject.
    * The select options are populate with the values of fields whos api name are in fieldsToSelect.
    * 
    * @param sObjectName The object the id matches.
    * @param sObjectId The id of an sObject we will grab values from.
    * @param fieldsToSelect The api names of fields we will grab the values from to populate our select option list.
    * 
    * @return the describe field result for the given field
    * 
    * @example
    * GenericsObjectSelectOptionFactory factory = new GenericsObjectSelectOptionFactory('Grouping__c', grouping.id, '_label__c');
    * List<SelectOption> options = factory.querySelectOptionFields('Grouping');
    */
    public GenericsObjectSelectOptionFactory(String sObjectName, id sObjectId, List<String> fieldsToSelect) {
        this.sObjectName = sObjectName;
        this.sObjectId = sObjectId;
        this.fieldsToSelect = fieldsToSelect;
    }
    
    public List<SelectOption> querySelectOptionFields(String sectionTitle) {
        List<SelectOption> options = new List<SelectOption>();

        if (String.isNotBlank(sectionTitle)) {
            List<SelectOption> selectSectionTitle = createSelectOptionSectionTitle(sectionTitle);
            options.addAll(selectSectionTitle);
        }

        List<String> fields = getsObjectsFieldNames();

        String query = generateDatabaseQueryString(fields);
        sObject obj = Database.query(query);

        List<SelectOption> fieldOptions = createSelectOptionsFromFieldsOnsObject(obj, fields);

        options.addAll(fieldOptions);

        return options;
    }

    public List<String> getsObjectsFieldNames() {
        system.Debug('Object name: ' + sObjectName);
        Map<String, Schema.sObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();

        List<String> filteredFields = new List<String>();

        for(Schema.sObjectField field : fields.values()) {
            Schema.DescribeFieldResult fieldResult = field.getDescribe();

            for(String fieldNameToSelect : fieldsToSelect){
                if (fieldResult.name.containsIgnoreCase(fieldNameToSelect)) {
                    filteredFields.add(fieldResult.name);
                }
            }
        }

        return filteredFields;
    }

    public String generateDatabaseQueryString(List<String> fields) {
        String selectFields = String.join(fields, ',');
        String idString = '\'' + sObjectId + '\'';

        List<String> queryComponents = new List<String>{
            'select',
            selectFields,
            'from',
            sObjectName,
            'where id =',
            idString
        };
        
        return String.join(queryComponents, ' ');
    }

    @testVisible
    private List<SelectOption> createSelectOptionsFromFieldsOnsObject(sObject obj, List<String> fields) {
        List<SelectOption> options = new List<SelectOption>();

        for (String field : fields) {
            String val = (String) obj.get(field);

            if (String.isNotBlank(val)) {
                SelectOption option = new SelectOption(val, val);
                options.add(option);
            }
        }

        return options;
    }

    @testVisible
    private List<SelectOption> createSelectOptionSectionTitle(String title) {
        String sectionTitle = '--- ' + title + ' ---';

        SelectOption blankOption = new SelectOption('', '');
        blankOption.setDisabled(true);

        SelectOption titleOption = new SelectOption(sectionTitle, sectionTitle);
        titleOption.setDisabled(true);

        return new List<SelectOption> {
            blankOption, titleOption, blankOption
        };
    }
}