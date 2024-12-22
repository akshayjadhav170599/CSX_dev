import { LightningElement, track, api, wire } from 'lwc';
import getBusinessRule from "@salesforce/apex/CSX_CMP_SimulateBusinessRule.getBusinessRule";
import { getRecord } from "lightning/uiRecordApi";
import InvalidStatus from '@salesforce/label/c.CSX_CMP_Invalid_Status';
import FeatureNotApplicable from '@salesforce/label/c.CSX_CMP_Feature_Not_Applicable';

const FIELDS = ['CSX_CMP_Business_Rule__c.CSX_CMP_Status__c', 'CSX_CMP_Business_Rule__c.RecordType.DeveloperName'];

export default class Csx_cmp_simulateBusinessRule extends LightningElement {
    @track selectedCaseId;
    @api recordId;
    @track businessId;
    @track statusValue;
    @track recordtype;
    @track invalidStatus = false;
    @track data = false;
    errorMessage;
    error;
    result = false;
    displayLDRRecordPicker = false;

    label = { InvalidStatus, FeatureNotApplicable};

    filter = {
        criteria: [
            {
                fieldPath: 'CreatedById',
                operator: 'ne',
                value: '',
            }
        ],
        filterLogic: '(1)',
    };

    handleChange = (event) => {
        this.businessId = this.recordId;
        this.selectedCaseId = event.detail.recordId;
    }

    handleClick(){
        this.invalidStatus = false;
        this.result = false;
        if (!this.result) {
            getBusinessRule({ claimId: this.selectedCaseId, businessId: this.recordId })
                .then((result) => {
                    this.result = true;
                    this.result = result;
                })
                .catch((error) => {
                    console.log(error);
                    this.error = 'Something went wrong';
                });
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.invalidStatus = false;
            this.data = data;
            this.statusValue = this.data.fields.CSX_CMP_Status__c.value;
            this.recordtype = this.data.fields.RecordType.value.fields.DeveloperName.value;

            if (this.statusValue === 'Invalid') {
                this.invalidStatus = true;
                this.errorMessage = this.label.InvalidStatus;
            }
            else if (this.recordtype === 'CSX_CMP_RR_General_Rule' || this.recordtype === 'CSX_CMP_Task_Checklist') {
                this.invalidStatus = true;
                this.errorMessage = this.label.FeatureNotApplicable;
            }
            else if (error) {
                this.error = error;
            }
            if (this.recordtype === 'CSX_CMP_L_D_Report_Assignment') {
                this.displayLDRRecordPicker = true;
            }
        }
    }
}