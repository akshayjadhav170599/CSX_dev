import { LightningElement, api } from 'lwc';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import getShipmentsRevenue from '@salesforce/apex/CSX_CMP_InterfaceUtility.newShipmentMaptoWrapper';
import { csx_cmp_logError } from 'c/csx_cmp_logError';

export default class Csx_cmp_shipmentSearchRevRR extends LightningElement {

    label = {
        reset
    }
    shipmentSearch = {
        urrwinNumber: '',
        equipmentId: '',
        waybillNumber: '',
        startDate: ''
    };
    disableEquipmentId = false;
    disableWaybillNumber = false;
    waybillDateReq = false;
    disableWaybillDate = false;
    disableUrrwinNumber = false;
    nosearchCriteria = false;
    isSubmitting = false;

    handleInputChange(event) {
        this.nosearchCriteria = false;
        if (event.target.type === 'date') {
            this.shipmentSearch[event.target.name] = new Date(event.target.value).toISOString('en-US', { year: "numeric", month: "2-digit", day: "2-digit" }).split('T')[0];
        }
        else {
            this.shipmentSearch[event.target.name] = event.target.value;
        }

        if (event.target.name == 'equipmentId' && event.target.value) {
            this.disableWaybillNumber = true;
            this.waybillDateReq = true;
            this.disableUrrwinNumber = true;
            this.disableWaybillDate = false;
            this.disableEquipmentId = false;
        } else if (event.target.name == 'waybillNumber' && event.target.value) {
            this.disableEquipmentId = true;
            this.waybillDateReq = true;
            this.disableUrrwinNumber = true;
            this.disableWaybillDate = false;
            this.disableWaybillNumber = false;
        } else if (event.target.name == 'startDate') {
            this.waybillDateReq = true;
        }
    }
    handleUrrwinChange(event) {
        let textAreaRegex = /^[0-9]{9}(,[0-9]{9})*,?$/;
        let urrwinNum = event.target.value;
        this.nosearchCriteria = false;
        this.disableEquipmentId = true;
        this.disableWaybillNumber = true;
        this.disableWaybillDate = true;
        this.waybillDateReq = false;
        let urrwinEntered = this.template.querySelector('lightning-textarea');
        if (urrwinNum != '') {
            if (urrwinNum.match(textAreaRegex)) {
                console.log("correct inputs");
                urrwinEntered.setCustomValidity("");
                this.shipmentSearch.urrwinNumber = urrwinNum;
            } else {
                urrwinEntered.setCustomValidity("Please enter valid data");
            }
        } else {
            urrwinEntered.setCustomValidity("");
        }
    }
    @api
    reset() {
        this.disableEquipmentId = false;
        this.disableWaybillNumber = false;
        this.disableWaybillDate = false;
        this.waybillDateReq = false;
        this.disableUrrwinNumber = false;
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-textarea')];
        inputFields.forEach(inputField => {
            let parameters = {
                required: false,
                type: inputField.type
            }
            inputField.value = '';
            inputField.type = '';
            inputField.setCustomValidity('');
            if (inputField.required) {
                parameters.required = true;
                inputField.required = false;
            }

            window.setTimeout(() => {
                inputField.reportValidity();
                if (parameters.required) {
                    inputField.required = true;
                }
                inputField.type = parameters.type;
            }, 300);

        });

        this.shipmentSearch = {
            urrwinNumber: '',
            equipmentId: '',
            waybillNumber: '',
            startDate: ''
        };
        this.dispatchEvent(new CustomEvent('resettable', { detail: '' }));
    }
    validate() {
        let inputFields = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-textarea')];
        let isValid = true;
        this.nosearchCriteria = false;
        if (inputFields) {
            inputFields.forEach(inputField => {
                if (!inputField.checkValidity()) {
                    inputField.reportValidity();
                    isValid = false;
                }
            });
        }
        if (this.shipmentSearch.urrwinNumber == '' && this.shipmentSearch.waybillNumber == '' && this.shipmentSearch.equipmentId == '') {
            this.nosearchCriteria = true;
            isValid = false;
        }
        return isValid;
    }
    addShipment() {
        this.isSubmitting = true;
        let isValid = this.validate();
        if (isValid) {
            getShipmentsRevenue({ shipmentDetails: this.shipmentSearch }).then(result => {
                this.isSubmitting = false;
                let data = [];
                if (result.length > 0) {
                    console.log('result in shipmentsearch ', result);
                    result.forEach(element => {
                        let tempData = {
                            urrwinNumber: element.urrwinNumber,
                            urrwinDate: element.urrwinDate ? element.urrwinDate : '',
                            stcc: element.commodityNumber,
                            description: element.description,
                            equipmentInitial: element.equipmentInitial,
                            equipmentNumber: element.equipmentNumber,
                            waybillNumber: element.waybillNumber,
                            waybillDate: element.waybillDate,
                            claimAmount: element.claimAmount,
                            totalCars: element.totalCars,
                            actualOriginStateCode: element.actualOriginStateCode,
                            actualOriginCityName: element.actualOriginCityName,
                            actualDestinationStateCode: element.actualDestinationStateCode,
                            actualDestinationCityName: element.actualDestinationCityName,
                            adjustmentDate: element.adjustmentDate,
                            challengeDate: element.challengeDate,
                            isSettlementDate: element.isSettlementDate,
                            waybillControls: element.waybillControls,
                            settlementAmount: element.settlementAmount,
                            flatCarId: element.flatCarId
                        };
                        data.push(tempData);
                    });
                    data = JSON.stringify(data);
                    this.dispatchEvent(new CustomEvent('addshipments', { detail: data }));
                }
                else {
                    let noResults = true;
                    this.dispatchEvent(new CustomEvent('noshipments', { detail: noResults }));
                }

            }).catch(error => {
                csx_cmp_logError('Csx_cmp_shipmentSearchRevRR', 'getShipmentsRevenue', error, '');
            });
        } else {
            this.isSubmitting = false;
        }
    }
}