import { LightningElement, api, wire, track } from 'lwc';

// standard imports
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import ldr from "@salesforce/schema/CSX_CMP_LD_Report__c";
import ldrType from '@salesforce/schema/CSX_CMP_LD_Report__c.CSX_CMP_LD_Type__c';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

// custom imports
import { csx_cmp_logError } from 'c/csx_cmp_logError';

// Apex handler imports
import createLDReport from '@salesforce/apex/CSX_CMP_LDRCreationController.createLDReport';

// custom labels
import submit from '@salesforce/label/c.CSX_CMP_LDRCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import backToSearch from '@salesforce/label/c.CSX_CMP_BackToSearchLabel';

export default class Csx_cmp_ldrCreationDerailment extends LightningElement {
    label = {
        backToSearch, submit, reset,
        noShipmentSelected: 'Please select at least one shipment to proceed'
    };
    userId = Id;
    @api selectedType;
    typeOptions;
    @track derailment = {
        'reportType': '',
        'incidentLocation': '',
        //'address': '',
        'damageReason': '',
        'cause': '',
        'incidentAction': '',
        //'estimatedLadingLoss': '',
        'incidentComments': '',
        'equipment': [],
        'source': 'Manual',
        'reportedDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
    };
    objData;
    issueOptions;
    causeOptions;
    actionOptions;
    showSpinner = false;

    //  Code change begined by Subodh to accomodate multiple different shipments selection
    selectedShipments = [];
    selectedShipmentsMap = new Map();
    columns = [

        { label: "Equipment ID", fieldName: 'equipment', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 110 },
        { label: "Origin", fieldName: 'origin', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Shipper", fieldName: 'shipperName', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Destination", fieldName: 'destination', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Consignee", fieldName: 'consigneeName', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Waybill #", fieldName: 'waybillNumber', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 90 },
        { label: "Waybill Date", fieldName: 'waybillDate', type: 'date', sortable: "true", typeAttributes: { day: '2-digit', month: '2-digit', year: 'numeric' }, hideDefaultActions: true, initialWidth: 110 },
        { label: "Shipment Type", fieldName: 'shipmentType', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 130 },
    ];

    // Code change ended by Subodh to accomodate multiple different shipments selection

    @wire(getRecord, { recordId: '$userId', fields: ['User.FederationIdentifier', 'User.FirstName'] })
    wiredUser({ error, data }) {
        if (data) {
            let reportedBy = data.fields.FederationIdentifier.value;
            if (reportedBy) {
                reportedBy = reportedBy.split('@')[0];
                this.derailment.reportedBy = reportedBy;

            } else {
                reportedBy = data.fields.FirstName.value;
                this.derailment.reportedBy = reportedBy;
            }
        } else if (error) {
            csx_cmp_logError('Csx_cmp_ldrCreationInTransit', 'wiredUser', error, '');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: ldr, recordTypeId: "012000000000000AAA", })
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
        let issueValues = result.CSX_CMP_Damage_Reason__c;
        let issueValue = issueValues.controllerValues.Derailment;
        let issueOptions = []
        issueValues.values.forEach(key => {
            if (key.validFor.includes(issueValue)) {
                issueOptions.push({ label: key.label, value: key.value });
            }
        });
        this.issueOptions = issueOptions;
        this.derailment.damageReason = this.issueOptions.find(option => option.value === 'I-Derailment').value;


        let causeValues = result.CSX_CMP_Cause__c;
        let causeValue = causeValues.controllerValues.Derailment;
        let causeOptions = []
        causeValues.values.forEach(key => {
            if (key.validFor.includes(causeValue)) {
                causeOptions.push({ label: key.label, value: key.value });
            }
        });
        this.causeOptions = causeOptions;
        this.derailment.cause = this.causeOptions.find(option => option.value === 'I-Derail').value;



