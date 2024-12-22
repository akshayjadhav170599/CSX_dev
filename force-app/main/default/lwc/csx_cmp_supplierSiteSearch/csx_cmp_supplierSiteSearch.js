import { LightningElement, api, track } from 'lwc';
import supplierSiteSearch from '@salesforce/apex/CSX_CMP_ClaimCreationController.supplierSiteSearch';
import search from '@salesforce/label/c.CSX_CMP_SearchLabel';
import reset from '@salesforce/label/c.CSX_CMP_ResetLabel';
import notFound from '@salesforce/label/c.CSX_CMP_NoResultsFound';
import mandatoryClaimant from '@salesforce/label/c.CSX_CMP_ClaimantIsMandatory';

export default class Csx_cmp_supplierSiteSearch extends LightningElement {

     selectedState = '';
     selectedCity = '';
     name;
     showTableData = false;
     records;
     recordsToDisplay;
     @api supplierCheck = false;
     @api claimType;
     @api recordType;
     noClaimType = false;
     isValid = true;
     @track selectedRows = [];

     noResults = false;
     datatableTitle = 'Claimant Results';
     label = {
          search,
          reset,
          notFound,
          mandatoryClaimant
     };
     supplierDetails = [

          { label: "Supplier Name", fieldName: 'Name', type: 'text', sortable: "true" },
          { label: "Supplier Number", fieldName: 'AccountNumber', type: 'text', sortable: "true" },
          { label: "Tax ID", fieldName: 'Tax_Id__c', type: 'text', sortable: "true" },
          { label: "Site Name", fieldName: 'Site', type: 'text', sortable: "true" },
          { label: "Bank Account Name", fieldName: 'Bank_Name__c', type: 'text', sortable: "true" },
          { label: "Bank Account Number", fieldName: 'Bank_Account_Number__c', type: 'text', sortable: "true" },
          { label: "Payment Address", fieldName: 'BillingAddress', type: 'text', sortable: "true" },
          { label: "Payment Method", fieldName: 'Payment_Method__c', type: 'text', sortable: "true" },
          { label: "Operating Unit", fieldName: 'Name', type: 'text', sortable: "true" }
     ];

     // Handler methods
     handleNameChange(event) {
          this.name = event.target.value;
     }
     handleStateChange(event) {
          const obj = JSON.parse(event.detail);
          this.selectedState = obj.value;
     }
     handleCityChange(event) {
          const obj = JSON.parse(event.detail);
          this.selectedCity = obj.value;
     }
     handleSupplierRecordsDisplay(event) {
          this.recordsToDisplay = event.detail;
     }
     handleRowSelection(event) {
          let selectedRows = event.detail.selectedRows;
          this.supplierCheck = false;
          if (selectedRows.length > 0) {
               let SupplierId = selectedRows[0].Id;
               let sendSupplierId = new CustomEvent('sendsupplierid', { detail: JSON.stringify(SupplierId) });
               this.dispatchEvent(sendSupplierId);
          }
     }
     //End of handler methods

     get isFreight() {
          return this.recordType === 'Freight';
     }
     //submit,reset and validation methods
     @api
     supplierValidation() {
          this.supplierCheck = true;
          console.log('this.supplierCheck', this.supplierCheck);
     }
     @api
     resetPage() {
          this.name = '';
          this.showTableData = false;
          this.noResults = false;
          this.noClaimType = false;
          this.records = [];
          this.recordsToDisplay = [];
          this.selectedState = '';
          this.selectedCity = '';
          this.supplierCheck = false;
          let inputField = this.template.querySelector('[data-id="supplierName"]');
          if (inputField) {
               let required = false;
               if (inputField.required) {
                    required = true;
                    inputField.required = false;
                    inputField.reportValidity();
               }
               inputField.value = '';
               if (required) {
                    inputField.required = true;
               }
          }
          this.isValid = true;
          let cityState = this.template.querySelector('c-csx_cmp_display-city-state');
          if (cityState) {
               cityState.resetData();
          }
          // let SupplierId = '';
          // let sendSupplierId = new CustomEvent('sendsupplierid', { detail: JSON.stringify(SupplierId) });
          // this.dispatchEvent(sendSupplierId);
          this.dispatchEvent(new CustomEvent('sendsupplierid', { detail: JSON.stringify('') }));
     }
     handleSearch() {
          this.dispatchEvent(new CustomEvent('sendsupplierid', { detail: JSON.stringify('') }));
          let inputSupplierField = this.template.querySelector('[data-id="supplierName"]');
          this.isValid = true;
          this.selectedRows = [];
          if (inputSupplierField) {
               if (!inputSupplierField.checkValidity()) {
                    inputSupplierField.reportValidity();
                    this.isValid = false;
               }
               if (this.claimType == undefined && this.recordType == 'Freight') {
                    this.noClaimType = true;
                    this.isValid = false;
               } else {
                    this.noClaimType = false;
               }
          }
          this.showTableData = false;
          this.recordsToDisplay = [];
          this.records = undefined;
          if (this.isValid) {
               supplierSiteSearch({ name: this.name, state: this.selectedState, city: this.selectedCity, claimType: this.claimType })
                    .then(data => {
                         if (data) {
                              this.showTableData = true;

                              if (data.length > 0) {
                                   let tempRecs = [];
                                   tempRecs = data.map(row => ({
                                        ...row,
                                        BillingAddress: row.BillingAddress.street + ',' + row.BillingAddress.city + ',' + row.BillingAddress.state + '  ' + row.BillingAddress.postalCode + '  ' + row.BillingAddress.country,
                                        Bank_Account_Number__c: row.Bank_Account_Number__c != null ? row.Bank_Account_Number__c.replace(/\d(?=\d{4})/g, "*") : null
                                   }));
                                   this.records = tempRecs;
                                   this.noResults = false;
                                   if (this.records.length == 1) {
                                        this.selectedRows = [this.records[0].Id];
                                        this.handleRowSelection({ detail: { selectedRows: [this.records[0]] } });
                                        this.recordsToDisplay = this.records;
                                   }
                              }
                              else {
                                   this.recordsToDisplay = [];
                                   this.records = [];
                                   this.showTableData = false;
                                   this.noResults = true;
                              }
                         }
                    });
          }

     }
     // end of submit,reset and validation methods
}