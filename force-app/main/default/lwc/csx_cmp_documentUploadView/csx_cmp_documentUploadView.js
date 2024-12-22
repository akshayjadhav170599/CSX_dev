import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import fetchData from '@salesforce/apex/CSX_CMP_DocumentUploadViewerController.fetchData';
import fileUpload from '@salesforce/apex/CSX_CMP_DocumentUploadViewerController.fileUpload';
import getDocuments from '@salesforce/apex/CSX_CMP_DocumentUploadViewerController.getDocuments';
import deleteDocument from '@salesforce/apex/CSX_CMP_DocumentUploadViewerController.deleteDocument';
// import scheduleBatchJob from '@salesforce/apex/CSX_CMP_DocumentUploadViewerController.scheduleBatchJob';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
const MAX_FILE_SIZE = 25242880;

export default class Csx_cmp_documentUploadView extends LightningElement {

    @track freight = false;
    @track revenue = false;
    @track ldReport = false;
    @api recordId;
    strNumber;
    screenData;
    @track uploadedDocuments = [];
    @track isInternalOnly = true;
    @track isUploadToECM = true;
    showSpinner = false;
    @track uploadDate;
    @track strComments;
    @track isUpload = false;
    @track isReupload = false;
    @track newFileName = '';
    @track isClaimType = false;

    files;
    fileData;
    isUploadToECMCheck;
    contentDocumentId;
    docId;

    connectedCallback() {
        console.log('calling connected callback');
        this.fetchRecordData();
        this.fetchUploadedDocuments();
        setInterval(() => {
            this.fetchUploadedDocuments();
        }, 5000);
    }
    
    fetchRecordData() {
        console.log('calling fetchrecorddata');
        const strId = this.recordId;
        fetchData({ strId })
            
            .then(result => {
                this.screenData = result;
                console.log('showing screenData', this.screenData);
                this.strNumber = this.screenData.strNumber;
                this.strEquipmentName = this.screenData.strEquipmentName;
                this.strVin = this.screenData.strVin;
                this.strWayBillDate = this.screenData.strWayBillDate;
                this.strComments = this.screenData.strComments;
                this.strContractNumber = this.screenData.strContractNumber;
                // console.log('result.strUserRole::: '+result.strUserRole);
                // console.log(result.strUserRole.includes('Freight'));
                if (result.strClaimType === 'FC Customer Claim') {
                    this.isClaimType = true;
                }

                if (result.strUserRole.includes('Admin')) {
                    if (result.strRecordTypeDeveloperName === 'Freight') {
                        this.freight = true;
                        this.revenue = false;
                        this.ldReport = false;
                    } else if (result.strRecordTypeDeveloperName === 'Revenue_Contract_Refund'
                                || result.strRecordTypeDeveloperName === 'Revenue_Overcharge'
                                || result.strRecordTypeDeveloperName === 'Revenue_Railroad')
                    {
                        this.freight = false;
                        this.revenue = true;
                        this.ldReport = false;
                    } else {
                        this.freight = false;
                        this.revenue = false;
                        this.ldReport = true;
                    }
                } else if (result.strUserRole.includes('Freight') || result.strUserRole.includes('Transflo')) {
                    this.freight = true;
                    this.revenue = false;
                    this.ldReport = false;
                } else if (result.strUserRole.includes('Revenue') ) {
                    this.freight = false;
                    this.revenue = true;
                    this.ldReport = false;
                } else {
                    this.freight = false;
                    this.revenue = false;
                    this.ldReport = true;
                }

            })
            .catch(error => {
                csx_cmp_logError('csx_cmp_documentUploadView', 'fetchRecordData', error, '');
            });

            console.log('this.freight', this.freight);
            console.log('this.revenue',this.revenue);
    }

    handleCommentsChange(event) {
        if (event.target.value) {
            this.strComments = event.target.value;
        }
    }

