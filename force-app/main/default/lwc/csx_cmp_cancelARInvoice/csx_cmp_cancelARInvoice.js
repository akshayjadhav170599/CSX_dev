import { LightningElement, wire } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import fetchARrecordDetails from '@salesforce/apex/CSX_CMP_InvoiceAdjustmentController.fetchARrecordDetails';
//import cancelInvoice from '@salesforce/apex/CSX_CMP_InvoiceAdjustmentController.cancelInvoice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import { createRecord } from 'lightning/uiRecordApi';
import NOTES_OBJECT from '@salesforce/schema/CSX_CMP_Notes__c';
import NOTE_TYPE from '@salesforce/schema/CSX_CMP_Notes__c.CSX_CMP_Note_Type__c';
import CLAIM_FIELD from '@salesforce/schema/CSX_CMP_Notes__c.CSX_CMP_Claim__c';
import NOTE_DETAILS_FIELD from '@salesforce/schema/CSX_CMP_Notes__c.CSX_CMP_Notes__c';
import { getRecord } from 'lightning/uiRecordApi';
import CLAIM_FIELDAR from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Claim__c';
import REQUEST_TYPE from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Request_Type__c';
import INVOICE_NUMBER from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Invoice_Number__c';
import REVERSAL_REASON from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Reversal_Reason__c';
import INVOICE_DATE from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Invoice_Date__c';
import COMPANY_CODE from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Company_Code__c';
import CASE_NUMBER from '@salesforce/schema/CSX_CMP_AR_Settlement__c.CSX_CMP_Claim__r.CaseNumber';
import AR_NAME from '@salesforce/schema/CSX_CMP_AR_Settlement__c.Name';
import fetchCancelInvoiceStatus from '@salesforce/apex/CSX_CMP_InterfaceUtility.fetchCancelInvoiceStatus';


export default class Csx_cmp_cancelARInvoice extends LightningElement {
    recordId;
    currentInvoiceNumber;
    currentInvoiceAmount; 
    currentStatus;
    Details = {};
    modalContainer;
    displaycontainer = false;
    displayErrorContainer = false;
    isLoaded = false;
    cancellationReason;
    noteId;
    claimId;
    requestType;
    invoiceNumber;
    reversalReason;
    invoiceDate;
    companyCode;
    caseNumber;
    createdDate;
    arName;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    @wire(getRecord, { recordId: '$recordId', fields: [CLAIM_FIELDAR,REQUEST_TYPE,INVOICE_NUMBER,REVERSAL_REASON,INVOICE_DATE,COMPANY_CODE,CASE_NUMBER,AR_NAME]})
    wiredRecord({ error, data }) {
        if (data) {
            if(data.fields.CSX_CMP_Claim__c.value){
                this.claimId = data.fields.CSX_CMP_Claim__c.value;
            }
            if(data.fields.CSX_CMP_Request_Type__c.value){
                this.requestType = data.fields.CSX_CMP_Request_Type__c.value;
            }
            if(data.fields.CSX_CMP_Reversal_Reason__c.value){
                this.reversalReason = data.fields.CSX_CMP_Reversal_Reason__c.value;
            }
            if(data.fields.CSX_CMP_Invoice_Date__c.value){
                this.invoiceDate = data.fields.CSX_CMP_Invoice_Date__c.value;
            }
            if(data.fields.CSX_CMP_Company_Code__c.value){
                this.companyCode = data.fields.CSX_CMP_Company_Code__c.value;
            } 
            if (data.fields.CSX_CMP_Claim__r) {
                this.caseNumber = data.fields.CSX_CMP_Claim__r.value.fields.CaseNumber.value;
            }
            if(data.fields.CSX_CMP_Invoice_Number__c.value){
                this.invoiceNumber = data.fields.CSX_CMP_Invoice_Number__c.value;
            }  
            if(data.fields.Name.value){
                this.arName = data.fields.Name.value;
            }
            let currentDate = new Date(); 
            
            this.createdDate = currentDate.getUTCFullYear() + '-' +
            String(currentDate.getUTCMonth() + 1).padStart(2, '0') + '-' +
            String(currentDate.getUTCDate()).padStart(2, '0') + 'T' +
            String(currentDate.getUTCHours()).padStart(2, '0') + ':' +
            String(currentDate.getUTCMinutes()).padStart(2, '0') + ':' +
            String(currentDate.getUTCSeconds()).padStart(2, '0') + '.0Z';

            console.log('claimId ' + this.claimId);
            console.log(' this.caseNumber ' +  this.caseNumber);
            console.log(' this.reversalReason ' + this.reversalReason);
            console.log('  this.createdDate ' +  this.createdDate);
            
        } else if (error) {
            console.error('Error fetching record fields: ' + error.body.message);
            console.log('Error details: '+JSON.stringify(error))
        }
    }

