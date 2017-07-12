public class DACAllocator {
    static ID censusResponseRT = Schema.SObjectType.Response__c.getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
    
    /** util method to allow allocation of an unalloated DAC store record to the given response
     */
    public static DAC_Store__c allocateDAC(Response__c response, boolean updateResponse) {
        // check if response is a dwelling response under census
        if(response == null || response.recordtypeid != censusResponseRT){return null;}
        
        try {
            //If the address Type of the response being cloned is a NPD then select a row from the DAC Store that
            //has the Is_Non_Private_Dwelling indicator set to true                 
             DAC_Store__c dac = null;
              system.debug('unit of interest address type: '+response.Unit_of_Interest__r.Address_Type__c);
              if (response.Unit_of_Interest__r.Address_Type__c == 'Non-private dwelling') {
                           dac = [select access_code__c, Document_ID__c from DAC_Store__c 
               				where allocation_status__c = 'Unallocated' and Is_Non_Private_Dwelling__c = true
                                            and For_Print__c = false limit 1 for update];  
                }   else {
                      dac = [select access_code__c, Document_ID__c from DAC_Store__c 
               				where allocation_status__c = 'Unallocated' and  Is_Non_Private_Dwelling__c = false
                                          and For_Print__c = false limit 1 for update];  
                }       

			system.debug(logginglevel.Info, dac);
            
            // update the Response with the new dac details
            if (String.isBlank(response.document_number__c)){
                response.document_number__c = dac.Document_ID__c;
            } else {
                response.document_number__c += ',' + dac.Document_ID__c;
            }

            if (String.isBlank(response.access_code__c)){
                response.access_code__c = dac.access_code__c;
            } else {
                response.access_code__c += ',' + dac.access_code__c;
            }
            
            //response.Document_Number_Extract__c = dac.Document_ID__c;
            //response.Access_Code_Extract__c = dac.access_code__c;
            
            if (updateResponse){update response;}
            
            
            return dac;

        } catch (Exception ex){
            system.debug(logginglevel.Error, ex);
        }
        return null;
    }
}