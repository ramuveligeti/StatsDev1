/**
* Remark         Steven Zhu 20160908 ECP 3023 update zeacom status and call metric reporting
*/
public class CSRActionRecorder {
    
    public static Map<String,SystemSettings__c> systemSettings = SystemSettings__c.getAll();
    public static Map<String,String> defaultZeacomActions = new Map<String,String>{
        'zeacom.requestwork.action' => 'Request Work Item',
        'zeacom.inprogress.action' => 'Request Work Item',
        'zeacom.recordoutcome.action' => 'Recording Outcome',
        'zeacom.blocking.action' => 'After Call Work Time',
        'zeacom.blocking.duration' => '20'
    };
    
    static final String REQUEST_WORK_ITEM =  'Request Work Item';
    static final String IN_PROGRESS = 'In Progress';
    static final String RECORD_OUTCOME = 'Record Outcome';
    static final String OVERALL_DURATION = 'Overall Duration';
    static final String OUTBOUND_CALL = 'Outbound Call';
    
    public static void requestWorkItem(Id workItem, DateTime dt) {
        requestWorkItem(workItem, dt, false);
    }
    
    public static void requestWorkItem(Id workItem, DateTime dt, boolean inlineCallout) {
        
        // based on requirements, we only set the zeacom status, and call metric, if and only if we don't have anything outstanding under the user
        Id csr = UserInfo.getUserId();
        List<Call_Metric__c> outstandingActionsOnCSR = [
            select CSR__c, End__c, Work_Item__c
            from Call_Metric__c
            where CSR__c = :csr
            and End__c = null
        ];
        
        if(outstandingActionsOnCSR.size()==0){
            //0we have to set Request Work Item even we are getting the same item over and over again.
            setWorktime('zeacom.requestwork.action', null, inlineCallout);
            createNewCallMetric(REQUEST_WORK_ITEM, workItem, dt);
            CreateNewCallMetric(OVERALL_DURATION, workItem, dt);
        }
    }

    public static void finishPreviewing(Id workItem, DateTime dt) {
        finishPreviewing(workItem,dt,false);
    }
    public static void finishPreviewing(Id workItem, DateTime dt, boolean inlineCallout) {
        setWorktime('zeacom.inprogress.action', null, inlineCallout); // reset user Zeacom to in-progress
        completeCallMetric(REQUEST_WORK_ITEM, dt);
        createNewCallMetric(IN_PROGRESS, workItem, dt);
    }
    
    public static void endCalling(List<Task> tasks) {
        System.debug('End Calling');
        // Filter tasks. We only want outbound calls.
        Map<Id, Call_Metric__c> calls = new Map<Id, Call_Metric__c>();
        List<Call_Metric__c> metrics = new List<Call_Metric__c>();
        
        // select OwnerId, Caller_ID__c, task.CreatedDate, CallDurationInSeconds from Task where CallType = 'outbound'
        for (Task task : Tasks) {
            System.debug('Owner Id: ' + task.OwnerId + ', Call Type: ' + task.CallType);
            if ('Outbound'.equalsIgnoreCase(task.CallType)) {
                Id csr = task.OwnerId;
                DateTime callEndedAt = task.CreatedDate;
                DateTime callStartedAt = callEndedAt.addSeconds(task.CallDurationInSeconds * -1);
                Call_Metric__c cm =  new Call_Metric__c(
                    CSR__c = csr,
                    Action__c = OUTBOUND_CALL,
                    Start__c = callStartedAt,
                    End__c = callEndedAt
                    // Phone__c = task.Caller_ID__c
                );
                calls.put(csr, cm); // let the last task on the user rules the logic
                metrics.add(cm);
            }
        }
        
        List<Id> users = new List<Id>(calls.keySet());
        // this is a safety net, in case the CSR didn't end the "request work item" call metric
        List<Call_Metric__c> workItemRequestActions = [
            select CSR__c, End__c, Work_Item__c
            from Call_Metric__c
            where CSR__c in :users
            and Action__c = :REQUEST_WORK_ITEM
            and End__c = null
        ];
        
        for (Call_Metric__c workItemRequest : workItemRequestActions) {
            Call_Metric__c call = calls.get(workItemRequest.CSR__c);
            
            call.Work_Item__c = workItemRequest.Work_Item__c;
            workItemRequest.End__c = call.Start__c;
            // create an in progress at the same time
            Call_Metric__c cm =  new Call_Metric__c(
                CSR__c = call.csr__c,
                Action__c = IN_PROGRESS,
                Start__c = call.Start__c,
                End__c = null
            );
            // no callout in this stage.  This logic only cater for CSR metric reports
            metrics.add(cm);
            metrics.add(workItemRequest);
        }
        upsert metrics;
    }

    public static void startRecordingOutcome(Id workItem, DateTime dt) {
        startRecordingOutcome(workItem, dt, false); // default use future callout
    }   
    public static void startRecordingOutcome(Id workItem, DateTime dt, boolean inlineCallout) {
        // always set the status in Zeacom, as the CSR may cancel, and comes back, and we need to track it even the outcome already exists
        setWorktime('zeacom.recordoutcome.action', null, inlineCallout);
        completeCallMetric(IN_PROGRESS, dt);
        createNewCallMetric(RECORD_OUTCOME, workItem, dt);
    }

