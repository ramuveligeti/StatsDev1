@isTest
private class BulkAssignSkillset_Test {
    @isTest static void testMethod1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(false);
            col.Status__c = 'Active';
            insert col;
        	Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, true);
        	Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.User_Name__c = userObj.Id;
            skill1.Collection__c = col.Id;
            skill1.Skill__c = 'Phone3';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            insert skill1;
            test.startTest();
            Apexpages.StandardController stdCont = new Apexpages.StandardController(skill);
            BulkAssignSkillsetCon bas = new BulkAssignSkillsetCon(stdCont);
            bas.save();
            User userObj1 = TestDataHelper.createUser( 'Test1' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
            Collection__c col1 = TestDataHelper.createCollection(false);
            col1.Name = 'Census';
            col1.Collection_Code__c = 'Census';
            insert col1;
            bas.selectedUsers.add(new SelectOption(userObj.Id,'Ramu'));
            bas.selectedUsers.add(new SelectOption(userObj1.Id,'Ramu1'));
            bas.selectedCollections.add(new SelectOption(col.Id,col.Name));
            bas.selectedCollections.add(new SelectOption(col1.Id,col1.Name));
            bas.selectedSkills.add(new SelectOption('Phone','Phone'));
            bas.selectedSkills.add(new SelectOption('Phone1','Phone1'));
            bas.save();
            List<Skillset__c> s1 = [Select Id from Skillset__c where Id != :skill.Id and Id != :skill1.Id];
            system.assertEquals(0,s1.size());
            bas.selectedSkills.clear();
            bas.selectedSkills.add(new SelectOption('Phone2','Phone2'));
            bas.selectedSkills.add(new SelectOption('Phone1','Phone1'));
            bas.save();
            bas.cancel();
			test.stopTest();
            List<Skillset__c> s = [Select Id from Skillset__c where Id != :skill.Id and Id != :skill1.Id];
            system.assertEquals(8,s.size());
        }        
    }
}