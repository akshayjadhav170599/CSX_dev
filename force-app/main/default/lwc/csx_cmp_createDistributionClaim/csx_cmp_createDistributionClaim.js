import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

//Custom Fields
import newTotalManualadjAmount from '@salesforce/schema/CSX_CMP_Equipment__c.CSX_CMP_Total_Manual_Adj_Amount__c';
import totalclaimamounts from '@salesforce/schema/CSX_CMP_Equipment__c.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c';
import name from '@salesforce/schema/CSX_CMP_Equipment__c.Name';
import isClaimClosed from '@salesforce/schema/CSX_CMP_Equipment__c.CSX_CMP_Claim__r.IsClosed';
import claimType from '@salesforce/schema/CSX_CMP_Equipment__c.CSX_CMP_Claim__r.Type';
import origin from '@salesforce/schema/CSX_CMP_Equipment__c.CSX_CMP_Claim__r.Origin';

//Apex Callouts
import getEquipmentDetails from '@salesforce/apex/CSX_CMP_DistributionClaimCreateControlr.getEquipmentDetails';
import calculateDistribution from '@salesforce/apex/CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount';
import createNewClaims from '@salesforce/apex/CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim';
import isClaimCreationAllowed from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.isClaimCreationAllowed';

//Custom Labels
import errorMessage from '@salesforce/label/c.CSX_CMP_Create_Distribution_Claim';
import calculateAmountError from '@salesforce/label/c.CSX_CMP_Calculate_Amount_Error';
import calculateAmountSuccess from '@salesforce/label/c.CSX_CMP_Calculate_Amount_Success';
import deleteRecordSuccessMessage from '@salesforce/label/c.CSX_CMP_Delete_Record_Success_Message';
import deleteRecordErrorMessage from '@salesforce/label/c.CSX_CMP_Delete_Record_Error_Message';
import claimAmountMisMatchErrorMessage from '@salesforce/label/c.CSX_CMP_Claim_Amount_MisMatch_Error_Message';
import createDistributionClaimSuccessMessage from '@salesforce/label/c.CSX_CMP_Create_Distribution_Claim_Success_Message';
import noDistributionRecordsErrorMessage from '@salesforce/label/c.CSX_CMP_No_Distribution_Records_Error_Message';
import clickCalculateAmountErrorMessage from '@salesforce/label/c.CSX_CMP_Click_Calculate_Amount_Error_Message';
import distributionClaimCreationMsgForMexicanRR from '@salesforce/label/c.CSX_CMP_Distribution_Claim_Creation_Msg_For_MexicanRR';
import noNewClaimsCreatedErrorMessage from '@salesforce/label/c.CSX_CMP_No_New_Claims_Created_Error_Message';
import claimAlreadyExistsErrorMessage from '@salesforce/label/c.CSX_CMP_Claim_Already_Exists_Error_Message';
import applicableClaimTypes from '@salesforce/label/c.CSX_CMP_Applicable_Claim_Types_For_Distribution_Claim';

export default class Csx_cmp_createDistributionClaim extends NavigationMixin(LightningElement) {

