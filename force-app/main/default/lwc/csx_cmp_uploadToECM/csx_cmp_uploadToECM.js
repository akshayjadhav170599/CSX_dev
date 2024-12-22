import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import manualEmailUpload from "@salesforce/apex/CSX_CMP_UploadEmailToECMController.manualEmailUpload";
import manualDocumentUpload from "@salesforce/apex/CSX_CMP_UploadEmailToECMController.manualDocumentUpload";

export default class Csx_cmp_uploadToECM extends LightningElement {
	@api recordId;
	@api record;
	message;
	subscription = {};
	channelName='/event/CSX_CMP_ECM_Upload_Notification__e';

	uploadDocumentToECM() {
		if(this.recordId.startsWith('02s')){
			manualEmailUpload({ emailMessageId: this.recordId })
			.then((result) => {
				this.message = result;
				const uploadSuccess = new ShowToastEvent({
					title: this.message,
					variant: this.message.includes('successful') ? "success" : "error"
				});
				this.dispatchEvent(uploadSuccess);
				const toastCloseHandler = (event) =>{
					window.removeEventListener('toastClose',toastCloseHandler);
					window.location.reload();
				}

				window.addEventListener('toastClose',toastCloseHandler);

				setTimeout(() => {
							window.dispatchEvent(new CustomEvent('toastClose'));
				},5000);
				this.CloseModal();
			})
			.catch((error) => {
				const uploadError = new ShowToastEvent({
					title: "Could not upload Email",
					variant: "error"
				});
				console.log(error);
				this.dispatchEvent(uploadError);
				this.CloseModal();
			});
		}else{
			manualDocumentUpload({ contentDocId: this.record.CSX_CMP_Content_Document_ID__c })
			.then((result) => {
				const uploadSuccess = new ShowToastEvent({
					title: " Your Request has been submitted.Refresh again if the ECM Id is not generated ",
					variant: "success"
				});
				this.dispatchEvent(uploadSuccess);
				const toastCloseHandler = (event) =>{
					window.removeEventListener('toastClose',toastCloseHandler);
					window.location.reload();
				}

				window.addEventListener('toastClose',toastCloseHandler);

				setTimeout(() => {
							window.dispatchEvent(new CustomEvent('toastClose'));
				},5000);
				this.CloseModal();
			})
			.catch((error) => {
				const uploadError = new ShowToastEvent({
					title: "Could not upload document",
					variant: "error"
				});
				console.log(error);
				this.dispatchEvent(uploadError);
				this.CloseModal();
			});
		}
	}

	CloseModal() {
		const closeEvent = new CustomEvent("close");
		this.dispatchEvent(closeEvent);
	}
}