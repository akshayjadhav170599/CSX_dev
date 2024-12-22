/*
RICEF ID : CMP-E- , CMP-E-0442
@author : Infosys
@description : This class is used to send declination email for overcharge claim type and also call upload to ECM batch to upload it to ECM
*/

public class CSX_CMP_OverchargeDeclineEmailQueueable implements Queueable, Database.AllowsCallouts{
    public List<Id> eligibleIds;
    public CSX_CMP_OverchargeDeclineEmailQueueable(List<Id> declineClaimIds) {
        this.eligibleIds = declineClaimIds ;
    }
    public void execute(QueueableContext context) {
        if(!eligibleIds.isEmpty()){
            // calling helper to create declination email
           // CSX_CMP_ClaimTriggerHelper.emailDeclineLetter(eligibleIds);
            
            // calling batch class to upload to ECM
            List<EmailMessage> declineEmails = [
                SELECT
                Id,
                TextBody,
                HtmlBody,
                Subject,
                FromAddress,
                ToAddress,
                CcAddress,
                CreatedDate,
                ParentId,
                (SELECT Id, name FROM Attachments WHERE Name LIKE '%decline%')
                FROM EmailMessage
                WHERE ParentId = :eligibleIds AND Subject LIKE '%Decline letter%'
            ];
            CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(declineEmails);
            Database.executeBatch(uploadEmailBatch, 1);
        }
        
    }
    
}