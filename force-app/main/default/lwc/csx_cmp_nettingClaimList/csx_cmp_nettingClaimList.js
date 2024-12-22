import { LightningElement, track, api } from 'lwc';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_nettingClaimList extends LightningElement {

    showSpinner = false;
    data = [];
    error;
    @track selectedRecordIds = '';
    @api claimRecordList;
    @api nettingLabel;
    @track claimRecordWrapper;
    librariesLoaded = false;
    excelFileName = 'Netting Eligible Claim Report.xlsx';
    xlsData = [];
    xlsHeader = [];
    workSheetNameList = [];
    disableExportButton = true;
    displayComponent = false;
    inbClaim = [];
    outClaim = [];
    sortByName = 'railRoadName';
    sortDirection = 'asc';
    searchData = false;
    openExcelComponent = false;
    nettingClaimResultColumns = [
        { label: "Railroad", fieldName: 'railRoadName', sortable: "true", initialWidth: 293, wrapText: true, hideDefaultActions: false },
        {
            label: "Status", fieldName: '', initialWidth: 80, wrapText: false, hideDefaultActions: true,
            cellAttributes: { alignment: 'center', iconName: 'utility:priority', style: { fieldName: 'flagColor' } }
        },
        {
            label: "Sum Amount", fieldName: 'sumOfAmount', type: 'currency', initialWidth: 130, wrapText: false, hideDefaultActions: true,
            cellAttributes: { alignment: 'center', class: { fieldName: 'amountColor' } }
        },
        {
            label: "Count of claims", fieldName: 'countOfClaims', initialWidth: 120, wrapText: false, hideDefaultActions: true,
            cellAttributes: { alignment: 'center' }
        },
        {
            label: "Netting Claim#", fieldName: 'nettingClaimId', type: 'url',
            typeAttributes: { label: { fieldName: 'nettingClaim' }, target: '_blank' }, initialWidth: 130, wrapText: false, hideDefaultActions: true,
            cellAttributes: { alignment: 'center' }
        },

    ];

    connectedCallback() {
        this.showSpinner = true;

        let tempRecordsWithoutIds = [];
        let tempRecs = [];
        this.claimRecordList.forEach(ele => {
            let tempRec = Object.assign({}, ele);
            if (tempRec.nettingClaimId) {
                tempRec.nettingClaimId = '/' + tempRec.nettingClaimId;
                tempRecs.push(tempRec);
            } else {
                tempRec.nettingClaimId = '';
                tempRecordsWithoutIds.push(tempRec);
            }
        });
        this.claimRecordList = tempRecs.concat(tempRecordsWithoutIds);

        if (this.claimRecordList) {

            this.claimRecordList = this.claimRecordList.map(item => {
                let amountColor = item.sumOfAmount < 0 ? "slds-text-color_error" : "";
                let flagColor = item.supplierSiteStatus == 'true' ? "--sds-c-icon-color-foreground-default: #49A54C;" : "--sds-c-icon-color-foreground-default: #CB0015;";
                return {
                    ...item,
                    "amountColor": amountColor,
                    "flagColor": flagColor
                }
            })

            this.data = this.claimRecordList;
            this.showSpinner = false;
            this.disableExportButton = false;
            this.searchData = true;
            this.openExcelComponent = true;
        }
    }

    handleClaimRecordsDisplay(event) {
        this.selectedRecordIds = '';
        this.data = event.detail;
    }


    handleRowSelection(event) {
        this.inbClaim = [];
        this.outClaim = [];
        this.displayComponent = false;
        this.claimRecordWrapper = null;
        let selectedRows = event.detail.selectedRows;
        this.selectedRecordIds = selectedRows[0].railRoadUniqueId;

        if (this.selectedRecordIds) {
            this.claimRecordList.forEach(element => {
                if (element.railRoadUniqueId.toString() === this.selectedRecordIds.toString()) {
                    this.claimRecordWrapper = element;
                }
            });
        }
        if (this.claimRecordWrapper) {
            if (this.claimRecordWrapper.inboundClaimsList) {
                let tempRecs = [];
                this.claimRecordWrapper.inboundClaimsList.forEach(ele => {
                    if (ele.RecordType.DeveloperName === 'Freight') {
                        let tempRec = Object.assign({}, ele);
                        tempRec.Id = '/' + tempRec.Id;
                        tempRecs.push(tempRec);
                    } else if (ele.RecordType.DeveloperName === 'Revenue_Railroad') {
                        let tempRec = Object.assign({}, ele);
                        tempRec.Id = '/' + tempRec.Id;
                        tempRecs.push(tempRec);
                    }
                });
                this.inbClaim = tempRecs;

            }

            if (this.claimRecordWrapper.outboundClaimsList) {
                let tempRecs = [];
                this.claimRecordWrapper.outboundClaimsList.forEach(ele => {
                    if (ele.RecordType.DeveloperName === 'Freight') {
                        let tempRec = Object.assign({}, ele);
                        tempRec.Id = '/' + tempRec.Id;
                        tempRecs.push(tempRec);
                        
                        if (tempRecs) {
                            tempRecs = tempRecs.map(item => {
                                let amountColor = item.CSX_CMP_Claim_Amount__c < 0 ? "slds-text-color_error" : ""
                                return {
                                    ...item,
                                    "amountColor": amountColor,
                                }
                            })
                        }
                    } else if (ele.RecordType.DeveloperName === 'Revenue_Railroad') {
                        let tempRec = Object.assign({}, ele);
                        tempRec.Id = '/' + tempRec.Id;
                        tempRecs.push(tempRec);
                        
                        if (tempRecs) {
                            tempRecs = tempRecs.map(item => {
                                let amountColor = item.CSX_CMP_Claim_Amount__c < 0 ? "slds-text-color_error" : ""
                                return {
                                    ...item,
                                    "amountColor": amountColor,

                                }
                            })
                        }
                    }
                });
                this.outClaim = tempRecs;

            }
            
            this.displayComponent = true;
        }
    }

    //Excel generator

    excelLibraryLoaded() {
        this.librariesLoaded = true;
    }

    downloadClaimData() {
        if (this.librariesLoaded) {
            this.getClaimExport();
        }
    }

    getClaimExport() {
        try {
            let listForExport = this.claimRecordList.map(function (obj) {
                let tmp = {};
                // tmp["Railroad Name"] = obj.railRoadName;
                // tmp["Supplier Status"] = obj.supplierSiteStatus;
                // tmp["Amount"] = obj.sumOfAmount;
                // tmp["Count of Claims"] = obj.countOfClaims;
                // tmp["Netting Claim"] = obj.nettingClaim;
                tmp["Railroad"] = obj.railRoadName;
                tmp["Status"] = obj.supplierSiteStatus;
                tmp["Sum Amount"] = obj.sumOfAmount;
                tmp["Count of Claims"] = obj.countOfClaims;
                tmp["Netting Claim#"] = obj.nettingClaim;
                return tmp;
            });
            this.xlsFormatter(listForExport, "ClaimData");
        } catch (error) {
            let parameters = JSON.stringify(this.claimRecordList);
            csx_cmp_logError('csx_cmp_NettingClaim', 'getNetting', error, parameters);
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

    doSortingRailroad(event) {
        this.inbClaim = [];
        this.outClaim = [];
        this.claimRecordWrapper = null;
        let sortbyField = event.detail.fieldName;
        if (sortbyField === "railRoadName") {
            this.sortByName = "railRoadName";
        }
        else {
            this.sortByName = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortByName, this.sortDirection);
        this.sortByName = sortbyField;
    }

    sortData(fieldName, sortDirection) {
        let sortResult = Object.assign([], this.data);
        this.data = sortResult.sort(function (a, b) {
            a = a[fieldName] ? a[fieldName] : '';
            b = b[fieldName] ? b[fieldName] : '';
            if (a < b) {
                return sortDirection === 'asc' ? -1 : 1;
            } else if (a > b) {
                return sortDirection === 'asc' ? 1 : -1;
            } else {
                return 0;
            }
        })
        if (this.searchData) {
            this.searchData = false;
        } else {
            this.searchData = true;
        }
    }
}