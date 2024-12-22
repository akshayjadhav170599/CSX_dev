import { LightningElement, api, track, wire } from 'lwc';
import fetchClaims from '@salesforce/apex/CSX_CMP_ClaimSearchController.getClaimRecords';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import noPaymentsFound from '@salesforce/label/c.CSX_CMP_No_Payments_Found';
import noInvoiceFound from '@salesforce/label/c.CSX_CMP_No_Invoice_Found';
import claimSelection from '@salesforce/label/c.CSX_CMP_Selection_Option_For_ClaimSearch';
import createNewClaims from '@salesforce/apex/CSX_CMP_RechargeClaimCreationController.createRechargeClaim';
import checkExistingRechargeClaims from '@salesforce/apex/CSX_CMP_RechargeClaimCreationController.checkExistingRechargeClaims';
import recordSizeLimit from '@salesforce/label/c.CSX_CMP_RecordLimit_Warning';
import searchDataLimit from '@salesforce/label/c.CSX_CMP_SearchDataLimit';
import isClaimCreationAllowed from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.isClaimCreationAllowed';

export default class Csx_cmp_claimSearchFreight extends LightningElement {

    label = {
        recordSizeLimit,
        searchDataLimit,
        noPaymentsFound,
        noInvoiceFound,
        claimSelection,
        rechargeErrorMessage: 'Claims selected should be of type FC RR Inbound Claim or Recharges Inbound Claim',
        rechargeErrorMessageEmptyList: 'Please select atleast one claim to recharge',
        rechargeSuccessMessage: 'Recharge Claim(s) created successfully',
        rechargeErrorMessageWhileCreation: 'Error while creating Recharge Claim(s)',
        rechargeCommentErrorMessage: 'Please enter Recharge Reason',
        noRechargeClaimsCreated: 'Already recharge claims are created for Selected Claims',
        rechargeStatusErrorMessage: 'Claims selected should be of New or Pending Monthly Settlement status'
    };

    @api disableSearchButton = false;
    @api disableResetButton = false;
    @api claimInfoMapParentData = {};
    @api validation = false; // if validation and parentInputValidation is serving same purpose, then we can remove one of them - need to check with Shyam
    @api parentInputValidation = false; // using for validation from parent component to check whether claim type is selected or not
    @track paymentWrapper = [];
    @track invoiceWrapper = [];
    @track recordsToDisplay = [];
    @track records = [];
    //@track columns = [];
    @track workSheetNameList = [];
    @track xlsData = [];
    @track xlsHeader = [];
    @track rechargeClaimList = [];
    @track claimType = [];
    disableExportButton = true;
    openExcelComponent = false;
    librariesLoaded = false;
    searchResults = false;
    isSearchResultAvailable = false;
    showTable = false;
    sortByDetail = 'caseId';
    claimRecordslength;
    sortDirection = 'asc';
    shownoRecordError = false;
    showDetailButton = false;
    excelFileName = 'ClaimSearchResults.xlsx';
    isLoaded = true;
    displayRechargeCommentPopup = false;
    @api displayCreateClaimButton = false;
    equipInitial;
    equipNum;
    pageSize;



