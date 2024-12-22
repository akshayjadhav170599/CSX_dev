import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CLAIM_TYPE_FIELD from '@salesforce/schema/Case.Type';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import checkforDuplicates from '@salesforce/apex/CSX_CMP_ClaimCreationController.checkforDuplicates';
import createClaim from '@salesforce/apex/CSX_CMP_ClaimCreationController.createNewClaim';
import getGeneralRules from '@salesforce/apex/CSX_CMP_ClaimCreationController.getGeneralRules';
import getSuppliersForRailRoad from '@salesforce/apex/CSX_CMP_ClaimCreationController.getSuppliersForRailRoad';
import notFound from '@salesforce/label/c.CSX_CMP_NoResultsFound';
import submitClaim from '@salesforce/label/c.CSX_CMP_ClaimCreation_SubmitLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import claimAmountErr from '@salesforce/label/c.CSX_CMP_ClaimAmountError';
import shipmentError from '@salesforce/label/c.CSX_CMP_ShipmentSearchError';
import backToSearch from '@salesforce/label/c.CSX_CMP_BackToSearchLabel';
import duplicatesFound from '@salesforce/label/c.CSX_CMP_Duplicates_Found';
import getRoles from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.getRoleAccessConfiguration';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import checkRelatedClaim from '@salesforce/apex/CSX_CMP_ClaimCreationController.checkRelatedClaim';

export default class Csx_cmp_claimCreationRevRR extends LightningElement {

    @api recordType;
    label = {
        submitClaim,
        reset,
        backToSearch,
        notFound, shipmentError, claimAmountErr, duplicatesFound
    };

    @track claimRevenueRailRoad = {
        'claimType': '',
        'claimReason': '', // claimReason
        'supplierId': '', //supplierClaimantName
        'contactName': '',
        'phoneNumber': '',
        'email': '',
        'customerClaimDate': '', //customerClaimDate
        'notes': '', //notes
        'equipment': [], //equipment
        'sendEmail': false,
        'claimRecordType': '', //claimRecordType
        'claimAmount': '',
        'source': 'Manual',//source
        'previousClaimNumber': '' //[MR-00776]
        //'relatedClaim' : '',
    }; //data to be sent to apex

    shipmentCheck = false;
    isSuppressbottom = true;
    noCarrier = false;
    claimTypeOption;
    claimTypeOptionsData;
    shipmentValue = '';
    shipments;
    showAddNewShipment = false;
    showShipmentSearch = false;
    showUploadShipment = false;
    dupClaim = [];
    claimId;
    duplicateClaimNum;
    contactName;
    contactEmail;
    loggedInUserName;
    loggedInUserEmail;
    maximumDate;
    isSubmitting = false;
    contactNameMandatory = false;
    generalRuleNumberList;
    generalRuleNumberListOptions;
    suppliersList;
    payableRuleOptions = [];
    receivableRuleOptions = [];
    noResults = false;
    noClaimAmount = false;
    addClaimAmount = true;
    isModalOpen = false;
    isRchgClaim = false;
    declineMessage = '';

    accountList = [
        { label: 'Acme (Sample)', value: '1' },
        { label: 'Global Media (Sample)', value: '2' },
        { label: 'salesforce.com (Sample)', value: '3)' },
    ];

    datatableTitle = 'Selected Shipments';
    @track datatableColumns = [
        {
            label: 'URRWIN #', fieldName: 'urrwinNumber', initialWidth: 80,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'URRWIN Date', fieldName: 'urrwinDate', initialWidth: 110,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'Total Cars', fieldName: 'totalCars', initialWidth: 80,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'Origin/Destination', fieldName: 'originOrDest',
            hideDefaultActions: false,
        },
        {
            label: 'Commodity', fieldName: 'stcc', initialWidth: 90,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'Lead Equipment', fieldName: 'leadEquipment', initialWidth: 120,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'Waybill #', fieldName: 'waybillNumber', initialWidth: 80,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: 'Waybill Date', fieldName: 'waybillDate', initialWidth: 110,
            cellAttributes: { alignment: 'center' },
            hideDefaultActions: true,
        },
        {
            label: '*Claim Amount', fieldName: 'claimAmount', initialWidth: 110,
            hideDefaultActions: true, type: 'currency',
            editable: true,
        },
    ];

