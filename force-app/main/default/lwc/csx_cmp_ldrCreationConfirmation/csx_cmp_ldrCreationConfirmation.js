import { LightningElement, api, track } from 'lwc';
import confirmation from '@salesforce/label/c.CSX_CMP_ldrConfirmation_ldrNum';
import ecmRedirection from '@salesforce/label/c.CSX_CMP_ldrConfirmation_ECMlink';
import navigateBack from '@salesforce/label/c.CSX_CMP_ldrConfirmation_NavigateBack';

export default class Csx_cmp_ldrCreationConfirmation extends LightningElement {

   @api ldrNo;
   @api ldrId;
   @api ecmLink;
   initialText;
   endLine;
   @track decReasonee = false;


   label = {
      confirmation, ecmRedirection, navigateBack
   };

   connectedCallback() {
      let text = this.label.navigateBack.split('{ldrNo}');
      let line = text[0] + '<a onclick={redirectToRecord}>' + this.ldrNo + '</a>' + text[1];
      this.initialText = text[0];
      this.endLine = text[1];
   }

   redirectToRecord() {
      let ldrRecUrl = `/lightning/r/CSX_CMP_LD_Report__c/${this.ldrId}/view`;
      window.open(ldrRecUrl, '_blank');
   }

   redirectToECM() {
      // const ecmUrl = this.ecmLink;
      // window.open(ecmUrl, '_blank');
      this.decReasonee = true;
   }

}