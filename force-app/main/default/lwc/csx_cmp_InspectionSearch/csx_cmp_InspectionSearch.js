// standard imports
import { LightningElement, track, wire } from "lwc";
import { getObjectInfo, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// static resource
import csxStyle from "@salesforce/resourceUrl/CSX_CMP_CSXTheme";

// Apex controllers
import searchInspectionHeaderList from "@salesforce/apex/CSX_CMP_InspectionSearchController.searchInspectionHeaderList";
import fetchInspectionDetails from "@salesforce/apex/CSX_CMP_InspectionSearchController.fetchInspectionDetails";

// custom objects
import InspectionDetail_OBJECT from "@salesforce/schema/CSX_CMP_Inspection_Detail__c";
import InspectionHeader_OBJECT from "@salesforce/schema/CSX_CMP_Inspection_Header__c";

// custom labels
import futureDate from '@salesforce/label/c.CSX_CMP_FutureDate_Label';
import dateCriteria from '@salesforce/label/c.CSX_CMP_DateCriteria_Label';
import selectingInspection from "@salesforce/label/c.CSX_CMP_Select_Inspection";
import requiredFieldSearch from "@salesforce/label/c.CSX_CMP_Required_Field_To_Search";
import searchDataLimit from "@salesforce/label/c.CSX_CMP_SearchDataLimit";
import noDamagesFound from "@salesforce/label/c.CSX_CMP_No_damages";
import InspectionDetails from "@salesforce/label/c.CSX_CMP_InspectionDetails";
import InspectionDamages from "@salesforce/label/c.CSX_CMP_InspectionDamages";
import recordSizeLimit from "@salesforce/label/c.CSX_CMP_RecordLimit_Warning";

// error handling
import { csx_cmp_logError } from "c/csx_cmp_logError";

export default class Csx_cmp_InspectionSearch extends LightningElement {
	isLoaded = true;
	inputStartDate;
	startDate = "";
	endDate = "";
	buttonDisable = false;
	showEndDate = false;
	totalNumberOfRecords;
	shownoRecordError = false;
	sortBy = "nameLink";
	sortByDetail = "InspectionDetailURL";
	sortDirection = "asc";
	@track recordsToDisplay = [];
	@track paginatorRecords = [];
	@track detailPaginatorRecords = [];
	@track detailRecordToDisplay = [];
	@track sourcePicklistValues = [];
	showDownloadDetail = false;
	@track insepctionRoadPicklistValues = [];
	@track insepctionTypePicklistValues = [];
	errorReport = false;
	showCreateRequest = false;
	searchTotalRecords;
	totalDetailRecord;
	todayDate;
	showTable = false;
	paginationRecords;
	recordToDisplay = true;
	recordDetailToDisplay = false;
	showDamageButton = false;
	@track inspectionIds = [];
	showTableData = false;
	searchResult = false;
	searchresultDetail = false;
	showPaginatorValues = false;
	showInspectionDetail = false;
	showInsDetailExport = true;
	showInspectionPaginator = false;
	recordIdData;
	@track inspectionHeaderSelectedIds = [];
	showDetailButton = false;
	validStartDate;
	validEndDate;
	startDateValue;
	endDateValue;
	exCleanException = true;
	openExcelComponent = false;
	openExcelComponentDetail = false;
	librariesLoaded = false;
	librariesLoadedDetail = false;
	exportFileName = "InspectionSearchResults.xlsx";
	exportFileNameDetail = "InspectionDetailResults.xlsx";
	xlsHeaderDetail = [];
	xlsHeader = [];
	workSheetNameList = [];
	workSheetNameListDetail = [];
	xlsData = [];
	xlsDataDetail = [];
	checked = false;
	@track selectedRow = [];
	detailRecordCount;
	@track recordIdModal = [];
	isSpinner = false;
	openDetailExcelComponent = false;
	pageSize = 10;
	totalPage = 0;
	@track items = [];
	totalRecountCount = 0;
	@track dataDetail = [];
	@track damageAreaPicklistValues = [];
	@track damageTypePicklistValues = [];
	@track damageSeverityPicklistValues = [];

	//16 May changes | Start
	@track inspectionData = {
		'source': '',
		'inspectionRoad': '',
		'inspectionType': '',
		'rampId': '',
		'damageArea': '',
		'damageType': '',
		'damageSeverity': '',
		'equipmentInitial': '',
		'equipmentNumber': '',
		'vinNumber': '',
		'startDate': '',
		'endDate': ''
	};
	//16 May changes | End

	//label for the different error messages and CSV file name
	label = {
		selectingInspection,
		requiredFieldSearch,
		noDamagesFound,
		InspectionDetails,
		InspectionDamages,
		searchDataLimit,
		recordSizeLimit,
		futureDate,
		dateCriteria
	};

	//for Insepection details coloumn
	@track inspectionHeaderColumns = [
		{
			label: "Insp Header ID",
			fieldName: "nameLink",
			type: "url",
			typeAttributes: { label: { fieldName: "Name" }, tooltip: "Go to detail page", target: "_blank" },
			sortable: "true",
			initialWidth: 160
		},
		{
			label: "VIN",
			fieldName: "CSX_CMP_VIN__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 150
		},
		{
			label: "Inspection Company",
			fieldName: "CSX_CMP_Inspection_Road__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 150
		},
		{
			label: "Inspection Date",
			fieldName: "CSX_CMP_Inspection_Date__c",
			hideDefaultActions: true,
			type: "date",
			typeAttributes: { timeZone: "UTC", year: "numeric", month: "numeric", day: "numeric" },
			sortable: "true",
			initialWidth: 130
		},
		{
			label: "Inspection Type",
			fieldName: "CSX_CMP_Inspection_Report_Type__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 120
		},
		{
			label: "Equipment Initial",
			fieldName: "CSX_CMP_Equipment_Initial__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 125
		},
		{
			label: "Car/Equipment Number",
			fieldName: "CSX_CMP_Equipment_Number__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 163
		},
		{
			label: "Source",
			fieldName: "CSX_CMP_Source__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 115
		},
		{
			label: "Ramp ID",
			fieldName: "CSX_CMP_Ramp_Id__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 120
		},
		{
			label: "Manufacturer",
			fieldName: "CSX_CMP_Manufacturer__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 120
		},
		{
			label: "Driver Email",
			fieldName: "CSX_CMP_Driver_Email__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 180
		},
		{
			label: "Driver Name",
			fieldName: "CSX_CMP_Driver_Name__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 125
		},
		{
			label: "Driver Company",
			fieldName: "CSX_CMP_Haulaway_Company__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 130
		},
		{
			label: "Terminal Name",
			fieldName: "CSX_CMP_Terminal_Name__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 130
		},
		{
			label: "Previous Damage Indicator",
			fieldName: "CSX_CMP_Previous_Damage_Indicator__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 185
		},
		{
			label: "Reminder Indicator",
			fieldName: "CSX_CMP_Reminder_Indicator__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 135
		},
		{
			label: "Comments",
			fieldName: "CSX_CMP_Haulaway_Comments__c",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 110
		}
	];

	//for Inspection Header records coloummn
	@track inspectionDetailColumns = [
		{
			label: "Insp Detail ID",
			fieldName: "inspectionDetailURL",
			type: "url",
			typeAttributes: {
				label: { fieldName: "inspectionDetailId" },
				tooltip: "Go to detail page",
				target: "_blank"
			},
			sortable: "true",
			initialWidth: 150
		},
		{
			label: "Insp Header ID",
			fieldName: "inspectionHeaderURL",
			type: "url",
			typeAttributes: {
				label: { fieldName: "inspectionHeaderId" },
				tooltip: "Go to detail page",
				target: "_blank"
			},
			sortable: "true",
			initialWidth: 150
		},
		{ label: "VIN", fieldName: "vinNumber", type: "text", sortable: "true", initialWidth: 150 },
		{
			label: "Inspection Company",
			fieldName: "inspectionRoad",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 145
		},
		{
			label: "Inspection Date",
			fieldName: "inspectionDate",
			hideDefaultActions: true,
			type: "date",
			typeAttributes: { timeZone: "UTC", year: "numeric", month: "numeric", day: "numeric" },
			sortable: "true",
			initialWidth: 160
		},
		{
			label: "Inspection Type",
			fieldName: "inspectionType",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 145
		},
		{
			label: "Damage Area",
			fieldName: "damageArea",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 140
		},
		{
			label: "Damage Type",
			fieldName: "damageType",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 140
		},
		{
			label: "Damage Severity",
			fieldName: "damageSeverity",
			hideDefaultActions: true,
			type: "text",
			sortable: "true",
			initialWidth: 165
		}
	];

	//generic style class to implement and provide styling
	stylePath = csxStyle;
	constructor() {
		super();
		Promise.all([loadStyle(this, `${this.stylePath}/css3/styles.css`)]);
	}

	//to fetch Inspection Header record Type for picklist values
	@wire(getObjectInfo, { objectApiName: InspectionHeader_OBJECT })
	InspectionHeaderInfo;

	//to fetch Inspection Detail record Type for picklist values
	@wire(getObjectInfo, { objectApiName: InspectionDetail_OBJECT })
	InspectionDetailInfo;


	@wire(getPicklistValuesByRecordType, { objectApiName: InspectionHeader_OBJECT, recordTypeId: '$InspectionDetailInfo.data.defaultRecordTypeId', })
	objectInfo({ data, error }) {
		console.log('data:', data);
		console.log('error:', error);
		if (data) {
			let result = data.picklistFieldValues;
			this.assignPicklistValuesHeader(result);
		} else if (error) {
			csx_cmp_logError('Csx_cmp_InspectionSearch', 'objectInfo', error, '');
		}
	}

	@wire(getPicklistValuesByRecordType, { objectApiName: InspectionDetail_OBJECT, recordTypeId: '012000000000000AAA', })
	objectInfoDetail({ data, error }) {
		if (data) {
			let result = data.picklistFieldValues;
			this.assignPicklistValuesDetail(result);
		} else if (error) {
			csx_cmp_logError('Csx_cmp_InspectionSearch', 'objectInfoDetail', error, '');
		}
	}

	assignPicklistValuesHeader(result) {
		let sourceValues = result.CSX_CMP_Source__c;
		let sourceOptions = [];
		sourceValues.values.forEach(key => {
			sourceOptions.push({ label: key.label, value: key.value });
		});
		this.sourcePicklistValues = sourceOptions;

		let roadValues = result.CSX_CMP_Inspection_Road__c;
		let roadOptions = [];
		roadValues.values.forEach(key => {
			roadOptions.push({ label: key.label, value: key.value });
		});
		this.insepctionRoadPicklistValues = roadOptions;

		let typeValues = result.CSX_CMP_Inspection_Report_Type__c;
		let typeOptions = [];
		typeValues.values.forEach(key => {
			typeOptions.push({ label: key.label, value: key.value });
		});
		this.insepctionTypePicklistValues = typeOptions;
	}

	assignPicklistValuesDetail(result) {
		let areaValues = result.CSX_CMP_Damage_Area__c;
		let areaOptions = [];
		areaValues.values.forEach(key => {
			areaOptions.push({ label: key.label, value: key.value });
		});
		this.damageAreaPicklistValues = areaOptions;

		let typeValues = result.CSX_CMP_Damage_Type__c;
		let typeOptions = [];
		typeValues.values.forEach(key => {
			typeOptions.push({ label: key.label, value: key.value });
		});
		this.damageTypePicklistValues = typeOptions;

		let severityValues = result.CSX_CMP_Damage_Severity__c;
		let severityOptions = [];
		severityValues.values.forEach(key => {
			severityOptions.push({ label: key.label, value: key.value });
		});
		this.damageSeverityPicklistValues = severityOptions;
	}

	//set default from and to date values , while loading the component
	connectedCallback() {
		let newDateOptions = {
			year: "numeric",
			month: "2-digit",
			day: "2-digit"
		};
		let today = new Date();
		let curyear = today.getFullYear();
		let curyearMonth = today.getMonth() + 1;
		let curyearDay = today.getDate();
		let lastMon = curyearMonth - 1;

		if (curyearMonth == 2 && curyearDay == 29) {
			curyearDay = 28;
		}
		let lastMonth =
			("0000" + curyear.toString()).slice(-4) + "-" + ("00" + lastMon.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
		let todayy =
			("0000" + curyear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);

		this.startDateValue = lastMonth;
		this.endDateValue = today;
		this.currentDate = todayy.toLocaleString("en-US", newDateOptions);

		//16 May changes | Start
		this.inspectionData.endDate = this.currentDate;
		this.inspectionData.startDate = lastMonth.toLocaleString("en-US", newDateOptions);
		//16 May changes | End
	}

	//16 May Changes | Start

	handleInputChange(event) {
		try {
			this.inspectionData[event.target.name] = event.target.value;
			this.buttonDisable = false;
			const changedInputField = event.target;
			changedInputField.classList.add("highlight");
			if (this.inspectionData.startDate) {
				this.startDateValue = this.inspectionData.startDate;
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
						inputDate.setCustomValidity(this.label.futureDate);//'From Date cannot be in future'
						this.endDate = '';
						this.template.querySelector('[data-id="End_Date"]').value = '';
						this.showEndDate = false;
						this.errorReport = true;
					} else {
						inputDate.setCustomValidity("");
						this.showEndDate = false;
						this.errorReport = false;
						if (this.endDate) {
							let endDateValue = new Date(this.endDate);
							if (this.endDate && endDateValue < this.inputStartDate) {
								inputDate.setCustomValidity(this.label.dateCriteria);//'To date must be after From date'
								this.errorReport = true;
							} else {
								inputEndDate.setCustomValidity("");
								inputEndDate.reportValidity();
								this.errorReport = false;
							}
						}
					}
					inputDate.reportValidity();
				}
			}

			if (this.inspectionData.endDate) {
				let inputEndDate = this.template.querySelector('[data-id="End_Date"]');
				let inputDate = this.template.querySelector('[data-id="Start_Date"]');
				this.endDateValue = this.inspectionData.endDate;
				let dateValue = inputEndDate.value;
				let inputDateValue = new Date(dateValue);
				this.inputDate = new Date(inputDate.value);
				this.inputEndDate = new Date(inputEndDate.value);
				if (this.inputEndDate && inputDateValue < this.inputDate) {
					inputEndDate.setCustomValidity(this.label.dateCriteria);
					this.errorReport = true;
				} else {
					inputEndDate.setCustomValidity("");
					inputDate.reportValidity();
					inputEndDate.reportValidity();
					this.errorReport = false;
				}
				inputEndDate.reportValidity();
			}

			//VIN Number validaton
			const vinPattern = /^[A-Za-z0-9]+$/;
			let inputVinNumber = this.template.querySelector('[data-id="vinNumber"]');
			if(this.inspectionData.vinNumber){
              
                console.log('inputVinNumber :',inputVinNumber);
                if(inputVinNumber.value && (inputVinNumber.value.length == 8 || inputVinNumber.value.length == 17) && vinPattern.test(inputVinNumber.value)){
                    console.log('inputVinNumber if:',inputVinNumber);
                    inputVinNumber.setCustomValidity("");
                    this.errorReport = false;
					inputVinNumber.reportValidity();
                }else{
                    console.log('inputVinNumber else:',inputVinNumber);
                    inputVinNumber.setCustomValidity('VIN number must be either 8 or 17 characters long.');
                    this.errorReport = true;
					inputVinNumber.reportValidity();
                }  
            } else{
                this.isValidationError = false;
                inputVinNumber.setCustomValidity("");
                inputVinNumber.reportValidity();
            }
			

		} catch (ex) {
			this.isLoaded = true;
			let parameters = JSON.stringify('inside detail error:' + this.inspectionData);
			csx_cmp_logError('Csx_cmp_InspectionSearch', 'handleInputChange', ex, parameters);
		}
	}
	//16 May Changes | END

	handleExCleanInsepction(event) {
		this.exCleanException = event.target.checked;
		this.falseChecked = !event.target.checked;
		console.log('this.exCleanException: '+this.exCleanException);
	}

	handleEnter(event) {
		if (event.keyCode === 13 && this.buttonDisable == false) {
			this.handleSearchClick();
		}
	}

	//export records in CSV format for Inspection Header records
	dowloadRecords() {
		this.openExcelComponent = true;
		this.openExcelComponentDetail = false;

		if (this.librariesLoaded) {
			this.getHeaderExport();
		}
	}
	//export Inspection detail record in CSV format
	donwnloadDetailRecord() {
		this.openExcelComponent = false;
		this.openExcelComponentDetail = true;
		this.showDownloadDetail = true;

		if (this.librariesLoadedDetail) {
			this.getDetailExport();
		}
	}
	// export Inspection detail record in CSV format
	excelLibraryLoadedDetail() {
		this.librariesLoadedDetail = true;
		this.getDetailExport();
	}
	//export records in CSV format for Inspection Header records
	excelLibraryLoaded() {
		this.librariesLoaded = true;
		this.getHeaderExport();
	}
	// export Inspection detail record in CSV format
	getDetailExport() {
		try {
			let listForExportDetailRecord = this.detailRecordToDisplay.map(function (obj) {
				let tmp = {};
				tmp["Insp detail Id"] = obj.inspectionDetailId;
				tmp["Insp Header Id"] = obj.inspectionHeaderId;
				tmp["VIN"] = obj.vinNumber;
				tmp["Inspection Company"] = obj.inspectionRoad;
				tmp["Inspection Date"] = obj.inspectionDate;
				tmp["Inspection Type"] = obj.inspectionType;
				tmp["Damage Area"] = obj.damageArea;
				tmp["Damage Type"] = obj.damageType;
				tmp["Damage Severity"] = obj.damageSeverity;
				return tmp;
			});
			this.xlsFormatterDetail(listForExportDetailRecord, "DetailRecords");
		} catch (error) {
			let parameters = JSON.stringify(this.xlsFormatterDetail);
			csx_cmp_logError("csx_cmp_InspectionSearch", "getDetailExport", error, parameters);
		}
	}
	// excel export method for Inspection detail
	xlsFormatterDetail(data, sheetName) {
		try {
			let Header = Object.keys(data[0]);
			this.xlsHeaderDetail.push(Header);
			this.workSheetNameListDetail.push(sheetName);
			this.xlsDataDetail.push(data);
			this.template.querySelector("c-csx_cmp_excelexport").download();
			this.xlsHeaderDetail = [];
			this.workSheetNameListDetail = [];
			this.xlsDataDetail = [];
		} catch (error) {
			let parameters = JSON.stringify("inside detail error:" + this.xlsFormatterDetail);
			csx_cmp_logError("csx_cmp_InspectionSearch", "xlsFormatterDetail", error, parameters);
		}
	}
	//export records in CSV format for Inspection Header records
	getHeaderExport() {
		try {
			let listForExport = this.recordsToDisplay.map(function (obj) {
				let tmp = {};
				tmp["Insp Header Id"] = obj.Name;
				tmp["VIN"] = obj.CSX_CMP_VIN__c;
				tmp["Inspection Company"] = obj.CSX_CMP_Inspection_Road__c;
				tmp["Inspection Date"] = obj.CSX_CMP_Inspection_Date__c;
				tmp["Inspection Type"] = obj.CSX_CMP_Inspection_Report_Type__c;
				tmp["Equipment Initial"] = obj.CSX_CMP_Equipment_Initial__c;
				tmp["Source"] = obj.CSX_CMP_Source__c;
				tmp["Car/Equipment Number"] = obj.CSX_CMP_Equipment_Number__c;
				tmp["Ramp Id"] = obj.CSX_CMP_Ramp_Id__c;
				tmp["Manufacturer"] = obj.CSX_CMP_Manufacturer__c;
				tmp["Driver Email"] = obj.CSX_CMP_Driver_Email__c;
				tmp["Driver Name"] = obj.CSX_CMP_Driver_Name__c;
				tmp["Driver Company"] = obj.CSX_CMP_Haulaway_Company__c;
				tmp["Terminal Name"] = obj.CSX_CMP_Terminal_Name__c;
				tmp["Previous Damage Indicator"] = obj.CSX_CMP_Previous_Damage_Indicator__c;
				tmp["Reminder Indicator"] = obj.CSX_CMP_Reminder_Indicator__c;
				tmp["Comments"] = obj.CSX_CMP_Haulaway_Comments__c;

				return tmp;
			});
			this.xlsFormatter(listForExport, "HeaderRecords");
		} catch (error) {
			let parameters = JSON.stringify(this.xlsFormatter);
			csx_cmp_logError("csx_cmp_InspectionSearch", "getHeaderExport", error, parameters);
		}
	}
	//export records in CSV format for Inspection Header records
	xlsFormatter(data, sheetName) {
		try {
			let Header = Object.keys(data[0]);
			this.xlsHeader.push(Header);
			this.workSheetNameList.push(sheetName);
			this.xlsData.push(data);
			this.template.querySelector("c-csx_cmp_excelexport").download();
			this.xlsHeader = [];
			this.workSheetNameList = [];
			this.xlsData = [];
		} catch (error) {
			let parameters = JSON.stringify(this.workSheetNameList);
			csx_cmp_logError("csx_cmp_InspectionSearch", "xlsFormatter", error, parameters);
		}
	}

	//get records to display in Lightning data table from the paginator for Inspection Header
	handleHeaderRecordsDisplay(event) {
		this.paginatorRecords = event.detail;
	}
	//get records to display in Lightning data table from the paginator for Inspection Detail
	handleDetailRecordsDisplay(event) {
		try {
			this.detailPaginatorRecords = event.detail;
			this.isSpinner = true;
		} catch (ex) {
			csx_cmp_logError('Csx_cmp_InspectionSearch', 'handleDetailRecordsDisplay', ex, '');
		}
	}

	//reset everthing (varaible, data etc)
	handleResetClick() {
		//16 May changes | End
		this.inspectionData = {
			'source': '',
			'inspectionRoad': '',
			'inspectionType': '',
			'rampId': '',
			'damageArea': '',
			'damageType': '',
			'damageSeverity': '',
			'equipmentInitial': '',
			'equipmentNumber': '',
			'vinNumber': '',
			'startDate': '',
			'endDate': '',
			'excludeCleanInspectionData':''
		};
		//16 May Changes | End
		this.exCleanException = false;
		this.buttonDisable = true;
		this.recordToDisplay = false;
		this.showDamageButton = false;
		this.recordDetailToDisplay = false;
		this.showInspectionDetail = false;
		this.showInsDetailExport = true;
		this.showInspectionPaginator = false;
		this.showTableData = false;
		this.showPaginatorValues = false;
		this.inspectionIds = [];
		this.shownoRecordError = false;
		this.recordsToDisplay = [];
		this.inspectionHeaderSelectedIds = [];
		this.detailRecordToDisplay = [];
		this.showDetailButton = false;

		this.isLoaded = true;
		this.errorReport = false;
		this.showDownloadDetail = false;
		this.currentDate = "";
		this.showEndDate = true;

		this.startDateValue = "";
		this.endDateValue = "";
		this.template.querySelectorAll("lightning-datatable").forEach((each) => {
			each.selectedRows = [];
		});
		if (!this.showCreateRequest) {
			this.template.querySelectorAll("lightning-input").forEach((each) => {
				each.value = "";
				each.setCustomValidity("");
				each.classList.remove("highlight");
				each.reportValidity();
			});
			this.template.querySelectorAll("lightning-combobox").forEach((each) => {
				each.value = "";
				each.classList.remove("highlight");
			});
		}
	}

	//get data from the Server side for Inspection Header
	handleSearchClick() {
		this.isLoaded = false;
		this.shownoRecordError = false;
		this.inspectionIds = [];
		this.showTableData = false;
		this.showDetailButton = false;
		this.detailRecordToDisplay = [];
		this.showInspectionDetail = false;
		this.showInsDetailExport = true;
		this.paginatorRecords = [];
		this.recordsToDisplay = [];
		this.searchResult = false;
		this.totalNumberOfRecords = "";
		this.openExcelComponent = false;
		this.openExcelComponentDetail = false;
		//16 May Changes | Start

		let insepectionInfoMap = new Map();
		insepectionInfoMap = Object.keys(this.inspectionData).reduce((map, key) => {

			if (this.inspectionData[key]) {
				map.set(key, this.inspectionData[key]);
			}
			return map;
		}, new Map());

		let isValid = true;
		let inputFields = this.template.querySelectorAll("lightning-input");
		inputFields.forEach((field) => {
			if (!field.checkValidity()) {
				isValid = false;
				return;
			}
		});

		if (!isValid) {
			/*let selectionIssue = new ShowToastEvent({
				title: 'Error',
				message: 'Please enter valid input',
				variant: "error"
			});
			this.dispatchEvent(selectionIssue);*/
			this.buttonDisable = true;
			this.isLoaded = true;
			return;
		}

		let obj = Object.fromEntries(insepectionInfoMap);
		let inspectionDataStringCon = JSON.stringify(obj);
		if (inspectionDataStringCon != '{}') {
			try {
				this.buttonDisable = false;
				this.recordToDisplay = true;

				searchInspectionHeaderList({ inspectionSearchParameters: inspectionDataStringCon,exCleanException:this.exCleanException})
					.then((data) => {
						this.isLoaded = true;
						if (data) {
							// if (data.length >= this.label.searchDataLimit) {
							// 	const selectionHeaderIssue = new ShowToastEvent({
							// 		message: this.label.recordSizeLimit,
							// 		duration: "3000",
							// 		variant: "warning"
							// 	});
							// 	this.dispatchEvent(selectionHeaderIssue);
							// 	return;
							// }
							this.searchTotalRecords = data.length;
							this.showPaginatorValues = true;
							this.showTableData = true;
							this.searchResult = true;
							this.totalNumberOfRecords = data.length;
							this.showTable = true;
							if (data.length > 0) {
								let tempRecs = [];
								data.forEach((record) => {
									let tempRec = Object.assign({}, record);
									tempRec.nameLink = "/" + tempRec.Id;
									tempRecs.push(tempRec);
									this.inspectionIds.push(tempRec.Id);
								});

								this.items = tempRecs;
								this.totalRecountCount = tempRecs.length;
								this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
								this.dataDetail = this.items.slice(0, this.pageSize);
								this.recordsToDisplay = tempRecs;
								this.showDamageButton = true;
								this.showDetailButton = true;

								if (this.searchTotalRecords === 1) {
									try {
										this.inspectionHeaderSelectedIds = [];
										for (const obj of this.inspectionIds) {
											this.inspectionHeaderSelectedIds.push(obj);
										}
										this.showInspectionDetail = true;
										this.showInsDetailExport = false;
										this.displayDamageDetails();
									} catch (error) {
										let parameters = "";
										csx_cmp_logError("csx_cmp_InspectionSearch", "handleSearchClick", error, parameters);
									}
								}
							} else {
								this.recordsToDisplay = [];
								this.paginationRecords = [];
								this.showTable = false;
								this.shownoRecordError = true;
								this.showTableData = false;
								this.showDetailButton = false;
							}
						}
					})
					.catch((error) => {
						this.isLoaded = true;
						if (error.body.message.includes(this.label.recordSizeLimit)) {
							let selectionHeaderIssue = new ShowToastEvent({
								message: error.body.message,
								duration: "3000",
								variant: "warning"
							});
							this.dispatchEvent(selectionHeaderIssue);
						} else {
							let parameters = "";
							csx_cmp_logError("csx_cmp_InspectionSearch", "handleSearchClick", error, parameters);
							this.paginationRecords = [];
						}
					});
			} catch (ex) {
				csx_cmp_logError("csx_cmp_InspectionSearch", "handleSearchClick", ex, '');
			}
		} else {
			const selectionIssue = new ShowToastEvent({
				message: this.label.requiredFieldSearch,
				duration: "5000",
				variant: "error"
			});
			this.dispatchEvent(selectionIssue);
			this.buttonDisable = true;
		}

		//16 May Changes | END
	}
	//get data from the Server side for Inspection Details
	displayDamageDetails() {
		this.detailRecordToDisplay = [];
		if (this.searchTotalRecords === 1) {
		} else {
			this.inspectionHeaderSelectedIds = [];
		}
		this.showInspectionDetail = false;
		this.showInsDetailExport = true;
		this.detailPaginatorRecords = [];
		this.searchResultDetail = false;
		this.openExcelComponent = false;
		this.openExcelComponentDetail = false;

		if (this.searchTotalRecords === 1) {
			this.showDetailButton = false;
		}
		this.recordDetailToDisplay = true;
		if (this.searchTotalRecords > 1) {
			let sel = this.template.querySelector("lightning-datatable");
			let selected = sel.getSelectedRows();
			for (const element of selected) {
				this.inspectionHeaderSelectedIds.push(element.Id);
			}
		}
		if (!this.errorReport) {
			if (
				this.inspectionHeaderSelectedIds != undefined &&
				this.inspectionHeaderSelectedIds != null &&
				this.inspectionHeaderSelectedIds != ""
			) {
				this.showInspectionPaginator = true;
				fetchInspectionDetails({
					inspectionHeaderIds: this.inspectionHeaderSelectedIds,
					exCleanException: this.exCleanException
				})
					.then((data) => {
						if (data) {
							this.showInsDetailExport = false;
							this.showInspectionDetail = true;
							this.detailRecordCount = data.length;
							this.searchResultDetail = true;
							if (data.length > 0) {
								let tempRecs = [];
								data.forEach((record) => {
									let tempRec = Object.assign({}, record);
									tempRec.inspectionDetailURL = "/" + tempRec.inspectionDetailURL;
									tempRec.inspectionHeaderURL = "/" + tempRec.inspectionHeaderURL;
									tempRecs.push(tempRec);
								});

								//pagination logic
								this.detailRecordToDisplay.push(...tempRecs);
								this.isSpinner = true;
							} else {
								this.showInspectionDetail = false;
								this.showInsDetailExport = true;
								this.showInspectionPaginator = false;
								const selectionHeaderIssue = new ShowToastEvent({
									message: this.label.noDamagesFound,
									duration: "5000",
									variant: "warning"
								});
								this.dispatchEvent(selectionHeaderIssue);
							}
						}
					})
					.catch((error) => {
						let parameters = "";
						csx_cmp_logError("csx_cmp_InspectionSearch", "displayDamageDetails", error, parameters);
						this.paginationRecords = [];
					});
			} else {
				const selectionHeaderIssue = new ShowToastEvent({
					message: this.label.selectingInspection,
					duration: "5000",
					variant: "error"
				});
				this.dispatchEvent(selectionHeaderIssue);
			}
		}
	}

	//sorthing logic for the inspection header table
	doSortingDetail(event) {
		let sortbyField = event.detail.fieldName;
		if (sortbyField === "InspectionDetailURL") {
			this.sortByDetail = "inspectionDetailId";
		}
		if (sortbyField === "InspectionHeaderURL") {
			this.sortByDetail = "inspectionHeaderId";
		} else {
			this.sortByDetail = sortbyField;
		}
		this.sortDirection = event.detail.sortDirection;
		this.sortDataDetail(this.sortByDetail, this.sortDirection);
		this.sortByDetail = sortbyField;
	}
	//sorthing logic for the inspection header table
	doSorting(event) {
		let sortbyField = event.detail.fieldName;
		if (sortbyField === "nameLink") {
			this.sortBy = "Name";
		} else {
			this.sortBy = sortbyField;
		}
		this.sortDirection = event.detail.sortDirection;
		this.sortData(this.sortBy, this.sortDirection);
		this.sortBy = sortbyField;
	}
	//sorthing logic for the inspection header table
	sortData(fieldName, sortDirection) {
		let sortResult = Object.assign([], this.recordsToDisplay);
		this.recordsToDisplay = sortResult.sort(function (a, b) {
			a = a[fieldName] ? a[fieldName] : ""; // handling null values
			b = b[fieldName] ? b[fieldName] : "";
			if (a < b) {
				return sortDirection === "asc" ? -1 : 1;
			} else if (a > b) {
				return sortDirection === "asc" ? 1 : -1;
			} else {
				return 0;
			}
		});
		if (this.searchResult) {
			this.searchResult = false;
		} else {
			this.searchResult = true;
		}
	}
	//sorthing logic for the inspection detail table
	sortDataDetail(fieldName, sortDirection) {
		let sortResult = Object.assign([], this.detailRecordToDisplay);
		this.detailRecordToDisplay = sortResult.sort(function (a, b) {
			a = a[fieldName] ? a[fieldName] : ""; // handling null values
			b = b[fieldName] ? b[fieldName] : "";
			if (a < b) {
				return sortDirection === "asc" ? -1 : 1;
			} else if (a > b) {
				return sortDirection === "asc" ? 1 : -1;
			} else {
				return 0;
			}
		});
		if (this.searchResultDetail) {
			this.searchResultDetail = false;
		} else {
			this.searchResultDetail = true;
		}
	}
	//fetch record for modal view container to show the Inspection Damages records
	//fetch Row detail and trying to reset the selected record while reset button.
	handleRowSelection(event) {
		try {
			this.selectedRow = event.detail.selectedRows;
		} catch (error) {
			let parameters = "";
			csx_cmp_logError("csx_cmp_InspectionSearch", "handleRowSelection", error, parameters);
		}
	}
}