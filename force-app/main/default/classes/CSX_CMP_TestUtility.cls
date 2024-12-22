/**************************************************************************************
Apex Class Name     : CSX_CMP_TestUtility
Function            : Object and User creation , this can be helpful to write test class
Author              : Infosys
Modification Log    :
* Developer         : Date             Description
* ----------------------------------------------------------------------------                 
* Infosys           31/10/2023        First version of this class.
*************************************************************************************/

@isTest(SeeAllData=false)
public class CSX_CMP_TestUtility {
	// Claim Creation Payloads for different scenerios
	/**
     @description : This method is used to create claim creation request for Freight Claim
     @return : Map<String,String> : claim creation request
      */
	public static Map<String, String> newFreightClaimCreationRequest() {
		Account supplierAccount = [
			SELECT Id
			FROM Account
			WHERE CSX_CMP_External_ID__c = 'RebeccoOilIncCorporationUSA'
			LIMIT 1
		];
		// Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Freight').getRecordTypeId();
		Map<String, String> testData = new Map<String, String>();
		testData.put('claimAmount', '230');
		testData.put('notes', 'this is test description');
		testData.put('claimType', 'FC RR Inbound Claim');
		testData.put('contactName', 'mark');
		testData.put('customerClaimDate', '2024-01-17T06:13:08.651Z');
		testData.put('claimantReferenceNumber', '123456');
		testData.put('email', 'vaishnavi.nerkar@infosys.com');
		testData.put('causeCode', '');
		testData.put('ruleCode', '');
		testData.put('derailment', '');
		testData.put('phoneNumber', '9876547659');
		testData.put('reason', 'Broken Bands');
		testData.put('claimRecordType', 'Freight');
		testData.put('noWaybill', 'false');
		testData.put('source', 'Manual');
		testData.put('equipment', fetchSampleShipmentJSON());
		testData.put('sendEmail', 'true');
		testData.put('supplierId', supplierAccount.Id);
		testData.put('terminal', '');
        testData.put('SuppliedName', 'test');
		testData.put('derailment', 'true');
		return testData;
	}

	/**
    @description : This method is used to create claim creation request for Revenue Contract Claim
    @return : Map<String,String> : claim creation request
     */
	public static Map<String, String> newRevenueContractClaimCreationRequest() {
		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
			.get('Revenue_Contract_Refund')
			.getRecordTypeId();
		Account supplierAccount = [
			SELECT Id
			FROM Account
			WHERE CSX_CMP_External_ID__c = 'RebeccoOilIncCorporationUSA'
			LIMIT 1
		];
		CSX_CMP_Contract__c contract = [
			SELECT Id
			FROM CSX_CMP_Contract__c
			WHERE CSX_CMP_Customer_Name__r.CSX_CMP_External_ID__c = 'csxtransportationfreightclaims'
			LIMIT 1
		];
		Map<String, String> request = new Map<String, String>();
		request.put('claimAmount', '11000');
		request.put('claimType', 'Sidetrack Claim');
		request.put('claimRecordType', 'Revenue_Contract_Refund');
		request.put('contactName', 'Subodh');
		request.put('customerClaimDate', '2024-04-20');
		request.put('email', 'subodh.deshpande@infosys.com');
		request.put('phoneNumber', '04322334455');
		request.put('sendEmail', 'true');
		request.put('supplierId', supplierAccount.Id);
		request.put('contractNumber', contract.Id);
		request.put('recTypeId', caseRecordTypeId);
		request.put('source', 'Manual');
		// request.put('companyFilingClaim','001Dz00002lCMYJIA4');
		request.put('equipment', fetchSampleClaimLine());
		request.put('notes', 'Test');
		return request;
	}

	public static Map<String, String> newRevenueOverchargeClaimCreationRequest() {
		Map<String, String> request = new Map<String, String>();
		request.put('claimAmount', '600');
		request.put('claimType', 'Overcharge carload claim');
		request.put('claimRecordType', 'Revenue_Overcharge');
		request.put('contactName', 'Subodh');
		request.put('customerClaimDate', '2024-04-07');
		request.put('email', 'subodh.deshpande@infosys.com');
		request.put('source', 'shipCSX');
		request.put('equipment', fetchSampleClaimLine());
		return request;
	}

	/**
    @description : This method is used to create claim creation request for SHIPCSX Claim
    @return : CSX_CMP_NewClaimWrapper : claim creation request
     */
	public static CSX_CMP_NewClaimWrapper claimInputForShipCSX() {
		CSX_CMP_NewClaimWrapper inputClaimDetails = new CSX_CMP_NewClaimWrapper();
		inputClaimDetails.claimAmount = 10;
		inputClaimDetails.claimReason = 'shortage';
		inputClaimDetails.claimRecordType = 'Freight';
		inputClaimDetails.claimType = 'FC Customer Claim';
		inputClaimDetails.packageLostFlag = false;
		inputClaimDetails.email = 'akhil.makam@infosys.com';
		inputClaimDetails.contactName = 'Akhil';
		inputClaimDetails.source = 'SHIPCSX';
		inputClaimDetails.sendEmail = 'false';

		inputClaimDetails.equipment = new List<CSX_CMP_NewClaimWrapper.EquipmentORClaimLine>();
		CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipOrClaimLines = new CSX_CMP_NewClaimWrapper.EquipmentORClaimLine();
		equipOrClaimLines.equipmentInitial = 'CSXT';
		equipOrClaimLines.equipmentNumber = '143030';
		equipOrClaimLines.waybillNumber = '899990';
		equipOrClaimLines.waybillDate = Date.valueOf('2024-01-02');
		equipOrClaimLines.waybillControls = '712015951899990231206';

		equipOrClaimLines.products = new List<CSX_CMP_NewClaimWrapper.Product>();
		CSX_CMP_NewClaimWrapper.Product product = new CSX_CMP_NewClaimWrapper.Product();
		product.vin = '4T3LWRFVXPU102091';
		equipOrClaimLines.products.add(product);

		inputClaimDetails.equipment.add(equipOrClaimLines);

		return inputClaimDetails;
	}

	/**
    @description : This method is used to create claim creation request for Revenue Railroad Claim
    @return : Map<String,String> : claim creation request
     */
	public static Map<String, String> newRevenueRailRoadClaimCreationRequest() {
		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
			.get('Revenue_Railroad')
			.getRecordTypeId();
		Account supplierAccount = [
			SELECT Id
			FROM Account
			WHERE CSX_CMP_External_ID__c = 'RebeccoOilIncCorporationUSA'
			LIMIT 1
		];
		Map<String, String> testData = new Map<String, String>();
		testData.put('claimType', 'Rev-RR - Payable Claim');
		testData.put('claimReason', 'PAY - Rule 185A1a');
		testData.put('supplierId', supplierAccount.Id);
		testData.put('contactName', 'Subodh');
		testData.put('phoneNumber', '04322334455');
		testData.put('email', 'subodh.deshpande@infosys.com');
		testData.put('customerClaimDate', '2024-05-07');
		testData.put('notes', 'Test');
		testData.put('equipment', fetchSampleClaimLine());
		testData.put('sendEmail', 'false');
		testData.put('claimRecordType', 'Revenue_Railroad');
		testData.put('claimAmount', '100');
		testData.put('source', 'Manual');
		testData.put('recTypeId', caseRecordTypeId);
		testData.put('recTypeName', 'Revenue Railroad');
		return testData;
	}

