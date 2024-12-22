/*
@author : Infosys
@name : CSX_CMP_LetterGenerationController
@description : This class is used to generate Letters(Declination,Recharge, summary) and link it to the parent object
RICEFW Id : CMP-E-0493
*/
public with sharing class CSX_CMP_LetterGenerationController {
	/*
    @description : This method is used to generate recharge letters
    @param : recordIds - List of Case Ids
    */
	@AuraEnabled
	public static Boolean checkNoteOnClaim(List<Id> claimId) {
		Boolean hasNoteWithDNSDL = true;

		List<Case> declinedClaims = [
			SELECT Id, (SELECT Id FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Do not send Decline Letter')
			FROM Case
			WHERE Id IN :claimId
			WITH SECURITY_ENFORCED
		];

		if (!declinedClaims.isEmpty()) {
			for (Case claim : declinedClaims) {
				if (claim.Notes__r.isempty()) {
					hasNoteWithDNSDL = false;
				}
			}
		}

		return hasNoteWithDNSDL;
	}
	@AuraEnabled
	public static void generateLetters(List<Id> recordIds, String vfPageNameDec) {
		List<ContentVersion> cvList = new List<ContentVersion>();
		List<Id> listOfIds = new List<Id>();
		Case claim = [
			SELECT Id, CaseNumber, CSX_CMP_Case_Number_Formula__c
			FROM Case
			WHERE Id IN :recordIds
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		Integer count = 0;
		List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
		String title;
		String fileNameDec;
		boolean isUpdate = false;
		PageReference pdfPage;

		try {
			List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
			contentDocLinks = [
				SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility
				FROM ContentDocumentLink
				WHERE id != NULL AND LinkedEntityId IN :recordIds
				WITH SECURITY_ENFORCED
			];
			Map<String, List<String>> contentDocLinkMap = new Map<String, List<String>>();
			if (!contentDocLinks.isEmpty()) {
				for (ContentDocumentLink contentDoc : contentDocLinks) {
					if (contentDocLinkMap.containsKey(contentDoc.LinkedEntityId)) {
						contentDocLinkMap.get(contentDoc.LinkedEntityId).add(contentDoc.ContentDocumentId);
					} else {
						contentDocLinkMap.put(contentDoc.LinkedEntityId, new List<String>{ contentDoc.ContentDocumentId });
					}
				}
			}

			switch on vfPageNameDec {
				when 'CSX_CMP_RechargeLetterpage' {
					generateRechargeLetters(recordIds, contentDocLinkMap);
				}
				when 'CSX_CMP_FreightDeclineLetter' {
					title = 'FreightDeclineLetter_';
					fileNameDec = 'FreightDeclineLetter.pdf';
					pdfPage = Page.CSX_CMP_FreightDeclineLetter;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_ContractRefundDeclineLetter' {
					title = 'RevenueContractDeclineLetter_';
					fileNameDec = 'RevenueContractDeclineLetter.pdf';
					pdfPage = Page.CSX_CMP_ContractRefundDeclineLetter;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_OverchargeDeclineLetter' {
					title = 'RevenueOverchargeDeclineLetter_';
					fileNameDec = 'RevenueOverchargeDeclineLetter.pdf';
					pdfPage = Page.CSX_CMP_OverchargeDeclineLetter;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_RevenueRailroadDeclineLetter' {
					title = 'RevenueRailroadDeclineLetter_';
					fileNameDec = 'RevenueRailroadDeclineLetter.pdf';
					pdfPage = Page.CSX_CMP_RevenueRailroadDeclineLetter;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_FreightClaimSummary' {
					title = 'FreightClaimSummary_';
					fileNameDec = 'FreightClaimSummary.pdf';
					pdfPage = Page.CSX_CMP_FreightClaimSummary;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_OverchargeSummaryReport' {
					title = 'OverchargeClaimSummary_';
					fileNameDec = 'OverchargeClaimSummary.pdf';
					pdfPage = Page.CSX_CMP_OverchargeSummaryReport;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_RevenueRRSummaryReport' {
					title = 'revenueRRClaimSummary_';
					fileNameDec = 'RevenueClaimSummary.pdf';
					pdfPage = Page.CSX_CMP_RevenueRRSummaryReport;
					pdfPage.getParameters().put('id', claim.Id);
				}
				when 'CSX_CMP_ContractRefundSummary' {
					title = 'contractRefundClaimSummary_';
					fileNameDec = 'contractRefundClaimSummary.pdf';
					pdfPage = Page.CSX_CMP_ContractRefundSummary;
					pdfPage.getParameters().put('id', claim.Id);
				}
			}
			Blob pdfBlob;
			if (!system.Test.isRunningTest() && vfPageNameDec != 'CSX_CMP_RechargeLetterpage') {
				pdfBlob = pdfPage.getContentAsPDF();
			}

			if (vfPageNameDec != 'CSX_CMP_RechargeLetterpage') {
				List<ContentVersion> contentVersionList = new List<ContentVersion>();
				if (!contentDocLinkMap.isEmpty()) {
					contentVersionList = [
						SELECT Id, ContentDocumentId, Title
						FROM ContentVersion
						WHERE ContentDocumentId IN :contentDocLinkMap.get(claim.Id)
						WITH SECURITY_ENFORCED
					];
				}

				ContentVersion contentVersion = getContentVersion(contentVersionList, claim, title);
				if (contentVersion.Id != null) {
					count++;
					isUpdate = true;
				}
				String fileData = title + /*claim.CaseNumber*/ claim.CSX_CMP_Case_Number_Formula__c + '&&' + fileNameDec;
				ContentVersion content = createContentVersion(pdfBlob, contentVersion, fileData);
				cvList.add(content);
				Database.SaveResult[] cvRecs = Database.Insert(cvList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_LetterGenerationController',
					'generateLetters',
					cvRecs,
					'ContentVersion'
				);

				for (Database.SaveResult sr : cvRecs) {
					if (sr.isSuccess()) {
						listOfIds.add(sr.getId());
					}
				}

				List<Id> cvIds = linkContentDocument(listOfIds, new List<Case>{ claim });

				// if (vfPageNameDec.contains('Summary') && isUpdate) {
				if (vfPageNameDec.contains('Summary') || vfPageNameDec.contains('Decline')) {
					CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, false, 'Claim', false);
					Database.executeBatch(uploadBatch, 1);
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LetterGenerationController',
				'generateLetters',
				JSON.serialize(recordIds),
				e
			);
		}
	}

	private static void generateRechargeLetters(List<Id> claimIds, Map<String, List<String>> contentDocLinkMap) {
		try {
			String title = 'RechargeLetter_';
			String fileNameDec = 'RechargeLetter.pdf';
			PageReference pdfPage;
			Integer count = 0;
			List<Id> cvIds = new List<Id>();

			List<Case> claims = new List<Case>();
			claims = CSX_CMP_RechargeLetterController.getCaseDetails(claimIds);
			Map<String, Blob> pdfBlobMap = new Map<String, Blob>();
			Map<String, Case> claimMap = new Map<String, Case>();

			for (Case claim : claims) {
				pdfPage = Page.CSX_CMP_RechargeLetterpage;
				pdfPage.getParameters().put('case', JSON.serialize(claim));
				pdfBlobMap.put(claim.Id, pdfPage.getContentAsPDF());
				claimMap.put(claim.Id, claim);
			}

			Set<String> claimIdsSet = new Set<String>();
			if (!contentDocLinkMap.isEmpty()) {
				for (String claimId : contentDocLinkMap.keySet()) {
					claimIdsSet.addAll(new Set<String>(contentDocLinkMap.get(claimId)));
				}
			}

			List<ContentVersion> contentVersionList = new List<ContentVersion>();
			contentVersionList = [
				SELECT Id, ContentDocumentId, Title
				FROM ContentVersion
				WHERE ContentDocumentId IN :claimIdsSet
				WITH SECURITY_ENFORCED
			];

			List<ContentVersion> cvList = new List<ContentVersion>();

			for (String claimId : pdfBlobMap.keySet()) {
				Case claim = claimMap.get(claimId);
				Blob pdfBlob = pdfBlobMap.get(claimId);
				ContentVersion contentVersion = getContentVersion(contentVersionList, claim, title);
				if (contentVersion.Id != null) {
					count++;
					cvIds.add(contentVersion.contentDocumentId);
				}
				String fileData = title + /*claim.CaseNumber*/ claim.CSX_CMP_Case_Number_Formula__c + '&&' + fileNameDec;
				ContentVersion content = createContentVersion(pdfBlob, contentVersion, fileData);
				cvList.add(content);
			}

			Database.SaveResult[] cvRecs = Database.Insert(cvList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_LetterGenerationController',
				'generateRechargeLetters',
				cvRecs,
				'ContentVersion'
			);

			List<Id> listOfIds = new List<Id>();
			for (Database.SaveResult sr : cvRecs) {
				if (sr.isSuccess()) {
					listOfIds.add(sr.getId());
				}
			}

			if (count == 0) {
				cvIds = linkContentDocument(listOfIds, claims);
			}

			CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, false, 'Claim', false);
			Database.executeBatch(uploadBatch, 1);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LetterGenerationController',
				'generateRechargeLetters',
				JSON.serialize(claimIds),
				e
			);
		}
	}

	private static contentVersion createContentVersion(Blob pdfBlob, ContentVersion cVersion, String fileData) {
		ContentVersion cont = new ContentVersion();
		cont.Title = fileData.split('&&')[0];
		cont.PathOnClient = fileData.split('&&')[1];
		cont.VersionData = pdfBlob;
		cont.Origin = 'H';
		if (cVersion != null) {
			cont.contentDocumentId = cVersion.ContentDocumentId;
		}
		return cont;
	}

	private static ContentVersion getContentVersion(List<ContentVersion> contentVersionList, Case claim, String title) {
		// String title = 'RechargeLetter_';
		ContentVersion contentVersion = new ContentVersion();
		if (!contentVersionList.isEmpty()) {
			for (ContentVersion cVersion : contentVersionList) {
				if (cVersion.title == title + claim.CSX_CMP_Case_Number_Formula__c /*claim.CaseNumber*/) {
					contentVersion = cVersion;
					break;
				}
			}
		}
		return contentVersion;
	}

	private static List<Id> linkContentDocument(List<Id> contentVersionIds, List<Case> caseRecs) {
		List<Id> cvIds = new List<Id>();
		try {
			List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
			List<ContentVersion> contentVersionList = new List<ContentVersion>();
			contentVersionList = [
				SELECT Id, ContentDocumentId, Title
				FROM ContentVersion
				WHERE Id IN :contentVersionIds
				WITH SECURITY_ENFORCED
			];
			Map<String, String> caseMap = new Map<String, String>();
			for (Case caseRec : caseRecs) {
				caseMap.put(caseRec.CaseNumber, caseRec.Id);
			}
			for (ContentVersion cv : contentVersionList) {
				ContentDocumentLink cd1 = new ContentDocumentLink();
				cvIds.add(cv.Id);
				cd1.ContentDocumentId = cv.ContentDocumentId;
				String caseNum = String.valueOf(cv.Title.split('_')[1]);
				cd1.LinkedEntityId = caseMap.get(caseNum);
				cd1.ShareType = 'I';
				cd1.Visibility = 'AllUsers';
				contentDocLinks.add(cd1);
			}

			Database.SaveResult[] cdRecs = Database.Insert(contentDocLinks, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_LetterGenerationController',
				'linkContentDocument',
				cdRecs,
				'ContentDocumentLink'
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LetterGenerationController',
				'linkContentDocument',
				JSON.serialize(contentVersionIds),
				e
			);
		}
		return cvIds;
	}
}