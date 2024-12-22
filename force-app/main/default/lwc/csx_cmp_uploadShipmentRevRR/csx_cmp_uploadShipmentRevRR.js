import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { csx_cmp_logError } from "c/csx_cmp_logError";

// custom labels
import uploadInstructions from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_Instructions";
import noFileFoundMessage from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_noFileFoundMessage";
import fileUploadedMessage from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_fileUploadedMessage";
import columnMismatchMessage from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_columnMismatchMessage";
import submitClaim from "@salesforce/label/c.CSX_CMP_ClaimCreation_SubmitLabel";
import shipmentsMorethan500 from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_shipmentsMorethan500";
import validFileMessage from "@salesforce/label/c.CSX_CMP_Revenue_Rail_Road_Upload_validFileMessage";
import reset from "@salesforce/label/c.CSX_CMP_ResetLabel";
import claimAmountErr from "@salesforce/label/c.CSX_CMP_ClaimAmountError";
import backToSearch from "@salesforce/label/c.CSX_CMP_BackToSearchLabel";
import waybillDateMessage from "@salesforce/label/c.CSX_CMP_Waybill_Date_Error_Message";
import urrwinDateMessage from "@salesforce/label/c.CSX_CMP_Urrwin_Date_Error_Message";
import duplicateUrwinMessage from "@salesforce/label/c.CSX_CMP_Duplicate_Urrwin_Message";
import duplicateWaybillMessage from "@salesforce/label/c.CSX_CMP_Duplicate_Waybill_Message";
import equipmentInitialMessage from "@salesforce/label/c.CSX_CMP_Equipment_Initial_Error_Message";
import equipmentNumberMessage from "@salesforce/label/c.CSX_CMP_Equipment_Number_Error_Message";
import urrwinNumberMessage from "@salesforce/label/c.CSX_CMP_Urrwin_Number_Error_Message";
import waybillNumberMessage from "@salesforce/label/c.CSX_CMP_Waybill_Number_Error_Message";


export default class Csx_cmp_uploadShipmentRevRR extends LightningElement {
	//custom labels inported from Salesforce
	label = {
		submitClaim,
		reset,
		backToSearch,
		uploadInstructions,
		noFileFoundMessage,
		fileUploadedMessage,
		columnMismatchMessage,
		claimAmountErr,
		shipmentsMorethan500,
		validFileMessage,
		waybillDateMessage,
		urrwinDateMessage,
		duplicateUrwinMessage,
		duplicateWaybillMessage,
		equipmentInitialMessage,
		equipmentNumberMessage,
		urrwinNumberMessage,
		waybillNumberMessage
	};
	demoRecordsToAddInSample = []; //Sample Single record added to .csv file
	uploadedFile; // file uploaded by user
	uploadedFileName = "";
	@api
	totalClaimAmount = 0; // total claim amount of all records
	@api
	noClaimAmount = false;
	showSpinner = false; //spinner to be displayed while processing
	dataDisplayedOnDatatable; //data to be displayed on datatable
	recordsToDisplay; //records to be displayed on datatable
	// error message to be displayed on any duplicate found and message is populated from apex
	parsedData; //
	duplicateFlag = false; // flag to check if duplicate found
	isSuppressbottom = true;
	shipmentCheck = false;
	uploadShipment = {
		uploadShipmentRevRR: [], //data to be sent to apex
		duplicateComments: "", //comments from user to be sent to apex
		sendEmail: false //flag to check if email to be sent
	};

	//columnMap key should be same as headerMap label and it is case sensitive
	//map of column header to column name
	columnMap = new Map([
		["URRWIN #", "urrwinNumber"],
		["URRWIN Date (MM/DD/YYYY)", "urrwinDate"],
		["*Equipment Init", "equipmentInitial"],
		["*Equipment #", "equipmentNumber"],
		["*Waybill Number", "waybillNumber"],
		["*Waybill Date (MM/DD/YYYY)", "waybillDate"],
		["*Total Cars", "totalCars"],
		["*Origin State", "actOriginState"],
		["*Origin City", "actOriginCity"],
		["*Destination State", "actDestinationState"],
		["*Destination City", "actualDestinationCityName"],
		["Commodity #", "commodityNumber"],
		["Commodity Desc", "stccDescription"],
		["*Claim Amount", "claimAmount"]
	]);

	// map of column name to column header with required true/false
	headerMap = [
		{ label: "URRWIN #", value: "urrwinNumber", required: false, type: "number" },
		{ label: "URRWIN Date (MM/DD/YYYY)", value: "urrwinDate", required: false, type: "date" },
		{ label: "*Equipment Init", value: "equipmentInitial", required: true, type: "text", maxLength: 4 },
		{ label: "*Equipment #", value: "equipmentNumber", required: true, type: "number", maxLength: 6 },
		{ label: "*Waybill Number", value: "waybillNumber", required: true, type: "number" },
		{ label: "*Waybill Date (MM/DD/YYYY)", value: "waybillDate", required: true, type: "date" },
		{ label: "*Total Cars", value: "totalCars", required: true, type: "number" },
		{ label: "*Origin State", value: "actOriginState", required: true, type: "text" },
		{ label: "*Origin City", value: "actOriginCity", required: true, type: "text" },
		{ label: "*Destination State", value: "actDestinationState", required: true, type: "text" },
		{ label: "*Destination City", value: "actualDestinationCityName", required: true, type: "text" },
		{ label: "Commodity #", value: "commodityNumber", required: false, type: "number" },
		{ label: "Commodity Desc", value: "stccDescription", required: false, type: "text" },
		{ label: "*Claim Amount", value: "claimAmount", required: true, type: "currency" }
	];

