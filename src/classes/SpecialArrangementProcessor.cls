/** this class handles the special arrangement logic.  At this stage, I am planning to use the chain-processor engine.
 *  
 * this class can be invoked via:
 *  - a manual button - likely be visualforce button
 *  - a scheduled task (or a future job) - after the fileloading
 *
 *  assumption, 
 *   - file loading has completed
 *   - this is a one-off processing that apply to all the responses under the C.I.
 *   - this is a one-way processing logic.  That is, once the rule has been applied, it's doesn't go back and reverse it even the rule change
 *   - all active rules (at the time of running) will be applied
 *   - we don't have to do it as batch, we are dealing with "very small amount" of rules, e.g. Less than 1000
 *  remark: szhu 20161208 changes made for bug 3651 and 3773
*/
public class SpecialArrangementProcessor {
	
	private static Map<String,integer>months=new Map<String,integer>{
		'january'=>1,'february'=>2,'march'=>3,'april'=>4,'may'=>5,'june'=>6,
		'july'=>7,'august'=>8,'september'=>9,'october'=>10,'november'=>11,'december'=>12
	};
	private Collection_Instance__c ci{set;get;}
	public boolean processed{private set;get;}
	public boolean validated{private set;get;}
	public String errorMsg{private set;get;}
	private Map<Id,Error>combinedErrors{private set;get;}
    
	
	// this is the automated job constructor
	// collectionINstanceCode:  collection_instance__c.collection_instance_code__c
	public SpecialArrangementProcessor(String collectionINstanceCode){
		List<Collection_Instance__C> colInstances = [select id, Name, Collection_Period__c, Reference_Period__c, Return_Date__c, Planned_start_date__c, Collection__c, Extension_Cut_off_Date__c from Collection_Instance__c where Collection_Instance_Code__c =:collectionINstanceCode];
        
        if(colInstances != null && colInstances.size()>0) 
            ci=colInstances[0];
        
		processed=false;
	}
	
	// this is the visualforce constructor
	public SpecialArrangementProcessor(ApexPages.StandardController ctr){
		ci = (Collection_Instance__c)ctr.getRecord();
	}
	
	
	private Special_Arrangement__c[]activeSAs=null;
	// this metbod is used for the visualforce button at page-load
	public void init(){
        validated = ci.return_date__c!=null&&String.isNotBlank(ci.Reference_Period__c);
		if(!validated){
			errorMsg='Missing data under Collection Instance to process special arrangement, please check: Reference Period, and Return Date';
			return;
		}
		/*
		validated=ci.planned_start_date__c>system.today();
		if(!validated){
			errorMsg='You cannot process special arrangements, collection has already started';
			return;
		}
		*/
        ID CCSId = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Cross Collection Suppression').getRecordTypeId();
		combinedErrors=new Map<Id,Error>();
        
        activeSAs=[select recordtypeid,recordtype.Name,Survey_Unit__c,Name,
                Month_1__c,Month_2__c,Month_3__c,Month_4__c,Month_5__c,Month_6__c,
                Month_7__c,Month_8__c,Month_9__c,Month_10__c,Month_11__c,Month_12__c,
                Consolidated_Unit__c, Unit__c,Extension_Period_Days__c,Suppression_Type__c,
                Collection_Mode__c, Collection_Mode_Description__c, Unit_Delivery_Mode__c, Instrument_Name__c, Instrument_Code__c,
                Contact__c, Contact__r.Company_name__c, Contact__r.Box_Bag_Number__c,
                Contact__r.Building_Level_Unit__c, Contact__r.Building_Name__c, 
                Contact__r.Country__c, Contact__r.Delivery_Service_Type__c,
                Contact__r.Level_Number__c, Contact__r.Mail_Town__c, 
                Contact__r.Postcode__c, Contact__r.Road_Direction__c, Contact__r.Road_Name__c,
                Contact__r.Road_Number__c, Contact__r.Road_Number_Alpha__c, 
                Contact__r.Road_Type__c, Contact__r.Rural_Delivery_Number__c, 
                Contact__r.Suburb__c, Contact__r.Street_Road_PO_Box__c, 
                Contact__r.Suburb_Rural_Delivery__c, Contact__r.Town_or_City__c, Contact__r.Has_Address__c,
				Contact__r.Unit_Type__c //added this field as part of 3831 by Ramu Veligeti (Fronde)
                From Special_Arrangement__c 
                where (Collection__c = :ci.collection__c and Status__c = 'Active') OR (Status__c = 'Active' and recordTypeId = :CCSId )
                order by recordtypeid
                limit 1000
                ];
       
	}

