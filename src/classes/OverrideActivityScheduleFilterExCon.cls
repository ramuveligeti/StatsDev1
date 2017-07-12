public class OverrideActivityScheduleFilterExCon {
    public Activity_Schedule_Filter__c asf;
    public OverrideActivityScheduleFilterExCon(ApexPages.StandardController stdCont){
        asf = (Activity_Schedule_Filter__c)stdCont.getRecord();
    }
    
    public PageReference getRedirect(){
        system.debug('asf.Id=='+asf.Id+'==='+asf.Collection__c);
        PageReference pr; 
        if(asf.Id != NULL && asf.Collection__c != NULL){
            pr = new PageReference('/apex/ActivityScheduleFilters?action=edit&id='+asf.Id);
            return pr.setRedirect(true);
        }else if(asf.Id == NULL){
            Map<String, String> UrlParameterMap = ApexPages.currentPage().getParameters();
            String param;
            for(String k: UrlParameterMap.keySet()){
                if(param == null){param = k+'='+UrlParameterMap.get(k);}
                else {param += '&'+k+'='+UrlParameterMap.get(k);}
            }
        	pr = new PageReference('/apex/ActivityScheduleFilters?action=new&'+param);
            return pr.setRedirect(true);
        } else return null;
    }
}