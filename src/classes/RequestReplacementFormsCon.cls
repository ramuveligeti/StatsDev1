/**
* @description   This class is called from RequestReplacementForms page to create/modify skillsets for User
* @author        Ram Veligeti
* @date          04.09.2015
*
* @amendment     
* @author        Caterina Cuccurullo
* @date          07.09.2016
* @description   ECP-3527  fetch additional columns from response 
*/
public class RequestReplacementFormsCon {
    private static final List<String> ACTIVE_RESPONSE_STATUSES = new List<String>{
        'Scheduled for Delivery',
        'Ready for Delivery',
        'Delivered',
        'Not Delivered',
        'Loaded',
        'In Progress',
        'Suppressed',
        'Not completed',
        'No response',
        'On hold',
        'Partial'
    };


    private Id contactId;


    public List<SelectOption> ciSelectOptions{get; private set;}
    public String selectedCollectionInstance{get;set;}

    public List<SelectOption> dmSelectOptions{get; private set;}
    public String selectedDeliveryMode{get;set;}
    
    public List<ResponseWrapper> responses{get; set;}
    public List<PackWrapper> packs{get; set;}
	


    public Boolean getHasResponses(){
        return(!responses.isEmpty());
    }

    public Boolean getHasPacks(){
        return(!packs.isEmpty());
    }

    public Boolean getHasActiveCollectionIntance(){
        return(!ciSelectOptions.isEmpty());
    }

    public Boolean getHasSelectedCollectionInstance(){
        return(String.isNotBlank(selectedCollectionInstance));
    }

    public Boolean getHasSelectedDeliveryMode(){
        return(String.isNotBlank(selectedDeliveryMode));
    }

    public Boolean getHasReplaceables(){
        return(getHasResponses() && getHasPacks());
    }




    //Constructor
    public RequestReplacementFormsCon(){
        responses = new List<ResponseWrapper>();
        packs = new List<PackWrapper>();
        ciSelectOptions = new List<SelectOption>();

        String cid = ApexPages.currentPage().getParameters().get('cId');
        if(String.isBlank(cid)){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Contact Id was not provided'));
            return;
        }
        System.debug('cid = '+cid);

        List<Contact> contacts = [select Id from Contact where Id=:cid];
        if(contacts==null || contacts.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Contact was not found for id '+cid));
            return;
        }
        contactId = cid;
        
        List<Collection_Instance__c> collectionInstances = [select Name from Collection_Instance__c
            where
                Id in (select Collection_Instance__c from Response__c where Contact__c = :contactId and Collection_Instance__r.Status__c='Active')
        ];
        System.debug('collectionInstances = '+collectionInstances);
        
        if(collectionInstances==null || collectionInstances.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Contact is not assosiated with Active Collection Instance'));
            return;
        }else{
            ciSelectOptions.add(new SelectOption('','--None--'));
            for(Collection_Instance__c collectionInstance:collectionInstances){
                SelectOption option = new SelectOption(collectionInstance.Id, collectionInstance.Name);
                ciSelectOptions.add(option);
            }
        }
        
    }

    public PageReference onCollectionInstanceChange(){
        selectedDeliveryMode = null;
        dmSelectOptions = new List<SelectOption>();
        packs = new List<PackWrapper>();
        responses = new List<ResponseWrapper>();
        if(getHasSelectedCollectionInstance()){
            fetchDeliveryModes();
            fetchResponses();
        }
        return null;
    }

    public PageReference onDeliveryModeChange(){
    	packs = new List<PackWrapper>();
        if(getHasSelectedCollectionInstance() && getHasSelectedDeliveryMode()){
            fetchPacks();
        }
        return null;
    }

