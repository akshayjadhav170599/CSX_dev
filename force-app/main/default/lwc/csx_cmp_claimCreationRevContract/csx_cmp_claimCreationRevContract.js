import { LightningElement, api, track, wire } from 'lwc';

// standard imports
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CLAIM_TYPE_FIELD from '@salesforce/schema/Case.Type';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// custom labels
import saveAllRowsErrorMessage from '@salesforce/label/c.CSX_CMP_ClaimCreationRevContract_SaveAllRowsErrorMessage';
import oneRowRequiredErrorMessage from '@salesforce/label/c.CSX_CMP_ClaimCreationRevContract_OneRowRequiredErrorMessage';
import enterAllRequiredFieldsErrorMessage from '@salesforce/label/c.CSX_CMP_ClaimCreationRevContract_EnterAllRequiredFieldsErrorMessage';
import submitClaim from '@salesforce/label/c.CSX_CMP_ClaimCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import backToSearch from '@salesforce/label/c.CSX_CMP_BackToSearchLabel';
import overlapMessage from '@salesforce/label/c.CSX_CMP_Overlapping_Claims';
import duplicatesFound from '@salesforce/label/c.CSX_CMP_Duplicates_Found';

// Apex methods imports
import checkforDuplicates from '@salesforce/apex/CSX_CMP_ClaimCreationController.checkforDuplicates';
import getContractOptions from '@salesforce/apex/CSX_CMP_ClaimCreationController.getContractOptions';
import createClaim from '@salesforce/apex/CSX_CMP_ClaimCreationController.createNewClaim';