	/**
    @description : This method is used to create Equipment data for claim creation
    @return : String : Serialized Equipment data
     */
	public static String fetchSampleShipmentJSON() {
		//  '[{"equipmentInitial":"CSXT","equipmentNumber":"143030","waybillNumber":"887966","waybillDate":"2024-01-02","consignee":"GENERAL MOTORS LLC","stcc":"3030570","shipper":"GENERAL MOTORS DE MEXICO","originState":"GJ","destinationState":"OH","commodityNumber":"3030570","stccDescription":"test STCC description","actOriginCity":"SILAO","actDestinationCity":"CEMENTDAL","actOriginRoad":"FXE","originRoadNumber":"0295","originAuditNumber":"000574","waybillControlCode":"712012097873167240302","products":[{"vin":"4T3LWRFVXPU102091","customerDamages":[]}],"distributions":[{"scac":"ddd","junctionCode":"EAGPA"},{"scac":"UP","junctionCode":"DANVJ"}]}]';
		List<Map<String, Object>> shipments = new List<Map<String, Object>>();
		Map<String, Object> shipment = new Map<String, Object>();
		shipment.put('equipmentInitial', 'CSXT');
		shipment.put('equipmentNumber', '143030');
		shipment.put('waybillNumber', '887966');
		shipment.put('waybillDate', '2024-01-02');
		shipment.put('consignee', 'GENERAL MOTORS LLC');
		shipment.put('stcc', '3030570');
		shipment.put('shipper', 'GENERAL MOTORS DE MEXICO');
		shipment.put('originState', 'GJ');
		shipment.put('destinationState', 'OH');
		shipment.put('commodityNumber', '3030570');
		shipment.put('stccDescription', 'test STCC description');
		shipment.put('actOriginCity', 'SILAO');
		shipment.put('actDestinationCity', 'CEMENTDAL');
		shipment.put('actOriginRoad', 'FXE');
		shipment.put('originRoadNumber', '0295');
		shipment.put('originAuditNumber', '000574');
		shipment.put('waybillControlCode', '712012097873167240302');
		shipment.put('shipperLegalEntityId', '4847997');
		shipment.put('consigneeLegalEntityId', '9098012');
		List<Map<String, Object>> customerDamages = new List<Map<String, Object>>();
		Map<String, Object> customerDamage = new Map<String, Object>();
		customerDamages.add(customerDamage);
		List<Map<String, Object>> products = new List<Map<String, Object>>();
		Map<String, Object> product = new Map<String, Object>();
		product.put('vin', '4T3LWRFVXPU102091');
		product.put('customerDamages', customerDamages);
		products.add(product);
		product = new Map<String, Object>();
		product.put('description', 'test');
		product.put('customerDamages', customerDamages);
		products.add(product);
		shipment.put('products', products);
		List<Map<String, Object>> distributions = new List<Map<String, Object>>();
		Map<String, Object> distribution = new Map<String, Object>();
		distribution.put('scac', 'BNSF');
		distribution.put('junctionCode', 'EAGPA');
		distribution.put('miles', '10');
		distributions.add(distribution);
		distribution = new Map<String, String>();
		distribution.put('scac', 'BNSF');
		distribution.put('junctionCode', 'DANVJ');
		distribution.put('miles', '20');
		distributions.add(distribution);
		distribution = new Map<String, String>();
		distribution.put('scac', 'BNSF');
		distribution.put('junctionCode', 'EAGPB');
		distribution.put('miles', '30');
		distributions.add(distribution);
		distribution = new Map<String, String>();
		distribution.put('scac', 'BNSF');
		distribution.put('junctionCode', 'EAGPC');
		distribution.put('miles', '40');
		distributions.add(distribution);
		shipment.put('distributions', distributions);
		shipments.add(shipment);

		return JSON.serialize(shipments);
	}

	/**
    @description : This method is used to create Claim Line data for claim creation
    @return : String : Serialized Claim Line data
     */
	public static String fetchSampleClaimLine() {
		return '[{"urrwinNumber":"123456","urrwinDate":"2023-02-13","commodityNumber":"123457","description":"Testing","equipmentInitial":"CSXT","equipmentNumber":"143030","waybillNumber":"127356","waybillDate":"2024-02-07","claimAmount":50,"totalCars":"5","stcc":"3456349","actualOriginStateCode":"NJ","actualOriginCityName":"CLIFFWOOD","actualDestinationStateCode":"NY","actDestinationCity":"NEWYORK","adjustmentDate":"2023-04-15T00:00:00Z","challengeDate":"2023-04-10T00:00:00Z","isSettlementDate":"2023-04-09T00:00:00Z","waybillControlCode":"712012097873167240302","products":[], "distributions":[], "salvages":[]}]';
	}

	// LD Report Creation Payloads for different scenerios

	/**
    @desciption : This method is used to create LD Report Creation request for various type
    @param : type : String : Type of LD Report
    @return : Map<String,String> : LD Report Creation request
     */
	public static Map<String, String> newLDReportCreationRequest(String type) {
		Map<String, String> ldReport = new Map<String, String>();
		ldReport.put('reportType', type);
		ldReport.put('damageReason', 'Damage');
		ldReport.put('cause', 'Derailment');
		ldReport.put('incidentAction', 'Recovery');
		ldReport.put('milepost', '988');
		ldReport.put('incidentState', 'OH');
		ldReport.put('incidentCity', 'CLEVELAND');
		ldReport.put('pickupAddress', '4/6, 13th Street');
		ldReport.put('estimatedLadingLoss', '1000');
		ldReport.put('incidentComments', 'This is test comment');
		ldReport.put('reportedDate', '2024-04-02');
		ldReport.put('reportedBy', 'Subodh Deshpande');
		ldReport.put('source', 'Manual');
		ldReport.put('incidentDate', '2024-04-02');

		// Customer type specific fields
		ldReport.put('contactId', '');
		ldReport.put('contactName', 'Test Contact FORD MOTOR CO');
		ldReport.put('phone', '');
		ldReport.put('email', 'FordMotorCo@csx.com');
		ldReport.put('damageLocation', 'Doorway');
		ldReport.put('bracingMethod', 'Crossmembers');
		ldReport.put('disposition', 'Dumped');
		ldReport.put('productCondition', 'Broken');
		ldReport.put('visibleDamage', 'false');
		ldReport.put('canNotUnload', 'false');
		ldReport.put('unloadingExceededHours', 'false');
		ldReport.put('productRecords', '[{\"quantity\":5,\"productDescription\":\"test STCC description\"}]');
		ldReport.put('sendEmail', 'false');
		ldReport.put('trackId', '');
		ldReport.put('racfId', '');
		ldReport.put('pickupState', 'GA');
		ldReport.put('pickupCity', 'Savannah');
		ldReport.put('productConditionOther', '');
		ldReport.put('bracingMethodOther', '');
		ldReport.put('dispositionOther', '');

		// In Transit type specific fields
		ldReport.put('multipleBadOrders', 'false');
		ldReport.put('badOrderComments', 'Test Comments');
		ldReport.put('noWaybill', 'false');
		ldReport.put('equipNo', '');
		ldReport.put('vin', '');

		// Recovery type specific fields
		ldReport.put('recoveryAmount', '0');

		ldReport.put('equipment', fetchSampleShipmentJSON());
		return ldReport;
	}

	// JSON Payloads for Creation of Claim and LD Report

