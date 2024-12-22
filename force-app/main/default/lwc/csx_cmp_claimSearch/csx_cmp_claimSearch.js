import { LightningElement, track, wire } from 'lwc';
import csxStyle from '@salesforce/resourceUrl/CSX_CMP_CSXTheme';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';


import Id from '@salesforce/user/Id';  // where is this used?

// Importing Logger
import { csx_cmp_logError } from 'c/csx_cmp_logError';

// Apex method imports
import getClaimSearchBasedOnRole from '@salesforce/apex/CSX_CMP_ClaimSearchController.getClaimSearchBasedOnRole';

// Custom labels
import noPaymentsFound from '@salesforce/label/c.CSX_CMP_No_Payments_Found';
import claimSelection from '@salesforce/label/c.CSX_CMP_Selection_Option_For_ClaimSearch';
import noInvoiceFound from '@salesforce/label/c.CSX_CMP_No_Invoice_Found';
import ageCriteria from '@salesforce/label/c.CSX_CMP_AgeCriteria_Label';
import claimAmountCriteria from '@salesforce/label/c.CSX_CMP_ClaimAmountCriteria_Label';
import futureDate from '@salesforce/label/c.CSX_CMP_FutureDate_Label';
import dateCriteria from '@salesforce/label/c.CSX_CMP_DateCriteria_Label';
import FreightClaimTypeOptions from '@salesforce/label/c.CSX_CMP_Freight_Claim_Type_Options';
import RevenueContractClaimTypeOptions from '@salesforce/label/c.CSX_CMP_Revenue_Contract_Claim_Type_Options';
import RevenueOverchargeClaimTypeOptions from '@salesforce/label/c.CSX_CMP_Revenue_Overcharge_Claim_Type_Options';
import RevenueRailroadClaimTypeOptions from '@salesforce/label/c.CSX_CMP_Revenue_Railroad_Claim_Type_Options';
import FreightclaimStatusOptions from '@salesforce/label/c.CSX_CMP_Freight_Claim_Status_Options';
import RevenueRailroadclaimStatusOptions from '@salesforce/label/c.CSX_CMP_Revenue_Railroad_Claim_Status_Options';
import RevenueOverchargeclaimStatusOptions from '@salesforce/label/c.CSX_CMP_Revenue_Overcharge_Claim_Status_Options';
import RevenueContractRefundclaimStatusOptions from '@salesforce/label/c.CSX_CMP_Revenue_Contract_Refund_Status_Options';

const claimdefaultSelectVal = 'Freight';