    renderedCallback(){
        if(this.isLoaded){
            return;
        }
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--horizontalForm .modal-container{
            width:45% !important;
            max-width: 45%;
            min-width:5%;
            max-height:100%;
            min-height:480px;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }

    connectedCallback() {
        fetchARrecordDetails({ arSettlementId: this.recordId }).then(result => {
            if (result) {
                console.log(' this.Details'+result);
                this.Details = result;
                if(this.Details.invoiceStatus == 'Open'){
                    this.displaycontainer = true;
                    this.currentInvoiceNumber = this.Details.invoiceNumber;
                    this.currentInvoiceAmount = this.Details.invoiceAmount;
                    this.currentStatus = this.Details.invoiceStatus;
                }
                else{
                    this.displayErrorContainer = true;
                    this.currentStatus = this.Details.invoiceStatus;
                }
            }
            
        }).catch(error => {
            csx_cmp_logError('Csx_cmp_cancelARInvoice','fetchARrecordDetails',error);
        });
    }
    handleAddReason(event) {
        this.cancellationReason = event.target.value;
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    submitRequest(){
        console.log('this.recordId:'+this.recordId);
        const fields = {};
        fields[NOTE_DETAILS_FIELD.fieldApiName] = this.cancellationReason;
        fields[CLAIM_FIELD.fieldApiName] = this.claimId;
        fields[NOTE_TYPE.fieldApiName] = 'Cancellation Reason';
        
        const recordInput = { apiName: NOTES_OBJECT.objectApiName, fields };
                    fetchCancelInvoiceStatus({ invoiceNumber: this.invoiceNumber, arSettlementName: this.arName,companyCode: this.companyCode, invoiceDate: this.invoiceDate,reversalReason: this.reversalReason, requestType: this.requestType,createdDate: this.createdDate, claimNumber: this.caseNumber,invoiceId:this.recordId
                    }).then(result => {
                        console.log('result: '+result);
                        if(result){
                            console.log('result'+result);
                            if(result == 'Document posted successfully'){
                               // this.showToast('Success', 'AR Invoice is cancelled', 'success');
                                const invoiceCancelled = new ShowToastEvent({
                                    title:'Cancelled',
                                    message: 'AR Invoice is cancelled',
                                    duration: '50000',
                                    variant: 'Success',
                                });
                                this.dispatchEvent(invoiceCancelled);
                                createRecord(recordInput)
                                .then(note => {
                                    this.noteId = note.id;
                                    console.log('Note Created with id ' + note.id);
                                    /*this.showToast('Success', 'Note type of cancellation reason has been created successfully', 'success');*/
                                    const noteCreatedEvent = new ShowToastEvent({
                                        title:'Note Created',
                                        message: 'Note type of cancellation reason has been created successfully',
                                        duration: '50000',
                                        variant: 'Success',
                                    });
                                    this.dispatchEvent(noteCreatedEvent);
                                    setTimeout(() => {
                                        location.reload();
                                    }, 2000);
                                    console.log('this.createdDate:'+this.createdDate);
                                }).catch(error => {
                                    console.error('Error creating account: ' + error.body.message);
                                    console.error('Error creating account: ' + error);
                                    console.log('error: '+JSON.stringify(error));
                                    this.closeQuickAction();
                                    this.showToast('Error', 'AR Invoice is not cancelled', 'Error');
                                    this.closeQuickAction();  
                                });
                               
                            }
                            else if(result == 'Error'){
                                this.showToast('Error', 'AR Invoice is not cancelled', 'Error');
                                this.closeQuickAction();  
                            }
                            else {
                                this.showToast('Cancellation Unsuccessful', result, 'warning');
                                setTimeout(() => {
                                    location.reload();
                                }, 2000);
                            }
                    }
                    this.closeQuickAction();
                    }).catch(error => {
                        console.log('error :',error);
                        this.showToast('Error', 'Already AR Invoice is cancelled', 'error');
                        this.closeQuickAction();  
                    });          
    }

   /* handelSubmit() {
        cancelInvoice({ arSettlementId: this.recordId, cancellationReason: this.cancellationReason}).then(result => {
            if(result){
            if(result == 'Success'){
            this.showToast('Success', 'AR Invoice is cancelled', 'success');
            this.closeQuickAction();
            setTimeout(() => {
                location.reload();
            }, 2000);
            }else if(result == 'Error'){
                this.showToast('Error', 'AR Invoice is not cancelled', 'Error');
                this.closeQuickAction();  
            } 
        }
        
        }).catch(error => {
            console.log('error :',error);
            this.showToast('Error', 'Already AR Invoice is cancelled', 'error');
        });
    }*/

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            duration: 100000
        });
        this.dispatchEvent(event);
    }
}