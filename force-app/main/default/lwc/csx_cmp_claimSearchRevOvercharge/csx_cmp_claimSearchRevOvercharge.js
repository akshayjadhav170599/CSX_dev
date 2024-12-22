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

export default class Csx_cmp_claimSearchRevOvercharge extends LightningElement {
    label = {
        noPaymentsFound,
        noInvoiceFound,
        claimSelection,
        recordSizeLimit,
        searchDataLimit
    };
    @track paymentWrapper=[];
    @track recordsToDisplay = []; 
    @track records = []; 
    @api disableSearchButton = false;
    @api disableResetButton = false;
    @api claimInfoMapParentDataO={};
    @api validation=false;
    @api claimval;
    @track workSheetNameList = [];
    @track xlsData = []; 
    @track xlsHeader = [];
    sortByDetail='claimNumber';
    showPaginationComponent = false;
    openExcelComponent=false;
    librariesLoaded=false;
    claimReasonOptions;
    searchResults = false;
    showTable = false;
    claimNumber;
    claimRecordslength;
    shownoRecordError = false;
    showClaimDetail = false;
    excelFileName = 'ClaimSearchResults.xlsx';
    isLoaded=true;
    sortDirection = 'asc';
    showDetailButton = false;
    equipInitial;
    equipNum;

    @track revOvercharge= {
        'claimReason': '',
        'equipmentInitial':'',
        'equipmentNumber':'',
        'waybillfromDate':'',
        'waybilltoDate':'',
        'freightBillNumber':'',
        'waybill':'',
        'claimantReferenceNumber': '',
        'nationalAccNum' :'',
        'stcc':''
    }
    