	// this is a visualforce button to kick off the processing
	public void startProcessing(){
		if(!validated){return;}
        SpecialArrangementHandler[] handlers = New SpecialArrangementHandler[]{
			new ExtensionSAP(ci),
			new ConsolidationSAP(ci),
			new PeriodicCollectionSAP(ci),
			new SuppressionSAP(ci),
			new MultipleQuestionnaireSAP(ci),
			new InstrumentContactSAP(ci),
                new CrossCollectionSuppSAP(ci)};
    
        
		for(SpecialArrangementHandler h: handlers){
			Map<Id,Error>errors=h.apply(activeSAs);
			combinedErrors.putAll(errors);
		}
        
		processed=true;
	}
		
	public PageReference returnToCollectionInstance(){
		return new PageReference('/'+ci.id);
	}
	
	// this method is cater for automation, and unit tests
	public void autoProcessing(){
		init();
		startProcessing();
	}
		
	public boolean getHasError(){
		return !combinedErrors.isEmpty();
	}
	
	public Error[]getErrors(){
		return combinedErrors.values();
	}

	// SAP - Special Arrangement Processor
	public abstract class SpecialArrangementHandler{
		protected Collection_Instance__c ci{set;get;}
		protected Id recordtypeId{set;get;}
		protected integer collectionMonth{set;get;}
        protected Boolean crossCollectionSuppression = false;
		protected BusinessHours bizHrs = [SELECT Id FROM BusinessHours WHERE IsDefault=true];//never failed, SF force to set one as default
		
		public SpecialArrangementHandler(Collection_Instance__c ci){
 				this.ci=ci;
            
			String x= String.isBlank(ci.Reference_Period__c)?'':ci.Reference_Period__c.trim().mid(4,2);
			if(String.isNotBlank(x)&&x.isNumeric()){
				collectionMonth=Integer.valueOf(x);
			}else{
				collectionMonth=0;
			}
			system.debug(logginglevel.Info, 'collection month: '+collectionMonth);
            
		}
		