	/**
    @description : This method is used to create JSON payload for Claim Creation
    @return : String : JSON payload for Claim Creation
     */
	public static String claimCreationJSON() {
		Map<String, Object> claimCreation = new Map<String, Object>();
		claimCreation.put('claimType', 'FC Customer Automobile Claim');
		claimCreation.put('claimRecordType', 'Freight');
		claimCreation.put('claimReason', 'No bill');
		claimCreation.put('previousClaimNumber', '');
		claimCreation.put('customerClaimDate', '2024-02-01');
		claimCreation.put('source', 'EDI');
		claimCreation.put('claimAmount', 8000);
		claimCreation.put('shipCSXUserName', 'Test User');
		claimCreation.put('shipCSXUserId', 'ESC334');
		claimCreation.put('supplierClaimantName', 'BURLINGTON NORTHERN SANTA FE');
		claimCreation.put('supplierClaimantNumber', '1000020957');
		claimCreation.put('claimantReferenceNumber', '12234');
		claimCreation.put('notes', 'Test notes');
		claimCreation.put('derailment', true);
		claimCreation.put('causeCode', '01');
		claimCreation.put('ruleCode', '104');
		claimCreation.put('gsControlNumber', 34179903);
		claimCreation.put('messageDate', '2023-12-11');
		claimCreation.put('stControlNumber', 345);
		claimCreation.put('interchangeControlNumber', 987);
		claimCreation.put('senderSCAC', '433223');
		claimCreation.put('currencyCode', 'USD');
		claimCreation.put('exchangeRate', 34.23);
		claimCreation.put('dealerCode', 'dealerCode');
		claimCreation.put('dealerValue', 'dealerValu');
		claimCreation.put('dealerSplc', 'dealerSPLC');
		claimCreation.put('dealerReferenceNumber', 490);
		claimCreation.put('shipmentDate', '2023-01-31');
		claimCreation.put('contractCarrierDate', '2023-04-09');
		claimCreation.put('fldxFileReceivedDate', '2022-09-23');
		claimCreation.put('localInterlineTraffic', 'localInterlineTraffic');
		claimCreation.put('transactionType', 'transactionType');
		claimCreation.put('claimantCode', 'CC');
		claimCreation.put('foreignCustomerClaimAmount', 8776);
		claimCreation.put('contactName', 'Subodh Deshpande');
		claimCreation.put('phoneNumber', '2110998765');
		claimCreation.put('email', 'subodh.deshpande@infosys.com');
		claimCreation.put('fax', 'fax');
		claimCreation.put('adressLine1', 'address1');
		claimCreation.put('adressLine2', 'address2');
		claimCreation.put('city', 'city');
		claimCreation.put('state', 'state');
		claimCreation.put('country', 'country');
		claimCreation.put('contactType', 'type');
		claimCreation.put('company', 'company');
		claimCreation.put('department', 'department');
		claimCreation.put('carrierCode', 'carrierCo');
		claimCreation.put('salvageFileNumber', 70);
		claimCreation.put('code', '03');
		claimCreation.put('ldReportNumber', '');
		List<Map<String, Object>> equipment = new List<Map<String, Object>>();
		Map<String, Object> equipmentMap = new Map<String, Object>();
		equipmentMap.put('equipmentNumber', '143030');
		equipmentMap.put('equipmentInitial', 'CSXT');
		equipmentMap.put('waybillNumber', '946830');
		equipmentMap.put('waybillControlCode', '712-015249-946830-220913');
		equipmentMap.put('actOriginState', 'FL');
		equipmentMap.put('actOriginCity', 'RIDGEWOOD');
		equipmentMap.put('actDestinationState', 'FL');
		equipmentMap.put('actDestinationCity', 'MEMPHIS');
		equipmentMap.put('originalAmount', -7828.78);
		equipmentMap.put('claimAmount', 90712.736);
		equipmentMap.put('receivedAmount', -927.23);
		equipmentMap.put('settlementAmount', 724.9);
		equipmentMap.put('shipperName', 'MOSAIC FERTILIZER LLC');
		equipmentMap.put('consigneeName', 'MOSAIC FERTILIZER LLC');
		equipmentMap.put('primaryRemarks', 'remarks primary');
		equipmentMap.put('secondaryRemarks', 'remarks secondary');
		equipmentMap.put('shipperLegalEntityCode', '4847997');
		equipmentMap.put('consigneeLegalEntityCode', '4869012');
		List<Map<String, Object>> products = new List<Map<String, Object>>();
		Map<String, Object> productMap = new Map<String, Object>();
		productMap.put('vin', '4T3LWRFVXPU102091');
		productMap.put('description', 'Test description');
		productMap.put('quantity', null);
		List<Map<String, Object>> customerdamages = new List<Map<String, Object>>();
		Map<String, Object> customerdamage = new Map<String, Object>();
		customerdamage.put('amount', 5000);
		customerdamage.put('area', '10');
		customerdamage.put('type', '34');
		customerdamage.put('severity', '01');
		customerdamages.add(customerdamage);
		Map<String, Object> customerdamage1 = new Map<String, Object>();
		customerdamage1.put('amount', 5500);
		customerdamage1.put('area', '39');
		customerdamage1.put('type', '03');
		customerdamage1.put('severity', '04');
		customerdamages.add(customerdamage1);
		productMap.put('customerdamages', customerdamages);
		products.add(productMap);
		equipmentMap.put('products', products);

		List<Map<String, Object>> distributions = new List<Map<String, Object>>();
		Map<String, Object> distribution = new Map<String, Object>();
		distribution.put('scac', 'BNSF');
		distribution.put('junctionCode', 'EAGPC');
		distribution.put('miles', 30);
		distribution.put('manualAdjAmt', 30);
		distributions.add(distribution);
		Map<String, Object> distribution1 = new Map<String, Object>();
		distribution1.put('scac', 'BNSF');
		distribution1.put('junctionCode', 'EAGPD');
		distribution1.put('miles', 40);
		distribution1.put('manualAdjAmt', 40);
		distributions.add(distribution1);
		Map<String, Object> distribution2 = new Map<String, Object>();
		distribution2.put('scac', 'BNSF');
		distribution2.put('junctionCode', 'EAGPE');
		distribution2.put('miles', 50);
		distribution2.put('manualAdjAmt', 50);
		distributions.add(distribution2);
		Map<String, Object> distribution3 = new Map<String, Object>();
		distribution3.put('scac', 'BNSF');
		distribution3.put('junctionCode', 'EAGPA');
		distribution3.put('miles', 10);
		distribution3.put('manualAdjAmt', 10);
		distributions.add(distribution3);
		Map<String, Object> distribution4 = new Map<String, Object>();
		distribution4.put('scac', 'BNSF');
		distribution4.put('junctionCode', 'EAGPB');
		distribution4.put('miles', 20);
		distribution4.put('manualAdjAmt', 20);
		distributions.add(distribution4);
		Map<String, Object> distribution5 = new Map<String, Object>();
		distribution5.put('scac', 'BNSF');
		distribution5.put('junctionCode', 'EAGPF');
		distribution5.put('miles', 30);
		distribution5.put('manualAdjAmt', 30);
		distributions.add(distribution5);
		Map<String, Object> distribution6 = new Map<String, Object>();
		distribution6.put('scac', 'BNSF');
		distribution6.put('junctionCode', 'EAGPG');
		distribution6.put('miles', 40);
		distribution6.put('manualAdjAmt', 40);
		distributions.add(distribution6);
		Map<String, Object> distribution7 = new Map<String, Object>();
		distribution7.put('scac', 'BNSF');
		distribution7.put('junctionCode', 'EAGPH');
		distribution7.put('miles', 20);
		distribution7.put('manualAdjAmt', 20);
		distributions.add(distribution7);
		Map<String, Object> distribution8 = new Map<String, Object>();
		distribution8.put('scac', 'BNSF');
		distribution8.put('junctionCode', 'EAGPI');
		distribution8.put('miles', 22);
		distribution8.put('manualAdjAmt', 22);
		distributions.add(distribution8);
		Map<String, Object> distribution9 = new Map<String, Object>();
		distribution9.put('scac', 'BNSF');
		distribution9.put('junctionCode', 'EAGPJ');
		distribution9.put('miles', 12);
		distribution9.put('manualAdjAmt', 12);
		distributions.add(distribution9);

		equipmentMap.put('distributions', distributions);
		equipment.add(equipmentMap);
		claimCreation.put('equipment', equipment);
		// System.debug('claimCreation : ' + JSON.serialize(claimCreation));
		return JSON.serialize(claimCreation);
	}

