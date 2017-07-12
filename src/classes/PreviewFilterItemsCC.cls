public class PreviewFilterItemsCC {
    /*Set<String> originalvalues = new Set<String>();
    Public List<string> leftselected{get;set;}
    Public List<string> rightselected{get;set;}
    Set<string> leftvalues = new Set<string>();
    Set<string> rightvalues = new Set<string>();
    public PreviewFilterItemsCC(){
        leftselected = new List<String>();
        rightselected = new List<String>();
        List<Response__c> rspList = new List<Response__c>();
        String filter = ApexPages.currentPage().getParameters().get('filter');
        Id ciId = (Id)ApexPages.currentPage().getParameters().get('Id');
        system.debug('ciId=='+ciId);
        if(filter=='Wave'){
            rspList = [Select Id,Wave__c,Meshblock_Code__c from Response__c where Wave__c != null and Collection_Instance__c = :ciId];
        } else {
            rspList = [Select Id,Meshblock_Code__c,Wave__c from Response__c where Meshblock_Code__c != null and Collection_Instance__c = :ciId];
        }
        for(Response__c rs: rspList){
            if(rs.Wave__c!=null) leftvalues.add(String.valueOf(rs.Wave__c));
            else leftvalues.add(rs.Meshblock_Code__c);
        }
    }
    
    public PageReference selectclick(){
        rightselected.clear();
        for(String s : leftselected){
            leftvalues.remove(s);
            rightvalues.add(s);
        }
        return null;
    }
     
    public PageReference unselectclick(){
        leftselected.clear();
        for(String s : rightselected){
            rightvalues.remove(s);
            leftvalues.add(s);
        }
        return null;
    }
 
    public List<SelectOption> getunSelectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvalues);
        tempList.sort();
        for(string s : tempList)
            options.add(new SelectOption(s,s));
        return options;
    }
 
    public List<SelectOption> getSelectedValues(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        tempList.sort();
        for(String s : tempList)
            options1.add(new SelectOption(s,s));
        return options1;
    }*/
}