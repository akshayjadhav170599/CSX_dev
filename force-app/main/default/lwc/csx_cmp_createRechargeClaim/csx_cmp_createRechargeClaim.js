import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// custom labels
import noRechargeClaimsCreated from '@salesforce/label/c.CSX_CMP_NoRechargeClaimsCreated';
import rechargeCommentErrorMessage from '@salesforce/label/c.CSX_CMP_RechargeCommentErrorMessage';
import rechargeSuccessMessage from '@salesforce/label/c.CSX_CMP_RechargeSuccessMessage';
import rechargeSuccess from '@salesforce/label/c.CSX_CMP_RechargeSuccess';
import rechargeErrorMessageEmptyList from '@salesforce/label/c.CSX_CMP_RechargeErrorMessageEmptyList';
import rechargeErrorMessage from '@salesforce/label/c.CSX_CMP_RechargeErrorMessage';
import rechargeError from '@salesforce/label/c.CSX_CMP_RechargeError';

// apex handlers
import createNewClaims from '@salesforce/apex/CSX_CMP_RechargeClaimCreationController.createRechargeClaim';
import checkExistingRechargeClaims from '@salesforce/apex/CSX_CMP_RechargeClaimCreationController.checkExistingRechargeClaims';

export default class Csx_cmp_createRechargeClaim extends LightningElement {
    displayRechargeCommentPopup = false;
    @api recordId;
    showSpinner = false;
    claimData = {
        'rechargeReason': '',
    };
    label = {
        rechargeError,
        rechargeErrorMessage,
        rechargeErrorMessageEmptyList,
        rechargeSuccess,
        rechargeSuccessMessage,
        rechargeCommentErrorMessage,
        noRechargeClaimsCreated,
    };

    handleInputChange(event) {
        this.claimData[event.target.name] = event.target.value;
    }

    createRechargeClaim() {
        this.showSpinner = true;
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-textarea');
        fields.forEach(element => {
            if (!element.checkValidity()) {
                element.reportValidity();
                isValid = false;
            }
        });
        let existingRechargeClaims = {};
        let alreadyRecargedClaimsList = [];
        let alreadyRecargedClaims = 'This claim is already recharged: ';
        if (isValid) {
            checkExistingRechargeClaims({ claimIds: [this.recordId] }).then(result => {
                if (result) {
                    existingRechargeClaims = new Map(Object.entries(result));
                    existingRechargeClaims.forEach((value, key) => {
                        if (value === 'false') {
                            alreadyRecargedClaimsList.push(key);
                        }
                    });
                }
                if (alreadyRecargedClaimsList.length > 0) {
                    alreadyRecargedClaims = alreadyRecargedClaims + alreadyRecargedClaimsList.join(', ') + '.';
                }

                if (alreadyRecargedClaimsList.length > 0) {
                    this.dispatchEvent(new CloseActionScreenEvent());
                    let error = new ShowToastEvent({
                        title: 'Error',
                        message: alreadyRecargedClaims,
                        variant: 'error',
                    });
                    this.dispatchEvent(error);
                    this.showSpinner = false;
                } else {
                    let comment = this.claimData.rechargeReason;
                    let selectedClaimId = this.recordId;
                    let data = {
                        comment: comment,
                    }
                    createNewClaims({ sourceId: selectedClaimId, data: JSON.stringify(data) }).then(result => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSpinner = false;
                        if (result) {
                            console.log('inside if result');
                            this.dispatchEvent(new ShowToastEvent({
                                title: this.label.rechargeSuccess,
                                message: this.label.rechargeSuccessMessage,
                                variant: 'success'
                            }));
                            let caseRecUrl = `/lightning/r/Case/${selectedClaimId}/view`;
                            window.open(caseRecUrl, "_self");
                        } else {
                            this.dispatchEvent(new ShowToastEvent({
                                title: this.label.rechargeError,
                                message: this.label.noRechargeClaimsCreated,
                                variant: 'error',
                            }));
                        }
                    });
                }
            }).catch(error => {
                this.showSpinner = false;
                let parameters = selectedClaimIds;
                csx_cmp_logError('csx_cmp_claimSearchFreight', 'handleRecharge', error, parameters);
            });
        } else {
            this.showSpinner = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter the recharge comment',
                variant: 'error',
            }));
        }
    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}