	/**
	{
    "claims": [
        {
            "loadSequence": "",
            "debitHeader": "",
            "loadKey": 19090000,
            "recordIdentifier": 0,
            "fldxFileReceivedDate": "2019-09-01"
        },
        {
            "claimantReferenceNumber": "0055356228",
            "waybillNumber": 482300,
            "secondaryRemarks": "00000",
            "actualDestinationSCAC": "0712",
            "loadKey": 190901030055356228,
            "WaybillFound": "Y",
            "actualOriginSCAC": "0103",
            "equipmentInitial": "CSXT",
            "originAuditNumber": 58850,
            "primaryRemarks": "00616",
            "shipperCode": "NISNORAMA",
            "claimantCode": 4,
            "claimType": "Recharges Inbound Claim",
            "multiCarCount": "00",
            "actualOriginCityName": "CANTON",
            "senderSCAC": "0103",
            "causeCode": "03",
            "salvageCarrierCode": "",
            "piggybackPlanNumber": "",
            "actualDestinationCityName": "DORAUT",
            "fldxFileReceivedDate": "2019-09-01",
            "actualOriginStateCode": "MS",
            "mvManufacturingCode": "",
            "actualDestinationStateCode": "NJ",
            "amount": 43.617,
            "salvageProceeds": 0,
            "equipmentNumber": 600081,
            "localInterlineTraffic": 2,
            "destinationAuditNumber": 39205,
            "shipperAsClaimant": "",
            "proceedsCode": 2,
            "stcc": 3711120,
            "consigneeCode": "NISNORAMA",
            "recordIdentifier": 1,
            "waybillDate": "2018-07-15"
        },
        {
            "claimantReferenceNumber": "0055356228",
            "packageLostFlag": "",
            "foreignCustomerClaimAmount": 357.64,
            "loadKey": 190901030055356228,
            "roadReceivePapers": "",
            "freightBillDate": "",
            "ruleSecondary": "000",
            "ruleCode": "050",
            "senderSCAC": "0103",
            "claimReceivedDate": "2018-10-11",
            "vin": "1N6BF0LY8JN812561",
            "foreignCustomerClaimNumber": "CLA216724",
            "recordIdentifier": 2,
            "salvageFileNumber": "",
            "currencyCode": "USD",
            "fldxFileReceivedDate": "2019-09-01"
        },
        {
            "distributionTypeCode2": "P",
            "distributionTypeCode1": "P",
            "claimantReferenceNumber": "0055356228",
            "roadCode2": 712,
            "roadCode1": "0103",
            "roadCode3": "0000",
            "loadKey": 190901030055356228,
            "miles1": "0237",
            "miles2": 1387,
            "distributionTypeCode3": "",
            "miles3": "0000",
            "totalAmount1": 0,
            "amountProrated1": 0,
            "totalAmount3": 0,
            "senderSCAC": "0103",
            "amountProrated2": 43.17,
            "totalAmount2": 43.17,
            "amountProrated3": 0,
            "fldxFileReceivedDate": "2019-09-01",
            "junction1": "MEMPH",
            "junction2": "MEMPH",
            "junction3": "",
            "specialAmount1": 0,
            "specialAmount2": 0,
            "specialAmount3": 0,
            "recordIdentifier": 3
        },
        {
            "senderSCAC": "0103",
            "debitHeader": "SUBRD SUMMARY",
            "summaryClaimCount": "000001",
            "summaryRecordCount": "0000003",
            "loadKey": "19090103SUBRD SUMMARY",
            "recordIdentifier": 7,
            "summaryClaimAmount": 43.17,
            "fldxFileReceivedDate": "2019-09-01"
        },
        {
            "debitHeader": "TAPE SUMMARY",
            "summaryClaimCount": "000001",
            "summaryRecordCount": "0000006",
            "totalClaimAmount": 43.17,
            "loadKey": "19090000TAPE SUMMARY",
            "recordIdentifier": 9,
            "fldxFileReceivedDate": "2019-09-01"
        }
    ]
}
	 */

	 /**
	@description : This method is used to create JSON payload for FLDX Claim Creation
	@return : String : JSON payload for FLDX Claim Creation
	 */

