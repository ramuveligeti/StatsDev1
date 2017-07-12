/*
* Created by - Steven Zhu 19 October 2016
* User Story - ECP - 3642
*              Create a URL string which links to an MEP SSRS report.
*/
/* Updated  - ECP- 3861 Caterina Cuccurullo 21 April 2017
 *            New Report new URL string.
 */
@isTest  
private class OpenQBASReportController_Test { 

	@testSetup static void setupData(){
			Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'QBAS Link Test';
            col.Collection_Code__c = 'QBAS Link Test';
            insert col;
		
			Collection__c colOth = TestDataHelper.createCollection(false);
            colOth.Name = 'AOS Link Test';
            colOth.Collection_Code__c = 'AOS Link Test';
            insert colOth;

            Collection_Instance__c colInsMar = TestDataHelper.createCollectionInstance(col.Id,false);
			colInsMar.Name = 'QBAS March 2055';
			colInsMar.Collection_Instance_Code__c = 'QBAS March 2055';
			colInsMar.Reference_Period__c = '205503';
			Collection_Instance__c colInsSep = TestDataHelper.createCollectionInstance(col.Id,false);
			
			colInsSep.Collection_Instance_Code__c = 'QBAS September 2055';
			colInsSep.Name = 'QBAS September 2055';
			colInsSep.Reference_Period__c = '205509';
			Collection_Instance__c colInsJun = TestDataHelper.createCollectionInstance(col.Id,false);
			colInsJun.Collection_Instance_Code__c = 'QBAS June 2055';
			colInsJun.Name = 'QBAS June 2055';
			colInsJun.Reference_Period__c = '205506';

			Collection_Instance__c colInsDec = TestDataHelper.createCollectionInstance(col.Id,false);
			colInsDec.Name = 'QBAS December 2055';
			colInsDec.Collection_Instance_Code__c = 'QBAS December 2055';
			colInsDec.Reference_Period__c = '205512';
			Collection_Instance__c colInsOth = TestDataHelper.createCollectionInstance(colOth.Id,false);
			colInsOth.Collection_Instance_Code__c = 'AOS 2055';
			colInsOth.Name = 'AOS 2055';
			colInsOth.Reference_Period__c = '205501';

			insert colInsMar;
			insert colInsSep;
			insert colInsJun;
			insert colInsDec;
			insert colInsOth;

			Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='1001-01166';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;

            Response__c respMar = TestDataHelper.createResponse(colInsMar.Id, cnt.Id, null, unitObj.Id, true);
			Response__c respSept = TestDataHelper.createResponse(colInsSep.Id, cnt.Id, null, unitObj.Id, true);
			Response__c respJun = TestDataHelper.createResponse(colInsJun.Id, cnt.Id, null, unitObj.Id, true);
			Response__c respDec = TestDataHelper.createResponse(colInsDec.Id, cnt.Id, null, unitObj.Id, true);
			Response__c respOth = TestDataHelper.createResponse(colInsOth.Id, cnt.Id, null, unitObj.Id, true);
            
			Work_Item__c wiMar = TestDataHelper.createWorkItem(null, null, NULL, respMar.Id, null, false);
			wiMar.Work_Item_ExtId__c = 'testMar';
			insert wiMar;

			Work_Item__c wiSep = TestDataHelper.createWorkItem(null, null, NULL, respSept.Id, null, false);
			wiSep.Work_Item_ExtId__c = 'testSep';
			insert wiSep;
			Work_Item__c wiJun = TestDataHelper.createWorkItem(null, null, NULL, respJun.Id, null, false);
			wiJun.Work_Item_ExtId__c = 'testJun';
			insert wiJun;
			Work_Item__c wiDec = TestDataHelper.createWorkItem(null, null, NULL, respDec.Id, null, false);
			wiDec.Work_Item_ExtId__c = 'testDec';
			insert wiDec;
			Work_Item__c wiOth = TestDataHelper.createWorkItem(null, null, NULL, respOth.Id, null, false);
            wiOth.Work_Item_ExtId__c = 'testOth';
			insert wiOth;
            insert new SystemSettings__c(name ='QBASReport.link', value__c='http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fBESt%2fBuilding+Activity%2fBuilding+Activity+Reference+Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list={0}&ci_code_start={1}');
                                         
		
	}

