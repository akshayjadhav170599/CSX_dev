import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Success from '@salesforce/label/c.CSX_CMP_Success_Custom_Message';
import Error from '@salesforce/label/c.CSX_CMP_Error_Custom_Message';
import completeAllTasks from '@salesforce/apex/CSX_CMP_TaskController.updateTaskStatus';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_UploadTasks extends LightningElement {

    _recordId;
    result;
    error;

    @track label = {Success, Error}

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
        console.log('_recordId:::'+_recordId);
    }
    
    @api invoke() {
        completeAllTasks({ caseId: this._recordId }).then(result => {
                if (result == 1) {
                    this.showSuccessToast(this.label.Success);
                    window.location.reload();
                }
                else {
                    this.showErrorToast(this.label.Error);
                    // this.label.Error;
                }
            })
            .catch((error) => {
            this.error = error;
            csx_cmp_logError('Csx_cmp_updateAllTasks','invoke',error,'');
        });
    }

    showSuccessToast(msglabel) {
        console.log('msglabel??' + msglabel);
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(msglabel) {
        console.log('msglabel??' + msglabel);
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}