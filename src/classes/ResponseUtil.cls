public class ResponseUtil {

    public static void setResponseDetailsFromContact(Response__c resp, Contact person, String careOf){
        if(person!=null && resp!=null){
            if(String.isNotBlank(person.Company_name__c)){
                resp.Care_of__c = person.Company_name__c;
            }else if(String.isNotBlank(careOf)){
                resp.Care_of__c = careOf;
            }else{
                resp.Care_of__c = null;// blank it regardless
            }

            if(person.Has_Address__c){ 
                if(person.Box_Bag_Number__c==null){
                    resp.Box_Bag_Number__c=null;
                }else{
                    resp.Box_Bag_Number__c = Decimal.valueOf(person.Box_Bag_Number__c);         
                }
                resp.Building_Level_Unit__c = person.Building_Level_Unit__c;
                resp.Delivery_Building_Name__c = person.Building_Name__c;
                resp.Country__c = person.Country__c;
                resp.Delivery_Service_Type__c = person.Delivery_Service_Type__c;
                resp.Delivery_Level_Number__c = person.Level_Number__c;
                resp.Mail_Town__c = person.Mail_Town__c;
                resp.Delivery_Postcode__c = person.Postcode__c;
                resp.Road_Direction__c = person.Road_Direction__c;
                resp.Delivery_Road_Name__c = person.Road_Name__c;
                resp.Delivery_Road_Number__c = person.Road_Number__c;
                resp.Delivery_Road_Number_Alpha__c = person.Road_Number_Alpha__c;
                resp.Delivery_Road_Type__c = person.Road_Type__c;
                resp.Delivery_Rural_Delivery_Number__c = person.Rural_Delivery_Number__c;
                resp.Delivery_suburb__c = person.Suburb__c;
                resp.Street_Road_PO_Box__c = person.Street_Road_PO_Box__c;
                resp.Suburb_Rural_Delivery__c = person.Suburb_Rural_Delivery__c;
                resp.Delivery_Town_or_City__c = person.Town_or_City__c;

            }
        }
    }

    public static void setResponseDetailsFromUnit(Response__c response, Unit__c unit){
    	if(unit!=null && response!=null){
	    	response.Delivery_Building_Name__c = unit.Building_Name__c;
	        response.Delivery_Level_Number__c = unit.Level_Number__c;
	        response.Delivery_Unit_Number__c = unit.Unit_Number__c;
	        response.Delivery_Road_Name__c = unit.Road_Name__c;
	        response.Delivery_Road_Number__c = unit.Road_Number__c;
	        response.Delivery_Road_Number_Alpha__c = unit.Road_Number_Alpha__c;
	        response.Delivery_Road_Type__c = unit.Road_Type__c;
	        response.Delivery_Rural_Delivery_Number__c = unit.Rural_Delivery_Number__c;
	        response.Delivery_Suburb__c = unit.Suburb__c;
	        response.Delivery_Town_or_City__c = unit.Town_or_City__c;
	        response.Delivery_Postcode__c = unit.Postcode__c;
	        
	        // 4 line address
	        response.Building_Level_Unit__c = unit.Building_Level_Unit__c;
	        response.Street_Road_PO_Box__c = unit.Street_Road_PO_Box__c;
	        response.Suburb_Rural_Delivery__c = unit.Suburb_Rural_Delivery__c;
	        response.Country__c = unit.Country__c;

	    }
    }
}