    columns = [
        {label: "Claim #", fieldName: 'caseId',  type: 'url', typeAttributes: { label: { fieldName:'claimNumber' },tooltip: 'Go to detail page',target: '_blank'}, sortable: "true", initialWidth: 147 },   
        {label: "Claim Date", fieldName: 'claimDate', hideDefaultActions: true, type: 'date',typeAttributes: {timeZone:'UTC',year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true" , initialWidth: 95},
        {label: "Desk", fieldName: 'deskName', hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 85},
        {label: "Assigned To", fieldName: 'assignedTo', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 132 },
        {label: 'Age', fieldName:'claimAge',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 60},
        {label: 'Claim Amount',fieldName:'claimAmount',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 116},
        {label: 'Claim Type',fieldName: 'claimType',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 163},
        {label: 'Claim Status',fieldName: 'claimStatus',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 190},
        {label: 'Claim Reason',fieldName: 'claimReason',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 130},
        {label: 'Customer Name',fieldName: 'customerName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 205},
        {label: 'National Account#',fieldName: 'nationalAccountNumber',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140},
        {label: 'Claimant Name',fieldName: 'supplierClaimantName',hideDefaultActions: true, type: 'text', sortable: "true" , initialWidth: 140}
        ];

    buttonColumns=[
        {type: "button", label: 'View', initialWidth: 100, typeAttributes: {  
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
        
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT }) caseInfo;
    get recordTypeId() {
        if(this.caseInfo.data){
            const rtis = this.caseInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(
              rti => rtis[rti].name ==='Overcharge'
            );
        }         
    }
 
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT ,recordTypeId: '$recordTypeId'})
    claimReasonValues({ data, error }) {
        if (data) {
            this.claimReasonOptions = data.picklistFieldValues.CSX_CMP_Claim_Reason__c.values;
        } else{           
            console.log(error);
        }
    }
   
    handleInputChange(event) {
        if (event.target.checked) {
            this.revOvercharge[event.target.name] = event.target.checked;
            this.disableSearchButton = false;
            this.disableResetButton = false;
        } else {
            
            this.revOvercharge[event.target.name] = event.target.value;
            let equipInitial = this.template.querySelector('[data-id="equipInitial"]');
            let equipNumber = this.template.querySelector('[data-id="equipNumber"]');
            this.equipInitial=equipInitial.value;
            this.equipNum=equipNumber.value;
            this.disableSearchButton = false;
            this.disableResetButton = false;

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
                    equipNumber.setCustomValidity('Only numeric values are allowed.');
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
        this.shownoRecordError = false;
        this.dispatchEvent(new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true}));
        const searchValues= 'search';
        const selectEvent=new CustomEvent('searchchange',{detail:searchValues,bubbles:true});
        this.dispatchEvent(selectEvent);
        let claimInfoMap = new Map();
        //let claimStatus = this.revOvercharge.claimStatus;
        claimInfoMap = Object.keys(this.revOvercharge).reduce((map, key) => {
            if (this.revOvercharge[key]) {
                map.set(key, this.revOvercharge[key]);
            }
            return map;
        }
            , new Map());

        let claimInfoFromParent = new Map();
        claimInfoFromParent = Object.keys(this.claimInfoMapParentDataO).reduce((map, key) => {

            if (this.claimInfoMapParentDataO[key]) {
                map.set(key, this.claimInfoMapParentDataO[key]);
            }
            return map;
        }
        , new Map());

        let result = new Map([...claimInfoFromParent]);

        claimInfoMap.forEach((value, key) => {
            if (result.has(key)) {
            result.set(key, claimInfoFromParent.get(key));
            } else {
            result.set(key, value);
                }
        });
        let obj2 = Object.fromEntries(result);
        let claimDataStringCon = JSON.stringify(obj2);
        let obj = Object.fromEntries(claimInfoMap);
        let claimData = JSON.stringify(obj);
        console.log('claimData =>',claimData);

        if(claimDataStringCon != '{"claimGroup":"Revenue_Overcharge"}') {
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
                        tempRecs.push( tempRec );
                    });
                    
                    this.records=tempRecs;
                    this.showTable=true;
                    this.searchResults = true;
                    this.showDetailButton = true;
                    this.showClaimDetail=true;
                    this.isLoaded = true;
                    const paymentEvent= new CustomEvent('buttondisplay', { detail: this.showDetailButton, bubbles: true});
                    this.dispatchEvent(paymentEvent);
                }
                else{
                    this.showTable=false;
                    this.searchResults = false;
                    this.showClaimDetail = false;
                    this.showDetailButton = false;
                    this.shownoRecordError = true;
                    this.isLoaded=true;
                }
            }
            else{
                this.shownoRecordError = true;
                this.isLoaded=true;
            }
            })
            .catch(error => {
                let parameters =   this.records;
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
        }else{
            const selectionHeaderIssue = new ShowToastEvent({
                message:'Please enter atleast 1 search criteria',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }
        this.showPaginationComponent = true;
        this.showClaimDetail=true;

    }
    handleResetClick(){
        this.paymentID=[];
        this.claimSelectedIds=[];
        this.isLoaded=true;
        this.claimInfoMapParentData = {};
        this.shownoRecordError = false;
        const resetValues= 'reset';
        const selectEvent=new CustomEvent('valuechangeovercharge',{detail:resetValues,bubbles:true});
        this.dispatchEvent(selectEvent);
        this.showTable=false;
        this.claimNumber ='';
        this.claimStartDate = null
        this.waybillStartDate = null;
        this.claimEndDate = null;
        this.waybillEndDate=null;
        this.showDetailButton=false;
        this.disableSearchButton= true;
        this.disableResetButton = true;
        this.recordsToDisplay = [];
        this.showTable = false;
        this.searchResults = false;
        this.showClaimDetail = false;
        this.revOvercharge= {
            'claimReason': '',
            'equipmentInitial':'',
            'equipmentNumber':'',
            'waybillfromDate':'',
            'waybilltoDate':'',
            'freightBillNumber':'',
            'waybill':'',
            'claimantReferenceNumber': '',
            'nationalAccNum' :'',
            'stcc':''
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
                tmp["Claim #"]=obj.claimNumber;
                tmp["Desk"] =obj.deskName;
                tmp["Assigned To"] =obj.assignedTo;
                tmp["Claim Amount"] =obj.claimAmount;
                tmp["Claim Type"] = obj.claimType;
                tmp["Claim Status"] =obj.claimStatus;
                tmp["Claim Reason"] =obj.claimReason;
                tmp["Customer Name"] =obj.customerName;
                tmp["National Account#"] = obj.nationalAccountNumber;
                tmp["Claimant Name"] = obj.supplierClaimantName;  
                tmp["Name"] =obj.nameClaimContact;
                tmp["Email"] = obj.emailClaimContact;
                tmp["Telephone"] = obj.telephoneClaimContact; 
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
        } catch(error) {
                let parameters = '';
                csx_cmp_logError('csx_cmp_claimSearchrRevOvercharge', 'handleRowLinkClickSelection', error, parameters);
        }
    }

}