// custom imports
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_claimCreationRevContract extends LightningElement {

    //custom labels imported from Salesforce
    label = {
        saveAllRowsErrorMessage, oneRowRequiredErrorMessage, enterAllRequiredFieldsErrorMessage,
        submitClaim, reset, backToSearch, overlapMessage, duplicatesFound
    };

    selectedClaimType = '';
    claimTypeOptions;
    dupClaim;
    duplicateClaimNum;
    noActiveSupplierAvailable = false;
    @api recordType;
    errorMessage;
    isError;
    count = 0;
    isSubmitting = false;
    isModalOpen = false;
    noContracts = false;
    noRows = false;
    hideSupplierSiteSearch = true;
    ClaimantCompanyId;
    remainingBudget;
    caseNumbers;
    sendEmailCheck = true;
    claimCreationRevContract = {
        'source': 'Manual',
        'companyFilingClaim': '',
        'contractNumber': '',
        'claimType': '',
        'customerClaimDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
        'claimPeriodBeginDate': '',
        'claimPeriodEndDate': '',
        'notes': '',
        'equipment': [],
        'sendEmail': true,
        'claimAmount': '',
        'claimRecordType': '',
        'supplierId': '',
        'contactName': '',
        'phoneNumber': '',
        'email': '',
    };

    unitTypeOptions = [
        { label: 'Cars', value: 'Cars' },
        { label: 'Weight in Tons', value: 'Weight(in Tons)' }
    ];
    contractOptions;
    companyFilingClaimEntered = false;
    rowAdded = false;
    totalClaimAmount;
    headers = ['Unit Type', 'Cars or Weight', 'Refund Unit Rate', 'Refund Amount'];
    @track
    records = [
        {
            'rowNumber': 1, 'unitType': '', 'carsOrWeight': '', 'refundUnitRate': '',
            'refundAmount': '', 'isRowDisabled': false, 'unitTypeRequired': true,
            'carsOrWeightRequired': true, 'refundUnitRateRequired': true, 'displayEditIcon': false, 'displaySaveIcon': false
        },
    ];

    contractToClaimsMap = [{ 'contractId': '', 'claims': [] }];
    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: CLAIM_TYPE_FIELD })
    claimTypeValues({ data, error }) {
        if (data)
            this.claimTypeOptions = data.values;
        else {
            console.log(error);
        }
    }

    connectedCallback() {
        this.maximumDate = new Date().toISOString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
    }

    handleInputChange(event) {
        if (event.target.type == 'checkbox') {
            if (event.target.name == 'noActiveSupplierAvailable') {
                this.noActiveSupplierAvailable = event.target.checked;
                if (this.noActiveSupplierAvailable) {
                    this.hideSupplierSiteSearch = false;
                } else {
                    this.hideSupplierSiteSearch = true;
                }
            }

            if (event.target.name == 'sendEmail') {
                this.claimCreationRevContract[event.target.name] = event.target.checked;
                if (this.claimCreationRevContract[event.target.name]) {
                    this.sendEmailCheck = true;
                } else {
                    this.sendEmailCheck = false;
                }
            }
        } else if (event.target.type == 'date') {
            if (event.target.value != '' && event.target.value != null && event.target.value != undefined) {
                this.claimCreationRevContract[event.target.name] = new Date(event.target.value).toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' });
            } else {
                this.claimCreationRevContract[event.target.name] = null;
            }
            this.validateDate();

        } else {
            this.claimCreationRevContract[event.target.name] = event.target.value;
        }
    }

    handleContactDetailChange(event) {
        const data = JSON.parse(event.detail);
        this.claimCreationRevContract[data.label] = data.value;
    }

    validateDate() {
        let claimPeriodBeginDate = this.claimCreationRevContract.claimPeriodBeginDate;
        let claimPeriodEndDate = new Date(this.claimCreationRevContract.claimPeriodEndDate);
        let endDateEntered = this.template.querySelector('[data-id="endDate"]');
        endDateEntered.setCustomValidity('');

        if (claimPeriodBeginDate) {

            claimPeriodBeginDate = new Date((claimPeriodBeginDate == '01/01/1970' ? null : claimPeriodBeginDate));
            if (claimPeriodBeginDate > claimPeriodEndDate) {
                endDateEntered.setCustomValidity("End Date cannot be less than Begin Date");
                // endDateEntered.reportValidity();
                // return false;
            }
            // else {
            //     endDateEntered.setCustomValidity("");
            //     endDateEntered.reportValidity();
            //     // return true;
            // }
        } else if (claimPeriodEndDate) {
            endDateEntered.setCustomValidity("Enter Claim Period Begin Date first");
            // endDateEntered.reportValidity();
            // return false;
        }
        // else {
        //     endDateEntered.setCustomValidity("");
        //     endDateEntered.reportValidity();
        //     return true;
        // }
        endDateEntered.reportValidity();

    }

    handlecompanyFilingClaimChange(event) {

        if (event.detail.value !== null || event.detail.value !== '') {
            this.companyFilingClaimEntered = false;
            this.noContracts = false;
            this.claimCreationRevContract.companyFilingClaim = (event.detail.value)[0];
            this.ClaimantCompanyId = (event.detail.value)[0];
        }

        if (this.ClaimantCompanyId) {

            getContractOptions({ claimantId: this.ClaimantCompanyId }).then(result => {
                console.log('result', result);
                this.contractOptions = result.map(contract => ({
                    label: contract.Name,
                    value: contract.Id
                }));

                let contractToClaimsMap = new Map();
                result.forEach(contract => {
                    contractToClaimsMap.set(contract.Id, contract.Claims__r);
                });
                this.contractToClaimsMap = contractToClaimsMap;
                console.log('contractToClaimsMap', this.contractToClaimsMap);

                if (this.contractOptions.length > 0) {
                    this.claimCreationRevContract.companyFilingClaim != '' ? this.companyFilingClaimEntered = true : this.companyFilingClaimEntered = false;
                    this.remainingBudget = result[0].CSX_CMP_Remaining_Budget__c;
                    this.claimCreationRevContract.claimType = result[0].CSX_CMP_Claim_Type__c;
                } else {
                    this.noContracts = true;
                }
            }).catch(error => {
                csx_cmp_logError('Csx_cmp_claimCreationRevContract', 'handlecompanyFilingClaimChange', error, '');
            });
        }
    }
    submitClaim() {
        this.isSubmitting = true;
        this.claimCreationRevContract.equipment = this.records;
        this.claimCreationRevContract.claimPeriodBeginDate = this.claimCreationRevContract.claimPeriodBeginDate != '' ? new Date(this.claimCreationRevContract.claimPeriodBeginDate).toISOString().split('T')[0] : null;
        this.claimCreationRevContract.claimPeriodEndDate = this.claimCreationRevContract.claimPeriodEndDate != '' ? new Date(this.claimCreationRevContract.claimPeriodEndDate).toISOString().split('T')[0] : null;
        let allRowsDisabled = true;
        let refundDetails = [];
        this.claimCreationRevContract.equipment.forEach(element => {
            if (!element.isRowDisabled) {
                allRowsDisabled = false;
            }
            let refundDetail = {
                'unitType': element.unitType,
                // 'numberOfCars': element.carsOrWeight,
                'unitRefundPrice': element.refundUnitRate,
                'originalAmount': element.refundAmount,
                'claimAmount': element.refundAmount,
                'products': [],
                'distributions': [],
                //'salvages': [], // needs to be removed
            };
            if (refundDetail.unitType == 'Weight(in Tons)') {
                refundDetail.weight = element.carsOrWeight;
                refundDetail.numberOfCars = null;
            } else {
                refundDetail.numberOfCars = element.carsOrWeight;
                refundDetail.weight = null;
            }
            refundDetails.push(refundDetail);
        });
        this.claimCreationRevContract['claimAmount'] = this.totalClaimAmount;


        let finalRefundDetails = JSON.stringify(refundDetails);

        this.claimCreationRevContract.equipment = finalRefundDetails;
        this.claimCreationRevContract['claimRecordType'] = 'Revenue_Contract_Refund';
        let validation = this.validateInput();
        if (validation) {
            let claim = this.claimCreationRevContract;
            Object.keys(claim).forEach(function (key) {
                if (claim[key] != null || claim[key] != undefined || claim[key] != '') {
                    claim[key] = claim[key].toString();
                }
            });
            console.log('claim', claim);


            checkforDuplicates({ inputClaimDetails: claim }).then(result => {
                if (Object.keys(result).length != 0) {
                    this.dupClaim = Object.entries(result).map(([key, value]) => ({ Id: key, CaseNumber: value }));
                    this.duplicateClaimNum = Object.values(result);
                    this.isSubmitting = false;
                    this.isModalOpen = true;
                } else {
                    this.createClaim();
                }
            }).catch(error => {
                this.isSubmitting = false;
                csx_cmp_logError('Csx_cmp_claimCreationRevContract', 'checkforDuplicates', error, '');
            });
        } else {
            this.isSubmitting = false;
            const evt = new ShowToastEvent({
                title: 'Please Review Fields',
                message: 'Enter all the mandatory fields to create a claim',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }
    }

    validateInput() {

        let validList = [];
        validList.push(this.checkFieldValidity());
        validList.push(this.contractValidation());
        // let contractBudget = this.template.querySelector('[data-id="contract"]');
        // let datesOverlap = this.template.querySelector('[data-id="beginDate"]');
        // if (contractBudget) {
        //     contractBudget.setCustomValidity("");
        //     contractBudget.reportValidity();
        // }
        // if (datesOverlap) {
        //     datesOverlap.setCustomValidity("");
        //     datesOverlap.reportValidity();
        // }
        // let InputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        // let isValid = true;
        // let lookUpField = this.template.querySelector('lightning-input-field');
        // lookUpField.reportValidity();
        // InputFields.forEach(inputField => {
        //     if (!inputField.checkValidity()) {
        //         inputField.reportValidity();
        //         isValid = false;
        //     }
        // });

        // console.log('claimAmount : ', this.claimCreationRevContract['claimAmount'], 'remainingBudget : ', this.remainingBudget);
        // if (this.claimCreationRevContract['claimAmount'] != '' && this.claimCreationRevContract['claimAmount'] > this.remainingBudget) {
        //     contractBudget.setCustomValidity('The contract does not have enough balance to cover the current claim amount. The remaining balance is $' + this.remainingBudget);
        //     contractBudget.reportValidity();
        //     isValid = false;
        // }
        // else {
        //     if (contractBudget) {
        //         contractBudget.setCustomValidity("");
        //         contractBudget.reportValidity();
        //     }
        // }
        // if (this.noContracts) {
        //     isValid = false;
        // }
        // if (this.claimCreationRevContract['companyFilingClaim'] == '') {
        //     isValid = false;
        // }
        let isValid = true;
        if (this.claimCreationRevContract['supplierId'] == '' && !this.noActiveSupplierAvailable) {
            this.template.querySelector('c-csx_cmp_supplier-site-search').supplierValidation();
            isValid = false;
        }
        validList.push(isValid);
        isValid = true;
        let contactDetailsValid = this.template.querySelector('c-csx_cmp_contact-details').validate();
        if (!contactDetailsValid) {
            isValid = false;
        }
        validList.push(isValid);
        isValid = validList.every(function (value) {
            return value;
        });
        return isValid;
    }

    checkFieldValidity() {
        let isValid = true;
        let fields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        fields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    contractValidation() {
        let isValid = true;
        if (this.noContracts || this.claimCreationRevContract.companyFilingClaim == '') {
            isValid = false;
            return isValid;
        }

        let contractBudget = this.template.querySelector('[data-id="contract"]');
        let claimAmount = this.claimCreationRevContract['claimAmount'];
        let amountExceedMessage = '';
        if (claimAmount != '' && claimAmount > this.remainingBudget) {
            amountExceedMessage = 'The contract does not have enough balance to cover the current claim amount. The remaining balance is $' + this.remainingBudget;
            isValid = false;
        }
        if (contractBudget) {
            contractBudget.setCustomValidity(amountExceedMessage);
            contractBudget.reportValidity();
        }

        let contractClaims = this.contractToClaimsMap.get(this.claimCreationRevContract.contractNumber);
        let overlapMessage = '';
        if (contractClaims) {
            let beginDate = new Date(this.claimCreationRevContract.claimPeriodBeginDate);
            let endDate = new Date(this.claimCreationRevContract.claimPeriodEndDate);

            contractClaims.forEach(claim => {
                let claimBeginDate = new Date(claim.CSX_CMP_Period_Begin__c.toString());
                let claimEndDate = new Date(claim.CSX_CMP_Period_End__c.toString());
                if ((beginDate >= claimBeginDate && beginDate <= claimEndDate) || (endDate >= claimBeginDate && endDate <= claimEndDate)) {
                    console.log('overlap');
                    overlapMessage = 'Claim Period overlaps with existing claim(s). Please review the dates.';
                    isValid = false;
                    return;
                }
            });
        }

        if (overlapMessage != '') {
            let datesOverlap = this.template.querySelector('[data-id="beginDate"]');
            datesOverlap.setCustomValidity(overlapMessage);
            datesOverlap.reportValidity();
        }

        return isValid;
    }
    closeModal() {
        this.isModalOpen = false;
        this.duplicateClaimNum = null;
    }
    redirectToCase(event) {
        const claimNumber = event.target.dataset.claimNumber;
        let claim = this.dupClaim.find(claim => claim.CaseNumber === claimNumber);
        const caseRecUrl = `/lightning/r/Case/${claim.Id}/view`;
        window.open(caseRecUrl, '_blank');
    }
    createClaim() {
        let claimDetails;
        this.isSubmitting = true;
        this.isModalOpen = false;
        //method to create claim
        createClaim({ inputClaimDetails: this.claimCreationRevContract, duplicateClaims: this.duplicateClaimNum })
            .then(result => {
                claimDetails = result;
                this.isSubmitting = false;
                if (claimDetails) {
                    const sendClaimDetails = new CustomEvent('sendclaim', { detail: JSON.stringify(claimDetails) });
                    this.dispatchEvent(sendClaimDetails);
                }
            })
            .catch(error => {
                this.isSubmitting = false;
                csx_cmp_logError('Csx_cmp_claimCreationRevContract', 'createClaim', error, '');
            });
    }

    handleSupplierId(event) {
        let receivedRecord = JSON.parse(event.detail);
        this.claimCreationRevContract['supplierId'] = receivedRecord;
    }

    handleAddRow() {
        let records = this.records;
        let rowNumber = records.length + 1;
        records.push({
            'rowNumber': rowNumber, 'unitType': '', 'carsOrWeight': '', 'refundUnitRate': '',
            'refundAmount': '', 'isRowDisabled': false, 'unitTypeRequired': true,
            'carsOrWeightRequired': true, 'refundUnitRateRequired': true, 'displayEditIcon': false, 'displaySaveIcon': true
        });
        this.records = records;
        this.rowAdded = true;
    }

    handleRemoveRow(event) {
        let rowNumber = event.target.value;
        let records = this.records;

        records.splice(rowNumber - 1, 1);
        if (this.records.length == 0) {
            this.noRows = true;
            this.totalClaimAmount = 0;
            this.handleAddRow(event);
        } else {
            this.records = records;
            let totalClaimAmount = 0;
            this.records.forEach(function (element, index) {
                element.rowNumber = index + 1;
                totalClaimAmount += parseInt(element.refundAmount);
            });
            this.totalClaimAmount = totalClaimAmount;
        }

    }



    handleEditRow(event) {
        let rowNumber = event.target.value;
        let records = this.records;
        records[rowNumber - 1].isRowDisabled = false;
        records[rowNumber - 1].displayEditIcon = false;
        records[rowNumber - 1].displaySaveIcon = true;
        this.records = records;
    }

    handleSaveRow(rowNumber) {

        let records = this.records;
        if (records[rowNumber - 1].refundUnitRate != '' && records[rowNumber - 1].carsOrWeight != '') {
            records[rowNumber - 1].refundAmount = records[rowNumber - 1].refundUnitRate * records[rowNumber - 1].carsOrWeight;
        }

        this.records = records;
        let totalClaimAmount = 0;
        this.records.forEach(function (element) {
            totalClaimAmount += parseFloat(element.refundAmount);
        });
        this.totalClaimAmount = totalClaimAmount;

    }

    handleInputChangeForTable(event) {
        let rowNumber = event.target.dataset.id;
        this.noRows = false;
        let fieldName = event.target.name;
        let records = this.records;
        records[rowNumber - 1][fieldName] = event.target.value;
        if (records[rowNumber - 1].refundUnitRate != '' && records[rowNumber - 1].carsOrWeight != '') {
            records[rowNumber - 1].refundAmount = records[rowNumber - 1].refundUnitRate * records[rowNumber - 1].carsOrWeight;
        }
        if (records[rowNumber - 1].refundUnitRate != '' && records[rowNumber - 1].refundAmount != '') {
            this.handleSaveRow(rowNumber);
        }
        this.records = records;
    }

    /**Will be called multiple times */
    renderedCallback() {
        /**Handle only when new row is added and wants to make it editable */
        if (this.rowAdded) {
            this.rowAdded = false;
            let records = this.records;
            let rowNumber = records.length;
            records[rowNumber - 1].isRowDisabled = false;
            this.records = records;
        }
    }

    reset() {


        this.claimCreationRevContract = {
            'companyFilingClaim': '',
            'contractNumber': '',
            'claimType': '',
            'customerClaimDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
            'claimPeriodBeginDate': '',
            'claimPeriodEndDate': '',
            'notes': '',
            'equipment': [],
            'sendEmail': true,
            'claimAmount': '',
            'claimRecordType': '',
            'supplierId': '',
            'contactName': '',
            'phoneNumber': '',
            'email': '',
            'source': 'Manual'
        };
        this.noActiveSupplierAvailable = false;
        this.records = [
            {
                'rowNumber': 1, 'unitType': '', 'carsOrWeight': '', 'refundUnitRate': '',
                'refundAmount': '', 'isRowDisabled': false, 'unitTypeRequired': true,
                'carsOrWeightRequired': true, 'refundUnitRateRequired': true
            },
        ];
        this.rowAdded = true;
        this.totalClaimAmount = 0;
        this.companyFilingClaimEntered = false;
        this.contractOptions = null;
        this.rowAdded = false;
        this.noContracts = false;

        this.lookupFieldsReset();

        this.inputFieldReset();

        this.template.querySelector('c-csx_cmp_contact-details').resetPage();
        this.template.querySelector('c-csx_cmp_supplier-site-search').resetPage();

    }

    inputFieldReset() {
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        inputFields.forEach(element => {
            let parameters = {
                required: false,
                type: element.type
            }
            element.type = '';
            element.value = '';
            if (element.required) {
                parameters.required = true;
                element.required = false;
            }
            element.setCustomValidity('');
            window.setTimeout(() => {
                element.reportValidity();
                if (parameters.required) {
                    element.required = true;
                }
                element.type = parameters.type;
            }, 500);

        });

    }


    lookupFieldsReset() {
        let lookupField = this.template.querySelector('lightning-input-field');
        if (lookupField) {
            lookupField.value = '';
            lookupField.required = false;
            window.setTimeout(() => {
                lookupField.reportValidity();
                lookupField.required = true;
            }, 500);
        }

    }


    backToSearch() {
        const callClaimSearch = new CustomEvent('backtosearch');
        this.dispatchEvent(callClaimSearch);
    }
}