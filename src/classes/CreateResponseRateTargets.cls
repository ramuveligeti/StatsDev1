/**
* @description This is an extension controller for CreateResponseRateTargets Page.
* @author Ram Veligeti
* @date 5.Aug.2015
*/
public class CreateResponseRateTargets {
	private Response_Rate__c collectionResponseRate = new Response_Rate__c();
	public static Map<String,Grouping_Settings__c> groupingSettings = Grouping_Settings__c.getAll();
	public Grouping__c grouping{get;set;}
	public Map<String,list<SelectOption>> groupValues{get;set;}
	public boolean saveAndNew{get;set;}
	public Decimal targetPercentage{get;set;}
	public String targetMeasure{get;set;}
	public Map<String,SObjectField> responseFieldMap = Response__c.sObjectType.getDescribe().fields.getMap();
	public Map<String,SObjectField> groupingFieldMap = Grouping__c.sObjectType.getDescribe().fields.getMap();
	public Set<String> standardFields = new Set<String>();
	public boolean displayPage{get;set;}
	public boolean overallTarget{get;set;}
	// dummy object to use on the page to display drop down, and other field features
	public Response__c response{get;set;}
	public Response_Rate_Target__c inputRRT{get;set;}

	//Standard Controller
	public CreateResponseRateTargets(ApexPages.StandardController stdCont){
		collectionResponseRate = (Response_Rate__c)stdCont.getRecord();
		String collectionCode = collectionResponseRate.Collection__r.Collection_Code__c;
		groupValues = new Map<String,list<SelectOption>>();
		response= new Response__c();
		displayPage = true;
		overallTarget = false;
		system.debug('collectionCode=='+collectionCode+'=='+groupingSettings.get(collectionCode));
		//Fetch standard fields from custom settings
		if(groupingSettings.containsKey(collectionCode) && groupingSettings.get(collectionCode).Standard_Fields__c != NULL){
			displayPage = true;
			String temp = groupingSettings.get(collectionCode).Standard_Fields__c;
			if(temp.contains(',')){
				for(String s: temp.split(',')){standardFields.add(s);}
			} else {
				standardFields.add(temp);
			}
		}

		saveAndNew = false;
		//Dynamic SOQL to fetch all the fields of Grouping object
		if(collectionResponseRate.Grouping__c != NULL && collectionResponseRate.Grouping__r.Active__c){
			displayPage = true;
			String fieldNames = ApexUtility.getFieldNamesOfSObject(groupingFieldMap,true);
			String query ='Select '+fieldNames+' from Grouping__c where Id = \''+collectionResponseRate.Grouping__c+'\' and Active__c = true';
			try{
				grouping = Database.query(query);
			} catch(exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error: '+e.getMessage()));
				displayPage = false;
				return;
			}

			//Create picklist for Group names
			Map<String, Schema.SObjectField> groupingFieldMap = Schema.SObjectType.Grouping__c.fields.getMap();
			for(String fieldName: groupingFieldMap.keySet()){
				if(fieldName.startsWithIgnoreCase('GR_') && fieldName.containsIgnoreCase('Label') && grouping.get(fieldName) != NULL){
					groupValues.put(fieldName,fetchGroupingValues(fieldName));
				}
			}
		}
		
		inputRRT = new Response_Rate_Target__c();

	}

