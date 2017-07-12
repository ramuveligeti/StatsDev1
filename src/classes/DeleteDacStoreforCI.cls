public class DeleteDacStoreforCI {
//CP-167 Delete records from DAC Store so that we only have unique identifiers, so that records aren't duplicated
//Ad hoc process to delete all records in DAC_STore__c object for a collection Instance.
//This will be used for Census to clean out the DAC Store for a collection instance to avoid the possiblity
//of having duplicate DAC STore ID's
//As this is an AD Hoc process run this class from the Anonymous Window like this ==>  
//DeleteDacStoreforCI delDac = new DeleteDacStoreforCI('ELCENTST01');
//'ELCENTST01' is the collection instance code you want to delete the DAC STore records.
public DeleteDacStoreforCI(string CI){
DAC_Store__c[] DeleteDACRecs = [SELECT Id, Name FROM DAC_Store__c
                                WHERE response__r.collection_instance__r.Collection_Instance_Code__c =: CI];

        try {        
            delete DeleteDACRecs;
        
        } catch (DmlException e) {        
            // Process exception here
            System.debug('Exception error has occurred wil trying to delete DAC Store records'); 
        }
	}
}