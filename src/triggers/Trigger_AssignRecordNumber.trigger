trigger Trigger_AssignRecordNumber on Unit__c (before insert, before update) {

/*    if (trigger.isAfter) {
    }

    if (trigger.isBefore) {

        List<Id> workloadIds = new List<Id>();
        for (Unit__c u : trigger.new) {
            workloadIds.add(u.Workload_ID__c);
        }
        Map<Id, Workload__c> workloadMap = new Map<Id, Workload__c>([Select Default_Address_Type__c From Workload__c Where Id In :workloadIds]);
        
        if (trigger.isInsert) { 
            for (Unit__c u : trigger.new) {
                if (u.Cloned_From_ID__c == u.Address_ID__c) {
                    u.Address_ID__c = u.Address_ID_Generator__c;
                } else {
                    u.Cloned_From_ID__c = u.Address_ID__c;
                }
            }
    
            Unit_Counter__c uc = new Unit_Counter__c();
            Try{
                uc = [SELECT Id, Unit_Record_Counter__c FROM Unit_Counter__c];
            }
            catch(Exception ex)
            {
            }
            
            for(Unit__c u: trigger.new)
            {
                if(u.Address_ID__c == null)
                {
                    u.Address_ID__c = uc.Unit_Record_Counter__c;
                }
            }
            
            //update counter
            Integer ctr = integer.valueOf(uc.Unit_Record_Counter__c);
            uc.Unit_Record_Counter__c = String.valueOf(ctr+1);
            update uc;
        }
        
    Not requried this is covered by the Unit Trigger Handler    
    if (trigger.isInsert || trigger.isUpdate) {
            for (Unit__c u : trigger.new) {
                if (u.Address_Type__c == '--Use Workload Default--') {
                    if (workloadMap.get(u.Workload_ID__c) != null) {
                        u.Address_Type__c = workloadMap.get(u.Workload_ID__c).Default_Address_Type__c;
                    }
                }
            }
        }

    }*/

}