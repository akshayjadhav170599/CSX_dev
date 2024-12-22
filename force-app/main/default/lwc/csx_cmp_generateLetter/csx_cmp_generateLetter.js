import { LightningElement, track, api, wire } from 'lwc'; //old
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TYPE from '@salesforce/schema/Case.Type';
import RECORDTYPE from '@salesforce/schema/Case.RecordType.DeveloperName';
import STATUS from '@salesforce/schema/Case.Status';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { csx_cmp_logError } from "c/csx_cmp_logError";

const fields = [TYPE, RECORDTYPE, STATUS];
const fieldsArray = ['Case.Type',
    'Case.RecordType.DeveloperName'];
import generateLetters from '@salesforce/apex/CSX_CMP_LetterGenerationController.generateLetters';
import checkNoteOnClaim from '@salesforce/apex/CSX_CMP_LetterGenerationController.checkNoteOnClaim';

export default class Csx_cmp_generateLetter extends LightningElement {

    @api recordId;
    selectedOpt = '';
    revenueflag = false;
    typeD;
    @track optionSelected = false;
    @track noteCheck = false;
    @track decNoteCheck = false;
    recordTypeDetail;
    viewButton = true;
    letterType;
    letterCheckLetter = 0;
    approveDec = true;


    @wire(getRecord, { recordId: "$recordId", fields: fields }) caseRecords;
    @wire(getRecord, { recordId: "$recordId", fields: fieldsArray }) caseRecord;

    get claimType() {
        let typeDetails;
        let status;
        if (this.caseRecords.data) {
            typeDetails = getFieldValue(this.caseRecords.data, TYPE);
            status = getFieldValue(this.caseRecords.data, STATUS);
            if (typeDetails == 'FC Customer Automobile Claim' || typeDetails == 'FC Customer Claim' || typeDetails == 'Transflo Claim' || typeDetails == 'Contractor Claim') {
                if (status == 'Declined' || status == 'Re-Declined') {
                    return [
                        { label: 'Declination Letter', value: 'declinationLetter', checked: false },
                        { label: 'Claim Summary', value: 'claimSummary', checked: false },
                    ];
                } else {
                    return [
                        { label: 'Claim Summary', value: 'claimSummary', checked: false }
                    ];
                }

            }
            else if (typeDetails == 'Incentive Claim' || typeDetails == 'Service Claim' || typeDetails == 'Rev-RR - Payable Claim' || typeDetails == 'Rev-RR - Payable Rchg Claim' || typeDetails.startsWith('Overcharge')) {
                if (status == 'Declined' || status == 'Re-Declined') {
                    return [
                        { label: 'Declination Letter', value: 'declinationLetter', checked: false },
                        { label: 'Claim Summary', value: 'claimSummary', checked: false },
                    ];
                } else {
                    return [
                        { label: 'Claim Summary', value: 'claimSummary', checked: false }
                    ];
                }
            }
            else if (typeDetails == 'Recharges Outbound Claim') {
                return [
                    { label: 'Recharge Letter', value: 'rechargeLetter', checked: false },
                    { label: 'Claim Summary', value: 'claimSummary', checked: false }
                ]
            }
            else if (typeDetails == 'FC RR Inbound Claim' || typeDetails == 'Lawsuit Claim' || typeDetails == 'Recharges Inbound Claim') {
                return [
                    { label: 'Claim Summary', value: 'claimSummary', checked: false }
                ]
            }
            else if (typeDetails != 'FC RR Outbound Claim' || typeDetails != 'Railroad Netting FC Claim' || typeDetails != 'FC Salvage Claim') {
                return [
                    { label: 'Claim Summary', value: 'claimSummary', checked: false }
                ]
            }
            this.typeD = typeDetails;

        }
        return typeDetails;
    }

    get claimStatus() {
        let clStatus;
        if (this.caseRecords.data) {
            clStatus = getFieldValue(this.caseRecords.data, STATUS);
            this.status = clStatus;
        }
        return clStatus;
    }


    get developerName() {
        let devName;
        if (this.caseRecords.data) {
            devName = getFieldValue(this.caseRecords.data, RECORDTYPE);
            this.typeD = devName;
        }
        return devName;
    }

    handleRadioChange(event) {
        this.selectedOpt = event.detail.value;
        this.optionSelected = false;
        this.letterType = event.detail.value;
        if (this.letterType == 'declinationLetter') {
            this.letterType = 'Decline';
        }
        if (this.letterType == 'claimSummary') {
            this.letterType = 'Claim Summary';
        }
        if (this.letterType == 'rechargeLetter') {
            this.letterType = 'Recharge';
        }

    }

