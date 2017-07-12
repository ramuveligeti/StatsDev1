/**
* Remark         Steven Zhu 20160908 ECP 3023 update zeacom status and call metric reporting
*/
@isTest
public class CSRActionRecorder_Test {
    @testSetup
    static void setup() {
        TestDataHelper.createDataSet();
        
        SystemSettings__c[] config = new SystemSettings__c[]{
        	new SystemSettings__c(name='zeacom.requestwork.action', value__c='Request Work Item'),
        	new SystemSettings__c(name='zeacom.inprogress.action', value__c='Request Work Item'),
        	new SystemSettings__c(name='zeacom.recordoutcome.action', value__c='Recording Outcome'),
        	new SystemSettings__c(name='zeacom.blocking.action', value__c='After Call Work Time'),
        	new SystemSettings__c(name='zeacom.blocking.duration', value__c='20')
        };
        insert config;
        
    }
    
    static Id getWorkItemId() {
        Work_Item__c workItem = [
            select Id
            from Work_Item__c
            limit 1
        ];
        return workItem.Id;
    }
    
    static Datetime staticTime() {
        return Datetime.newInstance(2016, 1, 1);
    }
    
    static Task mockOutboundPhoneCall() {
        Task outboundCall = new Task(
            subject = 'Mocked outbound phone call',
            activitydate = staticTime().date(),
            calltype = 'Outbound',
            calldurationinseconds = 30,
            wait_time__c = '5',
            status = 'Completed',
            calldisposition = 'Successfully contacted',
            caller_id__c = '+64 (21) 1191103',
            pbx_ref__c = '3696085',
            call_wrapup_1__c = 'RTS',
            OwnerId = UserInfo.getUserId()
        );
        
        return outboundCall;
    }
    
    @isTest
    static void requestWorkItemCreatesCallMetric() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
        
        List<Call_Metric__c> metrics = [
            select Id
            from Call_Metric__c
            where Action__c = 'Request Work Item'
        ];
        
        List<Call_Metric__c> overallDurationMetrics = [
            select Id
            from Call_Metric__c
            where Action__c = 'Overall Duration'
        ];
        
        System.assertEquals(1, metrics.size());

        System.assertEquals(1, overallDurationMetrics.size());
    }

    @isTest
    static void endCallingUpdatesRequestWorkItemCallMetric() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
        
        insert mockOutboundPhoneCall();
        
        List<Call_Metric__c> metrics = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Request Work Item'
        ];
        
        System.assertNotEquals(null, metrics.get(0).End__c);
    }
    
    @isTest
    static void endCallingCreatesCallMetricWithStartDateTime() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
        
        insert mockOutboundPhoneCall();
        
       	Call_Metric__c metric = [
            select Start__c
            from Call_Metric__c
            where Action__c = 'Outbound Call'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.Start__c);
    }
    
    @isTest
    static void endCallingCreatesCallMetricWithEndDateTime() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
        
        insert mockOutboundPhoneCall();
        
       	Call_Metric__c metric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Outbound Call'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.End__c);
    }
    
    @isTest
    static void startRecordingOutcomeCreatesCallMetric() {
        CSRActionRecorder.startRecordingOutcome(getWorkItemId(), staticTime());
        
        Call_Metric__c metric = [
            select Start__c
            from Call_Metric__c
            where Action__c = 'Record Outcome'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.Start__c);
    }
    
    @isTest
    static void finishRecordingOutcomeUpdatesCallMetric() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
		CSRActionRecorder.startRecordingOutcome(getWorkItemId(), staticTime());
        CSRActionRecorder.finishRecordingOutcome(getWorkItemId(), staticTime());
        
        Call_Metric__c metric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Record Outcome'
            limit 1
        ];
        
        Call_Metric__c overallDurationMetric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Overall Duration'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.End__c);
        System.assertNotEquals(null, overallDurationMetric.End__c);
        
    }
    
     @isTest
    static void finishRecordingOutcomeMultiCallMetric() {
        CSRActionRecorder.requestWorkItem(getWorkItemId(), staticTime());
		CSRActionRecorder.startRecordingOutcome(getWorkItemId(), staticTime());
        CSRActionRecorder.finishRecordingOutcome(getWorkItemId(), staticTime());
        
        CSRActionRecorder.finishRecordingOutcome(getWorkItemId(), Datetime.newInstance(2017, 1, 1));
        CSRActionRecorder.finishRecordingOutcome(getWorkItemId(), Datetime.newInstance(2018, 1, 1));
        
        Call_Metric__c metric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Record Outcome'
            limit 1
        ];
        
        Call_Metric__c overallDurationMetric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Overall Duration'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.End__c);
        System.assertNotEquals(null, overallDurationMetric.End__c);
        System.assertEquals(Datetime.newInstance(2018, 1, 1), overallDurationMetric.End__c);    
    }

    @isTest
    static void cancelRecordingOutcomeUpdatesCallMetric() {
		CSRActionRecorder.startRecordingOutcome(getWorkItemId(), staticTime());
        CSRActionRecorder.cancelRecordingOutcome(getWorkItemId(), staticTime());
        
        Call_Metric__c metric = [
            select End__c
            from Call_Metric__c
            where Action__c = 'Record Outcome'
            limit 1
        ];
        
        System.assertNotEquals(null, metric.End__c);
    }

}