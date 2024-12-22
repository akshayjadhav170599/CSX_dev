import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues, getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CLAIM_TYPE_FIELD from '@salesforce/schema/Case.Type';
import FCD_CAUSE_FIELD from '@salesforce/schema/Case.CSX_CMP_FCD_Cause_Code__c';
import FCD_RULE_FIELD from '@salesforce/schema/Case.CSX_CMP_FCD_Rule_Code__c';
import CLAIM_REASON from '@salesforce/schema/Case.CSX_CMP_Claim_Reason__c';
import Terminal from '@salesforce/schema/Case.CSX_CMP_Terminal__c';
import checkforDuplicates from '@salesforce/apex/CSX_CMP_ClaimCreationController.checkforDuplicates';
import createClaim from '@salesforce/apex/CSX_CMP_ClaimCreationController.createNewClaim';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import submitClaim from '@salesforce/label/c.CSX_CMP_ClaimCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import backToSearch from '@salesforce/label/c.CSX_CMP_BackToSearchLabel';
import duplicatesFound from '@salesforce/label/c.CSX_CMP_Duplicates_Found';
import getRoles from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.getRoleAccessConfiguration';

export default class Csx_cmp_claimCreationFreight extends LightningElement {

    //custom labels imported from Salesforce
    label = {
        submitClaim, reset, backToSearch, duplicatesFound,
        hideVINForClaimTypes: 'Transflo Claim,FC Customer Claim,Contractor Claim,Lawsuit Claim',
    };

    @api recordType;
    @api recordTypeName;
    isTransflo = false;
    isRR = false;
    showShipmentSearch = true;
    showDerailment = true;
    showVinPicklist = true;
    showVinText = false;
    supplierSelected = false;
    selectedControllingValue = '';
    dependentValues;
    isSubmitting = false;
    isModalOpen = false
    noVinValues = false;
    claimTypeValue;
    claimTypeOptionsDataComplete;
    reasonOptions;
    vinOptions = [];
    fcdCauseOptions;
    fcdRuleOptions;
    terminalOptions;
    selectedClaimType = '';
    selectedVin;
    equipNo = '';
    claimDetails;
    receivedRecord;
    maximumDate;
    claim;
    vinSelectionApplicable = false;
    //data to be sent to apex
    freightClaim = {
        'derailment': '',
        'claimReason': '',
        'claimAmount': '',
        'customerClaimDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
        'claimantReferenceNumber': '',
        'notes': '',
        'causeCode': '',
        'ruleCode': '',
        'terminal': '',
        'contactName': '',
        'phoneNumber': '',
        'email': '',
        'claimRecordType': '',
        'claimType': '',
        'equipment': [],
        'supplierId': '',
        'sendEmail': true,
        'noWaybill': false,
        'equipId': '',
        'vin': '',
        'source': 'Manual'
    };

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    connectedCallback() {
        let today = new Date().toISOString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
        let maxDate = today.split('T');
        maxDate[1] = '23:59:59.999Z';
        this.maximumDate = maxDate.join('T');
    }

    claimTypesMap = new Map();
    @wire(getRoles)
    wiredRoles({ data, error }) {
        if (data) {
            if (data.length > 0) {
                let response = JSON.parse(data);
                let metadata = response.roleAccessConfigList;
                if (metadata[0].CSX_CMP_Eligible_Claim_Type_for_Creation__c) {
                    let eligibleClaimTypes = metadata[0].CSX_CMP_Eligible_Claim_Type_for_Creation__c.split(',');
                    this.claimTypesMap = new Map();
                    for (let i = 0; i < eligibleClaimTypes.length; i++) {
                        this.claimTypesMap.set(eligibleClaimTypes[i], eligibleClaimTypes[i]);
                    }
                }
            }
        }
        else if (error) {
            console.log('ERROR===', JSON.stringify(error));
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$recordType' })
    claimPicklistValues({ data, error }) {
        if (data) {
            this.assignPicklistValues(data.picklistFieldValues);
        } else if (error) {
            csx_cmp_logError('csx_cmp_claimCreationFreight', 'claimPicklistValues', error, '');
        }
    }

    assignPicklistValues(data) {
        let typeValues = data.Type;
        let typeOptions = []
        typeValues.values.forEach(key => {
            typeOptions.push({ label: key.label, value: key.value });
        });

        let reasonValues = data.CSX_CMP_Claim_Reason__c;
        let reasonOptions = [];
        reasonValues.values.forEach(key => {
            reasonOptions.push({ label: key.label, value: key.value });
        });

        let fcdCauseValues = data.CSX_CMP_FCD_Cause_Code__c;
        let fcdCauseOptions = [];
        fcdCauseValues.values.forEach(key => {
            fcdCauseOptions.push({ label: key.label, value: key.value });
        });

        let fcdRuleValues = data.CSX_CMP_FCD_Rule_Code__c;
        let fcdRuleOptions = [];
        fcdRuleValues.values.forEach(key => {
            fcdRuleOptions.push({ label: key.label, value: key.value });
        });

        let terminalValues = data.CSX_CMP_Terminal__c;
        let terminalOptions = [];
        terminalValues.values.forEach(key => {
            terminalOptions.push({ label: key.label, value: key.value });
        });
    }


    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: CLAIM_TYPE_FIELD })
    claimTypeValues({ data, error }) {

        if (data) {
            this.claimTypeOptionsDataComplete = data.values;
        }
        else {
            console.log(error);
        }
    }

