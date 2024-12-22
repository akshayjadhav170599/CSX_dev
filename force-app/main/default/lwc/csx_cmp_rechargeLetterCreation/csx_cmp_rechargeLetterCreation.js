import { LightningElement, track,api,wire } from 'lwc'; 
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TYPE from '@salesforce/schema/Case.Type';
import RECORDTYPE from '@salesforce/schema/Case.RecordType.DeveloperName';
import STATUS from '@salesforce/schema/Case.Status';  
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import generateLetters from '@salesforce/apex/CSX_CMP_LetterGenerationController.generateLetters';

const fields = [TYPE, RECORDTYPE,STATUS];
const fieldsArray=['Case.Type',
              'Case.RecordType.DeveloperName'];

export default class Csx_cmp_rechargeLetterCreation extends LightningElement {

    @api recordId;
    selectedOpt='';
    revenueflag=false;
    typeD;
    @track optionSelected=false;
    recordTypeDetail;
    viewButton=true;
    letterType;
    

    @wire(getRecord, { recordId: "$recordId", fields: fields}) caseRecords;
    @wire(getRecord, { recordId: "$recordId", fields: fieldsArray}) caseRecord;

        get claimType() {
            let typeDetails;
            let status;
            if(this.caseRecords.data){
                 typeDetails= getFieldValue(this.caseRecords.data, TYPE);
                 status= getFieldValue(this.caseRecords.data, STATUS);
                 if(typeDetails=='FC Customer Automobile Claim' || typeDetails=='FC Customer Claim' || typeDetails=='Transflo Claim' || typeDetails=='Contractor Claim'){
                    if(status=='Declined' || status=='Re-Declined'){
                        this.letterType='Decline';
                        return [
                            { label: 'Declination Letter', value: 'declinationLetter', checked: false },               
                            { label: 'Claim Summary', value: 'claimSummary', checked: false },
                        ];
                    }else{
                        return [
                            {label: 'Claim Summary', value: 'claimSummary', checked: false }   
                        ];
                    }
            
                 }
                 else if(typeDetails=='Incentive Claim' || typeDetails=='Service Claim' || typeDetails=='Rev-RR - Payable Claim' ||  typeDetails=='Rev-RR - Payable Rchg Claim' || typeDetails.startsWith('Overcharge')){
                    if(status=='Declined' || status=='Re-Declined'){
                        this.letterType='Decline';
                    return [
                        { label: 'Declination Letter', value: 'declinationLetter', checked: false },
                        { label: 'Claim Summary', value: 'claimSummary', checked: false },
                    ];
                }else{
                    return [
                        { label: 'Claim Summary', value: 'claimSummary', checked: false }   
                    ];
                }

                 }
                 else if( typeDetails=='Recharges Outbound Claim' ){
                    this.letterType='Recharge';
                        return[
                            { label: 'Recharge Letter', value: 'rechargeLetter', checked: false },
                            { label: 'Claim Summary', value: 'claimSummary', checked: false }
                        ]
                 }
                 else if( typeDetails== 'FC RR Inbound Claim'|| typeDetails=='Lawsuit Claim' || typeDetails=='Recharges Inbound Claim'){
                    return[
                        { label: 'Claim Summary', value: 'claimSummary', checked: false }
                    ]
                }
                else if( typeDetails!='FC RR Outbound Claim' || typeDetails!='Railroad Netting FC Claim' || typeDetails!='FC Salvage Claim'){
                    return [
                        { label: 'Claim Summary', value: 'claimSummary', checked: false}
                    ]
                 }
                this.typeD=typeDetails;
            }
        return typeDetails;
      }

    get claimStatus() {
        let clStatus;
        if(this.caseRecords.data){
            clStatus= getFieldValue(this.caseRecords.data, STATUS);
             this.status=clStatus;
        }
        return clStatus;
    }


    get developerName() {
        let devName;
        if(this.caseRecords.data){
            devName=getFieldValue(this.caseRecords.data, RECORDTYPE);
             this.typeD=devName; 
        }
        return  devName;
           
    }
      
    handleRadioChange(event) {
        this.selectedOpt = event.detail.value;
    }

    createDocument() {
        if(this.selectedOpt == ''){
            this.optionSelected=true;
        }
        else if (this.selectedOpt == 'rechargeLetter') {
            let vfPageName='CSX_CMP_RechargeLetterpage';
            this.generateLetter(vfPageName);
        }
        else if (this.selectedOpt == 'declinationLetter') {
            
            if(this.developerName==='Freight'){
                let vfPageName='CSX_CMP_FreightDeclineLetter';
                this.generateLetter(vfPageName);
            }
            if(this.developerName==='Revenue_Contract_Refund'){
                let vfPageName='CSX_CMP_ContractRefundDeclineLetter';
                this.generateLetter(vfPageName);
                
            }
            if(this.developerName==='Revenue_Overcharge'){
                let vfPageName='CSX_CMP_OverchargeDeclineLetter';
                this.generateLetter(vfPageName);
               
            }
            if(this.developerName==='Revenue_Railroad'){
                let vfPageName='CSX_CMP_RevenueRailroadDeclineLetter';
                this.generateLetter(vfPageName); 
            }
        }
        else if (this.selectedOpt == 'claimSummary') {
           this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    generateLetter(vfPageName){
        generateLetters({ recordIds: this.recordId,vfPageNameDec:vfPageName })
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            const rechargeLetterSuccess = new ShowToastEvent({
                title:  this.letterType+' Letter Attached to Claim',
                message: this.letterType+ 'Letter has been generated',
                variant: 'success',
            });
            this.dispatchEvent(rechargeLetterSuccess);
        })
        .catch(error => {
            console.log(error);
            this.dispatchEvent(new CloseActionScreenEvent());
            const rechargeError = new ShowToastEvent({
                title: 'Could not generate Recharge Letter',
                message: 'Could not generate Recharge Letter',
                variant: 'error',
            });
            this.dispatchEvent(rechargeError);
        });
    }
    viewDocument() {
    this.viewButton=false;

        if(this.selectedOpt == ''){
            this.optionSelected=true;
        }
        else if (this.selectedOpt == 'rechargeLetter') {
            this.optionSelected=false;
            window.open('/apex/CSX_CMP_RechargeLetterPage?recordId=' + this.recordId, '_blank');
        }
        else if (this.selectedOpt == 'declinationLetter') {
            this.optionSelected=false;
            if(this.developerName==='Freight'){
                window.open('/apex/CSX_CMP_FreightDeclineLetter?id=' + this.recordId, '_blank');
            }
            if(this.developerName==='Revenue_Contract_Refund'){
                window.open('/apex/CSX_CMP_ContractRefundDeclineLetter?id=' + this.recordId, '_blank');
            }
            if(this.developerName==='Revenue_Overcharge'){
                window.open('/apex/CSX_CMP_OverchargeDeclineLetter?id=' + this.recordId, '_blank');
            }
            if(this.developerName==='Revenue_Railroad'){
                window.open('/apex/CSX_CMP_RevenueRailroadDeclineLetter?id=' + this.recordId, '_blank');
            }
           
        }
        else if (this.selectedOpt == 'claimSummary') {
            
           this.dispatchEvent(new CloseActionScreenEvent());
        }
        
    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}