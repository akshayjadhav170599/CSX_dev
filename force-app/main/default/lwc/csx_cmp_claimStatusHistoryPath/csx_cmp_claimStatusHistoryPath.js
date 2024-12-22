import { LightningElement, api, wire, track } from 'lwc';
import getClaimStatusHistory from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.getClaimStatusHistory';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';

export default class Csx_cmp_claimStatusHistoryPath extends LightningElement {

    @api
    recordId;

    @track statusValues = [];
    isRendered = false;
    callRender = false;
    currentStatus = '';

    @wire(getClaimStatusHistory, { claimId: '$recordId' })
    claimStatusHistory;

    @wire(getRecord, { recordId: '$recordId', fields: ['Case.Status'] })
    wiredRecord({ error, data }) {
        if (data) {
            let status = data.fields.Status.value;
            if (!this.currentStatus) {
                this.currentStatus = status;
            } else if (this.currentStatus != status) {
                this.handleRefresh();
            }
        } else if (error) {
            console.log('error', error);
        }
    }

    handleRefresh() {
        this.callRender = false;
        this.isRendered = false;
        this.statusValues = [];
        this.claimStatusHistory = refreshApex(this.claimStatusHistory);
    }


    get claimStatusHistoryValues() {
        let values = [];
        let count = 0;
        //let historyValues = this.claimStatusHistory.data;
        let historyValues;
        if(this.claimStatusHistory.data){
            historyValues = this.claimStatusHistory.data;
        }
        console.log('historyValues', historyValues);
        if (historyValues != undefined && historyValues.length > 0) {
            historyValues.forEach(element => {
                let value = {};
                
                value.label = element.OldValue;
                value.class = 'slds-path__item slds-is-incomplete liClass';
                value.id = count;
                value.tabIndex = '-1';
                values.push(value);
                count++;
            });
            if (historyValues[historyValues.length - 1].NewValue) {
                let valueLast = {};
                valueLast.label = historyValues[historyValues.length - 1].NewValue;
                valueLast.class = 'slds-path__item slds-is-current slds-is-active liClass';
                valueLast.id = count + 1;
                valueLast.tabIndex = '0';
                values.push(valueLast);
            }
            this.callRender = true;
        }
        this.statusValues = values;
        return this.statusValues;
    }

    renderedCallback() {
        if (!this.isRendered && this.callRender && this.statusValues.length > 0) {
            this.isRendered = true;
            let innerWidth = window.innerWidth;
            // set width of each list element
            let ulClass = this.template.querySelector('.ulClass');
            ulClass.style.width = (this.statusValues.length * 150) + 'px';
            // scroll to last element
            let lastElement = this.template.querySelector('.liClass.slds-is-current');
            if (lastElement) {
                lastElement.scrollIntoView({ behavior: 'smooth', block: 'end' });
            }
            // check if scrollbar is present
            let firstDiv = this.template.querySelector('div');
            let width = parseInt(ulClass.style.width ? ulClass.style.width.replace('px', '') : 0);
            if (this.statusValues) {
                if (width > innerWidth) {
                    firstDiv.style['scrollbar-width'] = 'thin';
                } else {
                    firstDiv.style['scrollbar-width'] = 'none';
                }
            }
        }
    }
}