/**************************************************************************************
Apex Class Name     : CSX_CMP_NewClaimWrapper
Function            : Wrapper Class to store all details part of new Claim creation(from Salesforce screen or ShipCSX)
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Akshay           09/11/2023       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_NewClaimWrapper {
	//add all fields which we will get from ShipCSX or Salesforce LWC form
	public Id claimId; //This is used for Backend
    //public String relatedClaimNumber; //this is used for backend Rev-RR - Payable Rchg Claim && Rev-RR Receivable  Rchg Claim [MR -00776]
	public String claimType;
	public String claimRecordType;
	public String claimReason;
	public String previousClaimNumber;
	public String caseNumber; // Case number will be sent by Customer Service // renamed from serviceCaseNumber
	public Date customerClaimDate; // claimDate changed to customerClaimDate
	public String source;
	public String shipCSXUserName;
	public String shipCSXUserId; //shipCSXUserID changed to shipCSXUserId
	public String supplierClaimantName;
	public String supplierClaimantNumber;
	public String supplierClaimantSite;
	public String supplierId; //not added in YAML only for Internal use
	public String customerName;
	public String customerNumber;
	public String customerSite;
	public String customerId; //not added in YAML only for Internal use
	public String claimantReferenceNumber; //claimantRefNumber changed to claimantReferenceNumber
	public String notes; // on UI it will be claimDescription change it to notes
	public String contractNumber; //not added in YAML
	public Date periodBegin; //not added in YAML
	public Date periodEnd; //not added in YAML
	public Boolean derailmentFlag; //on UI needs to be changed to derailment from isDeailment // changed from derailment to derailmentFlag
	public String companyFilingClaim; // on UI needs to be changed from claimantCompanyName to companyFillingClaim
	public String terminal; //not added in YAML
	public String causeCode; //fcdCauseCode changed to causeCode on UI fcd cause also needs to be changed
	public String ruleCode; //fcdRuleCode changed to ruleCode  on uI fcdRule also needs to be changed
	public String ruleSecondary; //fcdSecondary changed to ruleSecondary check on UI if applicable
	public String generalRuleNumber; //not added in YAML
	public Integer gsControlNumber;
	public Date messageDate; //messageDTTM changed to messageDate
	public String gsMessageDTTM; //gsMessageDTTM changed to gsMessageDttm
	public Integer stControlNumber;
	public Integer interchangeControlNumber;
	public String receiverSCAC; //receiverID changed to receiverId // receiverId to receiverSCAC
	public String senderSCAC; //senderID changed to senderId // senderId to senderSCAC
	public Decimal claimAmount;
	public String currencyCode;
	public Decimal exchangeRate;
	public String dealerCode;
	public String dealerValue;
	public String dealerSPLC; //dealerSplc changed to dealerSPLC
	public String dealerReferenceNumber;
	public Date shipmentDate;
	public Date contractCarrierDate;
	public Date fldxFileReceivedDate;
	//public String  railroadClaimReferenceNumber; //railroadClaimRefNum changed to railroadClaimReferenceNumber this can be removed from wrapper
	public String localInterlineTraffic;
	public String transactionType;
	public String claimantCode; //Need to check with Sarath
	public String foreignCustomerClaimNumber; //foreignCustomerClaimNum changed to foreignCustomerClaimNumber
	public Decimal foreignCustomerClaimAmount;
	public String contactName; //mapped to CSX_CMP_Person__c on claim contact
	public String phoneNumber;
	public String email;
	public String sendEmail; //not added to Yaml
	public String fax;
	public String adressLine1;
	public String adressLine2;
	public String cityName; // changed from city to cityName
	public String stateCode; // changed state to stateCode
	public String countryCode; // changed country to countryCode
	public String contactType; //contacttype changed to contactType
	public String companyName; // changed from company to companyName
	public String vin; // only for UI
	public String equipmentId; // only for UI
	public String ldReportNumber; //not added to Yaml
	public String remarks;
	//Below fields are from Salvage
	public String scac; // changed from carrierCode to scac
	public Integer salvageFileNumber; //salvageFileNum changed to salvageFileNumber
	public Boolean packageLostFlag; // changed from packageLost to packageLostFlag
	public Decimal amount;
	public String proceedsCode; // changed from code to proceedsCode
	public Boolean noWaybill;
	//public String  originalAmount; //not added in YAML , data type change to decimal
	public string stagingRecordId; // This is used for Backend

	public list<EquipmentORClaimLine> equipment; //renamed to equipment

	public class EquipmentORClaimLine {
		public String equipmentInitial;
		public String equipmentNumber;
		public String waybillNumber;
		public Date waybillDate;
		public String waybillControls; // waybillControlCode changed to waybillControls
		public String stcc; //stccCode changed to stcc and change in ldrcontroller as well
		public String stccDescription;
		public String stccShortDescription; // not required for YAML
		public String originRoadNumber;
		public String originAuditNumber;
		public String actualOriginCityName; // actOriginCity changed to actualOriginCityName
		public String actualOriginStateCode; // actOriginState changed to actualOriginStateCode
		public String actualOriginSCAC; // actOriginRoad to actualOriginSCAC
		public String actualDestinationStateCode; // actDestinationState changed to actualDestinationStateCode
		public String actualDestinationCityName; // actDestinationCity changed to actualDestinationCityName
		public String actualDestinationSCAC; // actDestinationRoad changed to actualDestinationSCAC
		public string destinationRoadNumber;
		public String destinationAuditNumber;
		public String shipperCode;
		public String consigneeCode;
		public String equipmentId;
		// public String  equpmentI; // used for EDI // spell check

		public String urrwinNumber;
		public Date urrwinDate;
		public String challengeDate;
		public String isSettlementDate;
		public String adjustmentDate;
		public String billofLadingDate; //boLDate changed to billofLadingDate
		public String billofLadingNumber; //boLNumber changed to  billofLadingNumber
		public Integer numberOfCars; // not added in Yaml
		public Decimal weight; // not added in Yaml
		public Decimal unitRefundPrice; // not added in Yaml
		public Decimal receivedAmount; //correctAmount
		public Decimal claimAmount;
		public Decimal settlementAmount;
		public String unitType;
		public String shipperName;
		public String shipperAddressLine1; // shipperAddr1 changed to shipperAddressLine1
		public String shipperAddressLine2; // shipperAddr2 changed to shipperAddressLine2
		public String shipperCityName; // shipperCity changed to shipperCityName
		public String shipperStateCode; // shipperState changed to shipperStateCode
		public String shipperPostalCode; // shipperZip changed to shipperPostalCode
		public String consigneeName;
		public String consigneeAddressLine1; // consigneeAddr1 changed to consigneeAddressLine1
		public String consigneeAddressLine2; // consigneeAddr2 changed to consigneeAddressLine2
		public String consigneeCityName; // consigneeCity changed to consigneeCityName
		public String consigneeStateCode; // consigneeState changed to consigneeStateCode
		public String consigneePostalCode; // consigneeZip changed to consigneePostalCode
		public String originSwitchRoad;
		public String destinationSwitchRoad;
		public String fullRoad;
		public Integer equipmentPosition; // carPosition changed to equipmentPosition
		public String oncomingSCAC; // oncomingRoad changed to oncomingSCAC
		public String offgoingSCAC; // offgoingRoad changed to offgoingSCAC
		public String oncomingCityName; // oncomingCity changed to oncomingCityName
		public String oncomingStateCode; // oncomingState changed to oncomingStateCode
		public String offgoingCityName; // offgoingCity changed to offgoingCityName
		public String offgoingStateCode; // offgoingState changed to offgoingStateCode
		public String shipperAsClaimant;
		public String piggybackPlanNumber;
		public String mvManufacturingCode;
		public Integer multiCarCount; //need to check , data type change
		public Boolean waybillFoundFlag; //not present in Yaml
		public Date freightBillDate;
		public String freightBillAmount;
		public String freightBillNumber;
		public String flatCarId; // flatCar changed to flatCarId
		public String shipperLegalEntityId; //shipperLeCode changed to shipperLegalEntityCode // shipperLegalEntityCode changed to shipperLegalEntityId
		public String consigneeLegalEntityId; //consigneeLeCode changed to consigneeLegalEntityCode // consigneeLegalEntityCode changed to consigneeLegalEntityId
		public String ldReportId;
		public String patronCode; // not present in Yaml added for shipcsx ovecharge customer population

		public String businessUnit; // not present in Yaml 

		// FLDX specific fields
		public String wayBillFromFSAC;
		public String wayBillToFSAC;

		public list<Distribution> distributions;
		public list<Product> products;
		public Decimal originalAmount;      //amountPaid_OverchargeClaim
	}

	public class CustomerDamage {
		public String damageId; //damageID changed to damageId
		public decimal amount;
		public String area;
		public String type;
		public String severity; //sev changed to severity
	}

	public class Distribution {
		@AuraEnabled
		public String junctionCode; // junction changed to junctionCode
		@AuraEnabled
		public Integer miles;
		@AuraEnabled
		public String roadReceivePapers; // it should be string
		@AuraEnabled
		public Decimal manualAdjustedAmount; //manualAdjAmount changed to manualAdjustedAmount
		@AuraEnabled
		public Decimal foreignBilledAmount;
		@AuraEnabled
		public String scac; //based on this carrier code query account and assign id // carrierCode changed to scac
		@AuraEnabled
		public String roadType;
		@AuraEnabled
		public Integer routeSequenceNumber;
	}

	public class Product {
		@AuraEnabled
		public String vin;
		@AuraEnabled
		public String description; //productDescription changed to description, add stcc description
		@AuraEnabled
		public String uom;
		@AuraEnabled
		public Integer quantity;
		@AuraEnabled
		public String equipmentId;
		@AuraEnabled
		public list<CustomerDamage> customerDamages; //customerdamages changed to customerDamages
	}
}