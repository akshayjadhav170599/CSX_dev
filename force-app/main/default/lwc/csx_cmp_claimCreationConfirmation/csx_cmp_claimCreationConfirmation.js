import { LightningElement, api,track } from 'lwc';
import confirmation from '@salesforce/label/c.CSX_CMP_ClaimConfirmation_ClaimNum';
import ecmRedirection from '@salesforce/label/c.CSX_CMP_ClaimConfirmation_ECMlink';
import navigateBack from '@salesforce/label/c.CSX_CMP_ClaimConfirmation_NavigateBack';
import declineClaim from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.declineClaim';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_claimCreationConfirmation extends LightningElement {

   @api claimNo;
   @api claimId;
   @api recordId;
   @api ecmLink;
   @api decReason;
   @track decReasonee = false;
   
   label = {
      confirmation, ecmRedirection, navigateBack
   };
   
   redirectToCase() {
      this.redirectToClaim(this.claimId);
   }

   redirectToECM() {
      // const ecmUrl = this.ecmLink;
      // window.open(ecmUrl, '_blank');
      // this.redirectToDocument(this.claimId);
      this.decReasonee = true;
   }

   redirectToClaim(claimRecordId) {
      const caseRecUrl = `/lightning/r/Case/${claimRecordId}/view`;
      window.open(caseRecUrl, '_blank');
   }

   updateDecline(claimRecordId) {
      declineClaim({ claimId: claimRecordId })
         .then(result => {
            this.redirectToClaim(claimRecordId);
         })
         .catch(error => {
            csx_cmp_logError('Csx_cmp_claimCreationConfirmation', 'updateDecline', error, '');
         });
   }

   handleDecline() {
      this.updateDecline(this.claimId);
   }
}