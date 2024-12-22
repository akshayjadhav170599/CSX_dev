import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import search from '@salesforce/label/c.CSX_CMP_SearchLabel';
import futureDate from '@salesforce/label/c.CSX_CMP_FutureDate_Label';
import EndDate from '@salesforce/label/c.CSX_CMP_EndDate_Label';
import AmountLimit from '@salesforce/label/c.CSX_CMP_AmountLimit_Label';
import LDR_OBJECT from '@salesforce/schema/CSX_CMP_LD_Report__c';
import LDRTypePicklist from '@salesforce/schema/CSX_CMP_LD_Report__c.CSX_CMP_LD_Type__c';
import LDRStatusPicklist from '@salesforce/schema/CSX_CMP_LD_Report__c.CSX_CMP_Incident_Status__c';
import getStates from '@salesforce/apex/CSX_CMP_LDRSearchController.getStates';
import getLdrRecords from '@salesforce/apex/CSX_CMP_LDRSearchController.getLdrRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { csx_cmp_logError } from 'c/csx_cmp_logError';
import recordSizeLimit from '@salesforce/label/c.CSX_CMP_RecordLimit_Warning';
import searchDataLimit from '@salesforce/label/c.CSX_CMP_SearchDataLimit';
import getRoles from '@salesforce/apex/CSX_CMP_ClaimCreationHelper.getRoleAccessConfiguration';

export default class csx_cmp_ldrSearch extends LightningElement {

    label = {
        reset, search, futureDate, EndDate, AmountLimit, recordSizeLimit, searchDataLimit
    };
    librariesLoaded = false;
    xlsHeader = []; // store all the headers of the the tables
    workSheetNameList = [];
    xlsData = [];
    excelFileName = 'L&DSearchResults.xlsx';
    sortByDetail = 'ldrID';
    @track recordsToDisplay = [];
    @track records = [];
    @track statusOptions = [];
    @track typeOptions = [];
    errorReport = false;
    searchResults = false;
    EquipmentPopup = false;
    @track detailRecordToDisplay = [];
    shownoRecordError = false;
    isLoaded = true;
    isValidationError = false;
    @track lndData = {
        'reportNumber': '',
        'reportType': '',
        'startDate': '',
        'endDate': '',
        'incidentMgr': '',
        'incidentLocation': '',
        'rarNumber': '',
        'status': '',
        'equipmentInitial': '',
        'equipmentNumber': '',
        'vinNumber': '',
        'stcc': '',
        'salvage': '',
        'salvorName': '',
        'salvageAmountFrom': '',
        'salvageAmountTo': '',
        'region': '',
        'state': '',
        'shipper': ''
    };
    @track lndData2 = {
        'reportNumber': '',
        'reportType': '',
        'startDate': '',
        'endDate': '',
        'incidentMgr': '',
        'incidentLocation': '',
        'rarNumber': '',
        'status': '',
        'equipmentInitial': '',
        'equipmentNumber': '',
        'vinNumber': '',
        'stcc': '',
        'salvage': '',
        'salvorName': '',
        'salvageAmountFrom': '',
        'salvageAmountTo': '',
        'region': '',
        'state': '',
        'shipper': ''
    };
    disableSearchButton = false;
    disableResetButton = false;
    showTableData = false;
    inputStartDate;
    sortDirection = 'asc';
    startDateValue;
    openExcelComponent = false;
    endDateValue;
    endDate = '';
    showEndDate = false;
    salvageAmountFromFloat;
    salvageAmountToFloat;
    @track equipListSelected = [];
    @track stateOptions = [];
    @track regionOptions = [];
    displayCreateNew = false;
    equipInitial;
    equipNum

