/*
* Created by - Steven Zhu 19 October 2016
* User Story - ECP - 3642
*              Create a URL string which links to an MEP SSRS report.
*              This is called from a Visual Force Page OpenQBASReport.
*              The static part of the url is in System Settings under QBASReport.link
*              Because our Collection Instance code is not exactly the same as MEP 
*              the last two parameter for the link are reformatted, e.g Sep to Q3 .
*/

public class OpenQBASReportController
{ 
	public Work_Item__c workItem{get;set;}

	public Boolean display{get;Set;}

	public String urlString {get;Set;}

	 public OpenQBASReportController(ApexPages.StandardController stdCont){
        workItem = (Work_Item__c)stdCont.getRecord();
		string cCode = workItem.Response__r.Collection_Code__c;
	//	System.debug('OpenQBASReportController.collection=='+cCode );
		if(!cCode.contains('QBAS'))
		{
			urlString='';
			display = false;
		}else
		{
			display = true;
			String ciCode = workItem.Collection_Instance_Code__c;
			String ciName = workItem.Collection_Instance_Name__c;
			String unitId = workItem.Unit__c;

	//	    System.debug('OpenQBASReportController.ciCode=='+ciCode +' cciName=='+ciName+ ' unitId=='+ unitId);
			String QBASMEPReportLink = SystemSettings.getValue('QBASReport.link');
			String ciCodeMEP = 'QBAS Contact';
			
			String surveyYear = ciCode.substring(ciCode.length()-4);
	//		system.debug('OpenQBASReportController.surveyYear=='+surveyYear); 
			ciCodeMEP += ' ' + surveyYear;
			if(ciCode.contains('Mar') || ciName.contains('Mar'))
			{
				ciCodeMEP += ' Q1';
			}else if(ciCode.contains('Jun') || ciName.contains('Jun'))
			{
				ciCodeMEP += ' Q2';
			}	
			else if(ciCode.contains('Sep') || ciName.contains('Sep'))
			{
				ciCodeMEP += ' Q3';
			}
			else
			{
				ciCodeMEP += ' Q4';
			}

			QBASMEPReportLink = QBASMEPReportLink.replace('{0}',unitID);
			QBASMEPReportLink = QBASMEPReportLink.replace('{1}',ciCodeMEP);

			urlString = QBASMEPReportLink;

			System.debug('urlString=='+urlString);
		}
    }



}