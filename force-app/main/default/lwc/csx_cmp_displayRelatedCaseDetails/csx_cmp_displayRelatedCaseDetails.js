import { LightningElement, track, wire, api } from 'lwc';
import fetchCaseSummary from '@salesforce/apex/CSX_CMP_InterfaceUtility.fetchCaseSummary';
import linkRelatedCases from '@salesforce/apex/CSX_CMP_RelatedCasesController.linkRelatedCases';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEquipmentNumber from '@salesforce/apex/CSX_CMP_RelatedCasesController.getEquipmentNumber';
import notFound from '@salesforce/label/c.CSX_CMP_NoResultsFound';
import { CurrentPageReference , NavigationMixin } from 'lightning/navigation';
import caseNumber from '@salesforce/schema/Case.CaseNumber';
import { getRecord } from 'lightning/uiRecordApi';

const caseDetailColumn = [

    { label: 'Case Number', fieldName: 'caseUrl', type: 'url', sortable: "true", initialWidth: 125, typeAttributes: { label: { fieldName: 'caseNumber' }, target: '_blank' }, hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
    { label: 'Case Date', fieldName: 'caseDate', type: 'date', sortable: "true", hideDefaultActions: true, initialWidth: 120, typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' } },
    { label: 'Status', fieldName: 'status', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 110 },
    { label: 'Company Name', fieldName: 'companyName', type: 'text', sortable: "true", wrapText: true, hideDefaultActions: false 
    , initialWidth: 255 },
    { label: 'Contact Name', fieldName: 'createdBy', type: 'text', sortable: "true", hideDefaultActions: false, wrapText: true
    , initialWidth: 190}
];

export default class Csx_cmp_displayRelatedCaseDetails extends NavigationMixin(LightningElement){
    caseColumn = caseDetailColumn;
    caseColumnForRelatedList = [

        { label: 'Case Number', fieldName: 'caseUrl', type: 'url', sortable: "true", initialWidth: 160, typeAttributes: { label: { fieldName: 'caseNumber' }, target: '_blank' }, hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
        { label: 'Case Date', fieldName: 'caseDate', type: 'date', sortable: "true", hideDefaultActions: true, initialWidth: 160, typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' } },
        { label: 'Status', fieldName: 'status', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 150 },
        { label: 'Company Name', fieldName: 'companyName', type: 'text', sortable: "true", wrapText: true, hideDefaultActions: false 
        , initialWidth: 400 },
        { label: 'Contact Name', fieldName: 'createdBy', type: 'text', sortable: "true", hideDefaultActions: false, wrapText: true
        , initialWidth: 350}
    ];
    @track claimRecordList = [];
    @track data = [];
    disableLinkButton = true;
    equipmentId;
    @track selectedClaimId = [];
    @track selectedClaim = [];
    sortByName = 'caseUrl';
    sortDirection = 'asc';
    searchData = false;
    relatedCaseNumber = [];
    relatedCaseRecords = [];
    existingRecord = [];
    defaultRecordsonPage = true;
    //recordId;
    isSpinner = false;
    isDataAvailable = false;
    count = 0;
    label = {
        notFound
    };
    @api recordId;
    caseNo;
    caseDetails;
    isRecordPage;
    
    connectedCallback() {
        console.log('Call connect');
        this.isSpinner = true;
        getEquipmentNumber({ claimId: this.recordId })
        .then(result => {
            if(result){
                this.equipmentId = result;
            }
        })
        .catch(error => {
            this.isSpinner = false;
            csx_cmp_logError('Csx_cmp_displayRelatedCases', 'connectedCallback', error, '');
        });

        setTimeout(() => {
            if(this.equipmentId){
                this.disableLinkButton = true;
                fetchCaseSummary({ equipmentId: this.equipmentId })
                    .then(result => {
                        if(result){
                            this.claimRecordList = result;
                            if (this.claimRecordList && this.claimRecordList.length > 0) {
                                this.count = this.claimRecordList.length;
                                this.data = this.claimRecordList;
                                if (this.isRecordPage) {
                                    this.data = this.data.slice(0, 24);
                                }
                                this.isSpinner = false;
                            }else{
                                this.isSpinner = false;
                            }
                            this.searchData = true;
                        }else{
                            this.isSpinner = false;
                        }
                    })
                    .catch(error => {
                        this.isSpinner = false;
                        csx_cmp_logError('Csx_cmp_displayRelatedCases', 'connectedCallback', error, '');
                    })
                }else{
                    this.isSpinner = false;
                }
        }, 2000);
        
    }

    @wire(getRelatedListRecords, {parentRecordId: '$recordId',relatedListId: 'Related_Cases__r',
        fields: ['CSX_CMP_Related_Case__c.CSX_CMP_Case_Number__c']})
    relatedListRecords({ error, data }) {
        if (data) {
            this.assignData(data.records);
        } else if (error) {
            console.log('Error',error);
        }
    }

    assignData(data) {
        this.relatedCaseRecords = [];
        data.forEach((element) => {
            Object.keys(element.fields).forEach((key) => {
                if (key === 'CSX_CMP_Case_Number__c' && element.fields[key].value !== null) {
                    this.relatedCaseRecords.push(element.fields[key].value);
                }
            })
        })
    }

    

    handleRowSelection(event) {
        this.selectedClaim = [];
        let selectedRows = event.detail.selectedRows;
        this.selectedClaim = JSON.stringify(selectedRows);
        if (selectedRows.length > 0) {
            this.disableLinkButton = false;
        } else {
            this.disableLinkButton = true;
        }
    }

    handleLinkClaim() {
        this.existingRecord = [];
        let newSelectedClaim = [];
        if(this.selectedClaim){
            for (const caseObject of JSON.parse(this.selectedClaim)) {
                if(this.relatedCaseRecords && !this.relatedCaseRecords.includes(caseObject.caseNumber)){
                    newSelectedClaim.push(caseObject);
                }else{
                    this.existingRecord.push(caseObject.caseNumber);
                }     
            }
        }
        
        if(newSelectedClaim && newSelectedClaim.length > 0){
            linkRelatedCases({ claimId: this.recordId, selectedCases: JSON.stringify(newSelectedClaim) })
                .then(result => {
                    if (result) {
                        this.showToast('Success', 'Linked successfully.', 'success');
                        setTimeout(() => {
                            location.reload();
                        }, 2000);
                    }
                    if(this.existingRecord && this.existingRecord.length > 0){
                        setTimeout(() => {
                            this.showToast('Warning', 'Case '+this.existingRecord+' already linked to the claim.', 'warning');
                            this.closeQuickAction();
                        }, 1000);
                    }else{
                        this.closeQuickAction();
                    }
                })
                .catch(error => {
                    csx_cmp_logError('Csx_cmp_displayRelatedCases', 'handleLinkClaim', error, '');
                })
        }else{
           this.showToast('Warning', 'Case '+this.existingRecord+' already linked to the claim.', 'warning');
        }
    }

    handleClaimRecordsDisplay(event) {
        this.data = event.detail;
    }

    doSortingCaseNumber(event) {
        let sortbyField = event.detail.fieldName;
        if (sortbyField === "caseUrl") {
            this.sortByName = "caseNumber";
        }
        else {
            this.sortByName = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortByName, this.sortDirection);
        this.sortByName = sortbyField;
    }

    sortData(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.data);
        this.data = sortResult.sort(function (a, b) {
            a = a[fieldName] ? a[fieldName] : '';
            b = b[fieldName] ? b[fieldName] : '';
            if (a < b) {
                return sortDirection === 'asc' ? -1 : 1;
            } else if (a > b) {
                return sortDirection === 'asc' ? 1 : -1;
            } else {
                return 0;
            }
        })
        if (this.searchData) {
            this.searchData = false;
        } else {
            this.searchData = true;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }



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

    @wire(getRecord, { recordId: '$recordId', fields: [caseNumber] })
    record({ error, data }) {
        if (data) {
            this.caseDetails = data;
            this.error = undefined;
            this.caseNo = this.caseDetails.fields.CaseNumber.value;
            if (this.caseDetails !== undefined) {
                this.showSpinner = false;
            }
        } else if (error) {
            this.error = error;
            this.caseDetails = undefined;
        }
    }

     //Page Navigation Methods

    openRelatedList() {
        let recId = this.recordId.toString();
        let url = '/lightning/n/CSX_CMP_Related_Case_Summary?c__recordId=' + recId;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            },
        });
    }

    openCaseRecord() {
        let url = '/lightning/r/Case/' + this.recordId + '/view';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    openCaseHomepage() {
        let url = '/lightning/o/Case/home';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

}