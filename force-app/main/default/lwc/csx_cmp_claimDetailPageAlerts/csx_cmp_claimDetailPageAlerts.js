import { LightningElement, api, wire } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import ORIGIN_FIELD from "@salesforce/schema/Case.Origin";
import { loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import claimTypesForTotalCost from '@salesforce/label/c.CSX_CMP_Total_Cost_Calculation_Claim_Types';

export default class Csx_cmp_claimDetailPageAlerts extends LightningElement {
    @api recordId;
    objectInfo;
    freightRecType = false;
    rrRectype = false;
    //reviewFlagShow = false;
    ediOrigin = false;
    stylePath = csxStyle;
    recType;
    origin;
    amount;
    showPopup = false;
    flagColor;
    displayTotalCost = false;

    labels = {
        claimTypesForTotalCost
    };
   
    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['Case.RecordType.DeveloperName', 'Case.Type', ORIGIN_FIELD, 'Case.CSX_CMP_Total_Cost_of_Claim__c', 'Case.CSX_CMP_Review__c'] })
    wiredRecType({ data, error }) {
        if (data) {
            console.log('data', data);
            this.recType = data.recordTypeInfo.name;
            this.origin = data.fields.Origin;
            if (this.recType == 'Freight') {
                this.freightRecType = true;
                if (this.origin.value == 'EDI') {
                    this.ediOrigin = true;
                }
            }
            if (this.recType == 'Railroad Revenue') {
                this.rrRectype = true;
                console.log('CSX_CMP_Review__c', data.fields.CSX_CMP_Review__c.value);
                if (data.fields.CSX_CMP_Review__c.value == true) {
                    //this.reviewFlagShow = true;
                    this.flagColor = '--sds-c-icon-color-foreground-default: #CB0015;';
                } else {
                    //this.reviewFlagShow = false;
                    this.flagColor = '--sds-c-icon-color-foreground-default: #49A54C;';
                }
            }
            if (data.fields.CSX_CMP_Total_Cost_of_Claim__c) {
                this.amount = data.fields.CSX_CMP_Total_Cost_of_Claim__c;
            }

            let claimTypesList = [];
            this.labels.claimTypesForTotalCost.split(',').forEach(element => {

                let e = element.replace('\'', '');
                e = e.replace('Claim\'', 'Claim');
                claimTypesList.push(e.trim());

            });
            
            if (claimTypesList.includes(data.fields.Type.value)) {
                this.displayTotalCost = true;
            }
        } else if (error) {
            console.log('ERROR=====>', JSON.stringify(error))
        }
    }

    handleOpenPopup() {
        this.showPopup = true;
    }

    closeModal() {
        this.showPopup = false;
    }
}