    createDocument() {
        if (this.selectedOpt == '') {
            this.optionSelected = true;
        }
        else if (this.selectedOpt == 'rechargeLetter') {
            let vfPageName = 'CSX_CMP_RechargeLetterpage';
            this.generateLetter(vfPageName);
        }
        else if (this.selectedOpt == 'declinationLetter') {

            if (this.developerName === 'Freight') {
                let vfPageName = 'CSX_CMP_FreightDeclineLetter';
                this.generateLetter(vfPageName);
            }
            if (this.developerName === 'Revenue_Contract_Refund') {

                let vfPageName = 'CSX_CMP_ContractRefundDeclineLetter';
                this.generateLetter(vfPageName);

            }
            if (this.developerName === 'Revenue_Overcharge') {
                let vfPageName = 'CSX_CMP_OverchargeDeclineLetter';
                this.generateLetter(vfPageName);

            }
            if (this.developerName === 'Revenue_Railroad') {
                let vfPageName = 'CSX_CMP_RevenueRailroadDeclineLetter';
                this.generateLetter(vfPageName);
            }
        }
        else if (this.selectedOpt == 'claimSummary') {

            if (this.developerName === 'Freight') {
                let vfPageName = 'CSX_CMP_FreightClaimSummary';
                this.generateLetter(vfPageName);
            }
            if (this.developerName === 'Revenue_Contract_Refund') {

                let vfPageName = 'CSX_CMP_ContractRefundSummary';
                this.generateLetter(vfPageName);

            }
            if (this.developerName === 'Revenue_Overcharge') {
                let vfPageName = 'CSX_CMP_OverchargeSummaryReport';
                this.generateLetter(vfPageName);

            }
            if (this.developerName === 'Revenue_Railroad') {
                let vfPageName = 'CSX_CMP_RevenueRRSummaryReport';
                this.generateLetter(vfPageName);
            }
        }

    }
    generateLetter(vfPageName) {

        generateLetters({ recordIds: this.recordId, vfPageNameDec: vfPageName })
            .then(result => {

                this.dispatchEvent(new CloseActionScreenEvent());
                const rechargeLetterSuccess = new ShowToastEvent({
                    title: this.letterType + ' Letter has been successfully generated and attached to the claim',
                    variant: 'success',
                });
                this.dispatchEvent(rechargeLetterSuccess);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.refreshPage();;
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(new CloseActionScreenEvent());
                const rechargeError = new ShowToastEvent({
                    title: 'Could not generate ' + this.letterType + ' Letter',
                    message: 'Could not generate ' + this.letterType + ' Letter',
                    variant: 'error',
                });
                this.dispatchEvent(rechargeError);
            });
    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    refreshPage() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
            this.closeQuickAction();

        }
            , 3000);
    }
    viewDocument() {
        this.noteCheck = false;
        this.viewButton = true;
        this.optionSelected = false;
        if (this.selectedOpt == '') {
            this.optionSelected = true;
        }
        else if (this.selectedOpt == 'rechargeLetter') {
            this.optionSelected = false;
            window.open('/apex/CSX_CMP_RechargeLetterPage?recordId=' + this.recordId, '_blank');
            this.viewButton = false;
            this.noteCheck = false;
        }
        else if (this.selectedOpt == 'declinationLetter') {

            checkNoteOnClaim({ claimId: this.recordId })
                .then(result => {
                    if (result == false) {
                        this.noteCheck = true;
                    } else {
                        this.decNoteCheck = result;
                        if (this.decNoteCheck) {
                            this.viewButton = false;
                        }
                    }
                })
                .catch(error => {
                    csx_cmp_logError('Csx_cmp_generateLetter', 'checkNoteOnClaim', error, '');
                });
            this.optionSelected = false;
            if (this.developerName === 'Freight') {
                window.open('/apex/CSX_CMP_FreightDeclineLetter?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Contract_Refund') {
                window.open('/apex/CSX_CMP_ContractRefundDeclineLetter?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Overcharge') {
                window.open('/apex/CSX_CMP_OverchargeDeclineLetter?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Railroad') {
                window.open('/apex/CSX_CMP_RevenueRailroadDeclineLetter?id=' + this.recordId, '_blank');
            }


        }
        else if (this.selectedOpt == 'claimSummary') {
            if (this.developerName === 'Freight') {
                window.open('/apex/CSX_CMP_FreightClaimSummary?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Overcharge') {
                window.open('/apex/CSX_CMP_OverchargeSummaryReport?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Railroad') {
                window.open('/apex/CSX_CMP_RevenueRRSummaryReport?id=' + this.recordId, '_blank');
            }
            if (this.developerName === 'Revenue_Contract_Refund') {
                window.open('/apex/CSX_CMP_ContractRefundSummary?id=' + this.recordId, '_blank');
            }
            this.viewButton = false;
            this.noteCheck = false;
        }

    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}