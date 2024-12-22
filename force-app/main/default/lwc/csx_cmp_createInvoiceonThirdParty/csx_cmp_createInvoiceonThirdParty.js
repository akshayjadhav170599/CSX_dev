import { LightningElement, api } from 'lwc';
import create3rdPartyARSettlement from '@salesforce/apex/CSX_CMP_SettlementUtility.create3rdPartyARSettlement';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Csx_cmp_createInvoiceonThirdParty extends LightningElement {
    showSpinner = false;
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    @api invoke() {
        create3rdPartyARSettlement({ partyId: this.recordId }).then(result => {
                this.showToast('Success', 'AR Invoice is Created', 'success');
            
            this.showSpinner = true;
                setTimeout(() => {
                    location.reload();
                }, 2000);

                //Code to refresh the page
                 
        }).catch(error => {
            console.log(error);
            this.showToast('Error', 'An error while processing', 'error');
        });
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
}