    @track columns = [
        { label: "Claim Number", fieldName: 'caseId', type: 'url', typeAttributes: { label: { fieldName: 'claimNumber' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: "Claim Date", fieldName: 'claimDate', hideDefaultActions: true, type: 'date', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true", initialWidth: 95 },
        { label: "Desk", fieldName: 'deskName', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 85 },
        { label: "Assigned To", fieldName: 'assignedTo', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 132 },
        { label: 'Age', fieldName: 'claimAge', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 60 },
        { label: 'Claim Amount', fieldName: 'claimAmount', hideDefaultActions: true, type: 'text', typeAttributes: { maximumFractionDigits: '3', currencyDisplayAs: "symbol" }, sortable: "true", initialWidth: 116 },
        { label: 'Claim Type', fieldName: 'claimType', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 163 },
        { label: 'Claim Status', fieldName: 'claimStatus', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 190 },
        { label: 'Decline Code', fieldName: 'declineCode', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 120 },
        { label: 'Claimant Name', fieldName: 'supplierClaimantName', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 265 },
        { label: 'L&D Number', fieldName: 'ldReportNumbers', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 120 },
        { label: 'VIN # / Product', fieldName: 'productVinNumber', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 180 },
        { label: 'Origin City', fieldName: 'equipmentOriginCity', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 130 },
        { label: 'Origin State', fieldName: 'equipmentOriginState', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 95 },
        { label: 'Dest City', fieldName: 'equipmentDestCity', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 97 },
        { label: 'Dest State', fieldName: 'equipmentDestState', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 97 },
        { label: 'Equipment ID', fieldName: 'equipmentID', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 117 },
        { label: 'Waybill#', fieldName: 'equipmentWaybillNumber', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 98 },
        { label: 'Waybill Date', fieldName: 'equipmentWaybillDate', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 115 },
        { label: 'STCC Code', fieldName: 'equipmentSTCCCode', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 107 },
        { label: 'Shipper', fieldName: 'equipmentShipper', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 295 },
        { label: 'Consignee', fieldName: 'equipmentConsignee', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 295 },
        { label: 'Customer', fieldName: 'customerName', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 240 },
        { label: "Netting Claim #", fieldName: 'claimNettingClaim', type: 'url', typeAttributes: { label: { fieldName: 'claimNettingClaimNum' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: 'Service Period', fieldName: 'servicePeriod', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 115 },
        // { label: 'CSX Explanation', fieldName: 'csxExplanation', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 145 },
        // { label: 'Work Note', fieldName: 'workNote', hideDefaultActions: true, type: 'text', wrapText: "true", initialWidth: 145 }
    ];
    buttonColumns = [
        {
            type: "button", label: 'View', initialWidth: 100, typeAttributes: {
                label: 'Documents',
                name: 'DocumnetDetails',
                title: 'DocumnetDetails',
                disabled: false,
                value: 'view',
                iconPosition: 'right',
                iconName: '',
                variant: 'slds-button_outline-brand'
            }
        }
    ]

    @track claimData = {
        'equipmentInitial': '',
        'equipmentNumber': '',
        'vinNumber': '',
        'nettingClaimNumber': '',
        'servicePeriod': '',
        'lDRNumber': '',
        'claimFromDate': '',
        'claimToDate': '',
        'rechargeReason': '',
    };

    @wire(isClaimCreationAllowed, { permissionName: 'CSX_CMP_Create_Recharge_Claim' })
    claimCreationAllowed({ error, data }) {
        if (data) {
            this.displayCreateClaimButton = data;
        } else if (error) {
            this.displayCreateClaimButton = false;
        }
    }

    handleInputChange(event) {
        this.claimData[event.target.name] = event.target.value;
        let equipInitial = this.template.querySelector('[data-id="equipInitial"]');
        let equipNumber = this.template.querySelector('[data-id="equipNumber"]');
        this.disableSearchButton = false;
        this.disableResetButton = false;
        this.equipInitial = equipInitial.value;
        this.equipNum = equipNumber.value;
        console.log('inside equipment length: internal' + this.equipInitial.length);
        this.displayCreateClaimButton = true;

        if (this.equipInitial && /[^a-zA-Z]/.test(this.equipInitial)) {
            equipInitial.setCustomValidity('Only alphabet characters are allowed.');
            this.validation = true;
        }
        if (event.key === 'Tab' && this.equipInitial == '') {
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity(); // Report the validity state
        }
        if (this.equipInitial == '' || this.equipInitial == undefined) {
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity(); // Report the validity state
        }
        else if (!(/[^a-zA-Z]/.test(this.equipInitial)) && this.equipInitial.length >= 2) {
            console.log('inside clear()');
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity();
            this.validation = false;
        }
        else if (this.equipInitial.length < 2) {
            console.log('inside equipment length: inner' + this.equipInitial.length);
            equipInitial.setCustomValidity('At least 2 alphabet characters are required.');
            this.validation = true;
        }

        equipInitial.reportValidity();

        if (this.equipNum) {
            console.log(' this.equipNum: ' + this.equipNum);
            console.log('this.equipNum: ' + this.equipNum);
            if (!equipNumber.value || isNaN(equipNumber.value)) {
                equipNumber.setCustomValidity('Only numeric values are allowed.');
                this.showNumError = true;
                console.log(' inside equipNumber.value: ' + equipNumber.value);
                this.validation = true;
            } else {
                console.log('else: ' + this.equipNum);
                equipNumber.setCustomValidity(''); // Clear any previous error message
                this.showNumError = false;
                equipNumber.reportValidity();
                this.validation = false;
                // Proceed with your logic
            }
            equipNumber.reportValidity();
        } else {
            this.validation = false;
            equipNumber.setCustomValidity("");
            equipNumber.reportValidity();
        }


        //VIN Number Validation
        const vinPattern = /^[A-Za-z0-9]+$/;
        let inputVinNumber = this.template.querySelector('[data-id="vinNumber"]');
        if (this.claimData.vinNumber) {
            console.log('inputVinNumber :', inputVinNumber);
            if (inputVinNumber.value && (inputVinNumber.value.length == 8 || inputVinNumber.value.length == 17) && vinPattern.test(inputVinNumber.value)) {
                console.log('inputVinNumber if:', inputVinNumber);
                inputVinNumber.setCustomValidity("");
                inputVinNumber.reportValidity();
                this.validation = false;
            } else {
                console.log('inputVinNumber else:', inputVinNumber);
                inputVinNumber.setCustomValidity('VIN number must be either 8 or 17 characters long.');
                inputVinNumber.reportValidity();
                this.validation = true;
            }
        } else {
            this.isValidationError = false;
            inputVinNumber.setCustomValidity("");
            inputVinNumber.reportValidity();
        }
    }

    handleEnter(event) {
        if (event.keyCode === 13) {
            this.handleSearchClaim();
        }
    }
    @api
    handleSearchClaim() {
        this.parentInputValidation = true;
        let selectEvent = new CustomEvent('validateinput', { bubbles: true });
        this.dispatchEvent(selectEvent);
        console.log('child validation');
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-input');
        fields.forEach(element => {
            if (!element.checkValidity()) {
                element.reportValidity();
                isValid = false;
            }
        });
        window.setTimeout(() => {
            if (!this.parentInputValidation) {
                isValid = false;
            }
            console.log('this.parentInputValidation from child: ', this.parentInputValidation);
            if (!isValid) {
                const selectionHeaderIssue = new ShowToastEvent({
                    message: 'Please review error messages',
                    duration: '3000',
                    variant: 'error',
                });
                this.dispatchEvent(selectionHeaderIssue);
                return;
            } else {
                this.submitSearch();
            }
        }, 300);
    }


    async validateInput() {
        this.parentInputValidation = true;
        let selectEvent = new CustomEvent('validateinput', { bubbles: true });
        this.dispatchEvent(selectEvent);
        console.log('child validation');
        return new Promise((resolve, reject) => {
            let isValid = true;
            let fields = this.template.querySelectorAll('lightning-input');
            fields.forEach(element => {
                if (!element.checkValidity()) {
                    element.reportValidity();
                    isValid = false;
                }
            });
            window.setTimeout(() => {
                if (!this.parentInputValidation) {
                    isValid = false;
                }

                console.log('this.parentInputValidation from child: ', this.parentInputValidation);
                return resolve(isValid);

            }, 300);
        });
    }

    // handleSearchClaim() {
    submitSearch() {

        console.log('this.validation: ' + this.validation);
        this.showTable = false;
        this.isLoaded = false;
        this.shownoRecordError = false;
        this.claimRecordslength = '';
        this.searchResults = false;
        this.isSearchResultAvailable = false;
        this.showDetailButton = false;
        this.dispatchEvent(new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true }));
        this.records = [];
        const searchValues = 'search';
        const selectEvent = new CustomEvent('searchchange', { detail: searchValues, bubbles: true });
        this.dispatchEvent(selectEvent);
        let claimInfoMap = new Map();
        claimInfoMap = Object.keys(this.claimData).reduce((map, key) => {
            if (this.claimData[key]) {
                map.set(key, this.claimData[key]);
            }
            return map;
        }
            , new Map());
        //let obj = Object.fromEntries(claimInfoMap);
        let claimInfoMapParent = new Map();
        claimInfoMapParent = Object.keys(this.claimInfoMapParentData).reduce((map, key) => {

            if (this.claimInfoMapParentData[key]) {
                map.set(key, this.claimInfoMapParentData[key]);
            }
            return map;
        }
            , new Map());

        let result = new Map([...claimInfoMapParent]);

        claimInfoMap.forEach((value, key) => {
            if (result.has(key)) {
                result.set(key, claimInfoMapParent.get(key));
            } else {
                result.set(key, value);
            }
        });
        let obj2 = Object.fromEntries(result);
        let claimDataStringCon = JSON.stringify(obj2);
        console.log('claimDataStringCon :' + claimDataStringCon);
        if (claimDataStringCon != '{"claimGroup":"Freight"}') {
            if (this.validation == false) {
                fetchClaims({ claimSearchParameters: claimDataStringCon })
                    .then(result => {
                        if (result) {
                            const formatter = new Intl.NumberFormat('en-US', {
                                style: 'currency',
                                currency: 'USD'
                            });
                            let finalData = result.results;
                            this.claimRecordslength = finalData.length;
                            if (this.claimRecordslength >= this.label.searchDataLimit) {
                                const selectionHeaderIssue = new ShowToastEvent({
                                    message: this.label.recordSizeLimit,
                                    duration: '3000',
                                    variant: 'warning',
                                });
                                this.dispatchEvent(selectionHeaderIssue);
                                this.isLoaded = true;
                                return;
                            }
                            if (finalData.length > 0) {
                                let tempRecs = [];
                                finalData.forEach((record) => {
                                    let tempRec = Object.assign({}, record);
                                    tempRec.caseId = '/' + tempRec.caseId;
                                    tempRec.claimAmount = formatter.format(tempRec.claimAmount);
                                    if (tempRec.claimNettingClaim) {
                                        tempRec.claimNettingClaim = '/' + tempRec.claimNettingClaim;
                                    }
                                    tempRecs.push(tempRec);
                                });
                                this.records = tempRecs;
                                this.showTable = true;
                                this.isLoaded = true;
                                this.disableExportButton = false;
                                this.searchResults = true;
                                this.isSearchResultAvailable = true;
                                this.showDetailButton = true;
                                this.displayCreateClaimButton = true;
                                const paymentEvent = new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true });
                                this.dispatchEvent(paymentEvent);
                            }
                            else {
                                this.displayCreateClaimButton = false;
                                this.showTable = false;
                                this.disableExportButton = true;
                                this.searchResults = false;
                                this.isSearchResultAvailable = false
                                this.showDetailButton = false;
                                this.shownoRecordError = true;
                                this.isLoaded = true;
                            }
                        }
                        else {
                            this.shownoRecordError = true;
                            this.isLoaded = true;
                        }
                    })
                    .catch(error => {
                        let parameters = this.records;
                        csx_cmp_logError('csx_cmp_claimSearch', 'handleSearchClaim', error, parameters);
                    });
            } else {
                const selectionHeaderIssue = new ShowToastEvent({
                    message: 'Please review error messages',
                    duration: '5000',
                    variant: 'warning'
                });
                this.dispatchEvent(selectionHeaderIssue);
                this.isLoaded = true;
            }
        } else {

            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Please enter atleast 1 search criteria',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }
    }
    handleClaimRecordsDisplay(event) {
        this.recordsToDisplay = event.detail;

    }
    handlePageSize(event) {
        try {
            this.pageSize = event.detail;
            console.log('inside handlePageSize()');
            let searchQuerySelectorString = 'c-csx_cmp_pagination';
            console.log('this.pageSize: ' + this.pageSize);
            this.template.querySelector(searchQuerySelectorString).pageSize = this.pageSize;
        } catch (ex) {
            console.log(
                `Error caught: ${ex.message}`
            )
        }
    }

    downloadClaimData() {
        this.openExcelComponent = true;
        if (this.librariesLoaded) {
            this.getClaimExport();
        }
    }

    excelLibraryLoaded() {
        this.librariesLoaded = true;
        this.getClaimExport();
    }

    getClaimExport() {
        try {
            let listForExport = this.records.map(function (obj) {
                let tmp = {};
                tmp["Claim Number"] = obj.claimNumber;
                tmp["Claim Date"] = obj.claimDate;
                tmp["Desk"] = obj.deskName;
                tmp["Assigned To"] = obj.assignedTo;
                tmp["Age"] = obj.claimAge;
                tmp["Claim Amount"] = obj.claimAmount;
                tmp["Claim Type"] = obj.claimType;
                tmp["Claim Status"] = obj.claimStatus;
                tmp["Decline Code"] = obj.declineCode;
                tmp["Claimant Name"] = obj.supplierClaimantName;
                tmp["L&D Number"] = obj.ldReportNumbers;
                tmp["VIN # / Product"] = obj.productVinNumber;
                tmp["Origin City"] = obj.equipmentOriginCity;
                tmp["Origin State"] = obj.equipmentOriginState;
                tmp["Dest City"] = obj.equipmentDestCity;
                tmp["Dest State"] = obj.equipmentDestState;
                tmp["Equipment ID"] = obj.equipmentID;
                tmp["Waybill#"] = obj.equipmentWaybillNumber;
                tmp["Waybill Date"] = obj.equipmentWaybillDate;
                tmp["STCC Code"] = obj.equipmentSTCCCode;
                tmp["Shipper"] = obj.equipmentShipper;
                tmp["Consignee"] = obj.equipmentConsignee;
                tmp["Customer"] = obj.customerName;
                tmp["Netting Claim #"] = obj.claimNettingClaimNum;
                tmp["Service Period"] = obj.servicePeriod;
                tmp["CSX Explanation"] = obj.csxExplanation;
                tmp["Work Note"] = obj.workNote;
                tmp["ECM Link"] = obj.ecmLink;
                return tmp;
            });
            this.xlsFormatter(listForExport, "ClaimData");
        } catch (error) {
            let parameters = JSON.stringify(this.records);
            csx_cmp_logError('csx_cmp_claimSearch', 'getClaimExport', error, parameters);
        }
    }

    xlsFormatter(data, sheetName) {
        let Header = Object.keys(data[0]);
        this.xlsHeader.push(Header);
        this.workSheetNameList.push(sheetName);
        this.xlsData.push(data);
        this.template.querySelector("c-csx_cmp_excelexport").download();
        this.xlsHeader = [];
        this.workSheetNameList = [];
        this.xlsData = [];
    }

    handleRowLinkClickSelection(event) {
        try {
            const ecmLinkForDocument = event.detail.row.ecmLink;
            const actionName = event.detail.action.name;
            const ecmLink = JSON.stringify(ecmLinkForDocument);
            if (actionName === 'DocumnetDetails') {
                if (ecmLink) {
                    const externalURLWithParams = ecmLinkForDocument;
                    window.open(externalURLWithParams, '_blank');
                }
            }
        } catch (error) {
            let parameters = event.detail.row.ecmLink;
            csx_cmp_logError('csx_cmp_claimSearchFreight', 'handleRowLinkClickSelection', error, parameters);
        }
    }

    handleSelectedRows(event) {
        this.rechargeClaimList = [];
        let selectedRows = event.detail.selectedRows;
        this.rechargeClaimList = selectedRows;
        this.paymentWrapper = [];
        this.invoiceWrapper = [];
        this.claimType = [];
        selectedRows.forEach((record) => {
            let tempRec = Object.assign({}, record);
            this.paymentWrapper.push(tempRec.aPSettlements);
            this.invoiceWrapper.push(tempRec.aRSettlements);
            this.claimType.push(tempRec.claimType);
        });
        const paymentEvent = new CustomEvent('paymentchange', { detail: this.paymentWrapper, bubbles: true });
        this.dispatchEvent(paymentEvent);
        const invoiceEvent = new CustomEvent('invoicechange', { detail: this.invoiceWrapper, bubbles: true });
        this.dispatchEvent(invoiceEvent);
        const claimTypeEvent = new CustomEvent('typechange', { detail: this.claimType, bubbles: true });
        this.dispatchEvent(claimTypeEvent);
    }


    handleRecharge() {

        if (this.rechargeClaimList.length == 0) {
            const rechargeError = new ShowToastEvent({
                title: 'Error',
                message: this.label.rechargeErrorMessageEmptyList,
                variant: 'error',
            });
            this.dispatchEvent(rechargeError);
        } else {

            let selectedRows = this.rechargeClaimList;
            let rechargeClaimTypeList = [];
            let rechargeClaimStatusList = [];
            let selectedClaimIds = [];
            let existingRechargeClaims = {};
            let alreadyRecargedClaims = 'These claims are already recharged: ';
            let alreadyRecargedClaimsList = [];
            let recharge;
            let errorMessage = '';

            selectedRows.forEach(element => {
                let rechargeClaimType = false;
                if (element.claimType == 'FC RR Inbound Claim' || element.claimType == 'Recharges Inbound Claim') {
                    rechargeClaimType = true;
                }
                rechargeClaimTypeList.push(rechargeClaimType);
                let rechargeClaimStatus = false;
                if (element.claimStatus == 'New' || element.claimStatus == 'Pending Monthly Settlement') {
                    rechargeClaimStatus = true;
                }
                rechargeClaimStatusList.push(rechargeClaimStatus);
                selectedClaimIds.push(element.caseId.split('/').pop());
            });


            // based on the claim type and status, we are checking the recharge claim creation is allowed or not and respective error message should be displayed


            // if (rechargeClaimTypeList.length > 0) {
            //     recharge = rechargeClaimTypeList.every(function (item) {
            //         return item == true;
            //     });
            // } else {
            //     recharge = false;
            // }

            if (rechargeClaimTypeList.length > 0) {
                recharge = rechargeClaimTypeList.every(function (item) {
                    return item == true;
                });
                if (!recharge) {
                    errorMessage = this.label.rechargeErrorMessage;
                }
            }

            if (rechargeClaimStatusList.length > 0 && !errorMessage) {
                recharge = rechargeClaimStatusList.every(function (item) {
                    return item == true;
                });
                if (!recharge) {
                    errorMessage = this.label.rechargeStatusErrorMessage;
                }
            } else {
                recharge = false;
            }


            if (errorMessage) {
                let rechargeError = new ShowToastEvent({
                    title: 'Warning',
                    message: errorMessage,
                    variant: 'Warning',
                });
                this.dispatchEvent(rechargeError);
            } else {
                checkExistingRechargeClaims({ claimIds: selectedClaimIds }).then(result => {
                    if (result) {
                        existingRechargeClaims = new Map(Object.entries(result));
                        existingRechargeClaims.forEach((value, key) => {
                            if (value === 'false') {
                                alreadyRecargedClaimsList.push(key);
                            }
                        });
                    }
                    if (alreadyRecargedClaimsList.length > 0) {
                        alreadyRecargedClaims = alreadyRecargedClaims + alreadyRecargedClaimsList.join(', ') + '. Please deselect these claims and try again.';
                    }

                    if (alreadyRecargedClaims != 'These claims are already recharged: ') {
                        let error = new ShowToastEvent({
                            title: 'Error',
                            message: alreadyRecargedClaims,
                            variant: 'error',
                        });
                        this.dispatchEvent(error);
                        recharge = false;
                    }

                    if (recharge) {
                        this.displayRechargeCommentPopup = true;
                    }
                }).catch(error => {
                    recharge = false;
                    let parameters = selectedClaimIds;
                    csx_cmp_logError('csx_cmp_claimSearchFreight', 'handleRecharge', error, parameters);
                });
            }
        }
    }

    closeModal() {
        this.displayRechargeCommentPopup = false;
    }


    createRechargeClaim() {
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-textarea');
        fields.forEach(element => {
            if (!element.checkValidity()) {
                element.reportValidity();
                isValid = false;
            }
        });
        if (isValid) {
            let comment = this.claimData.rechargeReason;
            let selectedClaimIds = '';
            this.rechargeClaimList.forEach(element => {
                console.log('element.caseId', element.caseId);
                let claimId = element.caseId.split('/').pop();
                selectedClaimIds += claimId + ',';
            });

            console.log('selectedClaimIds', selectedClaimIds);

            selectedClaimIds = selectedClaimIds.includes(undefined) ? selectedClaimIds.replace(undefined, '') : selectedClaimIds;
            selectedClaimIds = selectedClaimIds.slice(0, -1);
            let data = {
                comment: comment,
            }
            this.displayRechargeCommentPopup = false;
            this.isLoaded = false;

            createNewClaims({ sourceId: selectedClaimIds, data: JSON.stringify(data) }).then(result => {
                this.isLoaded = true;
                if (result) {
                    let successMessage = this.label.rechargeSuccessMessage + ' ( ' + result + ' )';
                    const rechargeSuccess = new ShowToastEvent({
                        title: 'Success',
                        message: successMessage,
                        variant: 'success',
                    });
                    this.dispatchEvent(rechargeSuccess);
                    this.rechargeClaimList = [];
                    this.handleSearchClaim();
                } else {
                    this.rechargeClaimList = [];
                    const rechargeError = new ShowToastEvent({
                        title: 'Error',
                        message: this.label.noRechargeClaimsCreated,
                        variant: 'error',
                    });
                    this.dispatchEvent(rechargeError);
                }
            });

        } else {
            const rechargeError = new ShowToastEvent({
                title: 'Error',
                message: this.label.rechargeCommentErrorMessage,
                variant: 'error',
            });
            this.dispatchEvent(rechargeError);
        }
    }

    doSortingDetail(event) {
        let sortbyField = event.detail.fieldName;
        if (sortbyField === "caseId") {
            this.sortByDetail = "claimNumber";
        }
        else {
            this.sortByDetail = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortDataDetail(this.sortByDetail, this.sortDirection);
        this.sortByDetail = sortbyField;
    }

    sortDataDetail(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.records);
        this.records = sortResult.sort(function (a, b) {
            a = a[fieldName] ? a[fieldName] : '';
            b = b[fieldName] ? b[fieldName] : '';
            if (a < b) {
                return sortDirection === 'asc' ? -1 : 1;
            } else if (a > b) {
                return sortDirection === 'asc' ? 1 : -1;
            } else {
                return 0;
            }
        })
        if (this.searchResults) {
            this.searchResults = false;
        } else {
            this.searchResults = true;
        }
    }

    handleResetClick() {
        this.paymentID = [];
        this.claimInfoMapParentData = {};
        this.displayCreateClaimButton = false;
        const resetValues = 'reset';
        const selectEvent = new CustomEvent('valuechange', { detail: resetValues, bubbles: true });
        this.dispatchEvent(selectEvent);
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.value = '';
            element.setCustomValidity('');
            element.reportValidity();
        });
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.value = '';
        });
        this.claimData = {
            'equipmentInitial': '',
            'equipmentNumber': '',
            'vinNumber': '',
            'nettingClaimNumber': '',
            'servicePeriod': '',
            'lDRNumber': '',
            'claimFromDate': '',
            'claimToDate': ''
        };
        this.disableSearchButton = true;
        this.disableResetButton = true;
        this.showTable = false;
        this.showDetailButton = false;
        this.claimRecordslength = '';
        this.shownoRecordError = false;
        this.isLoaded = true;
        this.records = [];
        this.isSearchResultAvailable = false;
    }
}