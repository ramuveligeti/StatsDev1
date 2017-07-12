public class ContactRoleEditorController {

	private Contact_Role__c record{set;get;}
	private Map<Id,Unit>displayUnitMap{private set;get;}
	public Unit[]displayUnits{private set;get;}
	public boolean processed{private set;get;}
	public boolean activeCR{private set;get;}
	public ContactRoleEditorController(ApexPages.StandardController std){
		record = (Contact_Role__c)std.getRecord();
		activeCR=record.status__c=='Active';
		if(!activeCR){
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Contact role is not active, you cannot make any changes'));
			return;
		}
		// build the display list
		// 1. pick up all the unit from collection instance
		// based on the contact role, assume that is connected to the collection-unit
		set<id>surveyUnitIds=new Set<Id>();
		// go through all collection-instances.... will be relying on the cleanup of old data
		for(Response__c r: [select survey_unit__c from Response__c 
			where Collection_Instance__r.collection__c=:record.collection__c
			and Unit_of_Interest__c=:record.Unit_of_Interest_ID__c]){
			if(r.survey_unit__c!=null){
				surveyUnitIds.add(r.survey_unit__c);
			}
		}

		// assume we have less than 1000 of units for this collection-unit
		displayUnitMap = new Map<Id,Unit>();
		for(Unit__c u: [select id, name, Address__c, Unit_of_Interest_ID__c from Unit__c where id in:surveyUnitIds]){
			displayUnitMap.put(u.id, new Unit(u));
		}
		
		// 2. for those which have already selected, mark it with the tick
		for(Contact_Role_Unit__c cu: [select Survey_Unit_Link__r.id, Survey_Unit_Link__r.Name, 
			Survey_Unit_Link__r.Address__c, Survey_Unit_Link__r.Unit_of_Interest_ID__c
			from Contact_Role_Unit__c where contact_role__c=:record.id]){
			
			if(displayUnitMap.containsKey(cu.Survey_Unit_Link__c)){
				displayUnitMap.get(cu.Survey_Unit_Link__c).selected=true;
			}else{
				displayUnitMap.put(cu.Survey_Unit_Link__c, new Unit(true, cu.Survey_Unit_Link__r));
			}
		}
		displayUnits = displayUnitMap.values();	
	}
	
	public PageReference save(){
		// go with simple approach
		// empty the list,
		// create new list
		delete [select id from contact_role_unit__c where contact_role__c = :record.id];
		Contact_Role_Unit__c[]newList=new Contact_Role_Unit__c[]{};
		for(Unit u: displayUnits){
			if(u.selected){
				newList.add(new Contact_Role_Unit__c(Contact_Role__c=record.id,Survey_Unit_Link__c=u.record.id));
			}
		}
		insert newList;
		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'Changes have been saved successfully.'));
		processed=true;
		return null;//take user back to the same screen
	}
	
	public PageReference cancel(){
		return new PageReference('/'+record.id);
	}
	
	public class Unit{
		public boolean selected{set;get;}
		public Unit__c record{set;get;}
		public Unit(Unit__c r){
			selected=false;
			record=r;
		}
		public Unit(boolean s, Unit__c r){
			selected=s;
			record=r;
		}
	}

}