	//columns displayed on datatable
	datatableColumns = [
		{
			label: "Error Message",
			fieldName: "errorMessage",
			type: "text",
			initialWidth: 180,
			cellAttributes: { alignment: "left", class: "slds-text-color_error" },
			hideDefaultActions: false
		},
		{
			label: "URRWIN #",
			fieldName: "urrwinNumber",
			type: "text",
			initialWidth: 90,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "URRWIN Date",
			fieldName: "urrwinDate",
			type: "date",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true,
			typeAttributes: {
				month: "2-digit",
				day: "2-digit",
				year: "numeric"
			}
		},
		{
			label: "Equipment Init",
			fieldName: "equipmentInitial",
			type: "text",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Equipment #",
			fieldName: "equipmentNumber",
			type: "text",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Waybill #",
			fieldName: "waybillNumber",
			type: "text",
			initialWidth: 90,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Waybill Date",
			fieldName: "waybillDate",
			type: "date",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true,
			typeAttributes: {
				month: "2-digit",
				day: "2-digit",
				year: "numeric"
			}
		},
		{
			label: "Total Cars",
			fieldName: "totalCars",
			type: "number",
			initialWidth: 80,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Origin State",
			fieldName: "actOriginState",
			type: "text",
			initialWidth: 90,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Origin City",
			fieldName: "actOriginCity",
			type: "text",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Destination State",
			fieldName: "actDestinationState",
			type: "text",
			initialWidth: 130,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Destination City",
			fieldName: "actualDestinationCityName",
			type: "text",
			initialWidth: 130,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Commodity #",
			fieldName: "commodityNumber",
			type: "text",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "Commodity Desc",
			fieldName: "stccDescription",
			type: "text",
			initialWidth: 150,
			cellAttributes: { alignment: "center" },
			hideDefaultActions: true
		},
		{
			label: "*Claim Amount",
			fieldName: "claimAmount",
			type: "currency",
			initialWidth: 110,
			cellAttributes: { alignment: "center" },
			typeAttributes: { currencyCode: "USD" },
			hideDefaultActions: true,
			editable: true
		}
	];
	dataTableTitle = "Selected Shipments";

	connectedCallback() {
		let data = {
			urrwinNumber: "31827525",
			urrwinDate: "2020-11-30",
			equipmentInitial: "UMXU",
			equipmentNumber: "889526",
			waybillNumber: "734367",
			waybillDate: "2020-05-20",
			totalCars: "2",
			actOriginState: "KY",
			actOriginCity: "ADDISON",
			actDestinationState: "NJ",
			actualDestinationCityName: "ALDENE",
			commodityNumber: "3071652",
			stccDescription: "PLASTICS",
			claimAmount: "56"
		};
	}

	handleInputChange(event) {
		if (event.target.type === "checkbox") {
			this.uploadShipment[event.target.name] = event.target.checked;
		} else {
			this.uploadShipment[event.target.name] = event.target.value;
		}
	}

	handleCellChange(event) {
		let updatedCell = event.detail.draftValues[0];
		let data = this.parsedData;
		data[updatedCell.rowNumber - 1].claimAmount = updatedCell.claimAmount;
		this.calculateClaimAmount(data);
	}

	getdownloadTemplate() {
		let generateCSV = this.template.querySelector("c-csx_cmp_excelexport");
		let headerList = this.headerMap.map((item) => item.label);
		let columnMap = Object.fromEntries(this.columnMap);
		let exportFileName = "Shipments Upload Template.csv";

		let data = {
			headerList: headerList,
			filename: exportFileName,
			data: this.demoRecordsToAddInSample,
			columnMap: JSON.stringify(columnMap)
		};
		generateCSV.exportCSVFile(JSON.stringify(data));
	}

	handleFilesChange(event) {
		let files = event.target.files;
		if (files.length > 0) {
			this.shipmentCheck = false;
			this.uploadedFile = files[0];
			let allowedExtensions = /(\.csv)$/i;
			if (!allowedExtensions.exec(this.uploadedFile.name)) {
				this.displayToast("Error", this.label.validFileMessage, "error");
				return;
			}

			this.validateInput();
		}
	}