export default class Csx_cmp_claimSearch extends LightningElement {
    label = {
        FreightClaimTypeOptions,
        RevenueContractClaimTypeOptions,
        RevenueOverchargeClaimTypeOptions,
        RevenueRailroadClaimTypeOptions,
        FreightclaimStatusOptions,
        RevenueRailroadclaimStatusOptions,
        RevenueOverchargeclaimStatusOptions,
        RevenueContractRefundclaimStatusOptions,
        ageCriteria,
        claimAmountCriteria,
        futureDate,
        dateCriteria,
        noPaymentsFound,
        claimSelection,
        noInvoiceFound
    };
    @track paymentWrapper = [];
    @track invoiceWrapper = [];
    @track claimTypeCheck = [];
    @track invoiceRecordToDisplay = [];
    @track paymentRecordToDisplay = [];
    @track workSheetNameListPayment = [];
    @track workSheetNameListInvoice = [];
    @track xlsDataPayment = [];
    @track xlsDataInvoice = [];
    @track xlsHeaderInvoice = [];
    @track xlsHeaderPayment = [];
    @track fcTypes = ['FC Customer Claim', 'FC Customer Automobile Claim', 'Railroad Netting FC Claim', 'FC Salvage Claim'];
    showPayment = false;
    invoiceButton = false;
    showInvoice = false;
    openExcelComponent = false;
    openExcelComponentPayment = false;
    openExcelComponentInvoice = false;
    librariesLoadedPayment = false;
    librariesLoadedInvoice = false;
    showDetailButton = false;
    Freight = false;
    RevenueRailroad = false;
    RevenueContractRefunds = false;
    RevenueOvercharge = false;
    claimval = claimdefaultSelectVal;
    claimdefaultSelectVal = claimdefaultSelectVal;
    statusOptions;
    deskValues;
    claimPriorityOptions;
    inputToDate;
    inputStartDate;
    ageToData;
    claimAmountFromData;
    freightClaimTypeCheck;
    claimAmountToData;
    // claimTypes;
    excelFileNamePayment = 'PaymentSearchResults.xlsx';
    excelFileNameInvoice = 'InvoiceSearchResults.xlsx';
    sortByPayment = 'paymentID';
    sortByInvoice = 'invoiceID';
    sortDirection = 'asc';
    stylePath = csxStyle;
    userId = Id;
    userRoleName = '';
    developerName = '';
    displayCreateClaim = false;
    roleAccessDetails;
    validationCheck = false;

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}/css3/styles.css`)
        ]);
        // this.querySelector('c-csx_cmp_claim-search-freight').addEventListener('validateInput', this.validateInput.bind(this));
    }

    @track paymentColumns = [
        { label: "Settlement #", fieldName: 'paymentURL', type: 'url', typeAttributes: { label: { fieldName: 'paymentID' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: "Claim #", fieldName: 'claimURL', type: 'url', typeAttributes: { label: { fieldName: 'claimID' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: "Claim Amount Paid", fieldName: 'amountPaid', type: 'text', sortable: "true", initialWidth: 165 },
        { label: "Check #", fieldName: 'checkNumber', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 145 },
        { label: "Check Date", fieldName: 'checkDate', hideDefaultActions: true, type: 'date', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true", initialWidth: 160 },
        { label: "Check Amount", fieldName: 'checkAmount', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 145 },
        { label: "Payment Method", fieldName: 'paymentMethod', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 },
        { label: "Invoice Status", fieldName: 'paymentStatus', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 },
        { label: "Payment Address", fieldName: 'paymentAddress', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 },
        { label: "Bank Account", fieldName: 'bankAccount', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 }
    ];
    @track InvoiceColumns = [
        { label: "Settlement #", fieldName: 'invoiceURL', type: 'url', typeAttributes: { label: { fieldName: 'invoiceID' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: "Claim #", fieldName: 'claimURL', type: 'url', typeAttributes: { label: { fieldName: 'claimID' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        { label: "Claim Amount Paid", fieldName: 'amountPaid', type: 'text', sortable: "true", initialWidth: 165 },
        { label: "Invoice #", fieldName: 'invoiceNumber', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 145 },
        { label: "Invoice Date", fieldName: 'invoiceDate', hideDefaultActions: true, type: 'date', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true", initialWidth: 160 },
        { label: "Invoice Amount", fieldName: 'invoiceAmount', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 145 },
        { label: "Invoice Status", fieldName: 'invoicePaymentStatus', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 },
        { label: "Payment Address", fieldName: 'paymentAddress', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 },
        { label: "Bank Account", fieldName: 'bankAccount', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 140 }
    ];

    // MR-00971
    @track requiredOnLayout = {
        'claimType': false
    }

    validateInput(event) {
        console.log('parent validation');
        let isValid = true;
        let fields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')];
        console.log('fields: ', fields);
        fields.forEach(field => {
            if (!field.checkValidity()) {
                isValid = false;
                field.reportValidity();
            }
        });
        console.log('isValid from parent: ', isValid);
        this.template.querySelector('c-csx_cmp_claim-search-freight').parentInputValidation = isValid;
        console.log('this.querySelector(c-csx_cmp_claim-search-freight).parentInputValidation: ', this.template.querySelector('c-csx_cmp_claim-search-freight').parentInputValidation);
        return isValid;
    }


    connectedCallback() {
        if (this.claimdefaultSelectVal === 'Freight') {
            this.invoiceButton = true;
            this.Freight = true;
            this.RevenueRailroad = false;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = false;
            let claimStatus = [];
            let modifiedLabel;
           /* this.label.FreightclaimStatusOptions.split('|').forEach(element => {
               // modifiedLabel= element.replace(/\s+/g, '-');
                modifiedLabel=element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                claimStatus.push({ label: modifiedLabel, value: element });
            });*/

            this.label.FreightclaimStatusOptions.split('|').forEach(element => {
                if (element.includes("On Hold") || element.includes("Re-Declined") || 
                    element.includes("Re-Opened")) {
                    modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                    claimStatus.push({ label: modifiedLabel, value: element });                        
                    console.log('inside if Pending review');
                } else {
                    console.log('inside else replace Pending review');
                    claimStatus.push({ label: element, value: element });
                }
            });


            this.statusOptions = claimStatus;
            this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
            // let options = [];
            // this.label.FreightClaimTypeOptions.split('|').forEach(element => {
            //     options.push({ label: element, value: element });
            // });
            // this.claimTypes = options;

        }
        console.log('this.claimdefaultSelectVal: ' + this.claimdefaultSelectVal);
        if (this.claimdefaultSelectVal === 'Revenue_Contract_Refund' || this.claimdefaultSelectVal === 'Revenue_Overcharge') {
            this.invoiceButton = false;
        }


        let newDateOptions = { year: "numeric", month: "2-digit", day: "2-digit" };
        let today = new Date();
        let curyear = today.getFullYear();
        let curyearMonth = today.getMonth() + 1;
        let curyearDay = today.getDate();
        let lastYear = curyear - 1;
        if ((curyearMonth == 2) && (curyearDay == 29)) {
            curyearDay = 28;
        }
        let lastYearDisplay = ("0000" + lastYear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        let todayy = ("0000" + curyear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        this.claimData.claimFromDate = lastYearDisplay.toLocaleString("en-US", newDateOptions);
        this.claimData.claimToDate = todayy.toLocaleString("en-US", newDateOptions);
    }


    @wire(getClaimSearchBasedOnRole)
    layoutDetails({ data, error }) {
        if (data) {
            console.log('data: ', data);
            this.userRoleName = data.CSX_CMP_Search_Layout_Access__c;
            console.log('this.userRoleName:'+this.userRoleName );
            this.displayCreateClaim = data.CSX_CMP_Create_Claim__c;
            this.developerName = data.DeveloperName;
            this.roleAccessDetails = data;
            if (this.userRoleName == 'Overcharge,Contract Refund,Railroad Revenue') { 
                this.claimdefaultSelectVal = 'Revenue_Contract_Refund';
                this.Freight = false;
                this.invoiceButton = false;
                this.RevenueRailroad = false;
                this.RevenueContractRefunds = true;
                this.RevenueOvercharge = false;
                let claimStatus = [];
                let modifiedLabel;
               /* this.label.RevenueContractRefundclaimStatusOptions.split('|').forEach(element => {
                    modifiedLabel=element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                    claimStatus.push({ label: modifiedLabel, value: element });
                });*/
                this.label.RevenueContractRefundclaimStatusOptions.split('|').forEach(element => {
                    if (element.includes("On Hold") || element.includes("Re-Declined") || 
                    element.includes("Re-Opened")) {
                    modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                    claimStatus.push({ label: modifiedLabel, value: element });                        
                    console.log('inside if Pending review');
                    } else {
                        console.log('inside else replace Pending review');
                        claimStatus.push({ label: element, value: element });
                    }
                });
                this.statusOptions = claimStatus;
                this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
                let options = [];
                this.label.RevenueContractClaimTypeOptions.split('|').forEach(element => {
                    options.push({ label: element, value: element });
                });
                // this.claimTypes = options;
                return [
                    { label: 'Contract Refund', value: 'Revenue_Contract_Refund' }
                ];
            }
            let userRole = data.MasterLabel;
            console.log('userRole: ', userRole);
            if (userRole.includes('Transflo') || userRole.includes('LEADS')) {
                this.requiredOnLayout.claimType = true;
                console.log('this.requiredOnLayout.claimType: ', this.requiredOnLayout.claimType);
            }

        } else if (error) {
            csx_cmp_logError('csx_cmp_claimSearch', 'layoutDetails', error, this.userRoleName);
        }
    }

    claimTypesMap = new Map();

    get claimTypes() {
        let claimTypesMap = new Map();
        let validTypes = [];
        try {
            if (this.roleAccessDetails) {
                if (this.roleAccessDetails.CSX_CMP_Eligible_Claim_Types_for_Search__c) {
                    let eligibleClaims = this.roleAccessDetails.CSX_CMP_Eligible_Claim_Types_for_Search__c.split(',');
                    eligibleClaims.forEach(element => {
                        let splitElement = element.split('-');
                        let key = splitElement[0];
                        let value = [];
                        splitElement.forEach((element, index) => {
                            if (index > 0) {
                                value.push(element);
                            }
                        });

                        if (claimTypesMap.has(key)) {
                            let temp = claimTypesMap.get(key);
                            claimTypesMap.set(key, temp + ',' + value.join('-'));
                        } else {
                            claimTypesMap.set(key, value.join('-'));
                        }
                    });
                }

                this.claimTypesMap = claimTypesMap;
                console.log(' this.claimdefaultSelectVal: ', this.claimdefaultSelectVal);
                console.log('this.claimTypesMap: ', this.claimTypesMap);
                claimTypesMap.get(this.claimdefaultSelectVal).split(',').forEach(element => {
                    validTypes.push({ label: element, value: element });
                });
                validTypes = validTypes.sort((a, b) => a.label.localeCompare(b.label))
                /* claimTypesMap.forEach(element => {
                     validTypes.push({ label: element, value: element });
                 });*/
                 
                console.log('validTypes: ', validTypes);
                
            }

        } catch (ex) {
            console.log('Error in claimTypes: ', ex);
        }
        return validTypes;

    }

    get claimSelectOptions() {
        if (this.userRoleName == 'Freight,Overcharge,Contract Refund,Railroad Revenue' || this.userRoleName == '') {
            return [
                { label: 'Freight', value: 'Freight' },
                { label: 'Contract Refund', value: 'Revenue_Contract_Refund' },
                { label: 'Overcharge', value: 'Revenue_Overcharge' },
                { label: 'Railroad Revenue', value: 'Revenue_Railroad' },
            ];

        }else if (this.userRoleName == 'Overcharge,Contract Refund,Railroad Revenue') { 
            return [
                { label: 'Contract Refund', value: 'Revenue_Contract_Refund' },
                { label: 'Overcharge', value: 'Revenue_Overcharge' },
                { label: 'Railroad Revenue', value: 'Revenue_Railroad' },
            ];
        }
         else if (this.userRoleName == 'Freight') {
            this.claimdefaultSelectVal = 'Freight';
            this.Freight = true;
            this.RevenueRailroad = false;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = false;
            return [
                { label: 'Freight', value: 'Freight' }
            ];

        } else if (this.userRoleName == 'Contract Refund') {
            this.Freight = false;
            this.invoiceButton = false;
            this.RevenueRailroad = false;
            this.RevenueContractRefunds = true;
            this.RevenueOvercharge = false;
            this.claimdefaultSelectVal = 'Revenue_Contract_Refund';
            let claimStatus = [];
            let modifiedLabel;
            this.label.RevenueContractRefundclaimStatusOptions.split('|').forEach(element => {
                if (element.includes("On Hold") || element.includes("Re-Declined") || 
                element.includes("Re-Opened")) {
                modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                claimStatus.push({ label: modifiedLabel, value: element });                        
                console.log('inside if Pending review');
            } else {
                console.log('inside else replace Pending review');
                claimStatus.push({ label: element, value: element });
            }
            });
            this.statusOptions = claimStatus;
            this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
            let options = [];
            this.label.RevenueContractClaimTypeOptions.split('|').forEach(element => {
                options.push({ label: element, value: element });
            });
            // this.claimTypes = options;
            return [
                { label: 'Contract Refund', value: 'Revenue_Contract_Refund' }
            ];

        } else if (this.userRoleName == 'Railroad Revenue') {
            this.Freight = false;
            this.RevenueRailroad = true;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = false;
            this.claimdefaultSelectVal = 'Revenue_Railroad';
            let claimStatus = [];
            let modifiedLabel;
            this.label.RevenueRailroadclaimStatusOptions.split('|').forEach(element => {
                if (element.includes("On Hold") || element.includes("Re-Declined") || 
                element.includes("Re-Opened")) {
                modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                claimStatus.push({ label: modifiedLabel, value: element });                        
                console.log('inside if Pending review');
                } else {
                    console.log('inside else replace Pending review');
                    claimStatus.push({ label: element, value: element });
                }
            });
            this.statusOptions = claimStatus;
            this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
            let options = [];
            this.label.RevenueRailroadClaimTypeOptions.split('|').forEach(element => {
                options.push({ label: element, value: element });
            });
            // this.claimTypes = options;
            return [
                { label: 'Railroad Revenue', value: 'Revenue_Railroad' }
            ];
        } else if (this.userRoleName == 'Overcharge') {
            this.Freight = false;
            this.RevenueRailroad = false;
            this.invoiceButton = false;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = true;
            this.claimdefaultSelectVal = 'Revenue_Overcharge';
            let claimStatus = [];
            let modifiedLabel;
            this.label.RevenueOverchargeclaimStatusOptions.split('|').forEach(element => {
                if (element.includes("On Hold") || element.includes("Re-Declined") || 
                    element.includes("Re-Opened")) {
                    modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                    claimStatus.push({ label: modifiedLabel, value: element });                        
                    console.log('inside if Pending review');
                } else {
                    console.log('inside else replace Pending review');
                    claimStatus.push({ label: element, value: element });
                }
            });
            this.statusOptions = claimStatus;
            this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
            let options = [];
            this.label.RevenueOverchargeClaimTypeOptions.split('|').forEach(element => {
                options.push({ label: element, value: element });
            });
            // this.claimTypes = options;
            return [
                { label: 'Overcharge', value: 'Revenue_Overcharge' }
            ];
        }
    }
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT }) caseInfo;
    get recordTypeId() {
        if (this.caseInfo.data) {
            const rtis = this.caseInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(
                rti => rtis[rti].name === this.claimval
            );
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$recordTypeId' })
    claimPriorityValues({ data, error }) {
        if (data)
            this.claimPriorityOptions = data.picklistFieldValues.Priority.values;
        else {
            console.log(error);
        }
    }
    @track claimData = {
        'claimNumber': '',
        'claimType': '',
        'deskName': '',
        'unreadEmail': '',
        'claimPriority': '',
        'statusValues': '',
        'claimFromDate': '',
        'claimToDate': '',
        'ageFrom': '',
        'ageTo': '',
        'assignedTo': '',
        'claimAmountFrom': '',
        'claimAmountTo': '',
        'supplierClaimantName': '',
        'customerName': '',
        'potentialDuplicate': '',
        'claimGroup': ''
    }
    get UnreadEmailOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }
    /*get potentialDuplicateOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }*/

    handleInputChange(event) {
        try {
            this.claimData[event.target.name] = event.target.value;
            this.claimData.claimGroup = this.claimdefaultSelectVal;
            let ageFromId = this.template.querySelector('[data-id="ageFrom"]');
            let ageToId = this.template.querySelector('[data-id="ageTo"]');
            let claimAmountFromData = this.template.querySelector('[data-id="claimAmountFrom"]');
            let claimAmountToData = this.template.querySelector('[data-id="claimAmounTo"]');
            let searchQuerySelectorString = '';
            if (this.claimdefaultSelectVal === 'Freight') {
                searchQuerySelectorString = 'c-csx_cmp_claim-search-freight';
                this.template.querySelector(searchQuerySelectorString).claimInfoMapParentData = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Railroad') {
                searchQuerySelectorString = 'c-csx_cmp_claim-search-rev-r-r';
                this.template.querySelector(searchQuerySelectorString).claimInfoMapParentDataRR = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Overcharge') {
                searchQuerySelectorString = 'c-csx_cmp_claim-search-rev-overcharge';
                this.template.querySelector(searchQuerySelectorString).claimInfoMapParentDataO = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Contract_Refund') {
                searchQuerySelectorString = 'c-csx_cmp_claim-search-rev-contract';
                this.template.querySelector(searchQuerySelectorString).claimInfoMapParentDataRevCon = this.claimData;
            }
            this.template.querySelector(searchQuerySelectorString).disableSearchButton = false;
            this.template.querySelector(searchQuerySelectorString).disableResetButton = false;
            if (this.claimData.ageFrom == null || this.claimData.ageFrom == "") {
                this.claimData.ageTo = '';
                ageFromId.value = '';
                ageFromId.setCustomValidity("");
            } else {
                let dateValue = ageFromId.value;
                this.inputStartDate = dateValue;
                let ageTodata = ageToId.value;
                this.inputToDate = ageTodata;
                ageFromId.setCustomValidity("");
                this.errorReport = false;
                if (this.claimData.ageTo) {
                    if (parseFloat(this.claimData.ageTo) < parseFloat(this.claimData.ageFrom)) {
                        ageToId.setCustomValidity(this.label.ageCriteria);
                        this.errorReport = true;
                        this.validationCheck = true;
                        this.template.querySelector('c-csx_cmp_claim-search-freight').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = true;
                        console.log('to age must be greater then from date: ' + this.label.ageCriteria);
                    } else {
                        ageToId.setCustomValidity("");
                        ageToId.reportValidity();
                        this.template.querySelector('c-csx_cmp_claim-search-freight').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = false;

                    }
                }
                ageToId.reportValidity();
            }
            this.claimAmountFromData = parseFloat(claimAmountFromData.value);
            this.claimAmountToData = parseFloat(claimAmountToData.value);
            if (this.claimAmountToData) {
                if (this.claimAmountFromData > this.claimAmountToData) {
                    claimAmountToData.setCustomValidity(this.label.claimAmountCriteria);
                    this.validationCheck = true;
                    this.template.querySelector('c-csx_cmp_claim-search-freight').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = true;
                } else {
                    claimAmountToData.setCustomValidity('');
                    this.template.querySelector('c-csx_cmp_claim-search-freight').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = false;

                }
                claimAmountToData.reportValidity();
            }
            if (this.claimData.claimFromDate) {
                this.startDateValue = this.claimData.claimFromDate
                let inputDate = this.template.querySelector('[data-id="Start_Date"]');
                let inputEndDate = this.template.querySelector('[data-id="End_Date"]');
                if (this.startDateValue == null || this.startDateValue == "") {
                    this.endDate = '';
                    inputDate.value = '';
                    this.showEndDate = true;
                    inputDate.setCustomValidity("");
                } else {
                    let dateValue = inputDate.value;
                    let inputDateValue = new Date(dateValue);
                    this.inputStartDate = inputDateValue;
                    let today = new Date();
                    if (this.inputStartDate && inputDateValue > today) {
                        inputDate.setCustomValidity(this.label.futureDate);
                        this.validationCheck = true;
                        this.endDate = '';
                        this.template.querySelector('[data-id="End_Date"]').value = '';
                        this.showEndDate = false;
                        this.errorReport = true;
                        this.template.querySelector('c-csx_cmp_claim-search-freight').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = true;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = true;

                    } else {

                        inputDate.setCustomValidity("");
                        this.showEndDate = false;
                        this.errorReport = false;
                        this.template.querySelector('c-csx_cmp_claim-search-freight').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = false;
                        this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = false;
                        if (this.endDate) {
                            let endDateValue = new Date(this.endDate);
                            if (this.endDate && endDateValue < this.inputStartDate) {
                                inputDate.setCustomValidity(this.label.dateCriteria);
                                this.errorReport = true;
                                this.validationCheck = true;
                                this.template.querySelector('c-csx_cmp_claim-search-freight').validation = true;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = true;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = true;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = true;
                            } else {

                                inputEndDate.setCustomValidity("");
                                inputEndDate.reportValidity();
                                this.errorReport = false;
                                this.template.querySelector('c-csx_cmp_claim-search-freight').validation = false;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = false;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = false;
                                this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = false;
                            }
                        }
                    }
                    inputDate.reportValidity();
                }
            }
            if (this.claimData.claimToDate) {
                let inputEndDate = this.template.querySelector('[data-id="End_Date"]');
                let inputDate = this.template.querySelector('[data-id="Start_Date"]');
                this.endDateValue = this.claimData.claimToDate;
                let dateValue = inputEndDate.value;
                let inputDateValue = new Date(dateValue);
                this.inputDate = new Date(inputDate.value);
                this.inputEndDate = new Date(inputEndDate.value);
                if (this.inputEndDate && inputDateValue < this.inputDate) {
                    inputEndDate.setCustomValidity(this.label.dateCriteria);
                    this.validationCheck = true;
                    this.errorReport = true;
                    this.template.querySelector('c-csx_cmp_claim-search-freight').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = true;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = true;
                } else {
                    inputEndDate.setCustomValidity("");
                    inputDate.reportValidity();
                    inputEndDate.reportValidity();
                    this.errorReport = false;
                    this.template.querySelector('c-csx_cmp_claim-search-freight').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').validation = false;
                    this.template.querySelector('c-csx_cmp_claim-search-rev-contract').validation = false;
                }
                inputEndDate.reportValidity();
            }
        }
        catch (ex) {
            let parameters = this.claimData;
            csx_cmp_logError('csx_cmp_claimSearch', 'handleInputChange', ex, parameters);
        }
    }

    handleInvoices() {
        this.isLoaded = false;
        this.claimSelectedIds = [];
        this.invoiceRecordToDisplay = [];
        this.searchresultInvoice = false;
        this.showInspectionPaginator = true;
        console.log('inside 436');
        if ((JSON.stringify(this.invoiceWrapper) == '[]')) {
            console.log('inside !(JSON.stringify(this.invoiceWrapper) 438 != ');
            this.showInvoice = false;
            this.isLoaded = true;
            this.showInsDetailExport = true;
            this.showInspectionPaginator = false;
            this.modalOpen = false;
            const selectionHeaderIssue = new ShowToastEvent({
                message: this.label.claimSelection,
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.modalCall = false;
        }
        console.log('inside 452 != ' + JSON.stringify(this.invoiceWrapper));
        if ((!(JSON.stringify(this.claimTypeCheck).includes('Railroad Netting REV Claim'))) && JSON.stringify(this.claimTypeCheck) != '[]') {
            console.log('inside If !(JSON.stringify(this.claimTypeCheck) 453 ');
            this.showInvoice = false;
            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Please select claims with the type Railroad Netting REV Claim',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
        }
        if (((JSON.stringify(this.claimTypeCheck).includes('Railroad Netting REV Claim'))) && JSON.stringify(this.invoiceWrapper) == '[]') {
            this.showInvoice = false;
            this.isLoaded = true;
            this.showInsDetailExport = true;
            this.showInspectionPaginator = false;
            this.modalOpen = false;
            this.showInvoice = false;
            const selectionHeaderIssue = new ShowToastEvent({
                message: this.label.noInvoiceFound,
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.modalCall = false;
        }
        if (((JSON.stringify(this.claimTypeCheck).includes('Railroad Netting REV Claim'))) && JSON.stringify(this.claimTypeCheck) != '[]' && JSON.stringify(this.invoiceWrapper) != '[]') {
            console.log('inside some have of data Railroad Netting REV Claim');
            if (Object.keys(this.invoiceWrapper).length === 0) {
                this.showInvoice = false;
                const selectionHeaderIssue = new ShowToastEvent({
                    message: this.label.noInvoiceFound,
                    duration: '5000',
                    variant: 'error',
                });
                this.dispatchEvent(selectionHeaderIssue);
            }
            else {
                this.showInvoice = true;
            }
            this.modalOpen = true;
            let tempRecs = [];
            this.searchresultInvoice = true;
            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD'
            });
            this.invoiceWrapper.forEach((record) => {
                for (let i = 0; i < record.length; i++) {
                    let tempRec = Object.assign({}, record[i]);
                    tempRec.invoiceURL = '/' + tempRec.invoiceURL;
                    tempRec.claimURL = '/' + tempRec.claimURL;
                    tempRec.amountPaid = formatter.format(tempRec.amountPaid);
                    tempRec.invoiceAmount = formatter.format(tempRec.invoiceAmount);
                    tempRecs.push(tempRec);
                }
                this.isLoaded = true;
                this.showInvoice = true;
            });
            this.isLoaded = true;
            this.invoiceRecordToDisplay = tempRecs;
        }
        console.log('inside 474 != ');
        if (!(this.freightClaimTypeCheck.some(item => this.fcTypes.includes(item))) && (JSON.stringify(this.freightClaimTypeCheck) != '[]')) {
            this.showInvoice = false;
            console.log('inside If freightClaimTypeChec ');
            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Invoices are not applicable for this claim type',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
        }
        else {
            console.log('inside else: last 479');
            if (JSON.stringify(this.invoiceWrapper) != '[]') {
                this.showInsDetailExport = false;
                if (Object.keys(this.invoiceWrapper).length === 0) {
                    this.showInvoice = false;
                    const selectionHeaderIssue = new ShowToastEvent({
                        message: this.label.noInvoiceFound,
                        duration: '5000',
                        variant: 'error',
                    });
                    this.dispatchEvent(selectionHeaderIssue);
                }
                else {
                    this.showInvoice = true;
                }
                this.modalOpen = true;
                let tempRecs = [];
                this.searchresultInvoice = true;
                const formatter = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                });
                this.invoiceWrapper.forEach((record) => {
                    for (let i = 0; i < record.length; i++) {
                        let tempRec = Object.assign({}, record[i]);
                        tempRec.invoiceURL = '/' + tempRec.invoiceURL;
                        tempRec.claimURL = '/' + tempRec.claimURL;
                        tempRec.amountPaid = formatter.format(tempRec.amountPaid);
                        tempRec.invoiceAmount = formatter.format(tempRec.invoiceAmount);
                        tempRecs.push(tempRec);
                    }
                    this.isLoaded = true;
                    this.showInvoice = true;
                });
                this.isLoaded = true;
                this.invoiceRecordToDisplay = tempRecs;
                console.log('inside 515');
            }
            else {
                console.log('inside 518');
                this.showInvoice = false;
                this.isLoaded = true;
                this.showInsDetailExport = true;
                this.showInspectionPaginator = false;
                this.modalOpen = false;
                const selectionHeaderIssue = new ShowToastEvent({
                    message: this.label.claimSelection,
                    duration: '5000',
                    variant: 'error',
                });
                this.dispatchEvent(selectionHeaderIssue);
                this.modalCall = false;
            }
            console.log('inside 532');
        }
        console.log('inside 534');
    }

    handlePayments() {
        this.paginatorValue = false;
        this.claimSelectedIds = [];
        this.isLoaded = false;
        this.showPayment = false;
        this.paymentRecordToDisplay = [];
        this.searchresultPayment = false;

        try {
            if (JSON.stringify(this.paymentWrapper) != '[]') {
                this.showInsDetailExport = false;
                if (Object.keys(this.paymentWrapper).length === 0) {
                    this.showPayment = false;
                    const selectionHeaderIssue = new ShowToastEvent({
                        message: this.label.noPaymentsFound,
                        duration: '5000',
                        variant: 'error',
                    });
                    this.dispatchEvent(selectionHeaderIssue);
                }
                else {
                    this.showPayment = true;
                }
                this.modalOpen = true;
                let tempRecs = [];
                this.showInspectionPaginator = true;
                const formatter = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                });
                this.paymentWrapper.forEach((record) => {
                    for (let i = 0; i < record.length; i++) {
                        let tempRec = Object.assign({}, record[i]);
                        tempRec.paymentURL = '/' + tempRec.paymentURL;
                        tempRec.claimURL = '/' + tempRec.claimURL;
                        tempRec.amountPaid = formatter.format(tempRec.amountPaid);
                        tempRec.checkAmount = formatter.format(tempRec.checkAmount);
                        tempRecs.push(tempRec);
                        this.searchresultPayment = true;
                    }
                });
                this.paginatorValue = true;
                this.isLoaded = true;
                this.paymentRecordToDisplay = tempRecs;
            }
            else {
                this.showPayment = false;
                this.showInsDetailExport = true;
                this.showInspectionPaginator = false;
                this.modalOpen = false;
                const selectionHeaderIssue = new ShowToastEvent({
                    message: this.label.claimSelection,
                    duration: '5000',
                    variant: 'error',
                });
                this.dispatchEvent(selectionHeaderIssue);
                this.modalCall = false;
                this.isLoaded = true;
            }
        }
        catch (error) {
            let parameters = this.paymentWrapper;
            csx_cmp_logError('csx_cmp_claimSearch', 'handlePayments', error, parameters);
            this.paginationRecords = [];
        }
    }
    handlePaymentRecordsDisplay(event) {
        this.detailPaginatorRecords = event.detail;
        this.isSpinner = true;
    }
    handleInvoiceRecordsDisplay(event) {
        this.invoicePaginatorRecords = event.detail;
        this.isSpinner = true;
    }
    handleStatusValueChange(event) {
        this.claimData[event.target.name] = event.detail.values;
        this.claimData.claimGroup = this.claimdefaultSelectVal;
        let claimTypes;
        if (this.claimdefaultSelectVal === 'Freight') {
            claimTypes = 'c-csx_cmp_claim-search-freight';
            this.template.querySelector(claimTypes).claimInfoMapParentData = this.claimData;
        }
        if (this.claimdefaultSelectVal === 'Revenue_Railroad') {
            claimTypes = 'c-csx_cmp_claim-search-rev-r-r';
            this.template.querySelector(claimTypes).claimInfoMapParentDataRR = this.claimData;
        }
        if (this.claimdefaultSelectVal === 'Revenue_Overcharge') {
            claimTypes = 'c-csx_cmp_claim-search-rev-overcharge';
            this.template.querySelector(claimTypes).claimInfoMapParentDataO = this.claimData;
        }
        if (this.claimdefaultSelectVal === 'Revenue_Contract_Refund') {
            claimTypes = 'c-csx_cmp_claim-search-rev-contract';
            this.template.querySelector(claimTypes).claimInfoMapParentDataRevCon = this.claimData;
        }
        this.template.querySelector(claimTypes).disableSearchButton = false;
        this.template.querySelector(claimTypes).disableResetButton = false;
    }

    openModal() {
        const callOpenModel = new CustomEvent('openmodal');
        this.dispatchEvent(callOpenModel);
    }
    handleResetValues(event) {
        if (event.detail === 'reset') {
            this.reset();
        }
    }
    handlePayment(event) {
        const paymentData = event.detail;
        this.paymentWrapper = paymentData;
    }
    handleClaimType(event) {
        const claimType = event.detail;
        this.claimTypeCheck = claimType;
    }
    handleFreightClaimType(event) {
        const claimType = event.detail;
        this.freightClaimTypeCheck = claimType;
    }

    handleInvoice(event) {
        const invoiceData = event.detail;
        this.invoiceWrapper = invoiceData;
    }
    handleDisplayOfButton(event) {
        const buttonStatus = event.detail;
        this.showDetailButton = buttonStatus;
        this.showInvoice = false;
        this.showPayment = false;
    }

    handlerSearchValue(event) {
        if (event.detail === 'search') {
            this.claimData.claimGroup = this.claimdefaultSelectVal;
            if (this.claimdefaultSelectVal === 'Freight') {
                this.template.querySelector('c-csx_cmp_claim-search-freight').claimInfoMapParentData = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Railroad') {
                this.template.querySelector('c-csx_cmp_claim-search-rev-r-r').claimInfoMapParentDataRR = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Overcharge') {
                this.template.querySelector('c-csx_cmp_claim-search-rev-overcharge').claimInfoMapParentDataO = this.claimData;
            }
            if (this.claimdefaultSelectVal === 'Revenue_Contract_Refund') {
                this.template.querySelector('c-csx_cmp_claim-search-rev-contract').claimInfoMapParentDataRevCon = this.claimData;
            }
        }
    }


    reset() {
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clearSelectedValues();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clear();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').options = this.statusOptions;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.value = '';
        });
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.setCustomValidity('');
            element.classList.remove('highlight');
            element.reportValidity();
        });
        this.claimData = {
            'claimNumber': '',
            'claimType': '',
            'deskName': '',
            'unreadEmail': '',
            'claimPriority': '',
            'statusValues': '',
            'claimFromDate': '',
            'claimToDate': '',
            'ageFrom': '',
            'ageTo': '',
            'assignedTo': '',
            'claimAmountFrom': '',
            'claimAmountTo': '',
            'supplierClaimantName': '',
            'customerName': '',
            'potentialDuplicate': '',
            'claimGroup': ''
        }
        this.showDetailButton = false;
        this.openExcelComponent = false;
        this.openExcelComponentPayment = false;
        this.openExcelComponentInvoice = false;
        this.librariesLoadedPayment = false;
        this.librariesLoadedInvoice = false;
        this.invoiceRecordToDisplay = [];
        this.paymentRecordToDisplay = [];
        this.workSheetNameListPayment = [];
        this.workSheetNameListInvoice = [];
        this.xlsDataPayment = [];
        this.xlsDataInvoice = [];
        this.xlsHeaderInvoice = [];
        this.showPayment = false;
        this.showInvoice = false;
        this.claimTypeCheck = [];
    }

    handleEnter(event) {
        if (this.claimdefaultSelectVal == 'Freight') {
            if (event.keyCode === 13) {
                console.log('inside handleEnter: ');
                this.template.querySelector("c-csx_cmp_claim-search-freight").handleSearchClaim();
            }
        }
        if (this.claimdefaultSelectVal == 'Revenue_Railroad') {
            if (event.keyCode === 13) {
                this.template.querySelector("c-csx_cmp_claim-search-rev-r-r").handleSearchClaim();
            }
        }
        if (this.claimdefaultSelectVal =='Revenue_Contract_Refund') {
            if (event.keyCode === 13) {
                this.template.querySelector("c-csx_cmp_claim-search-rev-contract").handleSearchClaim();
            }
        }
        if (this.claimdefaultSelectVal == 'Revenue_Overcharge') {
            if (event.keyCode === 13) {
                this.template.querySelector("c-csx_cmp_claim-search-rev-overcharge").handleSearchClaim();
            }
        }
    }

    handleClaimSelection(event) {
        this.claimdefaultSelectVal = event.detail.value;
        this.claimData.claimGroup = this.claimdefaultSelectVal;
        this.showDetailButton = false;
        let statusCustomLabelValue = '';
        let claimTypeCustomLabelValue = '';
        let typeOptions = [];
        let claimStatus = [];
        this.isLoaded = true;
        this.showInsDetailExport = true;
        this.showInspectionPaginator = false;
        this.modalOpen = false;
        this.modalCall = false;
        this.showInvoice = false;
        this.showPayment = false;
        this.paginatorValue = false;
        this.claimSelectedIds = [];
        this.paymentRecordToDisplay = [];
        this.searchresultPayment = false;
        this.invoiceRecordToDisplay = [];
        this.searchresultInvoice = false;
        this.claimData = {
            'claimNumber': '',
            'claimType': '',
            'deskName': '',
            'unreadEmail': '',
            'claimPriority': '',
            'statusValues': '',
            'ageFrom': '',
            'ageTo': '',
            'assignedTo': '',
            'claimAmountFrom': '',
            'claimAmountTo': '',
            'supplierClaimantName': '',
            'customerName': '',
            'potentialDuplicate': '',
            'claimGroup': ''
        }
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clearSelectedValues();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clear();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').options = this.statusOptions;
        let newDateOptions = { year: "numeric", month: "2-digit", day: "2-digit" };
        let today = new Date();
        let curyear = today.getFullYear();
        let curyearMonth = today.getMonth() + 1;
        let curyearDay = today.getDate();
        let lastYear = curyear - 1;
        if ((curyearMonth == 2) && (curyearDay == 29)) {
            curyearDay = 28;
        }
        let lastYearDisplay = ("0000" + lastYear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        let todayy = ("0000" + curyear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        this.claimData.claimFromDate = lastYearDisplay.toLocaleString("en-US", newDateOptions);
        this.claimData.claimToDate = todayy.toLocaleString("en-US", newDateOptions);

        if (this.claimdefaultSelectVal === 'Freight') {
            this.invoiceButton = true;
            this.Freight = true;
            this.RevenueRailroad = false;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = false
            this.claimTypeCheck = [];

            statusCustomLabelValue = this.label.FreightclaimStatusOptions;
            claimTypeCustomLabelValue = this.label.FreightClaimTypeOptions;

        }
        if (this.claimdefaultSelectVal === 'Revenue_Railroad') {
            this.invoiceButton = true;
            this.Freight = false;
            this.RevenueRailroad = true;
            this.RevenueContractRefunds = false;
            this.RevenueOvercharge = false;
            this.freightClaimTypeCheck = [];
            statusCustomLabelValue = this.label.RevenueRailroadclaimStatusOptions;
            claimTypeCustomLabelValue = this.label.RevenueRailroadClaimTypeOptions;
        }
        if (this.claimdefaultSelectVal === 'Revenue_Contract_Refund') {
            this.invoiceButton = false;
            this.RevenueContractRefunds = true;
            this.Freight = false;
            this.RevenueRailroad = false;
            this.RevenueOvercharge = false
            this.claimTypeCheck = [];
            this.freightClaimTypeCheck = [];
            statusCustomLabelValue = this.label.RevenueContractRefundclaimStatusOptions;
            claimTypeCustomLabelValue = this.label.RevenueContractClaimTypeOptions;
        }
        if (this.claimdefaultSelectVal === 'Revenue_Overcharge') {
            console.log(' inside this.claimdefaultSelectVal' + this.claimdefaultSelectVal);
            this.invoiceButton = false;
            this.RevenueContractRefunds = false;
            this.Freight = false;
            this.RevenueRailroad = false;
            this.RevenueOvercharge = true;
            this.claimTypeCheck = [];
            this.freightClaimTypeCheck = [];
            statusCustomLabelValue = this.label.RevenueOverchargeclaimStatusOptions;
            claimTypeCustomLabelValue = this.label.RevenueOverchargeClaimTypeOptions;
        }
        claimTypeCustomLabelValue.split('|').forEach(element => {
            typeOptions.push({ label: element, value: element });
        });
        let modifiedLabel;;
        // this.claimTypes = typeOptions;
        statusCustomLabelValue.split('|').forEach(element => {
            if (element.includes("On Hold") || element.includes("Re-Declined") || 
                    element.includes("Re-Opened")) {
                    modifiedLabel = element.replace(/(\w+)\s+(\w+)/, '$1-$2');
                    claimStatus.push({ label: modifiedLabel, value: element });                        
                    console.log('inside if Pending review');
            } else {
                console.log('inside else replace Pending review');
                claimStatus.push({ label: element, value: element });
            }
        });
        this.statusOptions = claimStatus.sort((a, b) => a.label.localeCompare(b.label))
        this.statusOptions = claimStatus;
    }

    donwnloadPaymentRecord() {
        try {
            this.openExcelComponent = false;
            this.openExcelComponentInvoice = false;
            this.openExcelComponentPayment = true;
            if (this.librariesLoadedPayment) {
                this.getPaymentExport();
            }
        } catch (ex) {
            csx_cmp_logError('csx_cmp_claimSearch', 'handleInputChange', ex, '');
        }
    }

    excelLibraryLoadedPayment() {
        this.librariesLoadedPayment = true;
        this.getPaymentExport();
    }

    getPaymentExport() {
        try {
            let listForExportPaymnet = this.paymentRecordToDisplay.map(function (obj) {
                let tmp = {};
                tmp["Settlement #"] = obj.paymentID;
                tmp["Claim #"] = obj.claimID;
                tmp["Claim Amount Paid"] = obj.amountPaid;
                tmp["Check #"] = obj.checkNumber;
                tmp["Check Date"] = obj.checkDate;
                tmp["Check Amount"] = obj.checkAmount;
                tmp["Payment Method"] = obj.paymentMethod;
                tmp["Payment Address"] = obj.paymentAddress;
                tmp["Payment Status"] = obj.paymentStatus;
                tmp["Bank Account"] = obj.bankAccount;
                return tmp;
            });
            this.xlsFormatterPayment(listForExportPaymnet, "Payment Data");
        } catch (error) {
            let parameters = JSON.stringify(this.paymentRecordToDisplay);
            csx_cmp_logError('csx_cmp_claimSearch', 'getPaymentExport', error, parameters);
        }
    }
    xlsFormatterPayment(data, sheetName) {
        try {
            let Header = Object.keys(data[0]);
            this.xlsHeaderPayment.push(Header);
            this.workSheetNameListPayment.push(sheetName);
            this.xlsDataPayment.push(data);
            this.template.querySelector("c-csx_cmp_excelexport").download();
            this.xlsHeaderPayment = [];
            this.workSheetNameListPayment = [];
            this.xlsDataPayment = [];
        } catch (error) {
            let parameters = JSON.stringify('xlsFormatterPayment:' + this.xlsFormatterPayment);
            csx_cmp_logError('csx_cmp_InspectionSearch', 'xlsFormatterPayment', error, parameters);
        }
    }
    donwnloadInvoiceRecord() {
        this.openExcelComponentInvoice = true;
        this.openExcelComponent = false;
        this.openExcelComponentPayment = false;
        if (this.librariesLoadedInvoice) {
            this.getInvoiceExport();
        }
    }
    excelLibraryLoadedInvoice() {
        this.librariesLoadedInvoice = true;
        this.getInvoiceExport();
    }
    getInvoiceExport() {
        try {
            let listForExportInvoice = this.invoiceRecordToDisplay.map(function (obj) {
                let tmp = {};
                tmp["Settlement #"] = obj.invoiceID;
                tmp["Claim #"] = obj.claimID;
                tmp["Claim Amount Paid"] = obj.amountPaid;
                tmp["Invoice #"] = obj.invoiceNumber;
                tmp["Invoice Date"] = obj.invoiceDate;
                tmp["Invoice Amount"] = obj.invoiceAmount;
                tmp["Invoice Status"] = obj.invoicePaymentStatus;
                tmp["Payment Address"] = obj.paymentAddress;
                tmp["Bank Account"] = obj.bankAccount;
                return tmp;
            });
            this.xlsFormatterInvoice(listForExportInvoice, "InvoiceData");
        } catch (error) {
            let parameters = JSON.stringify(this.records);
            csx_cmp_logError('csx_cmp_claimSearch', 'getInvoiceExport', error, parameters);
        }
    }
    xlsFormatterInvoice(data, sheetName) {
        let Header = Object.keys(data[0]);
        this.xlsHeaderInvoice.push(Header);
        this.workSheetNameListInvoice.push(sheetName);
        this.xlsDataInvoice.push(data);
        this.template.querySelector("c-csx_cmp_excelexport").download();
        this.xlsHeaderInvoice = [];
        this.workSheetNameListInvoice = [];
        this.xlsDataInvoice = [];
    }
    doSortingPayment(event) {

        let sortbyField = event.detail.fieldName;
        if (sortbyField === "paymentURL") {
            this.sortByPayment = "paymentID";
        }
        else {
            this.sortByPayment = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortDataPayment(this.sortByPayment, this.sortDirection);
        this.sortByPayment = sortbyField;
    }
    sortDataPayment(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.paymentRecordToDisplay);
        this.paymentRecordToDisplay = sortResult.sort(function (a, b) {
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
        if (this.searchresultPayment) {
            this.searchresultPayment = false;
        } else {
            this.searchresultPayment = true;
        }
    }
    doSortingInvoice(event) {

        let sortbyField = event.detail.fieldName;
        if (sortbyField === "invoiceURL") {
            this.sortByInvoice = "invoiceID";
        }
        else {
            this.sortByInvoice = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortDataInvoice(this.sortByInvoice, this.sortDirection);
        this.sortByInvoice = sortbyField;
    }
    sortDataInvoice(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.invoiceRecordToDisplay);
        this.invoiceRecordToDisplay = sortResult.sort(function (a, b) {
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
        if (this.searchresultInvoice) {
            this.searchresultInvoice = false;
        } else {
            this.searchresultInvoice = true;
        }
    }
}