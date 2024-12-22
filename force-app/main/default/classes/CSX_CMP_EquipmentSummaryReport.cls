/**
@Author       - Infosys
@Name         - CSX_CMP_EquipmentSummaryReport
RICEFW #      - CMP-R-0443
@Created Date - 03/06/2024
@Description  - This class is used to generate the Equipment Summary Report for the Equipment record.
*/
public with sharing class CSX_CMP_EquipmentSummaryReport {
	public EquipmentSummaryReportWrapper wrapper { get; set; }
	public  string csxLogo {get; set;}
	/* @description - This is the constructor of the class which is used to fetch the Equipment Summary Report details.*/

	public CSX_CMP_EquipmentSummaryReport(ApexPages.StandardController controller) {
		wrapper = new EquipmentSummaryReportWrapper();
		csxLogo = CSX_CMP_Utility.logoUrl();
		Id equipmentId = controller.getId();
		if (equipmentId != null) {
			List<CSX_CMP_Equipment__c> equipmentRecord = getEquipmentDetails(new List<Id>{ equipmentId });
			Map<String, List<CSX_CMP_Notes__c>> equipmentToNotesMap = getNotesOfLDReport(equipmentRecord);			
			wrapper = fetchLDReport(
				equipmentRecord[0],
				equipmentToNotesMap.get(equipmentId)			
			);
		}
	}

	/*
@description - This method is used to fetch the Equipment details.
@param equipmentIds - List of Equipment Ids.
@return - List of Equipment records.
*/

	public static List<CSX_CMP_Equipment__c> getEquipmentDetails(List<Id> equipmentIds) {
		try {
			List<CSX_CMP_Equipment__c> equipmentRecord = [
				SELECT
					Name,
					CSX_CMP_Waybill_Num__c,
					CSX_CMP_Waybill_Date__c,
					CSX_CMP_Shipper__c,
					CSX_CMP_Act_Origin_City__c,
					CSX_CMP_Act_Origin_State__c,
					CSX_CMP_Act_Destination_City__c,
					CSX_CMP_Act_Destination_State__c,
					CSX_CMP_Consignee__c,
					CSX_CMP_STCC__c,
					CSX_CMP_STCC_Description__c,
					CSX_CMP_LD_Report__r.name,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_Manager__r.Name,
					CSX_CMP_LD_Report__r.CSX_CMP_Disposition__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Damage_Location__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_Date__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Reported_By__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_Comments__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Damage_Reason__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Cause__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_Action__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Product_Condition__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_State__c,
					CSX_CMP_LD_Report__r.CSX_CMP_Incident_Location__r.Name,
					(
						SELECT
							id,
							Name,
							CSX_CMP_Transfer_Equipment_Number__c,
							CSX_CMP_Transfer_Equipment_Initia__c,
							CSX_CMP_Transfer_Seal_Number__c
						FROM Transfer_Equipment__r
					),
					(SELECT CSX_CMP_Notes__c, CreatedDate, CreatedBy.Name FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Comment'),
					(
						SELECT
							Id,
							CSX_CMP_VIN__c,
							CSX_CMP_Quantity__c,
							CSX_CMP_Product_Description__c,
							CSX_CMP_UOM__c,
							CSX_CMP_Product_Amount__c,
							CSX_CMP_Unit_Price__c
						FROM Products__r
					)
				FROM CSX_CMP_Equipment__c
				WHERE Id IN :equipmentIds WITH SECURITY_ENFORCED
				
			];
			return equipmentRecord;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EquipmentSummaryReport', 'getEquipmentDetails', '', e);
			return null;
		}
	}

	/*
@description - This method is used to fetch the Notes of the LD Report.
@param equipmentList - List of Equipment records.
@return - Map of Equipment Id and List of Notes.
*/
	public static Map<String, List<CSX_CMP_Notes__c>> getNotesOfLDReport(List<CSX_CMP_Equipment__c> equipmentList) {
		try {
			Map<String, List<CSX_CMP_Notes__c>> response = new Map<String, List<CSX_CMP_Notes__c>>();
			Map<String, String> equipToLDRMap = new Map<String, String>();
			// Map<String, String> equipToTransferEquipMap = new Map<String, String>();
			Set<String> equipToTransferEquipMap = new Set<String>();
			for (CSX_CMP_Equipment__c equip : equipmentList) {
				equipToLDRMap.put(equip.CSX_CMP_LD_Report__c, equip.Id);
				// equipToTransferEquipMap.put(equip.Id, equip.Id);
				equipToTransferEquipMap.add(equip.Id);
			}

			Map<Id, CSX_CMP_Transfer_Equipment__c> transferEquipMap = new Map<Id, CSX_CMP_Transfer_Equipment__c>([SELECT Id, CSX_CMP_Equipment__c FROM CSX_CMP_Transfer_Equipment__c WHERE CSX_CMP_Equipment__c IN : equipToTransferEquipMap WITH SECURITY_ENFORCED]);

			List<CSX_CMP_Notes__c> relatedNotes = [
				SELECT CSX_CMP_Notes__c, CSX_CMP_Transfer_Equipment__c, CSX_CMP_LD_Report__c, CreatedDate, CreatedBy.Name
				FROM CSX_CMP_Notes__c
				WHERE
					CSX_CMP_Note_Type__c = 'Comment'
					AND (CSX_CMP_LD_Report__c IN :equipToLDRMap.keySet()
					OR CSX_CMP_Transfer_Equipment__c IN :transferEquipMap.keySet()) WITH SECURITY_ENFORCED
					
				ORDER BY CreatedDate DESC 		
			];
			
			if (!relatedNotes.isEmpty()) {
				for (CSX_CMP_Notes__c note : relatedNotes) {
					if (response.containsKey(equipToLDRMap.get(note.CSX_CMP_LD_Report__c))) {
						response.get(equipToLDRMap.get(note.CSX_CMP_LD_Report__c)).add(note);
					} else {
						response.put(equipToLDRMap.get(note.CSX_CMP_LD_Report__c), new List<CSX_CMP_Notes__c>{ note });
					}
					
					if(transferEquipMap.containsKey(note.CSX_CMP_Transfer_Equipment__c)){
						if (response.containsKey(transferEquipMap.get(note.CSX_CMP_Transfer_Equipment__c).CSX_CMP_Equipment__c)) {
							response.get(transferEquipMap.get(note.CSX_CMP_Transfer_Equipment__c).CSX_CMP_Equipment__c).add(note);
						} else {
							response.put(
								transferEquipMap.get(note.CSX_CMP_Transfer_Equipment__c).CSX_CMP_Equipment__c,
								new List<CSX_CMP_Notes__c>{ note }
							);
						}
					}
					
				}
              
			}

			return response;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EquipmentSummaryReport', 'getNotesOfLDReport', '', e);
			return null;
		}
	}
	
	/*
@description - This method is used to fetch the Equipment Summary Report details.
@param equipmentRecord - Equipment record.
@param notesFromLDReport - List of Notes.
@return - EquipmentSummaryReportWrapper.
*/ 
	private EquipmentSummaryReportWrapper fetchLDReport(
		CSX_CMP_Equipment__c equipmentRecord,
		List<CSX_CMP_Notes__c> notesFromLDReport // List<CSX_CMP_Notes__c> notesFromTransferEquipment
	) {
		EquipmentSummaryReportWrapper equipmentWrapper = new EquipmentSummaryReportWrapper();
		try {
			if (equipmentRecord != null) {
				equipmentWrapper.equipment = equipmentRecord;
				equipmentWrapper.incidentManagerName = equipmentRecord.CSX_CMP_LD_Report__r.CSX_CMP_Incident_Manager__r.Name;
				equipmentWrapper.cityname = equipmentRecord.CSX_CMP_LD_Report__r.CSX_CMP_Incident_Location__r.Name;
				if (equipmentRecord.CSX_CMP_LD_Report__r != null) {
					equipmentWrapper.ldReport = equipmentRecord.CSX_CMP_LD_Report__r;
				}
				if (!equipmentRecord.Products__r.isEmpty()) {
					equipmentWrapper.relatedProducts = equipmentRecord.Products__r;
				}
				if (!equipmentRecord.Transfer_Equipment__r.isEmpty()) {
					equipmentWrapper.transferEquipment = equipmentRecord.Transfer_Equipment__r;
				}
				equipmentWrapper.finalNotes = new List<CSX_CMP_Notes__c>();
				if (!equipmentRecord.Notes__r.isEmpty()) {
					equipmentWrapper.finalNotes.addAll(equipmentRecord.Notes__r);
				}
				if (notesFromLDReport != null && !notesFromLDReport.isEmpty()) {
					equipmentWrapper.finalNotes.addAll(notesFromLDReport);
				}

				if(!equipmentWrapper.finalNotes.isEmpty()){
					equipmentWrapper.finalNotes.sort();
				}
               /* finalNotes.sort(new Comparator<CSX_CMP_Notes__c>() {
                    public Integer compare(CSX_CMP_Notes__c a, CSX_CMP_Notes__c b) {
                        return b.CreatedDate.compareTo(a.CreatedDate);
                    }
                });*/
				// if (notesFromTransferEquipment != null && !notesFromTransferEquipment.isEmpty()) {
				// 	equipmentWrapper.finalNotes.addAll(notesFromTransferEquipment);
				// }
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EquipmentSummaryReport', 'getNotesOfLDReport', '', e);
		}
		return equipmentWrapper;
	}

	/*
@description - This method is used to generate and save the PDF.
@param id - Equipment Id.
*/
	public static void generateAndSavePDF(String id) {
		try {
			PageReference pdfPageRef = Page.CSX_CMP_EquipmentSummaryReport;
			pdfPageRef.getParameters().put('id', id);

			String encodedPDF;
			if (Test.isRunningTest()) {
				encodedPDF = 'Test';
			} else {
				Blob pdfBlob = pdfPageRef.getContentAsPDF();
				encodedPDF = EncodingUtil.base64Encode(pdfBlob);
			}
			String equipmentQuery = 'SELECT Id, CSX_CMP_Equipment_Summary_Report__c FROM CSX_CMP_Equipment__c WHERE Id = :id LIMIT 1';
			CSX_CMP_Equipment__c equipment = Database.query(equipmentQuery);
			equipment.CSX_CMP_Equipment_Summary_Report__c = encodedPDF;
			Database.SaveResult result = Database.update(equipment, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_EquipmentSummaryReport', 'generateAndSavePDF', result, 'CSX_CMP_Equipment__c');
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EquipmentSummaryReport', 'generateAndSavePDF', id, e);
		}
	}

	public class EquipmentSummaryReportWrapper {
		public List<CSX_CMP_Product__c> relatedProducts { get; set; }
		public List<CSX_CMP_Transfer_Equipment__c> transferEquipment { get; set; }
		public List<CSX_CMP_Notes__c> finalNotes { get; set; }
		public CSX_CMP_LD_Report__c ldReport { get; set; }
		public CSX_CMP_Equipment__c equipment { get; set; }
		public String incidentManagerName { get; set; }
		public String cityName { get; set; }
	}
}