	validateInput() {
		this.showSpinner = true;
		this.uploadShipment.uploadShipmentRevRR = [];
		this.dataDisplayedOnDatatable = [];
		this.recordsToDisplay = [];
		if (!this.uploadedFile) {
			this.showSpinner = false;
			this.displayToast("Error", this.label.noFileFoundMessage, "error");
			//return;
		} else {
			let dataOfUploadedFile = this.template.querySelector("c-csx_cmp_excelexport");
			let columns = Object.fromEntries(this.columnMap);
			let columnMap = JSON.stringify(columns);
			let data = {
				file: this.uploadedFile,
				columnMap: columnMap,
				headerMap: this.headerMap
			};
			this.parsedData = [];

			dataOfUploadedFile
				.readCSVFile(data)
				.then((result) => {
					let element = JSON.parse(result);
					console.log('element :::', element);
					if (element.length > 500) {
						this.displayToast("Error", this.label.shipmentsMorethan500, "error");
						this.showSpinner = false;
						this.uploadedFile = null;
						this.uploadedFileName = "";
						return;
					}

					if (element[0].errorMessage == "Column count mismatch") {
						this.displayToast("Error", this.label.columnMismatchMessage, "error");
						this.showSpinner = false;
					} else {
						this.uploadedFileName = "Uploaded File  : " + this.uploadedFile.name;
						this.displayToast("Success", this.label.fileUploadedMessage, "success");
						let data = JSON.parse(result);
						let urrwinMap = [];
						let waybillMap = [];
						data.forEach((element, index) => {
							element.rowNumber = index + 1;
							if (new Date(element.waybillDate) > new Date()) {
								element.errorMessage += this.label.waybillDateMessage;
							}
							if (element.equipmentInitial.length < 2 || element.equipmentInitial.length > 4) {
								element.errorMessage += this.label.equipmentInitialMessage;
							}
							if (element.equipmentNumber.length < 1 || element.equipmentNumber.length > 6) {
								element.errorMessage += this.label.equipmentNumberMessage;
							}
							if (element.urrwinNumber.length > 9) {
								element.errorMessage += this.label.urrwinNumberMessage;
							}
							if (element.waybillNumber.length < 1 || element.waybillNumber.length > 6) {
								element.errorMessage += this.label.waybillNumberMessage;
							}

							if (element.urrwinDate) {
								if (new Date(element.urrwinDate) > new Date()) {
									element.errorMessage += this.label.urrwinDateMessage;
								}
							}
							urrwinMap.push({ key: element.rowNumber, value: element.urrwinNumber });
							waybillMap.push({ key: element.rowNumber, value: element.waybillNumber });
						});

						let urrwinDuplicates = this.duplicateCheck(urrwinMap);
						if (urrwinDuplicates.length > 0) {
							urrwinDuplicates.forEach((element) => {
								data[element].errorMessage += this.label.duplicateUrwinMessage;
							});
						}

						let waybillDuplicates = this.duplicateCheck(waybillMap);
						if (waybillDuplicates.length > 0) {
							waybillDuplicates.forEach((element) => {
								data[element].errorMessage += this.label.duplicateWaybillMessage;
							});
						}

						this.dataDisplayedOnDatatable = data;
						this.recordsToDisplay = data;
						this.parsedData = data;
						this.calculateClaimAmount(data);
						this.showSpinner = false;
					}
				})
				.catch((error) => {
					this.showSpinner = false;
					csx_cmp_logError("Csx_cmp_uploadShipmentRevRR", "validateInput", error, "");
				});
		}
	}

	duplicateCheck(data) {
		let duplicates = [];
		let duplicateMap = new Map();
		data.forEach((element, index) => {
			if (duplicateMap.has(element.value) && element.value) {
				duplicates.push(index);
			} else {
				duplicateMap.set(element.value, index);
			}
		});
		return duplicates;
	}



	calculateClaimAmount(data) {
		let totalClaimAmount = 0;
		data.forEach((element) => {
			if (element.claimAmount != "") {
				totalClaimAmount = totalClaimAmount + parseFloat(element.claimAmount);
			}
		});
		this.uploadShipment.uploadShipmentRevRR = data;
		this.totalClaimAmount = totalClaimAmount;
	}
	handleHeaderRecordsDisplay(event) {
		this.dataDisplayedOnDatatable = event.detail;
	}

	@api
	reset() {
		this.uploadedFile = null;
		this.uploadedFileName = "";
		this.dataDisplayedOnDatatable = [];
		this.recordsToDisplay = [];
		this.totalClaimAmount = 0;
		this.uploadShipment = {
			uploadShipmentRevRR: [],
			duplicateComments: "",
			sendEmail: false
		};
	}

	@api
	submitClaim() {
		let inputValidated = false;
		if (this.uploadShipment.uploadShipmentRevRR.length <= 0) {
			this.shipmentCheck = true;
			return null;
		}

		let errorLines = [];
		this.parsedData.forEach((element, key) => {
			if (element.errorMessage) {
				errorLines.push(key + 1);
			}
		});
		inputValidated = errorLines.length > 0 ? false : true;
		if (inputValidated) {
			let data = this.uploadShipment.uploadShipmentRevRR;
			return JSON.stringify(data);
		} else {
			let errorMessage = "Please fix the errors in line(s) " + errorLines.join(", ");
			this.displayToast("Error", errorMessage, "error");
		}
	}

	displayToast(title, message, variant) {
		let event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	backToSearch() {
		const callClaimSearch = new CustomEvent("backtosearch");
		this.dispatchEvent(callClaimSearch);
	}
}