	public static String fldxClaimCreationJSON() {
		Map<String, Object> fldxClaimCreation = new Map<String, Object>();
		List<Map<String, Object>> claims = new List<Map<String, Object>>();
		Map<String, Object> claim1 = new Map<String, Object>();
		claim1.put('loadSequence', '');
		claim1.put('debitHeader', '');
		claim1.put('loadKey', 19090000);
		claim1.put('recordIdentifier', 0);
		claim1.put('fldxFileReceivedDate', '2019-09-01');
		claims.add(claim1);

		Map<String, Object> claim2 = new Map<String, Object>();
		claim2.put('claimantReferenceNumber', '0055356228');
		claim2.put('waybillNumber', 482300);
		claim2.put('secondaryRemarks', '00000');
		claim2.put('actualDestinationSCAC', '0712');
		claim2.put('loadKey', '190901030055356228');
		claim2.put('WaybillFound', 'Y');
		claim2.put('actualOriginSCAC', '0103');
		claim2.put('equipmentInitial', 'CSXT');
		claim2.put('originAuditNumber', 58850);
		claim2.put('primaryRemarks', '00616');
		claim2.put('shipperCode', 'NISNORAMA');
		claim2.put('claimantCode', 4);
		claim2.put('claimType', 'Recharges Inbound Claim');
		claim2.put('multiCarCount', '00');
		claim2.put('actualOriginCityName', 'CANTON');
		claim2.put('senderSCAC', '0103');
		claim2.put('causeCode', '03');
		claim2.put('salvageCarrierCode', '');
		claim2.put('piggybackPlanNumber', '');
		claim2.put('actualDestinationCityName', 'DORAUT');
		claim2.put('fldxFileReceivedDate', '2019-09-01');
		claim2.put('actualOriginStateCode', 'MS');
		claim2.put('mvManufacturingCode', '');
		claim2.put('actualDestinationStateCode', 'NJ');
		claim2.put('amount', 43.617);
		claim2.put('salvageProceeds', 0);
		claim2.put('equipmentNumber', 600081);
		claim2.put('localInterlineTraffic', 2);
		claim2.put('destinationAuditNumber', 39205);
		claim2.put('shipperAsClaimant', '');
		claim2.put('proceedsCode', 2);
		claim2.put('stcc', 3711120);
		claim2.put('consigneeCode', 'NISNORAMA');
		claim2.put('recordIdentifier', 1);
		claim2.put('waybillDate', '2018-07-15');
		claims.add(claim2);

		Map<String, Object> claim3 = new Map<String, Object>();
		claim3.put('claimantReferenceNumber', '0055356228');
		claim3.put('packageLostFlag', '');
		claim3.put('foreignCustomerClaimAmount', 357.64);
		claim3.put('loadKey', '190901030055356228');
		claim3.put('roadReceivePapers', '');
		claim3.put('freightBillDate', '');
		claim3.put('ruleSecondary', '000');
		claim3.put('ruleCode', '050');
		claim3.put('senderSCAC', '0103');
		claim3.put('claimReceivedDate', '2018-10-11');
		claim3.put('vin', '1N6BF0LY8JN812561');
		claim3.put('foreignCustomerClaimNumber', 'CLA216724');
		claim3.put('recordIdentifier', 2);
		claim3.put('salvageFileNumber', '');
		claim3.put('currencyCode', 'USD');
		claim3.put('fldxFileReceivedDate', '2019-09-01');
		claims.add(claim3);

		Map<String, Object> claim4 = new Map<String, Object>();
		claim4.put('distributionTypeCode2', 'P');
		claim4.put('distributionTypeCode1', 'P');
		claim4.put('claimantReferenceNumber', '0055356228');
		claim4.put('roadCode2', 712);
		claim4.put('roadCode1', '0103');
		claim4.put('roadCode3', '0000');
		claim4.put('loadKey', '190901030055356228');
		claim4.put('miles1', '0237');
		claim4.put('miles2', 1387);
		claim4.put('distributionTypeCode3', '');
		claim4.put('miles3', '0000');
		claim4.put('totalAmount1', 0);
		claim4.put('amountProrated1', 0);
		claim4.put('totalAmount3', 0);
		claim4.put('senderSCAC', '0103');
		claim4.put('amountProrated2', 43.17);
		claim4.put('totalAmount2', 43.17);
		claim4.put('amountProrated3', 0);
		claim4.put('fldxFileReceivedDate', '2019-09-01');
		claim4.put('junction1', 'MEMPH');
		claim4.put('junction2', 'MEMPH');
		claim4.put('junction3', '');
		claim4.put('specialAmount1', 0);
		claim4.put('specialAmount2', 0);
		claim4.put('specialAmount3', 0);
		claim4.put('recordIdentifier', 3);
		claims.add(claim4);

		Map<String, Object> claim5 = new Map<String, Object>();
		claim5.put('senderSCAC', '0103');
		claim5.put('debitHeader', 'SUBRD SUMMARY');
		claim5.put('summaryClaimCount', '000001');
		claim5.put('summaryRecordCount', '0000003');
		claim5.put('loadKey', '19090103SUBRD SUMMARY');
		claim5.put('recordIdentifier', 7);
		claim5.put('summaryClaimAmount', 43.17);
		claim5.put('fldxFileReceivedDate', '2019-09-01');
		claims.add(claim5);

		Map<String, Object> claim6 = new Map<String, Object>();
		claim6.put('debitHeader', 'TAPE SUMMARY');
		claim6.put('summaryClaimCount', '000001');
		claim6.put('summaryRecordCount', '0000006');
		claim6.put('totalClaimAmount', 43.17);
		claim6.put('loadKey', '19090000TAPE SUMMARY');
		claim6.put('recordIdentifier', 9);
		claim6.put('fldxFileReceivedDate', '2019-09-01');
		claims.add(claim6);

		fldxClaimCreation.put('claims', claims);
		return JSON.serialize(fldxClaimCreation);
	}

	/**
    @description : This method is used to create JSON payload for LD Report Creation
    @return : String : JSON payload for LD Report Creation
     */
	public static String ldrCreationJSON() {
		Map<String, Object> ldrCreation = new Map<String, Object>();
		ldrCreation.put('reportType', 'In transit');
		ldrCreation.put('source', 'MTI');
		ldrCreation.put('cause', 'AWAITING DISPO');
		ldrCreation.put('damageReason', 'I-Broken bands');
		ldrCreation.put('incidentAction', 'Inspection');
		ldrCreation.put('trackId', '');
		ldrCreation.put('incidentDate', '2024-05-03');
		ldrCreation.put('multipleBadOrders', false);
		ldrCreation.put('incidentCity', 'CLEVELAND');
		ldrCreation.put('incidentState', 'OH');
		ldrCreation.put('milepost', '00K649');
		ldrCreation.put('reportedBy', 'Z7350');
		ldrCreation.put('reportedDate', '2024-05-03');
		ldrCreation.put('incidentComments', 'despcrinto');
		ldrCreation.put('noWaybill', false);
		ldrCreation.put('racfId', 'GMLLCF');
		List<Map<String, Object>> equipment = new List<Map<String, Object>>();
		Map<String, Object> equipmentMap = new Map<String, Object>();
		equipmentMap.put('equipmentNumber', '143030');
		equipmentMap.put('equipmentInitial', 'CSXT');
		equipmentMap.put('waybillNumber', 123456);
		equipmentMap.put('flatCar', 'A302');
		equipmentMap.put('shipperLegalEntityCode', '4847997');
		equipmentMap.put('consigneeLegalEntityCode', '9098012');
		List<Map<String, Object>> products = new List<Map<String, Object>>();
		Map<String, Object> productMap = new Map<String, Object>();
		productMap.put('vin', '4T3LWRFVXPU102091');
		productMap.put('uom', null);
		productMap.put('quantity', null);
		productMap.put('description', null);
		products.add(productMap);
		equipmentMap.put('products', products);
		equipment.add(equipmentMap);
		ldrCreation.put('equipment', equipment);
		// System.debug('ldrCreation : ' + JSON.serialize(ldrCreation));
		return JSON.serialize(ldrCreation);
	}

