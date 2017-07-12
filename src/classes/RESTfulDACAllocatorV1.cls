//This resful API is created for the story ECP-2623
//Author - Karthik Gunasekaran
//Created Date - 17/Aug/2016
@RestResource(urlMapping='/RESTfulDACAllocator/1.0/*')
global with sharing class RESTfulDACAllocatorV1 {
@HttpPost
    global static String allocateDAC(String responseID){ 
        List<Response__c> response = new list<Response__c>([select RecordTypeId,document_number__c,access_code__c,Unit_of_Interest__c, unit_of_Interest__r.address_type__c from Response__c 
                                  where Name =: responseID]);         
           if(response.size()>0 ){ 
               //Allocate documentID or Access code for the response
               DAC_Store__c dac = DACAllocator.allocateDAC(response[0], true); 
                   if(dac == null){
                        system.debug(' Failed to allocate DAC and Response ID is '+response[0].Name);
                        return 'Error';
                   }
                   else{
                        return 'Success'; 
                   }
               }
            else{
             return 'No Response Found'; 
            }              
          }
}