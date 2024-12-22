import { LightningElement, api, wire, track } from 'lwc';

// custom labels
import submit from '@salesforce/label/c.CSX_CMP_LDRCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';

// standard imports
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import ldreport from "@salesforce/schema/CSX_CMP_LD_Report__c";

// custom imports
import { csx_cmp_logError } from 'c/csx_cmp_logError';

// apex handler imports
import createLDReport from '@salesforce/apex/CSX_CMP_LDRCreationController.createLDReport';
import getStates from '@salesforce/apex/CSX_CMP_LDRSearchController.getStates';

export default class Csx_cmp_ldrCreationCustomer extends LightningElement {
    label = {
        submit, reset
    };
    userId = Id;
    @api selectedType;
    @track records = [];
    rowAdded = false;
    typeOptions;
    issueOptions;
    causeOptions;
    productConditionOptions;
    productLocationOptions;
    bracingMethodOptions;
    dispositionOptions;
    displayOtherFields = false;
    displayProductConditionOther = false;
    displayBracingMethodOther = false;
    displayDispositionOther = false;
    requiredPickupFields = false;
    headers = ['*Quantity', '*Product Description'];

    @track customer = {
        'reportType': '',
        'contactId': '',
        'incidentLocation': '',
        'division': '',
        'pickupAddress': '',
        'pickupCity': '',
        'pickupState': '',
        'damageReason': '',
        'cause': '',
        'estimatedLadingLoss': '',
        'damageLocation': '',
        'bracingMethod': '',
        'disposition': '',
        'productCondition': '',
        'visibleDamage': '',
        'canNotUnload': '',
        'unloadingExceededHours': '',
        'incidentComments': '',
        'sendEmail': '',
        'equipment': [],
        'source': 'Manual',
        'productRecords': [],
        'productConditionOther': '',
        'bracingMethodOther': '',
        'dispositionOther': '',
        'reportedDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
    };

    emailRequired = false;
    showSpinner = false;
    pickupStateOptions = [];

    @wire(getStates)
    wiredStateAndCityData({ data, error }) {
        if (data) {
            this.pickupStateOptions = data.state;
            this.pickupStateOptions = Object.values(data.state).map(state => ({
                label: state,
                value: state
            }));
        }
        if (error) {
            let parameters = data;
            csx_cmp_logError('csx_cmp_ldrSearch', 'wiredStateAndCityData', error, parameters);
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: ['User.FederationIdentifier', 'User.FirstName'] })
    wiredUser({ error, data }) {
        if (data) {
            let reportedBy = data.fields.FederationIdentifier.value;
            if (reportedBy) {
                reportedBy = reportedBy.split('@')[0];
                this.customer.reportedBy = reportedBy;

            } else {
                reportedBy = data.fields.FirstName.value;
                this.customer.reportedBy = reportedBy;
            }

            console.log('this.customer', this.customer);
        } else if (error) {
            csx_cmp_logError('Csx_cmp_ldrCreationInTransit', 'wiredUser', error, '');
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: ldreport, recordTypeId: "012000000000000AAA", })
    objectInfo({ data, error }) {
        if (data) {
            let result = data.picklistFieldValues;
            this.assignPicklistValues(result);
        }
        else if (error) {
            csx_cmp_logError('csx_cmp_ldrCreationCustomer', 'objectInfo', error, 'Error in getting picklist values');
        }
    }

