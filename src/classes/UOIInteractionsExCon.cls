public class UOIInteractionsExCon {
    /*public Unit__c unit{get;set;}
    public List<Unit__c> unitObj{get;set;}
    public Map<String,List<interactionsWrapper>> uoiInteractionsWrapperMap{get;set;}
    
    public UOIInteractionsExCon(ApexPages.StandardController stdCont){
        unit = (Unit__c)stdCont.getRecord();
        uoiInteractionsWrapperMap = new Map<String,List<interactionsWrapper>>();
        unitObj = [Select 	Id,Name,Unit_Number__c,Unit_of_Interest_Description__c,Enterprise__c,Enterprise__r.Name,Enterprise__r.Unit_of_Interest_Description__c,
                   (Select Id,Name,Status__c,Unit_of_Interest__c,Collection_Instance__c,Collection_Instance__r.Name from Responses__r), 
                   (Select Id,Contact__c,Role__c,Unit_of_Interest_ID__c from Contact_Roles__r)
                   from 	Unit__c 
                   where 	Id = :unit.Id or Enterprise__c = :unit.Id or Parent__c = :unit.Id or Group_Top_Enterprise__c = :unit.Id];
        
        List<Id> responseId = new List<Id>();
        List<Id> unitId = new List<Id>();
        List<Id> contactId = new List<Id>();
        Map<Id,Set<Id>> contactMap = new Map<Id,Set<Id>>();
        Map<Id,Contact_Role__c> contactRoleMap = new Map<Id,Contact_Role__c>();
        Map<Id,List<Response__c>> responseMap = new Map<Id,List<Response__c>>();
        for(Unit__c unit: unitObj){
            unitId.add(unit.Id);
            for(Response__c resp: unit.Responses__r){
                responseId.add(resp.Id); 
                if(responseMap.containsKey(resp.Unit_of_Interest__c)){
                    responseMap.get(resp.Unit_of_Interest__c).add(resp);    
                } else {
                    responseMap.put(resp.Unit_of_Interest__c, new List<Response__c>{resp});                    
                }
            }
            
            for(Contact_Role__c cr: unit.Contact_Roles__r){
                contactId.add(cr.Contact__c);
                if(contactMap.containsKey(cr.Unit_of_Interest_ID__c)){
                    contactMap.get(cr.Unit_of_Interest_ID__c).add(cr.Contact__c);
                } else {
                    contactMap.put(cr.Unit_of_Interest_ID__c,new Set<Id>{cr.Contact__c});
                }
                
                contactRoleMap.put(cr.Contact__c,cr);
            }
        }
        
        List<Work_Item__c> workItemList = [Select Id,Name,Contact__c,Contact__r.FirstName,Contact__r.LastName,Response__c,CreatedDate,CreatedById,Related_Case__c,Work_Item_Type__c,Core_Result__c,Outcome__c,Notes__c
                                           from Work_Item__c 
                                           where Response__c in :responseId
                                           and Contact__c in :contactId];
        
        Map<Id,List<Work_Item__c>> workItemMap = new Map<Id,List<Work_Item__c>>();
        Set<Id> caseId = new Set<Id>();
        
        for(Work_Item__c wi: workItemList){
            caseId.add(wi.Related_Case__c);
            if(workItemMap.containsKey(wi.Response__c)){
                workItemMap.get(wi.Response__c).add(wi);    
            } else {
                workItemMap.put(wi.Response__c, new List<Work_Item__c>{wi});                    
            }
        }
        
        Map<Id,Case> caseMap = new Map<Id,Case>([Select Id,caseNumber,Status,Type,Reason,OwnerId,CreatedDate,CreatedById from Case where ContactId in :contactId and Id in :caseId]);
        
        for(Unit__c unit: unitObj){
            List<interactionsWrapper> interactionsList = new List<interactionsWrapper>();
            if(responseMap.containsKey(unit.Id)){
                for(Response__c rs: responseMap.get(unit.Id)){
                    interactionsWrapper inw = new interactionsWrapper();
                    inw.uoiNumber = unit.Name;
                    inw.uoiDescription = unit.Unit_of_Interest_Description__c;
                    inw.enterpriseUoiId = unit.Enterprise__r.Name;
                    inw.enterpriseUoiDescription = unit.Enterprise__r.Unit_of_Interest_Description__c;
                    inw.collectionInstance = rs.Collection_Instance__r.Name;
                    inw.responseNumber = rs.Name;
                    inw.responseStatus = rs.Status__c;
                    if(workItemMap.containsKey(rs.Id)){
                        for(Work_Item__c wi: workItemMap.get(rs.Id)){
                            inw.workItemNumber = wi.Name;
                            inw.workItemCreatedDate = wi.CreatedDate.format();
                            inw.workItemCreatedBy = findUserName(wi.CreatedById);
                            inw.workItemType = wi.Work_Item_Type__c;
                            inw.coreResult = wi.Core_Result__c;
                            inw.outcome = wi.Outcome__c;
                            inw.workItemNotes = wi.Notes__c;
                            if(contactMap.containsKey(unit.Id) && contactMap.get(unit.Id).contains(wi.Contact__c)){
                                inw.contactFullName = wi.Contact__r.FirstName+' '+wi.Contact__r.LastName;
                            }
                            if(contactRoleMap.containsKey(wi.Contact__c)){
                                inw.contactRole = contactRoleMap.get(wi.Contact__c).Role__c;
                            }
                            if(caseMap.containsKey(wi.Related_Case__c)){
                                inw.caseNumber = caseMap.get(wi.Related_Case__c).caseNumber;
                                inw.caseStatus = caseMap.get(wi.Related_Case__c).Status;
                                inw.caseType = caseMap.get(wi.Related_Case__c).Type;
                                inw.caseReason = caseMap.get(wi.Related_Case__c).Reason;
                                inw.caseOwner = findUserName(caseMap.get(wi.Related_Case__c).OwnerId);
                                inw.caseCreatedDate = caseMap.get(wi.Related_Case__c).CreatedDate.format();
                                inw.caseCreatedBy = findUserName(caseMap.get(wi.Related_Case__c).CreatedById);
                            }
                        }
                    }
                    interactionsList.add(inw);
                }
            }
            uoiInteractionsWrapperMap.put(unit.Name,interactionsList);
        }
    }
    
    public String findUserName(Id userId){
        User us = [Select Id,FirstName,LastName from User where Id = :userId];
        return us.FirstName+' '+us.LastName;
    }
    
    public class interactionsWrapper{
        public String collectionInstance{get;set;}
        public String uoiNumber{get;set;}
        public String uoiDescription{get;set;}
        public String enterpriseUoiId{get;set;}
        public String enterpriseUoiDescription{get;set;}
        public String responseNumber{get;set;}
        public String responseStatus{get;set;}
        public String workItemNumber{get;set;}
        public String workItemCreatedDate{get;set;}
        public String workItemCreatedBy{get;set;}
        public String workItemType{get;set;}
        public String deliveryMode{get;set;}
        public String workItemStatus{get;set;}
        public String coreResult{get;set;}
        public String outcome{get;set;}
        public String workItemNotes{get;set;}
        public String contactRole{get;set;}
        public String contactFullName{get;set;}
        public String caseNumber{get;set;}
        public String caseStatus{get;set;}
        public String caseType{get;set;}
        public String caseReason{get;set;}
        public String caseOwner{get;set;}
        public String caseCreatedDate{get;set;}
        public String caseCreatedBy{get;set;}
    }*/
}