	/**
    @description : This method is used to create Equipment records (Maximum return size is 4)
    @return : List<CSX_CMP_Equipment__c>
     */
	public static List<CSX_CMP_Equipment__c> createEquipmentData(Integer count) {
		List<CSX_CMP_Equipment__c> listEquipment = new List<CSX_CMP_Equipment__c>();
		Integer i = 0;

		List<String> ListEquipmentJSONFreeText = new List<String>();
		ListEquipmentJSONFreeText.add(
			'{"Name":"BMOU 611863","CSX_CMP_Act_Destination_City__c":"MEMPHIS","CSX_CMP_Act_Destination_State__c":"TN","CSX_CMP_Equipment_Initial__c":"BMOU","CSX_CMP_Equipment_Num__c":"611863","CSX_CMP_Act_Origin_City__c":"Savannah Port Auth","CSX_CMP_Origin_Road_Num__c":"130","CSX_CMP_Act_Origin_State__c":"GA","CSX_CMP_STCC__c":"4611110","CSX_CMP_Shipper__c":"MEDITERRANEAN SHIPPING COMPANY (USA) INC","CSX_CMP_Terminal_Name__c":"MEMPHIS","CSX_CMP_Consignee__c":"MEDITERRANEAN SHIPPING COMPANY (USA) INC","CSX_CMP_Waybill_Num__c":"181685","CSX_CMP_Waybill_Controls__c":"188050628449415220511","CSX_CMP_Waybill_Date__c":"2023-06-30","CSX_CMP_Start_Date__c":"2023-06-30","CSX_CMP_STCC_Description__c":"FREIGHT ALL KINDS, (FAK) OR ALL FREIGHT RATE SHIP- MENTS, NEC, OR TRAILER-ON FLATCAR SHIPMENTS, COMMERCIAL (EXCEPT IDEN- TIFIED BY COMMODITIES, THEN CODE BY COMMODITY)","CSX_CMP_Act_Origin_Road__c":"FXE","CSX_CMP_Act_Destination_Road__c":"CSXT","CSX_CMP_Freight_Bill_Date__c":"2023-11-27","CSX_CMP_Amount_Rec__c":1000,"CSX_CMP_Balance_Due__c":0,"CSX_CMP_Billed_Amount__c":1000,"CSX_CMP_Flat_Car__c":"BMOU611863","CSX_CMP_CSX_Waybill_Found__c":false,"CSX_CMP_Freight_Bill_Num__c":"95024343","CSX_CMP_Total_Product_Amount__c": 4170,"CSX_CMP_Total_Manual_Adj_Amount__c":6832.76,"CSX_CMP_Sum_of_Manual_Adj_Amount__c":6832.76,"CSX_CMP_Waybill_Date_Aging__c":307,"CSX_CMP_Point_Records_Count__c":0,"CSX_CMP_Salvage_Count__c":0,"CSX_CMP_Number_of_Distribution_Claim__c":1,"CSX_CMP_Total_Product_Count__c":5,"CSX_CMP_Supplier_Claimant_Type__c":"4"}'
		);
		ListEquipmentJSONFreeText.add(
			'{"Name":"TTGX 693234","CSX_CMP_Act_Destination_City__c":"Buffalo","CSX_CMP_Act_Destination_State__c":"OH","CSX_CMP_Equipment_Initial__c":"TTGX","CSX_CMP_Equipment_Num__c":"693234","CSX_CMP_Act_Origin_City__c":"Talladega","CSX_CMP_Act_Origin_State__c":"AL","CSX_CMP_STCC__c":"3711120","CSX_CMP_Shipper__c":"GEORGIA-PACIFIC LLC","CSX_CMP_Terminal_Name__c":"MEMPHIS","CSX_CMP_Consignee__c":"AMERICAN HONDA MOTOR COMPANY INC","CSX_CMP_Waybill_Num__c":"899990","CSX_CMP_Waybill_Controls__c":"712015951899990231206","CSX_CMP_Waybill_Date__c":"2023-07-12","CSX_CMP_Start_Date__c":"2023-07-12","CSX_CMP_STCC_Description__c":"NA","CSX_CMP_Act_Origin_Road__c":"TDSI","CSX_CMP_CSX_Waybill_Found__c":false,"CSX_CMP_Total_Product_Amount__c":0,"CSX_CMP_Total_Manual_Adj_Amount__c":14125.13,"CSX_CMP_Sum_of_Manual_Adj_Amount__c":14125.13,"CSX_CMP_Waybill_Date_Aging__c":295,"CSX_CMP_Point_Records_Count__c":2,"CSX_CMP_Salvage_Count__c":0,"CSX_CMP_Number_of_Distribution_Claim__c":2,"CSX_CMP_Total_Product_Count__c":2,"CSX_CMP_Supplier_Claimant_Type__c":"4"}'
		);
		ListEquipmentJSONFreeText.add(
			'{"Name":"AZNU 208464","CSX_CMP_Act_Destination_City__c":"JACKSONVILLE","CSX_CMP_Act_Destination_State__c":"FL","CSX_CMP_Equipment_Initial__c":"AZNU","CSX_CMP_Equipment_Num__c":"208464","CSX_CMP_Consignee__c":"WEYERHAEUSER","CSX_CMP_Waybill_Num__c":"846623","CSX_CMP_Waybill_Date__c":"2023-12-04","CSX_CMP_CSX_Waybill_Found__c":false,"CSX_CMP_Total_Product_Amount__c": 0,"CSX_CMP_Total_Manual_Adj_Amount__c":4000,"CSX_CMP_Sum_of_Manual_Adj_Amount__c":4000,"CSX_CMP_Waybill_Date_Aging__c":150,"CSX_CMP_Point_Records_Count__c":0,"CSX_CMP_Salvage_Count__c":0,"CSX_CMP_Number_of_Distribution_Claim__c":1,"CSX_CMP_Total_Product_Count__c":2,"CSX_CMP_Supplier_Claimant_Type__c":"4"}'
		);
		ListEquipmentJSONFreeText.add(
			'{"Name":"BMOU 611863","CSX_CMP_Act_Destination_City__c":"Memphis","CSX_CMP_Act_Destination_State__c":"TN","CSX_CMP_Equipment_Initial__c":"BMOU","CSX_CMP_Equipment_Num__c":"611863","CSX_CMP_Act_Origin_City__c":"Savannah Port Auth","CSX_CMP_Origin_Road_Num__c":"130","CSX_CMP_Act_Origin_State__c":"GA","CSX_CMP_STCC__c":"4611110","CSX_CMP_Shipper__c":"MEDITERRANEAN SHIPPING COMPANY (USA) INC","CSX_CMP_Consignee__c":"MEDITERRANEAN SHIPPING COMPANY (USA) INC","CSX_CMP_Waybill_Num__c":"181685","CSX_CMP_Waybill_Date__c":"2023-06-30","CSX_CMP_STCC_Description__c":"FREIGHT ALL KINDS, (FAK) OR ALL FREIGHT RATE SHIP- MENTS, NEC, OR TRAILER-ON FLATCAR SHIPMENTS, COMMERCIAL (EXCEPT IDEN- TIFIED BY COMMODITIES, THEN CODE BY COMMODITY)","CSX_CMP_Act_Origin_Road__c":"FXE","CSX_CMP_Act_Destination_Road__c":"CSXT","CSX_CMP_Billed_Amount__c":1000,"CSX_CMP_CSX_Waybill_Found__c":false,"CSX_CMP_Freight_Bill_Num__c":"95024343","CSX_CMP_Total_Product_Amount__c": 0,"CSX_CMP_Total_Manual_Adj_Amount__c":4000,"CSX_CMP_Sum_of_Manual_Adj_Amount__c":4000,"CSX_CMP_Waybill_Date_Aging__c":307,"CSX_CMP_Point_Records_Count__c":0,"CSX_CMP_Salvage_Count__c":0,"CSX_CMP_Number_of_Distribution_Claim__c":4,"CSX_CMP_Total_Product_Count__c":3,"CSX_CMP_Supplier_Claimant_Type__c":"4"}'
		);

		for (String equipmentJSON : ListEquipmentJSONFreeText) {
			if (i == count) {
				break;
			}
			CSX_CMP_Equipment__c objEquipment = (CSX_CMP_Equipment__c) JSON.deserialize(
				equipmentJSON,
				CSX_CMP_Equipment__c.class
			);
			listEquipment.add(objEquipment);
			i++;
		}
		return listEquipment;
	}

