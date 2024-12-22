import { LightningElement, api, wire, track } from 'lwc';
import ldrType from '@salesforce/schema/CSX_CMP_LD_Report__c.CSX_CMP_LD_Type__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi'

export default class Csx_cmp_ldrCreateTypeSelectionPopup extends LightningElement {

    selectedOption = '';
    @api isModalOpen = false;
    @track picklistOptions = [];

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ldrType })
    picklistValues({ data, error }) {
        if (data) {
            let picklistValues = data.values;
            this.picklistOptionsInit(picklistValues);
        }
        else {
            console.log('error ::',error);
        }
    }

    picklistOptionsInit(picklistValues) {
        let picklistOptions = [];
        const values = Object.values(picklistValues);
        values.sort((a, b) => a.label.localeCompare(b.label));
        values.forEach((key) => {
            if (key.label === 'In transit') {
                picklistOptions.push({ label: key.label, value: key.value, display: true });
                this.selectedOption = key.value;
            } else {
                picklistOptions.push({ label: key.label, value: key.value, display: false });
            }
        });
        this.picklistOptions = picklistOptions;
    }


    handleRadioChange(event) {
        let selectedOpt = event.detail.value;
        this.picklistOptions.forEach(option => {
            if (option.value === selectedOpt) {
                option.display = true;
            } else {
                option.display = false;
            }
        });
        this.selectedOption = selectedOpt;
    }

    openCreatePage() {

        let data = {
            picklistOptions: this.picklistOptions,
        }
        console.log('call OpenCreate page',data);
        this.dispatchEvent(new CustomEvent('modalapply', {
            detail: JSON.stringify(data)
        }));
    }


    closeModal() {
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
    }

}