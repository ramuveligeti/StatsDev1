public class GetCustomSettingValue { 
 @InvocableMethod(label='Get Custom Setting Value' description='This class is used to read custom settings value, so that It can be used in flow')
  public static List<String>getValue (List<String> names){
    string name=names[0];
    System.debug('name is '+name);
    List<String> values= new List<String>(); 
    SystemSettings__c tempSettings = SystemSettings__c.getValues(name);
    String value= tempSettings == null?'C_L_Escalation_Queue':tempSettings.value__c;
    values.add(value); 
    System.debug('Value is '+value );
    return values; 
    }
  }