    equipmentColoumns = [
        { label: "Equipment ID", hideDefaultActions: true,fieldName: 'equipmentId', type: 'url', typeAttributes: { label: { fieldName: 'equipmentName' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 140 },
        { label: "Shipper", fieldName: 'shipper', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 210 },
        { label: "Consignee", fieldName: 'consignee', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 160 },
        { label: "STCC", fieldName: 'stcc', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 80 },
    ]
    ldrButtonColumns = [
        {
            type: "button", label: 'View', initialWidth: 98, typeAttributes: {
                label: 'Equipment',
                name: 'EquipmentDetails',
                title: 'EquipmentDetails',
                disabled: false,
                value: 'view',
                iconPosition: 'right'
            }
        },
        {
            type: "button", label: 'View', initialWidth: 98, typeAttributes: {
                label: 'Documents',
                name: 'DocumentDetails',
                title: 'DocumentDetails',
                disabled: false,
                value: 'view',
                iconPosition: 'right'
            }
        }
    ]

    ldrColumns = [
        { label: "L&D #", fieldName: 'ldrID', type: 'url', typeAttributes: { label: { fieldName: 'reportNumber' }, tooltip: 'Go to detail page', target: '_blank' }, sortable: "true", initialWidth: 100 },
        { label: "L&D Status", fieldName: 'status', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 100 },
        { label: "RAR #", fieldName: 'rarNumber', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 90 },
        { label: "Incident Date", fieldName: 'incidentDate', hideDefaultActions: true, type: 'date', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }, sortable: "true", initialWidth: 120 },
        { label: "Incident Location", fieldName: 'incidentLocation', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 230 },
        { label: "Incident Region", fieldName: 'incidentRegion', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 120 },
        { label: "Equipment ID", fieldName: 'equipmentName', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 110, wrapText: true },
        { label: "Shipper", fieldName: 'shipper', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 170 },
        { label: "Consignee", fieldName: 'consignee', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 170 },
        { label: "STCC", fieldName: 'stcc', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 80 },
        //{ label: "equipmentData", fieldName: 'equipmentsWrapList', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 120 },
        { label: "Completed Date", fieldName: 'completedDate', typeAttributes: { timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric' }, hideDefaultActions: true, type: 'date', sortable: "true", initialWidth: 120 },
        { label: "Reported By", fieldName: 'reportedBy', hideDefaultActions: true, type: 'text', sortable: "true", initialWidth: 120 }
    ];

    @wire(getStates)
    wiredStateAndCityData({ data, error }) {
        if (data) {
            this.stateOptions = data.state;
            this.regionOptions = data.region;
            this.stateOptions = Object.values(data.state).map(state => ({
                label: state,
                value: state
            }));
            this.regionOptions = Object.values(data.region).map(region => ({
                label: region,
                value: region
            }));
        }
        if (error) {
            let parameters = data;
            csx_cmp_logError('csx_cmp_ldrSearch', 'wiredStateAndCityData', error, parameters);
        }
    }

    @wire(getRoles)
    wiredRoles({ data, error }) {
        if (data) {
            if (data.length > 0) {
                let response = JSON.parse(data);
                let metadata = response.roleAccessConfigList;
                if (metadata[0].CSX_CMP_Create_L_D_Reports__c) {
                    this.displayCreateNew = true;
                }
            }
        }
        else if (error) {
            console.log('ERROR=====>', JSON.stringify(error));
        }
    }

    openModal() {
        const callOpenModel = new CustomEvent('openmodal');
        this.dispatchEvent(callOpenModel);
    }
    connectedCallback() {
        let newDateOptions = { year: "numeric", month: "2-digit", day: "2-digit" };
        let today = new Date();
        let curyear = today.getFullYear();
        let curyearMonth = today.getMonth() + 1;
        let curyearDay = today.getDate();
        let lastYear = curyear - 1;
        if ((curyearMonth == 2) && (curyearDay == 29)) {
            curyearDay = 28;
        }
        let lastYearDisplay = ("0000" + lastYear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        let todayy = ("0000" + curyear.toString()).slice(-4) + "-" + ("00" + curyearMonth.toString()).slice(-2) + "-" + ("00" + curyearDay.toString()).slice(-2);
        this.lndData.startDate = lastYearDisplay.toLocaleString("en-US", newDateOptions);
        this.lndData.endDate = todayy.toLocaleString("en-US", newDateOptions);

    }

    //to fetch L&D Report record Type for picklist values
    @wire(getObjectInfo, { objectApiName: LDR_OBJECT })
    LDR_OBJECT;

    //fetch L&D type picklist values
    @wire(getPicklistValues, { recordTypeId: '$LDR_OBJECT.data.defaultRecordTypeId', fieldApiName: LDRTypePicklist })
    typeOption({ data, error }) {
        if (data) {
            this.typeOptions = data.values;
        }else if (error) {
            console.log('ERROR=====>', JSON.stringify(error));
        }
    }

    //fetch L&D status picklist values
    @wire(getPicklistValues, { recordTypeId: '$LDR_OBJECT.data.defaultRecordTypeId', fieldApiName: LDRStatusPicklist })
    statusOption({ data, error }) {
        if (data) {
            this.statusOptions = data.values;
        }else if (error) {
            console.log('ERROR=====>', JSON.stringify(error));
        }
    }

    get salvageOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ]
    }
    isModified(fieldName) {
        return this.lndData2[fieldName] !== this.lndData[fieldName];
    }

    handleInputChange(event) {
        try {
            this.lndData[event.target.name] = event.target.value;
            this.lndData2[event.target.name] = event.target.value;
            if (this.isModified(event.target.name)) event.currentTarget.classList.add('dirty-field');
            if (!this.isModified(event.target.name)) event.currentTarget.classList.remove('dirty-field');

            this.disableResetButton = false;
            this.disableSearchButton = false;
            let salvageAmountFrom = this.template.querySelector('[data-id="salvage_amount_from"]');
            let salvageAmountTo = this.template.querySelector('[data-id="salvage_amount_to"]');
            if (this.lndData.startDate) {
                this.startDateValue = this.lndData.startDate
                let inputDate = this.template.querySelector('[data-id="Start_Date"]');
                let inputEndDate = this.template.querySelector('[data-id="End_Date"]');

                if (this.startDateValue == null || this.startDateValue == "") {
                    this.endDate = '';
                    inputDate.value = '';
                    this.showEndDate = true;
                    inputDate.setCustomValidity("");
                    this.isValidationError = false;
                } else {
                    let dateValue = inputDate.value;
                    let inputDateValue = new Date(dateValue);
                    this.inputStartDate = inputDateValue;
                    let today = new Date();
                    if (this.inputStartDate && inputDateValue > today) {
                        inputDate.setCustomValidity(this.label.futureDate);
                        this.isValidationError = true;
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
                                inputDate.setCustomValidity(this.label.EndDate);
                                this.isValidationError = true;
                                this.errorReport = true;
                            } else {
                                inputEndDate.setCustomValidity("");
                                this.isValidationError = false;
                                inputEndDate.reportValidity();
                                this.errorReport = false;
                            }
                        }
                    }
                    inputDate.reportValidity();
                }
            }
            if (this.lndData.endDate) {
                let inputEndDate = this.template.querySelector('[data-id="End_Date"]');
                let inputDate = this.template.querySelector('[data-id="Start_Date"]');
                this.endDateValue = this.lndData.endDate;
                let dateValue = inputEndDate.value;
                let inputDateValue = new Date(dateValue);
                this.inputDate = new Date(inputDate.value);
                this.inputEndDate = new Date(inputEndDate.value);
                if (this.inputEndDate && inputDateValue < this.inputDate) {
                    inputEndDate.setCustomValidity(this.label.EndDate);
                    this.isValidationError = true;
                    this.errorReport = true;
                } else {
                    inputEndDate.setCustomValidity("");
                    inputDate.reportValidity();
                    inputEndDate.reportValidity();
                    this.errorReport = false;
                }
                inputEndDate.reportValidity();
            }
            this.salvageAmountFromFloat = parseFloat(salvageAmountFrom.value);
            this.salvageAmountToFloat = parseFloat(salvageAmountTo.value);
            if (this.salvageAmountToFloat) {
                if (this.salvageAmountFromFloat > this.salvageAmountToFloat) {
                    salvageAmountTo.setCustomValidity(this.label.AmountLimit);
                    this.isValidationError = true;
                } else {
                    salvageAmountTo.setCustomValidity('');
                }
                salvageAmountTo.reportValidity();
            }
            
            //VIN Number Validation
            const vinPattern = /^[A-Za-z0-9]+$/;
            let inputVinNumber = this.template.querySelector('[data-id="vinNumber"]');
            if(this.lndData.vinNumber){
               
                console.log('inputVinNumber :',inputVinNumber);
                if(inputVinNumber.value && (inputVinNumber.value.length == 8 || inputVinNumber.value.length == 17)  && vinPattern.test(inputVinNumber.value)){
                    console.log('inputVinNumber if:',inputVinNumber);
                    inputVinNumber.setCustomValidity("");
                    this.errorReport = false;
                    this.isValidationError = false;
                }
                else{
                    console.log('inputVinNumber else:',inputVinNumber);
                    inputVinNumber.setCustomValidity('VIN number must be either 8 or 17 characters long.');
                    this.errorReport = true;
                    this.isValidationError = true;
                }  
                inputVinNumber.reportValidity();
            }
            else{
                this.isValidationError = false;
                inputVinNumber.setCustomValidity("");
                inputVinNumber.reportValidity();
            }


            let equipInitial = this.template.querySelector('[data-id="equipInitial"]');
            let equipNumber = this.template.querySelector('[data-id="equipNumber"]');
            this.equipInitial = equipInitial.value;
            this.equipNum = equipNumber.value;

            if (this.equipInitial && /[^a-zA-Z]/.test(this.equipInitial)) {
                equipInitial.setCustomValidity('Only alphabet characters are allowed.');
                this.isValidationError = true;
            }
            if (event.key === 'Tab' && this.equipInitial == '') {
                equipInitial.setCustomValidity(''); // Clear any previous error message
                equipInitial.reportValidity(); // Report the validity state
            }
            if (this.equipInitial == '' || this.equipInitial == undefined) {
                equipInitial.setCustomValidity(''); // Clear any previous error message
                equipInitial.reportValidity(); // Report the validity state
            }
            else if (!(/[^a-zA-Z]/.test(this.equipInitial)) && this.equipInitial.length >= 2) {
                console.log('inside clear()');
                equipInitial.setCustomValidity(''); // Clear any previous error message
                equipInitial.reportValidity();
                this.isValidationError = false;
            }
            else if (this.equipInitial.length < 2) {
                console.log('inside equipment length: inner' + this.equipInitial.length);
                equipInitial.setCustomValidity('At least 2 alphabet characters are required.');
                this.isValidationError = true;
            }
    
            equipInitial.reportValidity();
    
            if (this.equipNum) {
                console.log(' this.equipNum: '+ this.equipNum);
                console.log('this.equipNum: '+ this.equipNum);
                if (!equipNumber.value || isNaN(equipNumber.value)) {
                    equipNumber.setCustomValidity('Only numeric values are allowed.');
                    console.log(' inside equipNumber.value: '+ equipNumber.value);
                    this.isValidationError = true;
                } else {
                    console.log('else: '+ this.equipNum);
                    equipNumber.setCustomValidity(''); // Clear any previous error message
                    equipNumber.reportValidity();
                    this.isValidationError = false;
                    // Proceed with your logic
                }
                equipNumber.reportValidity();
            }else{
                this.validation = false;
                equipNumber.setCustomValidity("");
                equipNumber.reportValidity();
            }


        }
        catch (ex) {
            this.isLoaded = true;
            let parameters = JSON.stringify('inside detail error:' + this.lndData);
            csx_cmp_logError('csx_cmp_ldrSearch', 'handleInputChange', ex, parameters);
        }
    }
    handleStatusValueChange(event) {
        this.disableResetButton = false;
        this.disableSearchButton = false;
        this.lndData[event.target.name] = event.detail.values;
    }