    @track recordsToDisplay = [];
    totalClaimAmount = 0;
    dataDisplayedOnDatatable = [];


    @track shipmentValueOptions = [
        { label: 'Shipment Search', value: 'searchShipment', checked: true },
        { label: 'Add New Shipment', value: 'addNewShipment', checked: false },
        { label: 'Upload Shipment', value: 'uploadShipment', checked: false },
    ];


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
            console.log('ERROR=====>', JSON.stringify(error));
        }
    }

    get claimTypeOptions() {
        let claimTypeOptions = [];
        if (this.claimTypeOptionsData) {
            this.claimTypeOptionsData.forEach(option => {
                if (this.claimTypesMap.has(option.value)) {
                    claimTypeOptions.push({
                        label: option.label,
                        value: option.value
                    });
                }
            }
            );
        }
        return claimTypeOptions;
    }


    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD, EMAIL_FIELD] })
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.loggedInUserName = data.fields.Name.value;
            this.loggedInUserEmail = data.fields.Email.value;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$recordType', fieldApiName: CLAIM_TYPE_FIELD })
    claimTypeValues({ data, error }) {
        if (data) {

            this.claimTypeOptionsData = data.values
                .filter(option => option.value !== 'Railroad Netting REV Claim')
                .map(option => ({ label: option.label, value: option.value }));
        }
        else {
            console.log(error);
        }
    }
    @wire(getGeneralRules, {})
    getGeneralRuleValues({ error, data }) {
        if (data) {
            this.generalRuleNumberList = Object.keys(data).map(key => ({
                label: data[key],
                value: key
            }));
            this.generalRuleNumberListOptions = this.generalRuleNumberList;
        } else {
            console.log(error);
        }
    }
    @wire(getSuppliersForRailRoad, {})
    getSuppliersForRailRoad({ error, data }) {

        if (data) {
            this.suppliersList = data.map(rule => ({
                label: rule.Name,
                value: rule.Id
            }));

        } else {
            console.log(error);
        }

    }

    connectedCallback() {
        this.maximumDate = new Date().toISOString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' });
        this.shipmentValue = 'searchShipment';
        this.displayChildComponent(this.shipmentValue);
    }

    handleClaimTypeChange(event) {
        this.claimRevenueRailRoad.claimType = event.detail.value;
        let claimType = this.claimRevenueRailRoad.claimType;
        this.contactNameMandatory = false;

        if (claimType == 'Rev-RR - Payable Rchg Claim' || claimType == 'Rev-RR - Receivable Rchg Claim') {
            this.isRchgClaim = true;
            let defaultRule = this.generalRuleNumberListOptions.find(option => option.value === 'Rule 93');
            if (defaultRule) {
                this.claimRevenueRailRoad.claimReason = defaultRule.value;
                this.generalRuleNumberList = [defaultRule];
            }
        } else {
            this.isRchgClaim = false;
            this.claimRevenueRailRoad.claimReason = '';
            this.generalRuleNumberList = this.generalRuleNumberListOptions;
        }

        if (claimType == 'Rev-RR - Payable Claim' || claimType == 'Rev-RR - Payable Rchg Claim') {
            this.contactNameMandatory = true;
        }
        if (claimType == 'Rev-RR - Receivable Claim' || claimType == 'Rev-RR - Receivable Rchg Claim') {
            this.contactName = this.loggedInUserName;
            this.contactEmail = this.loggedInUserEmail;
            this.claimRevenueRailRoad.contactName = this.contactName;
            this.claimRevenueRailRoad.email = this.contactEmail;
        } else {
            this.contactName = '';
            this.contactEmail = '';
        }
    }

    handleContactDetailChange(event) {
        let data = JSON.parse(event.detail);
        this.claimRevenueRailRoad[data.label] = data.value;
    }

    handleInputChange(event) {
        if (event.target.type == 'checkbox') {
            this.claimRevenueRailRoad[event.target.name] = event.target.checked;
        } else if (event.target.type == 'date') {
            let date = event.target.value;
            this.claimRevenueRailRoad[event.target.name] = date;
        } else {
            this.claimRevenueRailRoad[event.target.name] = event.target.value;
            if (event.target.name == 'previousClaimNumber') {
                let inputClaimNo = event.target;
                let relatedClaimVlaue = inputClaimNo.value;
                if (relatedClaimVlaue) {
                    if (relatedClaimVlaue.startsWith('CLA') || relatedClaimVlaue.startsWith('cla')) {
                        inputClaimNo.setCustomValidity(''); // Clear any previous error
                        this.claimRevenueRailRoad[event.target.name] = relatedClaimVlaue;//event.target.
                    } else {
                        inputClaimNo.setCustomValidity('Value must start with CLA/cla');
                    }
                    inputClaimNo.reportValidity();
                }
            } else {
                this.claimRevenueRailRoad[event.target.name] = event.target.value;
            }
        }
    }

    handleCellChange(event) {
        let updatedCell = event.detail.draftValues[0];
        if (updatedCell.claimAmount == null || updatedCell.claimAmount == "") {
            this.addClaimAmount = true;
        }
        let data = this.claimRevenueRailRoad.equipment;
        data.forEach((element, index) => {
            if ((index + 1) == updatedCell.rowNumber)
                element.claimAmount = updatedCell.claimAmount;
        });
        this.calculateClaimAmount(data);
    }

    handleShipmentValueChange(event) {
        let selectedOption = event.target.value;
        this.displayChildComponent(selectedOption);
    }

    displayChildComponent(selectedOption) {
        this.showAddNewShipment = false;
        this.showShipmentSearch = false;
        this.showUploadShipment = false;
        if (selectedOption == 'addNewShipment') {
            this.showAddNewShipment = true;
            this.shipmentValueOptions.forEach(element => {
                if (element.value == 'addNewShipment') {
                    element.checked = true;
                } else {
                    element.checked = false;
                }
            });
        } else if (selectedOption == 'searchShipment') {
            this.showShipmentSearch = true;
            this.shipmentValueOptions.forEach(element => {
                if (element.value == 'searchShipment') {
                    element.checked = true;
                } else {
                    element.checked = false;
                }
            });
        } else if (selectedOption == 'uploadShipment') {

            this.showUploadShipment = true;
            this.shipmentValueOptions.forEach(element => {
                if (element.value == 'uploadShipment') {
                    element.checked = true;
                } else {
                    element.checked = false;
                }
            });
        }
    }

    addClaimsToObject(shipments) {
        shipments.forEach(element => {
            this.claimRevenueRailRoad.equipment.push(element);
        });
    }

    tempShipment = {
        'urrwinNumber': '',
        'urrwinDate': '',
        'stcc': '',
        'commodityNumber': '',
        'originOrDest': '',
        'leadEquipment': '',
        'waybillNumber': '',
        'waybillDate': '',
        'claimAmount': '',
        'totalCars': '',
        'actualOriginStateCode': '',
        'actualOriginCityName': '',
        'actualDestinationStateCode': '',
        'destinationCity': '',
        'stccDescription': '',
        'waybillControls': ''
    };

    addShipments(event) {
        // this.shipments = [];
        // this.recordsToDisplay = [];
        // this.dataDisplayedOnDatatable = [];
        let shipments = event.detail;
        this.shipmentCheck = false;
        let newShipments = JSON.parse(shipments);
        this.shipments = newShipments;
        this.noResults = false;
        let data = [];
        this.addClaimsToObject(newShipments);
        // if (this.dataDisplayedOnDatatable.length > 0) {
        //     data = this.dataDisplayedOnDatatable;
        // }

        try {
            newShipments.forEach(element => {
                let claimAmount = '';
                // Object.keys(this.tempShipment).forEach(key => {
                //     this.tempShipment[key] = '';
                // });
                let tempShipment = {};

                if (element.claimAmount != undefined && element.claimAmount != '') {
                    claimAmount = parseFloat(element.claimAmount);
                    
                }

                tempShipment.urrwinNumber = element.urrwinNumber;
                tempShipment.urrwinDate = element.urrwinDate;
                tempShipment.stcc = element.stcc;
                tempShipment.commodityNumber = element.stcc;
                tempShipment.originOrDest = element.actualOriginCityName + ', ' + element.actualOriginStateCode + '\n'
                    + element.actualDestinationCityName + ', ' + element.actualDestinationStateCode;
                tempShipment.leadEquipment = element.equipmentInitial + element.equipmentNumber;
                tempShipment.waybillNumber = element.waybillNumber;
                tempShipment.waybillDate = element.waybillDate;
                tempShipment.claimAmount = claimAmount;
                tempShipment.totalCars = element.totalCars;
                tempShipment.actualOriginStateCode = element.actualOriginStateCode;
                tempShipment.actualOriginCityName = element.actualOriginCityName;
                tempShipment.actualDestinationStateCode = element.actualDestinationStateCode;
                tempShipment.destinationCity = element.destinationCity;
                tempShipment.stccDescription = element.stccDescription;
                tempShipment.waybillControls = element.waybillControls;
                data.push(tempShipment);
            });
            this.dataDisplayedOnDatatable = this.dataDisplayedOnDatatable.concat(data);
            this.calculateClaimAmount(this.claimRevenueRailRoad.equipment);
            this.dataDisplayedOnDatatable.forEach((element, index) => {
                if (element.rowNumber == undefined || element.rowNumber == '') {
                    element.rowNumber = parseInt(index + 1);
                }
            });
            this.shipmentValue = 'searchShipment';
            this.displayChildComponent(this.shipmentValue);
            this.recordsToDisplay = this.dataDisplayedOnDatatable;



        } catch (error) {
            csx_cmp_logError('Csx_cmp_claimCreationRevRR', 'addShipments', error, '');
        }
    }
    noShipments(event) {
        let shipments = event.detail;
        this.noResults = shipments;

    }

    calculateClaimAmount(data) {
        let totalClaimAmount = 0;
        data.forEach((element) => {
            if (element.claimAmount != '') {

                totalClaimAmount = totalClaimAmount + parseFloat(element.claimAmount);
            }
        });
        // this.recordsToDisplay = data;

        this.totalClaimAmount = totalClaimAmount;
        if( (this.claimRevenueRailRoad.claimType==='Rev-RR - Receivable Rchg Claim' || this.claimRevenueRailRoad.claimType==='Rev-RR - Receivable Claim')){
            this.totalClaimAmount=-this.totalClaimAmount/1.0;

        }
        this.claimRevenueRailRoad.claimAmount = this.totalClaimAmount;
        console.log('this.claimRevenueRailRoad.claimAmount: '+this.claimRevenueRailRoad.claimAmount);
    }

    handleHeaderRecordsDisplay(event) {
        this.dataDisplayedOnDatatable = event.detail;
    }

    closeAddShipmentModal() {
        this.shipmentValue = 'searchShipment';
        this.displayChildComponent(this.shipmentValue);
    }

    reset() {
        this.noResults = false;
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-input-field'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        if (inputFields) {
            inputFields.forEach(element => {
                let parameters = {
                    required: false,
                    type: element.type
                }
                element.type = '';
                element.value = '';
                if (element.required) {
                    parameters.required = true;
                    element.required = false;
                }
                element.setCustomValidity('');
                window.setTimeout(() => {
                    element.reportValidity();
                    if (parameters.required) {
                        element.required = true;
                    }
                    element.type = parameters.type;
                }, 500);
            });
        }
        this.claimRevenueRailRoad = {
            'claimType': '',
            'claimReason': '',
            'supplierId': '',
            'contactName': '',
            'phoneNumber': '',
            'email': '',
            'customerClaimDate': '',
            'notes': '',
            'equipment': [],
            'sendEmail': false,
            'claimAmount': '',
            'source': 'Manual',
            'previousClaimNumber': ''
            //'relatedClaim' : ''

        };
        this.template.querySelector('c-csx_cmp_contact-details').resetPage();


        if (this.showUploadShipment) {
            this.template.querySelector('c-csx_cmp_upload-shipment-rev-r-r').reset();
        } else {
            this.template.querySelector('c-csx_cmp_shipment-search-rev-r-r').reset();
        }
        this.resetTable();
    }


    resetTable() {
        if (this.dataDisplayedOnDatatable.length > 0) {
            this.dataDisplayedOnDatatable.forEach((element) => {
                element = {};
            });
        }
        this.claimRevenueRailRoad.equipment = [];
        this.dataDisplayedOnDatatable = [];
        this.recordsToDisplay = [];
        this.totalClaimAmount = 0;
        this.noResults = false;
        this.addClaimAmount = true;
        this.noClaimAmount = false;
        this.clearDraftValues();
    }

    clearDraftValues() {
        const datatable = this.template.querySelector("lightning-datatable");
        if (datatable) {
            datatable.draftValues = null;
        }
    }

    submitClaim() {
        let count;
        this.isSubmitting = true;
        this.claimRevenueRailRoad['claimRecordType'] = 'Revenue_Railroad';
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        let isValid = true;
        let contactDetailsValid = this.template.querySelector('c-csx_cmp_contact-details').validate();

        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        if (this.claimRevenueRailRoad['supplierId'] == '') {
            isValid = false;
        }

        if (this.showUploadShipment) {
            let uploadShipmentCmp = this.template.querySelector('c-csx_cmp_upload-shipment-rev-r-r');
            this.claimRevenueRailRoad.claimAmount = uploadShipmentCmp.totalClaimAmount;
            let shipments = uploadShipmentCmp.submitClaim();
            if (shipments) {
                shipments = JSON.parse(shipments);
                this.claimRevenueRailRoad.equipment = [];
                this.claimRevenueRailRoad.equipment = shipments;
            } else {
                isValid = false;
            }
        }
        if (this.claimRevenueRailRoad.equipment.length <= 0) {
            isValid = false;
            this.shipmentCheck = true;
        }

        let data = this.claimRevenueRailRoad.equipment;
        if (typeof data != 'string') {
            data.forEach((equipment) => {
                equipment.urrwinDate = equipment.urrwinDate != '' ? new Date(equipment.urrwinDate).toISOString().split('T')[0] : null;
                equipment.waybillDate = equipment.waybillDate != '' ? new Date(equipment.waybillDate).toISOString().split('T')[0] : null;

                if (equipment.vinNum === undefined) {
                    equipment.products = [];
                    equipment.distributions = [];
                    equipment.salvages = []; // needs to be removed
                }
                if (equipment.claimAmount == null || equipment.claimAmount == "") {
                    count = 1;
                }
            });
        }
        if (count == 1) {
            this.noClaimAmount = true;
            this.addClaimAmount = false;
            isValid = false;
        } else {
            this.noClaimAmount = false;
            this.addClaimAmount = false;
        }

        if (isValid && contactDetailsValid) {
            let claim = this.claimRevenueRailRoad;
            Object.keys(claim).forEach(key => {
                if (claim[key] != null && claim[key] != undefined && claim[key] != '') {
                    if (claim[key].type === 'date') {
                        claim[key] = new Date(claim[key]).toISOString();
                    } else if (key === 'equipment' && typeof claim[key] != 'string') {
                        claim[key] = JSON.stringify(claim[key]);
                    } else {
                        claim[key] = claim[key].toString();
                    }
                }

            });

            //this.checkforDuplicates(claim);
            if (this.claimRevenueRailRoad.claimType == 'Rev-RR - Payable Rchg Claim' || this.claimRevenueRailRoad.claimType == 'Rev-RR - Receivable Rchg Claim') {
                this.checkForRelatedClaim(claim);
            } else {
                this.checkforDuplicates(claim);
            }


        } else {
            this.isSubmitting = false;
            let evt = new ShowToastEvent({
                title: 'Please Review Fields',
                message: 'Enter all the mandatory fields to create a claim',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.duplicateClaimNum = null;
    }
    backToSearch() {
        let callClaimSearch = new CustomEvent('backtosearch');
        this.dispatchEvent(callClaimSearch);
    }

    checkForRelatedClaim(claim) {
        checkRelatedClaim({ relatedClaimNumber: this.claimRevenueRailRoad.previousClaimNumber, claimType: this.claimRevenueRailRoad.claimType })
            .then(result => {
                let runDup = false;
                let showDeclineMsg = false;
                let relatedClaimNotFound = false;
                if (this.claimRevenueRailRoad.claimType == 'Rev-RR - Payable Rchg Claim') {
                    if (result && result != 'Closed') {
                        this.declineMessage = 'Related Claim Number is not closed and cannot be Recharged.';
                        runDup = true;
                        showDeclineMsg = true;
                        //this.isSubmitting = false;
                        //this.checkforDuplicates(claim);
                    } else if (result && result == 'Closed') {
                        runDup = true;
                    }
                    else {
                        relatedClaimNotFound = true;
                    }

                } else if (this.claimRevenueRailRoad.claimType == 'Rev-RR - Receivable Rchg Claim') {
                    if (result && result != 'Closed') {
                        let msg = 'The entered claim number ' + this.claimRevenueRailRoad.previousClaimNumber + ' is not in a Closed status. Please provide a claim number that is in closed status.';
                        let evt = new ShowToastEvent({
                            title: 'Error',
                            message: msg,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                        showDeclineMsg = false;
                        this.isSubmitting = false;
                        return;
                    } else if (result && result == 'Closed') {
                        runDup = true;
                        //showDeclineMsg = false;
                    }
                    else {
                        relatedClaimNotFound = true;
                    }
                }
                // else{
                //     runDup = true;
                // }

                if (result == '' && showDeclineMsg == false && relatedClaimNotFound) {
                    this.isSubmitting = false;
                    let msg = 'Please fill correct related Claim Number';
                    let evt = new ShowToastEvent({
                        title: 'Error',
                        message: msg,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
                if (runDup) {
                    this.checkforDuplicates(claim);
                }

            }).catch(error => {
                this.isSubmitting = false;
                csx_cmp_logError('Csx_cmp_claimCreationRevRR', 'checkForRelatedClaim', error, '');
            });
    }

    checkforDuplicates(claim) {
        checkforDuplicates({ inputClaimDetails: claim }).then(result => {

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
            csx_cmp_logError('Csx_cmp_claimCreationRevRR', 'checkforDuplicates', error, '');
        });

    }

    redirectToCase(event) {
        let claimNumber = event.target.dataset.claimNumber;
        let claim = this.dupClaim.find(claim => claim.CaseNumber === claimNumber);
        let caseRecUrl = `/lightning/r/Case/${claim.Id}/view`;
        window.open(caseRecUrl, '_blank');
    }

    createClaim() {
        this.isSubmitting = true;
        this.isModalOpen = false;
        //method to create claim
        createClaim({ inputClaimDetails: this.claimRevenueRailRoad, duplicateClaims: this.duplicateClaimNum })
            .then(result => {
                this.claimDetails = result;
                this.isSubmitting = false;
                if (this.declineMessage) {
                    this.claimDetails.declineReason = this.declineMessage + '\n\n' + this.claimDetails.declineReason + '.';
                }
                if (this.claimDetails) {
                    let sendClaimDetails = new CustomEvent('sendclaim', { detail: JSON.stringify(this.claimDetails) });
                    this.dispatchEvent(sendClaimDetails);
                }
            })
            .catch(error => {
                this.isSubmitting = false;
                csx_cmp_logError('Csx_cmp_claimCreationRevRR', 'createClaim', error, '');
            });
    }

}