	//Dynamic VF component to render Standard fields from custom setting and grouping fields
	public Component.Apex.PageBlockSection getDynamicSection(){
		Component.Apex.PageBlockSection dynamicSection = new Component.Apex.PageBlockSection();

		// add in overall target checkbox
		Component.Apex.PageBlockSectionItem dsi = new Component.Apex.PageBlockSectionItem();
		Component.Apex.InputCheckbox icb = new Component.Apex.InputCheckbox();
		icb.expressions.value = '{!overallTarget}';
		icb.id = 'overallTarget';
		Component.Apex.OutputLabel ol = new Component.Apex.OutputLabel();
		ol.value = 'Overall Target';
		dsi.childComponents.add(ol);
		dsi.childComponents.add(icb);
		dynamicSection.childComponents.add(dsi);
		dynamicSection.childComponents.add(new Component.Apex.PageBlockSectionItem());

		integer compCount=0;
		//Loop thru standard fields
		for(String st: standardFields){
			if(String.isNotBlank(st)){
				st= st.trim();
				list<SelectOption> options = new list<SelectOption>();
				options.add(new SelectOption('True', 'Yes'));
				options.add(new SelectOption('False', 'No'));
				options.add(new SelectOption('', '--None--',true));
				Component.Apex.PageBlockSectionItem dynamicSectionItem = new Component.Apex.PageBlockSectionItem();
				Schema.DisplayType fielddataType = responseFieldMap.get(st.toLowerCase()).getDescribe().getType();

				Component.Apex.OutputLabel inputFieldLabel = new Component.Apex.OutputLabel();
				inputFieldLabel.value = responseFieldMap.get(st.toLowerCase()).getDescribe().getLabel();
				//inputFieldLabel.for = st;
				dynamicSectionItem.childComponents.add(inputFieldLabel);

				if(fielddataType == Schema.DisplayType.BOOLEAN){
					Component.Apex.selectList selectList = new Component.Apex.selectList();
					selectList.expressions.value = '{!response.'+st+'}';
					selectList.id = st;
					selectList.multiSelect = false;
					selectList.size =1;

					for(SelectOption s: options){
						Component.Apex.SelectOption dynamicSelectOption = new Component.Apex.SelectOption();
						if(String.isBlank(s.getValue())){
							dynamicSelectOption.itemValue = s.getValue();
							dynamicSelectOption.itemLabel = s.getLabel();
						} else {
							dynamicSelectOption.itemValue = Boolean.valueOf(s.getValue());
							dynamicSelectOption.itemLabel = s.getLabel();
						}
						selectList.childComponents.add(dynamicSelectOption);
					}
					dynamicSectionItem.childComponents.add(selectList);
				} else {
					Component.Apex.InputField inputField = new Component.Apex.InputField();
					inputField.expressions.value = '{!response.'+st+'}';
					inputField.id = st;
					dynamicSectionItem.childComponents.add(inputField);
				}
				dynamicSection.childComponents.add(dynamicSectionItem);
				compCount++;
			}
		}

		//Loop thru grouping fields
		for(String st: groupValues.keySet()){
			Component.Apex.PageBlockSectionItem dynamicSectionItem = new Component.Apex.PageBlockSectionItem();

			String fName = st.removeStartIgnoreCase('GR_');
			fName = fName.removeEndIgnoreCase('_label__c');
			String fValueApi = 'GV'+fName+'__c';

			Component.Apex.selectList selectList = new Component.Apex.selectList();
			selectList.expressions.value = '{!grouping.'+fValueApi+'}';
			selectList.id = st;
			selectList.multiSelect = false;
			selectList.size =1;
			for(SelectOption sol: groupValues.get(st)){
				Component.Apex.SelectOption dynamicSelectOption = new Component.Apex.SelectOption();
				dynamicSelectOption.itemValue = sol.getValue();
				dynamicSelectOption.itemLabel = sol.getLabel();
				selectList.childComponents.add(dynamicSelectOption);
			}
			Component.Apex.OutputLabel selectListLabel = new Component.Apex.OutputLabel();
			selectListLabel.value = grouping.get(st);
			dynamicSectionItem.childComponents.add(selectListLabel);
			dynamicSectionItem.childComponents.add(selectList);
			dynamicSection.childComponents.add(dynamicSectionItem);
			compCount++;
		}

		if(Math.mod(compCount,2)==1){
			// make sure the target parcentage always the last item on its own row
			dynamicSection.childComponents.add(new Component.Apex.PageBlockSectionItem());
		}

		List<String[]> standardRRTFields = new List<String[]>{
			new String[]{'inputRRT.Target_Percentage__c', 'targetPercentage','Target Percentage'}, 
			new String[]{'inputRRT.Measure__c', 'measure','Measure'}
		};
		for(String[] x:standardRRTFields){
			Component.Apex.PageBlockSectionItem dynamicSectionItem = new Component.Apex.PageBlockSectionItem();
			Component.Apex.InputField inputField = new Component.Apex.InputField();
			inputField.expressions.value = '{!'+x[0]+'}';
			inputField.id = x[1];
			Component.Apex.OutputLabel inputFieldLabel = new Component.Apex.OutputLabel();
			inputFieldLabel.value = x[2];
			dynamicSectionItem.childComponents.add(inputFieldLabel);
			dynamicSectionItem.childComponents.add(inputField);
			dynamicSection.childComponents.add(dynamicSectionItem);
		}
		

		return dynamicSection;
	}

	//To fetch picklist values for the selected group name
	private list<SelectOption> fetchGroupingValues(String fName){
		//Dynamically find the value for the selected group name by API Name
		fName = fName.removeStartIgnoreCase('GR_');
		fName = fName.removeEndIgnoreCase('_label__c');
		String fValueApi = 'GV'+fName+'__c';
		String gValue = String.valueOf(grouping.get(fValueApi));

		list<SelectOption> options = new list<SelectOption>();
		options.add(new SelectOption('', '--None--'));
		if(String.isNotBlank(gValue) && gValue.contains(',')){
			List<String> valueOptions = gValue.split(',');
			for(String st: valueOptions){
				options.add(new SelectOption(st, st));
			}
		} else if(String.isNotBlank(gValue)){
			options.add(new SelectOption(gValue, gValue));
		}
		return options;
	}