    handleEnter(event) {
        if (event.keyCode === 13) {
            this.handleSearchClick();
        }
    }

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
            this.isLoaded = true;
            let parameters = JSON.stringify('inside detail error:' + this.xlsFormatterDetail);
            csx_cmp_logError('csx_cmp_ldrSearch', 'xlsFormatterDetail', error, parameters);
        }
    }

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
            this.isLoaded = true;
            let parameters = JSON.stringify(this.workSheetNameList);
            csx_cmp_logError('csx_cmp_ldrSearch', 'xlsFormatter', error, parameters);
        }
    }

    handleResetClick() {
        this.shownoRecordError = false;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.setCustomValidity('');
            element.reportValidity();
        });
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clearSelectedValues();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').clear();
        this.template.querySelector('c-csx_cmp_multi-select-dropdown').options = this.statusOptions;
        this.disableResetButton = true;
        this.searchResults = false;
        this.showTableData = false;
        this.disableSearchButton = true;
        this.isLoaded = true;
        this.lndData = {
            'reportNumber': '',
            'reportType': '',
            'startDate': '',
            'endDate': '',
            'incidentMgr': '',
            'incidentLocation': '',
            'rarNumber': '',
            'status': '',
            'equipmentInitial': '',
            'equipmentNumber': '',
            'vinNumber': '',
            'stcc': '',
            'salvage': '',
            'salvorName': '',
            'salvageAmountFrom': '',
            'salvageAmountTo': '',
            'region': '',
            'state': '',
            'shipper': ''
        }

        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox'), ...this.template.querySelectorAll('lightning-textarea')];
        inputFields.forEach(field => {
            field.value = '';
        });
        this.template.querySelector('lightning-input').resetData();
    }

    handleLDRRecordsDisplay(event) {
        this.recordsToDisplay = event.detail;
    }

    handleRowLinkClickSelection(event) {
        try {
            const actionName = event.detail.action.name;
            const equipmentList = event.detail.row.equipment;
            if (actionName === 'EquipmentDetails') {
                if (equipmentList) {
                    if(equipmentList.length==1){
                        let tempRec = Object.assign({}, equipmentList[0]);
                        this.EquipmentPopup = false;
                        const equipmentId = tempRec.equipmentId;                        
                        window.open(`/lightning/r/${equipmentId}/view`, '_blank');               
                        return
                    }
                    this.EquipmentPopup = true;
                    let tempRecs = [];
                    equipmentList.forEach((record) => {
                        let tempRec = Object.assign({}, record);
                        tempRec.equipmentId = '/' + tempRec.equipmentId;
                        tempRecs.push(tempRec);
                    });
                    this.equipListSelected = tempRecs;
                }
                else {
                    const selectionHeaderIssue = new ShowToastEvent({
                        message: 'No Equipment found for selected L&D Report',
                        duration: '5000',
                        variant: 'error',
                    });
                    this.dispatchEvent(selectionHeaderIssue);
                }
            }

            const ecmLinkForDocument = event.detail.row.documentLink;
            const ecmLink = JSON.stringify(ecmLinkForDocument);

            if (actionName === 'DocumentDetails') {
                if (ecmLink) {
                    const externalURLWithParams = ecmLinkForDocument;
                    window.open(externalURLWithParams, '_blank');
                } else {
                    console.log('External URL is not defined.');
                }
            }
        } catch (error) {
            this.isLoaded = true;
            let parameters = '';
            csx_cmp_logError('csx_cmp_ldrSearch', 'handleRowLinkClickSelection', error, parameters);
        }
    }

    closeEquipmemtModal(event) {
        const equipModalStatus = event.detail;
        if (equipModalStatus == 'Close') {
            this.EquipmentPopup = false;
        }
    }
    //export records in CSV format for Inspection Header records
    dowloadRecords() {
        this.openExcelComponent = true;
        if (this.librariesLoaded) {
            this.getHeaderExport();
        }
    }

    //export records in CSV format for Inspection Header records
    excelLibraryLoaded() {
        this.librariesLoaded = true;
        this.getHeaderExport();
    }

    //export records in CSV format for Inspection Header records
    getHeaderExport() {
        try {
            let result = [];
            let listForExport = this.records.map(function (obj) {
                if (obj.equipmentName != undefined) {
                    let tmp = {};
                    let equipName = String(obj.equipmentName).split(',');
                    for (let i = 0; i < equipName.length; i++) {
                        tmp = {};
                        tmp["L&D #"] = obj.reportNumber;
                        tmp["RAR #"] = obj.rarNumber;
                        tmp["Incident Date"] = obj.incidentDate;
                        tmp["Incident Location"] = obj.incidentLocation;
                        tmp["Incident Region"] = obj.incidentRegion;
                        tmp["Equipment ID"] = equipName[i];
                        tmp["Shipper"] = obj.shipper;
                        tmp["Consignee"] = obj.consignee;
                        tmp["STCC"] = obj.stcc;
                        tmp["L&D Status"] = obj.status;
                        tmp["Completed Date"] = obj.completedDate;
                        tmp["Reported By"] = obj.reportedBy;
                        //tmp["ECM Link"] = obj.documentLink;
                        result.push(tmp);
                    }
                }
            });
            this.xlsFormatter(result, "L&DRecords");
        } catch (error) {
            this.isLoaded = true;
            let parameters = JSON.stringify(this.xlsFormatter);
            csx_cmp_logError('getHeaderExport', 'getHeaderExport', error, parameters);
        }
    }

    handleSearchClick() {
        this.shownoRecordError = false;
        this.showTableData = false;
        this.showDetailButton = false;
        this.detailRecordToDisplay = [];
        this.paginatorRecords = [];
        this.recordsToDisplay = [];
        this.searchResult = false;
        this.totalNumberOfRecords = '';
        this.openExcelComponent = false;
        this.openExcelComponentDetail = false;
        this.isLoaded = false;
        this.records = [];
        this.recordToDisplay = true;

        if(this.isValidationError){
            this.isLoaded = true;
            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Please review error messages',
                duration: '3000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            return;
        }

        let lndInfoMap = new Map();
        lndInfoMap = Object.keys(this.lndData).reduce((map, key) => {

            if (this.lndData[key]) {
                map.set(key, this.lndData[key]);
            }
            return map;
        }, new Map());

        let obj = Object.fromEntries(lndInfoMap);
        let lndDataStringCon = JSON.stringify(obj);

        if (lndDataStringCon != '{}') {

            getLdrRecords({ ldrSearchParameters: lndDataStringCon })
                .then(result => {
                    if (result) {
                        let finalData = result.results;
                        this.ldrRecordslength = finalData.length;
                        
                        if (finalData.length >= this.label.searchDataLimit) {
                            const selectionHeaderIssue = new ShowToastEvent({
                                message: this.label.recordSizeLimit,
                                duration: '3000',
                                variant: 'warning',
                            });
                            this.dispatchEvent(selectionHeaderIssue);
                            this.isLoaded = true;
                            return;
                        }
                        if (finalData.length > 0) {
                            let tempRecs = [];
                            finalData.forEach((record) => {
                                let tempRec = Object.assign({}, record);
                                tempRec.ldrID = '/' + tempRec.ldrID;
                                if (tempRec.equipment != undefined) {
                                    tempRec.stcc = tempRec.equipment[0].stcc;
                                    tempRec.shipper = tempRec.equipment[0].shipper;
                                    tempRec.consignee = tempRec.equipment[0].consignee;
                                }
                                tempRecs.push(tempRec);
                            });
                            this.records = tempRecs;
                            this.showTableData = true;
                            this.showTable = true;
                            this.disableExportButton = false;
                            this.searchResults = true;
                            this.showDetailButton = true;
                            this.isSpinner = true;
                            this.isLoaded = true;
                        }
                        else {
                            this.isSpinner = true
                            this.showTable = false;
                            this.disableExportButton = true;
                            this.searchResults = false;
                            this.showDetailButton = false;
                            this.shownoRecordError = true;
                            this.isLoaded = true;
                        }
                    }
                    else {
                        this.isSpinner = true
                        this.shownoRecordError = true;
                    }
                })
                .catch(error => {
                    this.isLoaded = true;
                    let parameters = this.statusKeyValue + ',' + this.claimNumber + ',' + this.selectedClaimType;
                    csx_cmp_logError('csx_cmp_claimSearch', 'handleSearchClick', error, parameters);
                });
        } else {
            const selectionHeaderIssue = new ShowToastEvent({
                message: 'Please enter atleast 1 search criteria',
                duration: '5000',
                variant: 'error',
            });
            this.dispatchEvent(selectionHeaderIssue);
            this.isLoaded = true;
        }

    }


    doSortingDetail(event) {

        let sortbyField = event.detail.fieldName;
        if (sortbyField === "ldrID") {
            this.sortByDetail = "reportNumber";
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