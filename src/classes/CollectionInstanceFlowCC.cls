/**
 * @description   Controller for VF Page CollectionInstanceFlow
 * @author        Ram Veligeti
 * @date          26.Mar.2015
 */
public with sharing class CollectionInstanceFlowCC{
    public Flow.Interview.Setup_Collection_Instance_Flow collectionInstanceFlow{get; set;}
    private Collection__c collection;
    
    public CollectionInstanceFlowCC(ApexPages.StandardController stdController){
        this.collection = (Collection__c)stdController.getRecord();
    }
    
    //Gets Collection Instance Id from flow
    public String getcollectionInstanceId() {
        if(collectionInstanceFlow!=null && collectionInstanceFlow.CreateCollectionInstance!=null) return collectionInstanceFlow.CreateCollectionInstance.Id;
        else return null;
    }
    
    //Used for Flow finish location
    public PageReference getFinishLocation(){
        PageReference p;
        if(getcollectionInstanceId() != NULL){
	        p = new PageReference('/'+getcollectionInstanceId());
        } else {
	        p = new PageReference('/'+collection.Id);
        }
        p.setRedirect(true);
        return p;
    }
}