    get claimTypeOptionsData() {
        let claimTypeOptions = [];
        if (this.claimTypeOptionsDataComplete) {
            this.claimTypeOptionsDataComplete.forEach(opt => {
                if (this.claimTypesMap.has(opt.value)) {
                    claimTypeOptions.push({
                        label: opt.label,
                        value: opt.value
                    });
                }
            });
        }
        return claimTypeOptions;
    }

    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: CLAIM_REASON })
    reasonValues({ data, error }) {
        if (data) {
            this.dependentValues = data;
        }
        else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: FCD_CAUSE_FIELD })
    fcdCauseValues({ data, error }) {
        if (data) {
            this.fcdCauseOptions = data.values;
        }
        else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: FCD_RULE_FIELD })
    fcdRuleValues({ data, error }) {
        if (data)
            this.fcdRuleOptions = data.values;
        else {
            console.log(error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: Terminal })
    terminalValues({ data, error }) {
        if (data)
            this.terminalOptions = data.values;
        else {
            console.log(error);
        }
    }


    //Event Handlers
    handleClaimTypeChange(event) {
        this.freightClaim.claimType = event.target.value;
        let key = this.dependentValues.controllerValues[event.target.value];
        this.reasonOptions = this.dependentValues.values.filter(opt => opt.validFor.includes(key));
        this.isTransflo = false;
        this.isRR = false;
        this.showDerailment = true;
        let displayVinCheck = true;
        let defaultSelection = 'equipment';
        //this.freightClaim.noWaybill = false;
        // if (this.freightClaim.claimType === 'Transflo Claim' || this.freightClaim.claimType === 'FC Customer Claim') {
        if (this.label.hideVINForClaimTypes.split(',').includes(this.freightClaim.claimType)) {
            displayVinCheck = false;
            this.vinSelectionApplicable = false;
        } else {
            this.vinSelectionApplicable = true;
        }
        if (this.freightClaim.claimType === 'FC Customer Automobile Claim') {
            defaultSelection = 'vin';
        }
        if (this.freightClaim.claimType === 'Transflo Claim') {
            this.isTransflo = true;
            this.showDerailment = false;
        }
        if (this.freightClaim.claimType === 'FC RR Inbound Claim' || this.freightClaim.claimType === 'Recharges Inbound Claim') {
            this.isRR = true;
        }
        this.claimTypeValue = event.target.value;
        //this.template.querySelector('c-csx_cmp_shipment-search').displayVin = displayVinCheck;
        let shipmentSearchComponent = this.template.querySelector('c-csx_cmp_shipment-search');
        if (shipmentSearchComponent) {
            shipmentSearchComponent.displayVin = displayVinCheck;
            shipmentSearchComponent.selectedOption = defaultSelection;
            shipmentSearchComponent.handleDefaultOptionChange(this.freightClaim.claimType);

        }
        /*let shipmentSearchDisplayVIN = this.template.querySelector('c-csx_cmp_shipment-search');
        if (shipmentSearchDisplayVIN) {
            shipmentSearchDisplayVIN.displayVin = displayVinCheck;
        }
        let shipmentSearchselectedOption = this.template.querySelector('c-csx_cmp_shipment-search');
        if (shipmentSearchselectedOption) {
            shipmentSearchselectedOption.selectedOption = defaultSelection;
        }
        window.setTimeout(() => {
            this.template.querySelector('c-csx_cmp_shipment-search').handleDefaultOptionChange(this.freightClaim.claimType);
            console.log('display vin after ::',displayVinCheck);
        }, 200);*/
        //this.template.querySelector('c-csx_cmp_shipment-search').displayVin = displayVinCheck;
        //this.template.querySelector('c-csx_cmp_shipment-search').selectedOption = defaultSelection;
        //this.template.querySelector('c-csx_cmp_shipment-search').handleDefaultOptionChange(this.freightClaim.claimType);

    }

    handleCheckboxChange(event) {
        let isChecked = event.target.checked;
        if (isChecked) {
            this.showShipmentSearch = false;
            this.showVinPicklist = false;
            this.showVinText = true;
            this.freightClaim.noWaybill = true;
            this.noVinValues = false;
        }
        else {
            this.showShipmentSearch = true;
            this.showVinPicklist = true;
            this.showVinText = false;
            this.noVinValues = false;
        }

        window.setTimeout(() => {
            let shipmentSearch = this.template.querySelector('c-csx_cmp_shipment-search');
            if (shipmentSearch) {
                this.handleClaimTypeChange({ target: { value: this.freightClaim.claimType } });
            }
        }, 300);
    }

    handleShipmentsReceived(event) {
        this.selectedVin = '';
        let receivedRecords = JSON.parse(event.detail);
        if (receivedRecords.length > 0) {
            let receivedRecord = receivedRecords[0];
            this.equipNo = receivedRecord.equipmentInitial + receivedRecord.equipmentNumber;
            if (receivedRecord.vinNum.length > 0) {
                this.noVinValues = false;
                this.showVinText = false;
                this.showVinPicklist = true;
                this.vinOptions = receivedRecord.vinNum.map(value => ({
                    label: value,
                    value: value
                }));
                if (this.vinOptions.length == 1) {
                    this.selectedVin = this.vinOptions[0].value;
                    receivedRecord.vinNumSelected = this.selectedVin;
                }
            } else {
                this.noVinValues = true;
                this.showVinPicklist = false;
                this.showVinText = false;
            }
            this.receivedRecord = receivedRecord;
        }
    }

    handleVinChange(event) {
        this.selectedVin = event.target.value;
        this.receivedRecord.vinNumSelected = this.selectedVin;
    }

    handleInputChange(event) {
        if (event.target.type == 'checkbox') {
            this.freightClaim[event.target.name] = event.target.checked;
        } else if (event.target.type == 'date') {
            this.freightClaim[event.target.name] = event.target.value;
        } else {
            this.freightClaim[event.target.name] = event.target.value;
        }

        if (event.target.name == 'equipId') {
            this.validateEquipment();
        }

        if (event.target.name == 'vin') {
            this.validateVin();
        }
    }

    validateVin() {
        let vin = this.template.querySelector('[data-id="vin"]');
        let error = "";
        if (this.freightClaim.vin.length > 0) {
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

    validateEquipment() {
        let equipment = this.template.querySelector('[data-id="equipNo"]');
        let error = "";
        if (this.freightClaim.equipId.length > 0) {
            let equip = equipment.value;
            if (equip.length !== 0) {
                let initial;
                let number;
                let regex = /^[A-Za-z]{2,4}[0-9]{1,6}$/;

                if (equip.length >= 3 && equip.length <= 11) {
                    // check whether the equipment number contains special characters
                    let specialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/;
                    if (specialChar.test(equip)) {
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

                if (error === "" && !equipmentNumber.match(regex)) {
                    error = 'Invalid Equipment Number';
                }

            }
        }
        equipment.setCustomValidity(error);
        equipment.reportValidity();
    }


    handleContactDetailChange(event) {
        let data = JSON.parse(event.detail);
        this.freightClaim[data.label] = data.value;
    }

    handleSupplierId(event) {
        let receivedRecord = JSON.parse(event.detail);
        this.freightClaim['supplierId'] = receivedRecord;
    }
    //End of handlers

    //Submit Methods
    submitClaim() {
        this.isSubmitting = true;
        this.freightClaim['claimRecordType'] = 'Freight';
        let isValid = false;
        let supplierCheck = true;
        let equipOrVinCheck = true;
        let errorMessage = '';
        if (this.showShipmentSearch == false) {
            equipOrVinCheck = this.validateEquipOrVin();
        }
        if (this.freightClaim['supplierId'] == '') {
            this.supplierSelected = true;
            this.template.querySelector('c-csx_cmp_supplier-site-search').supplierValidation();
            supplierCheck = false;
        }

        let contactDetails = this.template.querySelector('c-csx_cmp_contact-details').validate();
        let isValidList = [];
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ... this.template.querySelectorAll('lightning-textarea')];
        if (inputFields) {
            inputFields.forEach(inputField => {
                let validityCheck = true;
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    validityCheck = false;
                    isValidList.push(validityCheck);
                } else {
                    isValidList.push(validityCheck);
                }
            });
        }

        let inputFieldValiditycheck = isValidList.every(function (value) {
            return value == true;
        });

        if (contactDetails && inputFieldValiditycheck && supplierCheck && equipOrVinCheck) {
            isValid = true;
        } else {
            errorMessage = 'Enter all the mandatory fields/Valid Input to create a claim';
        }

        if (errorMessage === '') {
            if (this.showShipmentSearch == true) {
                if (!this.receivedRecord) {
                    isValid = false;
                    errorMessage = 'Select a shipment to create a claim';
                }
            } else {
                if (this.freightClaim.equipId == '' || this.freightClaim.vin == '') {
                    isValid = false;
                    errorMessage = 'Enter Equipment Id or VIN to create a claim';
                }
            }
        }

        console.log('isValid', isValid);
        console.log('supplierCheck', supplierCheck);
        console.log('this.receiveRecord', this.receivedRecord);

        if (isValid) {
            this.claim = this.freightClaim;
            if (this.receivedRecord) {
                let finalReceivedRecords = [];
                let products = [];
                let receivedProducts = this.receivedRecord.products;
                let productWithDescription;
                receivedProducts.forEach(key => {
                    // if (key.description != null) {
                    //     products.push(key);
                    // } else if (key.vin == this.receivedRecord.vinNumSelected) {
                    //     products.push(key);
                    // }
                    if (this.freightClaim.claimType === 'FC Customer Automobile Claim' && key.vin) {

                        if (key.vin == this.receivedRecord.vinNumSelected) {
                            if (productWithDescription) {
                                key.description = productWithDescription.description;
                                key.quantity = 1;
                            }
                            products.push(key);
                        }
                    } else if (this.freightClaim.claimType === 'FC Customer Automobile Claim' && key.description) {
                        productWithDescription = key;
                    } else if (this.freightClaim.claimType !== 'FC Customer Automobile Claim') {
                        if (key.description != null || key.vin == this.receivedRecord.vinNumSelected) {
                            products.push(key);
                        }
                    }
                });
                let ReceivedShipmentRec = {
                    'equipmentInitial': this.receivedRecord.equipmentInitial,
                    'equipmentNumber': this.receivedRecord.equipmentNumber,
                    'waybillNumber': this.receivedRecord.waybillNumber,
                    'waybillDate': this.receivedRecord.waybillDate != undefined ? this.receivedRecord.waybillDate.split('T')[0] : null,
                    'consigneeName': this.receivedRecord.consigneeName,
                    'stcc': this.receivedRecord.commodityNumber,
                    'shipperName': this.receivedRecord.shipperName,
                    'actualOriginStateCode': this.receivedRecord.actualOriginStateCode,
                    'actualDestinationStateCode': this.receivedRecord.actualDestinationStateCode,
                    'stccDescription': this.receivedRecord.stccDescription,
                    'actualOriginCityName': this.receivedRecord.actualOriginCityName,
                    'actualDestinationCityName': this.receivedRecord.actualDestinationCityName,
                    'actualOriginSCAC': this.receivedRecord.actualOriginSCAC,
                    'actualDestinationSCAC': this.receivedRecord.actualDestinationSCAC,
                    'originRoadNumber': this.receivedRecord.originRoadNumber,
                    'originAuditNumber': this.receivedRecord.originAuditNumber,
                    'destinationAuditNumber': this.receivedRecord.destinationAuditNumber,
                    'waybillControls': this.receivedRecord.waybillControls,
                    'shipperLegalEntityId': this.receivedRecord.shipperLegalEntityId,
                    'consigneeLegalEntityId': this.receivedRecord.consigneeLegalEntityId,
                    'products': products,
                    'distributions': this.receivedRecord.distributions,
                    'flatcarId': this.receivedRecord.flatCarId,
                    'businessUnit': this.receivedRecord.businessUnit,
                };
                finalReceivedRecords.push(ReceivedShipmentRec);
                console.log('finalReceivedRecords', finalReceivedRecords);
                this.claim['equipment'] = JSON.stringify(finalReceivedRecords);
            }



            if (this.showShipmentSearch == false) {
                let shipmentList = [];
                let products = [];
                let tempProduct = {};
                tempProduct.customerDamages = [];
                let shipment = {
                    'equipmentInitial': this.claim.equipId,
                    'equipmentNumber': '',
                    'products': [],
                };
                Object.keys(this.claim).forEach(key => {
                    if (key == 'equipId') {
                        let equipment = this.claim[key].split(/([0-9]+)/);
                        shipment['equipmentInitial'] = equipment[0].toUpperCase();
                        shipment['equipmentNumber'] = equipment[1];
                    } else if (key == 'vin') {
                        tempProduct.vin = this.claim[key];
                    } else {
                        this.claim[key].toString();
                    }
                });
                products.push(tempProduct);
                shipment['products'] = products;
                shipmentList.push(shipment);
                this.claim['equipment'] = JSON.stringify(shipmentList);
            }
            this.checkforDuplicates();
        }
        else {
            this.isSubmitting = false;
            const evt = new ShowToastEvent({
                title: 'Please Review Fields',
                message: errorMessage,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }
    }
    validateEquipOrVin() {
        let equipField = this.template.querySelector(".EquipErr");
        let VinField = this.template.querySelector(".VinErr");
        let equipValue = equipField.value;
        let VinValue = VinField.value;
        let isValid = true;
        if (!(equipValue) && !(VinValue)) {
            isValid = false;
            equipField.setCustomValidity("Enter Equipment Id or VIN");
            VinField.setCustomValidity("Enter Equipment Id or VIN");

        }
        else {
            isValid = true;
            equipField.setCustomValidity("");
            VinField.setCustomValidity("");
        }
        equipField.reportValidity();
        VinField.reportValidity();
        return isValid;
    }
    //to check for duplicate claims
    checkforDuplicates() {
        checkforDuplicates({ inputClaimDetails: this.claim }).then(result => {
            console.log('result', result);
            if (Object.keys(result).length != 0) {
                this.dupClaim = Object.entries(result).map(([key, value]) => ({ Id: key, CaseNumber: value }));
                this.duplicateClaimNum = Object.values(result);
                this.isSubmitting = false;
                this.isModalOpen = true;
            } else {
                this.createClaim();
            }
        }).catch(error => {
            this.isSubmitting = false;
            let parameters = ''
            csx_cmp_logError('csx_cmp_claimCreationFreight', 'checkforDuplicates', error, parameters);
        });

    }

    closeModal() {
        this.isModalOpen = false;
        this.duplicateClaimNum = null;
    }

    redirectToCase(event) {
        const claimNumber = event.target.dataset.claimNumber;
        let claim = this.dupClaim.find(claim => claim.CaseNumber === claimNumber);
        const caseRecUrl = `/lightning/r/Case/${claim.Id}/view`;
        window.open(caseRecUrl, '_blank');
    }

    // claim creation method
    createClaim() {
        this.isSubmitting = true;
        this.isModalOpen = false;

        createClaim({ inputClaimDetails: this.claim, duplicateClaims: this.duplicateClaimNum })
            .then(result => {
                this.claimDetails = result;
                this.isSubmitting = false;
                if (this.claimDetails) {
                    this.dispatchEvent(new CustomEvent('sendclaim', { detail: JSON.stringify(this.claimDetails) }));
                }
            })
            .catch(error => {
                this.isSubmitting = false;
                let parameters = '';
                csx_cmp_logError('csx_cmp_claimCreationFreight', 'createClaim', error, parameters);
            });
    }

    resetPage() {
        this.vinSelectionApplicable = false;
        this.freightClaim = {
            'derailment': '',
            'claimReason': '',
            'claimAmount': '',
            'customerClaimDate': new Date().toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }),
            'claimantReferenceNumber': '',
            'notes': '',
            'causeCode': '',
            'ruleCode': '',
            'terminal': '',
            'contactName': '',
            'phoneNumber': '',
            'email': '',
            'claimRecordType': '',
            'claimType': '',
            'equipment': [],
            'supplierId': '',
            'sendEmail': true,
            'noWaybill': false,
            'equipId': '',
            'vin': '',
            'source': 'Manual'

        };

        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...  this.template.querySelectorAll('lightning-combobox'), ... this.template.querySelectorAll('lightning-textarea')];
        inputFields.forEach(element => {

            let parameters = {
                required: false,
                type: element.type
            }
            if (element.required) {
                parameters.required = true;
                element.required = false;
            }

            element.value = '';
            element.type = '';
            element.setCustomValidity('');
            window.setTimeout(() => {
                element.reportValidity();
                if (parameters.required) {
                    element.required = true;
                }
                element.type = parameters.type;
            }, 500);
        });
        let shipmentfields = this.template.querySelector('c-csx_cmp_shipment-search');
        if (shipmentfields) {
            shipmentfields.resetPage();
        }
        this.template.querySelector('c-csx_cmp_contact-details').resetPage();
        this.template.querySelector('c-csx_cmp_supplier-site-search').resetPage();
    }

    //This method is triggered by an event from shipment search component
    resetShipment() {
        this.equipNo = '';
        this.selectedVin = '';
        this.vinOptions = [];
        this.freightClaim.equipment = [];
        this.receivedRecord = null;
    }

}