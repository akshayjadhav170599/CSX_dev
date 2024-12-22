import { LightningElement, api } from 'lwc';
import fetchmilege from '@salesforce/apex/CSX_CMP_FetchMileageController.fetchmilege';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {csx_cmp_logError} from 'c/csx_cmp_logError';

export default class Csx_cmp_fetchMiles extends LightningElement {
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    @api invoke() {
        fetchmilege({ recordId: this._recordId })
            .then(result => {
                if (result == 'OK') {
                    this.showToast('Success', 'Miles updated successfully.', 'success');
                    location.reload();
                } else {
                    this.showToast('Error', 'Miles not available.', 'error');
                }
            })
            .catch(error => {
                csx_cmp_logError('Csx_cmp_fetchMiles', 'invoke', error, this._recordId);
            })
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