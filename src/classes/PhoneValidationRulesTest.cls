/*
    Validation: 
    4. Validation on Main phone / Alt. Phone / Mobile phone has to be international and follow the following format +XX (XXXX) XXXXXXXXXX, Area code between brackets has a maximum length of 4, and phone number (minus area code) has a maximum length of 10. This rule only applies to NZ (61)/ Australia (64) phone numbers. No format validation for other countries. (note: mobile area code now needs a maximum length of 3 to exclude 0800 like numbers as agreed by Yannick and Tania) 
    5. An 0800 xxx xxx, or 0508 xxx xxx number can be allowed for main phone and Alt. Phone, but not for mobile phone. 
    6. There can't be a 'alt. phone' without a valid 'main phone' 
    7. Extension on main and alt. phone: Numeric only (min 1 number / max 4), can't have an extension without an associated main or alt. phone
*/

@isTest
public class PhoneValidationRulesTest {
    
    @isTest
    static void ValidateMainPhone() {
       	Contact contact = new Contact(
            Phone = '09 222 3333'
        );
        
        List<Contact> contacts = new List<Contact> {
            contact
        };
        
        PhoneValidationRules.ValidateContacts(contacts);
        
        System.assertEquals('+64 (9) 2223333', contact.Phone);
    }
    
    @isTest
    static void ValidateAltPhone() {
       	Contact contact = new Contact(
            HomePhone = '09 222 3333'
        );
        
        List<Contact> contacts = new List<Contact> {
            contact
        };
        
        PhoneValidationRules.ValidateContacts(contacts);
        
        System.assertEquals('+64 (9) 2223333', contact.HomePhone);
    }
    
    @isTest
    static void ValidateMobilePhone() {
       	Contact contact = new Contact(
            MobilePhone = '022 222 3333'
        );
        
        List<Contact> contacts = new List<Contact> {
            contact
        };
        
        PhoneValidationRules.ValidateContacts(contacts);
        
        System.assertEquals('+64 (22) 2223333', contact.MobilePhone);
    }

    @isTest
    static void ValidateOtherPhone() {
       	Contact contact = new Contact(
            OtherPhone = '022 222 3333'
        );
        
        List<Contact> contacts = new List<Contact> {
            contact
        };
        
        PhoneValidationRules.ValidateContacts(contacts);
        
        System.assertEquals('+64 (22) 2223333', contact.OtherPhone);
    }

}