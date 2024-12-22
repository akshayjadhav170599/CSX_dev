/**************************************************************************************
/*
@author             : Infosys
@description        : Test Class for creating all the major master test data either coming from external sources or setup as configurable data
Apex Class Name     : CSX_CMP_TestMasterDataUtility
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
public with sharing class CSX_CMP_TestMasterDataUtility {
	public static void createMasterData() {
		createAccounts(); //assign LeAT code
		createContacts();
		createUsers(); //create 1 user for each user role and assign respective permission sets. time being use system admin or freight claim user . Once permission sets are created, method can be updated - done
		createDesks();
		createDeclineCodeMaster();
		createAutopayKickoutMaster();
		createCityStateMaster();
		createContracts(); //same Customer/National Account Number referred above - done
		// createBusinessRules();
		createFLREmailMaster();
		createSimilarityMatrix();
		//createSAPAccountingDetails(); //only if live data is not visible in test class
		// createDocuments();
		createCustomSettings();
		createInspectionHeaders(); //cover different sources - done
		// Use same VIN referred in shipment mock data - This is not done yet will finalize VIN once shipment mock data is created
		createInspectionDetails();
	}

	//getShipmentMockData    //use same LeAt code for Shipper and Consignee
	//Umler data - done
	//Waybill Image
	//Freight Bill  - done    //same waybillControl Number or Freight bill number
	//MTI - done
	//Mileage - done
	//RARS - done
	//Customer Service Cases for summary - done       //same Equipment id (needs to be done)
	//Customer Service Case full details - done
	//AR Balance - done       same Customer/National Account Number referred above

	public static void createAccounts() {
		Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
		List<Account> accounts = new List<Account>();
		// for all accounts have external id as account name without spaces

		// Customer Accounts
		Account account = new Account();
		account.Name = 'SAIL Account';
		account.Type = 'Customer';
		account.BillingStreet = '155 West 41st Street';
		account.BillingCity = 'New York';
		account.BillingState = 'NY';
		account.BillingPostalCode = '10018';
		account.BillingCountry = 'United States';
		account.Phone = '07020958976';
		account.AccountNumber = '1000020957';
		account.Website = 'godaddy.com';
		account.Industry = 'Agriculture';
		account.Description = 'Test Description';
		account.Site = 'PY1012';
		account.Status__c = 'Active';
		account.CSX_CMP_FC_Railroad_Road_Code__c = 'dd';
		account.CSX_CMP_FC_SCAC__c = 'ddd';
		account.CSX_CMP_Salvage_Account__c = true;
		account.CSX_CMP_External_ID__c = 'sailaccount';
		account.CSX_CMP_3rd_Party__c = false;
		account.National_Account__c = '004963565';
		account.CSX_CMP_FC_Contact_Email__c = 'sailaccount@csx.com';
		account.Le_Code__c = '9098012';
		account.CSX_CMP_Exclude_from_Distribution__c = false;
		account.CSX_CMP_FC_Gross_Net_Customer__c = 'NET';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		account = new Account();
		account.Name = 'CSX Transportation-Freight Claims';
		account.Type = 'Customer';
		account.BillingStreet = 'Attn Account payable';
		account.BillingCity = 'Jacksonville';
		account.BillingState = 'FL';
		account.BillingPostalCode = '32202';
		account.BillingCountry = 'US';
		account.ShippingStreet = '500 Water Street';
		account.ShippingState = '500 water ST';
		account.AccountNumber = '7000013641';
		account.Site = 'P1KY02 - 712';
		account.Status__c = 'Active';
		account.CSX_CMP_FC_Railroad_Road_Code__c = '0712';
		account.CSX_CMP_FC_SCAC__c = 'CSXT';
		account.CSX_CMP_Salvage_Account__c = false;
		account.CSX_CMP_External_ID__c = 'csxtransportationfreightclaims';
		account.CSX_CMP_3rd_Party__c = false;
		account.National_Account__c = '0012706';
		account.CSX_CMP_Exclude_from_Distribution__c = true;
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		/*Account account1 = new Account();
		account1.Name = 'SAIL Account';
		account1.Type = 'Customer';
		account1.BillingStreet = '155 West 41st Street';
		account1.BillingCity = 'New York';
		account1.BillingState = 'NY';
		account1.BillingPostalCode = '10018';
		account1.BillingCountry = 'United States';
		account1.Phone = '07020958976';
		account1.AccountNumber = '1000020957';
		account1.Website = 'godaddy.com';
		account1.Industry = 'Agriculture';
		account1.Description = 'Des';
		account1.Site = 'PY1012';
		account1.Status__c = 'Active';
		// account1.CSX_CMP_Active_From__c = Date.valueOf('2023-11-01');
		// account1.CSX_CMP_Active_To__c = Date.valueOf('2023-11-01');
		account1.CSX_CMP_FC_Railroad_Road_Code__c = '0987';
		account1.CSX_CMP_FC_SCAC__c = 'TTTX';
		account1.CSX_CMP_Salvage_Account__c = true;
		// account1.CSX_CMP_Time_Zone__c = 'IST';
		// account1.CSX_CMP_Tax_Jurisdiction__c = 'ee';
		//account1.CSX_CMP_PO_Box__c = '22';
		account1.CSX_CMP_3rd_Party__c = false;
		// account1.CSX_CMP_Salutation__c = 'MR.';
		account1.National_Account__c = '0012505';
		account1.CSX_CMP_FC_Contact_Email__c = 'testEmailUser@csx.com';
		// account1.CSX_CMP_PO_Box_Postal_Code__c = '440002';
		account1.Le_Code__c = '9098012';
		account1.CSX_CMP_Class_1_Railroad__c = false;
		account1.CSX_CMP_Exclude_from_Distribution__c = false;
		account1.CSX_CMP_FC_Gross_Net_Customer__c = 'NET';
		account1.CSX_CMP_External_ID__c = 'SAILAccount';
		account1.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account1.Location_Type__c = 'Billing Address';
		accounts.add(account1);

		Account account2 = new Account();
		account2.Name = 'KANSAS CITY SOUTHERN RAILWAY COMPANY';
		account2.Type = 'Customer';
		account2.BillingStreet = 'PO BOX 219335';
		account2.BillingCity = 'KANSAS CITY';
		account2.BillingState = 'MO';
		account2.BillingPostalCode = '64121-9335';
		account2.BillingCountry = 'USA';
		account2.AccountNumber = '6000000001';
		account2.Site = 'E PORLEASEPAYMT';
		account2.Status__c = 'Active';
		// account2.CSX_CMP_Active_From__c = Date.valueOf('2023-08-01');
		// account2.CSX_CMP_Active_To__c = Date.valueOf('2025-03-01');
		account2.CSX_CMP_FC_Railroad_Road_Code__c = '0400';
		account2.CSX_CMP_FC_SCAC__c = 'CH';
		account2.CSX_CMP_Salvage_Account__c = false;
		// account2.CSX_CMP_Tax_Jurisdiction__c = '27-0383222';
		account2.CSX_CMP_External_ID__c = 'KansasCitySouthernRailwayCompany';
		account2.CSX_CMP_3rd_Party__c = false;
		account2.National_Account__c = '1005456';
		account2.Payment_Method__c = 'Electronics';
		account2.CSX_CMP_Class_1_Railroad__c = false;
		account2.CSX_CMP_Operating_Unit__c = 'CSX TRANSPORTATION';
		account2.CSX_CMP_Exclude_from_Distribution__c = false;
		account2.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account2.Location_Type__c = 'Billing Address';
		accounts.add(account2);

		Account account3 = new Account();
		account3.Name = 'CSX Transportation-Freight Claims';
		account3.Type = 'Customer';
		account3.BillingStreet = 'Attn Account payable';
		account3.BillingCity = 'Jacksonville';
		account3.BillingState = 'FL';
		account3.BillingPostalCode = '32202';
		account3.BillingCountry = 'US';
		account3.ShippingStreet = '500 Water Street';
		account3.ShippingState = '500 water ST';
		account3.AccountNumber = '6000000002';
		account3.Site = 'P1KY02 - 712';
		account3.Status__c = 'Active';
		// account3.CSX_CMP_Active_From__c = Date.valueOf('2023-11-19');
		// account3.CSX_CMP_Active_To__c = Date.valueOf('2030-12-20');
		account3.CSX_CMP_FC_Railroad_Road_Code__c = '0712';
		account3.CSX_CMP_FC_SCAC__c = 'CSXT';
		account3.CSX_CMP_Salvage_Account__c = false;
		account3.CSX_CMP_3rd_Party__c = false;
		account3.National_Account__c = '0012505';
		account3.CSX_CMP_Class_1_Railroad__c = false;
		account3.CSX_CMP_Exclude_from_Distribution__c = true;
		account3.CSX_CMP_External_ID__c = 'CSXTransportationFreightClaims';
		account3.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account3.Location_Type__c = 'Billing Address';
		accounts.add(account3);*/

		// Supplier Accounts
		account = new Account();
		account.Name = 'UNION PACIFIC RAILROAD COMPANY';
		account.Type = 'Supplier';
		account.BillingStreet = '8111,Westchester 10 Street Hitech Street Pole';
		account.BillingCity = 'Dallas';
		account.BillingState = 'TX';
		account.BillingPostalCode = '75225';
		account.BillingCountry = 'US';
		account.AccountNumber = '6000000001';
		account.Site = 'E ILCHI12567COL';
		account.Status__c = 'Active';
		account.CSX_CMP_FC_Railroad_Road_Code__c = '07';
		account.CSX_CMP_FC_SCAC__c = 'JUWB';
		account.CSX_CMP_Salvage_Account__c = false;
		account.CSX_CMP_3rd_Party__c = false;
		account.National_Account__c = null;
		account.CSX_CMP_FC_Contact_Email__c = 'unionpacificrailroadcompany@csx.com';
		account.CSX_CMP_FC_EDI_Sender_ID__c = '433223';
		account.CSX_CMP_FC_Threshold_From__c = 10;
		account.CSX_CMP_FC_Threshold_To__c = 30;
		account.Payment_Method__c = 'Electronics';
		account.CSX_CMP_Class_1_Railroad__c = false;
		account.CSX_CMP_Operating_Unit__c = 'CSX TRANSPORTATION';
		account.CSX_CMP_Exclude_from_Distribution__c = true;
		account.CSX_CMP_FC_Gross_Net_Customer__c = 'NET';
		account.CSX_CMP_External_ID__c = 'UnionPacificRailroadCompany';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		account = new Account();
		account.Name = 'REBECCO OIL INC CORPORATION USA';
		account.Type = 'Supplier';
		account.BillingStreet = '8111,Westchester 10 Street Hitech Street Pole';
		account.BillingCity = 'Dallas';
		account.BillingState = 'TX';
		account.BillingPostalCode = '75225';
		account.BillingCountry = 'US';
		account.AccountNumber = '1000000012';
		account.Site = 'Hitech';
		account.Status__c = 'Active';
		account.CSX_CMP_FC_Railroad_Road_Code__c = '0103';
		account.CSX_CMP_FC_SCAC__c = 'KCSM';
		account.CSX_CMP_Salvage_Account__c = false;
		account.CSX_CMP_3rd_Party__c = false;
		account.National_Account__c = '63061';
		account.Payment_Method__c = 'W';
		account.CSX_CMP_Class_1_Railroad__c = false;
		account.CSX_CMP_Operating_Unit__c = '1000';
		account.CSX_CMP_Exclude_from_Distribution__c = false;
		account.Care_of_Name__c = 'Rebecco Corp INC';
		account.CSX_CMP_FC_Gross_Net_Customer__c = 'NET';
		account.CSX_CMP_External_ID__c = 'RebeccoOilIncCorporationUSA';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		account = new Account();
		account.Name = 'Canadian National Railway';
		account.Type = 'Supplier';
		account.BillingStreet = 'Maharashtra';
		account.BillingCity = 'Nagpur';
		account.BillingState = 'MAH';
		account.BillingPostalCode = '440002';
		account.BillingCountry = 'INDIA';
		account.AccountNumber = '543234';
		account.Status__c = 'Active';
		account.CSX_CMP_FC_Railroad_Road_Code__c = '2341';
		account.CSX_CMP_FC_SCAC__c = 'UP';
		account.CSX_CMP_Salvage_Account__c = false;
		account.CSX_CMP_3rd_Party__c = false;
		account.National_Account__c = null;
		account.Payment_Method__c = null;
		account.CSX_CMP_Class_1_Railroad__c = false;
		account.CSX_CMP_Exclude_from_Distribution__c = false;
		account.CSX_CMP_FC_Gross_Net_Customer__c = 'GROSS';
		account.CSX_CMP_External_ID__c = 'CanadianNationalRailway';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		/*Account account6 = new Account();
		account6.Name = 'BURLINGTON NORTHERN SANTA FE';
		account6.Type = 'Supplier';
		account6.BillingStreet = 'ATTN ACCOUNTS PAYABLE,\r\nPO BOX 961034';
		account6.BillingCity = 'Fort Worth';
		account6.BillingState = 'TX';
		account6.BillingPostalCode = '76101';
		account6.BillingCountry = 'USA';
		account6.AccountNumber = '1000020957';
		account6.Site = '634NNG - 712';
		account6.Status__c = 'Active';
		// account6.CSX_CMP_Active_From__c = Date.valueOf('2023-10-01');
		// account6.CSX_CMP_Active_To__c = Date.valueOf('2025-12-31');
		account6.CSX_CMP_FC_Railroad_Road_Code__c = '8768';
		account6.CSX_CMP_FC_SCAC__c = 'BNSF';
		account6.CSX_CMP_Salvage_Account__c = false;
		// account6.CSX_CMP_Tax_Jurisdiction__c = '21-0383220';
		account6.CSX_CMP_3rd_Party__c = false;
		account6.National_Account__c = '1000';
		account6.CSX_CMP_FC_Contact_Email__c = 'TestUser@csx.com';
		account6.Le_Code__c = '4847997';
		account6.Payment_Method__c = 'Electronics';
		account6.CSX_CMP_Class_1_Railroad__c = false;
		account6.CSX_CMP_Operating_Unit__c = 'CSX';
		account6.CSX_CMP_Exclude_from_Distribution__c = false;
		account6.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
		account6.CSX_CMP_FC_EDI_Sender_ID__c = '433223';
		account6.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account6.Location_Type__c = 'Billing Address';
		accounts.add(account6);

		Account account7 = new Account();
		account7.Name = 'UNION PACIFIC RAILROAD COMPANY';
		account7.Type = 'Supplier';
		account7.BillingStreet = '8111,Westchester 10 Street Hitech Street Pole';
		account7.BillingCity = 'Dallas';
		account7.BillingState = 'TX';
		account7.BillingPostalCode = '75225';
		account7.BillingCountry = 'US';
		account7.AccountNumber = '6000000001';
		account7.Site = 'E ILCHI12567COL';
		account7.Status__c = 'Active';
		// account7.CSX_CMP_Active_From__c = Date.valueOf('2023-09-01');
		// account7.CSX_CMP_Active_To__c = Date.valueOf('2025-11-30');
		account7.CSX_CMP_FC_Railroad_Road_Code__c = '0712';
		account7.CSX_CMP_FC_SCAC__c = 'CSXT';
		account7.CSX_CMP_Salvage_Account__c = false;
		// account7.CSX_CMP_Tax_Jurisdiction__c = '26-0383292';
		account7.CSX_CMP_3rd_Party__c = false;
		account7.CSX_CMP_FC_Contact_Email__c = 'TestUser@csx.com';
		account7.CSX_CMP_FC_Threshold_From__c = 10;
		account7.CSX_CMP_FC_Threshold_To__c = 30;
		account7.Payment_Method__c = 'Electronics';
		account7.CSX_CMP_Class_1_Railroad__c = true;
		account7.CSX_CMP_Operating_Unit__c = 'CSX TRANSPORTATION';
		account7.CSX_CMP_Exclude_from_Distribution__c = false;
		account7.CSX_CMP_External_ID__c = 'UnionPacificRailroadCompany';
		accounts.add(account7);

		Account account8 = new Account();
		account8.Name = 'FERROCARRIL MEXICANO SA DE CV';
		account8.Type = 'Supplier';
		account8.BillingStreet = 'BOSQUE DE CIRVELOS 99,\r\nCOL BOSQUES DE LAS LOMAS';
		account8.BillingCity = 'MEXICO DF';
		account8.BillingState = 'CP';
		account8.BillingPostalCode = '11700';
		account8.BillingCountry = 'US';
		account8.AccountNumber = '1047251';
		account8.Site = 'E MXMEXBOSQUEDE';
		account8.Status__c = 'Active';
		// account8.CSX_CMP_Active_From__c = Date.valueOf('2023-08-01');
		// account8.CSX_CMP_Active_To__c = Date.valueOf('2025-11-30');
		account8.CSX_CMP_FC_SCAC__c = 'MP';
		// account8.CSX_CMP_Tax_Jurisdiction__c = '23-0384522';
		account8.CSX_CMP_3rd_Party__c = false;
		account8.CSX_CMP_FC_Contact_Email__c = 'TestCSXUser@csx.com';
		account8.CSX_CMP_FC_Threshold_From__c = 100;
		account8.CSX_CMP_FC_Threshold_To__c = 2500;
		account8.Le_Code__c = '4869012';
		account8.Payment_Method__c = 'Electronics';
		account8.CSX_CMP_Class_1_Railroad__c = false;
		account8.CSX_CMP_Operating_Unit__c = 'CSX TRANSPORTATION';
		account8.CSX_CMP_Exclude_from_Distribution__c = false;
		account8.CSX_CMP_External_ID__c = 'FerrocarrilMexicanoSaDeCv';
		accounts.add(account8);*/

		//EDI Accounts
		Account account4 = new Account();
		account4.Name = 'GMLLC FINISHED VEHICLE CLAIMS';
		account4.Type = 'Customer';
		account4.BillingStreet = 'DEPT 771808';
		account4.BillingCity = 'DETROIT';
		account4.BillingState = 'MI';
		account4.BillingPostalCode = '77000';
		account4.BillingCountry = 'US';
		account4.AccountNumber = '6000000003';
		account4.Site = 'E CNOSH1908COL1';
		account4.Status__c = 'Active';
		// account4.CSX_CMP_Active_From__c = Date.valueOf('2023-11-19');
		// account4.CSX_CMP_Active_To__c = Date.valueOf('2030-12-20');
		account4.CSX_CMP_FC_Railroad_Road_Code__c = '0712';
		account4.CSX_CMP_FC_EDI_Sender_ID__c = 'VASCGM';
		account4.CSX_CMP_FC_Contact_Email__c = 'FCDecline_Messages@csx.com';
		account4.CSX_CMP_FC_Threshold_From__c = 150;
		account4.CSX_CMP_FC_Threshold_To__c = 1000;
		account4.CSX_CMP_FC_Gross_Net_Customer__c = 'NET';
		account4.CSX_CMP_3rd_Party__c = false;
		account4.CSX_CMP_Exclude_from_Distribution__c = false;
		account4.CSX_CMP_External_ID__c = 'GMLLCFinishedVehicleClaims';
		accounts.add(account4);

		Account account5 = new Account();
		account5.Name = 'FORD MOTOR CO';
		account5.Type = 'Customer';
		account5.BillingStreet = '5111 AUTO CLUB DRIVE';
		account5.BillingCity = 'Dearborn Heights';
		account5.BillingState = 'MI';
		account5.BillingPostalCode = '48126';
		account5.BillingCountry = 'US';
		account5.AccountNumber = '119835';
		account5.Site = '3AN90Q - 712';
		account5.Status__c = 'Active';
		// account5.CSX_CMP_Active_From__c = Date.valueOf('2023-11-19');
		// account5.CSX_CMP_Active_To__c = Date.valueOf('2030-12-20');
		account5.CSX_CMP_FC_Railroad_Road_Code__c = '0712';
		account5.CSX_CMP_FC_EDI_Sender_ID__c = 'VASC';
		account5.CSX_CMP_FC_Contact_Email__c = 'fordclaims@vascorltd.com';
		account5.CSX_CMP_FC_Threshold_From__c = 251;
		account5.CSX_CMP_FC_Threshold_To__c = 1000;
		account5.CSX_CMP_3rd_Party__c = false;
		account5.CSX_CMP_Exclude_from_Distribution__c = false;
		account5.CSX_CMP_External_ID__c = 'FordMotorCo';
		accounts.add(account5);

		// 3rd Party Accounts
		Account account9 = new Account();
		account9.Name = 'TOYOTA MOTOR SALES USA INC';
		account9.Type = 'Customer';
		account9.BillingStreet = 'ATTN: WILLIAM MITCHELL W1-1A\r\n6565 HEADQUARTERS DR';
		account9.BillingCity = 'PLANO';
		account9.BillingState = 'TX';
		account9.BillingPostalCode = '75024';
		account9.BillingCountry = 'US';
		account9.AccountNumber = '0012345';
		account9.Site = '00000';
		account9.Status__c = 'Inactive';
		// account9.CSX_CMP_Active_From__c = Date.valueOf('2020-02-01');
		// account9.CSX_CMP_Active_To__c = Date.valueOf('2030-02-01');
		// account9.CSX_CMP_Time_Zone__c = 'PST';
		// account9.CSX_CMP_Tax_Jurisdiction__c = 'TX0000000';
		account9.CSX_CMP_3rd_Party__c = true;
		account9.National_Account__c = '0012345';
		account9.CSX_CMP_Exclude_from_Distribution__c = false;
		account9.CSX_CMP_External_ID__c = 'ToyotaMotorSalesUSAInc';
		accounts.add(account9);

		account = new Account();
		account.Name = 'GLOVIS AMERICA INC';
		account.Type = 'Customer';
		account.AccountNumber = '6000000001';
		account.Status__c = 'Active';
		account.CSX_CMP_3rd_Party__c = true;
		account.CSX_CMP_External_ID__c = 'glovisAmericaINC';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		account = new Account();
		account.Name = 'GLOVIS AMERICA INC | IRVINE CA';
		account.Type = 'Customer';
		account.RecordTypeId = recordTypeMap.get('Location').getRecordTypeId();
		account.BillingStreet = '17305 Von Karman Avenue\r\nSUITE 200';
		account.BillingCity = 'Irvine';
		account.BillingState = 'CA';
		account.BillingPostalCode = '92614-0914';
		account.BillingCountry = 'United States';
		account.AccountNumber = '6000000001';
		account.Site = 'IRVINE CA';
		account.Status__c = 'Active';
		account.CSX_CMP_External_ID__c = 'cglovisAmericaINCIRVINECA';
		account.Location_Type__c = 'Billing Address';
		accounts.add(account);

		insert accounts;

		linkSuppliersToCustomers();
		linkChildAccounts();
	}

	private static void linkSuppliersToCustomers() {
		List<Account> supplierAccounts = new List<Account>();

		Account supplierAccount = new Account();
		supplierAccount.CSX_CMP_External_ID__c = 'UnionPacificRailroadCompany';
		supplierAccount.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount');
		supplierAccounts.add(supplierAccount);

		supplierAccount = new Account();
		supplierAccount.CSX_CMP_External_ID__c = 'RebeccoOilIncCorporationUSA';
		supplierAccount.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'csxtransportationfreightclaims');
		supplierAccounts.add(supplierAccount);

		supplierAccount = new Account();
		supplierAccount.CSX_CMP_External_ID__c = 'CanadianNationalRailway';
		supplierAccount.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount');
		supplierAccounts.add(supplierAccount);

		Database.UpsertResult[] results = Database.upsert(supplierAccounts, Account.Fields.CSX_CMP_External_ID__c, false);
	}

	private static void linkChildAccounts() {
		List<Account> childAccounts = new List<Account>();

		Account childAccount = new Account();
		childAccount.CSX_CMP_External_ID__c = 'cglovisAmericaINCIRVINECA';
		childAccount.parent = new Account(CSX_CMP_External_ID__c = 'glovisAmericaINC');
		childAccounts.add(childAccount);

		Database.UpsertResult[] results = Database.upsert(childAccounts, Account.Fields.CSX_CMP_External_ID__c, false);
	}

	public static void createContacts() {
		// create contact for each account
		List<Account> accounts = [SELECT Id, Name, CSX_CMP_External_ID__c FROM Account WHERE CSX_CMP_External_ID__c != Null ORDER BY CreatedDate DESC LIMIT 1];
		List<Contact> contacts = new List<Contact>();
        
		for (Account acc : accounts) {
			Contact contact = new Contact();
			contact.FirstName = 'Test Contact';
			contact.LastName = ' : ' + acc.Name;
			contact.CSX_CMP_Inv_Notif_PDF_Attach__c = true; 
            contact.Email = 'testdata@csx.com'; //acc.CSX_CMP_External_ID__c + 
			contact.CSX_CMP_Inv_Notif_Other_Emails__c = 'fordclaims@vascorltd.com';
			contact.AccountId = acc.Id;
			contact.CSX_CMP_RACF_ID__c = acc.CSX_CMP_External_ID__c.substring(0, 6);
			contacts.add(contact);
		}

		insert contacts;
	}

	@future
	public static void createUsers() {
		Map<String, Id> profileMap = new Map<String, Id>();
		List<Profile> profileList = [SELECT Id, Name FROM Profile];
		for (Profile profile : profileList) {
			profileMap.put(profile.Name, profile.Id);
		}

		List<UserRole> userRoles = [SELECT Id, Name FROM UserRole];
		Map<String, Id> userRoleMap = new Map<String, Id>();
		for (UserRole userRole : userRoles) {
			userRoleMap.put(userRole.Name, userRole.Id);
		}

		String profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		String chatterProfileId = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User'].Id;

		List<User> users = new List<User>();

		//chatter User
		User chatterUser = new User(
			Username = 'chatter@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'chatter',
			FirstName = 'Expert',
			Email = 'chatter@csx.com',
			Alias = 'clusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Chatter Free User'),
			LanguageLocaleKey = 'en_US'
		);
		users.add(chatterUser);

		// name : Claims Admin
		User claimsAdmin = new User(
			Username = 'claimsAdmin@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'Admin',
			FirstName = 'Claims',
			Email = 'claimsAdmin@csx.com',
			Alias = 'cladmn',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Claims Admin'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Claims Admin')
		);
		users.add(claimsAdmin);

		// name : LEADS User (L&D)
		User leadsUser = new User(
			Username = 'leadsUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Leads',
			Email = 'leadsUser@csx.com',
			Alias = 'ldusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Freight User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('LEADS User')
		);
		users.add(leadsUser);

		// name : Transflo User
		User transfloUser = new User(
			Username = 'transfloUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Transflo',
			Email = 'transfloUser@csx.com',
			Alias = 'trusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Freight User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Transflo User')
		);
		users.add(transfloUser);

		// name : Freight Claim User
		User freightClaimUser = new User(
			Username = 'freightClaimUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Freight Claim',
			Email = 'freightClaimUser@csx.com',
			Alias = 'frusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Freight User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Freight Claim User')
		);
		users.add(freightClaimUser);

		// name : Freight Claim Manager
		User freightClaimManager = new User(
			Username = 'freightClaimManager@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'Manager',
			FirstName = 'Freight Claim',
			Email = 'freightClaimManager@csx.com',
			Alias = 'frmgr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Freight User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Freight Claim Manager')
		);
		users.add(freightClaimManager);

		// name : Revenue Contract Refunds User
		// String revenueContractRefundsUser =
		// 	'{"Username": "revenueContractRefundsUser@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "User", "FirstName": "Revenue Contract Refunds", "Email": "revenueContractRefundsUser@csx.com", "Alias": "rcrusr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user7 = (User) JSON.deserialize(revenueContractRefundsUser, User.class);
		// users.add(user7);
		User revenueContractRefundsUser = new User(
			Username = 'revenueContractRefundsUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Revenue Contract Refunds',
			Email = 'revenueContractRefundsUser@csx.com',
			Alias = 'rcrusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Contract Refunds User')
		);
		users.add(revenueContractRefundsUser);

		// name : Revenue Contract Refunds Manager
		// String revenueContractRefundsManager =
		// 	'{"Username": "revenueContractRefundsManager@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "Manager", "FirstName": "Revenue Contract Refunds", "Email": "revenueContractRefundsManager@csx.com", "Alias": "rcrmgr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user8 = (User) JSON.deserialize(revenueContractRefundsManager, User.class);
		// users.add(user8);
		User revenueContractRefundsManager = new User(
			Username = 'revenueContractRefundsManager@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'Manager',
			FirstName = 'Revenue Contract Refunds',
			Email = 'revenueContractRefundsManager@csx.com',
			Alias = 'rcrmgr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Contract Refunds Manager')
		);
		users.add(revenueContractRefundsManager);

		// name : Revenue Railroad User
		// String revenueRailroadUser =
		// 	'{"Username": "RevenueRailroadUser@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "User", "FirstName": "Revenue Railroad", "Email": "RevenueRailroadUser@csx.com", "Alias": "rrusr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user9 = (User) JSON.deserialize(revenueRailroadUser, User.class);
		// users.add(user9);
		User revenueRailroadUser = new User(
			Username = 'RevenueRailroadUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Revenue Railroad',
			Email = 'RevenueRailroadUser@csx.com',
			Alias = 'rrusr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Railroad User')
		);
		users.add(revenueRailroadUser);

		// name : Revenue Railroad Manager
		// String revenueRailroadManager =
		// 	'{"Username": "revenueRailroadManager@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "Manager", "FirstName": "Revenue Railroad", "Email": "revenueRailroadManager@csx.com", "Alias": "rrmgr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user10 = (User) JSON.deserialize(revenueRailroadManager, User.class);
		// users.add(user10);
		User revenueRailroadManager = new User(
			Username = 'revenueRailroadManager@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'Manager',
			FirstName = 'Revenue Railroad',
			Email = 'revenueRailroadManager@csx.com',
			Alias = 'rrmgr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Railroad Manager')
		);
		users.add(revenueRailroadManager);

		// name : Revenue Overcharge User
		// String revenueOverchargeUser =
		// 	'{"Username": "revenueOverchargeUser@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "User", "FirstName": "Revenue Overcharge", "Email": "revenueOverchargeUser@csx.com", "Alias": "rousr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user11 = (User) JSON.deserialize(revenueOverchargeUser, User.class);
		// users.add(user11);
		User revenueOverchargeUser = new User(
			Username = 'revenueOverchargeUser@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'User',
			FirstName = 'Revenue Overcharge',
			Email = 'revenueOverchargeUser@csx.com',
			Alias = 'rousr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Overcharge User')
		);
		users.add(revenueOverchargeUser);

		// name : Revenue Overcharge Manager
		// String revenueOverchargeManager =
		// 	'{"Username":"revenueOverchargeManager@csx.com.dev' +
		// 	String.valueOf(System.currentTimeMillis()) +
		// 	'", "LastName": "Manager", "FirstName": "Revenue Overcharge", "Email": "revenueOverchargeManager@csx.com", "Alias": "romgr", "IsActive": true, "TimeZoneSidKey": "America/Los_Angeles", "LocaleSidKey": "en_US", "EmailEncodingKey": "UTF-8", "ProfileId": "' +
		// 	profileId +
		// 	'", "permissionSetId": "' +
		// 	permissionSetId +
		// 	'", "LanguageLocaleKey": "en_US"}';
		// User user12 = (User) JSON.deserialize(revenueOverchargeManager, User.class);
		// users.add(user12);
		User revenueOverchargeManager = new User(
			Username = 'revenueOverchargeManager@csx.com.dev' + String.valueOf(System.currentTimeMillis()),
			LastName = 'Manager',
			FirstName = 'Revenue Overcharge',
			Email = 'revenueOverchargeManager@csx.com',
			Alias = 'romgr',
			IsActive = true,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileMap.get('Revenue User'),
			LanguageLocaleKey = 'en_US',
			UserRoleId = userRoleMap.get('Revenue Overcharge Manager')
		);
		users.add(revenueOverchargeManager);

		insert users;

		assignPermissionSets(users);
	}

	private static void assignPermissionSets(List<User> users) {
		List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet];
		Map<String, Id> permissionSetMap = new Map<String, Id>();
		for (PermissionSet permissionSet : permissionSets) {
			permissionSetMap.put(permissionSet.Name, permissionSet.Id);
		}
		List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
		for (User user : users) {
			if (user.Username.contains('claimsAdmin')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Claims_Admin_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('freightClaimUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claim_User_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('freightClaimManager')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claim_User_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claim_Manager_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueContractRefundsUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.permissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Contract_Refunds_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueContractRefundsManager')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.permissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Contract_Refunds_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get(
					'CSX_CMP_Revenue_Contract_Refunds_Manager_Access'
				);
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueRailroadUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Railroad_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueRailroadManager')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Railroad_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Railroad_Manager_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueOverchargeUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Overcharge_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('revenueOverchargeManager')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Overcharge_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Revenue_Overcharge_Manager_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('leadsUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Leads_User_Access');
				permissionSetList.add(permissionSetAssignment);
			} else if (user.Username.contains('transfloUser')) {
				PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Freight_Claims_Access');
				permissionSetList.add(permissionSetAssignment);
				permissionSetAssignment = new PermissionSetAssignment();
				permissionSetAssignment.AssigneeId = user.Id;
				permissionSetAssignment.PermissionSetId = permissionSetMap.get('CSX_CMP_Transflo_User_Access');
				permissionSetList.add(permissionSetAssignment);
			}
		}
		Database.UpsertResult[] results = Database.upsert(permissionSetList, false);
		for(Database.UpsertResult result : results) {
			if (!result.isSuccess()) {
				System.debug('Error: ' + result.getErrors()[0].getMessage());
			}
		}
	}

	public static void createDesks() {
		String claimUserId = [SELECT Id FROM User WHERE Username = 'claimuser@csx.com.dev'].Id;
		// Map<String, Id> deskMap = new Map<String, Id>();

		List<CSX_CMP_Desk__c> desks = new List<CSX_CMP_Desk__c>();
		desks.add(
			buildDesk('Desk 11', 'Desk for Honda Claims', Date.valueOf('2024-03-22'), Date.valueOf('2025-03-22'), claimUserId)
		);
		desks.add(buildDesk('Catchall Desk3', '', Date.valueOf('2024-03-22'), Date.valueOf('2025-03-22'), claimUserId));
		desks.add(
			buildDesk(
				'Contract Refunds',
				'Desk for Contract Refunds',
				Date.valueOf('2024-03-22'),
				Date.valueOf('2025-03-22'),
				claimUserId
			)
		);
		desks.add(
			buildDesk(
				'Railroad Payable',
				'Desk for Railroad Payable Claims',
				Date.valueOf('2024-03-22'),
				Date.valueOf('2025-03-22'),
				claimUserId
			)
		);
		desks.add(
			buildDesk(
				'REC - Rule 185A1f',
				'Desk for REC - Rule 185A1f Claims',
				Date.valueOf('2024-03-22'),
				Date.valueOf('2025-03-22'),
				claimUserId
			)
		);
		desks.add(
			buildDesk(
				'Sidetrack',
				'Desk for Sidetrack Claims',
				Date.valueOf('2024-03-22'),
				Date.valueOf('2025-03-22'),
				claimUserId
			)
		);

		desks.add(
			buildDesk(
				'Desk 91',
				'Desk for Distribution Claims',
				Date.valueOf('2024-03-22'),
				Date.valueOf('2025-03-22'),
				claimUserId
			)
		);

		insert desks;
	}

	public static void createDeclineCodeMaster() {
		List<CSX_CMP_Decline_Code_Master__c> declineCodeMasters = new List<CSX_CMP_Decline_Code_Master__c>();

		String decline1 = '{"Name": "AOG", "CSX_CMP_Meaning__c": "LOSS OR DAMAGE DUE TO ACT OF GOD - SEE CORRESPONDENCE", "CSX_CMP_Email_Message__c": "The damage to the unit is due to an Act of God, an event that is unusual, sudden and unexpected due to the forces of nature which man cannot resist or prevent. Damages to the unit under this act prevents the exercise of reasonable foresight and therefore the railroad carrier cannot be held liable for such damages.","CSX_CMP_Description__c": "The damage to the unit is due to an Act of God, an event that is unusual, sudden and unexpected due to the forces of nature which man cannot resist or prevent. Damages to the unit under this act prevents the exercise of reasonable foresight and therefore ","CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster1 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline1,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMaster1.CSX_CMP_External_ID__c = 'AOG';
		declineCodeMasters.add(declineCodeMaster1);

		String decline2 = '{"Name": "CAC", "CSX_CMP_Meaning__c": "CORRECTION TO AMOUNT CLAIMED-KEYING OR TRANSMISSION ERROR", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster2 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline2,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster2);

		String decline3 = '{"Name": "CCD", "CSX_CMP_Meaning__c": "CARRIER DISAGREES WITH CONSIGNEE DMGS NOTED-PROOF TO FOLLOW", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster3 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline3,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster3);

		String decline4 = '{"Name": "CDC", "CSX_CMP_Meaning__c": "COMPROMISE OFFERED ON CONCEALED DMG", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster4 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline4,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster4);

		String decline5 = '{"Name": "CDI", "CSX_CMP_Meaning__c": "CARRIERS NOT GIVEN AN OPPORTUNITY TO INSPECT CLAIMED DAMAGES", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster5 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline5,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster5);

		String decline6 = '{"Name": "CFO", "CSX_CMP_Meaning__c": "CLAIM FOR OTHER THAN L/D OR DELAY TO SHPMNT-SEE LETTER", "CSX_CMP_Email_Message__c": "The submitted claim is not for loss, damage or delay to shipment.", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster6 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline6,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster6);

		String decline7 = '{"Name": "CIB", "CSX_CMP_Meaning__c": "INCORRECT BASIS-SALES LOSS VS MKT DECLINE/RETAIL VS INVOICE", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster7 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline7,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster7);

		String decline8 = '{"Name": "CIC", "CSX_CMP_Meaning__c": "CORRECTION TO INITIAL CLAIM FILED FOR PRELIMINARY ESTIMATE", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster8 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline8,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster8);

		String decline9 = '{"Name": "CNG", "CSX_CMP_Meaning__c": "DEST INSPEC REVEALS CONTRIBUTORY NEGLIGENCE-COMPROMISE OFFER", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster9 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline9,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster9);

		String decline10 = '{"Name": "CNL", "CSX_CMP_Meaning__c": "NOT CARRIER LIABILITY, SALV PROCEEDS OFFERED IN SETTLEMENT", "CSX_CMP_Email_Message__c": "The submitted claim is not carrier liability; salvage proceeds have been offered in settlement.", "CSX_CMP_Description__c": "template OTH For Letter", "CSX_CMP_Start_Date__c": "2013-03-04", "CSX_CMP_Enabled__c": false}';
		CSX_CMP_Decline_Code_Master__c declineCodeMaster10 = (CSX_CMP_Decline_Code_Master__c) JSON.deserialize(
			decline10,
			CSX_CMP_Decline_Code_Master__c.class
		);
		declineCodeMasters.add(declineCodeMaster10);

		insert declineCodeMasters;
	}

	public static void createAutopayKickoutMaster() {
		List<CSX_CMP_Auto_pay_kickout_Code_Master__c> autoPayKickoutCodeMasters = new List<CSX_CMP_Auto_pay_kickout_Code_Master__c>();
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('00', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('15', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('17', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('06', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('02', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('01', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('12', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('14', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('04', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('09', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('13', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('05', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('11', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('10', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('16', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('07', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('03', ''));
		autoPayKickoutCodeMasters.add(generateAutoPayKickoutCodeMaster('08', ''));
		insert autoPayKickoutCodeMasters;
	}

	private static CSX_CMP_Auto_pay_kickout_Code_Master__c generateAutoPayKickoutCodeMaster(
		String code,
		String description
	) {
		CSX_CMP_Auto_pay_kickout_Code_Master__c autoPayKickoutCodeMaster = new CSX_CMP_Auto_pay_kickout_Code_Master__c();
		autoPayKickoutCodeMaster.Name = code;
		// autoPayKickoutCodeMaster.CSX_CMP_Description__c = description;
		return autoPayKickoutCodeMaster;
	}

	public static void createCityStateMaster() {
		List<CSX_CMP_City_State_Master__c> cityStateMasters = new List<CSX_CMP_City_State_Master__c>();
		cityStateMasters.add(buildCityStateMaster('CLEVELAND', '988', 'OH'));
		cityStateMasters.add(buildCityStateMaster('CLEVELAND AMTRACK', '087', 'OH'));
		cityStateMasters.add(buildCityStateMaster('13TH STREET CP', '399', 'AL'));
		cityStateMasters.add(buildCityStateMaster('13TH STREET YLM', 'ANJ982', 'AL'));
		cityStateMasters.add(buildCityStateMaster('27TH STREET CP', '397', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ABANDA', 'ANJ853', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ABERNANT', '0LC423', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ADAMS', 'NS  11', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ADDISON OS', 'ANJ938', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ADGER', '0LC413', 'AL'));
		cityStateMasters.add(buildCityStateMaster('AKKA', '000661', 'AL'));
		cityStateMasters.add(buildCityStateMaster('AL STATE DOCKS CP', '000662', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ALABAMA CITY', '0LE452', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ALABAMA STATE DOCKS', '000666', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ALAGA', 'AN 761', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ALBERTVILLE', '0AG468', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ALFORD DD', '000422', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ANDERSON', 'SG 668', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ANSLEY', 'AN 863', 'AL'));
		cityStateMasters.add(buildCityStateMaster('ARDMORE', '0BA279', 'AL'));

		insert cityStateMasters;
	}

	private static CSX_CMP_City_State_Master__c buildCityStateMaster(String city, String milepost, String state) {
		CSX_CMP_City_State_Master__c cityStateMaster = new CSX_CMP_City_State_Master__c();
		cityStateMaster.CSX_CMP_City__c = city;
		cityStateMaster.CSX_CMP_Milepost__c = milepost;
		cityStateMaster.CSX_CMP_State__c = state;
		cityStateMaster.CSX_CMP_Status__c = 'Active';
		cityStateMaster.Name = city + ' | ' + state + ' | ' + milepost;
		String cityStateMasterId = city + milepost + state;
		cityStateMaster.CSX_CMP_External_ID__c = cityStateMasterId.replaceAll(' ', '');
		return cityStateMaster;
	}

	public static void createContracts() {
		List<CSX_CMP_Contract__c> contracts = new List<CSX_CMP_Contract__c>();
		CSX_CMP_Contract__c contract1 = new CSX_CMP_Contract__c();
		contract1.CSX_CMP_Status__c = 'Active';
		contract1.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount');
		contract1.CSX_CMP_Start_Date__c = Date.valueOf('2023-12-01');
		contract1.CSX_CMP_End_Date__c = Date.valueOf('2050-12-31');
		contract1.CSX_CMP_Business_Unit__c = 'PF';
		contract1.CSX_CMP_Contract_Budget__c = 999999;
		contract1.CSX_CMP_Consumed_Budget__c = 637345;
		contract1.CSX_CMP_Claim_Type__c = 'Sidetrack Claim';
		contracts.add(contract1);

		CSX_CMP_Contract__c contract2 = new CSX_CMP_Contract__c();
		contract2.CSX_CMP_Status__c = 'Active';
		contract2.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'csxtransportationfreightclaims');
		contract2.CSX_CMP_Start_Date__c = Date.valueOf('2023-12-06');
		contract2.CSX_CMP_End_Date__c = Date.valueOf('2024-01-31');
		contract2.CSX_CMP_Business_Unit__c = 'PF';
		contract2.CSX_CMP_Contract_Budget__c = 999999999;
		contract2.CSX_CMP_Consumed_Budget__c = 23018;
		contract2.CSX_CMP_Claim_Type__c = 'Sidetrack Claim';
		contracts.add(contract2);

		CSX_CMP_Contract__c contract3 = new CSX_CMP_Contract__c();
		contract3.CSX_CMP_Status__c = 'Active';
		contract3.CSX_CMP_Customer_Name__r = new Account(CSX_CMP_External_ID__c = 'csxtransportationfreightclaims');
		contract3.CSX_CMP_Start_Date__c = Date.valueOf('2024-02-01');
		contract3.CSX_CMP_End_Date__c = Date.valueOf('2099-02-28');
		contract3.CSX_CMP_Business_Unit__c = 'CSX';
		contract3.CSX_CMP_Contract_Budget__c = 999999999;
		contract3.CSX_CMP_Consumed_Budget__c = 2444;
		contract3.CSX_CMP_Claim_Type__c = 'Incentive Claim';
		contracts.add(contract3);

		// contract2 = new CSX_CMP_Contract__c();
		// contract2.CSX_CMP_Status__c = 'Active';
		// contract2.CSX_CMP_Customer_Name__r = new Account( CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe');
		// contract2.CSX_CMP_Start_Date__c = Date.valueOf('2023-12-06');
		// contract2.CSX_CMP_End_Date__c = Date.valueOf('2024-01-31');
		// contract2.CSX_CMP_Business_Unit__c = 'PF';
		// contract2.CSX_CMP_Contract_Budget__c = 999999999;
		// contract2.CSX_CMP_Consumed_Budget__c = 23018;
		// contract2.CSX_CMP_Claim_Type__c = 'Sidetrack Claim';
		// contracts.add(contract2);

		insert contracts;
	}

	public static void createBusinessRules() {
		Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.CSX_CMP_Business_Rule__c.getRecordTypeInfosByDeveloperName();
		Id deskRecordTypeId = recordTypes.get('CSX_CMP_Claim_Desk_Assignment').getRecordTypeId();
		Id priorityRecordTypeId = recordTypes.get('CSX_CMP_Claim_Priority').getRecordTypeId();
		Id arThresholdRecordTypeId = recordTypes.get('CSX_CMP_AR_Threshold').getRecordTypeId();
		Id flrEmailRecordTypeId = recordTypes.get('CSX_CMP_FLR').getRecordTypeId();
		List<CSX_CMP_Business_Rule__c> businessRules = new List<CSX_CMP_Business_Rule__c>();

		// String businessRule1 = '{"Name": "Sidetrack", "CSX_CMP_Start_Date__c": Date.valueOf("2013-07-02"), "CSX_CMP_End_Date__c": Date.valueOf("2023-07-02"), "CSX_CMP_Version__c": 1, "CSX_CMP_Description__c": "Sidetrack Default", "CSX_CMP_Business_Rule__c": "1", "CSX_CMP_Status__c": "Valid", "CSX_CMP_Created_By__c": "Sidetrack-Generic DEVUser", "CSX_CMP_Claim_Type__c": "Sidetrack", "RecordTypeId":' + deskRecordTypeId + '}';

		// businessRules.add((CSX_CMP_Business_Rule__c) JSON.deserialize(businessRule1, CSX_CMP_Business_Rule__c.class));
		businessRules.add(
			buildBusinessRule(
				'Sidetrack',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2023-07-02'),
				1,
				'Sidetrack Default',
				'1',
				'Valid',
				'Sidetrack-Generic DEVUser',
				'Sidetrack',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'Contract Refunds',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2023-07-02'),
				1,
				'Contract Ref Default',
				'1',
				'Valid',
				'Contract Refunds-Generic DEVUser',
				'Contract Refunds',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'Railroad Payable',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2099-07-02'),
				2,
				'PAY - RR Default',
				'1 AND 2',
				'Valid',
				'Railroad Payable-Generic DEVUser',
				'Railroad Payable',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'Catchall Desk3',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2099-07-02'),
				1,
				'Default for Box Cars - Merchandise',
				'1',
				'Valid',
				'Desk 3-kedaraPriyaguggulla',
				'Catchall Desk3',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'Desk 11 Honda',
				Date.valueOf('2023-05-05'),
				Date.valueOf('2024-05-05'),
				6,
				'Automobiles - Honda',
				'1 AND 2',
				'Valid',
				'Desk 11-Generic DEVUser',
				'Desk 11',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'REC - Rule 185A1f',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2099-07-02'),
				null,
				'Rule 185A1f -  R11 changed to Through or vice versa',
				'1',
				'Valid',
				'NA',
				'REC - Rule 185A1f',
				deskRecordTypeId
			)
		);

		businessRules.add(
			buildBusinessRule(
				'FC Auto Priority - High',
				Date.valueOf('2013-07-02'),
				Date.valueOf('2099-07-02'),
				null,
				'FC Automobile claim >50K as high priority',
				'1',
				'Valid',
				'High',
				null,
				priorityRecordTypeId
			)
		);

		CSX_CMP_Business_Rule__c arThresholdRule = new CSX_CMP_Business_Rule__c();
		arThresholdRule.CSX_CMP_Rule_Name__c = 'AR Threshold Limit for Incentive claims';
		arThresholdRule.CSX_CMP_Start_Date__c = Date.valueOf('2013-07-02');
		arThresholdRule.CSX_CMP_End_Date__c = Date.valueOf('2099-07-02');
		arThresholdRule.CSX_CMP_Priority__c = null;
		arThresholdRule.CSX_CMP_Comments__c = 'AR Threshold Limit for Incentive claims';
		arThresholdRule.CSX_CMP_Where_Clause__c = '1 AND 2';
		arThresholdRule.CSX_CMP_Status__c = 'Valid';
		arThresholdRule.CSX_CMP_External_ID__c = 'AR Threshold Limit for Incentive claims';
		arThresholdRule.RecordTypeId = arThresholdRecordTypeId;
		arThresholdRule.CSX_CMP_AR_Threshold_Amount__c = 35000;
		arThresholdRule.CSX_CMP_Finance_Charge_Threshold__c = 30000;
		businessRules.add(arThresholdRule);

		CSX_CMP_Business_Rule__c flrEmailRule1 = new CSX_CMP_Business_Rule__c();
		flrEmailRule1.CSX_CMP_Rule_Name__c = 'FC Customer Claim FLR Questions 1';
		flrEmailRule1.CSX_CMP_Start_Date__c = Date.valueOf('2023-12-01');
		flrEmailRule1.CSX_CMP_End_Date__c = Date.valueOf('2024-11-30');
		flrEmailRule1.CSX_CMP_Comments__c = 'Questions to be listed on FLR email for FC Customer Claim when it is associated to Desk 16';
		flrEmailRule1.CSX_CMP_Where_Clause__c = '1 AND 2 AND 3 AND 4';
		flrEmailRule1.CSX_CMP_Status__c = 'Valid';
		flrEmailRule1.RecordTypeId = flrEmailRecordTypeId;
		flrEmailRule1.CSX_CMP_External_ID__c = 'FC Customer Claim FLR Questions 1';
		businessRules.add(flrEmailRule1);

		CSX_CMP_Business_Rule__c flrEmailRule2 = new CSX_CMP_Business_Rule__c();
		flrEmailRule2.CSX_CMP_Rule_Name__c = 'FC Customer Claim FLR Questions 2';
		flrEmailRule2.CSX_CMP_Start_Date__c = Date.valueOf('2024-01-01');
		flrEmailRule2.CSX_CMP_End_Date__c = Date.valueOf('2025-02-07');
		flrEmailRule2.CSX_CMP_Comments__c = 'Questions to be listed on FLR email for FC Customer Claim when it is associated to Desk 16';
		flrEmailRule2.CSX_CMP_Where_Clause__c = '1 AND 2 AND 3 AND 4';
		flrEmailRule2.CSX_CMP_Status__c = 'Valid';
		flrEmailRule2.RecordTypeId = flrEmailRecordTypeId;
		flrEmailRule2.CSX_CMP_External_ID__c = 'FC Customer Claim FLR Questions 2';
		businessRules.add(flrEmailRule2);

		CSX_CMP_Business_Rule__c flrEmailRule3 = new CSX_CMP_Business_Rule__c();
		flrEmailRule3.CSX_CMP_Rule_Name__c = 'FC Customer Claim FLR Questions 3';
		flrEmailRule3.CSX_CMP_Start_Date__c = Date.valueOf('2024-01-01');
		flrEmailRule3.CSX_CMP_End_Date__c = Date.valueOf('2025-01-23');
		flrEmailRule3.CSX_CMP_Comments__c = 'Questions to be listed on FLR email for FC Customer Claim when it is associated to Desk 16';
		flrEmailRule3.CSX_CMP_Where_Clause__c = '1 AND 2 AND 3 AND 4';
		flrEmailRule3.CSX_CMP_Status__c = 'Valid';
		flrEmailRule3.RecordTypeId = flrEmailRecordTypeId;
		flrEmailRule3.CSX_CMP_External_ID__c = 'FC Customer Claim FLR Questions 3';
		businessRules.add(flrEmailRule3);

		CSX_CMP_Business_Rule__c flrEmailRule4 = new CSX_CMP_Business_Rule__c();
		flrEmailRule4.CSX_CMP_Rule_Name__c = 'FC CUSTOMER AUTOMOBILE CLAIM';
		flrEmailRule4.CSX_CMP_Start_Date__c = Date.valueOf('2024-01-01');
		flrEmailRule4.CSX_CMP_End_Date__c = Date.valueOf('2025-01-23');
		flrEmailRule4.CSX_CMP_Comments__c = 'Automobiles - Honda';
		flrEmailRule4.CSX_CMP_Where_Clause__c = '1 AND 3 AND 4 AND 2';
		flrEmailRule4.CSX_CMP_Status__c = 'Valid';
		flrEmailRule4.RecordTypeId = flrEmailRecordTypeId;
		flrEmailRule4.CSX_CMP_External_ID__c = 'FC CUSTOMER AUTOMOBILE CLAIM';
		businessRules.add(flrEmailRule4);

		insert businessRules;

		List<CSX_CMP_Business_Rule_Condition__c> businessRuleConditions = new List<CSX_CMP_Business_Rule_Condition__c>();

		// Business Rule Conditions
		// Rules for Sidetrack
		businessRuleConditions.add(
			buildRuleCondition('Sidetrack', 'claim_claimType', 'Equal To', 'Sidetrack Claim', 'Sidetrack', 1)
		);
		// Rules for Contract Refunds
		businessRuleConditions.add(
			buildRuleCondition('Contract Refund', 'claim_recordType', 'Equal To', 'Contract Refund', 'Contract Refunds', 1)
		);
		// Rules for Railroad Payable
		businessRuleConditions.add(
			buildRuleCondition(
				'Railroad Payable',
				'claim_claimType',
				'Equal To',
				'Rev-RR - Receivable Rchg Claim',
				'Railroad Payable',
				1
			)
		);
		businessRuleConditions.add(
			buildRuleCondition(
				'Railroad Payable',
				'claim_claimType',
				'Equal To',
				'Rev-RR - Payable Claim',
				'Railroad Payable',
				2
			)
		);
		// Rules for Catchall Desk3
		businessRuleConditions.add(
			buildRuleCondition('Catchall Desk3', 'claim_supplierCountry', 'Equal To', 'US', 'Catchall Desk3', 1)
		);
		// Rules for Desk 11 Honda
		businessRuleConditions.add(
			buildRuleCondition(
				'Desk 11 Honda',
				'claim_equipment_equipmentShipper',
				'In List',
				'AMERICAN HONDA MOTOR COMPANY,AMERICAN HONDA MOTOR CO,HONDA DE MEXICO SA DE CV,HONDA CANADA INC,TM CLAIMS SERVICE INC,HONDA MANUFACTURING OF INDIANA',
				'Desk 11 Honda',
				1
			)
		);
		businessRuleConditions.add(
			buildRuleCondition('Desk 11 Honda', 'claim_claimVendor', 'Equal To', 'TM CLAIMS SERVICE INC', 'Desk 11 Honda', 2)
		);
		// Rules for REC - Rule 185A1f
		businessRuleConditions.add(
			buildRuleCondition(
				'REC - Rule 185A1f',
				'claim_claimReason',
				'Equal To',
				'REC - Rule 185A1f',
				'REC - Rule 185A1f',
				1
			)
		);

		// Rules for FC Auto Priority - High
		businessRuleConditions.add(
			buildRuleCondition(
				'FC Auto Priority - High',
				'claim_claimType',
				'Equal To',
				'FC Customer Automobile Claim',
				'FC Auto Priority - High',
				1
			)
		);

		// businessRuleConditions.add(
		// 	buildRuleCondition(
		// 		'FC Auto Priority - High',
		// 		'claim_claimAmount',
		// 		'Greater Than',
		// 		'50000',
		// 		'FC Auto Priority - High',
		// 		2
		// 	)
		// );

		// businessRuleConditions.add(
		// 	buildRuleCondition(
		// 		'FC Auto Priority - High',
		// 		'claim_claimAge',
		// 		'Greater Than',
		// 		'30',
		// 		'FC Auto Priority - High',
		// 		3
		// 	)
		// );

		// businessRuleConditions.add(
		// 	buildRuleCondition(
		// 		'FC Auto Priority - High',
		// 		'claim_claimStatus',
		// 		'In List',
		// 		'New, Open',
		// 		'FC Auto Priority - High',
		// 		4
		// 	)
		// );

		//Rules for AR Threshold Limit for Incentive claims
		businessRuleConditions.add(
			buildRuleCondition(
				'AR Threshold Limit for Incentive claims',
				'claim_claimType',
				'Equal To',
				'Incentive Claim',
				'AR Threshold Limit for Incentive claims',
				1
			)
		);

		businessRuleConditions.add(
			buildRuleCondition(
				'AR Threshold Limit for Incentive claims',
				'claim_nationalAccount',
				'In List',
				'0012505,1005456',
				'AR Threshold Limit for Incentive claims',
				2
			)
		);

		// Business Rule Conditions for FLR
		// Rules for FC Customer Claim FLR Questions 1
		businessRuleConditions.add(
			buildRuleCondition(
				'FC Customer Claim FLR Questions 1',
				'claim_claimType',
				'Equal To',
				'FC Customer Claim',
				'FC Customer Claim FLR Questions 1',
				1
			)
		);

		businessRuleConditions.add(
			buildRuleCondition(
				'FC Customer Claim FLR Questions 1',
				'claim_claimAmount',
				'Greater Than',
				'50000',
				'FC Customer Claim FLR Questions 1',
				2
			)
		);

		businessRuleConditions.add(
			buildRuleCondition(
				'FC Customer Claim FLR Questions 1',
				'claim_claimAge',
				'Greater Than',
				'30',
				'FC Customer Claim FLR Questions 1',
				3
			)
		);

		businessRuleConditions.add(
			buildRuleCondition(
				'FC Customer Claim FLR Questions 1',
				'claim_claimStatus',
				'In List',
				'New, Open',
				'FC Customer Claim FLR Questions 1',
				4
			)
		);

		insert businessRuleConditions;
	}

	public static void createFLREmailMaster() {
		List<CSX_CMP_FLR_Email_Master__c> freightClaimRailroads = new List<CSX_CMP_FLR_Email_Master__c>();

		String freightRR1 = '{"CSX_CMP_FC_Railroad_Road_Code__c": "777", "CSX_CMP_Desk__c": "ALL", "CSX_CMP_Start_Date__c": "2017-04-04", "CSX_CMP_End_Date__c": null, "CSX_CMP_Email__c": "cargoclaims@bnsf.com", "CSX_CMP_Claim_Type__c": "FC Customer Automobile Claim", "CSX_CMP_Enabled__c": true, "CSX_CMP_Desk_Name__c": "a0oO2000000jVioIAE"}';
		CSX_CMP_FLR_Email_Master__c freightClaimRailroad1 = (CSX_CMP_FLR_Email_Master__c) JSON.deserialize(
			freightRR1,
			CSX_CMP_FLR_Email_Master__c.class
		);
		freightClaimRailroads.add(freightClaimRailroad1);

		String freightRR2 = '{"CSX_CMP_FC_Railroad_Road_Code__c": "103", "CSX_CMP_Desk__c": "ALL", "CSX_CMP_Start_Date__c": "2023-02-13", "CSX_CMP_End_Date__c": null, "CSX_CMP_Email__c": "nautoflr@cn.ca", "CSX_CMP_Claim_Type__c": "FC Customer Automobile Claim", "CSX_CMP_Enabled__c": true, "CSX_CMP_Desk_Name__c": null}';
		CSX_CMP_FLR_Email_Master__c freightClaimRailroad2 = (CSX_CMP_FLR_Email_Master__c) JSON.deserialize(
			freightRR2,
			CSX_CMP_FLR_Email_Master__c.class
		);
		freightClaimRailroads.add(freightClaimRailroad2);

		String freightRR3 = '{"CSX_CMP_FC_Railroad_Road_Code__c": "263", "CSX_CMP_Desk__c": "ALL", "CSX_CMP_Start_Date__c": "2017-04-04", "CSX_CMP_End_Date__c": null, "CSX_CMP_Email__c": "freightclaims@fecrwy.com", "CSX_CMP_Claim_Type__c": "FC Customer Automobile Claim", "CSX_CMP_Enabled__c": true, "CSX_CMP_Desk_Name__c": null}';
		CSX_CMP_FLR_Email_Master__c freightClaimRailroad3 = (CSX_CMP_FLR_Email_Master__c) JSON.deserialize(
			freightRR3,
			CSX_CMP_FLR_Email_Master__c.class
		);
		freightClaimRailroads.add(freightClaimRailroad3);

		String freightRR4 = '{"CSX_CMP_FC_Railroad_Road_Code__c": "480", "CSX_CMP_Desk__c": "ALL", "CSX_CMP_Start_Date__c": "2017-04-04", "CSX_CMP_End_Date__c": null, "CSX_CMP_Email__c": "mnbr-cs@gwrr.com", "CSX_CMP_Claim_Type__c": "FC Customer Automobile Claim", "CSX_CMP_Enabled__c": true, "CSX_CMP_Desk_Name__c": null}';
		CSX_CMP_FLR_Email_Master__c freightClaimRailroad4 = (CSX_CMP_FLR_Email_Master__c) JSON.deserialize(
			freightRR4,
			CSX_CMP_FLR_Email_Master__c.class
		);
		freightClaimRailroads.add(freightClaimRailroad4);

		String freightRR5 = '{"CSX_CMP_FC_Railroad_Road_Code__c": "357", "CSX_CMP_Desk__c": "ALL", "CSX_CMP_Start_Date__c": "2017-04-04", "CSX_CMP_End_Date__c": null, "CSX_CMP_Email__c": "peggy.bricker@ihbrr.com", "CSX_CMP_Claim_Type__c": "FC Customer Automobile Claim", "CSX_CMP_Enabled__c": true, "CSX_CMP_Desk_Name__c": null}';
		CSX_CMP_FLR_Email_Master__c freightClaimRailroad5 = (CSX_CMP_FLR_Email_Master__c) JSON.deserialize(
			freightRR5,
			CSX_CMP_FLR_Email_Master__c.class
		);
		freightClaimRailroads.add(freightClaimRailroad5);

		insert freightClaimRailroads;
	}

	public static void createSimilarityMatrix() {
		List<CSX_CMP_Similarity_Matrix__c> similarityMatrixList = new List<CSX_CMP_Similarity_Matrix__c>();
		String matrix1 = '{"CSX_CMP_Damage_Code__c": "00","CSX_CMP_Similar_Damage_Code__c": "000","CSX_CMP_Start_Date__c": "2013-10-02","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_00_000"}';
		CSX_CMP_Similarity_Matrix__c matrix1Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix1,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix1Obj);

		String matrix2 = '{"CSX_CMP_Damage_Code__c": "01","CSX_CMP_Similar_Damage_Code__c": "01","CSX_CMP_Start_Date__c": "2013-03-18","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_01_01"}';
		CSX_CMP_Similarity_Matrix__c matrix2Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix2,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix2Obj);

		String matrix3 = '{"CSX_CMP_Damage_Code__c": "01","CSX_CMP_Similar_Damage_Code__c": "001","CSX_CMP_Start_Date__c": "2013-03-19","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_01_001"}';
		CSX_CMP_Similarity_Matrix__c matrix3Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix3,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix3Obj);

		String matrix4 = '{"CSX_CMP_Damage_Code__c": "01","CSX_CMP_Similar_Damage_Code__c": "23","CSX_CMP_Start_Date__c": "2013-03-20","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_01_23"}';
		CSX_CMP_Similarity_Matrix__c matrix4Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix4,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix4Obj);

		String matrix5 = '{"CSX_CMP_Damage_Code__c": "01","CSX_CMP_Similar_Damage_Code__c": "37","CSX_CMP_Start_Date__c": "2013-03-21","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_01_37"}';
		CSX_CMP_Similarity_Matrix__c matrix5Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix5,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix5Obj);

		String matrix6 = '{"CSX_CMP_Damage_Code__c": "02","CSX_CMP_Similar_Damage_Code__c": "002","CSX_CMP_Start_Date__c": "2013-03-22","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_02_002"}';
		CSX_CMP_Similarity_Matrix__c matrix6Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix6,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix6Obj);

		String matrix7 = '{"CSX_CMP_Damage_Code__c": "02","CSX_CMP_Similar_Damage_Code__c": "02","CSX_CMP_Start_Date__c": "2013-03-23","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_02_02"}';
		CSX_CMP_Similarity_Matrix__c matrix7Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix7,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix7Obj);

		String matrix8 = '{"CSX_CMP_Damage_Code__c": "02","CSX_CMP_Similar_Damage_Code__c": "49","CSX_CMP_Start_Date__c": "2013-03-24","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_02_49"}';
		CSX_CMP_Similarity_Matrix__c matrix8Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix8,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix8Obj);

		String matrix9 = '{"CSX_CMP_Damage_Code__c": "02","CSX_CMP_Similar_Damage_Code__c": "99","CSX_CMP_Start_Date__c": "2013-03-25","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_02_99"}';
		CSX_CMP_Similarity_Matrix__c matrix9Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix9,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix9Obj);

		String matrix10 = '{"CSX_CMP_Damage_Code__c": "03","CSX_CMP_Similar_Damage_Code__c": "003","CSX_CMP_Start_Date__c": "2013-03-26","CSX_CMP_End_Date__c": null,"CSX_CMP_Enabled__c": true,"CSX_CMP_Type__c": "Damage Area","CSX_CMP_External_ID__c": "Damage Area_03_003"}';
		CSX_CMP_Similarity_Matrix__c matrix10Obj = (CSX_CMP_Similarity_Matrix__c) JSON.deserialize(
			matrix10,
			CSX_CMP_Similarity_Matrix__c.class
		);
		similarityMatrixList.add(matrix10Obj);

		insert similarityMatrixList;
	}

	private static CSX_CMP_Desk__c buildDesk(
		String deskName,
		String description,
		Date startDate,
		Date endDate,
		String deskOwner
	) {
		CSX_CMP_Desk__c desk = new CSX_CMP_Desk__c();
		desk.Name = deskName;
		desk.CSX_CMP_Description__c = description;
		desk.CSX_CMP_Start_Date__c = startDate;
		desk.CSX_CMP_End_Date__c = endDate;
		desk.CSX_CMP_External_ID__c = deskName;
		desk.CSX_CMP_Desk_Owner__c = deskOwner;
		return desk;
	}

	private static CSX_CMP_Business_Rule__c buildBusinessRule(
		String ruleName,
		Date startDate,
		Date endDate,
		Integer priority,
		String comments,
		String whereClause,
		String status,
		String outcome,
		String deskExternalId,
		String recTypeName
	) {
		CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c();
		businessRule.CSX_CMP_Rule_Name__c = ruleName;
		businessRule.CSX_CMP_Start_Date__c = startDate;
		businessRule.CSX_CMP_End_Date__c = endDate;
		businessRule.CSX_CMP_Priority__c = priority;
		businessRule.CSX_CMP_Comments__c = comments;
		businessRule.CSX_CMP_Where_Clause__c = whereClause;
		businessRule.CSX_CMP_Status__c = status;
		businessRule.CSX_CMP_External_ID__c = ruleName;
		businessRule.RecordTypeId = recTypeName;
		if (String.isNotBlank(deskExternalId)) {
			businessRule.CSX_CMP_Desk_Name__r = new CSX_CMP_Desk__c(CSX_CMP_External_ID__c = deskExternalId);
		}
		return businessRule;
	}

	private static CSX_CMP_Business_Rule_Condition__c buildRuleCondition(
		String ruleName,
		String attributeName,
		String operator,
		String value,
		String businessRuleExternalId,
		Integer sequenceNumber
	) {
		CSX_CMP_Business_Rule_Condition__c businessRuleCondition = new CSX_CMP_Business_Rule_Condition__c();
		businessRuleCondition.CSX_CMP_Business_Rule__r = new CSX_CMP_Business_Rule__c(
			CSX_CMP_External_ID__c = businessRuleExternalId
		);
		businessRuleCondition.CSX_CMP_Attribute_Name__c = attributeName;
		businessRuleCondition.CSX_CMP_Operator__c = operator;
		businessRuleCondition.CSX_CMP_Value__c = value;
		businessRuleCondition.Name = String.valueOf(sequenceNumber);
		return businessRuleCondition;
	}

	public static void createInspectionHeaders() {
		// Id ediRecordTypeId = Schema.SObjectType.CSX_CMP_Inspection_Header__c.getRecordTypeInfosByDeveloperName()
		// 	.get('CSX_CMP_EDI')
		// 	.getRecordTypeId();
		// Id haulawayRecordTypeId = Schema.SObjectType.CSX_CMP_Inspection_Header__c.getRecordTypeInfosByDeveloperName()
		// 	.get('CSX_CMP_HAULAWAY')
		// 	.getRecordTypeId();

		Id masterRecordTypeId = Schema.SObjectType.CSX_CMP_Inspection_Header__c.getRecordTypeInfosByDeveloperName()
			.get('CSX_CMP_Master')
			.getRecordTypeId();

		List<CSX_CMP_Inspection_Header__c> inspectionHeaders = new List<CSX_CMP_Inspection_Header__c>();
		CSX_CMP_Inspection_Header__c inspectionHeader1 = new CSX_CMP_Inspection_Header__c();
		inspectionHeader1.CSX_CMP_VIN__c = '4T3LWRFVXPU102091';
		inspectionHeader1.CSX_CMP_Inspection_Date__c = Date.valueOf('2020-12-14');
		inspectionHeader1.CSX_CMP_Inspection_Road__c = 'TDSI';
		inspectionHeader1.CSX_CMP_Terminal_Name__c = 'New Boston';
		inspectionHeader1.CSX_CMP_Haulaway_Company__c = 'Truck Company Name';
		inspectionHeader1.CSX_CMP_Ramp_Id__c = 'test1234';
		// inspectionHeader1.CSX_CMP_Source__c = 'HAULAWAY';
		inspectionHeader1.CSX_CMP_Origin_Carrier__c = 'CSXT';
		inspectionHeader1.CSX_CMP_Route_Code__c = 'ABCDDD';
		inspectionHeader1.CSX_CMP_External_ID__c = '4T3LWRFVXPU102091_2020-12-14';
		inspectionHeader1.CSX_CMP_Haulaway_Transaction_ID__c = 'test1234';
		inspectionHeader1.CSX_CMP_Inspection_City__c = 'Annapolis';
		inspectionHeader1.CSX_CMP_Inspection_state__c = 'MD';
		inspectionHeader1.CSX_CMP_Inspector_ID__c = 'test9598';
		inspectionHeader1.CSX_CMP_Destination_Carrier__c = 'BNSF';
		inspectionHeader1.CSX_CMP_Shipment_Date__c = Date.valueOf('2020-12-01');
		inspectionHeader1.CSX_CMP_Seal_Status__c = 'aabc';
		inspectionHeader1.CSX_CMP_AAR_Equipment_Type__c = 'V123';
		inspectionHeader1.CSX_CMP_Vehicle_Type__c = '12345';
		inspectionHeader1.CSX_CMP_Dealer_Code__c = '7JJDBC';
		inspectionHeader1.CSX_CMP_Company_SCAC__c = 'DRAY';
		inspectionHeader1.CSX_CMP_Driver_License_ID__c = 'MD183858K00032093';
		inspectionHeader1.CSX_CMP_Driver_Phone_Number__c = '1234567890';
		inspectionHeader1.CSX_CMP_MFRS_Code__c = 'G';
		inspectionHeader1.CSX_CMP_Inspection_Report_Type__c = '04';
		inspectionHeader1.recordTypeId = masterRecordTypeId;
		inspectionHeaders.add(inspectionHeader1);

		CSX_CMP_Inspection_Header__c inspectionHeader2 = new CSX_CMP_Inspection_Header__c();
		inspectionHeader2.CSX_CMP_VIN__c = '4T3LWRFVXPU102092';
		inspectionHeader2.CSX_CMP_Inspection_Date__c = Date.valueOf('2024-01-05');
		inspectionHeader2.CSX_CMP_Inspection_Road__c = 'ACOM';
		inspectionHeader2.CSX_CMP_Inspection_Report_Type__c = '04';
		inspectionHeader2.CSX_CMP_External_ID__c = '43434343432024-01-05ACOM';
		inspectionHeader2.recordTypeId = masterRecordTypeId;
		inspectionHeader2.CSX_CMP_Source__c = 'HAULAWAY';
		inspectionHeaders.add(inspectionHeader2);

		CSX_CMP_Inspection_Header__c inspectionHeader3 = new CSX_CMP_Inspection_Header__c();
		inspectionHeader3.CSX_CMP_VIN__c = '4T3LWRFVXPU102087';
		inspectionHeader3.CSX_CMP_Inspection_Date__c = Date.valueOf('2024-01-05');
		inspectionHeader3.CSX_CMP_Inspection_Road__c = 'ACOM';
		inspectionHeader3.CSX_CMP_Manufacturer__c = 'QUIN';
		inspectionHeader3.CSX_CMP_Ramp_Id__c = 'RAMP1234';
		// inspectionHeader3.CSX_CMP_Source__c = 'HAULAWAY';
		inspectionHeader3.CSX_CMP_External_ID__c = '4T3LWRFVXPU102087_2024-01-05ACOM';
		inspectionHeader3.CSX_CMP_AAR_Equipment_Type__c = 'TTX';
		inspectionHeader3.CSX_CMP_Bay_Locate__c = 'SS';
		inspectionHeader3.recordTypeId = masterRecordTypeId;
		inspectionHeaders.add(inspectionHeader3);

		insert inspectionHeaders;
	}

	public static void createInspectionDetails() {
		List<CSX_CMP_Inspection_Detail__c> inspectionDetails = new List<CSX_CMP_Inspection_Detail__c>();
		CSX_CMP_Inspection_Detail__c inspectionDetail1 = new CSX_CMP_Inspection_Detail__c();
		inspectionDetail1.CSX_CMP_External_ID__c = '0000088888070102';
		inspectionDetail1.CSX_CMP_Damage_Severity__c = '1';
		inspectionDetail1.CSX_CMP_Damage_Type__c = '01';
		inspectionDetail1.CSX_CMP_Damage_Area__c = '06';
		inspectionDetail1.CSX_CMP_Inspection_Header__r = new CSX_CMP_Inspection_Header__c(
			CSX_CMP_External_ID__c = '4T3LWRFVXPU102091_2020-12-14'
		);
		inspectionDetails.add(inspectionDetail1);

		CSX_CMP_Inspection_Detail__c inspectionDetail2 = new CSX_CMP_Inspection_Detail__c();
		inspectionDetail2.CSX_CMP_Damage_Severity__c = '1';
		inspectionDetail2.CSX_CMP_Damage_Type__c = '01';
		inspectionDetail2.CSX_CMP_Damage_Area__c = '06';
		inspectionDetail2.CSX_CMP_Inspection_Header__r = new CSX_CMP_Inspection_Header__c(
			CSX_CMP_External_ID__c = '43434343432024-01-05ACOM'
		);
		inspectionDetails.add(inspectionDetail2);

		CSX_CMP_Inspection_Detail__c inspectionDetail3 = new CSX_CMP_Inspection_Detail__c();
		inspectionDetail3.CSX_CMP_Damage_Severity__c = '1';
		inspectionDetail3.CSX_CMP_Damage_Type__c = '01';
		inspectionDetail3.CSX_CMP_Damage_Area__c = '06';
		inspectionDetail3.CSX_CMP_Inspection_Header__r = new CSX_CMP_Inspection_Header__c(
			CSX_CMP_External_ID__c = '4T3LWRFVXPU102091_2020-12-14'
		);
		inspectionDetails.add(inspectionDetail3);

		CSX_CMP_Inspection_Detail__c inspectionDetail4 = new CSX_CMP_Inspection_Detail__c();
		inspectionDetail4.CSX_CMP_Damage_Severity__c = '0';
		inspectionDetail4.CSX_CMP_Damage_Type__c = '00';
		inspectionDetail4.CSX_CMP_Damage_Area__c = '00';
		inspectionDetail4.CSX_CMP_Inspection_Header__r = new CSX_CMP_Inspection_Header__c(
			CSX_CMP_External_ID__c = '4T3LWRFVXPU102087_2024-01-05ACOM'
		);
		inspectionDetails.add(inspectionDetail4);
		insert inspectionDetails;
	}

	public static void createDocuments(String folderId) {
		List<Document> documents = new List<Document>();
		Document testDocument = new Document(
			DeveloperName = 'CSX_CMP_Logo',
			FolderId = folderId,
			Name = 'Test Logo',
			Body = Blob.valueOf('Test Content')
		);
		documents.add(testDocument);
		insert documents;
	}

	public static void createCustomSettings() {
		List<CSX_CMP_External_Interface_Endpoint__c> endpoints = new List<CSX_CMP_External_Interface_Endpoint__c>();

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Total Miles',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/shipcsx-reference/v1/mileage/search'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'ECM_Upload_Revenue',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/enterprise-documents/v1/repositories/ecm-revenueclaims/documents'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Customer Service Status Update',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/salesforce-case/v1/claims/UpdateClaim'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'ECM_Upload_Freight',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/enterprise-documents/v1/repositories/ecm-FreightClaims/documents'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'MTI',
				CSX_CMP_End_Point__c = 'http://apidev.csx.com/mechanical-events/api/v1/bad-orders'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Case Detail',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/salesforce-case/v1/claims/casecardetail'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Case Summary',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/salesforce-case/v1/claims/casecarsummary'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Freight Bill',
				CSX_CMP_End_Point__c = 'https://integration-dev-zs11iare.it-cpi013-rt.cfapps.us21.hana.ondemand.com/http/v1/freight-bill-details'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'BTP',
				CSX_CMP_End_Point__c = 'https://integration-dev-zs11iare.it-cpi013-rt.cfapps.us21.hana.ondemand.com/http/v1/approval-initiate'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'ARBalance',
				CSX_CMP_End_Point__c = 'https://integration-dev-zs11iare.it-cpi013-rt.cfapps.us21.hana.ondemand.com/http/v1/ar-balance-details'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Axway Token URL',
				CSX_CMP_End_Point__c = 'https://logon-dev.csx.com/oauth2/aus1j3sfjmaIVNNit0h8/v1/token'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'Mileage',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/shipcsx-reference/v1/mileage/segments/search'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'RARS',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/safety-rar/v1/freight-claims'
			)
		);

		endpoints.add(
			new CSX_CMP_External_Interface_Endpoint__c(
				Name = 'UMLER',
				CSX_CMP_End_Point__c = 'https://apistaging.csx.com/umler/v1/cars/search'
			)
		);

		insert endpoints;

		CSX_CMP_Axway_Connection_Detail__c axwayConnection = new CSX_CMP_Axway_Connection_Detail__c(
			CSX_CMP_APIKey__c = 'test',
			CSX_CMP_APISecret__c = 'test',
			CSX_CMP_End_Point__c = 'https://logon-dev.csx.com/oauth2/aus1j3sfjmaIVNNit0h8/v1/token'
		);

		insert axwayConnection;

		List<CSX_CMP_Last_Execution_Log__c> executionLogs = new List<CSX_CMP_Last_Execution_Log__c>();
		executionLogs.add(
			new CSX_CMP_Last_Execution_Log__c(
				Name = 'CMP-E-0425_FLR_Email_Batch',
				CSX_CMP_RICEFW_Reference__c = 'CMP-E-0425',
				CSX_CMP_Process_Name__c = 'Send FLR Emails',
				CSX_CMP_Execution_Time__c = Datetime.newInstance(2023, 10, 1, 7, 16, 0)
			)
		);

		executionLogs.add(
			new CSX_CMP_Last_Execution_Log__c(
				Name = 'CMP-I-0439_Send_onhold_email',
				CSX_CMP_RICEFW_Reference__c = 'CMP-I-0439',
				CSX_CMP_Process_Name__c = 'Send OnHold Remainder Email',
				CSX_CMP_Execution_Time__c = Datetime.newInstance(2024, 6, 4, 15, 44, 16),
				CSX_CMP_For_System_Use_Only__c = UserInfo.getUserEmail()
			)
		);

		executionLogs.add(
			new CSX_CMP_Last_Execution_Log__c(
				Name = 'CMP-E-0491_Invoice_Email_Batch',
				CSX_CMP_RICEFW_Reference__c = 'CMP-E-0491',
				CSX_CMP_Process_Name__c = 'Send Invoice Email',
				CSX_CMP_Execution_Time__c = Datetime.newInstance(2024, 3, 28, 7, 33, 0)
			)
		);

		insert executionLogs;

		List<CSX_CMP_Claim_Email_Service__c> claimEmailServices = new List<CSX_CMP_Claim_Email_Service__c>();
		CSX_CMP_Claim_Email_Service__c claimEmailService1 = new CSX_CMP_Claim_Email_Service__c();

		claimEmailService1.CSX_CMP_Email_Id__c = 'csxsupport@t-1kkfl0uyamiwc87ryblp1sq06kq1g8sv1wdo37mvepws0w4ie.dz-1qdzhmay.usa256s.apex.sandbox.salesforce.com';
		claimEmailServices.add(claimEmailService1);

		insert claimEmailServices;
	}

	public static String umlerMockResponse() {
		Map<String, Object> response = new Map<String, Object>();
		Map<String, Object> getUMLERDataResponse = new Map<String, Object>();
		Map<String, Object> commonHeader = new Map<String, Object>();
		commonHeader.put('consumerID', 'SY');
		commonHeader.put('applicationID', 'UM');
		commonHeader.put('transactionName', 'getUMLERData');
		commonHeader.put('timestamp', system.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSSSSXXX'));
		commonHeader.put('invokedBy', 'JWDS_APP');
		getUMLERDataResponse.put('commonHeader', commonHeader);
		getUMLERDataResponse.put('returnCode', '00');
		getUMLERDataResponse.put('returnDescription', 'SUCCESS');
		Map<String, Object> carDetailsList = new Map<String, Object>();
		List<Map<String, Object>> carDetails = new List<Map<String, Object>>();
		Map<String, Object> car1 = new Map<String, Object>();
		car1.put('carID', 'CSXT	  143030');
		List<Map<String, Object>> element1 = new List<Map<String, Object>>();
		Map<String, Object> element1_1 = new Map<String, Object>();
		element1_1.put('elementID', 'UMET');
		element1_1.put('elementDesc', 'NULL');
		element1_1.put('filter', 'EQPT');
		Map<String, Object> elementDetails1_1 = new Map<String, Object>();
		elementDetails1_1.put('location', '0000000000');
		elementDetails1_1.put('value', 'D127');
		elementDetails1_1.put('valueDesc', 'NULL');
		element1_1.put('elementDetails', elementDetails1_1);
		element1.add(element1_1);
		Map<String, Object> element1_2 = new Map<String, Object>();
		element1_2.put('elementID', 'UMMD');
		element1_2.put('elementDesc', 'NULL');
		element1_2.put('filter', 'EQPT');
		Map<String, Object> elementDetails1_2 = new Map<String, Object>();
		elementDetails1_2.put('location', '0000000000');
		elementDetails1_2.put('value', 'D');
		elementDetails1_2.put('valueDesc', 'Locomotive');
		element1_2.put('elementDetails', elementDetails1_2);
		element1.add(element1_2);
		Map<String, Object> element1_3 = new Map<String, Object>();
		element1_3.put('elementID', 'UMOW');
		element1_3.put('elementDesc', 'NULL');
		element1_3.put('filter', 'EQPT');
		Map<String, Object> elementDetails1_3 = new Map<String, Object>();
		elementDetails1_3.put('location', '0000000000');
		elementDetails1_3.put('value', 'CSXT');
		elementDetails1_3.put('valueDesc', 'NULL');
		element1_3.put('elementDetails', elementDetails1_3);
		element1.add(element1_3);
		Map<String, Object> element1_4 = new Map<String, Object>();
		element1_4.put('elementID', '9008');
		element1_4.put('elementDesc', 'NULL');
		element1_4.put('filter', 'EQPT');
		Map<String, Object> elementDetails1_4 = new Map<String, Object>();
		elementDetails1_4.put('location', '0000000000');
		elementDetails1_4.put('value', 'CSXT');
		elementDetails1_4.put('valueDesc', 'NULL');
		element1_4.put('elementDetails', elementDetails1_4);
		element1.add(element1_4);
		car1.put('element', element1);
		carDetails.add(car1);
		carDetailsList.put('carDetails', carDetails);
		getUMLERDataResponse.put('carDetailsList', carDetailsList);
		response.put('getUMLERDataResponse', getUMLERDataResponse);
		return JSON.serialize(response);
	}

	public static String mtiMockResponse() {
		List<Map<String, Object>> mtiResponse = new List<Map<String, Object>>();
		Map<String, Object> mtiEvent = new Map<String, Object>();
		mtiEvent.put('carInit', 'CSXT');
		mtiEvent.put('carNum', '143030');
		mtiEvent.put('eventType', 'BadOrder');
		mtiEvent.put('eventDate', '2016-02-22 09:45:27.0');
		mtiEvent.put('trainId', 'Y19516');
		mtiEvent.put('trackId', 'B28');
		mtiEvent.put('loadOrEmpty', 'L');
		mtiEvent.put('eventClass', 'BOS');
		mtiEvent.put('eventNotes', 'CSX221;CSX220-bearing');
		mtiResponse.add(mtiEvent);
		return JSON.serialize(mtiResponse);
	}

	public static String rarsMockResponse() {
		Map<String, Object> rarsResponse = new Map<String, Object>();
		rarsResponse.put('equipmentInitial', 'CSXT');
		rarsResponse.put('equipmentNumber', 143030);
		rarsResponse.put('incidentCategoryCode', 'D');
		rarsResponse.put('incidentCity', 'CLEVELAND');
		rarsResponse.put('incidentId', 'R000196401');
		rarsResponse.put('incidentState', 'OH');
		rarsResponse.put('incidentTimestamp', '2021-03-17T11:56:00');
		return JSON.serialize(rarsResponse);
	}

	// Data needs to be adjusted for caseSummaryMockResponse, caseDetailMockResponse,totalMilesMockResponse,mileageMockResponse adjusting to  the test data on Utility class
	public static String caseSummaryMockResponse() {
		/**
		string jsonString = '{"errorObject": {"message": "SUCCESS","code": "200"},"CaseCarSummaryList": [{"status": "Open","equipmentNumber": "CSXT130004","createdDate": "2020-11-02T11:51:43.000Z","contactIdName": "William Olson","caseNumber": "00001045","callerCompanyName": "INTERNATIONAL PAPER CO"},{"status": "New","equipmentNumber": "CSXT130004","createdDate": "2020-12-02T12:16:57.000Z","contactIdName": "William Olson","caseNumber": "00330131","callerCompanyName": "INTERNATIONAL PAPER CO | AL AUTAUGA CREEK"}]}';
		 */
		Map<String, Object> caseSummaryResponse = new Map<String, Object>();
		caseSummaryResponse.put('errorObject', new Map<String, Object>{ 'message' => 'SUCCESS', 'code' => '200' });
		List<Map<String, Object>> caseCarSummaryList = new List<Map<String, Object>>();
		Map<String, Object> case1 = new Map<String, Object>();
		case1.put('status', 'Open');
		case1.put('equipmentNumber', 'CSXT143030');
		case1.put('createdDate', '2020-11-02T11:51:43.000Z');
		case1.put('contactIdName', 'William Olson');
		case1.put('caseNumber', '00001045');
		case1.put('callerCompanyName', 'INTERNATIONAL PAPER CO');
		caseCarSummaryList.add(case1);
		Map<String, Object> case2 = new Map<String, Object>();
		case2.put('status', 'New');
		case2.put('equipmentNumber', 'CSXT143030');
		case2.put('createdDate', '2020-12-02T12:16:57.000Z');
		case2.put('contactIdName', 'William Olson');
		case2.put('caseNumber', '00330131');
		case2.put('callerCompanyName', 'INTERNATIONAL PAPER CO | AL AUTAUGA CREEK');
		caseCarSummaryList.add(case2);
		caseSummaryResponse.put('CaseCarSummaryList', caseCarSummaryList);
		return JSON.serialize(caseSummaryResponse);
	}

	public static String caseDetailMockResponse() {
		/**
		string jsonString = '{"errorObject": {"message": "SUCCESS","code": "200"},"CaseCarDetailObject": {"status": "CSX Responded","shipCsxUserId": null,"RelatedResponsesList": [{"type": "SPR","responseByName": null,"createdDate": "2020-12-03T12:56:05.000Z","comment": "adding a new response to this case"}],"RelatedCaseCommentsList": [{"creatorName": "William Olson","createdDate": "2020-12-08T11:51:13.000Z","commentBody": "Adding Comments Here Its a Disaster Empty Car,Event: PullCutoff: 2020-06-18T12:29:05.050ZKey: SHA  01108 Sub Event: Pull from Station Track 49From Track Spot: 2020-06-15T11:11:11.050ZTo Track Spot: 2020-06-18T12:29:05.050ZCurrent Location: INTERNATIONAL PAPER CO AL AUTAUGA CREEK(SHA  01108)STCC: 4211299Car Remarks: Add my Car Remarks here"}],"reason": "E-Business Set Up","onBehalfOfName": null,"equipmentList": "CSXT130004","description": "adding a note to this case","customerRole": "Shipper","contactPhone": "904-633-4891","contactIdName": "William Olson","contactEmail": "william_olson@csx.com.invalid","caseNumber": "00330135","callerCompanyName": "INTERNATIONAL PAPER CO"}}';
		 */
		Map<String, Object> caseDetailResponse = new Map<String, Object>();
		caseDetailResponse.put('errorObject', new Map<String, Object>{ 'message' => 'SUCCESS', 'code' => '200' });
		Map<String, Object> caseCarDetailObject = new Map<String, Object>();
		caseCarDetailObject.put('status', 'CSX Responded');
		caseCarDetailObject.put('shipCsxUserId', null);
		List<Map<String, Object>> relatedResponsesList = new List<Map<String, Object>>();
		Map<String, Object> response1 = new Map<String, Object>();
		response1.put('type', 'SPR');
		response1.put('responseByName', null);
		response1.put('createdDate', '2020-12-03T12:56:05.000Z');
		response1.put('comment', 'adding a new response to this case');
		relatedResponsesList.add(response1);
		caseCarDetailObject.put('RelatedResponsesList', relatedResponsesList);
		List<Map<String, Object>> relatedCaseCommentsList = new List<Map<String, Object>>();
		Map<String, Object> comment1 = new Map<String, Object>();
		comment1.put('creatorName', 'William Olson');
		comment1.put('createdDate', '2020-12-08T11:51:13.000Z');
		comment1.put(
			'commentBody',
			'Adding Comments Here Its a Disaster Empty Car,Event: PullCutoff: 2020-06-18T12:29:05.050ZKey: SHA  01108 Sub Event: Pull from Station Track 49From Track Spot: 2020-06-15T11:11:11.050ZTo Track Spot: 2020-06-18T12:29:05.050ZCurrent Location: INTERNATIONAL PAPER CO AL AUTAUGA CREEK(SHA  01108)STCC: 4211299Car Remarks: Add my Car Remarks here'
		);
		relatedCaseCommentsList.add(comment1);
		caseCarDetailObject.put('RelatedCaseCommentsList', relatedCaseCommentsList);
		caseCarDetailObject.put('reason', 'E-Business Set Up');
		caseCarDetailObject.put('onBehalfOfName', null);
		caseCarDetailObject.put('equipmentList', 'CSXT143030');
		caseCarDetailObject.put('description', 'adding a note to this case');
		caseCarDetailObject.put('customerRole', 'Shipper');
		caseCarDetailObject.put('contactPhone', '904-633-4891');
		caseCarDetailObject.put('contactIdName', 'William Olson');
		caseCarDetailObject.put('contactEmail', 'william_olson@csx.com.invalid');
		caseCarDetailObject.put('caseNumber', '00330135');
		caseCarDetailObject.put('callerCompanyName', 'INTERNATIONAL PAPER CO');
		caseDetailResponse.put('CaseCarDetailObject', caseCarDetailObject);
		return JSON.serialize(caseDetailResponse);
	}

	public static String totalMilesMockResponse() {
		/**
		String jsonString = '[{"destination":{"city":"TAMPA","state":"FL"},"mileage":"510","origin":{"city":"JACKSONVILLE","state":"FL"},"route":"CSXT "}]';
		 */
		List<Map<String, Object>> totalMilesResponse = new List<Map<String, Object>>();
		Map<String, Object> totalMiles = new Map<String, Object>();
		Map<String, Object> destination = new Map<String, Object>();
		destination.put('city', 'TAMPA');
		destination.put('state', 'FL');
		totalMiles.put('destination', destination);
		totalMiles.put('mileage', '510');
		Map<String, Object> origin = new Map<String, Object>();
		origin.put('city', 'JACKSONVILLE');
		origin.put('state', 'FL');
		totalMiles.put('origin', origin);
		totalMiles.put('route', 'CSXT');
		totalMilesResponse.add(totalMiles);
		return JSON.serialize(totalMilesResponse);
	}

	public static String mileageMockResponse() {
		/**
		string jsonString = '{"application":"SHIPCSX","mileageRoutes":[{"destination":{"city":"LAREDO","state":"TX","stationType":"OPSL"},"origin":{"city":"MIAMI","state":"FL","stationType":"OPSL"},"routeType":"FULL_ROUTE","mileage":1688,"segments":[{"junctionCode":"JACVL","roadCode":"FEC ","mileage":349},{"junctionCode":"NEWOR","roadCode":"CSXT","mileage":616},{"roadCode":"UP  ","mileage":723}]}]}';
		 */
		Map<String, Object> mileageResponse = new Map<String, Object>();
		mileageResponse.put('application', 'SHIPCSX');
		List<Map<String, Object>> mileageRoutes = new List<Map<String, Object>>();
		Map<String, Object> mileageRoute = new Map<String, Object>();
		Map<String, Object> destination = new Map<String, Object>();
		destination.put('city', 'LAREDO');
		destination.put('state', 'TX');
		destination.put('stationType', 'OPSL');
		mileageRoute.put('destination', destination);
		Map<String, Object> origin = new Map<String, Object>();
		origin.put('city', 'MIAMI');
		origin.put('state', 'FL');
		origin.put('stationType', 'OPSL');
		mileageRoute.put('origin', origin);
		mileageRoute.put('routeType', 'FULL_ROUTE');
		mileageRoute.put('mileage', 1688);
		List<Map<String, Object>> segments = new List<Map<String, Object>>();
		Map<String, Object> segment1 = new Map<String, Object>();
		segment1.put('junctionCode', 'JACVL');
		segment1.put('roadCode', 'FEC');
		segment1.put('mileage', 349);
		segments.add(segment1);
		Map<String, Object> segment2 = new Map<String, Object>();
		segment2.put('junctionCode', 'NEWOR');
		segment2.put('roadCode', 'CSXT');
		segment2.put('mileage', 616);
		segments.add(segment2);
		Map<String, Object> segment3 = new Map<String, Object>();
		segment3.put('roadCode', 'UP');
		segment3.put('mileage', 723);
		segments.add(segment3);
		mileageRoute.put('segments', segments);
		mileageRoutes.add(mileageRoute);
		mileageResponse.put('mileageRoutes', mileageRoutes);
		return JSON.serialize(mileageResponse);
	}

	public static string arBalanceMockResponse() {
		/**
		{"ARBalanceDetailsSet":{"ARBalanceDetails":{"totalOutstandingAccountReceivablebalance":"12050.00 USD","pastDueAccountReceivable":"12050.00 USD","past15DaysDuedateAccountReceivableBalance":"2000.00 USD","financeCharges":"6750.00 USD"}}}
		 */
		Map<String, Object> response = new Map<String, Object>();
		Map<String, Object> balance = new Map<String, Object>();
		balance.put('totalOutstandingAccountReceivablebalance', '12050.00 USD');
		balance.put('pastDueAccountReceivable', '12050.00 USD');
		balance.put('past15DaysDuedateAccountReceivableBalance', '2000.00 USD');
		balance.put('financeCharges', '6750.00 USD');
		response.put('ARBalanceDetails', balance);
		return JSON.serialize(response);
	}

	public static String freightBillDetailsMockResponse() {
		/**
		{"freightBillResponseSet":{"freightBillResponse":[{"wayBillControlNumber":"CMX-000000-118634-231024-1","freightBillNumber":"0010000014","billedAmount":"40000.00","amountReceived":"0.00","balanceDue":"0.00","wayBillDate":"2023-12-22T00:00:00.000"},{"wayBillControlNumber":"CMX-000000-118634-231024-1","freightBillNumber":"0010000013","billedAmount":"30000.00","amountReceived":"0.00","balanceDue":"0.00","wayBillDate":"2023-12-22T00:00:00.000"}]}}
		 */
		Map<String, Object> response = new Map<String, Object>();
		Map<String, Object> freightBillResponse = new Map<String, Object>();
		List<Map<String, Object>> freightBillList = new List<Map<String, Object>>();
		Map<String, Object> freightBill1 = new Map<String, Object>();
		freightBill1.put('wayBillControlNumber', 'CMX-000000-118634-231024-1');
		freightBill1.put('freightBillNumber', '0010000014');
		freightBill1.put('billedAmount', '40000.00');
		freightBill1.put('amountReceived', '0.00');
		freightBill1.put('balanceDue', '0.00');
		freightBill1.put('wayBillDate', '2023-12-22T00:00:00.000');
		freightBillList.add(freightBill1);
		Map<String, Object> freightBill2 = new Map<String, Object>();
		freightBill2.put('wayBillControlNumber', 'CMX-000000-118634-231024-1');
		freightBill2.put('freightBillNumber', '0010000013');
		freightBill2.put('billedAmount', '30000.00');
		freightBill2.put('amountReceived', '0.00');
		freightBill2.put('balanceDue', '0.00');
		freightBill2.put('wayBillDate', '2023-12-22T00:00:00.000');
		freightBillList.add(freightBill2);
		freightBillResponse.put('freightBillResponse', freightBillList);
		response.put('freightBillResponseSet', freightBillResponse);
		return JSON.serialize(response);
	}

	public static String btpMockResponse() {
		/**
		{
      "claimId": "500Dz00000a7bqxIDF",
      "integrationStatus": "Error",
      "errorReason": "Entity already exists"
   }
		 */
		Map<String, Object> response = new Map<String, Object>();
		response.put('claimId', '500Dz00000a7bqxIDF');
		response.put('integrationStatus', 'Error');
		response.put('errorReason', 'Entity already exists');
		return JSON.serialize(response);
	}
}