public class SystemSettings {
	
	private static Map<String, SystemSettings__c> systemSettings = SystemSettings__c.getAll();

	public static String getValue(String name) {
		if(String.isNotBlank(name)){
			SystemSettings__c systemSetting = systemSettings.get(name);
			if(systemSetting!=null){
				return systemSetting.Value__c;
			}else{
				throw new SystemSettingsException('System Setting does not exist: '+name);
			}
		}else{
			throw new SystemSettingsException('System Setting name was not provided');
		}
	}

	//if custom setting does not exist then return default
	public static String getValue(String name, String defaultValue) {
		if(String.isNotBlank(name)){
			SystemSettings__c systemSetting = systemSettings.get(name);
			if(systemSetting!=null){
				return systemSetting.Value__c;
			}else{
				return defaultValue;
			}
		}else{
			throw new SystemSettingsException('System Setting name was not provided');
		}
	}

	public static Integer getIntegerValue(String name) {
		if(String.isNotBlank(name)){
			if(systemSettings.containsKey(name)){
				String strValue = systemSettings.get(name).Value__c;
				return Integer.valueOf(strValue);
			}else{
				throw new SystemSettingsException('System Setting does not exist: '+name);
			}
		}else{
			throw new SystemSettingsException('System Setting name was not provided');
		}
	}

	//if custom setting does not exist then return default
	public static Integer getIntegerValue(String name, Integer defaultValue) {
		if(String.isNotBlank(name)){
			if(systemSettings.containsKey(name)){
				String strValue = systemSettings.get(name).Value__c;
				if(String.isBlank(strValue)){
					return null;
				}else{
					return Integer.valueOf(strValue);
				}
			}else{
				return defaultValue;
			}
		}else{
			throw new SystemSettingsException('System Setting name was not provided');
		}
	}
}