    fetchUploadedDocuments() {
         console.log('calling fetchuploadeddocuments');
        const strId = this.recordId;
        getDocuments({strId}) 
            .then(result => {
                console.debug("Testing", result);
                    this.uploadedDocuments = result.map(doc => {
                        
                        return {
                        ...doc,
                        uploadDate: new Date(doc.CreatedDate).toISOString().slice(0, 10),
                    };
                    });
                        refreshApex(result);
            })
            .catch(error => {
                csx_cmp_logError('csx_cmp_documentUploadView', 'fetchUploadedDocuments', error, '');
            });
    }

    UploadOnlyCheckboxChange(event) {
        if (event.target.checked) {
            this.isUploadToECM = true;
            
        } else {
            this.isUploadToECM = false;
        }
    }

    InternalOnlyCheckboxChange(event) {
        if (event.target.checked) {
            this.isInternalOnly = true;
        } else {
            this.isInternalOnly = false;
        }
    }

    onfileUpload(event) {
        console.log('Upload button clicked');
    
        const strID = this.recordId;        
        this.files = event.target.files;
        this.showSpinner = true;
        // let errorMessage = '';
        // let successCount = 0;

        Array.from(this.files).forEach((file, index, arr) => {
                
            if (file.size > MAX_FILE_SIZE) {
                this.showToast('Error', 'error', `${file.name} exceeds the maximum file size of 25MB.`);
                this.showSpinner = false;
                return;
            }
            const reader = new FileReader();

            reader.onload = () => {
                var base64 = reader.result.split(',')[1];
                this.fileData = {
                    'filename': file.name,
                    'base64': base64,
                    'parentId': strID,
                };
                console.log('this.isReupload::: ' + this.isReupload + 'this.isUpload::: ' + this.isUpload);
                this.isUploadToECMCheck = this.uploadToECMForRow != null ? this.uploadToECMForRow : this.isUploadToECM;
                console.log('177: this.isUploadToECMCheck::: ' + this.isUploadToECMCheck + ' this.docId::: ' + this.docId);
                const { base64: fileBase64, filename, parentId } = this.fileData;
                
                fileUpload({
                        base64: fileBase64,
                        filename,
                        parentId,
                        isInternalOnly: this.isInternalOnly,
                        isUploadToECM: this.isUploadToECMCheck,
                        newComments: this.strComments,
                        isReupload: this.isReupload,
                        isUpload: this.isUpload,
                        contentDocumentId: this.contentDocumentId,
                        docId : this.docId
                    })
                    .then(result => {
                        if (result) {
                            this.showSpinner = false;
                            this.showToast('Success', 'success', `Documents uploaded successfully!!`);
                        }
                        else {
                            this.showSpinner = false;
                            this.showToast('Error', 'error','Error in document uploading', 'error');
                        }
                            refreshApex(result);
                        // const uploadedFiles = file.name
                        // this.recentlyUploadedDocuments.push(uploadedFiles);
                        // console.log('this.recentlyUploadedDocuments',JSON.stringify(this.recentlyUploadedDocuments));

                        // if (successCount + errorMessage.length === arr.length) {
                        //     console.log('successCount:: '+successCount);
                        //     this.showSingleToast(successCount, errorMessage);
                        //      this.showSpinner = false;
                        // }
                        
                        // Fetch the docuements
                        //this.fetchUploadedDocuments();
                        
                        // Submit the document for ECM upload
                        // if(this.isUploadToECMCheck){
                        //     this.onSubmitClick(); 
                        // }
                    })
                    .catch(error => {
                        this.showSpinner = false;
                        this.showToast('Error', 'error','Something went wrong', 'error');
                    });
            };
            reader.readAsDataURL(file);
        });
    }

    showSingleToast(successCount, errorMessage) {
        this.showSpinner = false;
        if (errorMessage) {
            this.showToast('Error', 'error', errorMessage);
        } else if (successCount > 0) {
            this.showToast('Success', 'success', `Documents uploaded successfully!`);
        }
    }