		public Map<Id,Error> apply(Special_Arrangement__c[]colSAs){			
			Set<Id>ids=new Set<Id>();
			Special_Arrangement__c[]sas=new Special_Arrangement__c[]{};
            
			// loop through all special-arrangement on the Collection, and only apply those handled by this processor
			for(Special_Arrangement__c sa:colSAs){
                //cross collection suppression using collection unit not survey unit
                if(crossCollectionSuppression)
                {
                    system.debug(logginglevel.Info, 'cross collection suppression ');
                    if(sa.recordtypeid==recordtypeid && sa.Unit__c !=null){
                        ids.add(sa.Unit__c);
                        sas.add(sa);
                    }
                }else 
                {
					if(sa.recordtypeid==recordtypeid && sa.Survey_Unit__c!=null){
						ids.add(sa.Survey_Unit__c);
						sas.add(sa);
					}
                }  
			}
                        
			Map<Id,set<Response__c>>resps=new Map<Id,set<Response__c>>();
            //If cross collection suppression we need to get all responses which has the collection unit being the SA rule unit
			if(crossCollectionSuppression)
            {
                for(Response__c r: [select id, Name, survey_unit__c, Unit_of_Interest__c, status__c, response_status_reason__c, instrument__c,Extension_Past_Cut_Off__c from Response__c 
                    where collection_instance__c = :ci.id and (Unit_of_Interest__c in :ids or survey_unit__c in :ids) ]){
                        
                    set<Response__c>temp=resps.get(r.Unit_of_Interest__c);
                    if(temp==null){temp=new set<Response__c>{};}
                    if(!temp.contains(r)){temp.add(r);}
                    resps.put(r.Unit_of_Interest__c,temp);
                        
                    set<Response__c>tempSU=resps.get(r.survey_unit__c);
                    if(tempSU==null){tempSU=new set<Response__c>{};}
                    if(!tempSU.contains(r)){tempSU.add(r);}
                    resps.put(r.survey_unit__c,tempSU); 
                        
                 }
             }else
             {
                 //also for every other SA rule, need to get responses which has the survey unit being the SA rule unit
                 for(Response__c r: [select id, Name, survey_unit__c, Unit_of_Interest__c, status__c, response_status_reason__c, instrument__c,Extension_Past_Cut_Off__c from Response__c 
                        where survey_unit__c in :ids and collection_instance__c = :ci.id]){
                        set<Response__c>temp=resps.get(r.survey_unit__c);
                        if(temp==null){temp=new set<Response__c>{};}
                        if(!temp.contains(r)){temp.add(r);}
                        resps.put(r.survey_unit__c,temp); 
                  }
             }
            
                
			Map<Id,Response__c>updateSAResp=new Map<Id,Response__c>();
			
			if(crossCollectionSuppression) //cross collection suppression checking on collection unit not survey unit of SA rule
            {
                for(Special_Arrangement__c sa:sas){
					if(resps.get(sa.Unit__c)==null){continue;}
					for(Response__c r: resps.get(sa.Unit__c)){
						system.debug(logginglevel.Info, 'Applying SA: '+sa);
						system.debug(logginglevel.Info, 'On Resp: '+r);
						if(r!=null && apply(sa,r)){
							r.special_arrangement__c=sa.id;
							r.special_arrangement__r=sa;
							updateSAResp.put(r.id,r);
						}
					}
            	}
            }else
            {
                for(Special_Arrangement__c sa:sas){
					if(resps.get(sa.Survey_unit__c)==null){continue;}
					for(Response__c r: resps.get(sa.Survey_Unit__c)){
						system.debug(logginglevel.Info, 'Applying SA: '+sa);
						system.debug(logginglevel.Info, 'On Resp: '+r);
						if(r!=null && apply(sa,r)){
							r.special_arrangement__c=sa.id;
							r.special_arrangement__r=sa;
							updateSAResp.put(r.id,r);
						}
					}
                }
            }
            system.debug(logginglevel.Info, 'responses updated #: '+updateSAResp.values().size());
            Map<Id,Error>errors=new Map<Id,Error>();
			if(!updateSAResp.isEmpty()){
				Response__c[]temp=updateSAResp.values();
				// put in the override control to by-pass validation rules
				System_Update__c su = System_Update__c.getOrgDefaults();
	            su.Execute__c = true;
	            update su;
				Database.SaveResult[] res=Database.update(temp,false);// allow partial commits
				// reset the by-pass
	            su.Execute__c = false;
	            update su;
				for(integer i=0; i<temp.size();i++){
					Database.SaveResult sr=res[i];
					Response__c r=temp[i];
					if (!sr.isSuccess()) {
						for(Database.Error err:sr.getErrors()) {
							errors.put(r.id, new Error(r.id, r.Name, err.getMessage(), r.special_arrangement__c, r.special_arrangement__r.name));// only the last error
                            system.debug(logginglevel.Info, 'error updating response: '+err.getMessage());
						
                        }
					}
				}			
			}
			return errors;
		}
		
		protected Date nextBusinessDay(Date inputDate){
			if(inputDate==null){return null;}
			// local timezone Datetime
			DateTime tempDT = DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
			if(BusinessHours.isWithin(bizHrs.id, tempDT)){ return inputDate;}
			Datetime nextStart = BusinessHours.nextStartDate(bizHrs.id, tempDT);
			return nextStart.Date();//local timezone
		}
		
		public abstract boolean apply(Special_Arrangement__c sa,Response__c r);
	}

