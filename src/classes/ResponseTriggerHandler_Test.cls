@isTest
private class ResponseTriggerHandler_Test {
    @testSetup static void setupData(){
        TestDataHelper.createWrapupCodes();
        TestDataHelper.createResponseProperties();

         System_Update__c config = System_Update__c.getInstance();
         config.Debug_Enabled__c = true;
         upsert config;
    }

    @isTest static void completeWorkItemsTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            // cannot use DF, logic moved to response summary status
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Canvassing').getRecordTypeId();
            resp.Status__c = 'No Response';
			insert resp;
            
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<200 ;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
                wi.Work_Item_ExtId__c = 'test'+i;
                wi.Delivery_Mode__c = 'Reminder'+i;
                wi.Status__c = 'New';
                wiList.add(wi);
            }
            
            insert wiList;
            test.startTest();
            resp.status__c = 'Completed';
            update resp;
            test.stopTest();
            List<Work_Item__c> w = [Select Id from Work_Item__c where Status__c = 'Completed'];
            system.assertEquals(200, w.size());
        }
    }
    
    @isTest static void updateContactTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            Contact_Role__c cr = TestDataHelper.createContactRole(col.Id, unitObj.Id, cnt.Id, false);
            cr.Primary_Contact__c = true;
            insert cr;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
            resp.Status__c = 'No Response';
            test.startTest();
			insert resp;
            test.stopTest();
            
            Response__c rs = [Select Id, Contact__c from Response__c];
            //system.assertEquals(cnt.Id, rs.Contact__c);
        }
    }

    /*@isTest static void reallocateWorkItem(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Test';
            col.Collection_Code__c = 'Test';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
			Workload__c workload = TestDataHelper.createWorkLoad(colIns.id,true);
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.Status__c = 'No Response';
            resp.Workload__c = workload.id;
			insert resp;
            
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<200 ;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
                wi.Work_Item_ExtId__c = 'test'+i;
                wi.Delivery_Mode__c = 'Reminder'+i;
                wi.Work_Item_Type__c = 'Email'+i;
				wi.Status__c = (Math.mod(i,2)==0)?'New':'Completed';
                wi.workload__c = workload.id;
                wiList.add(wi);
            }
            
            insert wiList;
            
			Workload__c workload2 = TestDataHelper.createWorkLoad(colIns.id,true);
            test.startTest();
            resp.workload__c = workload2.id;
            update resp;
            test.stopTest();
            for(Work_Item__c wi: [Select Id, workload__c,status__c from Work_Item__c] ){
            	if(wi.status__c=='Completed'){
            		system.assertEquals(workload2.id, wi.workload__c);
            	} else {
            		system.assertEquals(workload2.id, wi.workload__c);
            	}
            }
        }
    }

    @isTest static void reallocateWorkItemAndOwner(){
    	User[]users=new User[]{
        	TestDataHelper.createUser( 'Test0' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test1' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test2' + datetime.now().getTime()+'@gmail.com','System Administrator',false)
    	};
    	insert users;
        system.runAs(users[0]){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Test';
            col.Collection_Code__c = 'Test';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
			Workload__c workload = TestDataHelper.createWorkLoad(colIns.id,false);
			workload.ownerid=users[1].id;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.Status__c = 'No Response';
            resp.Workload__c = workload.id;
			insert resp;
            
            List<Work_Item__c> wiList = new List<Work_Item__c>();
            for(integer i=0;i<200 ;i++){
                Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
                wi.Work_Item_ExtId__c = 'test'+i;
                wi.Delivery_Mode__c = 'Reminder'+i;
                wi.Work_Item_Type__c = 'Email'+i;
				wi.Status__c = (Math.mod(i,2)==0)?'New':'Completed';
                wi.workload__c = workload.id;
                wi.ownerId =users[1].id;
                wiList.add(wi);
            }
            
            insert wiList;
            
			Workload__c workload2 = TestDataHelper.createWorkLoad(colIns.id,false);
			workload2.ownerId=users[2].id;
			insert workload2;
            test.startTest();
            resp.workload__c = workload2.id;
            update resp;
            test.stopTest();
            for(Work_Item__c wi: [Select Id, workload__c,status__c,ownerid from Work_Item__c] ){
            	if(wi.status__c=='Completed'){
            		system.assertEquals(workload2.id, wi.workload__c);
            		system.assertEquals(users[2].id, wi.ownerid);
            	} else {
            		system.assertEquals(workload2.id, wi.workload__c);
            		system.assertEquals(users[2].id, wi.ownerid);
            	}
            }
        }
    }*/


    @isTest 
    static void markIn_reverse_test(){
    	User[]users=new User[]{
        	TestDataHelper.createUser( 'Test0' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test1' + datetime.now().getTime()+'@gmail.com','System Administrator',false),
        	TestDataHelper.createUser( 'Test2' + datetime.now().getTime()+'@gmail.com','System Administrator',false)
    	};
    	insert users;
        system.runAs(users[0]){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Test';
            col.Collection_Code__c = 'Test';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ENXXX';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
			Workload__c workload = TestDataHelper.createWorkLoad(colIns.id,false);
			workload.ownerid=users[1].id;
            Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            resp.Status__c = 'No Response';
            resp.Response_Status_Reason__c='WTF';
            resp.previous_status_reason__c=null;
            resp.Previous_Status__c=null;
            //resp.Workload__c = workload.id;
            resp.Mark_In__c=false;
			insert resp;
            
            
            Test.startTest();
            system.assertEquals(null, resp.Previous_Status__c);
            resp.Mark_In__c = true;
            update resp;
            
            Response__c vR=[select id, status__c, previous_status__c,previous_status_reason__c from Response__c where id=:resp.id];
            system.assertEquals('no response', vR.previous_status__c.toLowercase());
            system.assertEquals('WTF', vR.previous_status_reason__c);
            system.assertEquals('Completed', vR.status__c);

            vR.Mark_In__c = false;
            update vR;
			vR=[select id, status__c, previous_status__c from Response__c where id=:resp.id];
            system.assertEquals('no response', vR.status__c.toLowercase());
            Test.stopTest();
            
        }
    }

    @isTest static void updateDwellingResponses_InsertTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
            insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            // this is the primary resp
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = dfID;
            resp.Status__c = 'Completed';
            resp.Number_of_Occupants__c=5;
			resp.Response_ExtId__c = 'EricTestERICABC';
			            
            Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp1.RecordTypeId = dfID;
            resp1.Status__c = 'No Response';
            insert new Response__c[]{resp,resp1};

            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<20;i++){
                Response__c res = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                res.RecordTypeId = ifID;
                res.Status__c = (Math.mod(i,2)==0)?'No Response':'Completed';
                res.Mark_In__c=Math.mod(i,2)!=0;
                respList.add(res);
            }
            
            test.startTest();
            ResponseTriggerHandler.Executed=false;
            insert respList;
            test.stopTest();
			Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Paper_Dwelling_Forms__c,Number_of_Paper_Individual_Forms__c,
				Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(10, vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals(0,vResp.Number_of_Paper_Dwelling_Forms__c);
            system.assertEquals('Completed', vResp.Response_Summary_Status__c);// we have more IF than expected
        }
    }
    
    @isTest static void assignRecordType_beforeInsertTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
            colIns.Target_Response_Type__c = 'Census';
	        insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            List<Response__c> respList = new List<Response__c>();
            // this is the primary resp
            Response__c resp = new Response__c();
            resp.Collection_Instance__c = colIns.Id;
            resp.Contact__c = cnt.Id;
            resp.Unit_of_Interest__c = unitObj.Id;
            resp.Status__c = 'Completed';
            resp.Number_of_Occupants__c=5;
			resp.Response_ExtId__c = 'RamuTestERICABC';
			resp.Mobile_Device_Id__c = 'mobId42';
            respList.add(resp);
            test.startTest();
            insert respList;
            test.stopTest();
            Response__c rr = [Select Id,recordtypeId from Response__c where Response_ExtId__c = 'RamuTestERICABC'];
            system.assertEquals(dfId, rr.recordtypeId);
        }
    }

    @isTest static void updateDwellingResponses_UpdateTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
	        insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            // this is the primary resp
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = dfID;
            resp.Status__c = 'Completed';
			resp.Response_ExtId__c = 'EricTestERICABC';
			// note, no number of occupants
			            
            Response__c resp1 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp1.RecordTypeId = dfID;
            resp1.Status__c = 'No Response';

            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<20;i++){
                Response__c res = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                res.RecordTypeId = ifID;
                res.Status__c = (Math.mod(i,2)==0)?'No Response':'Completed';
                res.Mark_In__c=Math.mod(i,2)!=0;
                respList.add(res);
            }
            respList.add(resp);
            respList.add(resp1);
            insert respList;
            system.assertEquals('Completed',respList[1].status__c);
            system.assertEquals('No Response',respList[0].status__c);
            system.assertEquals('No Response',respList[2].status__c);
            system.assertEquals('No Response',respList[4].status__c);
            
            test.startTest();
            // make sure we can run the trigger again for this test
            ResponseTriggerHandler.Executed=false;
            // let's chagne some responses to completed
            Response__c[]updList=new Response__c[]{respList[0],respList[2],respList[4]};
            respList[0].Mark_In__c=true;
            respList[2].Mark_In__c=true;
            respList[4].Mark_In__c=true;
            respList[0].Response_Mode__c='Paper';
            respList[2].Response_Mode__c='Post';
            respList[4].Response_Mode__c='Paper';
            update updList;
            test.stopTest();
            
			Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Paper_Dwelling_Forms__c,Number_of_Paper_Individual_Forms__c,
				Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(13, vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(3, vResp.Number_of_Paper_Individual_Forms__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals(0,vResp.Number_of_Paper_Dwelling_Forms__c);
            system.assertEquals('Partial - DF', vResp.Response_Summary_Status__c); // due to no occupant number

        }
    }
    
    @isTest static void updateDwellingResponses_delTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
	        insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            // this is the primary resp
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = dfID;
            resp.Status__c = 'Completed';
			resp.Response_ExtId__c = 'EricTestERICABC';
			resp.Response_Mode__c = 'Post';
            resp.Number_of_Occupants__c=5;
            insert resp;
			            
            ResponseTriggerHandler.Executed=false;
            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<5;i++){
                Response__c res = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                res.RecordTypeId = ifID;
                res.Status__c = 'Completed';
                res.Previous_Status__c='No Response';
                res.Mark_In__c=true;
                res.Response_Mode__c='Paper';
                respList.add(res);
            }
            insert respList;
            
            ResponseTriggerHandler.Executed=false;
			Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Paper_Dwelling_Forms__c,Number_of_Paper_Individual_Forms__c,
				Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(5, vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals(5, vResp.Number_of_Paper_Individual_Forms__c);
            system.assertEquals(1,vResp.Number_of_Paper_Dwelling_Forms__c);
            system.assertEquals('Completed', vResp.Response_Summary_Status__c);

            test.startTest();
            // make sure we can run the trigger again for this test
            ResponseTriggerHandler.Executed=false;
            // let's chagne some responses to completed
            Response__c[]dellist=new Response__c[]{respList[0],respList[2],respList[4]};
            delete dellist;
            test.stopTest();
            
			vResp = [select Id,Response_Summary_Status__c,Number_of_Paper_Dwelling_Forms__c,Number_of_Paper_Individual_Forms__c,
				Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(2, vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals(2, vResp.Number_of_Paper_Individual_Forms__c);
            system.assertEquals(1,vResp.Number_of_Paper_Dwelling_Forms__c);
            system.assertEquals('Partial - DF', vResp.Response_Summary_Status__c);

        }
    }

    @isTest static void updateDwellingResponses_UnMarkInTest(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
	        insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            // this is the primary resp
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = dfID;
            resp.Status__c = 'Completed';
			resp.Response_ExtId__c = 'EricTestERICABC';
            resp.Number_of_Occupants__c=5;
            insert resp;
			
			ResponseTriggerHandler.Executed=false;
            List<Response__c> respList = new List<Response__c>();
            for(integer i=0;i<5;i++){
                Response__c res = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
                res.RecordTypeId = ifID;
                res.Status__c = 'Completed';
                res.Previous_Status__c='No Response';
                res.Mark_In__c=true;
                respList.add(res);
            }
            insert respList;
            
			Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(5, vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals('Completed', vResp.Response_Summary_Status__c);

            test.startTest();
            // make sure we can run the trigger again for this test
            ResponseTriggerHandler.Executed=false;
            // let's chagne some responses to completed
            Response__c[]updList=new Response__c[]{respList[0],respList[2],respList[4]};
            respList[0].Mark_In__c=false;
            respList[2].Mark_In__c=false;
            respList[4].Mark_In__c=false;
            update updList;
            test.stopTest();
            
			vResp = [select Id,Response_Summary_Status__c,Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
            system.assertEquals(2,vResp.Number_of_Individual_Forms_Received__c);
            system.assertEquals(1,vResp.Number_of_Dwelling_Forms_Received__c);
            system.assertEquals('Partial - DF', vResp.Response_Summary_Status__c);

        }
    }

    @isTest static void updateDocId_Test(){
            DAC_Store__c[]dacs=new DAC_Store__c[]{
            	new DAC_Store__c(document_id__c='1111', access_code__c='XXX1'),
            	new DAC_Store__c(document_id__c='2222', access_code__c='XXX2'),
            	new DAC_Store__c(document_id__c='3333', access_code__c='XXX3'),
            	new DAC_Store__c(document_id__c='4444', access_code__c='XXX4'),
            	new DAC_Store__c(document_id__c='5555', access_code__c='XXX5'),
            	new DAC_Store__c(document_id__c='9999', access_code__c='XXX9'),
            	new DAC_Store__c(document_id__c='8888', access_code__c='YYY8'),
            	new DAC_Store__c(document_id__c='8881', access_code__c='YYY1'),
            	new DAC_Store__c(document_id__c='8882', access_code__c='YYY2')
            };
            insert dacs;


			ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
			ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
            Collection__c col = TestDataHelper.createCollection(false);
            col.Name = 'Census';
            col.Collection_Code__c = 'Census';
            insert col;
            Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
	        colIns.Collection_Instance_Code__c='EricTest';
	        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
	        insert colIns;
            Contact cnt = TestDataHelper.createContact(true);
            Unit__c unitObj = TestDataHelper.createUnit(false);
            unitObj.Unit_of_Interest_ID__c ='ERICABC';
            unitObj.Address_Type__c = '--Use Workload Default--';
            unitObj.Other_Address_Type__c = null;
            unitObj.Rural_Delivery_Number__c = null;
            unitObj.Postcode__c = '123';
            unitObj.P_O_Box__c = null;
            insert unitObj;
            // this is the primary resp
            Response__c resp = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp.RecordTypeId = dfID;
            resp.Status__c = 'No Response';
			resp.Response_ExtId__c = 'EricTestERICABC';
			resp.access_code__c='ABC';
			resp.document_number__c='123';
            Response__c resp2 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp2.RecordTypeId = dfID;
            resp2.Status__c = 'No Response';
            Response__c resp3 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp3.RecordTypeId = dfID;
            resp3.Status__c = 'No Response';
			resp3.Response_ExtId__c = 'EricTestERICXYZ';
			resp3.access_code__c=null;
			resp3.document_number__c=null;
            Response__c resp4 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp4.RecordTypeId = dfID;
            resp4.Status__c = 'No Response';
			resp4.Response_ExtId__c = 'EricTestERICERIC';
			resp4.access_code__c=null;
			resp4.document_number__c=null;

            Response__c resp5 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp5.RecordTypeId = dfID;
            resp5.Status__c = 'No Response';
			resp5.Response_ExtId__c = 'EricTestERICINS1';
			resp5.access_code__c=null;
			resp5.document_number__c='8881';

            Response__c resp6 = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
            resp6.RecordTypeId = dfID;
            resp6.Status__c = 'No Response';
			resp6.Response_ExtId__c = 'EricTestERICINS2';
			resp6.access_code__c='whatever';
			resp6.document_number__c='8882';
			        
            insert new Response__c[]{resp,resp2,resp3,resp4,resp5,resp6};           
            
			Response__c vResp = [select Id,Document_Number__c,Access_Code__c from Response__c where ID=:resp.id];

            
            // let's chagne some responses
            resp.document_number__c='8888,1111,2222';            
            resp2.document_number__c='9999';
            resp3.document_number__c='3333';
            resp4.document_number__c='4444,5555';
            update new Response__c[]{resp,resp2,resp3,resp4};
                        
            // resp2 is not a primary response, do nothing
			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp2.id];
			system.assertEquals('XXX9',vResp.Access_Code__c);
            
            // resp has an existing doc/acc-code, appending multiple
			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp.id];
			system.assertEquals('YYY8,XXX1,XXX2',vResp.Access_Code__c);
			system.assertEquals('8888,1111,2222',vResp.Document_Number__c);

			// resp3 has no existing doc/acc-code, adding new one do nothing
			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp3.id];
			system.assertEquals('XXX3',vResp.Access_Code__c);
			system.assertEquals('3333',vResp.Document_Number__c);

			// resp4 has no exisitng, and got multiple ids, append additional ids
			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp4.id];
			system.assertEquals('XXX4,XXX5',vResp.Access_Code__c);
			system.assertEquals('4444,5555',vResp.Document_Number__c);
			

			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp5.id];
			system.assertEquals('YYY1',vResp.Access_Code__c);
			system.assertEquals('8881',vResp.Document_Number__c);

			vResp = [select Document_Number__c,Access_Code__c from Response__c where ID=:resp6.id];
			system.assertEquals('YYY2',vResp.Access_Code__c);//no changes from insert
			system.assertEquals('8882',vResp.Document_Number__c); 


			DAC_Store__c[] vDac = [select Document_id__c,Response__c from DAC_Store__c where id in :dacs];
			System.debug('vDac = '+vDac);
			// same order
			system.assertEquals('1111', vDac[0].Document_id__c);
			system.assertEquals(resp.Id, vDac[0].Response__c);

			system.assertEquals('2222', vDac[1].Document_id__c);
			system.assertEquals(resp.Id, vDac[1].Response__c);

			system.assertEquals('3333', vDac[2].Document_id__c);
			system.assertEquals(resp3.Id, vDac[2].Response__c);
			
			system.assertEquals('4444', vDac[3].Document_id__c);
			system.assertEquals(resp4.Id, vDac[3].Response__c);
			
			system.assertEquals('5555', vDac[4].Document_id__c);
			system.assertEquals(resp4.Id, vDac[4].Response__c);
			
			system.assertEquals('9999', vDac[5].Document_id__c);
			system.assertEquals(resp2.Id, vDac[5].Response__c);
			
			system.assertEquals('8888', vDac[6].Document_id__c);
			system.assertEquals(resp.Id, vDac[6].Response__c);
			
			system.assertEquals('8881', vDac[7].Document_id__c);
			system.assertEquals(resp5.Id, vDac[7].Response__c);
			
			system.assertEquals('8882', vDac[8].Document_id__c);
			system.assertEquals(resp6.Id, vDac[8].Response__c);
    }

	static testmethod void testCopyResponseFieldsFromOriginResponse(){
		Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id, true);
	    Unit__c unitObj = TestDataHelper.createUnit(true);
	    Contact cnt = TestDataHelper.createContact(true);
	    
	    Response__c parentResponse = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
	    parentResponse.Wave__c = 'TestWave';
	    insert parentResponse;
	    
	    Response__c response = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
	    response.Created_From_Response_Id__c = parentResponse.Id;
	    
	    List<Response__c> responses = new List<Response__c>();
		responses.add(response);
		
		ResponseTriggerHandler.copyResponseFieldsFromOriginResponse(responses);
		
		System.assertEquals('TestWave', response.Wave__c);
	}

	static testmethod void testCreateResponseFromOriginResponse(){
		Collection__c col = TestDataHelper.createCollection(true);
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id, true);
	    Unit__c unitObj = TestDataHelper.createUnit(true);
	    Contact cnt = TestDataHelper.createContact(true);
	    
	    Response__c parentResponse = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
	    parentResponse.Response_ExtId__c = '1';
	    parentResponse.Wave__c = 'TestWave';
	    insert parentResponse;
	    
	    Response__c response = TestDataHelper.createResponse(colIns.Id, cnt.Id, null, unitObj.Id, false);
	    response.Response_ExtId__c = '2';
	    response.Created_From_Response_Id__c = parentResponse.Id;
	    insert response;
	    
	    Response__c testResponse = [select Wave__c from Response__c where Id = :response.Id];
		
		System.assertEquals('TestWave', testResponse.Wave__c);
	}
	
