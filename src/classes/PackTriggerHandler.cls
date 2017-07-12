/**
* @description   Trigger on Pack object
* @author        Ram Veligeti
* @date          17.04.2015
*/
public class PackTriggerHandler {
    /**
    * @description   To validate if Artefact's Delivery Modes matching with Pack's Delivery mode
    */
    public static void validatePackContentsDeliveryModes(Map<Id,Pack__c> newPackMap, Map<Id,Pack__c> oldPackMap){
        List<Pack__c> packList = new List<Pack__c>();
        for(Pack__c pack: newPackMap.values()){
            if(pack.Delivery_Mode__c != oldPackMap.get(pack.Id).Delivery_Mode__c){
                packList.add(pack);
            }
        }
        
        if(!packList.isEmpty()){
            //Fetch all pack contents of the pack
            List<Pack_Contents__c> packContents = [Select Id,Pack__c,Artefact__c,Artefact__r.Delivery_Modes__c from Pack_Contents__c where Pack__c in :packList];

            for(Pack__c pack: packList){
                for(Pack_Contents__c pc: packContents){
                    //Validate pack delivery mode with Artefact's delivery modes
                    if(pc.Pack__c == pack.Id && !pc.Artefact__r.Delivery_Modes__c.contains(pack.Delivery_Mode__c)){
                        pack.addError('Artefact\'s Delivery Modes must match with Pack\'s Delivery Mode');
                    }
                }
            }
        }
    }
}