        let actionValues = result.CSX_CMP_Incident_Action__c;
        let actionOptions = []
        actionValues.values.forEach(key => {
            actionOptions.push({ label: key.label, value: key.value });
        });
        this.actionOptions = actionOptions;
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: ldrType })
    picklistValues({ data, error }) {
        if (data) {
            let picklistValues = data.values;
            let picklistOptions = [];
            picklistValues.forEach((key) => {
                picklistOptions.push({ label: key.label, value: key.value });
            });
            this.typeOptions = picklistOptions;
            this.derailment.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;
        }
        else {
            console.log(error);
        }
    }


    handleContactDetailChange(event) {
        let detail = JSON.parse(event.detail);
        if (detail.label === 'contactName') {
            this.derailment.name = detail.value;
        } else if (detail.label === 'phoneNumber') {
            this.derailment.phone = detail.value;
        } else if (detail.label === 'email') {
            this.derailment.email = detail.value;
        }
    }

    handleInputChange(event) {
        if (event.target.type === 'checkbox') {
            this.derailment[event.target.name] = event.target.checked;
        } else {
            this.derailment[event.target.name] = event.target.value;
        }
    }

    handleShipmentsReceived(event) {
        this.derailment.equipment = [];
        let equipment = JSON.parse(event.detail);
        equipment.forEach(equipment => {
            equipment.waybillDate = equipment.waybillDate != undefined ? new Date(equipment.waybillDate).toISOString().split('T')[0] : null;
            equipment.urrwinDate = equipment.urrwinDate != undefined ? new Date(equipment.urrwinDate).toISOString().split('T')[0] : null;
            // equipment.equipmentInitial = equipment.equipmentInitial;
            // equipment.equipmentNumber = equipment.equipmentNumber;
            // if (equipment.vinNum && equipment.vinNum.length > 0) {
            //     let products = [];
            //     equipment.vinNum.forEach(vin => {
            //         let tempProduct = {};
            //         tempProduct.vin = vin;
            //         products.push(tempProduct);
            //     });
            //     equipment.products = [...equipment.products, ...products];
            // }
            this.selectedShipmentsMap.set(equipment.equipmentInitial + equipment.equipmentNumber, equipment);
        });
        // this.derailment.equipment = equipment;

        this.selectedShipmentsMap.forEach((value, key) => {
            value.Id = key;
        });
        console.log('selectedShipmentsMap ::', this.selectedShipmentsMap);
        this.selectedShipments = Array.from(this.selectedShipmentsMap.values());
        console.log('selectedShipments ::', this.selectedShipments);

    }

    handleRowSelection(event) {
        let selectedRows = event.detail.selectedRows;
        let selectedShipmentsMap = this.selectedShipmentsMap;
        selectedRows.forEach(row => {
            let equipment = selectedShipmentsMap.get(row.Id);
            if (row.Id) {
                equipment.isSelected = true;
            } else {
                equipment.isSelected = false;
            }
            selectedShipmentsMap.set(row.Id, equipment);
        });

    }

    submit() {
        this.showSpinner = true;
        let recordMap = {};
        let equipments = [];
        if (this.selectedShipmentsMap.size > 0) {
            this.selectedShipmentsMap.forEach((value, key) => {
                if (value.isSelected) {
                    equipments.push(value);
                }
            });
        }
        this.derailment.equipment = equipments;
        let isValid = this.validateInput();
        if (isValid) {
            Object.keys(this.derailment).forEach(key => {
                console.log('key ::', key);
                if (key === 'equipment') {
                    recordMap[key] = JSON.stringify(this.derailment[key]);
                } else if (key === 'reportedDate') {
                    recordMap[key] = recordMap[key] != undefined ? recordMap[key].toString().split('T')[0] : null;
                } else {
                    if (this.derailment[key]) {
                        recordMap[key] = this.derailment[key].toString();
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
                csx_cmp_logError('csx_cmp_ldrCreationDerailment', 'createLDReport', error, '');
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

        if (this.derailment.equipment.length === 0) {
            isValid = false;
            let event = new ShowToastEvent({
                title: 'Error',
                message: this.label.noShipmentSelected,
                variant: 'error',
            });
            this.dispatchEvent(event);
        }
        return isValid;
    }


    resetPage() {
        this.derailment = {
            'reportType': '',
            'name': '',
            'phone': '',
            'email': '',
            'incidentLocation': '',
            'damageReason': '',
            'incidentAction': '',
            //'estimatedLadingLoss': '',
            'incidentComments': '',
            'division': '',
            // 'address': '',
            'source': 'Manual',
        }
        this.template.querySelector('c-csx_cmp_shipment-search').resetPage();
        this.locationLookupReset();

        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'),
        ...this.template.querySelectorAll('lightning-textarea'), ...this.template.querySelectorAll('lightning-input-field')];
        inputFields.forEach(field => {

            let parameters = {
                required: false,
                type: field.type
            }
            field.type = '';
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
                this.derailment.damageReason = this.issueOptions.find(option => option.value === 'I-Derailment').value;
                this.derailment.cause = this.causeOptions.find(option => option.value === 'I-Derail').value;
                this.derailment.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;
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


    backToSearch() {
        const callClaimSearch = new CustomEvent('backtosearch');
        this.dispatchEvent(callClaimSearch);
    }
}