// ECP-3575 tests
	@isTest
	static private void testPartial_InCompleteWorkItems(){
		ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'Census';
        col.Collection_Code__c = 'Census';
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ERICABC';
        unitObj.Address_Type__c = '--Use Workload Default--';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
        // this is the primary resp
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = dfID;
        resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTestERICABC';
        resp.Number_of_Occupants__c=5;
        insert resp;
        
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Work_Item_ExtId__c = 'test'+system.now().getTime();
        wi.Delivery_Mode__c = 'Post';
        wi.Status__c = 'New';
        wi.Work_Item_Type__c = 'Non-response follow-up'; // using Non-response follow-up causes flow error
        insert wi;
		            
		Test.startTest();
 		// rerun logic
 		ResponseTriggerHandler.Executed = false;
        List<Response__c> respList = new List<Response__c>();
        for(integer i=0;i<4;i++){
            Response__c res = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            res.RecordTypeId = ifID;
            res.Status__c = 'Completed';
            res.Mark_In__c=true;
            respList.add(res);
        }
        insert respList;
        Test.stopTest();
        
		Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
        system.assertEquals(4, vResp.Number_of_Individual_Forms_Received__c);
        system.assertEquals(0, vResp.Number_of_Dwelling_Forms_Received__c);
        system.assertEquals('Partial - DF', vResp.Response_Summary_Status__c);
        
        Work_Item__c vWI = [select status__c from Work_Item__c where response__c = :resp.id];
        system.assertEquals('New', vWI.status__c);
	}

	@isTest
	static private void testComplete_CompleteWorkItems(){
		ID dfID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
		ID ifID=Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Individual').getRecordTypeId();
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'Census';
        col.Collection_Code__c = 'Census';
        insert col;
        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;
        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ERICABC';
        unitObj.Address_Type__c = '--Use Workload Default--';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;
        // this is the primary resp
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = dfID;
        resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTestERICABC';
        resp.Number_of_Occupants__c=5;
        insert resp;
        
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Work_Item_ExtId__c = 'test'+system.now().getTime();
        wi.Delivery_Mode__c = 'Post';
        wi.Status__c = 'New';
        wi.Work_Item_Type__c = 'Refusal'; // using Non-response follow-up causes flow error
        insert wi;
		            
		Test.startTest();
 		// rerun logic for DF mark-in
 		ResponseTriggerHandler.Executed = false;
        resp.mark_in__c = true;
        update resp;
        // rerun logic for IF creation, this is the same as Mark-in logic, as update happens on the after-trigger under Mark-in-request.  Then future on each batch on create IF
 		ResponseTriggerHandler.Executed = false;
        List<Response__c> respList = new List<Response__c>();
        for(integer i=0;i<5;i++){
            Response__c res = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
            res.RecordTypeId = ifID;
            res.Status__c = 'Completed';
            res.Mark_In__c=true;
            respList.add(res);
        }
        upsert respList;
        Test.stopTest();
        
		Response__c vResp = [select Id,Response_Summary_Status__c,Number_of_Individual_Forms_Received__c,Number_of_Dwelling_Forms_Received__c from Response__c where ID=:resp.id];
        system.assertEquals(5, vResp.Number_of_Individual_Forms_Received__c);
        system.assertEquals(1, vResp.Number_of_Dwelling_Forms_Received__c);
        system.assertEquals('Completed', vResp.Response_Summary_Status__c);
        
        Work_Item__c vWI = [select status__c from Work_Item__c where response__c = :resp.id];
        system.assertEquals('Completed', vWI.status__c);
	}

	@isTest
	static private void testCompleteWorkitemsForUnitStatus(){
        Collection__c col = TestDataHelper.createCollection(false);
        col.Name = 'Census';
        col.Collection_Code__c = 'Census';
        insert col;

        Collection_Instance__c colIns = TestDataHelper.createCollectionInstance(col.Id,false);
        colIns.Collection_Instance_Code__c='EricTest';
        colIns.recordtypeid = Schema.SObjectType.Collection_Instance__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert colIns;

        Unit__c unitObj = TestDataHelper.createUnit(false);
        unitObj.Unit_of_Interest_ID__c ='ERICABC';
        unitObj.Address_Type__c = '--Use Workload Default--';
        unitObj.Other_Address_Type__c = null;
        unitObj.Rural_Delivery_Number__c = null;
        unitObj.Postcode__c = '123';
        unitObj.P_O_Box__c = null;
        insert unitObj;

        // this is the primary resp
        Response__c resp = TestDataHelper.createResponse(colIns.Id, null, null, unitObj.Id, false);
        resp.RecordTypeId = Response__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Census Dwelling').getRecordTypeId();
        resp.Status__c = 'No Response';
		resp.Response_ExtId__c = 'EricTestERICABC';
        resp.Number_of_Occupants__c=5;
        resp.Workflow_Status__c = 'Test';
        insert resp;
        
        Work_Item__c wi = TestDataHelper.createWorkItem(null, null, NULL, resp.Id, null, false);
        wi.Work_Item_ExtId__c = 'test'+system.now().getTime();
        wi.Delivery_Mode__c = 'Post';
        wi.Status__c = 'New';
        wi.Work_Item_Type__c = 'Non-response follow-up';
        wi.RecordTypeId = Schema.SObjectType.Work_Item__c.getRecordTypeInfosByName().get('Census').getRecordTypeId();
        insert wi;
		            
		Test.startTest();
        resp.Workflow_Status__c = 'Refused';
        update resp;
        Test.stopTest();
        
		Work_Item__c workitem_test = [select Status__c from Work_Item__c where Id = :wi.Id];
        system.assertEquals('Completed', workitem_test.Status__c);
	}
	
}