    public static void finishRecordingOutcome(Id workItem, DateTime dt) {
        finishRecordingOutcome(workItem, dt, false); // default to future callout
    }   
    public static void finishRecordingOutcome(Id workItem, DateTime dt, boolean inlineCallout) {
        setWorktime('zeacom.blocking.action', 'zeacom.blocking.duration', inlineCallout);
        completeCallMetric(RECORD_OUTCOME, dt);
        completeCallMetric(OVERALL_DURATION, dt);
        
        // this is a safety net to make sure CSR actions are linear
        // close off any potential open call_metric
        Id csr = UserInfo.getUserId();
        Call_Metric__c[] closeOffOutstandingOnCSR = new Call_Metric__c[]{};
        for (Call_Metric__c c: [select CSR__c, End__c, Work_Item__c from Call_Metric__c where CSR__c = :csr and End__c = null]) {
            c.End__c=dt;
            closeOffOutstandingOnCSR.add(c);
        }
        if(!closeOffOutstandingOnCSR.isEmpty()){
            update closeOffOutstandingOnCSR;
        }
    }

    public static void cancelRecordingOutcome(Id workItem, DateTime dt) {
        cancelRecordingOutcome(workItem, dt, false); // default future callout
    }
    public static void cancelRecordingOutcome(Id workItem, DateTime dt, boolean inlineCallout) {
        setWorktime('zeacom.inprogress.action', null, inlineCallout); // reset user Zeacom to in-progress
        completeCallMetric(RECORD_OUTCOME, dt);
        createNewCallMetric(IN_PROGRESS, workItem, dt);
    }

    /* REGION: Utilities */
    static boolean createNewCallMetric(String action, Id workItem, DateTime dt){
        Id csr = UserInfo.getUserId();
        
        List<Call_Metric__c> recordOutcomeActions = [
            select Id
            from Call_Metric__c
            where CSR__c = :csr
            and Action__c = :action
            and End__c = null
        ];
        
        if (recordOutcomeActions.isEmpty()) {
            insert new Call_Metric__c(
                CSR__c = csr,
                Work_Item__c = workItem,
                Action__c = action,
                Start__c = dt
            );
            return true;
        }
        return false;
    }
    
    static boolean completeCallMetric(String action, DateTime dt){
        Id csr = UserInfo.getUserId();
        List<Call_Metric__c> recordOutcomeActions = NULL;
        
        //if overall duration action we want to only update latest call metric object
        IF (action.equalsIgnoreCase(OVERALL_DURATION) ) 
        {
            recordOutcomeActions = [
            select End__c
            from Call_Metric__c
            where CSR__c = :csr
            and Action__c = :action
            and End__c = null
            order by Start__C desc
            ];
            //if we couldn't find any overall duration that is not finished
            //we need to get the last finished overall duration of the same user
            if(recordOutcomeActions == null || recordOutcomeActions.size() == 0)
            {
                recordOutcomeActions = [
                select End__c
                from Call_Metric__c
                where CSR__c = :csr
                and Action__c = :action
                and End__c != null
                order by End__c desc
                limit 1
                ];
            }
        }else
        {
            recordOutcomeActions = [
            select End__c
            from Call_Metric__c
            where CSR__c = :csr
            and Action__c = :action
            and End__c = null
            ];
        }
        
        if (recordOutcomeActions.size() > 0) {
            Call_Metric__c recordOutcome = recordOutcomeActions.get(0);
            recordOutcome.End__c = dt;
            update recordOutcome;
            return true;
        }
        return false;
    }
    
    static void setWorktime(String reason, String duration, boolean setWorkTime, boolean inlineCallout) {
        
        String defaultAction = defaultZeacomActions.get(reason);
        SystemSettings__c configAction = systemSettings.get(reason);
        String defaultDuration = defaultZeacomActions.get(duration);
        SystemSettings__c configDuration = systemSettings.get(duration);
        
        if (!Test.isRunningTest()) {
            try {
                String action = configAction==null?defaultAction:configAction.value__c;
                integer countdown = Integer.ValueOf(configDuration==null?(String.isBlank(defaultDuration)?'0':defaultDuration):configDuration.value__c);
                if (inlineCallout ){
                    ZeacomClient.setWorktimeInline(getUsersPhoneExtension(), action, countdown, setWorkTime);
                } else {
                    ZeacomClient.SetWorktime(getUsersPhoneExtension(), action, countdown, setWorkTime);                 
                }
            }
            catch (Exception e) {
            }
        }
    }

    static void setWorktime(String reason, String duration, boolean inlineCallout) {
        setWorktime(reason, duration, true, inlineCallout);// default set that to "worktime = true"
    }
    
    static String getUsersPhoneExtension() {
        User currentUser = [
            select Extension
            from User
            where Id = :UserInfo.getUserId()
            limit 1
        ];
        
        return currentUser.Extension;
    }
}