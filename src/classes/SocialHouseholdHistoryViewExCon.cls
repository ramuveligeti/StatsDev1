/*
author: Ram Veligeti
story: ECP-2367
description: to display previous week responses of that quarter on work item. This class is called from SocialHouseholdHistoryView page
*/
public class SocialHouseholdHistoryViewExCon{
    public Work_Item__c workItem{get;set;}
    public Id socialRecordTypeId = Work_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Social').getRecordTypeId();
    public Id DwellingRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Dwelling').getRecordTypeId();
    public Id IndividualRecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Individual').getRecordTypeId();
    public Map<Response__c,List<Response__c>> householdMap{get;set;}
    public List<Response__c> DwellingResps{get;set;}
    public List<Response__c> IndividualResps{get;set;}
    public Map<Id,Response__History> respHistory{get;set;}

    public SocialHouseholdHistoryViewExCon(ApexPages.StandardController stdCont){
        workItem = (Work_Item__c)stdCont.getRecord();
        if(workItem.recordTypeId == socialRecordTypeId && String.isNotBlank(workItem.Unit_Id__c)){
            List<Response__c> resps =  [Select Id,Name,Wave__c,Rotation__c,Status__c,Response_Status_Reason__c,Contact__c,Contact__r.Name,RecordTypeId,Unit_of_Interest__c,
                                               Contact__r.Phone,Contact__r.Email,Contact__r.Gender__c,Contact__r.Birthdate,
                                               (Select ParentId,OldValue,NewValue,CreatedDate,CreatedById from Histories where Field = 'Status__c' order by CreatedDate desc limit 1)
                                          from Response__c 
                                         where Unit_of_Interest__c = :workItem.Unit_Id__c
                                           and Rotation__c < :workItem.Response__r.Rotation__c
                                           and Collection_Instance__r.Collection__c = :workItem.Collection__c
                                         order by Rotation__c,Unit_of_Interest__c,Record_Type_Name__c];

            householdMap = new Map<Response__c,List<Response__c>>();
            DwellingResps = new List<Response__c>();
            IndividualResps = new List<Response__c>();
            respHistory = new Map<Id,Response__History>();
            for(Response__c rs: resps){
                system.debug('rs.RecordTypeId=='+rs.RecordTypeId+'=='+DwellingRecordTypeId+'=='+IndividualRecordTypeId);
                if(rs.RecordTypeId == DwellingRecordTypeId){
                    DwellingResps.add(rs);
                }else if(rs.RecordTypeId == IndividualRecordTypeId){
                    IndividualResps.add(rs);
                }
                respHistory.put(rs.Id,new Response__History());
                for(Response__History rh: rs.Histories){
                    system.debug('rh.parentId=='+rh);
                    respHistory.put(rh.parentId,rh);
                }
            }
            system.debug('DwellingResps=='+DwellingResps+'=='+IndividualResps);
            for(Response__c dr: DwellingResps){
                householdMap.put(dr,new List<Response__c>());
                for(Response__c ir: IndividualResps){
                    if(dr.Unit_of_Interest__c == ir.Unit_of_Interest__c && dr.Rotation__c == ir.Rotation__c){
                        if(householdMap.containsKey(dr)){householdMap.get(dr).add(ir);}
                    }
                }
            }
            system.debug('householdMap=='+householdMap);
        }
    }
}