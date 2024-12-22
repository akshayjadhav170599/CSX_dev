/**************************************************************************************
Apex Class Name     : CSX_CMP_LDRSearchController
Function            : This class is to fetch the L&D records as per filtered criteria.
Author              : Nilesh Soni
* Developer         : Date             Description   
* ----------------------------------------------------------------------------                 
* Infosys           1/2/2024      first version of this class.
*************************************************************************************/

global with sharing class CSX_CMP_LDRSearchController {
	@AuraEnabled(cacheable=true)
	public static CityStateWrapper getStates() {
		CityStateWrapper cityStateWrap = new CityStateWrapper();
		List<CSX_CMP_City_State_Master__c> cityStateMaster = new List<CSX_CMP_City_State_Master__c>();
		try {
			Set<String> stateSet = new Set<String>();
			Set<String> regionSet = new Set<String>();

			cityStateMaster = [
				SELECT id, CSX_CMP_State__c, CSX_CMP_Operating_Region__c
				FROM CSX_CMP_City_State_Master__c
				WHERE CSX_CMP_Status__c = 'Active' WITH SECURITY_ENFORCED
			];

			for (CSX_CMP_City_State_Master__c cState : cityStateMaster) {
				stateSet.add(cState.CSX_CMP_State__c);
				regionSet.add(cState.CSX_CMP_Operating_Region__c);
			}

			List<String> stateList = new List<String>(stateSet);
			List<String> regionList = new List<String>(regionSet);
			stateList.sort();
			regionList.sort();
			cityStateWrap.state = stateList;
			cityStateWrap.region = regionList;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRSearchController', 'getStates', '', ex);
		}
		return cityStateWrap;
	}

	@AuraEnabled(cacheable=true)
	public static LdrSearchResultWrapper getLdrRecords(String ldrSearchParameters) {
		LdrSearchResultWrapper resultWrapper = new LdrSearchResultWrapper();
		list<CSX_CMP_LD_Report__c> finalResults = new List<CSX_CMP_LD_Report__c>();
		List<LdrSearchResponseWrapper> ldrResponseWrapper = new List<LdrSearchResponseWrapper>();
		list<CSX_CMP_Product__c> prodQueryResults = new List<CSX_CMP_Product__c>();
		list<sObject> initialQueryResults = new List<sObject>();
		Set<Id> lDRIds = new Set<Id>();
		Set<Id> ldrRecordId= new Set<Id>();
		Set<Id> equipSetId= new Set<Id>();
		List<String> filters = new List<String>();

		String lDRReportQuery = 'SELECT Id,CSX_CMP_Incident_Location__r.CSX_CMP_State__c,CSX_CMP_Incident_Location__r.CSX_CMP_Operating_Region__c,Name,CSX_CMP_RAR_Num__c,CSX_CMP_Incident_Date__c,CSX_CMP_Incident_Location__c,	CSX_CMP_Incident_State__c,CSX_CMP_Incident_Status__c FROM CSX_CMP_LD_Report__c ';
		String equipmentQuery = 'Select Name,CSX_CMP_Shipper__c,CSX_CMP_LD_Report__c,CSX_CMP_STCC__c,CSX_CMP_Consignee__c from CSX_CMP_Equipment__c';
		String salvageQuery = 'SELECT CSX_CMP_Salvor_Name__c,CSX_CMP_Parent_Equipment__r.CSX_CMP_LD_Report__c,CSX_CMP_Salvage_Amount__c FROM CSX_CMP_Salvage__c';

		String lDReferenceKey = '';
		String lDRChildReferenceKey = '';
		String initialSearchQuery = '';
		string lDRReferenceValue = '';

		String lDRWhereReferenceKey = '';
		String equipmenttoLDRReferenceKey = 'CSX_CMP_LD_Report__r.';
		String salvageLDRReferenceKey = 'CSX_CMP_Parent_Equipment__r.CSX_CMP_LD_Report__r.';

		Map<String, String> refKeykeyMap = new Map<String, String>();
		refKeykeyMap.put('salvageLDRReferenceKey', salvageLDRReferenceKey);
		refKeykeyMap.put('equipmenttoLDRReferenceKey', equipmenttoLDRReferenceKey);
		refKeykeyMap.put('lDRWhereReferenceKey', lDRWhereReferenceKey);

		Map<String, String> refKeyQueryMap = new Map<String, String>();
		refKeyQueryMap.put('salvageLDRReferenceKey', salvageQuery);
		refKeyQueryMap.put('equipmenttoLDRReferenceKey', equipmentQuery);
		refKeyQueryMap.put('lDRWhereReferenceKey', lDRReportQuery);

		try {
			LDRSearchRequestWrapper wrapperObj = (LDRSearchRequestWrapper) JSON.deserialize(
				ldrSearchParameters,
				LDRSearchRequestWrapper.class
			);
			if (
				wrapperObj.salvage == 'Yes' ||
				(string.isBlank(wrapperObj.salvage) &&
				(string.isNotBlank(wrapperObj.salvageAmountFrom) ||
				string.isNotBlank(wrapperObj.salvorName) ||
				string.isNotBlank(wrapperObj.salvageAmountTo)))
			) {
				lDReferenceKey = 'salvageLDRReferenceKey'; //Use salvage query
			} else if ( string.isNotBlank(wrapperObj.stcc) || string.isNotBlank(wrapperObj.shipper)) {//string.isNotBlank(wrapperObj.equipmentInitial) || string.isNotBlank(wrapperObj.equipmentNumber) ||
				lDReferenceKey = 'equipmenttoLDRReferenceKey'; // Use equipment query
			} else {
				lDReferenceKey = 'lDRWhereReferenceKey'; //L&D query
			}

			if (string.isNotBlank(wrapperObj.vinNumber)) {
				String vinNum;
				if (wrapperObj.vinNumber.length() == 8) {
					vinNum = wrapperObj.vinNumber.right(8);
				} else {
					vinNum = wrapperObj.vinNumber;
				}
				String vinPattern = '%' + vinNum + '%';
				String relatedLDRQuery = 'SELECT CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c != null AND CSX_CMP_VIN__c LIKE :vinPattern';
				prodQueryResults = Database.query(relatedLDRQuery);
				/*String relatedLDRQuery =
					'SELECT CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c!=null and CSX_CMP_VIN__c LIKE ' +
					'\'%' +
					vinNum +
					'\'';
				prodQueryResults = Database.query(relatedLDRQuery);*/
				if (!prodQueryResults.isEmpty() && prodQueryResults.size() > 0) {
					for (CSX_CMP_Product__c rec : prodQueryResults) {
						ldrRecordId.add(rec.CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c);
						equipSetId.add(rec.CSX_CMP_Equipment__c);
					}
				} else {
					ldrRecordId.add(null);
				}
			}

			if (lDReferenceKey == 'salvageLDRReferenceKey') {
				lDRChildReferenceKey = 'CSX_CMP_Parent_Equipment__r.';
			} else if (lDReferenceKey == 'equipmenttoLDRReferenceKey') {
				lDRChildReferenceKey = '';
			}

			if (!String.isBlank(lDReferenceKey)) {
				lDRReferenceValue = refKeykeyMap.get(lDReferenceKey);
			}

			//preparing filter clauses for LDR Object.
			if (string.isNotBlank(wrapperObj.reportNumber)) {
				String lndNumber = String.valueOf(wrapperObj.reportNumber);
				filters.add(LDRReferenceValue + 'Name like ' + ' \'%' + lndNumber + '%\'');
			}

			if (string.isNotBlank(wrapperObj.reportType)) {
				String reportType = String.valueOf(wrapperObj.reportType);
				filters.add(LDRReferenceValue + 'CSX_CMP_LD_Type__c = :reportType');
			}
			if (string.isNotBlank(wrapperObj.startDate)) {
				Date startDate = Date.valueOf(wrapperObj.startDate);
				filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Date__c >= :startDate');
			}
			if (string.isNotBlank(wrapperObj.endDate)) {
				Date endDate = Date.valueOf(wrapperObj.endDate).addDays(1);
				filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Date__c < :endDate');
			}
			if (String.isNotBlank(wrapperObj.incidentLocation)) {
				String incidentLocation = String.valueOf(wrapperObj.incidentLocation);
				filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Location__c = :incidentLocation');
			}
			if (string.isNotBlank(wrapperObj.rarNumber)) {
				String rarNumber = String.valueOf(wrapperObj.rarNumber);
				filters.add(LDRReferenceValue + 'CSX_CMP_RAR_Num__c = :rarNumber');
			}
			if (wrapperObj.status != null && !wrapperObj.status.isEmpty()) {
				List<String> statusValues = new List<string>();
				for (String key : wrapperObj.status) {
					if (key != null && String.isNotBlank(Key)) {
						statusValues.add(key);
					}
				}
				if (!statusValues.isEmpty()) {
					filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Status__c IN :statusValues');
				}
			}
			if (string.isNotBlank(wrapperObj.incidentMgr)) {
				String incidentMgr = String.valueOf(wrapperObj.incidentMgr);
				filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Manager__c = :incidentMgr');
			}

			if (String.isNotBlank(wrapperObj.state)) {
				String incidentState = String.valueOf(wrapperObj.state);
				filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Location__r.CSX_CMP_State__c = :incidentState');
			}
			if (String.isNotBlank(wrapperObj.region)) {
				String incidentRegion = String.valueOf(wrapperObj.region);
				filters.add(
					LDRReferenceValue + 'CSX_CMP_Incident_Location__r.CSX_CMP_Operating_Region__c = :incidentRegion'
				);
			}

			//equipment filters
			if (string.isNotBlank(wrapperObj.shipper)) {
				String shipper = String.valueOf(wrapperObj.shipper);
				filters.add(lDRChildReferenceKey + 'CSX_CMP_Shipper__c = :shipper');
			}

			if (string.isNotBlank(wrapperObj.stcc)) {
				String stcc = String.valueOf(wrapperObj.stcc);
				filters.add(lDRChildReferenceKey + 'CSX_CMP_STCC__c=:stcc');
			}

			//String equipmentWhereClause = '';

			/*if (string.isNotBlank(wrapperObj.equipmentInitial) && string.isNotBlank(wrapperObj.equipmentNumber)) {
				String equipmentID =
					String.valueOf(wrapperObj.equipmentInitial) +
					' ' +
					String.valueOf(wrapperObj.equipmentNumber);

				equipmentWhereClause = '(Name = :equipmentID OR CSX_CMP_Flat_Car__c = :equipmentID)';
			} else if (string.isNotBlank(wrapperObj.equipmentInitial)) {
				String equipmentInitial = String.valueOf(wrapperObj.equipmentInitial);
				equipmentWhereClause = '(CSX_CMP_Equipment_Initial__c = :equipmentInitial)';
			} else if (string.isNotBlank(wrapperObj.equipmentNumber)) {
				String equipmentNumber = String.valueOf(wrapperObj.equipmentNumber).leftPad(6, '0');
				equipmentWhereClause = '(CSX_CMP_Equipment_Num__c = :equipmentNumber)';
			}*/

			  //transfer Equipment
           // Set<Id> equipIds = new Set<Id>();
		  
		   String equipQuery = 'Select Name,CSX_CMP_Equipment_Num__c,CSX_CMP_Equipment_Initial__c,CSX_CMP_Shipper__c,CSX_CMP_LD_Report__c,CSX_CMP_STCC__c,CSX_CMP_Consignee__c,CSX_CMP_Flat_Car__c FROM CSX_CMP_Equipment__c WHERE CSX_CMP_LD_Report__c != null';
		   String transferEquipQuery = 'SELECT CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c,CSX_CMP_Transfer_Equipment_Initia__c,CSX_CMP_Transfer_Equipment_Number__c FROM CSX_CMP_Transfer_Equipment__c WHERE CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c != null';
            List<CSX_CMP_Transfer_Equipment__c> transEquipQueryResults = new List<CSX_CMP_Transfer_Equipment__c>();
			List<CSX_CMP_Equipment__c> equipQueryResults = new List<CSX_CMP_Equipment__c>();
            if (string.isNotBlank(wrapperObj.equipmentInitial) && string.isNotBlank(wrapperObj.equipmentNumber)) {
				ldrRecordId.clear();
                String equipmentInitial = String.valueOf(wrapperObj.equipmentInitial);
               // String equipmentNumber = String.valueOf(wrapperObj.equipmentNumber).leftPad(6, '0'); 
			   	String equipmentNumber = String.valueOf(wrapperObj.equipmentNumber);
				equipQuery += ' AND CSX_CMP_Equipment_Initial__c = :equipmentInitial AND CSX_CMP_Equipment_Num__c = :equipmentNumber';
				if(!equipSetId.isEmpty()){
					equipQuery += ' AND Id in :equipSetId';
				}
				if(equipQuery != ''){ 
					equipQueryResults = Database.query(equipQuery);
				}
				
                transferEquipQuery += ' AND CSX_CMP_Transfer_Equipment_Initia__c =: equipmentInitial AND CSX_CMP_Transfer_Equipment_Number__c =: equipmentNumber';
				if(!equipSetId.isEmpty()){
					transferEquipQuery += ' AND CSX_CMP_Equipment__c in :equipSetId';
				}
				if(transferEquipQuery != ''){ 
					transEquipQueryResults = Database.query(transferEquipQuery);
				}
			} else if (string.isNotBlank(wrapperObj.equipmentInitial)) {
				ldrRecordId.clear();
				String equipmentInitial = String.valueOf(wrapperObj.equipmentInitial);
				equipQuery += ' AND CSX_CMP_Equipment_Initial__c = :equipmentInitial';
				if(!equipSetId.isEmpty()){
					equipQuery += ' AND Id in :equipSetId';
				}
				if(equipQuery != ''){ 
					equipQueryResults = Database.query(equipQuery);
				}
				transferEquipQuery += ' AND CSX_CMP_Transfer_Equipment_Initia__c =: equipmentInitial';
				if(!equipSetId.isEmpty()){
					transferEquipQuery += ' AND CSX_CMP_Equipment__c in :equipSetId';
				}
				if(transferEquipQuery != ''){ 
					transEquipQueryResults = Database.query(transferEquipQuery);
				}
			} else if (string.isNotBlank(wrapperObj.equipmentNumber)) {
				ldrRecordId.clear();
				//String equipmentNumber = String.valueOf(wrapperObj.equipmentNumber).leftPad(6, '0'); 
				String equipmentNumber = String.valueOf(wrapperObj.equipmentNumber);
				
				equipQuery += ' AND CSX_CMP_Equipment_Num__c =: equipmentNumber';
				if(!equipSetId.isEmpty()){
					equipQuery += ' AND Id in :equipSetId';
				}
				if(equipQuery != ''){ 
					equipQueryResults = Database.query(equipQuery);
				}
				transferEquipQuery += ' AND CSX_CMP_Transfer_Equipment_Number__c =: equipmentNumber';
				if(!equipSetId.isEmpty()){
					transferEquipQuery += ' AND CSX_CMP_Equipment__c in :equipSetId';
				}
				if(transferEquipQuery != ''){ 
					transEquipQueryResults = Database.query(transferEquipQuery);
				}
			}
				
			if (!equipQueryResults.isEmpty()) {
                for (CSX_CMP_Equipment__c rec : equipQueryResults) {
                    ldrRecordId.add(rec.CSX_CMP_LD_Report__c);
                }
            }

            if (!transEquipQueryResults.isEmpty()) {
                for (CSX_CMP_Transfer_Equipment__c rec : transEquipQueryResults) {
                    ldrRecordId.add(rec.CSX_CMP_Equipment__r.CSX_CMP_LD_Report__c);
                }
            }
			//salvage filters
			if (
				(string.isNotBlank(wrapperObj.salvageAmountFrom) ||
				string.isNotBlank(wrapperObj.salvorName) ||
				string.isNotBlank(wrapperObj.salvageAmountTo)) &&
				(wrapperObj.salvage == 'Yes' || string.isBlank(wrapperObj.salvage))
			) {
				if (string.isNotBlank(wrapperObj.salvageAmountFrom)) {
					Decimal salvageAmountFrom = Decimal.valueOf(wrapperObj.salvageAmountFrom);
					filters.add('CSX_CMP_Salvage_Amount__c >= :salvageAmountFrom');
				}
				if (string.isNotBlank(wrapperObj.salvageAmountTo)) {
					Decimal salvageAmountTo = decimal.valueOf(wrapperObj.salvageAmountTo);
					filters.add('CSX_CMP_Salvage_Amount__c <= :salvageAmountTo');
				}
				if (string.isNotBlank(wrapperObj.salvorName)) {
					String salvorName = String.valueOf(wrapperObj.salvorName);
					filters.add('CSX_CMP_Salvor_Name__c = :salvorName');
				}
			}
			if (filters.size() == 0) {
				if (wrapperObj.salvage == 'Yes' || wrapperObj.salvage == 'No') {
					List<String> statusVal = new List<String>{ 'NEW', 'OPEN', 'IN-PROGRESS', 'COMPLETED', 'CANCELLED' };
					filters.add(LDRReferenceValue + 'CSX_CMP_Incident_Status__c IN :statusVal');
				}
			}

			initialSearchQuery = refKeyQueryMap.get(lDReferenceKey);

			if (filters.size() > 0) {
				initialSearchQuery = initialSearchQuery + ' WHERE ' + String.join(filters, ' AND ');
                if(((string.isNotBlank(wrapperObj.equipmentInitial)) || (string.isNotBlank(wrapperObj.equipmentNumber)))){
                    initialSearchQuery = initialSearchQuery  + ' AND ' + lDRReferenceValue + 'Id in :ldrRecordId';
                }
                
				if (!ldrRecordId.isEmpty() && ldrRecordId != null && ldrRecordId.size() > 0) {
					initialSearchQuery = initialSearchQuery + ' AND ' + lDRReferenceValue + 'Id in :ldrRecordId';
				}
			} else if(!ldrRecordId.isEmpty() && ldrRecordId != null && ldrRecordId.size() > 0){
				//if (!ldrRecordId.isEmpty() && ldrRecordId != null && ldrRecordId.size() > 0) {
					initialSearchQuery = initialSearchQuery;
					initialSearchQuery = initialSearchQuery + ' WHERE ' + lDRReferenceValue + 'Id in :ldrRecordId';
				//}
			}  else if ((string.isNotBlank(wrapperObj.equipmentInitial)) || (string.isNotBlank(wrapperObj.equipmentNumber)) ){
				initialSearchQuery = initialSearchQuery + ' WHERE ' + lDRReferenceValue + 'Id in :ldrRecordId';
			}
			if (filters.size() == 0 && initialSearchQuery == '') {
				resultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
				resultWrapper.status = '200';
			} else {
				initialQueryResults = Database.query(initialSearchQuery);
			}
			if (initialQueryResults.size() > 0) {
				for (sObject rec : initialQueryResults) {
					if (lDReferenceKey == 'salvageLDRReferenceKey') {
						CSX_CMP_Salvage__c obj = (CSX_CMP_Salvage__c) rec;
						lDRIds.add(obj.CSX_CMP_Parent_Equipment__r.CSX_CMP_LD_Report__c);
					} else if (lDReferenceKey == 'equipmenttoLDRReferenceKey') {
						CSX_CMP_Equipment__c obj = (CSX_CMP_Equipment__c) rec;
						lDRIds.add(obj.CSX_CMP_LD_Report__c);
					} else if (lDReferenceKey == 'lDRWhereReferenceKey') {
						CSX_CMP_LD_Report__c obj = (CSX_CMP_LD_Report__c) rec;
						lDRIds.add(obj.Id);
					}
				}

				if (!lDRIds.isEmpty()) {
					lDRReportQuery += ' WHERE Id in:lDRIds';
					finalResults = Database.query(lDRReportQuery);
				}
				ldrResponseWrapper = CSX_CMP_LDRSearchController.fetchFullLDRDetails(
					lDRIds,
					wrapperObj.salvage,
					wrapperObj.salvageAmountFrom,
					wrapperObj.salvageAmountTo,
					wrapperObj.salvorName
				);
			} else {
				resultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
				resultWrapper.status = '200';
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRSearchController', 'getLdrRecords', ldrSearchParameters, e);
			resultWrapper.status = '400';
			resultWrapper.errorMessage = e.getMessage();
		}

		if (!ldrResponseWrapper.isEmpty()) {
			resultWrapper.status = '200';
			resultWrapper.results = ldrResponseWrapper;
		} else {
			resultWrapper.results = ldrResponseWrapper;
			resultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
			resultWrapper.status = '200';
		}
		return resultWrapper;
	}

	public static List<LdrSearchResponseWrapper> fetchFullLDRDetails(
		Set<Id> ldrIds,
		String salvage,
		String salvageAmountFrom,
		string salvageAmountTo,
		string salvorName
	) {
		try {
			List<CSX_CMP_LD_Report__c> ldReportList = new List<CSX_CMP_LD_Report__c>();
			List<LdrSearchResponseWrapper> ldrdataList = new List<LdrSearchResponseWrapper>();

			ldReportList = [
				SELECT
					Name,
					CSX_CMP_Incident_Comments__c,
					CSX_CMP_Bad_Order_Comments__c,
					CSX_CMP_Reported_Date__c,
					CSX_CMP_Incident_Manager__r.Email,
					CSX_CMP_Track_ID__c,
					CSX_CMP_Source__c,
					CSX_CMP_Cause__c,
					CSX_CMP_Incident_Manager__r.Name,
					CSX_CMP_Incident_Action__c,
					CSX_CMP_Damage_Reason__c,
					Id,
					CSX_CMP_RAR_Num__c,
					CSX_CMP_Incident_Date__c,
					CSX_CMP_ECM_Link__c,
					CSX_CMP_Incident_State__c,
					CSX_CMP_Incident_Location__r.Name,
					CSX_CMP_Incident_Location__r.CSX_CMP_Operating_Region__c,
					CSX_CMP_Incident_Status__c,
					CSX_CMP_LD_Type__c,
					CSX_CMP_Reported_By_Lookup__r.Name,
					CSX_CMP_Reported_By_Lookup__r.Phone,
					CSX_CMP_Reported_By_Lookup__r.Email,
					CSX_CMP_Completed_Date__c,
					CSX_CMP_Reported_By__c,
					(
						SELECT
							Id,
							CSX_CMP_Salvage_Count__c,
							CSX_CMP_Waybill_Date__c,
							CSX_CMP_STCC_Description__c,
							CSX_CMP_LD_Report__c,
							CSX_CMP_Equipment_Summary_Report__c,
							Name,
							CSX_CMP_Shipper__c,
							CSX_CMP_Consignee__c,
							CSX_CMP_STCC__c
						FROM Equipments__r
					),
					(
						SELECT
							CSX_CMP_Contact_Role__c,
							CreatedDate,
							CSX_CMP_Email__c,
							Name,CSX_CMP_Contact_Name__c,
							CSX_CMP_Phone_Number__c
						FROM L_D_Contacts__r ORDER BY CreatedDate 
					)
				
				FROM CSX_CMP_LD_Report__c
				WHERE Id IN :ldrIds WITH SECURITY_ENFORCED
			];

			for (CSX_CMP_LD_Report__c ldData : ldReportList) {
				LdrSearchResponseWrapper ldresWrapper = new LdrSearchResponseWrapper();

				if (String.isNotBlank(ldData.Name)) {
					ldresWrapper.reportNumber = ldData.Name;
				}

				if (String.isNotBlank(ldData.CSX_CMP_ECM_Link__c)) {
					ldresWrapper.documentLink = ldData.CSX_CMP_ECM_Link__c;
				}

				if (String.isNotBlank(ldData.Id)) {
					ldresWrapper.ldrID = ldData.Id;
				}

				if (String.isNotBlank(ldData.CSX_CMP_Damage_Reason__c)) {
					ldresWrapper.damageReason = ldData.CSX_CMP_Damage_Reason__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_RAR_Num__c)) {
					ldresWrapper.rarNumber = ldData.CSX_CMP_RAR_Num__c;
				}

				if (ldData.CSX_CMP_Incident_Date__c != null) {
					ldresWrapper.incidentDate = ldData.CSX_CMP_Incident_Date__c;
				}

				if (String.isNotBlank(ldData.CSX_CMP_Incident_Location__r.Name)) {
					ldresWrapper.incidentLocation = ldData.CSX_CMP_Incident_Location__r.Name;
				}

				if (String.isNotBlank(ldData.CSX_CMP_Incident_Location__r.CSX_CMP_Operating_Region__c)) {
					ldresWrapper.incidentRegion = ldData.CSX_CMP_Incident_Location__r.CSX_CMP_Operating_Region__c;
				}

				if (String.isNotBlank(ldData.CSX_CMP_Incident_Status__c)) {
					ldresWrapper.status = ldData.CSX_CMP_Incident_Status__c;
				}

				if (ldData.CSX_CMP_Completed_Date__c != null) {
					ldresWrapper.completedDate = ldData.CSX_CMP_Completed_Date__c;
				}

				
				if (ldData.L_D_Contacts__r != null && !ldData.L_D_Contacts__r.isEmpty()) {
					
					//CSX_CMP_LD_Contact__c ldContact = ldData.L_D_Contacts__r;
					//[MR-00972] changes start
					List<String> contactRole = new List<String>();

				/*	if(String.isNotBlank(ldContact.CSX_CMP_Contact_Role__c)){
						contactRole=ldContact.CSX_CMP_Contact_Role__c;
					} */
				for(CSX_CMP_LD_Contact__c ldContacts : ldData.L_D_Contacts__r){
					
					if( (string.isNotBlank(ldData.CSX_CMP_Source__c) && ( ldData.CSX_CMP_Source__c=='MTI' || ldData.CSX_CMP_Source__c=='ShipCSX') || ( ldData.CSX_CMP_Source__c=='Manual' && ldData.CSX_CMP_LD_Type__c=='Customer') ) && ldContacts.CSX_CMP_Contact_Role__c=='L&D Contacts' ){
						
							if (string.isNotBlank(ldContacts.CSX_CMP_Phone_Number__c)) {
								ldresWrapper.contactPhone = ldContacts.CSX_CMP_Phone_Number__c;
							}
							if (string.isNotBlank(ldContacts.CSX_CMP_Contact_Name__c)) {
								ldresWrapper.contactName = ldContacts.CSX_CMP_Contact_Name__c;
							}
							if (string.isNotBlank(ldContacts.CSX_CMP_Email__c)) {
								ldresWrapper.contactEmail = ldContacts.CSX_CMP_Email__c;
						}
					}
					 else if (string.isNotBlank(ldData.CSX_CMP_Source__c) && ldData.CSX_CMP_Source__c=='Manual' && ldData.CSX_CMP_LD_Type__c=='In transit' && ldContacts.CSX_CMP_Contact_Role__c=='ReportedBy' ){	
						
							if (string.isNotBlank(ldContacts.CSX_CMP_Phone_Number__c)) {
								ldresWrapper.contactPhone = ldContacts.CSX_CMP_Phone_Number__c;
							}
							if (string.isNotBlank(ldContacts.CSX_CMP_Contact_Name__c)) {
								ldresWrapper.contactName = ldContacts.CSX_CMP_Contact_Name__c;
							}
							if (string.isNotBlank(ldContacts.CSX_CMP_Email__c)) {
								ldresWrapper.contactEmail = ldContacts.CSX_CMP_Email__c;
							}	
					}
					else{
						
						if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Name)) {
							ldresWrapper.contactName = ldData.CSX_CMP_Reported_By_Lookup__r.Name;
						}
						if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Phone)) {
							ldresWrapper.contactPhone = ldData.CSX_CMP_Reported_By_Lookup__r.Phone;
						}
						if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Email)) {
							ldresWrapper.contactEmail = ldData.CSX_CMP_Reported_By_Lookup__r.Email;
						}
					}
				}
					//[MR-00972] changes End
				}
				
				if (ldData.L_D_Contacts__r == null || ldData.L_D_Contacts__r.isEmpty()) {
					
					if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Name)) {
						ldresWrapper.contactName = ldData.CSX_CMP_Reported_By_Lookup__r.Name;
					}
					if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Phone)) {
						ldresWrapper.contactPhone = ldData.CSX_CMP_Reported_By_Lookup__r.Phone;
					}
					if (string.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Email)) {
						ldresWrapper.contactEmail = ldData.CSX_CMP_Reported_By_Lookup__r.Email;
					}
				}
				if (String.isNotBlank(ldData.CSX_CMP_Reported_By_Lookup__r.Name)) {
					ldresWrapper.reportedBy = ldData.CSX_CMP_Reported_By_Lookup__r.Name;
				}
				if (ldData.CSX_CMP_Reported_Date__c != null) {
					ldresWrapper.reportedDate = ldData.CSX_CMP_Reported_Date__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Track_ID__c)) {
					ldresWrapper.trackId = ldData.CSX_CMP_Track_ID__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Cause__c)) {
					ldresWrapper.cause = ldData.CSX_CMP_Cause__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Incident_Manager__r.Name)) {
					ldresWrapper.incidentManager = ldData.CSX_CMP_Incident_Manager__r.Name;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Incident_Manager__r.Email)) {
					ldresWrapper.incidentManagerEmail = ldData.CSX_CMP_Incident_Manager__r.Email;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Incident_Action__c)) {
					ldresWrapper.incidentAction = ldData.CSX_CMP_Incident_Action__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Bad_Order_Comments__c)) {
					ldresWrapper.badOrderComments = ldData.CSX_CMP_Bad_Order_Comments__c;
				}
				if (String.isNotBlank(ldData.CSX_CMP_Incident_Comments__c)) {
					ldresWrapper.incidentComments = ldData.CSX_CMP_Incident_Comments__c;
				}

				ldresWrapper.salvageCount = 0;
				if (ldData.Equipments__r != null && !ldData.Equipments__r.isEmpty()) {
					List<EquipmentWrapper> equipmentWrapList = new List<EquipmentWrapper>();
					for (CSX_CMP_Equipment__c equip : ldData.Equipments__r) {
						if (String.isNotBlank(equip.Name)) {
							if (String.isNotBlank(ldresWrapper.equipmentName)) {
								ldresWrapper.equipmentName += ', ' + equip.Name;
							} else {
								ldresWrapper.equipmentName = equip.Name;
							}
						}
						if (equip.CSX_CMP_Salvage_Count__c != null) {
							ldresWrapper.salvageCount += equip.CSX_CMP_Salvage_Count__c;
						}

						EquipmentWrapper equWrap = new EquipmentWrapper();
						equWrap.equipmentId = equip.Id;
						equWrap.equipmentName = equip.Name;
						equWrap.stcc = equip.CSX_CMP_STCC__c;
						equWrap.consignee = equip.CSX_CMP_Consignee__c;
						equWrap.shipper = equip.CSX_CMP_Shipper__c;
						equWrap.waybillDate = equip.CSX_CMP_Waybill_Date__c;
						equWrap.stccDescription = equip.CSX_CMP_STCC_Description__c;
						/*  if(equip.Id!=null){
                        equWrap.equipmentSummaryReport=CSX_CMP_LD_Report.generateAndSavePDF(equip.Id);
                        }*/
						equipmentWrapList.add(equWrap);
					}
					ldresWrapper.equipment = equipmentWrapList;
				}
				ldrdataList.add(ldresWrapper);
			}

			List<LdrSearchResponseWrapper> ldrdataFinalList = new List<LdrSearchResponseWrapper>();
			for (LdrSearchResponseWrapper ldrResponse : ldrdataList) {
				if (salvage == 'No') {
					if (ldrResponse.salvageCount == 0) {
						ldrdataFinalList.add(ldrResponse);
					}
				} else {
					ldrdataFinalList.add(ldrResponse);
				}
			}
			return ldrdataFinalList;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimSearchController',
				'fetchFullClaimDetails',
				'Search',
				e
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class LDRSearchRequestWrapper {
		public String shipper { get; set; }
		public String state { get; set; }
		public String region { get; set; }
		public String reportNumber { get; set; }
		public String reportType { get; set; }
		public String startDate { get; set; }
		public String endDate { get; set; }
		public String incidentMgr { get; set; }
		public String incidentLocation { get; set; }
		public String rarNumber { get; set; }
		public List<String> status { get; set; }
		public String equipmentInitial { get; set; }
		public String equipmentNumber { get; set; }
		public String vinNumber { get; set; }
		public String stcc { get; set; }
		public String salvage { get; set; }
		public String salvorName { get; set; }
		public String salvageAmountFrom { get; set; }
		public String salvageAmountTo { get; set; }
	}

	public class EquipmentWrapper {
		@AuraEnabled
		public String equipmentId { get; set; }
		@AuraEnabled
		public String equipmentName { get; set; }
		@AuraEnabled
		public string stcc { get; set; }
		@AuraEnabled
		public String consignee { get; set; }
		@AuraEnabled
		public String shipper { get; set; }
		@AuraEnabled
		public String equipmentSummaryReport { get; set; }
		@AuraEnabled
		public String stccDescription { get; set; }
		@AuraEnabled
		public Date waybillDate { get; set; }
	}

	public class LdrSearchResponseWrapper {
		@AuraEnabled
		public list<EquipmentWrapper> equipment; //equipment
		@AuraEnabled
		public String reportNumber { get; set; }
		@AuraEnabled
		public Decimal salvageCount { get; set; }
		@AuraEnabled
		public String damageReason { get; set; }
		@AuraEnabled
		public String ldrID { get; set; }
		@AuraEnabled
		public String documentLink { get; set; }
		@AuraEnabled
		public String rarNumber { get; set; }
		@AuraEnabled
		public Date incidentDate { get; set; }
		@AuraEnabled
		public String incidentLocation { get; set; }
		@AuraEnabled
		public String incidentRegion { get; set; }
		@AuraEnabled
		public String equipmentId { get; set; }
		@AuraEnabled
		public String equipmentName { get; set; }
		@AuraEnabled
		public String status { get; set; }
		@AuraEnabled
		public Date completedDate { get; set; }
		@AuraEnabled
		public String reportedBy { get; set; }
		@AuraEnabled
		public Date reportedDate { get; set; }
		@AuraEnabled
		public String trackId { get; set; }
		@AuraEnabled
		public String cause { get; set; }
		@AuraEnabled
		public String incidentManager { get; set; }
		@AuraEnabled
		public String incidentManagerEmail { get; set; }
		@AuraEnabled
		public String incidentAction { get; set; }
		@AuraEnabled
		public String contactName { get; set; }
		@AuraEnabled
		public String contactPhone { get; set; }
		@AuraEnabled
		public String contactEmail { get; set; }
		@AuraEnabled
		public String badOrderComments { get; set; }
		@AuraEnabled
		public String incidentComments { get; set; }
	}

	public class CityStateWrapper {
		@AuraEnabled
		public List<String> state { get; set; }
		@AuraEnabled
		public List<String> region { get; set; }
	}

	global class LdrSearchResultWrapper {
		@AuraEnabled
		public string status;
		@AuraEnabled
		public string errorMessage;
		@AuraEnabled
		public list<LdrSearchResponseWrapper> results;
	}
}