	/**
    @description : This method is used to create Product records (Maximum return size is 5)
    @return : List<CSX_CMP_Product__c>
     */
	public static List<CSX_CMP_Product__c> createProductData(Integer count) {
		List<CSX_CMP_Product__c> listProduct = new List<CSX_CMP_Product__c>();
		Integer i = 0;
		List<String> ListProductJSONFreeText = new List<String>();
		ListProductJSONFreeText.add(
			'{"CSX_CMP_Quantity__c":15,"CSX_CMP_VIN__c":"13245678909087654","CSX_CMP_Total_Customer_Damage__c":280,"CSX_CMP_Product_Amount__c":280,"CSX_CMP_Unit_Price__c":18.67}'
		);
		ListProductJSONFreeText.add(
			'{"CSX_CMP_Quantity__c":45,"CSX_CMP_Product_Description__c":"Testing","CSX_CMP_Total_Customer_Damage__c":0,"CSX_CMP_Product_Amount__c":600,"CSX_CMP_Unit_Price__c":13.33}'
		);
		ListProductJSONFreeText.add(
			'{"CSX_CMP_Quantity__c":252,"CSX_CMP_Product_Description__c":"#5 MIXED HWD","CSX_CMP_Total_Customer_Damage__c":0,"CSX_CMP_Product_Amount__c":790,"CSX_CMP_Unit_Price__c":3.13}'
		);
		ListProductJSONFreeText.add(
			'{"CSX_CMP_Quantity__c":4,"CSX_CMP_Total_Customer_Damage__c":0,"CSX_CMP_Product_Amount__c":2000,"CSX_CMP_Unit_Price__c":500}'
		);
		ListProductJSONFreeText.add(
			'{"CSX_CMP_Quantity__c":40,"CSX_CMP_Product_Description__c":"IND","CSX_CMP_Total_Customer_Damage__c":0,"CSX_CMP_Product_Amount__c":500,"CSX_CMP_Unit_Price__c":12.5}'
		);

		for (String productJSON : ListProductJSONFreeText) {
			if (i == count) {
				break;
			}
			CSX_CMP_Product__c objProduct = (CSX_CMP_Product__c) JSON.deserialize(productJSON, CSX_CMP_Product__c.class);
			listProduct.add(objProduct);
			i++;
		}
		return listProduct;
	}

	/**
    @description : This method is used to create Customer Damage records (Maximum return size is 2)
    @return List<CSX_CMP_Customer_Damage__c>
    */
	public static List<CSX_CMP_Customer_Damage__c> createCustomerDamageData(Integer count) {
		List<CSX_CMP_Customer_Damage__c> listCustomerDamage = new List<CSX_CMP_Customer_Damage__c>();
		Integer i = 0;
		List<String> listCustomerDamageJSONFreeText = new List<String>();
		listCustomerDamageJSONFreeText.add(
			'{"CSX_CMP_Amount__c":140,"CSX_CMP_Area__c":"05","CSX_CMP_Type__c":"34","CSX_CMP_Severity__c":"4"}'
		);
		listCustomerDamageJSONFreeText.add(
			'{"CSX_CMP_Amount__c":140,"CSX_CMP_Area__c":"10","CSX_CMP_Type__c":"34","CSX_CMP_Severity__c":"1"}'
		);

		for (String customerDamageJSON : listCustomerDamageJSONFreeText) {
			if (i == count) {
				break;
			}
			CSX_CMP_Customer_Damage__c objCustomerDamage = (CSX_CMP_Customer_Damage__c) JSON.deserialize(
				customerDamageJSON,
				CSX_CMP_Customer_Damage__c.class
			);
			listCustomerDamage.add(objCustomerDamage);
			i++;
		}
		return listCustomerDamage;
	}

	/**
    @description : This method is used to return AP Settlement record
    @return : CSX_CMP_AP_Settlement__c
     */
	public static CSX_CMP_AP_Settlement__c generateAPSettlement() {
		CSX_CMP_AP_Settlement__c objSettlement = new CSX_CMP_AP_Settlement__c();

		objSettlement.CSX_CMP_Amount_Paid__c = 1600;
		objSettlement.CSX_CMP_Payment_Address__c = '1234, 5th Street, New York';
		//objSettlement.CSX_CMP_Payment_Method__c = 'Check';

		objSettlement.CSX_CMP_Check__c = '0000023';
		objSettlement.CSX_CMP_Check_Date__c = Date.newInstance(2024, 2, 12);
		objSettlement.CSX_CMP_Invoice_Payment_Status__c = 'Open';
		objSettlement.CSX_CMP_Bank_Account_Number__c = '177799';
		objSettlement.CSX_CMP_Check_Amount__c = 1600;
		objSettlement.CSX_CMP_Scheduled_Pay_Date__c = Date.newInstance(2024, 2, 12);
		objSettlement.CSX_CMP_Payment_Date__c = Date.newInstance(2024, 2, 12);
		objSettlement.CSX_CMP_Payment_Amount__c = 1600;
		objSettlement.CSX_CMP_Invoice_Number__c = '5100000173';
		objSettlement.CSX_CMP_External_ID__c = 'CLA000028_000081';
		objSettlement.CSX_CMP_Currency__c = 'USD';
		objSettlement.CSX_CMP_Operating_Unit__c = '1000';
		objSettlement.CSX_CMP_Integration_Status__c = 'Processed';
		objSettlement.CSX_CMP_GL_Account__c = '65001001';
		objSettlement.CSX_CMP_Cost_Center__c = 'DUMMY_TEST';
		objSettlement.CSX_CMP_Company_Code__c = '1000';
		return objSettlement;
	}

	/**
    @description : This method is used to return AR Settlement record
    @return : CSX_CMP_AR_Settlement__c
     */
	public static CSX_CMP_AR_Settlement__c generateARSettlement() {
		CSX_CMP_AR_Settlement__c objSettlement = new CSX_CMP_AR_Settlement__c();
		objSettlement.CSX_CMP_Invoice_Date__c = Date.newInstance(2024, 5, 6);
		objSettlement.CSX_CMP_Invoice_Amount__c = 1800;
		objSettlement.CSX_CMP_Invoice_Number__c = '1800000494';
		objSettlement.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe');
		objSettlement.CSX_CMP_Source__c = 'Freight';
		objSettlement.CSX_CMP_Invoice_Payment_Status__c = 'Open';
		objSettlement.CSX_CMP_Integration_Status__c = 'Processed';
		objSettlement.CSX_CMP_Document_Type__c = 'AC';
		objSettlement.CSX_CMP_Company_Code__c = '1000';
		objSettlement.CSx_CMP_Cost_Center__c = 'DUMMY_TEST';
		objSettlement.CSX_CMP_GL_Account__c = '41090000';
		objSettlement.CSX_CMP_Currency_Type__c = 'USD';
		objSettlement.CSX_CMP_Request_Type__c = 'Create';

		return objSettlement;
	}

	public static String mileageMockResponse() {
		Map<String, Object> mileageResponse = new Map<String, Object>();
		mileageResponse.put('totalmiles', 200);
		List<Map<String, Object>> segmentMileages = new List<Map<String, Object>>();
		Map<String, Object> segmentMileage = new Map<String, Object>();
		segmentMileage.put('junction', 'EAGPA');
		segmentMileage.put('road', '2341');
		segmentMileage.put('mileage', 484);
		segmentMileages.add(segmentMileage);
		Map<String, Object> segmentMileage1 = new Map<String, Object>();
		segmentMileage1.put('junction', 'DANVJ');
		segmentMileage1.put('road', '1234');
		segmentMileage1.put('mileage', 370);
		segmentMileages.add(segmentMileage1);
		Map<String, Object> segmentMileage2 = new Map<String, Object>();
		segmentMileage2.put('junction', 'TOLED');
		segmentMileage2.put('road', 'CSXT');
		segmentMileage2.put('mileage', 342);
		segmentMileages.add(segmentMileage2);
		mileageResponse.put('segmentMileages', segmentMileages);
		return JSON.serialize(mileageResponse);
	}

