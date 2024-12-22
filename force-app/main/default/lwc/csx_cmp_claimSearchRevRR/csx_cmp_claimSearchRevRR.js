import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import {csx_cmp_logError} from 'c/csx_cmp_logError';
import fetchClaims from '@salesforce/apex/CSX_CMP_ClaimSearchController.getClaimRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import noPaymentsFound from '@salesforce/label/c.CSX_CMP_No_Payments_Found';
import noInvoiceFound from '@salesforce/label/c.CSX_CMP_No_Invoice_Found';
import claimSelection from '@salesforce/label/c.CSX_CMP_Selection_Option_For_ClaimSearch';
import recordSizeLimit from '@salesforce/label/c.CSX_CMP_RecordLimit_Warning';
import searchDataLimit from '@salesforce/label/c.CSX_CMP_SearchDataLimit';

export default class Csx_cmp_claimSearchRevRR extends LightningElement {

    label = {
        noPaymentsFound,noInvoiceFound,claimSelection,recordSizeLimit,searchDataLimit
    };
   @track claimData= {
        'rrSCAC': '',
        'claimReason': '',
        'supplierClaimantSite': '',
        'servicePeriod':'',
        'equipmentInitial':'',
        'equipmentNumber':'',
        'waybillfromDate':'',
        'waybilltoDate':'',
        'waybill':'',
        'stcc':'',
        'customerSite':'',
        'freightBillNumberNumber':'',
        'urrwin':'',
        'nettingRef':'',
        'claimantAmountFrom':'',
        'claimantAmountTo':''
    }
    @track paymentWrapper=[];
    @track claimType=[];
    @track invoiceWrapper=[];
    @api claimInfoMapParentDataRR={};
    @api validation=false;
    @api disableSearchButton = false;
    @api disableResetButton = false;
    @track workSheetNameList = []; 
    @track xlsData = []; 
    @track xlsHeader = []; 
    @track recordsToDisplay = []; 
    @track records = [];
    @api claimval;
    excelFileName = 'ClaimSearchResults.xlsx';
    openExcelComponent=false;
    librariesLoaded=false;
    claimReasonOptions;
    searchResults = false;
    showTable = false;
    shownoRecordError = false;
    claimRecordslength
    claimantAmountFromData;
    claimantAmountToData;
    sortByDetail = 'caseId';
    showInvoice = false;
    isLoaded=true;
    searchresultPayment = false;
    showDetailButton = false
    showPayment = false;
    sortDirection = 'asc';
    equipInitial;
    equipNum;
    showNumError;