	@isTest
	private static void TestReportControllerQBAS()
	{
		 Work_Item__c wiMar = [select Id, name, Collection__c,Collection_Instance_Code__c,Collection_Instance__c,Collection_Instance_Name__c,response__r.Collection_Code__c,Unit__c from Work_Item__c
		 where Collection_Instance_Code__c = 'QBAS March 2055' limit 1];
		 Work_Item__c wiJun = [select Id, name, Collection__c,Collection_Instance_Code__c,Collection_Instance__c,Collection_Instance_Name__c,response__r.Collection_Code__c,Unit__c from Work_Item__c
		 where Collection_Instance_Code__c = 'QBAS June 2055' limit 1];
		 Work_Item__c wiSep = [select Id, name, Collection__c,Collection_Instance_Code__c,Collection_Instance__c,Collection_Instance_Name__c,response__r.Collection_Code__c,Unit__c from Work_Item__c
		 where Collection_Instance_Code__c = 'QBAS September 2055' limit 1];
		 Work_Item__c wiDec = [select Id, name, Collection__c,Collection_Instance_Code__c,Collection_Instance__c,Collection_Instance_Name__c,response__r.Collection_Code__c,Unit__c from Work_Item__c
		 where Collection_Instance_Code__c = 'QBAS December 2055' limit 1];
        
		 ApexPages.StandardController stdControllerMar = new ApexPages.StandardController(wiMar);
         OpenQBASReportController oqrcMar = new OpenQBASReportController(stdControllerMar);

		 System.debug('oqrcMar=='+oqrcMar.urlString);
		// system.assertEquals(oqrcMar.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fbest%2fBuilding+Activity%2fBuilding%20Activity%20Contact%20Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q1');
         system.assertEquals(oqrcMar.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fBESt%2fBuilding+Activity%2fBuilding+Activity+Reference+Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q1');

		 ApexPages.StandardController stdControllerJune = new ApexPages.StandardController(wiJun);
         OpenQBASReportController oqrcJun = new OpenQBASReportController(stdControllerJune);

		// system.assertEquals(oqrcJun.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fbest%2fBuilding+Activity%2fBuilding%20Activity%20Contact%20Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q2');
         system.assertEquals(oqrcJun.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fBESt%2fBuilding+Activity%2fBuilding+Activity+Reference+Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q2');		
       
             ApexPages.StandardController stdControllerSep = new ApexPages.StandardController(wiSep);
         OpenQBASReportController oqrcSep = new OpenQBASReportController(stdControllerSep);

		// system.assertEquals(oqrcSep.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fbest%2fBuilding+Activity%2fBuilding%20Activity%20Contact%20Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q3');
          system.assertEquals(oqrcSep.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fBESt%2fBuilding+Activity%2fBuilding+Activity+Reference+Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q3');		
		
        ApexPages.StandardController stdControllerDec = new ApexPages.StandardController(wiDec);
         OpenQBASReportController oqrcDec= new OpenQBASReportController(stdControllerDec);

	//	 system.assertEquals(oqrcDec.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fbest%2fBuilding+Activity%2fBuilding%20Activity%20Contact%20Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q4');
         system.assertEquals(oqrcDec.urlString, 'http://snz-best-prd-ssrs/ReportServer/Pages/ReportViewer.aspx?%2fBESt%2fBuilding+Activity%2fBuilding+Activity+Reference+Details&rs%3aCommand=Render&rc:Parameters=Collapsed@i_code=QBAS_Contact&unit_list=1001-01166&ci_code_start=QBAS Contact 2055 Q4');		
	}

	@isTest
	private static void TestReportControllerOther()
	{
		 Work_Item__c wiOth = [select Id, name, Collection__c,Collection_Instance_Code__c,Collection_Instance__c,response__r.Collection_Code__c,Unit__c from Work_Item__c
		 where Collection_Instance_Code__c = 'AOS 2055' limit 1];

		 ApexPages.StandardController stdControllerOth = new ApexPages.StandardController(wiOth);
         OpenQBASReportController oqrcOth = new OpenQBASReportController(stdControllerOth);

		 system.assertEquals(oqrcOth.urlString, '');

	}

}