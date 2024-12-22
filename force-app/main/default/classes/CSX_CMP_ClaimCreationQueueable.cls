/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimCreationQueueable
Function            : Class process claim creation staging records from EDI and FLDX and create claims with all necessary details
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           03/05/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_ClaimCreationQueueable implements Queueable {
	CSX_CMP_Creation_Request__c stagingRecord;

	public CSX_CMP_ClaimCreationQueueable(CSX_CMP_Creation_Request__c stagingRecord) {
		this.stagingRecord = stagingRecord;
	}

	public void execute(QueueableContext context) {
		Map<String, String> responseMap = new Map<String, String>();
		try {
			if(stagingRecord.CSX_CMP_Claim__c == null){
				stagingRecord.CSX_CMP_Creation_Status__c = 'Pending';
				CSX_CMP_ClaimCreationHelper.updateStagingRecord(stagingRecord);
				responseMap = CSX_CMP_ClaimCreationHelper.CreateNewClaim(stagingRecord);
			} else {
				CSX_CMP_PostClaimCreationAPIQueueable.completeStagingRecord(stagingRecord);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreationQueueable','execute',JSON.Serialize(stagingRecord),e);
		}
	}
}