    columns = [
        {label: "Claim Number", fieldName: 'caseId',  type: 'url'  , typeAttributes: { label: { fieldName:'claimNumber' },tooltip: 'Go to detail page',target: '_blank'}, sortable: "true", initialWidth: 147 },   
        {label: "Claim Date", fieldName: 'claimDate', hideDefaultActions: true, type: 'date',typeAttributes: {timeZone:'UTC',year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true" , initialWidth: 95},
        {label: "Desk", fieldName: 'deskName', hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 85},
        {label: 'Age', fieldName:'claimAge',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 60},
        {label: 'Claim Amount',fieldName:'claimAmount',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 116},
        {label: 'Claim Type',fieldName: 'claimType',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 163},
        {label: 'Claim Status',fieldName: 'claimStatus',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 190},
        {label: 'Claim Reason',fieldName: 'claimReason',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 130},
        {label: 'Customer/Railroad Name',fieldName: 'customerName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 205},
        {label: 'National Account#',fieldName: 'nationalAccountNumber',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Claimant Name',fieldName: 'supplierClaimantName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Claimant Site',fieldName: 'supplierClaimantSite',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'RR SCAC',fieldName: 'rrSCAC',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 116},
        {label: 'Claimant Claim #',fieldName: 'claimantReferenceNumber',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Assigned To',fieldName: 'assignedTo',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 150},
        { label: "Netting Claim #", fieldName: 'claimNettingClaim', type: 'url', typeAttributes: { label: { fieldName: 'claimNettingClaimNum' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 150 },
        {label: 'Service Period',fieldName: 'servicePeriod',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 115},
        {label: 'CSX Explanation',fieldName: 'csxExplanation',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 145},
        {label: 'Work Note',fieldName: 'workNote',hideDefaultActions: true, type: 'text', wrapText: "true" , initialWidth: 145}
        ];

    buttonColumns = [
        { type: "button", label: 'View', initialWidth: 100, typeAttributes: {  
            label: 'Documents',
            name: 'DocumnetDetails',
            title: 'DocumnetDetails',
            disabled: false,
            value: 'view',
            iconPosition: 'right',
            iconName:'',
            variant:'slds-button_outline-brand'
            } 
        }
    ]

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT }) caseInfo;
    get recordTypeId() {
        if(this.caseInfo.data){
            const rtis = this.caseInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(
              rti => rtis[rti].name === 'Railroad Revenue'
            );
        }         
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    claimReaspnValues;

    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT ,recordTypeId: '$recordTypeId'})
    claimReasonValues({ data, error }) {
        if (data) {
            this.claimReasonOptions = data.picklistFieldValues.CSX_CMP_Claim_Reason__c.values;
        }
        
        if(error){
            console.log('error reason: '+error);
        }
    }
    
    handleEnter(event){
        if(event.keyCode === 13){
          this.handleSearchClaim();
        }
      }
    
    handleSelectedRows(event) {
        this.rechargeClaimList = [];
        let selectedRows = event.detail.selectedRows;
        this.rechargeClaimList = selectedRows;
        this.paymentWrapper=[];
        this.invoiceWrapper=[];
        this.claimType=[];
        selectedRows.forEach((record) => {
            let tempRec = Object.assign({}, record);
            this.paymentWrapper.push(tempRec.aPSettlements);
            this.invoiceWrapper.push(tempRec.aRSettlements);
            this.claimType.push(tempRec.claimType);
        });
        
        const paymentEvent= new CustomEvent('paymentchange', { detail: this.paymentWrapper, bubbles: true});
        this.dispatchEvent(paymentEvent);
        const invoiceEvent= new CustomEvent('invoicechange', { detail: this.invoiceWrapper, bubbles: true});
        this.dispatchEvent(invoiceEvent);
        const claimTypeEvent= new CustomEvent('typechange', { detail: this.claimType, bubbles: true});
        this.dispatchEvent(claimTypeEvent);
    }

    handleInputChange(event) {
        this.claimData[event.target.name] = event.target.value;
        this.disableSearchButton = false;
        this.disableResetButton = false; 
        let claimantAmountFromData=this.template.querySelector('[data-id="claimantAmountFrom"]');
        let claimantAmountToData=this.template.querySelector('[data-id="claimantAmountTo"]');
        this.claimantAmountFromData=parseFloat(claimantAmountFromData.value);
        this.claimantAmountToData=parseFloat(claimantAmountToData.value);
        let equipInitial = '';
        equipInitial=this.template.querySelector('[data-id="equipInitial"]');
        let equipNumber = this.template.querySelector('[data-id="equipNumber"]');
        this.equipInitial=equipInitial.value;
        this.equipNum=equipNumber.value;
        if(this.claimantAmountToData){
            if(this.claimantAmountFromData > this.claimantAmountToData){
                claimantAmountToData.setCustomValidity('To Claimant Amount must be greater then From Claimant Amount in order to search'); 
                this.validation=true;             
            }else{
                claimantAmountToData.setCustomValidity('');
                this.validation=false;
            }
            claimantAmountToData.reportValidity();
        }
        if (this.equipInitial && /[^a-zA-Z]/.test(this.equipInitial)) {
            equipInitial.setCustomValidity('Only alphabet characters are allowed.');
            this.validation=true;
        }
        if (event.key === 'Tab' && this.equipInitial=='') {
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity(); // Report the validity state
        }
        if (this.equipInitial=='' || this.equipInitial==undefined) {
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity(); // Report the validity state
        }
        else if(!(/[^a-zA-Z]/.test(this.equipInitial)) && this.equipInitial.length >= 2 ){
            console.log('inside clear()');
            equipInitial.setCustomValidity(''); // Clear any previous error message
            equipInitial.reportValidity();
            this.validation=false;
        }
        else if ( this.equipInitial.length < 2) {
            console.log('inside equipment length: inner'+this.equipInitial.length);
            equipInitial.setCustomValidity('At least 2 alphabet characters are required.');
            this.validation = true;
        }
         
        equipInitial.reportValidity();
        
        if(this.equipNum){
            if (!equipNumber.value || isNaN(equipNumber.value)) {
                this.showNumError = true;
                this.validation=true;
            } else {
                equipNumber.setCustomValidity(''); // Clear any previous error message
                this.showNumError = false;
                equipNumber.reportValidity();
                this.validation=false;
                // Proceed with your logic
            }
        } 
    }
    @api
    handleSearchClaim() {
        this.claimSelectedIds = [];
        this.isLoaded=false;   
        this.showInvoice=false;
        this.showPayment=false; 
        this.records=[];
        this.claimRecordslength='';
        this.showTable=false;
        this.shownoRecordError = false;
        this.showDetailButton = false;
        this.dispatchEvent(new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true}));
        const searchValues= 'search';
        const selectEvent=new CustomEvent('searchchange',{detail:searchValues,bubbles:true});
        this.dispatchEvent(selectEvent);

        let claimInfoMap = new Map();
        claimInfoMap = Object.keys(this.claimData).reduce((map, key) => {

            if (this.claimData[key]) {
                map.set(key, this.claimData[key]);
            }
            return map;
        }, new Map());

        let claimInfoMapParent = new Map();
        claimInfoMapParent = Object.keys(this.claimInfoMapParentDataRR).reduce((map, key) => {
            if (this.claimInfoMapParentDataRR[key]) {
                map.set(key, this.claimInfoMapParentDataRR[key]);
            }
            return map;
        }, new Map());

        let conResult = new Map([...claimInfoMap]);
        claimInfoMapParent.forEach((value, key) => {
            if (conResult.has(key)) {
                conResult.set(key, conResult.get(key) + value);
        } else {
            conResult.set(key, value);
            }
        });
        let obj2 = Object.fromEntries(conResult);
        let claimDataStringCon = JSON.stringify(obj2);

        if(claimDataStringCon != '{"claimGroup":"Revenue_Railroad"}'){
            if(this.validation==false){
            fetchClaims({claimSearchParameters:claimDataStringCon})
            .then(result => {
            if (result) {           
                const formatter = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD'
                  });
                 
                let finalData=result.results;
                this.claimRecordslength = finalData.length;
                if(this.claimRecordslength>=this.label.searchDataLimit){
                    const selectionHeaderIssue = new ShowToastEvent({
                        message: this.label.recordSizeLimit,
                        duration: '3000',
                        variant: 'warning',
                    });
                    this.dispatchEvent(selectionHeaderIssue);
                    this.isLoaded=true;
                    return;
                }
                if(finalData.length>0){
                    let tempRecs = [];
                    finalData.forEach( ( record ) => {
                        let tempRec = Object.assign( {}, record );  
                        tempRec.caseId='/'+ tempRec.caseId;
                        tempRec.claimAmount=formatter.format(tempRec.claimAmount);
                        if(tempRec.claimNettingClaim){
                            tempRec.claimNettingClaim='/'+ tempRec.claimNettingClaim;  
                        }      
                        tempRecs.push( tempRec );
                    });
                    this.records=tempRecs;
                    this.showTable=true;
                    this.searchResults = true;
                    this.showDetailButton = true;
                    this.isLoaded=true;
                    const paymentEvent= new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true});
                    this.dispatchEvent(paymentEvent);
                }
                else{
                    this.showTable=false;
                    this.searchResults = false;
                    this.showDetailButton = false;
                    this.shownoRecordError = true;
                    this.isLoaded=true;
                }
            }
            else{
                this.isLoaded=true;
                this.shownoRecordError = true;
            }
        })
        .catch(error => {
            let parameters = this.records;
            csx_cmp_logError('csx_cmp_claimSearch', 'handleSearchClaim', error, parameters);
        });
        }else{
            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Please review error messages',
                duration: '5000',
                variant: 'warning'
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }   
        }else{
            const selectionHeaderIssue = new ShowToastEvent({
                message:'Please enter atleast 1 search criteria',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }
    }
    handleRowLinkClickSelection(event) {
        let ecmLinkForDocument;
        try{
            ecmLinkForDocument = event.detail.row.ecmLink;
            const actionName = event.detail.action.name;
            const ecmLink=JSON.stringify(ecmLinkForDocument);
            if (actionName === 'DocumnetDetails') {
                if (ecmLink){
                    const externalURLWithParams = ecmLinkForDocument;
                    window.open(externalURLWithParams, '_blank');
                }
            }
        }catch(error) {
            let parameters = ecmLinkForDocument;
            csx_cmp_logError('csx_cmp_claimSearchRevRR', 'handleRowLinkClickSelection', error, parameters);
        }
    }
    handleResetClick(){
        const resetValues= 'reset';
        const selectEvent=new CustomEvent('valuechangerevrr',{detail:resetValues,bubbles:true});
        this.dispatchEvent(selectEvent);
        this.paymentWrapper=[];
        this.invoiceWrapper=[];
        this.claimInfoMapParentDataRR={};
        this.disableSearchButton = false;
        this.disableResetButton = false;
        this.ariaColSpanworkSheetNameList = []; 
        this.xlsData = []; 
        this.xlsHeader = []; 
        this.recordsToDisplay = []; 
        this.records = []; 
        this.claimval;
        this.showTable=false;
        this.isLoaded=true;
        this.shownoRecordError = false;
        this.disableSearchButton= true;
        this.disableResetButton = true;
        this.recordsToDisplay = [];
        this.showTable = false;
        this.searchResults = false;
        this.showDetailButton = false;
        this.showPayment = false;
        this.claimData= {
            'rrSCAC': '',
            'claimReason': '',
            'claimantSiteRevRR': '',
            'servicePeriod':'',
            'equipmentInitial':'',
            'equipmentNumber':'',
            'waybillfromDate':'',
            'waybilltoDate':'',
            'waybill':'',
            'stcc':'',
            'freightBillNumberNumber':'',
            'urrwin':'',
            'nettingRef':'',
            'customerSite':'',
            'claimantAmountFrom':'',
            'nettingClaimNumber':''
        }
    }

    handleClaimRecordsDisplay(event){
        this.recordsToDisplay= event.detail;
    }

    downloadClaimData(){
        this.openExcelComponent=true;
        if(this.librariesLoaded){
            this.getClaimExport();
        }
    }

    excelLibraryLoaded() {
        this.librariesLoaded = true;
        this.getClaimExport();
    }

    getClaimExport(){
        try {
            let listForExport=this.records.map(function(obj) {
                let tmp = {};
                tmp["Claim Number"] = obj.claimNumber;
                tmp["Claim Date"] = obj.claimDate;
                tmp["Desk"] = obj.deskName;
                tmp["Assigned To"] = obj.assignedTo;
                tmp["Age"] = obj.claimAge;
                tmp["Claim Amount"] = obj.claimAmount;
                tmp["Claim Type"] = obj.claimType;
                tmp["Claim Status"] = obj.claimStatus;
                tmp["Claim Reason"] = obj.claimReason;
                tmp["Customer/Railroad Name"] = obj.customerName;
                tmp["National Account#"] = obj.nationalAccountNumber;
                tmp["Claimant Name"] = obj.supplierClaimantName;
                tmp["Claimant Site"] = obj.supplierClaimantSite;
                tmp["RR SCAC"] = obj.rrSCAC;
                tmp["Claimant Claim #"] = obj.claimantReferenceNumber;
                tmp["Netting Claim#"] = obj.nettingClaimNumber;
                tmp["Service Period"] = obj.servicePeriod;
                tmp["CSX Explanation"] = obj.csxExplanation; 
                tmp["Work Note"] = obj.workNote;
                tmp["ECM Link"]=obj.ecmLink;  
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
}