public class DoNothing { 
	@InvocableMethod(label='Do Nothing' description='Used to skip required action methods in process builder')
	public static void doNothingMethod(){
		System.debug('Do Nothing');
	}
}