    assignPicklistValues(result) {
        let typeValues = result.CSX_CMP_LD_Type__c;
        let typeOptions = [];
        typeValues.values.forEach((key) => {
            typeOptions.push({ label: key.label, value: key.value });
        });
        this.typeOptions = typeOptions;
        this.customer.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;

        let issueValues = result.CSX_CMP_Damage_Reason__c;
        let issueValue = issueValues.controllerValues.Customer;
        let issueOptions = []
        issueValues.values.forEach(key => {
            if (key.validFor.includes(issueValue)) {
                issueOptions.push({ label: key.label, value: key.value });
            }
        });
        this.issueOptions = issueOptions;

        let causeValues = result.CSX_CMP_Cause__c;
        let causeValue = causeValues.controllerValues.Customer;
        let causeOptions = []
        causeValues.values.forEach(key => {
            if (key.validFor.includes(causeValue)) {
                causeOptions.push({ label: key.label, value: key.value });
            }
        });
        this.causeOptions = causeOptions;

        let productConditionValues = result.CSX_CMP_Product_Condition__c;
        let productConditionOptions = []
        productConditionValues.values.forEach(key => {
            productConditionOptions.push({ label: key.label, value: key.value });
        });
        this.productConditionOptions = productConditionOptions;

        let productLocationValues = result.CSX_CMP_Damage_Location__c;
        let productLocationOptions = []
        productLocationValues.values.forEach(key => {
            productLocationOptions.push({ label: key.label, value: key.value });
        });
        this.productLocationOptions = productLocationOptions;

        let bracingMethodValues = result.CSX_CMP_Bracing_Method__c;
        let bracingMethodOptions = []
        bracingMethodValues.values.forEach(key => {
            bracingMethodOptions.push({ label: key.label, value: key.value });
        });
        this.bracingMethodOptions = bracingMethodOptions;

        let dispositionValues = result.CSX_CMP_Disposition__c;
        let dispositionOptions = []
        dispositionValues.values.forEach(key => {
            dispositionOptions.push({ label: key.label, value: key.value });
        });
        this.dispositionOptions = dispositionOptions;

    }

    handleInputChange(event) {

        this.requiredPickupFields = false;
        if (event.target.type === 'checkbox') {
            this.customer[event.target.name] = event.target.checked;
        } else {
            this.customer[event.target.name] = event.target.value;
        }

        if (this.customer.sendEmail) {
            this.emailRequired = true;
        } else {
            this.emailRequired = false;
        }

        if (event.target.name === 'productCondition') {
            if (event.target.value === 'Other') {
                this.displayProductConditionOther = true;
            } else {
                this.displayProductConditionOther = false;
            }

        } else if (event.target.name === 'bracingMethod') {
            if (event.target.value === 'Other') {
                this.displayBracingMethodOther = true;
            } else {
                this.displayBracingMethodOther = false;
            }
        } else if (event.target.name === 'disposition') {
            if (event.target.value === 'Other') {
                this.displayDispositionOther = true;
            } else if (event.target.value === 'Rejected to Carrier') {
                this.displayDispositionOther = false;
                this.requiredPickupFields = true;
            } else {
                this.displayDispositionOther = false;
            }
        }

        if (this.displayProductConditionOther || this.displayBracingMethodOther || this.displayDispositionOther) {
            this.displayOtherFields = true;
        }
    }

    handleShipmentsReceived(event) {
        let equipment = JSON.parse(event.detail);
        equipment.forEach((equipment) => {
            equipment.waybillDate = equipment.waybillDate != undefined ? new Date(equipment.waybillDate).toISOString().split('T')[0] : null;
            equipment.urrwinDate = equipment.urrwinDate != undefined ? new Date(equipment.urrwinDate).toISOString().split('T')[0] : null;
        });
        this.customer.equipment = equipment;
        let products = [];
        if (equipment.length > 0) {
            if (equipment[0].products.length > 0) {
                let productList = equipment[0].products;
                let removedRow;
                productList.forEach((product) => {
                    if (product.quantity != null || product.productDescription != null) {
                        let tempProduct = {};
                        tempProduct.rowNumber = products.length + 1;
                        tempProduct.quantity = product.quantity;
                        tempProduct.productDescription = product.description;
                        tempProduct.uom = product.uom;
                        products.push(tempProduct);
                    }
                });
                productList.splice(removedRow - 1, 1);
                equipment[0].products = productList;
            }
        }
        this.records = products;
    }


    handleInputChangeForTable(event) {
        let rowNumber = event.target.dataset.id;
        let fieldName = event.target.name;
        let records = this.records;
        records[rowNumber - 1][fieldName] = event.target.value;
        this.records = records;
    }

    handleRemoveRow(event) {
        let rowNumber = event.target.value;
        let records = this.records;

        records.splice(rowNumber - 1, 1);
        if (this.records.length === 0) {

            this.handleAddRow(event);
        } else {
            this.records = records;

            this.records.forEach(function (element, index) {
                element.rowNumber = index + 1;
            });

        }

    }

    handleAddRow() {
        let records = this.records;
        let rowNumber = records.length + 1;
        records.push({
            'rowNumber': rowNumber, 'quantity': '', 'productDescription': '', 'isRowDisabled': true, 'quantityRequired': true,
            'descriptionRequired': true,
        },);
        this.records = records;
        this.rowAdded = true;
    }

