/**
* @description   This class is called from RequestReplacementForms page to create/modify skillsets for User
* @author        Ram Veligeti
* @date          04.09.2015
*/
public class RequestReplacementFormsCensusCon {
    public Response__c response{get;set;}
    public List<InstrumentsWrapper> InstrumentsWrapperList{get;set;}
    public List<CollateralWrapper> CollateralWrapperList{get;set;}
    public List<SelectOption> deliveryModes{get;set;}
    public String selectedDeliveryMode{get;set;}
    public List<SelectOption> availablePacks{get;set;}
    public String selectedPack{get;set;}
    public String caseId{get;set;}
    
    //Constructor
    public RequestReplacementFormsCensusCon(ApexPages.StandardController stdCont){
        response = (Response__c)stdCont.getRecord();
        InstrumentsWrapperList = new List<InstrumentsWrapper>();
        CollateralWrapperList = new List<CollateralWrapper>();
        selectedDeliveryMode = NULL;
        
        //Form picklist value for delivery mode
        deliveryModes = ApexUtility.getPicklistValues('Artefact__c', 'Delivery_Modes__c', true);
        system.debug('response.Collection_Instance__r.Collection__c=='+response.Collection_Instance__r.Collection__c);
        //Query packs to form picklist
        List<Pack__c> packs = [Select Id,Name from Pack__c where Collection__c = :response.Collection_Instance__r.Collection__c order by Name];
        availablePacks = new List<SelectOption>();
        availablePacks.add(new SelectOption('','-None-'));
        for(Pack__c pa: packs){
            availablePacks.add(new SelectOption(pa.Id,pa.Name));
        }
        
        //Query artefacts
        List<Artefact__c> artefactList = [Select Id, Name, RecordType.Name from Artefact__c where Collection__c = :response.Collection_Instance__r.Collection__c and Status__c = 'Active'];
        for(Artefact__c ar: artefactList){
            if(ar.RecordType.Name == 'Instrument'){
                InstrumentsWrapperList.add(new InstrumentsWrapper(ar));
            } else if(ar.RecordType.Name == 'Collateral'){
                CollateralWrapperList.add(new CollateralWrapper(ar));
            }
        }
        
        caseId=ApexPages.currentPage().getParameters().get('case');
    }
    
    public PageReference cancel(){
        if(!String.isBlank(caseId)){
            return new PageReference('/'+caseId);
        }
        return new PageReference('/'+response.Id);
    }
    
    //Create work items based on selected instruments and collaterals
    public PageReference createWorkItems(){
        try{
            if(selectedDeliveryMode == NULL){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select delivery mode.'));
                return null;
            }
            
            Map<Id,Integer> artefactMap = new Map<Id,Integer>();
            Map<Id,Work_Item__c> workItemMap = new Map<Id,Work_Item__c>();
            List<Work_Item__c> workItems = new List<Work_Item__c>();
            if(selectedPack != NULL){
                List<Pack_Contents__c> pcList = [Select Id,Artefact__c,pack__c,Number_of_Copies__c from Pack_Contents__c where pack__c = :selectedPack];
                
                for(Pack_Contents__c pc: pcList){
                    Work_Item__c wi = new Work_Item__c();
                    wi.Instrument__c = pc.Artefact__c;
                    wi.Response__c = response.Id;
                    wi.Delivery_Mode__c = selectedDeliveryMode;
                    wi.Work_Item_Type__c = 'Replacement questionnaire';
                    wi.Num_of_requested_forms__c = pc.Number_of_Copies__c;
                    wi.Related_Case__c = caseId;
                    wi.Pack__c = pc.pack__c; //ECP-2340, ECP-2674
                    workItemMap.put(pc.Artefact__c,wi);
                    artefactMap.put((ID)pc.Artefact__c,Integer.valueOf(pc.Number_of_Copies__c));
                }
            }

            for(InstrumentsWrapper iw: InstrumentsWrapperList){
                if(iw.sel){
                    if(iw.copies == NULL || iw.copies <=0){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'No.of Copies on the Instrument must be greater than 0.'));
                        return null;
                    }
                    
                    if(artefactMap.containsKey(iw.instrument.Id)){
                        Integer cnt = artefactMap.get(iw.instrument.Id)+iw.copies;
                        artefactMap.put(iw.instrument.Id,cnt);
                        workItemMap.get(iw.instrument.Id).Num_of_requested_forms__c = artefactMap.get(iw.instrument.Id); //ECP-2340, ECP-2674
                    } else {
                        artefactMap.put((ID)iw.instrument.Id,iw.copies);
                        Work_Item__c wi = new Work_Item__c();
                        wi.Instrument__c = iw.instrument.Id;
                        wi.Response__c = response.Id;
                        wi.Delivery_Mode__c = selectedDeliveryMode;
                        wi.Work_Item_Type__c = 'Replacement questionnaire';
                        wi.Num_of_requested_forms__c =artefactMap.get(iw.instrument.Id);
                        wi.Related_Case__c = caseId;
                        workItemMap.put((ID)iw.instrument.Id,wi);
                    }
                }
            }
            
            for(CollateralWrapper cw: CollateralWrapperList){
                if(cw.sel){
                    if(cw.copies == NULL || cw.copies <=0){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'No.of Copies on the Collateral must be greater than 0.'));
                        return null;
                    }
                    
                    if(artefactMap.containsKey(cw.collateral.Id)){
                        Integer cnt = artefactMap.get(cw.collateral.Id)+cw.copies;
                        artefactMap.put((ID)cw.collateral.Id,cnt);
                        workItemMap.get(cw.collateral.Id).Num_of_requested_forms__c = artefactMap.get(cw.collateral.Id); //ECP-2340
                    } else {
                        artefactMap.put((ID)cw.collateral.Id,cw.copies);
                        Work_Item__c wi = new Work_Item__c();
                        wi.Instrument__c = cw.collateral.Id;
                        wi.Response__c = response.Id;
                        wi.Delivery_Mode__c = selectedDeliveryMode;
                        wi.Work_Item_Type__c = 'Replacement questionnaire';
                        wi.Num_of_requested_forms__c =artefactMap.get(cw.collateral.Id);
                        wi.Related_Case__c = caseId;
                        workItemMap.put(cw.collateral.Id,wi);
                    }
                }
            }
            
            if(!workItemMap.isEmpty()){
                insert workItemMap.values();
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select a Pack or at least one Instrument/Collateral to create Work Items.'));
                return null;
            }
            
            if(!String.isBlank(caseId)){
                return new PageReference('/'+caseId);
            }
            return new PageReference('/'+response.Id);
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Error: '+e.getMessage()));
            return null;
        }
    }
    
    public class InstrumentsWrapper{
        public Boolean sel{get;set;}
        public Artefact__c instrument{get;set;}
        public Integer copies{get;set;}
        public InstrumentsWrapper(Artefact__c i){
            instrument = i;
            copies = 1;
            sel = false;
        }
    }
    
    public class CollateralWrapper{
        public Boolean sel{get;set;}
        public Artefact__c collateral{get;set;}
        public Integer copies{get;set;}
        public CollateralWrapper(Artefact__c c){
            collateral = c;
            copies = 1;
            sel = false;
        }
    }
}