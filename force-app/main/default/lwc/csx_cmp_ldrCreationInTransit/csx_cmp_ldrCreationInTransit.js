import { LightningElement, api, wire, track } from 'lwc';

// standard imports
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import ldr from "@salesforce/schema/CSX_CMP_LD_Report__c";

// custom labels
import submit from '@salesforce/label/c.CSX_CMP_LDRCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import backToSearch from '@salesforce/label/c.CSX_CMP_BackToSearchLabel';

// apex handler imports
import createLDReport from '@salesforce/apex/CSX_CMP_LDRCreationController.createLDReport';

// custom imports
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_ldrCreationInTransit extends LightningElement {

    /* 
    This is the single component handling both the LDR creation in transit and LDR creation recovery.
    This component is called from ldr Entry with the selectedType as a parameter.
    */

    label = {
        backToSearch, submit, reset,
        noShipmentSelected: 'Please select at least one shipment to proceed'
    };
    userId = Id;
    @api selectedType;
    typeOptions;
    @track inTransit = {
        'reportType': '',
        'noWaybillFlag': '',
        'equipNo': '',
        'vin': '',
        'incidentLocation': '',
        'damageReason': '',
        'cause': '',
        'incidentAction': '',
        'incidentComments': '',
        'recoveryAmount': '',
        'equipment': [],
        'source': 'Manual',
        'reportedDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
    };

    isRecoveryType = false;

    issueOptions;
    causeOptions;
    actionOptions;

    hidenoWaybill = false;
    showSpinner = false;
    equipNoRequired = true;
    vinRequired = true;

    @wire(getRecord, { recordId: '$userId', fields: ['User.FederationIdentifier', 'User.FirstName'] })
    wiredUser({ error, data }) {
        if (data) {
            let reportedBy = data.fields.FederationIdentifier.value;
            if (reportedBy) {
                reportedBy = reportedBy.split('@')[0];
                this.inTransit.reportedBy = reportedBy;

            } else {
                reportedBy = data.fields.FirstName.value;
                this.inTransit.reportedBy = reportedBy;
            }
        } else if (error) {
            csx_cmp_logError('Csx_cmp_ldrCreationInTransit', 'wiredUser', error, '');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: ldr, recordTypeId: '012000000000000AAA', })
    objectInfo({ data, error }) {
        if (data) {
            let result = data.picklistFieldValues;
            this.assignPicklistValues(result);
        }
        else {
            console.log(error);
        }
    }

    assignPicklistValues(result) {
        let typeValues = result.CSX_CMP_LD_Type__c;
        let typeOptions = []
        typeValues.values.forEach(key => {
            typeOptions.push({ label: key.label, value: key.value });
        });
        this.typeOptions = typeOptions;
        this.inTransit.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;
        if (this.inTransit.reportType === 'Recovery') {
            this.isRecoveryType = true;
        }

        let issueValues = result.CSX_CMP_Damage_Reason__c;
        let issueValue = issueValues.controllerValues['In transit'];
        let issueOptions = []
        issueValues.values.forEach(key => {
            if (key.validFor.includes(issueValue)) {
                issueOptions.push({ label: key.label, value: key.value });
            }
        });
        let recoveryOption = issueValues.values.find(option => option.value === 'Theft/Vandalism');
        issueOptions.push({ label: recoveryOption.label, value: recoveryOption.value });
        this.issueOptions = issueOptions;

        let causeValues = result.CSX_CMP_Cause__c;
        let causeValue = causeValues.controllerValues['In transit'];
        let causeOptions = []
        causeValues.values.forEach(key => {
            if (key.validFor.includes(causeValue)) {
                causeOptions.push({ label: key.label, value: key.value });
            }
        });

        let recoveryOptionCause = causeValues.values.find(option => option.value === 'Theft/Vandalism');
        causeOptions.push({ label: recoveryOptionCause.label, value: recoveryOptionCause.value });
        this.causeOptions = causeOptions;

        let actionValues = result.CSX_CMP_Incident_Action__c;
        let actionOptions = []
        actionValues.values.forEach(key => {
            actionOptions.push({ label: key.label, value: key.value });
        });
        this.actionOptions = actionOptions;

        if (this.isRecoveryType === true) {
            this.inTransit.damageReason = this.issueOptions.find(option => option.value === 'Theft/Vandalism').value;
            this.inTransit.cause = this.causeOptions.find(option => option.value === 'Theft/Vandalism').value;
            this.inTransit.incidentAction = this.actionOptions.find(option => option.value === 'Recovery').value;
        } else {
            this.issueOptions.splice(this.issueOptions.length - 1, 1);
            this.causeOptions.splice(this.causeOptions.length - 1, 1);

        }
    }

    handleInputChange(event) {
        if (event.target.type === 'checkbox') {
            this.inTransit[event.target.name] = event.target.checked;
            if (this.inTransit.noWaybillFlag === true) {
                this.hidenoWaybill = true;
                this.inTransit.equipment = [];
                this.vinRequired = true;
                this.equipNoRequired = true;
            } else {
                this.hidenoWaybill = false;
            }
        } else {
            this.inTransit[event.target.name] = event.target.value;
        }

        if (event.target.name === 'equipNo') {
            if (event.target.value) {
                this.vinRequired = false;
                this.equipNoRequired = true;
            } else {
                this.vinRequired = true;
                this.equipNoRequired = false;
            }

            this.validateEquipment();
        }

        if (event.target.name === 'vin') {
            if (event.target.value) {
                this.equipNoRequired = false;
                this.vinRequired = true;
            } else {
                this.equipNoRequired = true;
                this.vinRequired = false;
            }
            this.validateVin();
        }
    }

    validateEquipment() {
        let equipment = this.template.querySelector('[data-id="equipNo"]');
        let error = "";
        if (this.inTransit.equipNo.length > 0) {
            let equip = equipment.value;
            if (equip.length !== 0) {
                let initial;
                let number;
                let regex = /^[A-Za-z]{2,4}[0-9]{1,6}$/;

                console.log('equip', equip, equip.length);
                if (equip.length >= 3 && equip.length <= 11) {
                    // check whether the equipment number contains special characters
                    let specialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
                    if (specialChar.test(equip)) {
                        console.log('specialChar', specialChar.test(equip));
                        error = 'Special characters are not allowed in Equipment Number';
                    } else {
                        let equipList = equip.split(/([0-9]+)/);
                        initial = equipList[0];
                        number = equipList[1];
                    }
                }

                let equipmentNumber = '';
                if (initial && number) {
                    equipmentNumber = initial.trim() + number.trim();
                }
                console.log('equipmentNumber', equipmentNumber);

                if (error === "" && !equipmentNumber.match(regex)) {
                    error = 'Invalid Equipment Number';
                }

            }
        }
        equipment.setCustomValidity(error);
        equipment.reportValidity();
    }

    validateVin() {
        let vin = this.template.querySelector('[data-id="vin"]');
        let error = "";
        if (this.inTransit.vin.length > 0) {
            let vinValue = vin.value;
            if (vinValue.length !== 0) {
                let specialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
                if (specialChar.test(vinValue)) {
                    error = 'Special characters are not allowed in VIN';
                }
            }
        }
        vin.setCustomValidity(error);
        vin.reportValidity();
    }


    handleShipmentsReceived(event) {
        this.inTransit.equipment = [];
        let equipments = JSON.parse(event.detail);
        if (equipments && equipments.length > 0) {
            equipments.forEach((equipment) => {
                equipment.waybillDate = equipment.waybillDate != undefined ? new Date(equipment.waybillDate).toISOString().split('T')[0] : null;
                equipment.urrwinDate = equipment.urrwinDate != undefined ? new Date(equipment.urrwinDate).toISOString().split('T')[0] : null;
                equipment.equipmentInitial = equipment.equipmentInitial;
                equipment.equipmentNumber = equipment.equipmentNumber;
                let products = [];
                if (equipment.vinNum.length > 0) {
                    equipment.vinNum.forEach((vin) => {
                        let tempProduct = {};
                        tempProduct.vin = vin;
                        tempProduct.rowNumber = 1;
                        products.push(tempProduct);
                    });
                    equipment.products = [...equipment.products, ...products];
                }
            });
        }
        this.inTransit.equipment = equipments;

    }

    submit() {
        this.showSpinner = true;
        let recordMap = {};
        let isValid = this.validateInput();
        if (isValid) {
            Object.keys(this.inTransit).forEach(key => {
                if (key === 'equipment') {
                    recordMap[key] = JSON.stringify(this.inTransit[key]);
                } else if (key === 'reportedDate') {
                    recordMap[key] = recordMap[key] != undefined ? recordMap[key].toString().split('T')[0] : null;
                } else {
                    if (this.inTransit[key]) {
                        recordMap[key] = this.inTransit[key].toString();
                    }
                }
            });

            createLDReport({ recordMap: recordMap }).then(result => {
                this.showSpinner = false;
                if (result) {
                    this.dispatchEvent(new CustomEvent('creation', { detail: JSON.stringify(result) }));
                }
            }).catch(error => {
                this.showSpinner = false;
                csx_cmp_logError('Csx_cmp_ldrCreationInTransit', 'createLDReport', error, '');

            });
        } else {
            this.showSpinner = false;
        }

    }

    validateInput() {
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        let isValid = true;
        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        if (this.inTransit.noWaybillFlag === true) {
            let shipmentList = [];
            let shipment = {
                'equipmentInitial': '',
                'equipmentNumber': '',
                'vinNum': [],
                'parties': [],
                'products': [],
            };
            Object.keys(this.inTransit).forEach(key => {
                if (key === 'equipNo' && this.inTransit[key].length > 0) {
                    let equip = this.inTransit[key].split(/([0-9]+)/);
                    if (equip.length > 1) {
                        shipment.equipmentInitial = equip[0].toUpperCase();
                        shipment.equipmentNumber = equip[1];
                    }
                } else if (key === 'vin' && this.inTransit[key].length > 0) {
                    let product = {
                        'vin': this.inTransit[key],
                    }
                    shipment.products.push(product);
                }
            });
            shipmentList.push(shipment);
            this.inTransit.equipment = shipmentList;
        } else {
            if (this.inTransit.equipment.length === 0) {
                isValid = false;
                let event = new ShowToastEvent({
                    title: 'Error',
                    message: this.label.noShipmentSelected,
                    variant: 'error',
                });
                this.dispatchEvent(event);
            }
        }
        return isValid;
    }


    resetPage() {
        this.inTransit = {
            'reportType': '',
            'noWaybillFlag': '',
            'equipNo': '',
            'vin': '',
            'incidentLocation': '',
            //'address': '',
            'damageReason': '',
            'cause': '',
            'incidentAction': '',
            //'estimatedLadingLoss': '',
            'incidentComments': '',
            'recoveryAmount': '',
            'equipment': [],
            'source': 'Manual',
            'reportedDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
        }

        let shipments = this.template.querySelector('c-csx_cmp_shipment-Search');
        if (shipments) {
            shipments.resetPage();
        }
        this.locationLookupReset();

        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea'), ...this.template.querySelectorAll('lightning-input-field')];
        inputFields.forEach(field => {
            let parameters = {
                required: false,
                type: field.type
            }
            field.type = '';
            field.value = '';
            if (field.required) {
                parameters.required = true;
                field.required = false;
            }
            field.setCustomValidity('');
            window.setTimeout(() => {
                field.reportValidity();
                if (parameters.required) {
                    field.required = true;
                }
                field.type = parameters.type;

                if (this.hidenoWaybill) {
                    this.inTransit.noWaybillFlag = true;
                } else {
                    this.inTransit.noWaybillFlag = false;
                }

                this.inTransit.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;
                if (this.inTransit.reportType === 'Recovery') {
                    this.inTransit.damageReason = this.issueOptions.find(option => option.value === 'Theft/Vandalism').value;
                    this.inTransit.cause = this.causeOptions.find(option => option.value === 'Theft/Vandalism').value;
                    this.inTransit.incidentAction = this.actionOptions.find(option => option.value === 'Recovery').value;
                }
            }, 500);
        });
    }

    locationLookupReset() {
        let incidentLocationLookupField = this.template.querySelector('lightning-input-field');
        incidentLocationLookupField.value = '';
        window.setTimeout(() => {
            incidentLocationLookupField.reportValidity();
        }, 500);
    }
}