import { LightningElement, api, track } from 'lwc';

export default class Cg_multiselectDropdown extends LightningElement {
    
    @api showRequired = false;
    @api label = "Default label";
    @track inputOptions;
    @api options
    
    _disabled = false;
    @api
    get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
        this.handleDisabled();
    }

    @api
    setDisabledValue(value) {
        this._disabled = value;
        this.handleDisabled();
    }
    @api
    clearSelectedValues() {
        this.inputValue = '';
        this.options = '';
        this.value = [];
    }

    @track showRequiredError = false;

    @api
    checkSubCategoryRequired() {
        if (this.value.length == 0) {
            this.showRequiredError = true;
        }
        return this.showRequiredError;
    }
    

    @api
    clear() {
        this.value = [];
        this.inputValue = '';
        let listBoxOptions = this.template.querySelectorAll('.slds-is-selected');
        for (let option of listBoxOptions) {
            option.classList.remove("slds-is-selected");
        }
    }
    @api placeholder

    @api reset;
    value = [];
    @track inputValue = '';
    hasRendered;
    @api
    get receivedValues() {
        return this.inputValue;
    }
    set receivedValues(value) {
        this.inputValue = value;
        if (value != (''||undefined)) {
            let valuesSent = [];
            valuesSent = value.split('; ');
            if (valuesSent.length > 0) {
                for (let i = 0; i < valuesSent.length; i++) {
                    if (valuesSent[i] != '') {
                        let option = this.options.find(option => option.value === valuesSent[i]);
                        this.value.push(option);
                    }
                }
            }
        }
    }
    @api selecteddataid;
    renderedCallback() {
        let list = [];
        list = this.options;
        if (this.inputOptions == this.options) {

        } else {
            this.handleDisabled();
            this.inputOptions = this.options;

        }
        this.hasRendered = true;
        this.inputOptions = this.options;
    }
    handleDisabled() {
        let input = this.template.querySelector("input");
        if (input) {
            input.disabled = this.disabled;
        }
    }
    comboboxIsRendered;
    handleClick() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.toggle("slds-is-open");
        if (!this.comboboxIsRendered) {
            this.comboboxIsRendered = true;
        }
        if (this.inputValue == '') {
            console.log('it is null');
        }
    }
    handleSelection(event) {
        this.showRequiredError = false;
        let value = event.currentTarget.dataset.value;
        this.handleOption(event, value);
        let input = this.template.querySelector("input");
        input.focus();
        this.sendValues();
    }
    sendValues() {
        let values = [];
        for (const valueObject of this.value) {
            values.push(valueObject.value);
        }
        
        this.dispatchEvent(new CustomEvent("valuechange", {
            detail: { values }
        }));
        
        this.dispatchEvent(new CustomEvent("valuechangewithid", {
            detail: { values: values, selecteddataid: this.selecteddataid }
        }));
        
    }

    handleOption(event, value) {
        let listBoxOption = event.currentTarget.firstChild;
        if (listBoxOption.classList.contains("slds-is-selected")) {
            this.value = this.value.filter(option => option.value !== value);
        } else {
            let option = this.options.find(option => option.value === value);
            this.value.push(option);
        }
        if (this.value.length > 1) {
            let valueInput = '';
            for (let i = 0; i < this.value.length; i++) {
                valueInput = valueInput + this.value[i].label + '; '
            }

            this.inputValue = valueInput;
        } else if (this.value.length === 1) {
            this.inputValue = this.value[0].label;
        }
        else{
            this.inputValue = '';
            this.value = [];
        }
        listBoxOption.classList.toggle("slds-is-selected");
    }
    dropDownInFocus = false;
    handleBlur() {
        if (!this.dropDownInFocus) {
            this.closeDropbox();
        }
    }
    handleMouseleave() {
        this.dropDownInFocus = false;
    }
    handleMouseEnter() {
        this.showRequiredError = false;
        this.dropDownInFocus = true;
    }
    closeDropbox() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
    }
 
}