	// public static Case createAutoClaim(){
	//     Case cs = createClaimHeader();
	//     insert cs;
	//     CSX_CMP_Desk__c dsTest = new CSX_CMP_Desk__c();
	//     dsTest.Name = 'Desk';
	//     insert dsTest;

	//     Account accId = insertSupplierAccount();
	//     Account objAcc = insertCustomerAccount();

	//     CSX_CMP_Contract__c objCntrt = new CSX_CMP_Contract__c();
	//     objCntrt.CSX_CMP_Status__c = 'Active';
	//     objCntrt.CSX_CMP_Start_Date__c = Date.newInstance(2024, 1, 1);
	//     objCntrt.CSX_CMP_End_Date__c = Date.newInstance(2024, 1, 31);
	//     objCntrt.CSX_CMP_Contract_Budget__c = 999999999;
	//     objCntrt.CSX_CMP_Claim_Type__c = 'Max Allow Claim';
	//     objCntrt.CSX_CMP_Business_Unit__c = 'Test';
	//     objCntrt.CSX_CMP_Customer_Name__c = objAcc.id;
	//     objCntrt.CSX_CMP_Consumed_Budget__c = 888888;
	//     insert objCntrt;

	//     Case testCase = new Case();
	//     testCase.CSX_CMP_Supplier_Claimant__c = accId.Id;
	//     testCase.Status='Open';
	//     testCase.Type='FC Customer Claim';
	//     testCase.CSX_CMP_Desk_Name__c=dsTest.id;
	//     testCase.Origin = 'Email';
	//     testCase.CSX_CMP_Claim_Amount__c = 10000;
	//     testCase.CSX_CMP_Service_Period__c=null;
	//     testCase.CSX_CMP_Claim_Reason__c = 'PAY - Rule 185A1d';
	//     testCase.CSX_CMP_FLR_Email_Sent_Date__c = null;
	//     testCase.CSX_CMP_Contract_Num__c = objCntrt.id;
	//     testCase.AccountId = accId.id;
	//     testCase.CSX_CMP_FLR_Questions__c = 'Claim information, including claim number, amount and disposition if filed with you;Contractual limits of liability, including limited liability provision if applicable; Complete movement records, advising any rough or unusual handling or derailment; Provide seal records while on your line;Any salvage proceed involved, if applicable; Seal In-gate records, seal out-gate records, or J-1 records; Was the trailer appropriated by the shipper?..Copy of any exceptions, reports and photos noted at origin, interchange or destination; Copy of destination or interchange inspection reports and photos, advising any unloading or automobile facility incidents';
	//     testCase.Reason='Duplicate Bill';
	//     testCase.AccountId = accId.id;
	//     insert testCase;

	//     CSX_CMP_LD_Report__c LD = new CSX_CMP_LD_Report__c();
	//     LD.CSX_CMP_Pick_Up_Address__c ='abc';
	//     LD.CSX_CMP_LD_Type__c='Customer';
	//     insert LD;

	//     CSX_CMP_Related_LD_Report__c ldr = new CSX_CMP_Related_LD_Report__c();
	//     ldr.CSX_CMP_Claim__c=testCase.Id ;
	//     ldr.CSX_CMP_LD_Report__c=LD.id;
	//     insert ldr;

	//     CSX_CMP_Claim_Line__c cl = new CSX_CMP_Claim_Line__c();
	//     cl.CSX_CMP_Act_Destination_City__c = 'Nagpur';
	//     cl.CSX_CMP_Waybill_Num__c = '45678';
	//     cl.CSX_CMP_STCC__c = 'Cliam';
	//     cl.CSX_CMP_Equipment_Initial__c = 'Equ';
	//     cl.CSX_CMP_Claim__c = testCase.id;
	//     insert cl;

	//     CSX_CMP_Similarity_Matrix__c sm = new CSX_CMP_Similarity_Matrix__c();
	//     sm.CSX_CMP_Start_Date__c = system.today()-10;
	//     sm.CSX_CMP_Damage_Code__c = '345';
	//     sm.CSX_CMP_Similar_Damage_Code__c = sm.CSX_CMP_Damage_Code__c;
	//     sm.CSX_CMP_External_ID__c = 'External ID';
	//     insert sm;

	//     return testCase;
	// }

	// public static Case coverOverlapping(){
	//     Account objAcc = insertCustomerAccount();
	//     CSX_CMP_Contract__c objCnt = insertContract();
	//     Case newCase = createClaimHeader();
	//     newCase.CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01);//Date.valueof(01/01/2024);
	//     newCase.CSX_CMP_Period_End__c = Date.newInstance(2024,01,10);
	//     newCase.CSX_CMP_Contract_Num__c = objCnt.Id;
	//     newCase.CSX_CMP_Customer__c = objAcc.Id;
	//     insert newCase;
	//     return newCase;
	// }
	// public static CSX_CMP_Creation_Request__c createClaimCreationRequest(){
	//     Case objCSE = createAutoClaim();
	//     system.debug('objCSE &&&'+objCSE.id);
	//     CSX_CMP_Creation_Request__c objCR = new CSX_CMP_Creation_Request__c();
	//     objCR.CSX_CMP_Request_Payload__c = '{"phoneNumber":"9879876543","notes":"gt001,gt002","fcdRuleCode":"40-Imperfect Seal or Seal Record Resulting in Loss","fcdCauseCode":"1-Shortage, Packaged Shipment","equipmentorclaimlines":[{"products":[{"vin":"jhgh6565ty","uom":null,"quantity":null,"productDescription":null,"customerdamages":null}],"primaryRemarks":null,"ppn":null,"originSwitchRoad":null,"originRoadNumber":null,"originAuditNumber":null,"originalAmount":null,"oncomingState":null,"oncomingRoad":null,"oncomingCity":null,"offgoingState":null,"offgoingRoad":null,"offgoingCity":null,"numberOfCars":null,"mvManufacturingCode":null,"multiCarCount":null,"isSettlementDate":null,"fullRoad":null,"freightBillDate":null,"flatCarNumber":null,"equipmentNumber":"BNSF122211","equipmentInitial":null,"equipmentId":null,"equipI":null,"distributions":null,"destinationSwitchRoad":null,"destinationAuditNumber":null,"correctionDate":null,"consigneeZip":null,"consigneeState":null,"consigneeName":null,"consigneeCity":null,"consigneeAddr2":null,"consigneeAddr1":null,"consignee":null,"challengeDate":null,"carPosition":null,"boLNumber":null,"boLDate":null,"actOriginState":null,"actOriginRoad":null,"actOriginCity":null,"actDestinationState":null,"actDestinationRoad":null,"actDestinationCity":null}],"email":"test@gmail.com","derailment":false,"department":null,"dealerValue":null,"dealerSPLC":null,"dealerReferenceNumber":null,"dealerCode":null,"customerSite":null,"customerNumber":null,"customerName":null,"currencyCode":null,"country":null,"contractNumber":null,"contractCarrierDate":null,"contactName":"Neil","companyFilingClaim":null,"company":null,"claimType":"FC RR Inbound Claim","claimRecordType":"012Hp000001FCJxIAO","claimReason":"Damaged","claimId":"'+objCSE.Id+'","claimDate":"2023-12-01","claimantRefNumber":"1247","claimantCode":null,"claimant":null,"claimAmount":656,"city":null,"adressLine2":null,"adressLine1":null}';
	//     system.debug(objCR.CSX_CMP_Request_Payload__c);
	//     insert objCR;
	//     return objCR;
	// }
}