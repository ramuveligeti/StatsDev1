@isTest
private class AlterSkillsetForUserCon_Test {
    
    @isTest static void testMethod1(){
        User userObj = TestDataHelper.createUser( 'Test' + datetime.now().getTime()+'@gmail.com','System Administrator',true);
        system.runAs(userObj){
            Collection__c col = TestDataHelper.createCollection(true);
        	Skillset__c skill = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            //skill.User_Name__c = userObj.Id;
            skill.Skill__c = 'Phone';
            skill.Skillset_Ext_Id__c = skill.User_Name__c+''+skill.Collection__c+''+skill.Skill__c;
            insert skill;
        	/*Skillset__c skill1 = TestDataHelper.createSkillset(col.Id, userObj.Id, false);
            skill1.Skill__c = 'Phone';
            skill1.Skillset_Ext_Id__c = skill1.User_Name__c+''+skill1.Collection__c+''+skill1.Skill__c;
            insert skill1;*/
            test.startTest();
            Apexpages.StandardController stdCont = new Apexpages.StandardController(skill);
            AlterSkillsetForUserCon asf = new AlterSkillsetForUserCon(stdCont);
            asf.skillset.User_Name__c = null;
            asf.queryRelatedSkills();
            asf.skillset.User_Name__c = userObj.Id;
            asf.queryRelatedSkills();
            List<Skillset__c> s2 = [Select Id from Skillset__c];
            system.assertEquals(1,s2.size());
            
            asf.assignNewSkill();
            system.assertEquals(2,asf.skillsets.size());
            
            asf.removeId = skill.Id;
            asf.removeListId = 0;
            asf.deleteSkillset();
            system.assertEquals(1,asf.skillsets.size());
            List<Skillset__c> s3 = [Select Id from Skillset__c];
            system.assertEquals(0,s3.size());
            
            asf.removeListId = 0;
            asf.deleteSkillset();
            system.assertEquals(0,asf.skillsets.size());
            asf.assignNewSkill();
            asf.skillsets[0].User_Name__c = userObj.Id;
            asf.skillsets[0].Collection__c = null;
            asf.skillsets[0].Training_Completion_Date__c = system.now();
            asf.skillsets[0].Skill__c = 'Phone';
            asf.assignNewSkill();
            asf.skillsets[0].User_Name__c = userObj.Id;
            asf.skillsets[0].Collection__c = col.Id;
            asf.skillsets[0].Training_Completion_Date__c = system.now();
            asf.skillsets[0].Skill__c = 'Phone';
            system.assertEquals(1,asf.skillsets.size());
            asf.save();
            List<Skillset__c> s1 = [Select Id from Skillset__c];
            system.assertEquals(1,s1.size());
            asf.assignNewSkill();
            asf.skillsets[1].User_Name__c = userObj.Id;
            asf.skillsets[1].Collection__c = col.Id;
            asf.skillsets[1].Training_Completion_Date__c = system.now();
            asf.skillsets[1].Skill__c = 'Phone';
            system.assertEquals(2,asf.skillsets.size());
            asf.save();
            List<Skillset__c> s4 = [Select Id from Skillset__c];
            system.assertEquals(1,s4.size());
            asf.skillsets[1].Skill__c = 'Key';
            asf.save();
            asf.cancel();
            test.stopTest();
            List<Skillset__c> s = [Select Id from Skillset__c];
            system.assertEquals(2, s.size());
            delete s;
            asf.queryRelatedSkills();
            List<Skillset__c> s6 = [Select Id from Skillset__c];
            system.assertEquals(0, s6.size());
        }        
    }
}