/*RICEF ID : MR-00501
@author : Infosys
@description : This class is used to send LOA email for Payable/ Pay Recharge claim type and also call upload to ECM batch to upload it to ECM
*/
public class CSX_CMP_LOAEmailQueueable implements Queueable, Database.AllowsCallouts{
    public set<Id> eligibleIds;
    public CSX_CMP_LOAEmailQueueable(Set<Id> loaClaimIds) {
        this.eligibleIds = loaClaimIds ;
    }
    
    public void execute(QueueableContext context) {
        if(!eligibleIds.isEmpty()){
            // calling batch class to upload to ECM
            List<EmailMessage> loaEmails = [
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
                (SELECT Id, name FROM Attachments WHERE Name LIKE '%LOA%')
                FROM EmailMessage
                WHERE ParentId =: eligibleIds AND Subject LIKE '%LOA letter%'
            ];
            CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(loaEmails);
            Database.executeBatch(uploadEmailBatch, 1);
        }
    }
}