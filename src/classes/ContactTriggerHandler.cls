public class ContactTriggerHandler {
		
    public static void beforeInsert_AssignAccount(List<Contact> newContacts){
        List<Account> newAccounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for(Contact ct: newContacts){
        	// in order to stop private contacts, auto create accounts
            if(ct.LastName != NULL && ct.AccountId == NULL ) {
                Account acc = new Account();
                acc.Name = ct.FirstName+' '+ct.LastName;
                acc.Account_External_Id__c = ApexUtility.GUID();
                newAccounts.add(acc);
                ct.account = acc;
                contacts.add(ct);
            }
        }
        if(!newAccounts.isEmpty()){insert newAccounts;}
        for(Contact ct: contacts){
            ct.accountid = ct.account.id;
        }
    }
}