    handleDelete(event) {
        const documentId = event.currentTarget.dataset.id ;
        this.showSpinner = true;

        deleteDocument({ documentId })
            .then(() => {
                this.showToast('Success', 'success','Document deleted successfully!');
                this.showSpinner = false;
                this.fetchUploadedDocuments();
            })
            .catch(error => {
                this.showToast('Error', 'error','Error deleting document', 'error');
                csx_cmp_logError('csx_cmp_documentUploadView', 'handleDelete', error, '');
            });
    }

    onClickUpload(event) {
        console.log('Upload onclickupload clickec');
        
        this.isUpload = true;
        this.isReupload = false;

        let Title = event.currentTarget.dataset.id;
        this.newFileName = Title.substring(0, Title.lastIndexOf('.'));
        this.uploadToECMForRow = event.target.dataset.uploadecm;
        this.contentDocumentId = event.target.dataset.cdid;
        this.docId = event.target.dataset.docid;
        this.contentVersionId = event.target.dataset.cvid;
        
        this.template.querySelector("input[ type='file']").click();
    }

    onClickReUpload(event) {
        this.isUpload = false;
        this.isReupload = true;

        let Title = event.currentTarget.dataset.id;
        this.newFileName = Title.substring(0, Title.lastIndexOf('.'));
        this.uploadToECMForRow = event.target.dataset.uploadecm; 
        this.contentDocumentId = event.target.dataset.cdid;
        this.docId = event.target.dataset.docid;

        this.template.querySelector("input[ type='file']").click();
    }

    //  onSubmitClick(event) {
    //     let contentVersionIds;
    //     contentVersionIds = this.uploadedDocuments.filter(doc => doc.CSX_CMP_UploadToECM__c === true).map(doc => doc.CSX_CMP_ContentVersionID__c);
    //      this.finalUpload = this.uploadedDocuments.filter(doc => doc.CSX_CMP_UploadToECM__c === true).map(doc => doc.CSX_CMP_UploadToECM__c);
         
    //     if(this.isReupload){
    //         contentVersionIds = this.contentDocumentId;
    //         console.log('contentVersionIds:267: '+contentVersionIds);
    //     } else {
    //         console.log('cvIds--=== '+this.cvIds);
    //         contentVersionIds = this.cvIds;
    //     }
         
    //     if (contentVersionIds.length > 0) { //this.finalUpload
    //         scheduleBatchJob({
    //             contentVersionIds: contentVersionIds,
    //             isDelete: true,
    //             parentEntityType: this.freight ? 'Claim' : (this.revenue ? 'Claim' : 'LD Report'),
    //             isManual: true
    //         })
    //             .then(result => {
    //                 this.showToast('Success', 'success', 'Document has been sent for ECM upload successfully!');
    //                 setTimeout(() => {
    //                     refreshApex(result);
    //                 }, 600);
            
    //             })
    //             .catch(error => {
    //                 this.showToast('Error', 'error', 'Document not uploaded to ECM');
    //                 console.error(error);
    //             });
    //     }
    // }
    
    handleECMLinkClick(event) {
        const strId = this.recordId;
        fetchData({ strId })
            .then(result => {
                this.screenData = result;  
                this.strECMLink = this.screenData.strECMLink;
                console.log('this.ecmUrl??' + this.strECMLink);
            
                if (this.strECMLink) {
                    window.open(this.strECMLink, '_blank');
                } else {
                    this.showToast('Error', 'error','ECM link is not available');
                }     
            })
            .catch(error => {
                csx_cmp_logError('csx_cmp_documentUploadView', 'fetchRecordData', error, '');
            });
    }

//    onClickECMID(event) {
//         this.EcmLink = event.target.dataset.tilegroup;    
//         const url = `https://ecmd.csx.com/cs/idcplg?IdcService=GET_FILE&RevisionSelectionMethod=latest&Rendition=primary&Auth=Internet&dDocName=${this.EcmLink}`;
//         window.open(url, '_blank');
//     }

    showToast(title, variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: variant,
                message: message,
            })
        );
    }
}