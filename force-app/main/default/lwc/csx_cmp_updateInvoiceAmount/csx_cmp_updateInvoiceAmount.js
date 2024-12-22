import { LightningElement, wire } from 'lwc';
import { CurrentPageReference , NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateInvoiceAmount from '@salesforce/apex/CSX_CMP_InvoiceAdjustmentController.updateInvoiceAmount';
import fetchARrecordDetails from '@salesforce/apex/CSX_CMP_InvoiceAdjustmentController.fetchARrecordDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class csx_cmp_updateInvoiceAmount extends NavigationMixin(LightningElement) {
    recordId;
    Details = {}; 
    currentInvoiceNumber;
    currentInvoiceAmount;
    currentStatus;
    newInvoiceAmount;
    displaycontainer = false;
    displayErrorContainer = false;
    isLoaded = false;
    createdDate;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    renderedCallback() {
        if (this.isLoaded) {
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
            console.error('error', error);
        });
    }

    handelSubmit() {
        const recordIdPattern = /^[a-zA-Z0-9]{18}$/;
        let currentDate = new Date();
        this.createdDate = currentDate.getUTCFullYear() + '-' +
        String(currentDate.getUTCMonth() + 1).padStart(2, '0') + '-' +
        String(currentDate.getUTCDate()).padStart(2, '0') + 'T' +
        String(currentDate.getUTCHours()).padStart(2, '0') + ':' +
        String(currentDate.getUTCMinutes()).padStart(2, '0') + ':' +
        String(currentDate.getUTCSeconds()).padStart(2, '0') + '.0Z';
        updateInvoiceAmount({ arSettlementId: this.recordId, invoiceAmount: this.newInvoiceAmount ,createdDate:this.createdDate}).then(result => {
            if (result) {
                console.log('result:'+result);
                this.closeQuickAction();
                if(recordIdPattern.test(result)){  
                    this.showToast('Success', 'Invoice Amount updated successfully', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId : result,
                            objectApiName: 'CSX_CMP_AR_Settlement__c',
                            actionName: 'view'
                        },
                    });
                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                }else{
                    this.showToast('Error from SAP Server', 'Invoice Amount not updated successfully', 'Error');
                }
                    
            }
        }).catch(error => {
            console.log(error);
            this.showToast('Error', 'An error while processing', 'error');
        });

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleInvoiceAmountChange(event) {
        this.newInvoiceAmount = event.target.value;
    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}