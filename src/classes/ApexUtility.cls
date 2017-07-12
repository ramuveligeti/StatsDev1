/**
 * @description This class is used add reusable code
 * @author Ram Veligeti
 * @date 22.Apr.2015
 */
public class ApexUtility {
    /**
    * @description This method is used to Log errors
    * @author Ram Veligeti
    * @param errorMsg is used to capture the error message
    * @param lineNumber is used to capture the line number of the failure
    * @param processName is used to capture the Name of the component
    * @param userId is used to capture the user Id
    */
    public static void RecordErrorLog(String errorMsg, Integer lineNumber, String processName, String userId){
        Error_log__c el = new Error_log__c();
        el.Exception_Message__c = String.format('{0}\nLine Number: {1}', new List<String> {errorMsg, String.valueOf(lineNumber)});
        el.Process_Name__c = processName;
        el.User__c = userId;
        insert el;
    }

    // Method used in generating Dynamic SOQL
    public static String getFieldNamesOfSObject(Map<String,Schema.SObjectField> fieldMap, Boolean selectAllFields) {
        List<String> fieldList = new List<String>();
        //build dynamic list of fieldnames
        for (String fieldKey : fieldMap.keySet())
        {
            Schema.SObjectField fsObj = fieldMap.get(fieldKey);
            Schema.DescribeFieldResult f = fsObj.getDescribe();
            String fieldName = f.getName();
            if (selectAllFields)  fieldList.add(fieldName);
            else if (f.getName()=='Id' || f.isNameField() || f.isCustom()) fieldList.add(fieldName);
        }

        String fieldNames = '';
        for (String field : fieldList)
        {
            if (fieldNames.length()>0) fieldNames += ',';
            fieldNames += field;
        }
        return fieldNames;
    }

    private static String kHexChars = '0123456789abcdefABCDEF';

    public static String GUID() {
        String returnValue = '';
        Integer nextByte = 0;
        for(Integer i=0; i<16; i++){
            if (i==4||i==6||i==8| i==10) {returnValue += '-';}
            nextByte = (Math.round(Math.random() * 255)-128) & 255;
            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }
            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }
            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }
        return returnValue;
    }

    public static String getCharAtIndex(String str, Integer index) {
        // can't use null or empty, it may intentionally be a leading or tailing space
        if (str==null||str.length()<=0||index==str.length()){return null;}
        return str.substring(index, index+1);
    }

    public static list<SelectOption> getPicklistValues(String ObjectApi_name, String fld,Boolean noneRequired){
        list<SelectOption> options = new list<SelectOption>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        Sobject Object_name = targetType.newSObject();
        // Get the object type of the SObject.
        Schema.sObjectType objType = Object_name.getSObjectType();
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        // Get a map of fields for the SObject
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        // Get the list of picklist values for this field.
        list<Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();
        if(noneRequired){
            options.add(new SelectOption('', '--None--'));
        }
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a : values){
            options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        return options;
    }


	public static boolean sendEmail(SystemSettings__c notificationEmail,String subject,String bodyText, Id targetObjectId,String templateName, Id whatId, boolean saveActivity){        
        // we allow the custom settings to store multiple email addresses
        String[]recipients = new String[]{};
        if(notificationEmail!=null && String.isNotBlank(notificationEmail.Value__c)){
			recipients = notificationEmail.Value__c.split(',');
        } else {
        	recipients.add(UserInfo.getUserEmail());
        }
        
        return sendEmail(recipients,subject,bodyText, targetObjectId, templateName, whatId, saveActivity);
	}
	
	public static boolean sendEmail(String[]toAddresses,String subject,String bodyText, Id targetObjectId,String templateName, Id whatId, boolean saveActivity){
        
        if(toAddresses==null||toAddresses.isEmpty()||String.isBlank(subject)||string.isBlank(bodyText)){
        	system.debug(LoggingLevel.Warn, 'Cannot send email with null toAddresses, subject, or body');
        	return false;
        }
        Messaging.SingleEmailMessage message = createMessage(toAddresses,subject,bodyText, targetObjectId, templateName, whatId, saveActivity);
        Messaging.SingleEmailMessage[] messages =  new Messaging.SingleEmailMessage[]{message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug(LoggingLevel.Debug, 'The email was sent successfully.');
        } else {
            System.debug(LoggingLevel.Error, 'The email failed to send: ' + results[0].errors[0].message);
        }
        return results[0].success;
	}
	
	@TestVisible
	private static Messaging.SingleEmailMessage createMessage(String[]toAddresses,String subject,String bodyText, Id targetObjectId,String templateName, Id whatId, boolean saveActivity){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = toAddresses;
		message.subject = subject;
        message.plainTextBody = bodyText;

		if (String.isNotBlank(templateName)){
			message.setTemplateId([select id from EmailTemplate where DeveloperName= :templateName].id);
		}
		if (String.isNotBlank(whatId)){
			message.setWhatId(whatId);
		}
		if (String.isNotBlank(targetObjectId)){
			message.setTargetObjectId(targetObjectId);
		}
		
		message.setSaveAsActivity(saveActivity);
		return message;
	}
    
    
	
}