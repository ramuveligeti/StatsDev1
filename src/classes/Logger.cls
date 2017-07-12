public class Logger {

    private static System_Update__c systemSettings = System_Update__c.getInstance(UserInfo.getUserId());

    public static Boolean isEnabled(){
        return systemSettings.Debug_Enabled__c;

    }
}