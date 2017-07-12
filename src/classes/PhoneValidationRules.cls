/*
    Validation: 
    4. Validation on Main phone / Alt. Phone / Mobile phone has to be international 
	and follow the following format +XX (XXXX) XXXXXXXXXX, Area code between brackets has a maximum length of 4,
	and phone number (minus area code) has a maximum length of 10. This rule only applies to NZ (61)/ Australia (64) phone numbers.
	No format validation for other countries. (note: mobile area code now needs a maximum length of 3 to exclude 0800 like numbers as agreed by Yannick and Tania) 
    
	5. An 0800 xxx xxx, or 0508 xxx xxx number can be allowed for main phone and Alt. Phone, but not for mobile phone. 
    6. There can't be a 'alt. phone' without a valid 'main phone' 
    7. Extension on main and alt. phone: Numeric only (min 1 number / max 4), can't have an extension without an associated main or alt. phone
*/

public class PhoneValidationRules {
    static String MatchAnythingButNumbers = '(?![0-9]).';
    static String Blank = '';
    
    static Map<String, String> AreaCodes = new Map<String, String> {
        '03' => '+64 (3) ', // South Island
        '04' => '+64 (4) ', // Wellington
        '06' => '+64 (6) ', // Central North Island
        '07' => '+64 (7) ', // North Land
        '09' => '+64 (9) '  // Auckland
    };

    static Map<String, String> MobileCompanyCodes = new Map<String, String> {
        '020'  => '+64 (20) ',  // Orcon
        '021'  => '+64 (21) ',  // Vodafone
        '022'  => '+64 (22) ',  // 2degrees
        '023'  => '+64 (23) ',  // 360 Mobile, Moblopia
        '024'  => '+64 (24) ',  // Unused
        '025'  => '+64 (25) ',  // Unused
        '027'  => '+64 (27) ',  // Telecom New Zealand
        '028'  => '+64 (28) ',  // Mainly CallPlus
        '029'  => '+64 (29) '   // TelstraClear
    };
    
    public static String FormatePrefix(String phoneNumber) {
        if (String.isBlank(phoneNumber)) {
            return phoneNumber;
        }
        
        if (!phoneNumber.startsWith('0')) {
            return phoneNumber;
        }
        
        String numbersOnly = phoneNumber.replaceAll(MatchAnythingButNumbers, Blank);
        
        if(numbersOnly.length()<2){
        	return phoneNumber;
        }
        
        String phonePrefix = numbersOnly.substring(0, 2);
        
        if (AreaCodes.containsKey(phonePrefix)) {
            String prefix = AreaCodes.get(phonePrefix);
            return numbersOnly.replaceFirst(phonePrefix, prefix);
        }

        if(numbersOnly.length()<3){
        	return phoneNumber;
        }

        String mobilePrefix = numbersOnly.substring(0, 3);
        
        if (MobileCompanyCodes.containsKey(mobilePrefix)) {
            String prefix = MobileCompanyCodes.get(mobilePrefix);
            return numbersOnly.replaceFirst(mobilePrefix, prefix);
        }
        
        return phoneNumber;
    }
    
    public static void ValidateContacts(List<Contact> contacts) {
        for (Contact contact : contacts) {
            // Main Phone
            // If the number starts with a 0 convert to this format:
            // +XX (XXXX) XXXXXXXXXX
            contact.Phone = FormatePrefix(contact.Phone);
            
            // Alt. Phone
            // If the number starts with a 0 convert to this format:
            // +XX (XXXX) XXXXXXXXXX
            contact.HomePhone = FormatePrefix(contact.HomePhone);
            
            // Mobile Phone
            // If the number starts with a 0 convert to this format:
            // +XX (XXX) XXXXXXXXXX
            contact.MobilePhone = FormatePrefix(contact.MobilePhone);

            // Other Phone
            // If the number starts with a 0 convert to this format:
            // +XX (XXX) XXXXXXXXXX
            contact.OtherPhone = FormatePrefix(contact.OtherPhone);
        }
    }
}