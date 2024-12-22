import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//import OWNER_FIELD from "@salesforce/schema/Case.OwnerId";
import submitForApproval from "@salesforce/apex/CSX_CMP_SubmitForApprovalController.submitForApproval";
import updateClaimOnHold from "@salesforce/apex/CSX_CMP_SubmitForApprovalController.updateClaimOnHold";
import callApprovalBusinessRules from "@salesforce/apex/CSX_CMP_SubmitForApprovalController.callApprovalBusinessRules";
import claimApprovalEvalutionForARBalance from "@salesforce/apex/CSX_CMP_SubmitForApprovalController.claimApprovalEvalutionForARBalance";
import { CloseActionScreenEvent } from "lightning/actions";
import { log } from 'lightning/logger';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

//const FIELDS = [OWNER_FIELD];

export default class Csx_cmp_submitForApproval extends LightningElement {
	@api recordId;
	error;
	message;
	isOnHold = false;
	checkIfFailed = false;
	toggle;

	@track qualifiedData = [];
	@track unQualifiedData = [];
	@track strKey = "";

	connectedCallback() {
		setTimeout(() => {
			this.loadRecordData();
		}, 500);
	}

	loadRecordData() {
		submitForApproval({ caseId: this.recordId })
			.then((data) => {
				this.qualifiedData = [];
				this.unQualifiedData = [];

				data.forEach((item) => {
					if (item.strValueColor === "Green") {
						this.qualifiedData.push(item);
					} else if (item.strValueColor === "Red") {
						this.unQualifiedData.push(item);
						this.checkIfFailed = true;

					}
				});

				if (this.unQualifiedData.length == 0) {
					this.callForARBalanceCheck();
				}
			})
			.catch((error) => {
                this.error = error;
                log("this.error:: "+JSON.stringify(this.error));
			});
	}

	callForARBalanceCheck() {
		claimApprovalEvalutionForARBalance({ caseId: this.recordId })
			.then((data) => {
				data.forEach((item) => {
					if (item.strValueColor === "Green") {
						this.qualifiedData.push(item);
					} else if (item.strValueColor === "Red") {
						this.unQualifiedData.push(item);
					}
				});

				//show confirmation message and button
				if (this.unQualifiedData.length > 0) {
					this.isOnHold = true;
				} else {
					this.callAutoApprovalProcess();
				}
			})
			.catch((error) => {
                this.error = error;
				csx_cmp_logError('Csx_cmp_submitForApproval', 'claimApprovalEvalutionForARBalance', error, '');
			});
	}

	//update the claim status on Hold and send the email notification to customer
	keepClaimOnHold() {
		updateClaimOnHold({ caseId: this.recordId })
			.then((data) => {
				if (data) {
					this.showSuccessToast("Claim Status updated to On-hold & email notification sent to Customer.");
				} else {
					this.showErrorToast("Something went wrong, please contact with your administrator.");
				}

				//close the screen
				this.dispatchEvent(new CloseActionScreenEvent());

				// Display fresh data in the form
				//return refreshApex(this.recordId);
				setTimeout(() => {
					location.reload(this.recordId);
				}, 500);
			})
			.catch((error) => {
                this.error = error;
			});
	}

	// call the business rules for auto approval process
	callAutoApprovalProcess() {
		callApprovalBusinessRules({ caseId: this.recordId })
			.then((data) => {
				let strValue = "";
				let strMesssage = "";

				data.forEach((item) => {
					if (item.strValueColor === "Green") {
						this.qualifiedData.push(item);
					} else if (item.strValueColor === "Red") {
						this.unQualifiedData.push(item);
					}
					strValue = item.strValue;
					strMesssage = item.strErrorMessage;
				});

				//show confirmation message and button
				if (this.unQualifiedData.length == 0) {
					this.isOnHold = false;
					
					this.showSuccessToast(strValue);

					//close the screen
					this.dispatchEvent(new CloseActionScreenEvent());

					// Display fresh data in the form
					setTimeout(() => {
						location.reload(this.recordId);
					}, 500);
					
					// Display fresh data in the form
					//return refreshApex(this.recordId);
				} else {
					this.showErrorToast(strMesssage);

					//close the screen
					this.dispatchEvent(new CloseActionScreenEvent());

					// Display fresh data in the form
					setTimeout(() => {
						location.reload(this.recordId);
					}, 500);
					
					// Display fresh data in the form
					//return refreshApex(this.recordId);
				}
			})
			.catch((error) => {
                this.error = error;
                log("this.error:: "+JSON.stringify(this.error));
			});
	}

	showSuccessToast(msglabel) {
		const evt = new ShowToastEvent({
			message: msglabel,
			variant: "success"
		});
		this.dispatchEvent(evt);
	}

	showErrorToast(msglabel) {
		const evt = new ShowToastEvent({
			message: msglabel,
			variant: "error"
		});
		this.dispatchEvent(evt);
	}
}