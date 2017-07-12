public class StagingElementTriggerHandler {
	
	private static final Set<String> PROCESS_IMMIDEATELY_COLLECTION_INSTANCE_RECORD_TYPES = new Set<String>{'Census'};
	
	private static Collection_Instance__c private_collectionInstance;
	private static Boolean doneCollectionInstanceLookup = false;
	private static Collection_Instance__c findCollectionInstance(String collectionInstanceCode){
		if(!doneCollectionInstanceLookup){
			List<Collection_Instance__c> collectionInstances = [select
					Collection_Instance_Code__c,
					Collection__c,
					RecordType.Name,
					Sample_Size__c,
					Collection__r.Collection_Code__c,
					Collection__r.RecordType.Name,
					Primary_Mode__c,
					Delivery_Mode__c,
					Grouping__c,
					Grouping__r.GR_1_Label__c,
					Grouping__r.GR_2_Label__c,
					Grouping__r.GR_3_Label__c,
					Grouping__r.GR_4_Label__c,
					Grouping__r.GR_5_Label__c,
					Grouping__r.GR_6_Label__c,
					Grouping__r.GR_7_Label__c,
					Grouping__r.GR_8_Label__c,
					Grouping__r.GR_9_Label__c,
					Grouping__r.GR_10_Label__c,
					Contextual_Mappings__c,
					Contextual_Mappings__r.CO_1_Label__c,
					Contextual_Mappings__r.CO_2_Label__c,
					Contextual_Mappings__r.CO_3_Label__c,
					Contextual_Mappings__r.CO_4_Label__c,
					Contextual_Mappings__r.CO_5_Label__c,
					Contextual_Mappings__r.CO_6_Label__c,
					Contextual_Mappings__r.CO_7_Label__c,
					Contextual_Mappings__r.CO_8_Label__c,
					Contextual_Mappings__r.CO_9_Label__c,
					Contextual_Mappings__r.CO_10_Label__c,
					Contextual_Mappings__r.CO_11_Label__c,
					Contextual_Mappings__r.CO_12_Label__c,
					Contextual_Mappings__r.CO_13_Label__c,
					Contextual_Mappings__r.CO_14_Label__c,
					Contextual_Mappings__r.CO_15_Label__c
				from Collection_Instance__c 
				where 
					Collection_Instance_Code__c = :collectionInstanceCode
			];

			if(collectionInstances.size()==1){
				private_collectionInstance = collectionInstances.get(0);
			}

			doneCollectionInstanceLookup = true;
		}
		return private_collectionInstance;
	}

	//this is intended to run on before insert trigger
	public static void assignFieldValues(List<Staging_Element__c> stagingElements){
		if(stagingElements!=null && !stagingElements.isEmpty()){
			for(Staging_Element__c stagingElement:stagingElements){
				//Assign Unit of Interest Id
				if(String.isBlank(stagingElement.U_Unit_of_Interest_Id__c) && !String.isBlank(stagingElement.U_DP_ID__c)){
					stagingElement.U_Unit_of_Interest_Id__c = stagingElement.U_DP_ID__c;
				}

				// handle cases where R_Mark_in_Required__c is not provided in sample file
				// but the instrument is provided.  IN this case, set Mark-IN-required to true
				if(String.isNotBlank(stagingElement.A_Instrument_Code__c)){
					stagingElement.R_Mark_In_Required__c = true;
				}
			}
		}
	}

	public static Map<Id, Staging_Element__c> findElementsToProcessImmediately(List<Staging_Element__c> stagingElements){
		Collection_Instance__c collectionInstance = findCollectionInstance(stagingElements.get(0).CI_Collection_Instance_Code__c);
		Map<Id, Staging_Element__c> elementsToProcessImmediately = new Map<Id, Staging_Element__c>();
		for(Staging_Element__c stagingElement:stagingElements){
			if(collectionInstance==null){
				stagingElement.CI_Collection_Instance_Code__c.addError('Please check that collection insance codes are the same for all dataset and collection instance with this code exists in the system.');
			}else if(!collectionInstance.Collection_Instance_Code__c.equals(stagingElement.CI_Collection_Instance_Code__c)){
				stagingElement.CI_Collection_Instance_Code__c.addError('Please check that collection insance codes are the same for all dataset.');
			}else if(PROCESS_IMMIDEATELY_COLLECTION_INSTANCE_RECORD_TYPES.contains(collectionInstance.RecordType.Name)){
				elementsToProcessImmediately.put(stagingElement.Id, stagingElement);
			}
		}
		return elementsToProcessImmediately;
	}

	public static List<Staging_Element__c> findElementsToProcessLater(List<Staging_Element__c> stagingElements){
		Collection_Instance__c collectionInstance = findCollectionInstance(stagingElements.get(0).CI_Collection_Instance_Code__c);
		List<Staging_Element__c> elementsToProcessLater = new List<Staging_Element__c>();
		for(Staging_Element__c stagingElement:stagingElements){
			if(collectionInstance==null){
				stagingElement.CI_Collection_Instance_Code__c.addError('Please check that collection insance codes are the same for all dataset and collection instance with this code exists in the system.');
			}else if(!collectionInstance.Collection_Instance_Code__c.equals(stagingElement.CI_Collection_Instance_Code__c)){
				stagingElement.CI_Collection_Instance_Code__c.addError('Please check that collection insance codes are the same for all dataset.');
			}else if(!PROCESS_IMMIDEATELY_COLLECTION_INSTANCE_RECORD_TYPES.contains(collectionInstance.RecordType.Name)){
				elementsToProcessLater.add(stagingElement);
			}
		}
		return elementsToProcessLater;
	}
	
	public static void processStagingElements(Map<Id, Staging_Element__c> stagingElements){
		if(stagingElements!=null && !stagingElements.isEmpty()){
			Collection_Instance__c collectionInstance = findCollectionInstance(stagingElements.values().get(0).CI_Collection_Instance_Code__c);
			if(collectionInstance!=null){
				// flag to turn off some trigger calculations
				Boolean runCalculations = false;
				StagingElementUtils staginElementUtils = new StagingElementUtils(runCalculations);
				staginElementUtils.processStagingElements(stagingElements, collectionInstance);
			}
		}
	}
}