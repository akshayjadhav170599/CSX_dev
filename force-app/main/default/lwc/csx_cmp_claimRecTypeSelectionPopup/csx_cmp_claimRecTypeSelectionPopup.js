import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Claim from '@salesforce/schema/Case';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getRoles from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.getRoleAccessConfiguration';
export default class Csx_cmp_claimRecTypeSelectionPopup extends NavigationMixin(LightningElement) {
    lstRecordTypes = [];
    error;
    showCreatePage = false;
    selectedOpt = '';
    selectedOption = '';
    @api isModalOpen = false;
    userRole = '';
    label = {
        noRecordTypes: 'No Record Types Available',
    }
    noRecordTypes = false;
    roleData;

    @wire(getRoles)
    wiredRoles({ data, error }) {
        console.log('data', data);
        console.log('error', error);
        this.noRecordTypes = false;
        if (data) {
            this.roleData = data;
            this.assignRecordTypes(this.roleData);
        }
        else if (error) {
            console.log('ERROR=====>', JSON.stringify(error));
        }
    }

    closeModal() {
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
    }

    assignRecordTypes(data) {
        if (data.length > 0) {
            let response = JSON.parse(data);
            console.log('respose : ', response);
            let metadata = response.roleAccessConfigList;
            let recordTypeMap = response.recordTypeMap;
            let recordTypes = metadata[0].CSX_CMP_Search_Layout_Access__c.split(',');
            if (recordTypeMap) {
                this.lstRecordTypes = [];
                if (response.roleAccessConfigList[0].CSX_CMP_Create_Claim__c) {
                    for (let key in recordTypeMap) {
                        if (key != 'Overcharge' && key != 'Master' && recordTypes.includes(key)) {
                            this.lstRecordTypes.push({ label: key, value: recordTypeMap[key] });
                        }
                    }
                }
                this.lstRecordTypes.sort((a, b) => (a.label > b.label) ? 1 : -1);
                if (this.lstRecordTypes.length > 0) {
                    this.selectedOpt = this.lstRecordTypes[0].value;
                    this.selectedOption = this.lstRecordTypes[0].label;
                }

                this.lstRecordTypes.forEach(element => {
                    console.log('element', element);
                    if (element.label == 'Freight') {
                        this.selectedOpt = element.value;
                        this.selectedOption = element.label;
                        return;
                    }
                });
            }
        }
        if (this.lstRecordTypes.length == 0) {
            this.noRecordTypes = true;
        }
    }


    connectedCallback() {
        this.noRecordTypes = false;
        if (this.roleData) {
            this.assignRecordTypes(this.roleData);
        }
    }

    handleRadioChange(event) {
        this.selectedOpt = event.detail.value;
        this.selectedOption = this.lstRecordTypes.find(opt => opt.value === this.selectedOpt).label;
    }

    openCreatePage() {
        this.dispatchEvent(new CustomEvent('modalapply', {
            detail: {
                label: this.selectedOption,
                value: this.selectedOpt
            }
        }));
    }


}