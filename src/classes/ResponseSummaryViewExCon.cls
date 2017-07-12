/**
  * @description This is an extension controller for ResponseSummaryView Page. 
  * @author Ram Veligeti
  * @date 7.Jul.2015
*/
public with sharing class ResponseSummaryViewExCon {
	public List<ResponseSummaryWrapper> responseWrapper { get; set; }
	public static Map<String, Response_Settings__c> responseSummarySettings = Response_Settings__c.getAll();
	public Boolean noRecordsFound { get; set; }
	public String newIndividualRecord { get; set; }
	public Boolean createPerm { get; set; }
	public String buttonName { get; set; }

	//Standard Controller for Response
	public ResponseSummaryViewExCon(ApexPages.StandardController stdCont) {
		Response__c resp = (Response__c) stdCont.getRecord();
		String collectionCode = resp.Collection_Instance__r.Collection__r.Collection_Code__c;
		//Validate custom settings & Response fields
		if (responseSummarySettings.containsKey(collectionCode) &&
		    responseSummarySettings.get(collectionCode).Enable_Summary_View__c &&
		    String.isNotBlank(responseSummarySettings.get(collectionCode).Master_Response__c) &&
		    responseSummarySettings.get(collectionCode).Master_Response__c == resp.RecordType.Name &&
		    String.isNotBlank(responseSummarySettings.get(collectionCode).Detail_Responses__c) &&
		    String.isNotBlank(resp.Unit_of_Interest__c)
		) {
			responseWrapper = new List<ResponseSummaryWrapper> ();
			String detailedResponseRecordType = responseSummarySettings.get(collectionCode).Detail_Responses__c;
			String individualRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(detailedResponseRecordType).getRecordTypeId();
			String individualFieldIds = responseSummarySettings.get(collectionCode).New_Detail_Response_Field_Id_s__c;
			String individualObjectId = responseSummarySettings.get(collectionCode).New_Detail_Response_Object_Id__c;
			String whereClause = responseSummarySettings.get(collectionCode).Where_Clause__c;
			buttonName = responseSummarySettings.get(collectionCode).New_Detail_Response_Button__c;
			String collectionInstanceFieldId, unitFieldId;

			//get field Id's to form new Individual record string
			if (String.isNotBlank(individualFieldIds)) {
				List<String> fieldIds = individualFieldIds.split(',');
				for (String st : fieldIds) {
					if (st.containsIgnoreCase('Collection_Instance')) {
						collectionInstanceFieldId = st.split('=') [1].trim();
					}

					if (st.containsIgnoreCase('Unit')) {
						unitFieldId = st.split('=') [1].trim();
					}
				}
			}
			String whereClauseStr;
			if(String.isNotBlank(whereClause)){
				for (String st : whereClause.split(',')) {
					if(String.isBlank(whereClauseStr)){whereClauseStr = ' and '+st+' = \''+resp.get(st)+'\' ';}
					else{whereClauseStr += ' and '+st+' = \''+resp.get(st)+'\' ';}
				}
			}

			//check the object Id before forming the string
			if (String.isNotBlank(individualObjectId)) {
				newIndividualRecord = '/' + individualObjectId
				+ '/e?RecordType='
				+ individualRecordTypeId
				+ '&retURL=%2F'
				+ resp.Id
				+ '&' + collectionInstanceFieldId + '='
				+ resp.Collection_Instance__r.Name
				+ '&' + collectionInstanceFieldId + '_lkid='
				+ resp.Collection_Instance__c
				+ '&' + unitFieldId + '='
				+ resp.Unit_of_Interest__r.Name
				+ '&' + unitFieldId + '_lkid='
				+ resp.Unit_of_Interest__c;
			}

			//Fetch all field API names of Response
			Map<String, SObjectField> fieldMap = Response__c.sObjectType.getDescribe().fields.getMap();
			String fieldNames = ApexUtility.getFieldNamesOfSObject(fieldMap, true);
			fieldNames += ',Collection_Instance__r.Name';
			fieldNames += ',Unit_of_Interest__r.Name';
			fieldNames += ',RecordType.Name';
			fieldNames += ',Contact__r.FirstName';
			fieldNames += ',Contact__r.LastName';

			String queryString;
			system.debug('whereClauseStr=='+whereClauseStr);
			if (responseSummarySettings.get(collectionCode).Master_Response__c == responseSummarySettings.get(collectionCode).Detail_Responses__c && resp.Survey_Unit__c == NULL && resp.Unit_Association__c != NULL) {
				//Form query string
				if(String.isNotBlank(whereClauseStr)){
					queryString = 'Select '
					+ fieldNames
					+ ' from Response__c where Collection_Instance__c = \''
					+ resp.Collection_Instance__c
					+ '\' and Unit_of_Interest__c = \''
					+ resp.Unit_of_Interest__c
					+ '\' and Unit_of_Interest__c != NULL and Survey_Unit__c != NULL and Id != \''
					+ resp.Id
					+ '\' and Unit_Association__c = \''
					+ resp.Unit_Association__c
					+ '\' ' + whereClauseStr + ' order by createddate';
				}else{
					queryString = 'Select '
					+ fieldNames
					+ ' from Response__c where Collection_Instance__c = \''
					+ resp.Collection_Instance__c
					+ '\' and Unit_of_Interest__c = \''
					+ resp.Unit_of_Interest__c
					+ '\' and Unit_of_Interest__c != NULL and Survey_Unit__c != NULL and Id != \''
					+ resp.Id
					+ '\' and Unit_Association__c = \''
					+ resp.Unit_Association__c
					+ '\' order by createddate';
				}
			} else if (responseSummarySettings.get(collectionCode).Master_Response__c != responseSummarySettings.get(collectionCode).Detail_Responses__c) {
				//Form query string
				if(String.isNotBlank(whereClauseStr)){
					queryString = 'Select '
					+ fieldNames
					+ ' from Response__c where Collection_Instance__c = \''
					+ resp.Collection_Instance__c
					+ '\' and Unit_of_Interest__c = \''
					+ resp.Unit_of_Interest__c
					+ '\' and Unit_of_Interest__c != NULL and RecordTypeId = \''
					+ individualRecordTypeId
					+ '\' and Id != \''
					+ resp.Id
					+ '\' ' + whereClauseStr + ' order by createddate';
				}else{
					queryString = 'Select '
					+ fieldNames
					+ ' from Response__c where Collection_Instance__c = \''
					+ resp.Collection_Instance__c
					+ '\' and Unit_of_Interest__c = \''
					+ resp.Unit_of_Interest__c
					+ '\' and Unit_of_Interest__c != NULL and RecordTypeId = \''
					+ individualRecordTypeId
					+ '\' and Id != \''
					+ resp.Id
					+ '\' order by createddate';
				}
			}

			List<Response__c> responseSummaries = new List<Response__c> ();
			//Dynamic query
			if (String.isNotBlank(queryString)) {
				system.debug('queryString=='+queryString);
				responseSummaries = Database.query(queryString);
			}

			//Get profile name of the user
			String profileName = [Select Name
			                      from Profile
			                      where Id = :UserInfo.getProfileId()].Name;

			//Get object permissions of this user. We need this to display edit and delete links on the response records
			List<ObjectPermissions> objPermissions = [SELECT Id, SObjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete
			                                          FROM ObjectPermissions
			                                          WHERE SObjectType = 'Response__c'
			                                          and parentid in(select id
			                                                          from permissionset
			                                                          where PermissionSet.Profile.Name = :profileName)];
			Boolean editPerm = false, deletePerm = false, readPerm = false;
			createPerm = false;
			for (ObjectPermissions op : objPermissions) {
				if (op.PermissionsEdit) {
					editPerm = true;
				}

				if (op.PermissionsDelete) {
					deletePerm = true;
				}

				if (op.PermissionsCreate && String.isNotBlank(newIndividualRecord) && String.isNotBlank(buttonName)) {
					createPerm = true;
				}

				if (op.PermissionsRead) {
					readPerm = true;
				}
			}

			//check if detail responses exist or not
			if (responseSummaries.isEmpty() || !readPerm) {
				noRecordsFound = true;
			} else {
				noRecordsFound = false;
			}

			//Create wrapper using object permissions and response details
			for (Response__c rs : responseSummaries) {
				//Create edit URL 
				String editLink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + rs.Id + '/e?retURL=%2F' + resp.Id;
				responseWrapper.add(new ResponseSummaryWrapper(editLink, editPerm, deletePerm, rs));
			}
		} else {
			noRecordsFound = true;
		}
	}

	//Wrapper class
	public class ResponseSummaryWrapper {
		public String editLink { get; set; }
		public Boolean editPermission { get; set; }
		public Boolean deletePermission { get; set; }
		public Response__c responseObj { get; set; }
		public ResponseSummaryWrapper(String l, Boolean e, Boolean d, Response__c r) {
			editLink = l;
			editPermission = e;
			deletePermission = d;
			responseObj = r;
		}
	}
}