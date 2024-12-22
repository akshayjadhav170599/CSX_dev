import { LightningElement, api, track } from 'lwc';
import getShipments from '@salesforce/apex/CSX_CMP_InterfaceUtility.newShipmentMaptoWrapper';
import search from '@salesforce/label/c.CSX_CMP_SearchLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import notFound from '@salesforce/label/c.CSX_CMP_NoResultsFound';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_shipmentSearch extends LightningElement {

    @api selectMultipleRows = false;
    @api shipmentCheck = false;
    @api displayVin = false;
    @api selectedOption = 'equipment';
    @api claimType = '';
    @api claimTypeApplicable = false;
    showStartDate = true;
    showTableData = false;
    maximumDate;
    recordsToDisplay;
    noResults = false;
    vinSearchValue = [];
    isSubmitting = false;
    errorFetchingShipment = false;
    records;
    @track selectedRows = [];
    datatableTitle = 'Shipment Results';
    shipmentCriteria = {
        'startDate': '',
        'searchCriteria': '',
        'equipmentId': '',
        'vin': ''
    };
    label = {
        search,
        reset,
        notFound,
        error: 'Issue fetching shipments from SIMS. Please try again in sometime. If issue persists contact support',
        hideVINForClaimTypes: 'Transflo Claim,FC Customer Claim,Contractor Claim,Lawsuit Claim',
    };
    shipmentResultColumns = [

        { label: "Equipment ID", fieldName: 'equipment', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 110 },
        { label: "Origin", fieldName: 'origin', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Shipper", fieldName: 'shipperName', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Destination", fieldName: 'destination', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Consignee", fieldName: 'consigneeName', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 250 },
        { label: "Waybill #", fieldName: 'waybillNumber', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 90 },
        { label: "Waybill Date", fieldName: 'waybillDate', type: 'date', sortable: "true", typeAttributes: { day: '2-digit', month: '2-digit', year: 'numeric' }, hideDefaultActions: true, initialWidth: 110 },
        { label: "Shipment Type", fieldName: 'shipmentType', type: 'text', sortable: "true", hideDefaultActions: true, initialWidth: 130 },
    ];

    @track options = [
        { label: 'Equipment ID', value: 'equipment', checked: true },
        { label: 'VIN', value: 'vin', checked: false }
    ];


    @api handleDefaultOptionChange(claimType) {
        this.resetPage(); // need to check this once as reseting page clears out records which were queried as part of previous search based on claim type but as type changed to other claim type, records should be cleared out
        this.claimType = claimType;
        this.options.forEach(element => {
            if (element.value === this.selectedOption) {
                element.checked = true;
            } else {
                element.checked = false;
            }
        });

        if (this.selectedOption === 'vin') {
            this.showStartDate = false;
        } else {
            this.showStartDate = true;
        }
    }


    get searchOptions() {
        let options = [];
        let availableOptions = this.options;
        availableOptions.forEach(element => {
            if (this.displayVin || element.value !== 'vin') {
                options.push(element);
            }
        });
        console.log('options', options);
        if (!this.displayVin) {
            this.selectedOption = 'equipment';
            options.find(element => element.value === 'equipment').checked = true;
        }
        return options;
    }

    connectedCallback() {
        this.maximumDate = new Date().toISOString().split('T')[0];
    }
    // handler methods
    handleRadioChange(event) {
        this.selectedOption = event.target.value;
        this.options.forEach(element => {
            if (element.value === this.selectedOption) {
                element.checked = true;
            }
            else {
                element.checked = false;
            }
        });

        if (this.selectedOption === 'vin') {
            this.showStartDate = false;
            this.shipmentCriteria['startDate'] = '';
            this.shipmentCriteria['searchCriteria'] = '';
            this.shipmentCriteria['equipmentId'] = '';
            this.shipmentCriteria['vin'] = '';
            this.template.querySelectorAll('lightning-input').forEach(element => {
                element.value = '';
            });
        }
        else {
            this.showStartDate = true;
            this.shipmentCriteria['searchCriteria'] = '';
            this.shipmentCriteria['equipmentId'] = '';
            this.shipmentCriteria['vin'] = '';
            this.template.querySelectorAll('lightning-input').forEach(element => {
                element.value = '';
            });
        }
    }

    handleInputChange(event) {
        let fields = this.template.querySelectorAll('lightning-input');
        if (event.target.name == 'startDate') {
            if (event.target.value == '' || event.target.value == null) {
                fields.forEach(field => {
                    if (field.name === 'startDate') {
                        field.setCustomValidity('Your entry does not match the allowed format MM/DD/YYYY');
                        field.reportValidity();
                    }
                });
            } else {
                fields.forEach(field => {
                    if (field.name === 'startDate') {
                        field.setCustomValidity('');
                        field.reportValidity();
                        field.classList.remove('slds-has-error');
                    }
                });
                this.shipmentCriteria[event.target.name] = new Date(event.target.value).toISOString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }).split('T')[0];

            }
        } else {
            this.shipmentCriteria[event.target.name] = event.target.value;
            if (this.selectedOption === 'vin') {
                this.shipmentCriteria['vin'] = this.shipmentCriteria['searchCriteria'];
            } else {
                this.shipmentCriteria['equipmentId'] = this.shipmentCriteria['searchCriteria'];
            }
        }
    }

    handleShipmentRecordsDisplay(event) {
        this.records = event.detail;
    }

    handleRowSelection(event) {
        let selectedRows = [];
        let selectedValue = event.detail.selectedRows;
        if (selectedValue.length > 0) {
            //let selectedRowKeys = selectedValue;
            selectedRows = selectedValue;
            this.selectedRows = selectedValue;
        } else {
            this.selectedRows = [];
        }
        /*if (selectedValue.length > 0) {
            selectedRows = selectedValue[0];
            this.selectedRows = selectedRows;
        }*/
        this.dispatchEvent(new CustomEvent('sendshipments', { detail: JSON.stringify(selectedRows) }));
    }

    handleMultipleRowSelection(event) {
        let localSelected = event.detail.selectedRows;
        let selectedRows = [];
        let records = new Map();
        if (this.records) {
            this.records.forEach(element => {
                records.set(element.waybillNumber, element);
            });
        }
        console.log('records', records);
        if (localSelected.length > 0) {

            let selectedRowsMap = new Map();
            console.log('this.selectedRows', this.selectedRows);
            if (this.selectedRows && this.selectedRows.length > 0) {
                this.selectedRows.forEach(element => {
                    if (element) {
                        let elementObj = {};
                        Object.keys(records.get(element)).forEach(key => {
                            elementObj[key] = element[key];
                        });
                        selectedRowsMap.set(element.waybillNumber, elementObj);
                    }
                });
            }
            selectedRowsMap.delete(undefined);
            localSelected.forEach(element => {
                if (selectedRowsMap.has(element.waybillNumber)) {
                    selectedRowsMap.delete(element.waybillNumber);
                } else {
                    selectedRowsMap.set(element.waybillNumber, element);
                }
            });
            selectedRows = Array.from(selectedRowsMap.values());
            this.selectedRows = Array.from(selectedRowsMap.keys());
        }

        this.dispatchEvent(new CustomEvent('sendshipments', { detail: JSON.stringify(selectedRows) }));
    }
    // end of handler methods


    handleSearch() {
        console.log('this.claimTypeApplicable', this.claimTypeApplicable);
        console.log('this.claimType', this.claimType);
        if (this.claimTypeApplicable && this.claimType === '') {
            let event = new ShowToastEvent({
                title: 'Error',
                message: 'Please select a claim type',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        this.isSubmitting = true;
        this.showTableData = false;
        let isValid = this.validate();
        this.vinSearchValue = [];
        this.selectedRows = null;
        this.records = [];

        //reset vin and equi data in parent
        let resetEvent = new CustomEvent('resetshipment');
        this.dispatchEvent(resetEvent);
        if (isValid) {
            getShipments({ shipmentDetails: this.shipmentCriteria })
                .then(data => {
                    let records = [];
                    this.isSubmitting = false;
                    this.errorFetchingShipment = false;
                    this.selectedRows = [];
                    console.log('data', data);

                    if (data) {
                        records = data.map(row => ({
                            ...row,
                            origin: row.actualOriginCityName + ', ' + row.actualOriginStateCode,
                            destination: row.actualDestinationCityName + ', ' + row.actualDestinationStateCode,
                            equipment: row.equipmentInitial + ' ' + row.equipmentNumber,
                        }));


                        if (this.claimTypeApplicable) {
                            let tempList = [];
                            // if (this.claimType === 'Transflo Claim' || this.claimType === 'FC Customer Claim') {
                            if (this.label.hideVINForClaimTypes.split(',').includes(this.claimType)) {
                                records.forEach(record => {
                                    if (record.vinNum.length <= 0) {
                                        tempList.push(record);
                                    }
                                });
                            } else if (this.claimType === 'FC Customer Automobile Claim') {
                                records.forEach(record => {
                                    if (record.vinNum && record.vinNum.length > 0) {
                                        tempList.push(record);
                                    }
                                });
                            } else {
                                tempList = records;
                            }
                            records = tempList;
                        }
                        console.log('records', records);

                        if (records.length > 0) {
                            this.showTableData = true;
                            this.noResults = false;
                            this.records = records;
                            if ((this.shipmentCriteria.vin != null || this.shipmentCriteria.vin != '') && !this.showStartDate) {
                                records[0].vinNum.forEach(element => {
                                    if (element == this.shipmentCriteria.vin.toUpperCase()) {
                                        this.vinSearchValue.push(element);
                                    }
                                })
                                records[0].vinNum = this.vinSearchValue;
                            }

                            if (records.length == 1) {
                                //this.selectedRows = [this.records[0].equipment];
                                this.selectedRows = [records[0].waybillNumber];
                                console.log('this.selectedRows', this.selectedRows);
                                this.sendShipment();
                            }
                        } else {
                            this.recordsToDisplay = [];
                            this.records = [];
                            this.showTableData = false;
                            this.noResults = true;
                        }
                    }



                    // if (data) {

                    //     this.records = data.map(row => ({
                    //         ...row,
                    //         origin: row.actualOriginCityName + ', ' + row.actualOriginStateCode,
                    //         destination: row.actDestinationCity + ', ' + row.actualDestinationStateCode,
                    //         equipment: row.equipmentInitial + ' ' + row.equipmentNumber,
                    //     }));

                    //     if (this.records.length > 0) {
                    //         this.showTableData = true;
                    //         this.noResults = false;
                    //         if ((this.shipmentCriteria.vin != null || this.shipmentCriteria.vin != '') && !this.showStartDate) {
                    //             this.records[0].vinNum.forEach(element => {
                    //                 if (element == this.shipmentCriteria.vin.toUpperCase()) {
                    //                     this.vinSearchValue.push(element);
                    //                 }
                    //             })
                    //             this.records[0].vinNum = this.vinSearchValue;
                    //         }

                    //         if (this.records.length == 1) {
                    //             //this.selectedRows = [this.records[0].equipment];
                    //             this.selectedRows = [this.records[0].waybillNumber];
                    //             console.log('this.selectedRows', this.selectedRows);
                    //             this.sendShipment();
                    //         }
                    //     } else {
                    //         this.recordsToDisplay = [];
                    //         this.records = [];
                    //         this.showTableData = false;
                    //         this.noResults = true;
                    //     }
                    // }
                })
                .catch(error => {
                    this.isSubmitting = false;
                    this.recordsToDisplay = [];
                    this.records = [];
                    this.showTableData = false;
                    this.errorFetchingShipment = true;
                    csx_cmp_logError('Csx_cmp_shipmentSearch', 'getShipments', error, '');
                });
        } else {
            this.isSubmitting = false;
        }

    }

    sendShipment() {
        let sendShipment = new CustomEvent('sendshipments', { detail: JSON.stringify(this.records) });
        this.dispatchEvent(sendShipment);
    }

    // reset validate and submit methods

    validate() {
        let inputFields = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        return isValid;
    }

    @api
    resetPage() {
        this.template.querySelectorAll('lightning-input').forEach(field => {
            field.value = '';
            field.required = false;
            field.setCustomValidity('');
            field.reportValidity();
            field.required = true;

        });

        this.shipmentCriteria = {
            'startDate': '',
            'searchCriteria': '',
            'equipmentId': '',
            'vin': ''
        };
        this.showTableData = false;
        this.records = '';
        this.noResults = false;
        this.errorFetchingShipment = false;
        const resetEvent = new CustomEvent('resetshipment');
        this.dispatchEvent(resetEvent);
    }

    // end of reset validate and submit methods

}