	public class ExtensionSAP extends SpecialArrangementHandler {
		public ExtensionSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Extension').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			if(collectionMonth==0){return false;}
			if((boolean)sa.get('Month_'+collectionMonth+'__c')){
				String x = sa.Extension_Period_Days__c;
				x=(String.isNotBlank(x)&&x.isNumericSpace())?x.trim():'0';
				r.extension_date__c = nextBusinessDay(ci.return_date__c + Integer.valueof(x));
				// check if the r.extension_date__c is a business day
				// since this is a date field, have to turn it into a date-time for business-hours check

				//szhu 20161208 added this for bug 3651 and 3773
				if(r.Extension_Date__c > ci.Extension_Cut_off_Date__c && !r.Extension_Past_Cut_Off__c )
				{
					r.Extension_Past_Cut_Off__c = true;
					System.debug('updated past cut off flag');
				}
				return true;
			}
			return false;
		}
	}
	
	public class ConsolidationSAP extends SpecialArrangementHandler {
		public ConsolidationSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Consolidation').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			// this is period based
			r.status__c='Suppressed';
			r.response_status_reason__c='Consolidated Collection';
			return true;
		}
	}

	public class PeriodicCollectionSAP extends SpecialArrangementHandler {
		public PeriodicCollectionSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Periodic Collection').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			if(collectionMonth==0){return false;}
			// this is month based
			if((boolean)sa.get('Month_'+collectionMonth+'__c')){
				r.status__c='Suppressed';
				r.response_status_reason__c='Periodic Collection';
				return true;
			}
			return false;
		}
	}

	public class SuppressionSAP extends SpecialArrangementHandler {
		public SuppressionSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Suppression').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			// this is period based
			r.status__c='Suppressed';
			r.response_status_reason__c=sa.Suppression_Type__c + ' Exclusion';
			return true;
		}
	}
    
    public class CrossCollectionSuppSAP extends SpecialArrangementHandler {
        public CrossCollectionSuppSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Cross Collection Suppression').getRecordTypeId();
            crossCollectionSuppression = true;
		}
        
        public override boolean apply(Special_Arrangement__c sa,Response__c r){
			// this is period based
			r.status__c='Suppressed';
			r.response_status_reason__c=sa.Suppression_Type__c + ' Exclusion';
			return true;
		}   
    }

	public class InstrumentContactSAP extends SpecialArrangementHandler {
		public InstrumentContactSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Instrument Assignment').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			// this is period based
			if(r.instrument__c == sa.instrument_name__c){
				system.debug('sa.Contact__c=='+sa.Contact__c);
				r.Contact__c=sa.Contact__c;
				ResponseUtil.setResponseDetailsFromContact(r, sa.Contact__r, null);// will not set care-of
				return true;
			}
			return false;
		}
	}

	public class MultipleQuestionnaireSAP extends SpecialArrangementHandler {
		public MultipleQuestionnaireSAP(Collection_Instance__c ci){
			super(ci);
			recordtypeid = Schema.SObjectType.Special_Arrangement__c.getRecordTypeInfosByName().get('Multiple Questionnaires').getRecordTypeId();
		}
		public override boolean apply(Special_Arrangement__c sa,Response__c r){
			if(String.isNotBlank(sa.Unit_Delivery_Mode__c)&&sa.Unit_Delivery_Mode__c!='--None--'){
				r.Unit_Delivery_Mode__c=sa.Unit_Delivery_Mode__c;
			}
			if(String.isNotBlank(sa.collection_mode__c)&&sa.collection_mode__c!='--None--'){
				r.Collection_Mode__c=sa.collection_mode__c;
			}
			/*
			if(sa.contact__c!=null){
				r.contact__c=sa.contact__c;
			}
			*/
			return true;
		}
	}

	public class Error {
		public String recordName{set;get;}
		public String recordId{set;get;}
		public String ruleName{set;get;}
		public String ruleId{set;get;}
		public String errorMessage{set;get;}
		
		public Error(String rid, String name, String msg, String ruleId, String ruleName){
			this.recordId=rid;
			this.recordName=name;
			this.errorMessage=msg;
			this.ruleId=ruleId;
			this.ruleName=ruleName;
		}
		
	}

}