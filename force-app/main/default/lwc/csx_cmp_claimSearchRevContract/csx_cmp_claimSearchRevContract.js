import { LightningElement, api, track} from 'lwc';
import fetchClaims from '@salesforce/apex/CSX_CMP_ClaimSearchController.getClaimRecords';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SearchCriteriaToast from '@salesforce/label/c.CSX_CMP_SearchCriteriaToast_Label';
import noPaymentsFound from '@salesforce/label/c.CSX_CMP_No_Payments_Found';
import noInvoiceFound from '@salesforce/label/c.CSX_CMP_No_Invoice_Found';
import claimSelection from '@salesforce/label/c.CSX_CMP_Selection_Option_For_ClaimSearch';
import recordSizeLimit from '@salesforce/label/c.CSX_CMP_RecordLimit_Warning';
import searchDataLimit from '@salesforce/label/c.CSX_CMP_SearchDataLimit';

export default class Csx_cmp_claimSearchRevContract extends LightningElement {

    label = {
        noPaymentsFound,
        noInvoiceFound,
        claimSelection,
        SearchCriteriaToast,
        recordSizeLimit,
        searchDataLimit
    };
    @track revContract = {
        'nationalAccNum': '',
        'contractNumber': '',
        'claimantSiteRevContract': '',
    }
    @track paymentWrapper=[];
    @track recordsToDisplay = [];
    @track records = [];
    @api disableSearchButton = false;
    @api disableResetButton = false;
    @api claimInfoMapParentDataRevCon={};
    @api validation=false;
    sortByDetail='claimNumber';
    openExcelComponent = false;
    librariesLoaded = false;
    isLoaded=true;
    shownoRecordError = false;
    searchResults = false;
    showTable = false;
    claimRecordslength;
    showDetailButton = false
    workSheetNameList = [];
    excelFileName = 'ClaimSearchResults.xlsx';
    sortDirection = 'asc';
    xlsData = [];
    xlsHeader = []; 
    
