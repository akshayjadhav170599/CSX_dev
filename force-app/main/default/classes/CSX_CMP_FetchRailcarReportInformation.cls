/*
RICEF ID : CMP-E-1743
@author : Infosys
@description : This class is used to fetch the railcar report information which needs to be sent to Custmomer Service Org.
Modification Log:
Ver   Date           Author            Modification
1.0   08/08/2024     Infosys           Initial Version
*/
@RestResource(urlMapping='/v1/railcarreport/*')
global with sharing class CSX_CMP_FetchRailcarReportInformation {
	@HttpGet
	global static void fetchDetails() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		ResponseWrapper responseWrapper = new ResponseWrapper();
		try {
			req = RestContext.request;
			res = RestContext.response;

			Boolean isValid = true;
			String errorMessage = '';
			String recordId = '';
			recordId = req.params.get('recordId');

			if (String.isBlank(recordId)) {
				isValid = false;
				errorMessage = 'recordId is mandatory';
			} else if (!recordId.contains('_')) {
				isValid = false;
				errorMessage = 'recordId should be in the format of LDRName_EquipmentName';
			}
			

			if (isValid) {
				String ldrName = req.params.get('recordId').substringBefore('_');
				String equipmentName1 = req.params.get('recordId').substringAfter('_');
				String equipmentName = equipmentName1.replaceAll('([A-Za-z]+)([0-9]+)', '$1 $2');
				CSX_CMP_LD_Report__c ldReport;
				CSX_CMP_Equipment__c equipment;
				try {
					ldReport = [
						SELECT
							Id,
							Name,
							CSX_CMP_Incident_Manager__r.Name,
							CSX_CMP_Incident_Status__c,
							(
								SELECT Id, CreatedBy.Name, CreatedDate, lastModifiedDate, CSX_CMP_Notes__c
								FROM Notes__r
								WHERE CSX_CMP_Note_Type__c = 'Comment'
							)
						FROM CSX_CMP_LD_Report__c
						WHERE Name = :ldrName
						WITH SECURITY_ENFORCED
						LIMIT 1
					];
				} catch (Exception e) {
					res.responseBody = Blob.valueOf('No LD Report found for the given recordId');
					res.statusCode = 400;
					CSX_CMP_LoggerUtility.addIntegrationErrorLog('No LD Report found for the given recordId', 'Fetch Railcar Report Information', req.requestURI.toString(), '');
					return;
				}
				try {
					equipment = [
						SELECT
							Id,
							(
								SELECT Id, CreatedBy.Name, CreatedDate, lastModifiedDate, CSX_CMP_Notes__c
								FROM Notes__r
								WHERE CSX_CMP_Note_Type__c = 'Comment'
							)
						FROM CSX_CMP_Equipment__c
						WHERE Name = :equipmentName AND CSX_CMP_LD_Report__r.Name = :ldrName
						WITH SECURITY_ENFORCED
						LIMIT 1
					];
				} catch (Exception e) {
					
					res.responseBody = Blob.valueOf('No Equipment found for the given recordId');
					res.statusCode = 400;
					CSX_CMP_LoggerUtility.addIntegrationErrorLog('No Equipment found for the given recordId', 'Fetch Railcar Report Information', req.requestURI.toString(), '');
					return;
				}
				if (ldReport != null) {
					responseWrapper.ldReport = ldReport.Name;
					responseWrapper.incidentStatus = ldReport.CSX_CMP_Incident_Status__c;
					responseWrapper.incidentManagerName = ldReport.CSX_CMP_Incident_Manager__r.Name;
					List<Notes> notesList = new List<Notes>();
					for (CSX_CMP_Notes__c note : ldReport.Notes__r) {
						Notes notes = new Notes();
						notes.note = note.CSX_CMP_Notes__c;
						notes.createdDate = String.valueOf(note.CreatedDate);
						notes.lastModifiedDate = String.valueOf(note.lastModifiedDate);
						notes.createdBy = note.CreatedBy.Name;
						notesList.add(notes);
					}
					responseWrapper.finalNotes = notesList;
					res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
					res.statusCode = 200;
				} else {
					res.responseBody = Blob.valueOf('No LD Report found for the given recordId');
					res.statusCode = 400;
					CSX_CMP_LoggerUtility.addIntegrationErrorLog('No LD Report found for the given recordId', 'Fetch Railcar Report Information', req.requestURI.toString(), '');
					return;
				}

				if (equipment != null) {
					if (!equipment.Notes__r.isEmpty()) {
						List<Notes> notesList = new List<Notes>();
						for (CSX_CMP_Notes__c note : equipment.Notes__r) {
							Notes notes = new Notes();
							notes.note = note.CSX_CMP_Notes__c;
							notes.createdDate = String.valueOf(note.CreatedDate);
							notes.lastModifiedDate = String.valueOf(note.lastModifiedDate);
							notes.createdBy = note.CreatedBy.Name;
							notesList.add(notes);
						}
						responseWrapper.finalNotes.addAll(notesList);
					}
					res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
					res.statusCode = 200;
				} else {
					res.responseBody = Blob.valueOf('No Equipment found for the given recordId');
					res.statusCode = 400;
					CSX_CMP_LoggerUtility.addIntegrationErrorLog('No Equipment found for the given recordId', 'Fetch Railcar Report Information', req.requestURI.toString(), '');
					return;
				}
			} else {
				res.responseBody = Blob.valueOf(errorMessage);
				res.statusCode = 400;
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(errorMessage, 'Fetch Railcar Report Information', req.requestURI.toString(), '');
				return;
			}

		} catch (Exception e) {
			res.responseBody = Blob.valueOf(e.getMessage());
			res.statusCode = 500;
			CSX_CMP_LoggerUtility.addIntegrationErrorLog('Error fetching Document', 'Fetch Railcar Report Information', req.requestURI.toString(), '');
		}
	}

	public class ResponseWrapper {
		public String ldReport;
		public String incidentStatus;
		public String incidentManagerName;
		public List<Notes> finalNotes;
	}

	public class Notes {
		public String note;
		public String createdDate;
		public String createdBy;
		public String lastModifiedDate;
	}
}