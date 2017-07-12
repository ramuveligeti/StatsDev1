trigger Trigger_SetDefaultAddressTypeForShellUnits on Unit__c (before insert, before update) {
    
/*        Set<Id> workloadIds = new Set<Id>();
        Set<string> unitIds = new Set<string>();
        for(Unit__c u : Trigger.New){
            if (u.Shell_Address__c != null){
                unitIds.add(u.Shell_Address__c);
            }
        }
        
        List<Unit__c> parentUnits = [Select Id, Name, Address_Type__c from Unit__c where Name in : unitIds];
        for (Unit__c u : parentUnits) {
            workloadIds.add(u.Workload_ID__c);
        }
        Map<Id, Workload__c> workloadMap = new Map<Id, Workload__c>([Select Default_Address_Type__c From Workload__c Where Id In :workloadIds]);
      
        for (Unit__c u : parentUnits){
            if (u.Address_Type__c == '--Use Workload Default--'){
                for (Unit__c c : Trigger.New){
                    if (c.Shell_Address__c == u.Name && workloadMap.get(u.Id)!= null)
                        c.Workload_ID__c = u.Workload_ID__c;
                        c.Address_Type__c = workloadMap.get(u.Id).Default_Address_Type__c;
                }
            }
        }
  */  

}