    //fetch delivery modes
    private void fetchDeliveryModes(){
        Collection_Instance__c ci = [select Collection__c from Collection_Instance__c where Id=:selectedCollectionInstance];
        List<Pack__c> sfPacks =[select Delivery_Mode__c from Pack__c where Collection__c=:ci.Collection__c and Replaceable__c=true];
        if(!sfPacks.isEmpty()){
            dmSelectOptions.add(new SelectOption('','--None--'));
            Set<String> usedDeliveryModes = new Set<String>();
            for(Pack__c sfPack:sfPacks){
                if(!usedDeliveryModes.contains(sfPack.Delivery_Mode__c)){
                    SelectOption option = new SelectOption(sfPack.Delivery_Mode__c, sfPack.Delivery_Mode__c);
                    dmSelectOptions.add(option);
                    usedDeliveryModes.add(sfPack.Delivery_Mode__c);
                }
            }
        }
    }

    private void fetchResponses(){
        List<Response__c> sfResponses = [select
                Unit_of_Interest__r.Unit_of_Interest_ID__c ,
                Unit_of_Interest__r.Unit_Name__c,
                Address__c,
				Delivery_Address__c,
                Birth__c,
                Name,
                Survey_Unit_Name__c ,
                Survey_Unit__r.Unit_of_Interest_ID__c                         
              from Response__c 
            where 
                Contact__c = :contactId and
                Collection_Instance__c = :selectedCollectionInstance and
                Status__c in :ACTIVE_RESPONSE_STATUSES
        ];
        System.debug('sfResponses = '+sfResponses);

        if(sfResponses!=null && !sfResponses.isEmpty()){
            for(Response__c sfResponse:sfResponses){
                responses.add(new ResponseWrapper(sfResponse));
            }
        }
    }

    private void fetchPacks(){
        Collection_Instance__c ci = [select Collection__c from Collection_Instance__c where Id=:selectedCollectionInstance];
        List<Pack__c> sfPacks =[select 
                Name, 
                (select Artefact__c, Number_of_Copies__c from Pack_Contents__r where Artefact__r.Status__c='Active') 
            from Pack__c where 
                Collection__c=:ci.Collection__c and 
                Replaceable__c=true and 
                Delivery_Mode__c=:selectedDeliveryMode
        ];
        if(!sfPacks.isEmpty()){
            for(Pack__c p:sfPacks){
                packs.add(new PackWrapper(p));
            }
        } 
    }
    
    //Cancel
    public PageReference cancel(){
        return new PageReference('/'+contactId);
    }

    public PageReference createWorkItems(){
        List<Response__c> selectedResponses = new List<Response__c>();
        List<Pack__c> selectedPacks = new List<Pack__c>();

        for(ResponseWrapper response:responses){
            if(response.sel){
                selectedResponses.add(response.response);
            }
        }

        for(PackWrapper pack:packs){
            if(pack.sel){
                selectedPacks.add(pack.pack);
            }
        }

        if(selectedResponses.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select at least one unit response'));
            return null;
        }

        if(selectedPacks.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Please select at least one pack'));
            return null;
        }

        if(selectedPacks.size()>5){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,'Cannot select more than five packs'));
            return null;
        }

        List<Work_Item__c> workItems = new List<Work_Item__c>();
        for(Response__c response:selectedResponses){
            for(Pack__c pack:selectedPacks){
                //for(Pack_Contents__c item:pack.Pack_Contents__r){
                    Work_Item__c wi = new Work_Item__c();
                    wi.Contact__c = contactId;
                    wi.Pack__c = pack.Id;
                    wi.Response__c = response.Id;
                    wi.Work_Item_Type__c = 'Replacement questionnaire';
                    wi.Delivery_Mode__c = selectedDeliveryMode;
                    //wi.Num_of_requested_forms__c = item.Number_of_Copies__c;
                    wi.Status__c = 'New';
                    workItems.add(wi);
                //}
            }
        }
        if(!workItems.isEmpty()){
            insert workItems;
        }
        return new PageReference('/'+contactId);
    }
    
    public class ResponseWrapper{
        public Boolean sel{get;set;}
        public Response__c response{get;set;}
        public responseWrapper(Response__c r){
            response = r;
            sel = false;
        }
    }
    
    public class PackWrapper{
        public Boolean sel{get;set;}
        public Pack__c pack{get;set;}
        public PackWrapper(Pack__c p){
            pack = p;
            sel = false;
        }
    }
}