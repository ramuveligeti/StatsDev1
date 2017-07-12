public class CollectionResponseRateCustomSettingCtrl {

	private static Map<String,Grouping_Settings__c>configs=Grouping_Settings__c.getAll();
	private static Map<String,SObjectField> responseObjFieldMap=Response__c.sObjectType.getDescribe().fields.getMap();
	private Grouping_Settings__c sysConfig{get;set;}
	private String collectionCode{get;set;}
	private ID collectionId{get;set;}

	public Grouping_Settings__c collectionConfig{get;set;}
	public FieldSelection[]availableFields{get;set;}

	public CollectionResponseRateCustomSettingCtrl(ApexPages.StandardController std){
		// first of all, get the collection-code from parameter
		Collection__c rec=(Collection__c)std.getRecord();
		collectionCode=rec.Collection_Code__c;
		collectionId=std.getId();
		sysConfig=configs.get('ECP_SYSTEM');//hard coded the name, should be part of deployment
		if(sysConfig==null){
			sysConfig=new Grouping_Settings__c(Standard_Fields__c='');
		}else if(String.isBlank(sysConfig.Standard_Fields__c)){
			sysConfig.Standard_Fields__c='';
		}
		collectionConfig=configs.get(collectionCode);
		if(collectionConfig==null){
			collectionConfig=new Grouping_Settings__c(Name=collectionCode,Standard_Fields__c='');
		}else if(String.isBlank(collectionConfig.Standard_Fields__c)){
			collectionConfig.Standard_Fields__c='';
		}
		availableFields=new FieldSelection[]{};
		for(String s: sysConfig.Standard_Fields__c.split(',')){
			if(String.isNotBlank(s)){
				String l=responseObjFieldMap.get(s).getDescribe().getLabel();
				boolean b=collectionConfig.Standard_Fields__c.contains(s);
				availableFields.add(new FieldSelection(s,l,b));
			}
		}
	}
	
	
	public PageReference save(){
		String s='';
		// no need to check null, nothing is null
		for(FieldSelection f:availableFields){
			if(f.selected){
				s+=(String.isBlank(s))?'':',';
				s+=f.apiName;
			}
		}
		collectionConfig.Standard_Fields__c=s;
		if(collectionConfig.id!=null){
			update collectionConfig;
		}else{
			insert collectionConfig;
		}
		return cancel();
	}
	
	public PageReference cancel(){
		return new PageReference('/'+collectionId);
	}

	public class FieldSelection{
		public boolean selected{set;get;}
		public String label{set;get;}
		public String apiName{set;get;}
		public FieldSelection(String a,String l,boolean b){
			apiName=a;
			label=l;
			selected=b;
		}
	}
}