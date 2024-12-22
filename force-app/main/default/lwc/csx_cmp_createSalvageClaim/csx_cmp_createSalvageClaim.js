import { LightningElement, api, wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import createNewClaim from '@salesforce/apex/CSX_CMP_SalvageClaimCreationController.createSalvageClaim';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
//custom labels import
import salvageErrorMessageAlreadyExists from '@salesforce/label/c.CSX_CMP_SalvageErrorMessageAlreadyExists';
import salvageSuccessMessage from '@salesforce/label/c.CSX_CMP_SalvageSuccessMessage';

export default class Csx_cmp_createSalvageClaim extends LightningElement {
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    recordData;
    label = {
        salvageErrorMessageAlreadyExists,
        salvageSuccessMessage
    };

    @wire(getRecord, { recordId: '$_recordId', fields: ['CSX_CMP_Salvage__c.CSX_CMP_Parent_Equipment__r.CSX_CMP_LD_Report__c', 'CSX_CMP_Salvage__c.CSX_CMP_Parent_Equipment__c', 'CSX_CMP_Salvage__c.CSX_CMP_Product__c', 'CSX_CMP_Salvage__c.Name', 'CSX_CMP_Salvage__c.CSX_CMP_Salvage_Claim__c'] })
    recordDetails({ error, data }) {
        if (data) {
            this.recordData = data;
        } else if (error) {
            csx_cmp_logError('CSX_CMP_SalvageClaim', 'recordDetails', error, this._recordId);
        }
    }

    @api invoke() {
        let ldrId = this.recordData.fields.CSX_CMP_Parent_Equipment__r.value.fields.CSX_CMP_LD_Report__c.value;
        let equipmentId = this.recordData.fields.CSX_CMP_Parent_Equipment__c.value;
        let productDescription = this.recordData.fields.CSX_CMP_Product__c.value;
        if (this.recordData.fields.CSX_CMP_Salvage_Claim__c.value) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: this.label.salvageErrorMessageAlreadyExists,
                variant: 'warning'
            }));
        } else {
            //create salvage claim
            createNewClaim({ sourceId: this.recordId, data: JSON.stringify({ equipmentId: equipmentId, ldrId: ldrId, productDescription: productDescription }) }).then(result => {
                if (result == 'Success') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: this.label.salvageSuccessMessage,
                        variant: 'success'
                    }));
                }

                setTimeout(() => {
                    location.reload();
                }, 5000);
            }).catch(error => {
                csx_cmp_logError('CSX_CMP_SalvageClaim', 'invoke', error, this._recordId);
            });
        }
    }
}