	//Save
	public PageReference save(){
		if(inputRRT.Target_Percentage__c == NULL || inputRRT.Target_Percentage__c <=0 || inputRRT.Target_Percentage__c >100){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Target Percentage must not be NULL and should be between 1 and 100'));
			return null;
		}
		/*/Logic to create multiple groupings based on combinations of picklist values if ALL is selected
		Integer cnt=0;
		List<String> allList = new List<String>();
		for(integer i=1; i<=groupValues.size(); i++){
			String fName = 'GR_'+i+'_Label__c';
			String fValueApi = 'GV'+i+'__c';

			if(String.valueOf(grouping.get(fValueApi)) == 'All'){
				cnt++;
				//verify All values are not more than 2
				if(cnt > 2){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You cannot select more than 2 \'All\' values'));
					return null;
				} else {
					allList.add(fName);
				}
			}
		}

		List<Response_Rate_Target__c> cigList = new List<Response_Rate_Target__c>();
		if(allList.size() ==2){
			for(SelectOption al0: groupValues.get(allList[0].toLowerCase())){
				for(SelectOption al1: groupValues.get(allList[1].toLowerCase())){
					if(String.isNotBlank(al0.getValue()) && String.isNotBlank(al1.getValue())){
						Response_Rate_Target__c cig = new Response_Rate_Target__c();
						cig.Target_Value__c = al0.getValue()+'-'+al1.getValue();
						cig.Target_Name__c = grouping.get(allList[0])+'-'+grouping.get(allList[1]);
						cig.Response_Rate__c = collectionResponseRate.Id;
						cig.Target_Percentage__c = targetPercentage;
						cigList.add(cig);
					}
				}
			}
		} else if(allList.size() == 1){
			for(SelectOption al: groupValues.get(allList[0].toLowerCase())){
				if(String.isNotBlank(al.getValue())){
					Response_Rate_Target__c cig = new Response_Rate_Target__c();
					cig.Target_Value__c = al.getValue();
					cig.Target_Name__c = String.valueOf(grouping.get(allList[0]));
					cig.Response_Rate__c = collectionResponseRate.Id;
					cig.Target_Percentage__c = targetPercentage;
					cigList.add(cig);
				}
			}
		}

		if(!cigList.isEmpty()){
			insert cigList;
		} else {*/

		Map<String, Schema.SObjectField> mapData = Schema.getGlobalDescribe().get('Response__c').getDescribe().fields.getMap();

		String groupingName='',groupingValue='';
		if(overallTarget){
			groupingValue='true';
			groupingName='Overall Target';
		} else {
			//Loop thru standard fields to form grouping name and value
			for(String st: standardFields){
				st = st.trim();
				if(response.get(st) != NULL){
					if(String.isNotBlank(groupingName)){
						groupingName += '-';
					}
					groupingName+=String.valueOf(responseFieldMap.get(st.toLowerCase()).getDescribe().getLabel());

					if(String.isNotBlank(groupingValue)){						
						groupingValue+='-';
					}

					String tempValue=String.valueOf(response.get(st));
					// if the field is with lookup type, get the name field on the related record
					Schema.SObjectField fld=mapData.get(st);
					if(fld!=null && string.valueOf(fld.getDescribe().getType())=='REFERENCE'){
						String parentObjName=fld.getDescribe().getReferenceTo()[0].getDescribe().getName();
						sObject[] relatedRecords=Database.query('select Name from '+parentObjName+' where id=\''+response.get(st)+'\' ');
						if(relatedRecords.size()>0){
							tempValue=String.valueOf(relatedRecords[0].get('Name'));
						}
					}
					groupingValue+=tempValue;
				}
			}

			//Loop thru grouping fields to form grouping name and value
			for(integer i=1; i<=groupValues.size(); i++){
				String fName = 'GR_'+i+'_Label__c';
				String fValueApi = 'GV'+i+'__c';

				if(grouping.get(fValueApi) != NULL){
					if(String.isNotBlank(groupingValue)){
						groupingValue += '-';
					}
					groupingValue += String.valueOf(grouping.get(fValueApi));
					if(String.isNotBlank(groupingName)){
						groupingName += '-';
					}
					groupingName += String.valueOf(grouping.get(fName));
				}
			}

		}// not overall target

		//Create collection instance grouping
		if(String.isNotBlank(groupingValue)){
			Response_Rate_Target__c cig = new Response_Rate_Target__c();
			cig.Target_Value__c = groupingValue;
			cig.Target_Name__c = groupingName;
			cig.Response_Rate__c = collectionResponseRate.Id;
			cig.Target_Percentage__c = inputRRT.Target_Percentage__c;
			cig.Measure__c = inputRRT.Measure__c;
			insert cig;
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'You must provide atleast one value'));
			return null;
		}
		
		//If Save and New
		if(!saveAndNew){
			return new ApexPages.StandardController(collectionResponseRate).view();
		} else {
			PageReference reference= new PageReference('/apex/CreateResponseRateTargets?Id='+collectionResponseRate.Id);
			reference.setRedirect(true);
			return reference;
		}
	}
}