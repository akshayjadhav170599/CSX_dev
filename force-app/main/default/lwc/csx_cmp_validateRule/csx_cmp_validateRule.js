import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Success from '@salesforce/label/c.CSX_CMP_Validate_Custom_Message';
import Error from '@salesforce/label/c.CSX_CMP_Validate_Error_Message';
import ConditionNotExist from '@salesforce/label/c.CSX_CMP_Business_Rule_Condition_Does_Not_Exisit';
import Mathces from '@salesforce/label/c.CSX_CMP_Duplicate_Rule_Matches_Error';
import evaluateWhereClause from "@salesforce/apex/CSX_CMP_ValidateRule.evaluateWhereClause";
import AtleastMatchesForDuplicate from "@salesforce/label/c.CSX_CMP_Atleast_one_match_for_duplicate";
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_validateRule extends LightningElement {
    _recordId;
    result;
    error;
    @track label = { Success, Error , ConditionNotExist, Mathces, AtleastMatchesForDuplicate};

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    @api invoke() {
        evaluateWhereClause({ id: this._recordId }).then(result => {
            //Duplicate Rule Matches Error
            if (result == 1) {
                this.showErrorToast(this.label.Mathces);
            }
            //Invalid where clause error
            else if (result == 2) {
                this.showErrorToast(this.label.Error);
            }
            // Business rule condition does not exist   
            else if (result == 4) {
                this.showErrorToast(this.label.ConditionNotExist);
            }
            //At least one matches condition should exist for duplicate condition    
            else if (result == 5) {
                this.showErrorToast(this.label.AtleastMatchesForDuplicate);
            }
            //Business rule evaluated successfully    
            else if (result == 3) {
                this.showSuccessToast(this.label.Success);
                window.location.reload();
            }
            
        })
        .catch((error) => {
            this.error = error;
            csx_cmp_logError('Csx_cmp_validateRule','invoke',error,'');
        });
    }


    showErrorToast(msglabel) {
        console.log('msglabel??' + msglabel);
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    showSuccessToast(msglabel) {
        const evt = new ShowToastEvent({
            message: msglabel,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }
}