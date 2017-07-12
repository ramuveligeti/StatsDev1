@isTest
private class GetCustomSettingValueTest {

    private static testMethod void doTest() {

        Test.startTest();
        List<String> names= new List<String>(); 
        List<String> values= new List<String>(); 
        names.add('CnL.workitem.queue');
        values=GetCustomSettingValue.getValue(names); 
        Test.stopTest();

        string value = values[0];
        System.debug('Value is '+value );         

    }
}