    columns = [
        {label: "Claim Number", fieldName: 'caseId',  type: 'url', typeAttributes: { label: { fieldName:'claimNumber' },tooltip: 'Go to detail page',target: '_blank'}, sortable: "true", initialWidth: 147 },   
        {label: "Claim Date", fieldName: 'claimDate', hideDefaultActions: true, type: 'date',typeAttributes: {timeZone:'UTC',year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true" , initialWidth: 95},
        {label: "Desk", fieldName: 'deskName', hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 85},
        {label: "Assigned To", fieldName: 'assignedTo', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 132 },
        {label: 'Age', fieldName:'claimAge',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 60},
        {label: 'Claim Amount',fieldName:'claimAmount',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 116},
        {label: 'Claim Type',fieldName: 'claimType',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 163},
        {label: 'Claim Status',fieldName: 'claimStatus',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 190},
        {label: 'Claim Reason',fieldName: 'claimReason',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 130},
        {label: 'Customer/Railroad Name',fieldName: 'customerName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 205},
        {label: 'National Account#',fieldName: 'nationalAccountNumber',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Claimant Name',fieldName: 'supplierClaimantName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Claimant Site',fieldName: 'supplierClaimantSite',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Contract #',fieldName: 'contractNumber',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 135},    
        {label: 'CSX Explanation',fieldName: 'csxExplanationRevContract',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 145},
        {label: 'Work Note',fieldName: 'workNote',hideDefaultActions: true, type: 'text', wrapText: "true" , initialWidth: 145}
        ];
    buttonColumns=[
        { type: "button", label: 'View', initialWidth: 100, typeAttributes: { //later to remove modal view csxExplanationRevContract
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
    
    handleSelectedRows(event) { 
        this.rechargeClaimList = [];
        let selectedRows = event.detail.selectedRows;
        this.rechargeClaimList = selectedRows;
        this.paymentWrapper=[];
         selectedRows.forEach((record) => {
            let tempRec = Object.assign({}, record);
            this.paymentWrapper.push(tempRec.aPSettlements);
        });
        const paymentEvent= new CustomEvent('paymentchange', { detail: this.paymentWrapper, bubbles: true});
        this.dispatchEvent(paymentEvent);
    }
   
    handleInputChange(event) {
        this.revContract[event.target.name] = event.target.value;
        this.disableSearchButton = false;
        this.disableResetButton = false;
        // if(this.revContract.nationalAccNum){
        //     let nationalAccNumberData = this.revContract.nationalAccNum.toString(); 
        // }
    }

    handleEnter(event){
        if(event.keyCode === 13){
          this.handleSearchClaim();
        }
    }
    @api
    handleSearchClaim() {
        this.claimSelectedIds = [];
        this.isLoaded=false;
        this.records=[];
        this.claimRecordslength='';
        this.showTable=false;
        this.showDetailButton = false;
        this.dispatchEvent(new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true}));
        const searchValues= 'search';
        const selectEvent=new CustomEvent('searchchange',{detail:searchValues,bubbles:true});
        this.dispatchEvent(selectEvent);
        let claimInfoMap = new Map();
        //let claimStatus = this.revContract.claimStatus;
        this.shownoRecordError = false;
        claimInfoMap = Object.keys(this.revContract).reduce((map, key) => {

            if (this.revContract[key] && key != 'claimStatus') {
                map.set(key, this.revContract[key]);
            }
            return map;
        }
            , new Map());
        

        // let obj = Object.fromEntries(claimInfoMap);
        // let claimData = JSON.stringify(obj);

        let claimInfoMapParent = new Map();
        claimInfoMapParent = Object.keys(this.claimInfoMapParentDataRevCon).reduce((map, key) => {

        if (this.claimInfoMapParentDataRevCon[key]) {
            map.set(key, this.claimInfoMapParentDataRevCon[key]);
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

        if( claimDataStringCon != '{"claimGroup":"Revenue_Contract_Refund"}'){
          if(this.validation==false) {
            fetchClaims({claimSearchParameters:claimDataStringCon})
            .then(result => {
                if (result) {      
                    const formatter = new Intl.NumberFormat('en-US', {
                        style: 'currency',
                        currency: 'USD'
                      });       
                    let finalData= result.results;
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
                            tempRec.claimAmount=formatter.format(tempRec.claimAmount); 
                            tempRec.caseId='/'+ tempRec.caseId;
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
                let parameters = JSON.stringify(this.records);
                csx_cmp_logError('csx_cmp_claimSearch', 'handleSearchClaim', error, parameters);
            });
         } else{ 
             const selectionHeaderIssue = new ShowToastEvent({
            message: 'Please review error messages',
            duration: '5000',
            variant: 'warning'
        });
        this.dispatchEvent(selectionHeaderIssue);
        this.isLoaded = true;
        }
        }
        else{
            const selectionHeaderIssue = new ShowToastEvent({
                message: this.label.SearchCriteriaToast,
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }
    }
    handleClaimRecordsDisplay(event){
        this.recordsToDisplay= event.detail;
    }
    handleResetClick() {
        this.claimInfoMapParentDataRevCon = {};
        const resetValues= 'reset';
        const selectEvent=new CustomEvent('valuechangerevcontract',{detail:resetValues,bubbles:true});
        this.dispatchEvent(selectEvent);
        this.showTable=false;
        this.showTable=false;
        this.showDetailButton = false;
        this.deskName = null;
        this.claimStartDate = null;
        this.claimEndDate = null;
        this.disableResetButton = true;
        this.disableSearchButton = true;
        this.shownoRecordError = false;
        this.isLoaded=true;
        this.revContract = {
            'nationalAccNum': '',
            'contractNumber': '',
            'supplierClaimantSite': '',
        }
        let inputFields = this.template.querySelectorAll('lightning-input');
        if (inputFields) {
            inputFields.forEach(field => {
                field.value = '';
            });
        }
    }
    handleRowLinkClickSelection(event) {
        try{
            const ecmLinkForDocument = event.detail.row.ecmLink;
            const actionName = event.detail.action.name;
            const ecmLink=JSON.stringify(ecmLinkForDocument);
            if (actionName === 'DocumnetDetails') {
                if (ecmLink)  {
                    const externalURLWithParams = ecmLinkForDocument;
                    window.open(externalURLWithParams, '_blank');
                } else {
                    console.log('External URL is not defined.');
                }
            }
        }catch(error) {
            let parameters = '';
            csx_cmp_logError('csx_cmp_claimSearchRevContract', 'handleRowLinkClickSelection', error, parameters);
        }
    }
    downloadClaimData(){
        this.openExcelComponent=true;
        if(this.librariesLoaded){
            this.getClaimExport();
        }
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
                tmp["Contract #"] = obj.contractNumber;        
                tmp["ECM Link"]=obj.ecmLink;
                tmp["CSX Explanation"]=obj.csxExplanationRevContract; 
                tmp["Work Note"]=obj.workNote;       
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
    excelLibraryLoaded() {
        this.librariesLoaded = true;
        this.getClaimExport();
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
            a = a[fieldName] ? a[fieldName] : ''; // handling null values
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