    handleEditRow(event) {
        let rowNumber = event.target.value;
        let records = this.records;
        records[rowNumber - 1].isRowDisabled = false;
        records[rowNumber - 1].displayEditIcon = false;
        records[rowNumber - 1].displaySaveIcon = true;
        this.records = records;
    }

    renderedCallback() {
        /**Handle only when new row is added and wants to make it editable */
        if (this.rowAdded) {
            this.rowAdded = false;
            let records = this.records;
            let rowNumber = records.length;
            records[rowNumber - 1].isRowDisabled = false;
            this.records = records;
        }
        if (this.records.length === 0) {
            this.handleAddRow();
        }
    }

    submit() {
        this.showSpinner = true;
        let records = [];
        if (this.records.length > 0) {
            this.records.forEach(record => {
                let tempRecord = {};
                tempRecord.quantity = record.quantity;
                tempRecord.description = record.productDescription;
                tempRecord.uom = record.uom;
                records.push(tempRecord);
            });
        }

        this.customer.productRecords = records;

        let recordMap = {};
        let isValid = this.validateInput();
        if (isValid) {
            Object.keys(this.customer).forEach(key => {
                if (key === 'equipment' || key === 'productRecords') {
                    recordMap[key] = JSON.stringify(this.customer[key]);
                } else if (key === 'reportedDate') {
                    recordMap[key] = recordMap[key] != undefined ? recordMap[key].toString().split('T')[0] : null;
                } else {
                    if (this.customer[key]) {
                        recordMap[key] = this.customer[key].toString();
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
                csx_cmp_logError('csx_cmp_ldrCreationCustomer', 'createLDReport', error, '');
            });
        } else {
            this.showSpinner = false;
        }

    }

    validateInput() {
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'),
        ...this.template.querySelectorAll('lightning-textarea')];
        let isValid = true;

        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }

        let inputFiedsFromEditForm = [...this.template.querySelectorAll('lightning-input-field')];
        if (inputFiedsFromEditForm) {
            inputFiedsFromEditForm.forEach(inputField => {
                if ((inputField.name === 'contactId' || inputField.name === 'incidentLocation') && (inputField.value === '' || inputField.value === null)) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }

        if (this.customer.equipment.length === 0) {
            isValid = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please add at least one shipment',
                    variant: 'error',
                }),
            );
        }
        return isValid;
    }


    resetPage() {
        this.customer = {
            'reportType': '',
            'contactId': '',
            'incidentLocation': '',
            'division': '',
            'pickupAddress': '',
            'damageReason': '',
            'cause': '',
            'estimatedLadingLoss': '',
            'damageLocation': '',
            'bracingMethod': '',
            'disposition': '',
            'productCondition': '',
            'visibleDamage': '',
            'canNotUnload': '',
            'unloadingExceededHours': '',
            'incidentComments': '',
            'sendEmail': '',
            'equipment': [],
            'source': 'Manual',
            'productRecords': [],
            'reportedDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
        };
        this.template.querySelector('c-csx_cmp_shipment-Search').resetPage();

        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'),
        ...this.template.querySelectorAll('lightning-textarea')];
        // ...this.template.querySelectorAll('lightning-input-field')];
        inputFields.forEach(field => {
            if (field.name !== 'reportType') {
                field.value = '';
            }

            if (field.type === 'checkbox') {
                field.checked = false;
            }

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
                this.customer.reportType = this.typeOptions.find(option => option.value === this.selectedType).value;
            }, 500);


        });


        this.lookupContactFieldReset();
        this.lookupIncidentLocationFieldReset();



    }

    lookupContactFieldReset() {
        let contactIdLookupField = this.template.querySelector('[data-id="contactId"]');
        contactIdLookupField.value = '';
        contactIdLookupField.required = false;

        window.setTimeout(() => {
            contactIdLookupField.reset();
            contactIdLookupField.reportValidity();
            contactIdLookupField.required = true;
        }, 500);
    }

    lookupIncidentLocationFieldReset() {
        let incidentLocationLookupField = this.template.querySelector('[data-id="incidentLocation"]');
        incidentLocationLookupField.value = '';
        incidentLocationLookupField.required = false;
        window.setTimeout(() => {
            incidentLocationLookupField.reportValidity();
            incidentLocationLookupField.required = true;
        }, 500);
    }

    backToSearch() {
        const callClaimSearch = new CustomEvent('backtosearch');
        this.dispatchEvent(callClaimSearch);
    }
}