    stylePath = csxStyle;
    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }

    label = {
        errorMessage,
        calculateAmountError,
        calculateAmountSuccess,
        deleteRecordSuccessMessage,
        deleteRecordErrorMessage,
        claimAmountMisMatchErrorMessage,
        createDistributionClaimSuccessMessage,
        noDistributionRecordsErrorMessage,
        clickCalculateAmountErrorMessage,
        distributionClaimCreationMsgForMexicanRR,
        noNewClaimsCreatedErrorMessage,
        claimAlreadyExistsErrorMessage,
        applicableClaimTypes
    };

    @api recordId;
    @api equipIDClaimType;
    @api equipmentID;
    equipment;
    claimClosed;
    error;
    showSpinner = false;
    @track distributionRecords;
    equipmentName;
    count;
    isRecordPage = false;
    disableCreateClaimButton = true;
    displayCreateClaimButton = false;

    @wire(CurrentPageReference)
    currentPageReference(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.type === 'standard__recordPage') {
                this.isRecordPage = true;
            } else {
                this.isRecordPage = false;
            }

            if (!this.isRecordPage) {
                let stateParameters = currentPageReference.state;
                let recId = stateParameters.c__recordId;
                if (recId !== undefined && recId !== null && recId !== '') {
                    this.recordId = recId;
                }
            }
        }
    }

    @wire(isClaimCreationAllowed, { permissionName: 'CSX_CMP_Create_Distribution_Claim' })
    claimCreationAllowed({ error, data }) {
        if (data) {
            this.displayCreateClaimButton = data;
        } else if (error) {
            this.displayCreateClaimButton = false;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [newTotalManualadjAmount, totalclaimamounts, name, isClaimClosed, claimType, origin] })
    record({ error, data }) {
        if (data) {
            this.equipment = data;
            this.error = undefined;
            this.equipmentName = this.equipment.fields.Name.value;
            if (this.equipment.fields.CSX_CMP_Claim__r.value) {
                let claim = this.equipment.fields.CSX_CMP_Claim__r.value;
                this.claimClosed = claim.fields.IsClosed.value;
            }

            if (this.equipment !== undefined) {
                this.showSpinner = false;
            }

            this.checkClaimType();
        } else if (error) {
            this.error = error;
            this.equipment = undefined;
        }
    }

    checkClaimType() {
        if (this.equipment.fields.CSX_CMP_Claim__r.value === null || this.equipment.fields.CSX_CMP_Claim__r.value === undefined) {
            return;
        }
        let claimType = this.equipment.fields.CSX_CMP_Claim__r.value.fields.Type.value;
        let claimOrigin = this.equipment.fields.CSX_CMP_Claim__r.value.fields.Origin.value;
        if ((this.label.applicableClaimTypes.split(',').includes(claimType) || (claimType === 'FC RR Inbound Claim' && claimOrigin === 'Manual')) && this.displayCreateClaimButton) {
            this.displayCreateClaimButton = true;
        } else {
            this.displayCreateClaimButton = false;
        }
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Distributions__r',
        fields: ['CSX_CMP_Distribution__c.Name', 'CSX_CMP_Distribution__c.CSX_CMP_Code_Road__c', 'CSX_CMP_Distribution__c.CSX_CMP_Junction__c', 'CSX_CMP_Distribution__c.CSX_CMP_Miles__c', 'CSX_CMP_Distribution__c.CSX_CMP_Adj_Miles__c', 'CSX_CMP_Distribution__c.CSX_CMP_Point__c', 'CSX_CMP_Distribution__c.CSX_CMP_Calculated_Amount__c', 'CSX_CMP_Distribution__c.CSX_CMP_Manual_Adj_Amt__c', 'CSX_CMP_Distribution__c.CSX_CMP_Distribution_Claim__c', 'CSX_CMP_Distribution__c.CSX_CMP_Distribution_Claim__r.CaseNumber', 'CSX_CMP_Distribution__c.CSX_CMP_Hold_RR_Distribution__c', 'CSX_CMP_Distribution__c.CSX_CMP_Distribution_Sequence__c']
    })
    relatedListRecords({ error, data }) {
        if (data) {
            this.assignData(data.records);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.distributionRecords = undefined;
        }
    }

    assignData(data) {
        let distributionRecords = [];
        data.forEach((element) => {
            let record = {};
            record.id = element.id;
            Object.keys(element.fields).forEach((key) => {
                if (key === 'CSX_CMP_Distribution_Claim__r' && element.fields[key].value !== null) {
                    let parentRecord = element.fields[key].value;
                    Object.keys(parentRecord.fields).forEach((key1) => {
                        let recordKey = key + '.' + key1;
                        record[recordKey] = parentRecord.fields[key1].value;
                    });
                } else {
                    record[key] = element.fields[key].value;
                }
            });
            record.distributionURL = '/' + element.id;
            if (element.fields.CSX_CMP_Distribution_Claim__c.value !== null) {
                record.distributionClaimURL = '/' + element.fields.CSX_CMP_Distribution_Claim__c.value;
            }
            distributionRecords.push(record);
        });
        distributionRecords = distributionRecords.sort((a, b) => (a.CSX_CMP_Distribution_Sequence__c > b.
            CSX_CMP_Distribution_Sequence__c) ? 1 : -1);
        this.distributionRecords = distributionRecords;
        this.data = distributionRecords;
        this.count = this.distributionRecords.length;
    }

    //Page Navigation Methods

    openRelatedList() {
        let recId = this.recordId.toString();
        let url = '/lightning/n/CSX_CMP_Distribution_RelatedListViewAll?c__recordId=' + recId;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            },
        });
    }


    openEquipmentRecord() {
        let url = '/lightning/r/CSX_CMP_Equipment__c/' + this.recordId + '/view';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    openEquipmentHomepage() {
        let url = '/lightning/o/CSX_CMP_Equipment__c/home';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    // End of Page Navigation Methods
    // Start of Row Action Methods

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.editRow(row);
                break;
            case 'delete':
                this.deleteRow(row);
                break;
            default:
        }
    }

    createRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'CSX_CMP_Distribution__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: 'CSX_CMP_Equipment__c=' + this.recordId
            }
        });
    }

    editRow(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.id,
                objectApiName: 'CSX_CMP_Distribution__c',
                actionName: 'edit'
            }
        });
    }

    deleteRow(row) {
        this.showSpinner = true;
        deleteRecord(row.id).then(() => {
            this.showSpinner = false;
            let event = new ShowToastEvent({
                title: 'Success',
                message: this.label.deleteRecordSuccessMessage,
                variant: 'success'
            });
            this.dispatchEvent(event);
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            let event = new ShowToastEvent({
                title: 'Error',
                message: this.label.deleteRecordErrorMessage,
                variant: 'error'
            });
            this.dispatchEvent(event);
        });
    }

    // End of Row Action Methods

    calculateAmount() {
        let ids = [];
        ids.push(this.equipment.id);
        if (this.distributionRecords.length > 0) {
            calculateDistribution({ equipmentID: ids }).then(result => {
                let records = [];
                let successToastMessage = '';
                let errorToastMessage = '';
                if (result !== null && result !== undefined && result !== '') {
                    result.forEach((element) => {
                        let record = this.distributionRecords.find((item) => item.id === element.Id);
                        Object.keys(record).forEach((key) => {
                            if (element[key] !== undefined) {
                                record[key] = element[key];
                            }
                        });
                        records.push(record);
                    });
                    records.forEach((element) => {
                        if (element.CSX_CMP_Code_Road__c.includes('FXE')) {
                            errorToastMessage = errorToastMessage + element.Name + ',';
                        } else {
                            successToastMessage = successToastMessage + element.Name + ',';
                        }
                    });
                    errorToastMessage = errorToastMessage.substring(0, errorToastMessage.length - 1);
                    successToastMessage = successToastMessage.substring(0, successToastMessage.length - 1);

                    this.distributionRecords = records;
                    this.disableCreateClaimButton = false;
                } else {
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: this.label.calculateAmountError,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
            }).catch(error => {
                let event = new ShowToastEvent({
                    title: 'Error',
                    message: this.label.calculateAmountError,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            });
        } else {
            let event = new ShowToastEvent({
                title: 'Error',
                message: this.label.noDistributionRecordsErrorMessage,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }

    }


    handleCreateDistributionClaim() {
        getEquipmentDetails({ recordId: this.recordId }).then(result => {
            let newTotalManualadj = result.CSX_CMP_Total_Manual_Adj_Amount__c;
            let totalclaim = result.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c;
            this.showSpinner = true;
            if (this.distributionRecords === undefined || this.distributionRecords === null || this.distributionRecords.length === 0) {
                let event = new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noDistributionRecordsErrorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.showSpinner = false;
            } else if (newTotalManualadj === null || newTotalManualadj === undefined || newTotalManualadj === 0) {
                let event = new ShowToastEvent({
                    title: 'Error',
                    message: this.label.clickCalculateAmountErrorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.showSpinner = false;
            } else {
                if (newTotalManualadj === totalclaim) {
                    this.createDistribution();
                } else {
                    this.showSpinner = false;
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: this.label.claimAmountMisMatchErrorMessage,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);

                }
            }
        })

    }

    createDistribution() {
        let recordId = this.recordId;
        createNewClaims({ sourceId: recordId }).then(result => {
            let response;
            let distributionRecords = this.distributionRecords;
            if (result !== null && result !== undefined && result !== '') {
                response = JSON.parse(result);
                let errorMap = response[0];
                let successToastMessage = '';
                let errorToastMessage = '';
                distributionRecords.forEach((element) => {
                    if (errorMap[element.id] !== undefined) {
                        errorToastMessage = errorToastMessage + element.Name + ' : ' + errorMap[element.id] + ',';
                    } else if (!element.CSX_CMP_Code_Road__c.includes('FXE') && !element.CSX_CMP_Code_Road__c.includes('CSXT')) {
                        if (element.CSX_CMP_Distribution_Claim__c === null || element.CSX_CMP_Distribution_Claim__c === undefined || element.CSX_CMP_Distribution_Claim__c === '') {
                            let record = response.find((item) => item.distributionId === element.id);
                            if (record !== undefined) {
                                element.CSX_CMP_Distribution_Claim__c = record.claimId;
                                element.CSX_CMP_Distribution_Claim__r = {};
                                element.CSX_CMP_Distribution_Claim__r.CaseNumber = record.CaseNumber;
                                element.distributionClaimURL = '/' + record.claimId;
                                successToastMessage = successToastMessage + element.Name + ',';
                            }
                        }
                    }
                });
                errorToastMessage = errorToastMessage.substring(0, errorToastMessage.length - 1);
                successToastMessage = successToastMessage.substring(0, successToastMessage.length - 1);
                if (successToastMessage !== '') {
                    let event = new ShowToastEvent({
                        title: 'Success',
                        message: this.label.createDistributionClaimSuccessMessage + ' for ' + successToastMessage,
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                }
                if (errorToastMessage !== '') {
                    let event = new ShowToastEvent({
                        title: 'Error',
                        // message: this.label.claimAlreadyExistsErrorMessage + ' ( ' + errorToastMessage + ' )',
                        message: errorToastMessage,
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                }
                this.distributionRecords = distributionRecords;
                this.disableCreateClaimButton = true;
                setTimeout(() => {
                    location.reload(), 20000
                });
            } else {
                let event = new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noNewClaimsCreatedErrorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            }
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            csx_cmp_logError('Csx_cmp_createDistributionClaim', 'createNewClaims', error, '');
        });
    }

    rowActions = [
        { label: 'Edit', name: 'edit' },
        // { label: 'Delete', name: 'delete' },
    ]

    columns = [
        {
            label: 'Distribution #', fieldName: 'distributionURL', type: 'url', sortable: true,
            typeAttributes: {
                label: { fieldName: 'Name' }, target: '_blank'
            },
            callAttributes: {
                alignment: 'left',
            }, initialWidth: 130,
        },
        {
            label: 'Code Road', fieldName: 'CSX_CMP_Code_Road__c', type: 'text',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 130,
        },
        {
            label: 'Junction', fieldName: 'CSX_CMP_Junction__c', type: 'text',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 110,
        },
        {
            label: 'Miles', fieldName: 'CSX_CMP_Miles__c', type: 'number',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 100,
        },
        {
            label: 'Adj Miles', fieldName: 'CSX_CMP_Adj_Miles__c', type: 'number',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 100,
        },
        {
            label: 'Points', fieldName: 'CSX_CMP_Point__c', type: 'text',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 90,
        },
        {
            label: 'Calculated Amount', fieldName: 'CSX_CMP_Calculated_Amount__c', type: 'currency',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 145,
        },
        {
            label: 'Manual Adj Amount', fieldName: 'CSX_CMP_Manual_Adj_Amt__c', type: 'currency',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 145,
        },
        {
            label: 'Distribution Claim', fieldName: 'distributionClaimURL', type: 'url',
            cellAttributes: {
                alignment: 'left',
            },
            typeAttributes: {
                label: { fieldName: 'CSX_CMP_Distribution_Claim__r.CaseNumber' },
                target: '_blank'
            }, initialWidth: 150,
        },
        {
            label: 'Hold RR Distribution', fieldName: 'CSX_CMP_Hold_RR_Distribution__c', type: 'boolean',
            cellAttributes: {
                alignment: 'left',
            }, initialWidth: 90,
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: this.rowActions,
                menuAlignment: 'auto',
            }
        }
    ];

}