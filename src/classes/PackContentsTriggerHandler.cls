/**
* @description   Trigger on Pack Contents object
* @author        Ram Veligeti
* @date          17.04.2015
*/
public class PackContentsTriggerHandler {
    /**
    * @description   To validate if Artefact's Delivery Modes matching with Pack's Delivery mode
    */
    public static void validateDeliveryModeOfPackContents(List<Pack_Contents__c> newPackContents, Map<Id,Pack_Contents__c> oldPackContentsMap){
        Set<Id> packId = new Set<Id>();
        Set<Id> artefactId = new Set<Id>();
		List<Pack_Contents__c> packContentsList = new List<Pack_Contents__c>();

        for(Pack_Contents__c pc: newPackContents){
            if((!oldPackContentsMap.isEmpty() && pc.Artefact__c != oldPackContentsMap.get(pc.Id).Artefact__c) || (oldPackContentsMap.isEmpty())){
                packId.add(pc.Pack__c);
                artefactId.add(pc.Artefact__c);
                packContentsList.add(pc);
            } 
        }
        
        if(!packId.isEmpty() && !artefactId.isEmpty()){
            //Fetch pack delivery mode
            Map<Id,Pack__c> pack = new Map<Id,Pack__c>([Select Id, Delivery_Mode__c from Pack__c where Id in :packId]);
            //Fetch Artefact delivery modes
            Map<Id,Artefact__c> artefact = new Map<Id,Artefact__c>([Select Id, Delivery_Modes__c from Artefact__c where Id in :artefactId]);
            
            for(Pack_Contents__c pc: packContentsList){
                //Validate
                if(pack.containsKey(pc.Pack__c) && artefact.containsKey(pc.Artefact__c) && String.isNotBlank(pack.get(pc.Pack__c).Delivery_Mode__c) && !artefact.get(pc.Artefact__c).Delivery_Modes__c.contains(pack.get(pc.Pack__c).Delivery_Mode__c)){
                    pc.addError('Artefact\'s Delivery Modes must match with Pack\'s Delivery Mode');
                }
            }
        }
    }
}