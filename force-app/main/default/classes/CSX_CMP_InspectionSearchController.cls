/**
@Author       - Shyam Sharma
@Name         - CSX_CMP_InspectionSearchController
@Created Date - 10/16/2023
@Description  - Apex class controller for Inspection search
*/
public with sharing class CSX_CMP_InspectionSearchController {
	//Returns list of Inspection header search results based on search criteria
	@AuraEnabled(cacheable=true)
	public static List<CSX_CMP_Inspection_Header__c> searchInspectionHeaderList(String inspectionSearchParameters,boolean exCleanException) {
		List<CSX_CMP_Inspection_Header__c> inspectionHeaderRecords = new List<CSX_CMP_Inspection_Header__c>();
		list<sObject> initialQueryResults = new List<sObject>();
		List<String> filters = new List<String>();
		list<CSX_CMP_Inspection_Header__c> finalResults = new List<CSX_CMP_Inspection_Header__c>();
		Set<Id> inspectionHeaderIds = new Set<Id>();
		try {
			String query = 'SELECT Name,CSX_CMP_Source__c,CSX_CMP_VIN__c,CSX_CMP_Inspection_Road__c,CSX_CMP_Inspection_Date__c,CSX_CMP_Inspection_Report_Type__c,CSX_CMP_Equipment_Initial__c,CSX_CMP_Equipment_Number__c,CSX_CMP_Ramp_Id__c,CSX_CMP_Manufacturer__c,CSX_CMP_Driver_Name__c,CSX_CMP_Driver_Email__c,CSX_CMP_Haulaway_Company__c,CSX_CMP_Terminal_Name__c,CSX_CMP_Previous_Damage_Indicator__c,CSX_CMP_Reminder_Indicator__c,CSX_CMP_Haulaway_Comments__c,(select CSX_CMP_Damage_Area__c,CSX_CMP_Damage_Severity__c,CSX_CMP_Damage_Type__c from Inspection_Details__r )  FROM CSX_CMP_Inspection_Header__c ';
			String inspectionDetail = 'SELECT Id,CSX_CMP_Inspection_Header__c, CSX_CMP_Damage_Type__c, CSX_CMP_Damage_Area__c, CSX_CMP_Damage_Severity__c,CSX_CMP_Inspection_Header__r.Name,CSX_CMP_Inspection_Header__r.CSX_CMP_Source__c,CSX_CMP_Inspection_Header__r.CSX_CMP_VIN__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Inspection_Road__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Inspection_Date__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Inspection_Report_Type__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Equipment_Initial__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Equipment_Number__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Ramp_Id__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Manufacturer__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Driver_Name__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Driver_Email__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Haulaway_Company__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Terminal_Name__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Previous_Damage_Indicator__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Reminder_Indicator__c,CSX_CMP_Inspection_Header__r.CSX_CMP_Haulaway_Comments__c FROM CSX_CMP_Inspection_Detail__c';

			String inReferenceKey = '';
			String inRChildReferenceKey = '';
			String initialSearchQuery = '';
			string insReferenceValue = '';
			
			String iNSWhereReferenceKey = '';
			String inspectionDetailReferenceKey = 'CSX_CMP_Inspection_Header__r.';

			Map<String, String> refKeykeyMap = new Map<String, String>();
			refKeykeyMap.put('iNSWhereReferenceKey', iNSWhereReferenceKey);
			refKeykeyMap.put('inspectionDetailReferenceKey', inspectionDetailReferenceKey);

			Map<String, String> refKeyQueryMap = new Map<String, String>();
			refKeyQueryMap.put('inspectionDetailReferenceKey', inspectionDetail);
			
			if( exCleanException!=null && exCleanException){
				
				 query = 'SELECT Name,CSX_CMP_Source__c,CSX_CMP_VIN__c,CSX_CMP_Inspection_Road__c,CSX_CMP_Inspection_Date__c,CSX_CMP_Inspection_Report_Type__c,CSX_CMP_Equipment_Initial__c,CSX_CMP_Equipment_Number__c,CSX_CMP_Ramp_Id__c,CSX_CMP_Manufacturer__c,CSX_CMP_Driver_Name__c,CSX_CMP_Driver_Email__c,CSX_CMP_Haulaway_Company__c,CSX_CMP_Terminal_Name__c,CSX_CMP_Previous_Damage_Indicator__c,CSX_CMP_Reminder_Indicator__c,CSX_CMP_Haulaway_Comments__c,(select CSX_CMP_Damage_Area__c,	CSX_CMP_Damage_Severity__c,CSX_CMP_Damage_Type__c from Inspection_Details__r where ((CSX_CMP_Damage_Severity__c!=\'0\') AND (CSX_CMP_Damage_Area__c!=\'00\') AND (CSX_CMP_Damage_Type__c!=\'00\')) OR((CSX_CMP_Damage_Severity__c!=\'0\') OR (CSX_CMP_Damage_Area__c!=\'00\') OR (CSX_CMP_Damage_Type__c!=\'00\')) )  FROM CSX_CMP_Inspection_Header__c ';
				refKeyQueryMap.put('iNSWhereReferenceKey', query);
			}else{
				refKeyQueryMap.put('iNSWhereReferenceKey', query);
			}


			//16 may changes | Start
			InspectionSearchRequestWrapper wrapperObj = (InspectionSearchRequestWrapper) JSON.deserialize(
				inspectionSearchParameters,
				InspectionSearchRequestWrapper.class
			);
			if (
				string.isNotBlank(wrapperObj.damageType) ||
				string.isNotBlank(wrapperObj.damageSeverity) ||
				string.isNotBlank(wrapperObj.damageArea)
			) {
				inReferenceKey = 'inspectionDetailReferenceKey';
			} else {
				inReferenceKey = 'iNSWhereReferenceKey';
			}
			if (inReferenceKey == 'inspectionDetailReferenceKey') {
				inRChildReferenceKey = '';
			}
			if (!String.isBlank(inReferenceKey)) {
				insReferenceValue = refKeykeyMap.get(inReferenceKey);
			}
			if (String.isNotBlank(wrapperObj.vinNumber)) {
				String vinNo;
				if (wrapperObj.vinNumber.length() == 8) {
					vinNo = wrapperObj.vinNumber.right(8);
				} else {
					vinNo = wrapperObj.vinNumber;
				}
				filters.add(insReferenceValue + 'CSX_CMP_VIN__c LIKE ' + '\'%' + vinNo + '\'');
			}
			if (String.isNotBlank(wrapperObj.inspectionRoad)) {
				string inspRoad = string.valueOf(wrapperObj.inspectionRoad);
				filters.add(insReferenceValue + 'CSX_CMP_Inspection_Road__c = :inspRoad');
			}

			if (String.isNotBlank(wrapperObj.inspectionType)) {
				string inspType = string.valueOf(wrapperObj.inspectionType);
				filters.add(insReferenceValue + 'CSX_CMP_Inspection_Report_Type__c = :inspType');
			}

			if (String.isNotBlank(wrapperObj.rampId)) {
				string rampId = string.valueOf(wrapperObj.rampId);
				filters.add(insReferenceValue + 'CSX_CMP_Ramp_Id__c like ' + '\'%' + rampId + '%\'');
			}

			if (String.isNotBlank(wrapperObj.equipmentInitial)) {
				string equipmentInitial = string.valueOf(wrapperObj.equipmentInitial);
				filters.add(insReferenceValue + 'CSX_CMP_Equipment_Initial__c = :equipmentInitial');
			}

			if (String.isNotBlank(wrapperObj.equipmentNumber)) {
				string equipmentNumber = string.valueOf(wrapperObj.equipmentNumber);
				filters.add(insReferenceValue + 'CSX_CMP_Equipment_Number__c = :equipmentNumber');
			}

			if (String.isNotBlank(wrapperObj.source)) {
				string source = string.valueOf(wrapperObj.source);
				filters.add(insReferenceValue + 'CSX_CMP_Source__c = :source');
			}
			if (string.isNotBlank(wrapperObj.startDate)) {
				Date startDateValue = Date.valueOf(wrapperObj.startDate);
				filters.add(insReferenceValue + 'CSX_CMP_Inspection_Date__c >= :startDateValue');
			}
			if (string.isNotBlank(wrapperObj.endDate)) {
				Date endDateValue = Date.valueOf(wrapperObj.endDate).addDays(1);
				filters.add(insReferenceValue + 'CSX_CMP_Inspection_Date__c < :endDateValue');
			}
			//Inspection Detail
			
			if (string.isNotBlank(wrapperObj.damageType)) {
				
				String damageTypeValue = String.valueOf(wrapperObj.damageType);
				if (damageTypeValue == '00') {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Type__c !=:damageTypeValue');
				} else {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Type__c = :damageTypeValue');
				}
			}
			if (string.isNotBlank(wrapperObj.damageSeverity)) {
				
				String damageSeverityValue = String.valueOf(wrapperObj.damageSeverity);
				if (damageSeverityValue == '00') {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Severity__c !=:damageSeverityValue');
				} else {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Severity__c = :damageSeverityValue');
				}
			}
			if (string.isNotBlank(wrapperObj.damageArea)) {
				
				String damageAreaValue = String.valueOf(wrapperObj.damageArea);
				if (damageAreaValue == '00') {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Area__c!=:damageAreaValue');
				} else {
					filters.add(inRChildReferenceKey + 'CSX_CMP_Damage_Area__c=:damageAreaValue');
				}
			}

			//16 may changes | End

			initialSearchQuery = refKeyQueryMap.get(inReferenceKey);

			if (filters.size() > 0) {
				initialSearchQuery = initialSearchQuery + ' WHERE ' + String.join(filters, ' AND ');
			} else {
				initialSearchQuery = initialSearchQuery;
			}
			
			

			if (filters.size() > 0) {
				Set<CSX_CMP_Inspection_Header__c> inspectionHeaderRecordsSet = new Set<CSX_CMP_Inspection_Header__c>();
                Integer searchLimit = Integer.valueOf(System.Label.CSX_CMP_SearchDataLimit);
                Integer dataLimit = searchLimit + 1;
				initialSearchQuery += ' LIMIT '+ String.valueOf(dataLimit);
				
				if (inReferenceKey == 'iNSWhereReferenceKey') {
					
					List<CSX_CMP_Inspection_Header__c> tempInspectionHeaderRecords = new List<CSX_CMP_Inspection_Header__c>();
					tempInspectionHeaderRecords = Database.query(initialSearchQuery);
					
					if (tempInspectionHeaderRecords.size() > searchLimit) {
						String message = System.Label.CSX_CMP_RecordLimit_Warning;
						AuraHandledException e = new AuraHandledException(message);
						e.setMessage(message);
						throw e;
					} else if (!tempInspectionHeaderRecords.isEmpty()) {
                        
						for (CSX_CMP_Inspection_Header__c obj : tempInspectionHeaderRecords) {
							if (obj.Inspection_Details__r.size() > 0) {
								inspectionHeaderRecordsSet.add(obj);
							}
						}
					}
				} else if (inReferenceKey == 'inspectionDetailReferenceKey') {
					initialQueryResults = Database.query(initialSearchQuery);
					if (initialQueryResults.size() > searchLimit) {
						String message = System.Label.CSX_CMP_RecordLimit_Warning;
						AuraHandledException e = new AuraHandledException(message);
						e.setMessage(message);
						throw e;
					} else if (!initialQueryResults.isEmpty()) {
						
						for (sObject rec : initialQueryResults) {
							CSX_CMP_Inspection_Detail__c obj = (CSX_CMP_Inspection_Detail__c) rec;
							CSX_CMP_Inspection_Header__c objHeader = obj.CSX_CMP_Inspection_Header__r;
							inspectionHeaderRecordsSet.add(objHeader);
						}
					}
				}

				if (!inspectionHeaderRecordsSet.isEmpty()) {
					inspectionHeaderRecords = new List<CSX_CMP_Inspection_Header__c>(inspectionHeaderRecordsSet);
				}
			}
		} catch (exception ex) {
			String message = System.Label.CSX_CMP_RecordLimit_Warning;
			if (ex.getMessage().contains(message)) {
				throw new AuraHandledException(message);
			} else {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InspectionSearchController','searchInspectionHeaderList	',inspectionSearchParameters,ex);
			}
		}
		return inspectionHeaderRecords;
	}

	@AuraEnabled
	public static List<InspectionDetailWrapper> fetchInspectionDetails(
		List<ID> inspectionHeaderIds,
		Boolean exCleanException
	) {
        
		List<CSX_CMP_Inspection_Detail__c> inspectionDetailRecordsValues = new List<CSX_CMP_Inspection_Detail__c>();
		List<InspectionDetailWrapper> detailWrapperList = new List<InspectionDetailWrapper>();
		Boolean excludeCleanException = exCleanException;
		
		try {  
			if (excludeCleanException) {
				inspectionDetailRecordsValues = [
					SELECT
						Id,
						Name,
						CSX_CMP_Inspection_Header__c,
						CSX_CMP_Inspection_Header__r.Name,
						CSX_CMP_VIN__c,
						CSX_CMP_Damage_Area__c,
						CSX_CMP_Inspection_Road__c,
						CSX_CMP_Inspection_Date__c,
						CSX_CMP_Inspection_Report_Type__c,
						CSX_CMP_Damage_Severity__c,
						CSX_CMP_Damage_Type__c
					FROM CSX_CMP_Inspection_Detail__c
					WHERE
						CSX_CMP_Inspection_Header__c IN :inspectionHeaderIds AND
						((CSX_CMP_Damage_Severity__c!='0') AND (CSX_CMP_Damage_Area__c!='00') AND (CSX_CMP_Damage_Type__c!='00')) 
					WITH SECURITY_ENFORCED
					LIMIT 40000
				];
                
			} else {
                
              
				inspectionDetailRecordsValues = [
					SELECT
						Id,
						Name,
						CSX_CMP_Inspection_Header__c,
						CSX_CMP_Inspection_Header__r.Name,
						CSX_CMP_VIN__c,
						CSX_CMP_Damage_Area__c,
						CSX_CMP_Inspection_Road__c,
						CSX_CMP_Inspection_Date__c,
						CSX_CMP_Inspection_Report_Type__c,
						CSX_CMP_Damage_Severity__c,
						CSX_CMP_Damage_Type__c
					FROM CSX_CMP_Inspection_Detail__c
					WHERE CSX_CMP_Inspection_Header__c IN :inspectionHeaderIds
					WITH SECURITY_ENFORCED
					LIMIT 40000
				];
                
			}
			for (CSX_CMP_Inspection_Detail__c ins : inspectionDetailRecordsValues) {
				InspectionDetailWrapper wrapperValues = new InspectionDetailWrapper();
				wrapperValues.inspectionHeaderId = ins.CSX_CMP_Inspection_Header__r.Name;
				wrapperValues.inspectionHeaderURL = ins.CSX_CMP_Inspection_Header__c;
				wrapperValues.vinNumber = ins.CSX_CMP_VIN__c;
				wrapperValues.inspectionDetailId = ins.Name;
				wrapperValues.inspectionDetailURL = ins.Id;
				wrapperValues.inspectionRoad = ins.CSX_CMP_Inspection_Road__c;
				wrapperValues.inspectionDate = ins.CSX_CMP_Inspection_Date__c;
				wrapperValues.inspectionType = ins.CSX_CMP_Inspection_Report_Type__c;
				wrapperValues.damageArea = ins.CSX_CMP_Damage_Area__c;
				//wrapperValues.damageArea=ins.CSX_CMP_Damaged_Area__c;
				wrapperValues.damageType = ins.CSX_CMP_Damage_Type__c;
				wrapperValues.damageSeverity = ins.CSX_CMP_Damage_Severity__c;
				detailWrapperList.add(wrapperValues);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InspectionSearchController','fetchInspectionDetails',String.valueOf(inspectionHeaderIds),ex);
		}
		return detailWrapperList;
	}

	// Need to review once and remove this method if not required
/*	public static List<CSX_CMP_Inspection_Header__c> fetchFullInspectionDetails(Set<Id> inspectionHeaderIds) {
		List<CSX_CMP_Inspection_Header__c> headerRecords = [
			SELECT
				Id,
				Name,
				CSX_CMP_VIN__c,
				CSX_CMP_Inspection_Road__c,
				CSX_CMP_Inspection_Date__c,
				CSX_CMP_Inspection_Report_Type__c,
				CSX_CMP_Equipment_Initial__c,
				CSX_CMP_Equipment_Number__c,
				CSX_CMP_Source__c,
				CSX_CMP_Ramp_Id__c,
				CSX_CMP_Manufacturer__c,
				CSX_CMP_Driver_Email__c,
				CSX_CMP_Driver_Name__c,
				CSX_CMP_Haulaway_Company__c,
				CSX_CMP_Terminal_Name__c,
				CSX_CMP_Previous_Damage_Indicator__c,
				CSX_CMP_Reminder_Indicator__c,
				CSX_CMP_Haulaway_Comments__c,
				(
					SELECT CSX_CMP_Damage_Area__c, CSX_CMP_Damage_Severity__c, CSX_CMP_Damage_Type__c
					FROM Inspection_Details__r
					WHERE CSX_CMP_Damage_Severity__c != '00' AND CSX_CMP_Damage_Area__c != '00' AND CSX_CMP_Damage_Type__c != '00'
				)
			FROM CSX_CMP_Inspection_Header__c
			WHERE Id IN :inspectionHeaderIds
			WITH SECURITY_ENFORCED
		];

		List<CSX_CMP_Inspection_Header__c> finalheaderRecords = new List<CSX_CMP_Inspection_Header__c>();
		for (CSX_CMP_Inspection_Header__c insHeader : headerRecords) {
			if (insHeader.Inspection_Details__r.size() > 0) {
				finalheaderRecords.add(insHeader);
			}
		}
		return finalheaderRecords;
	} */

	public class InspectionSearchRequestWrapper {
		public String source;
		public String inspectionRoad;
		public String inspectionType;
		public String rampId;
		public String damageArea;
		public String damageType;
		public String damageSeverity;
		public String equipmentInitial;
		public String equipmentNumber;
		public String vinNumber;
		public String startDate;
		public String endDate;
	}

	public class InspectionDetailWrapper {
		@AuraEnabled
		public String inspectionHeaderId;
		@AuraEnabled
		public String inspectionHeaderURL;
		@AuraEnabled
		public string vinNumber;
		@AuraEnabled
		public String inspectionDetailId;
		@AuraEnabled
		public String inspectionDetailURL;
		@AuraEnabled
		public String inspectionRoad;
		@AuraEnabled
		public String inspectionDate;
		@AuraEnabled
		public String inspectionType;
		@AuraEnabled
		public String damageArea;
		@AuraEnabled
		public String damageType;
		@AuraEnabled
		public String damageSeverity;
	}
}