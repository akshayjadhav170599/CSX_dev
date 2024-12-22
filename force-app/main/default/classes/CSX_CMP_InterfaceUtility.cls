/**************************************************************************************
	Apex Class Name     : CSX_CMP_InterfaceUtility
	Function            : Class to keep all reusuable interface callouts
	Modification Log    :
	* Developer         : Date             Description 
	* ----------------------------------------------------------------------------                  
	* Infosys           02/11/2023       First version of this class.
	*************************************************************************************/
	public with sharing class CSX_CMP_InterfaceUtility {
		//Method to fetch Equipments from SIMS converting UI Input to SIMS Input
		@AuraEnabled(cacheable=false)
		public static List<ShipmentResponseWrapper> newShipmentMaptoWrapper(Map<String, String> shipmentDetails) {
			List<ShipmentResponseWrapper> responseList = new List<ShipmentResponseWrapper>();
			List<ShipmentRequestWrapper> shipmentReqWrap = new List<ShipmentRequestWrapper>();
			ShipmentRequestWrapper shipmentWrapper = new ShipmentRequestWrapper();
			String type;
			try {
				String equipmentId = String.isNotBlank(shipmentDetails.get('equipmentId'))
					? shipmentDetails.get('equipmentId')
					: null;
				if (equipmentId != null) {
					List<String> split = equipmentId.split('(?<=\\D)(?=\\d)');
					if (split.size() >= 2) {
						shipmentWrapper.equipmentInitial = equipmentId != null ? split[0] : 'null';
						shipmentWrapper.equipmentNumber = equipmentId != null ? split[1] : 'null';
					}
				}
				shipmentWrapper.waybillFromDate = String.isNotBlank(shipmentDetails.get('startDate'))
					? shipmentDetails.get('startDate')
					: 'null';
				shipmentWrapper.waybillToDate = String.isNotBlank(shipmentDetails.get('startDate'))
					? String.valueOf(Date.valueOf(shipmentDetails.get('startDate')).addDays(7))
					: 'null';
				shipmentWrapper.waybillNumber = String.isNotBlank(shipmentDetails.get('waybillNumber'))
					? shipmentDetails.get('waybillNumber')
					: 'null';
				String vinNumber = String.isNotBlank(shipmentDetails.get('vin'))
					? shipmentDetails.get('vin').toUpperCase()
					: 'null';
				shipmentWrapper.vinNumber = new List<String>{ vinNumber };
				String urrwinNumber = String.isNotBlank(shipmentDetails.get('urrwinNumber'))
					? shipmentDetails.get('urrwinNumber')
					: 'null';
				shipmentWrapper.urrwinNumber = urrwinNumber.split(',');
				shipmentReqWrap.Add(shipmentWrapper);
				if (String.isNotBlank(shipmentDetails.get('equipmentId'))) {
					type = 'equipment';
				} else if (String.isNotBlank(shipmentDetails.get('waybillNumber'))) {
					type = 'waybill';
				} else if (String.isNotBlank(shipmentDetails.get('vin'))) {
					type = 'vin';
				} else if (String.isNotBlank(shipmentDetails.get('urrwinNumber'))) {
					type = 'urrwin';
				}

				responseList = getShipmentDetails(shipmentReqWrap, type);
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_SIMSInterface',
					'newShipmentMaptoWrapper',
					string.valueOf(shipmentWrapper),
					e
				);
			}
			return responseList;
		}

		// Method to fetch Equipments from SIMS
		public static List<ShipmentResponseWrapper> getShipmentDetails(
			List<ShipmentRequestWrapper> shipmentReqWrap,
			String reqType
		) {
			List<ShipmentResponseWrapper> responseList = new List<ShipmentResponseWrapper>();
			Map<String, String> requestMap = new Map<String, String>();
			string endPointUrl;
			HttpResponse response;
			String requestBody;
			try {
				if (reqType == 'equipment') {
					requestBody = JSON.serialize(shipmentReqWrap);
				} else if (reqType == 'vin') {
					List<String> vinNumbers = shipmentReqWrap[0].vinNumber;
					requestBody = JSON.serialize(vinNumbers);
				} else if (reqType == 'urrwin') {
					requestBody = JSON.serialize(shipmentReqWrap[0].urrwinNumber);
				} else if (reqType == 'waybill') {
					requestBody = JSON.serialize(shipmentReqWrap);
				}
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('SIMS');
				endPointUrl = endpoint.CSX_CMP_End_Point__c + reqType;
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endPointUrl);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 200 && response.getBody() != null) {
					List<Object> resultObjectList = (List<Object>) JSON.deserializeunTyped(response.getBody());
					if (resultObjectList != null && !resultObjectList.isEmpty()) {
						for (Object resultObject : resultObjectList) {
							ShipmentResponseWrapper shipment = new ShipmentResponseWrapper();
							shipment.products = new List<CSX_CMP_NewClaimWrapper.Product>();
							shipment.distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
							Map<String, Object> shipmentResponseMap = (Map<String, Object>) resultObject;
							shipment.waybillNumber = (String) shipmentResponseMap.get('waybillNumber');
							shipment.waybillDate = shipmentResponseMap.get('waybillDate') != null
								? Date.valueOf((String) shipmentResponseMap.get('waybillDate'))
								: null;
							shipment.waybillControls = (String) shipmentResponseMap.get('controlCode');
							shipment.originAuditNumber = (String) shipmentResponseMap.get('originFsac');
							shipment.actualOriginSCAC = (String) shipmentResponseMap.get('originScac');
							shipment.actualOriginCityName = (String) shipmentResponseMap.get('originCityName');
							shipment.actualOriginStateCode = (String) shipmentResponseMap.get('originStateOrProvince');
							shipment.destinationAuditNumber = (String) shipmentResponseMap.get('destinationFsac');
							shipment.destinationRoadNumber = (String) shipmentResponseMap.get('destinationRoadNumber');
							shipment.originRoadNumber = (String) shipmentResponseMap.get('originRoadNumber');
							shipment.actualDestinationSCAC = (String) shipmentResponseMap.get('destinationScac');
							shipment.actualDestinationCityName = (String) shipmentResponseMap.get('destinationCityName');
							shipment.actualDestinationStateCode = (String) shipmentResponseMap.get('destinationStateOrProvince');
							shipment.flatCarId = (String) shipmentResponseMap.get('flatCarNumber');
							shipment.businessUnit = (String) shipmentResponseMap.get('businessUnit');
							if (String.isNotBlank(shipment.flatCarId)) {
								//TTXX     759716
								shipment.flatCarId =
									shipment.flatCarId.substring(0, 4) +
									' ' +
									shipment.flatCarId.substring(4, shipment.flatCarId.length()).trim();
							}
							// shipment.flatCarId = (String) shipmentResponseMap.get('FlatCarNumber');
							//system.debug('shipment.flatCarId'+shipment.flatCarId);
							//system.debug('shipmentResponseMap.get(FlatCarNumber)'+shipmentResponseMap.get('flatCarNumber'));
							shipment.billofLadingNumber = (String) shipmentResponseMap.get('billOfLadingNumber');
							shipment.billofLadingDate = (String) shipmentResponseMap.get('billOfLadingDate');
							shipment.shipmentType = (String) shipmentResponseMap.get('shipmentType');
							List<Object> commoditiesDetails = (List<Object>) shipmentResponseMap.get('commodities');
							List<Object> equipmentsDetails = (List<Object>) shipmentResponseMap.get('equipments');
							List<Object> partiesDetails = (List<Object>) shipmentResponseMap.get('parties');
							List<Object> routeDetails = (List<Object>) shipmentResponseMap.get('routes');
							// List<Object> interlinesDetails = (List<Object>) shipmentResponseMap.get('interlines');
							Object interlinesDetails = shipmentResponseMap.get('interline');
							Object weightSummary = shipmentResponseMap.get('weightSummary');
							if (commoditiesDetails != null && !commoditiesDetails.isEmpty()) {
								Map<String, object> commoditiesMap = (Map<String, object>) commoditiesDetails[0];
								shipment.commodityNumber = (String) commoditiesMap.get('transportationStcc');
								shipment.stccDescription = (String) commoditiesMap.get('stccDescription');
								// adding to products
								CSX_CMP_NewClaimWrapper.Product shipmentResProduct = new CSX_CMP_NewClaimWrapper.Product();
								shipmentResProduct.description = (String) commoditiesMap.get('stccDescription');
								shipmentResProduct.uom = (String) commoditiesMap.get('packageType');
								shipmentResProduct.quantity = (Integer) commoditiesMap.get('packagesCount');
								shipment.products.add(shipmentResProduct);
								// shipment.quantity = (String) commoditiesMap.get('packageType');
								shipment.unitType = String.valueOf(commoditiesMap.get('packagesCount'));
							}
							if (equipmentsDetails != null && !equipmentsDetails.isEmpty()) {
								for (Object equipment : equipmentsDetails) {
									Map<String, object> equipmentsMap = (Map<String, object>) equipment;
									Map<String, Object> productMap = new Map<String, Object>();
									productMap = getProducts(equipmentsMap);
									shipment.vinNum = (List<String>) productMap.get('vinNumbers');
									shipment.products.addAll((List<CSX_CMP_NewClaimWrapper.Product>) productMap.get('shipmentResPrdList'));
									String equipmentId = (String) equipmentsMap.get('equipmentId');
									List<String> equipmentDetails = equipmentId != null ? equipmentId.split(' ') : new List<String>();
									shipment.equipmentInitial = (shipment.equipmentInitial == null ||
										shipment.equipmentInitial == '')
										? equipmentDetails[0].trim()
										: shipment.equipmentInitial;
									shipment.equipmentNumber = (shipment.equipmentNumber == null ||
										shipment.equipmentNumber == '')
										? equipmentDetails[equipmentDetails.size() - 1].trim()
										: shipment.equipmentNumber;
								}
							}
							//system.debug('equipment products'+shipment.products);
							if (partiesDetails != null && !partiesDetails.isEmpty()) {
								for (Object party : partiesDetails) {
									Map<String, object> partiesMap = (Map<String, object>) party;
									if (
										partiesMap.containsKey('partyRoleDescription') &&
										(partiesMap.get('partyRoleDescription') == 'Shipper' ||
										partiesMap.get('partyRoleDescription') == 'Consignee')
									) {
										if (partiesMap.get('partyRoleDescription') == 'Shipper') {
											shipment.shipperLegalEntityId = (String) partiesMap.get('locationNumber');
											shipment.shipperName = (String) partiesMap.get('name');
											shipment.shipperCityName = (String) partiesMap.get('preferredCity');
											shipment.shipperStateCode = (String) partiesMap.get('preferredState');
											shipment.shipperPostalCode = (String) partiesMap.get('preferredZipCode');
										} else if (partiesMap.get('partyRoleDescription') == 'Consignee') {
											shipment.consigneeLegalEntityId = (String) partiesMap.get('locationNumber');
											shipment.consigneeName = (String) partiesMap.get('name');
											shipment.consigneeCityName = (String) partiesMap.get('preferredCity');
											shipment.consigneeStateCode = (String) partiesMap.get('preferredState');
											shipment.consigneePostalCode = (String) partiesMap.get('preferredZipCode');
										}
									}
								}
							}

							if (routeDetails != null && !routeDetails.isEmpty()) {
								for (Object route : routeDetails) {
									CSX_CMP_NewClaimWrapper.Distribution distribution = getDistribution(route);
									if (distribution != null) {
										shipment.distributions.add(distribution);
									}
								}
							}
							//system.debug('shipment.distributions'+shipment.distributions);
							if (interlinesDetails != null) {
								// Confirm whether to use first one like we did for commodity or need to consider all
								// If we need to consider all then how to accomodate all as in wrapper we do not have list of interlines / date variables in wrapper
								Map<String, Object> interlineMap = (Map<String, Object>) interlinesDetails;
								shipment.isSettlementDate = interLineMap.get('isssDate') != null
									? (String) interLineMap.get('isssDate')
									: '';
								shipment.challengeDate = interLineMap.get('challengeDate') != null
									? (String) interLineMap.get('challengeDate')
									: '';
								shipment.adjustmentDate = interLineMap.get('adjustmentDate') != null
									? (String) interLineMap.get('adjustmentDate')
									: '';
								shipment.settlementAmount = interLineMap.get('issSettledAmount') != null
									? Decimal.valueOf((String) interLineMap.get('issSettledAmount'))
									: null;
								// shipment.settlementAmount = interLineMap.get('SettledAmount') != null
								// 	? Decimal.valueOf((String) interLineMap.get('SettledAmount'))
								// 	: null;
								//system.debug('shipment.settlementAmount'+shipment.settlementAmount);
								//system.debug('interLineMap.get(issSettledAmount)'+interLineMap.get('SettledAmount'));
								shipment.urrwinNumber = interLineMap.get('urrwinNumber') != null
									? (String) interLineMap.get('urrwinNumber')
									: '';
								shipment.urrwinDate = (interLineMap.get('urrwinDate') != null &&
									String.isNotBlank((String) interLineMap.get('urrwinDate')))
									? Date.valueOf((String) interLineMap.get('urrwinDate'))
									: null;
							}
							if (weightSummary != null) {
								Map<String, Object> weightSummaryMap = (Map<String, Object>) weightSummary;
								shipment.totalCars = weightSummaryMap.get('equipmentTotal') != null
									? String.valueOf((Integer) weightSummaryMap.get('equipmentTotal'))
									: '';
							}
							responseList.add(shipment);
						}
					}
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_SIMSInterface',
					'Fetch shipment Details',
					json.Serialize(shipmentReqWrap)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SIMSInterface', 'getShipmentDetails', '', ex);
			}
			return responseList;
		}

		private static Map<String, Object> getProducts(Map<String, Object> equipment) {
			Map<String, Object> productMap = new Map<String, Object>();
			List<CSX_CMP_NewClaimWrapper.Product> shipmentResPrdList = new List<CSX_CMP_NewClaimWrapper.Product>();
			List<Object> vins = (List<Object>) equipment.get('vins');
			List<String> vinNumbers = new List<String>();
			for (Object vinObj : vins) {
				Map<String, Object> vinMap = (Map<String, Object>) vinObj;
				CSX_CMP_NewClaimWrapper.Product shipmentResProduct = new CSX_CMP_NewClaimWrapper.Product();

				if (vinMap.containsKey('vinNumber')) {
					shipmentResProduct.equipmentId = (String) equipment.get('equipmentId');
					shipmentResProduct.vin = (String) vinMap.get('vinNumber');
					vinNumbers.add(shipmentResProduct.vin);
				}
				shipmentResPrdList.add(shipmentResProduct);
				//vinNumbers.add(shipmentResProduct.vin);
			}

			productMap.put('vinNumbers', vinNumbers);
			productMap.put('shipmentResPrdList', shipmentResPrdList);
			return productMap;
		}

		private static CSX_CMP_NewClaimWrapper.Distribution getDistribution(Object route) {
			Map<String, Object> routeMap = (Map<String, Object>) route;
			if(routeMap.get('roadType') != 'SW'){
				if (routeMap.get('routeScac') != null) {
					CSX_CMP_NewClaimWrapper.Distribution distribution = new CSX_CMP_NewClaimWrapper.Distribution();
					distribution.junctionCode = (String) routeMap.get('routeJunction');
					distribution.scac = (String) routeMap.get('routeScac');
					distribution.routeSequenceNumber = (Integer) routeMap.get('routeSequenceNumber');
					return distribution;
				} else {
					return null;
				}
			}else{
				return null;
			}
		}

		//method to fetch waybill Image from SIMS
		public static Blob getWaybillImage(String controlNumber, String equipment) {
			string endPointUrl;
			HttpResponse response;
			// String requestBody;
			Blob decodedBlob;
			String usageIndicator = 'S';
            String userId;
            User objUser = [SELECT Id, FederationIdentifier FROM User where id =: userinfo.getUserId()];

				if(objUser.FederationIdentifier != null){
					userId = objUser.FederationIdentifier.split('@')[0];
				}
                else{
                   userId = System.Label.CSX_CMP_Default_RACF_ID_to_fetch_Waybill_Image;
                 }
			Map<String, String> requestMap = new Map<String, String>();
			CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
				'SIMS_Waybill_Image'
			);
			endPointUrl =
				endpoint.CSX_CMP_End_Point__c +
				'?waybill-control-number=' +
				controlNumber +
				'&equipment=' +
				equipment +
				'&usage-indicator=' +
				usageIndicator +
				'&user-id=' +
				userId;
			//endPointUrl = 'https://apistaging.csx.com/simscore/v1/waybill/pdf?waybill-control-number=712014209939383240709&equipment=JBHU313008&usage-indicator=S&user-id=F1011';
			requestMap.put('Method', 'GET');
			requestMap.put('EndpointURL', endPointUrl);
			requestMap.put('Content-Type', 'application/json');
			//requestMap.put('Body', requestBody);
			response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
            logIntegrationTime('CSX_CMP_InterfaceUtility', 'Fetch waybill Image', controlNumber + ' ' + equipment);
			if (response.getStatusCode() == 200 && response.getBody() != null) {
				decodedBlob = response.getBodyAsBlob();
				//system.debug('decodedBlob'+decodedBlob);
			}
			return decodedBlob;
		}

		// Send Approval initiation request to BTP CMP-I-0459
		//@HttpPost
		public static ApprovalResponseWrapperBTP sendApprovalInitiationRequest(
			ApprovalInitationRequestWrapper approvalInitiationReqs
		) {
			Map<String, String> requestMap = new Map<String, String>();
			ApprovalResponseWrapperBTP responseWrapper = new ApprovalResponseWrapperBTP();
			HttpResponse response;
			try {
				String requestBody = JSON.serialize(approvalInitiationReqs);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('BTP');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 201) {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
					//system.debug('resultObject??' + resultObject);
					if (resultObject != null) {
						responseWrapper.caseNumber = String.valueOf(resultObject.get('claimId'));
						responseWrapper.integrationStatus = String.valueOf(resultObject.get('integrationStatus'));
					}
				} else {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
					//system.debug('resultObject??' + resultObject);
					responseWrapper.caseNumber = String.valueOf(resultObject.get('claimId'));
					responseWrapper.integrationStatus = String.valueOf(resultObject.get('integrationStatus'));
					responseWrapper.errorReason = String.valueOf(resultObject.get('errorReason'));
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						responseWrapper.errorReason,
						'BTP',
						responseWrapper.integrationStatus,
						responseWrapper.caseNumber
					);
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch BTP details',
					json.Serialize(approvalInitiationReqs)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'sendApprovalInitiationRequest',
					JSON.serialize(approvalInitiationReqs),
					ex
				);
			}
			return responseWrapper;
		}
		// Check Integration Status  CMP-I-0456
		//@HttpPost
		public static string checkIntegrationStatus(CSX_CMP_AR_Settlement__c oldARrecord) {
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			string integrationStatus;
			try {
				String requestBody = JSON.serialize(oldARrecord);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('BTP');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 201) {
					if (response.getBody() != '') {
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
						List<Object> compositeRequestList = new List<Object>();
						if (resultObject != null) {
							compositeRequestList = (List<Object>) resultObject.get('compositeRequest');
							Map<String, Object> compositeRequestMap = (Map<string, Object>) compositeRequestList[0];
							//string url = string.valueOf(inteObject.get('url'));
							integrationStatus = string.valueOf(compositeRequestMap.get('CSX_CMP_Integration_Status__c'));
						}
					}
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog('', 'Integration Status', '', '');
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Integration Status',
					json.Serialize(oldARrecord)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'checkIntegrationStatus',
					JSON.serialize(oldARrecord),
					ex
				);
			}
			return integrationStatus;
		}
		@AuraEnabled(cacheable=false)
		public static String fetchCancelInvoiceStatus(String invoiceNumber, String arSettlementName, String companyCode, String invoiceDate, String reversalReason, String requestType, String createdDate,String claimNumber,Id invoiceId) {
			String invStatus='';
			
			InvoiceCancellationResponseWrapper1 responseWrapper1= new InvoiceCancellationResponseWrapper1();
			try{
			Map<String, String> requestMap = new Map<String, String>();
			String updateRecordStatus;
			InvoiceWrapper invWrapperDetails= new InvoiceWrapper();
			invWrapperDetails.invoiceNumber=invoiceNumber;
			invWrapperDetails.invoiceStatus='Cancelled';
			invWrapperDetails.externalId=claimNumber+'_'+arSettlementName;
			invWrapperDetails.companyCode=companyCode;
			invWrapperDetails.invoiceDate=invoiceDate;
			invWrapperDetails.reversalReason=reversalReason;
			invWrapperDetails.requestType='Cancel';
			invWrapperDetails.createdDate=createdDate;
            system.debug('invWrapperDetails: '+invWrapperDetails);
			String requestBody = JSON.serialize(invWrapperDetails);
            system.debug('requestBody: '+requestBody);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
					'cancel_invoice'
				);
				HttpResponse response;
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
                System.debug('response: '+response);
                System.debug('response.getStatusCode(): '+response.getStatusCode());
				if (response.getStatusCode() == 200) {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
					if (response.getBody() != '') {
							if (resultObject != null) {
								responseWrapper1.invoiceNumber = String.valueOf(resultObject.get('invoiceNumber'));
								
								responseWrapper1.status = String.valueOf(resultObject.get('status'));
								
								responseWrapper1.externalId =String.valueOf(resultObject.get('externalId'));
								
								responseWrapper1.message = String.valueOf(resultObject.get('message'));
								
								if(responseWrapper1.status=='Success' && String.isNotBlank(invoiceId)){
									updateRecordStatus=CSX_CMP_InvoiceAdjustmentController.invoiceRecordUpdate(invoiceId,responseWrapper1.status,claimNumber);
									invStatus=responseWrapper1.message;
								}
								if(responseWrapper1.status=='Failed' && String.isNotBlank(invoiceId)){
									updateRecordStatus = CSX_CMP_InvoiceAdjustmentController.invoiceRecordUpdate(invoiceId,responseWrapper1.status,'claimNumberNotFound');
									invStatus=responseWrapper1.message;
									CSX_CMP_LoggerUtility.addIntegrationErrorLog(
									String.valueOf(response.getBody()),
									String.valueOf(response.getStatusCode()),
									invoiceId,
									response.getBody());
					
                                  
								}
                                system.debug('invoiceNumber :'+invoiceNumber);
								system.debug('responseWrapper1.message :'+responseWrapper1.message);
								system.debug('responseWrapper1.message :'+responseWrapper1);
							} else {
								responseWrapper1.status = 'Error';
								invStatus='Error';
							}	
						}
				}
				if (response.getStatusCode() == 400 || response.getStatusCode() == 401 || response.getStatusCode() == 402 || response.getStatusCode() == 403 || response.getStatusCode() == 404 || response.getStatusCode() == 500 ) {
					// Sample JSON string
						//String jsonString = '{ "traceId": "string", "error": { "code": 0, "message": "string", "target": "string" }, "details": [ { "code": 0, "message": "string", "target": "string" } ] }';
				
						String detailMessages = '';
                        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
						
                        Map<String, Object> errorObject = (Map<String, Object>) jsonMap.get('error');
                        String errorMessage = (String) errorObject.get('message');
					
							Object details = jsonMap.get('details'); // Changed to Object to inspect the type
								List<Object> detailsList = (List<Object>) details;
								if (!detailsList.isEmpty() ) {
									/*Map<String, Object> firstDetail = (Map<String, Object>) detailsList.get(0);
									System.debug('firstDetail: '+firstDetail);
									String detailMessage = (String) firstDetail.get('message');
									System.debug('Detail Message: ' + detailMessage + ' errorMessage: ' + errorMessage); */
									String detailMessage;
									for (Object detail : detailsList) {
											Map<String, Object> detailMap = (Map<String, Object>) detail;
										    detailMessage = (String) detailMap.get('message');
											detailMessages += detailMessage + ' ';	
									}
									invStatus = errorMessage + detailMessage;
								} else {
									invStatus = errorMessage;
								}
							
						}
			}          
			catch(exception ex){
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchCancelInvoiceStatus',
					JSON.serialize(invStatus),
					ex
				);
			}
			return invStatus;  
		}

		// Method Created to Fetch Freight bill Invoice detail from S4 Hana
		//@HttpPost
		public static List<FreightbillResponseWrapper> fetchFreightBillDetails(
			List<FreightbillRequestWrapper> inputRequestList
		) {
			Map<String, Object> requestSetMap = new Map<String, Object>();
			FreightbillSAPRequestWrapper freightBillRequestContent = new FreightbillSAPRequestWrapper();
			freightBillRequestContent.freightBillDetails = inputRequestList;
			requestSetMap.put('freightBillRequestSet', freightBillRequestContent);
			// System.debug('freightBillRequestContent::: '+freightBillRequestContent);
			list<FreightbillResponseWrapper> retrunWrapperlist = new List<FreightbillResponseWrapper>();
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;

			try {
				//String requestBody = JSON.serialize(requestSetMap);
				String requestBody = JSON.serialize(freightBillRequestContent);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
					'Freight Bill'
				);
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				// system.debug('requestMap::: '+requestMap);
				// system.debug('response::: '+response);

				if (response.getStatusCode() == 200) {
					List<Object> freightBillDetails = new List<Object>();
					if (response.getBody() != '') {
						//&& !response.getBody().contains('Please provide the proper systemName.')
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
						Map<String, Object> mainObject = ((Map<String, Object>) resultObject.get('freightBillResponseSet'));
						freightBillDetails.add(mainObject.get('freightBillResponse'));
						if (freightBillDetails.size() == 1) {
							freightBillDetails = ((List<Object>) mainObject.get('freightBillResponse'));
						} else {
							freightBillDetails = (List<Object>) mainObject.get('freightBillResponse');
						}
						for (Object freight : freightBillDetails) {
							Map<String, Object> freightDet = (Map<String, Object>) freight;
							FreightbillResponseWrapper responseWrapper = new FreightbillResponseWrapper();
							responseWrapper.billedAmount = Decimal.valueOf(String.valueOf(freightDet.get('billedAmount')));
							responseWrapper.amountRec = Decimal.valueOf(String.valueOf(freightDet.get('receivedAmount')));
							responseWrapper.balanceDue = Decimal.valueOf(String.valueOf(freightDet.get('balanceDue')));
							responseWrapper.waybillDate = Date.valueOf(String.valueOf(freightDet.get('waybillDate')));
							responseWrapper.wayBillControlNumber = String.valueOf(freightDet.get('waybillControlNumber'));
							responseWrapper.freightBillNumber = String.valueOf(freightDet.get('freightBillNumber'));
							retrunWrapperlist.add(responseWrapper);
						}
					}
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						String.valueOf(response.getStatusCode()),
						JSON.Serialize(inputRequestList),
						response.getBody()
					);
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Freight bill details',
					json.Serialize(inputRequestList)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchFreightBillDetails',
					String.valueOf(inputRequestList),
					ex
				);
				return null;
			}
			return retrunWrapperlist;
		}

		//Below method is used to fetch the AR Balance
		public static ARBalanceResponseWrapper fetchARBalanceDetails(Integer nationalAccountNum) {
			Map<String, String> requestMap = new Map<String, String>();

			ARBalanceResponseWrapper arBalanceWrapper = new ARBalanceResponseWrapper();
			HttpResponse response;
			//Integer companyCode;
			try {
				/*Case claim = [select Id, Type from Case where Id=:claimId];
				CSX_CMP_SAP_Accounting_Detail__c sapAccInfo= CSX_CMP_SAP_Accounting_Detail__c.getValues(claim.type+'_NA');*/
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('ARBalance');

				/*if(sapAccInfo!=null){
	companyCode= Integer.valueOf(sapAccInfo.CSX_CMP_AR_Company_Code__c);
	}else{
	}*/
				if (endpoint != null) {
					requestMap.put('Method', 'GET');
					requestMap.put(
						'EndpointURL',
						endpoint.CSX_CMP_End_Point__c +
						'?nationalAccountNumber=' +
						nationalAccountNum /*+ '&companyCode='+companyCode*/
					);
					response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
					if (response.getStatusCode() == 200) {
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
						//Map<String, Object> mainObject = ((Map<String, Object>) resultObject.get('ARBalanceDetailsSet'));
						//Map<String, Object> balancedetails = (Map<String, Object>) mainObject.get('ARBalanceDetails');

						//system.debug('resultObject: '+resultObject);
						if (resultObject != null) {
							arBalanceWrapper.totalOutstandingARBalance = Decimal.valueOf(
								(String.valueOf(resultObject.get('totalOutstandingAccountReceivableBalance'))).remove('USD').trim()
							);
							arBalanceWrapper.pastDueAR = Decimal.valueOf(
								(String.valueOf(resultObject.get('pastDueBalance'))).remove('USD').trim()
							);
							arBalanceWrapper.financeCharges = Decimal.valueOf(
								(String.valueOf(resultObject.get('financeCharges'))).remove('USD').trim()
							);
							arBalanceWrapper.pastDueDateARBalance15Days = Decimal.valueOf(
								(String.valueOf(resultObject.get('pastDue15DaysBalance'))).remove('USD').trim()
							);
							arBalanceWrapper.status = 'Success';
							//system.debug('arBalanceWrapper :'+arBalanceWrapper);
						} else {
							arBalanceWrapper.status = 'Error';
						}
					} else {
						CSX_CMP_LoggerUtility.addIntegrationErrorLog(
							String.valueOf(response.getBody()),
							String.valueOf(response.getStatusCode()),
							JSON.serialize(nationalAccountNum),
							''
						);
					}

					CSX_CMP_InterfaceUtility.logIntegrationTime(
						'CSX_CMP_InterfaceUtility',
						'Fetch AR Balance details',
						nationalAccountNum /*+'\n'+JSON.serialize(claim)*/
					);
				} else {
					CSX_CMP_LoggerUtility.addApexErrorLog(
						'CSX_CMP_InterfaceUtility',
						'fetchARBalanceDetails',
						'Endpoint custom setting not available',
						null
					);
				}
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchARBalanceDetails',
					String.valueOf(nationalAccountNum),
					e
				);
			}
			return arBalanceWrapper;
		}

		//Method to fetch RARS details from RARS API
		public static RARSResponseWrapper fetchRARSDetail(RARSRequestWrapper inputdata) {
			RARSResponseWrapper responsewrapper = new RARSResponseWrapper();
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			try {
				string incidentDate = inputdata.fromReportedDate;
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('RARS');
				requestMap.put('Method', 'GET');
				requestMap.put(
					'EndpointURL',
					endpoint.CSX_CMP_End_Point__c +
					'?incidentDate=' +
					inputdata.fromReportedDate +
					'&incidentState=' +
					inputdata.incidentState +
					'&equipmentId=' +
					inputdata.equipmentId
				);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 200) {
					if (response.getBody() != '') {
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
						if (resultObject != null) {
							responsewrapper.incidentDate = Date.valueOf(String.valueOf(resultObject.get('incidentTimestamp')));
							responsewrapper.rarNumber = (String) resultObject.get('incidentId');
							responsewrapper.status = 'Success';
						} else {
							responsewrapper.status = 'Error';
						}
					} else {
						responsewrapper.status = 'No Results Found';
					}
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						String.valueOf(response.getStatusCode()),
						JSON.serialize(inputdata),
						''
					);
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch RARS details',
					json.Serialize(inputdata)
				);
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchRARSDetail',
					JSON.serialize(inputdata),
					e
				);
				return null;
			}
			return responsewrapper;
		}

		//Method to fetch MTI details from MTI API
		public static MTIResponseWrapper fetchMTIDetail(MTIRequestWrapper inputdata) {
			HttpResponse response;
			Map<String, String> requestMap = new Map<String, String>();
			MTIResponseWrapper responsewrapper = new MTIResponseWrapper();
			try {
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('MTI');
				requestMap.put('Method', 'GET');
				requestMap.put(
					'EndpointURL',
					endpoint.CSX_CMP_End_Point__c +
					'?carInitial=' +
					inputdata.equipmentInitial +
					'&carNumber=' +
					inputdata.equipmentNumber +
					'&fromDate=' +
					inputdata.waybillDate
				);

				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 200) {
					if (response.getBody() != '') {
						//String jsonString = '[{"carInit": "CSXT","carNum": "291562","eventType": "BadOrder","eventDate": "2016-02-22 09:45:27.0","trainId": "Y19516","trackId": "B28","loadOrEmpty": "L","eventClass": "BOS","eventNotes": "CSX221;CSX220-bearing"},{"carInit": "CSXT","carNum": "291562","eventType": "BadOrder","eventDate": "2016-02-22 09:37:26.0","trainId": "Q11111","trackId": "B07","loadOrEmpty": "L","eventClass": "BOS","eventNotes": null}]';
						//String jsonString = '[{"carInit": "CSXT","carNum": "291562","eventType": "BadOrder","eventDate": "2016-02-22 09:45:27.0","trainId": "Y19516","trackId": "B28","loadOrEmpty": "L","eventClass": "BOS","eventNotes": "CSX221;CSX220-bearing"}]';
						List<Object> resultObject = (List<Object>) JSON.deserializeunTyped(response.getBody());
						if (resultObject != null) {
							//responsewrapper.incidentDate = '2023-02-07T00:00:00Z';
							//responsewrapper.trackId = '654321';
							//responsewrapper.multipleBadOrders = 'true';
							//resposnewrapper.badOrderNotes;

							Object json = System.JSON.deserializeUntyped(response.getBody());
							List<Object> dataList = (List<Object>) json;
							if (!dataList.isEmpty()) {
								/*if((String) ((Map<String, Object>) dataList.get(0)).get('eventClass') == 'ADJ'){
									responsewrapper.multipleBadOrders = 'false';
									responsewrapper.incidentDate = (String) ((Map<String, Object>) dataList.get(0)).get('eventDate');
									responsewrapper.trackId = (String) ((Map<String, Object>) dataList.get(0)).get('trackId');
									//responsewrapper.multipleBadOrders = 'false';
									responsewrapper.badOrderNotes = (String) ((Map<String, Object>) dataList.get(0)).get('eventNotes');
									responsewrapper.status = 'Success';
									if (dataList.size() > 1) {
										responsewrapper.multipleBadOrders = 'true';
									}
								}else{
									responsewrapper.status = 'Success';
								}*/
								Boolean adjEventFound = false;
								for (Object data : dataList) {
									Map<String, Object> dataMap = (Map<String, Object>) data;
									if ((String) dataMap.get('eventClass') == 'ADJ' ) {
										responsewrapper.multipleBadOrders = 'false';
										responsewrapper.incidentDate = (String) dataMap.get('eventDate');
										responsewrapper.trackId = (String) dataMap.get('trackId');
										responsewrapper.badOrderNotes = (String) dataMap.get('eventNotes');
										responsewrapper.status = 'Success';
										adjEventFound = true;
										break;
									}
								}
								if (dataList.size() > 1) {
									responsewrapper.multipleBadOrders = 'true';
								}
								if (!adjEventFound) {
									responsewrapper.status = 'Success';
								}
							}
						}
					}
				} else {
					responsewrapper.status = 'Error';
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch MTI details',
					json.Serialize(inputdata)
				);
				return responsewrapper;
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InterfaceUtility', 'fetchMTIDetail', JSON.serialize(inputdata), e);
				return null;
			}
		}

		//Method to fetch case summary details from Salesforce Service App
		@AuraEnabled(cacheable=false)
		public static List<CaseSummaryResponseWrapper> fetchCaseSummary(string equipmentId) {
			List<CaseSummaryResponseWrapper> caseSummaryResponseWrapperList = new List<CaseSummaryResponseWrapper>();
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			try {
				Map<String, String> equipIdMap = new Map<String, String>();
				equipIdMap.put('equipmentNumber', equipmentId.replaceAll('\\s+', ''));
				String jsonCaseNumber = JSON.serialize(equipIdMap);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
					'Case Summary'
				);
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', jsonCaseNumber);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				//string jsonString = '{"errorObject": {"message": "SUCCESS","code": "200"},"CaseCarSummaryList": [{"status": "Open","equipmentNumber": "CSXT130004","createdDate": "2020-11-02T11:51:43.000Z","contactIdName": "William Olson","caseNumber": "00001045","callerCompanyName": "INTERNATIONAL PAPER CO"},{"status": "New","equipmentNumber": "CSXT130004","createdDate": "2020-12-02T12:16:57.000Z","contactIdName": "William Olson","caseNumber": "00330131","callerCompanyName": "INTERNATIONAL PAPER CO | AL AUTAUGA CREEK"}]}';
				//Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(jsonString);
				Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());

				if (resultObject != null) {
					Map<String, Object> errorObjectMap = (Map<String, Object>) resultObject.get('errorObject');
					if (errorObjectMap != null) {
						if (string.valueOf(errorObjectMap.get('code')) == '200') {
							if (resultObject.get('CaseCarSummaryList') != null) {
								List<Object> caseSummaryList = (List<Object>) resultObject.get('CaseCarSummaryList');
								String baseUrl = system.URL.getOrgDomainUrl().toExternalForm();
								if (!caseSummaryList.isEmpty()) {
									for (Object caseSummaryObj : caseSummaryList) {
										Map<String, Object> summaryMap = (Map<String, Object>) caseSummaryObj;
										CaseSummaryResponseWrapper caseSummResponse = new CaseSummaryResponseWrapper();
										caseSummResponse.caseNumber = (string) summaryMap.get('caseNumber');
										caseSummResponse.status = (string) summaryMap.get('status');
										caseSummResponse.caseDate = (string) summaryMap.get('createdDate');
										caseSummResponse.createdBy = (string) summaryMap.get('contactIdName');
										caseSummResponse.companyName = (string) summaryMap.get('callerCompanyName');
										caseSummResponse.caseAvailable = true;
										caseSummResponse.caseUrl =
											baseUrl +
											'/lightning/n/CSX_CMP_Case_Full_Details?c__caseRecordId=' +
											(string) summaryMap.get('caseNumber');
										caseSummaryResponseWrapperList.add(caseSummResponse);
									}
								}
							}
						} else {
							CSX_CMP_LoggerUtility.addIntegrationErrorLog(
								response.getBody(),
								'CSX_CMP_InterfaceUtility',
								'Fetch summary details',
								JSON.serialize(equipIdMap)
							);
						}
					}
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch summary details',
					json.Serialize(equipIdMap)
				);
				return caseSummaryResponseWrapperList;
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InterfaceUtility', 'fetchCaseSummary', equipmentId, e);
				return null;
			}
		}

		//Method to fetch case full details from Salesforce Service App
		@AuraEnabled
		public static CaseDetailResponseWrapper fetchCaseDetail(string caseNumber) {
			CaseDetailResponseWrapper responseWrapper = new CaseDetailResponseWrapper();
			HttpResponse response;
			Map<String, String> requestMap = new Map<String, String>();

			try {
				Map<String, String> caseNumberMap = new Map<String, String>();
				caseNumberMap.put('caseNumber', caseNumber);
				String jsonCaseNumber = JSON.serialize(caseNumberMap);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('Case Detail');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', jsonCaseNumber);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				//string jsonString = '{"errorObject": {"message": "SUCCESS","code": "200"},"CaseCarDetailObject": {"status": "CSX Responded","shipCsxUserId": null,"RelatedResponsesList": [{"type": "SPR","responseByName": null,"createdDate": "2020-12-03T12:56:05.000Z","comment": "adding a new response to this case"}],"RelatedCaseCommentsList": [{"creatorName": "William Olson","createdDate": "2020-12-08T11:51:13.000Z","commentBody": "Adding Comments Here Its a Disaster Empty Car,Event: PullCutoff: 2020-06-18T12:29:05.050ZKey: SHA  01108 Sub Event: Pull from Station Track 49From Track Spot: 2020-06-15T11:11:11.050ZTo Track Spot: 2020-06-18T12:29:05.050ZCurrent Location: INTERNATIONAL PAPER CO AL AUTAUGA CREEK(SHA  01108)STCC: 4211299Car Remarks: Add my Car Remarks here"}],"reason": "E-Business Set Up","onBehalfOfName": null,"equipmentList": "CSXT130004","description": "adding a note to this case","customerRole": "Shipper","contactPhone": "904-633-4891","contactIdName": "William Olson","contactEmail": "william_olson@csx.com.invalid","caseNumber": "00330135","callerCompanyName": "INTERNATIONAL PAPER CO"}}';
				//system.debug('Response Body ::'+response.getBody());
				if (string.isNotBlank(response.getBody())) {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());

					//Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(jsonString);
					if (resultObject != null) {
						Map<String, Object> errorObjectMap = (Map<String, Object>) resultObject.get('errorObject');
						if (errorObjectMap != null) {
							if ((string) errorObjectMap.get('code') == '200') {
								if (resultObject.get('CaseCarDetailObject') != null) {
									Map<String, Object> caseDetailMap = (Map<String, Object>) resultObject.get('CaseCarDetailObject');
									responseWrapper.status = (string) caseDetailMap.get('status');
									responseWrapper.shipCSXUserId = (string) caseDetailMap.get('shipCsxUserId');
									responseWrapper.caseReason = (string) caseDetailMap.get('reason');
									responseWrapper.onBehalfOf = (string) caseDetailMap.get('onBehalfOfName');
									responseWrapper.caseDescription = (string) caseDetailMap.get('description');
									responseWrapper.equipmentId = (string) caseDetailMap.get('equipmentList');
									responseWrapper.role = (string) caseDetailMap.get('customerRole');
									responseWrapper.contactPhone = (string) caseDetailMap.get('contactPhone');
									responseWrapper.customerEmail = (string) caseDetailMap.get('contactEmail');
									responseWrapper.createdBy = (string) caseDetailMap.get('contactIdName');
									responseWrapper.companyName = (string) caseDetailMap.get('callerCompanyName');
									responseWrapper.caseNumber = caseNumber; //(string)caseDetailMap.get('caseNumber');
									List<Object> caseResponseDetailList = (List<Object>) caseDetailMap.get('RelatedResponsesList');
									if (!caseResponseDetailList.isEmpty()) {
										for (Object caseDetailObj : caseResponseDetailList) {
											Map<String, Object> summaryDetailMap = (Map<String, Object>) caseDetailObj;
											CaseResponse objRes = new CaseResponse();
											objRes.createdDate = (string) summaryDetailMap.get('createdDate');
											objRes.responseBy = (string) summaryDetailMap.get('responseByName');
											if ((string) summaryDetailMap.get('type') == 'SPR') {
												objRes.responseType = 'External';
											} else {
												objRes.responseType = 'Internal';
											}
											objRes.response = (string) summaryDetailMap.get('comment');
											responseWrapper.caseResponses.add(objRes);
										}
									}

									List<Object> caseCommentDetailList = (List<Object>) caseDetailMap.get('RelatedCaseCommentsList');
									if (!caseCommentDetailList.isEmpty()) {
										for (Object caseCommentObj : caseCommentDetailList) {
											Map<String, Object> summaryCommentMap = (Map<String, Object>) caseCommentObj;
											CaseComment objCaseComment = new CaseComment();
											objCaseComment.commentCreatedDate = (string) summaryCommentMap.get('createdDate');
											objCaseComment.commentBy = (string) summaryCommentMap.get('creatorName');
											string commentBody = string.valueOf(summaryCommentMap.get('commentBody'));
											objCaseComment.caseCommentInternal = commentBody.replace('\n', ' ');
											responseWrapper.caseComments.add(objCaseComment);
										}
									}
								}
							} else {
								CSX_CMP_LoggerUtility.addIntegrationErrorLog(
									response.getBody(),
									'CSX_CMP_InterfaceUtility',
									'Fetch Case details',
									JSON.serialize(caseNumberMap)
								);
							}
						}
					}
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Case details',
					json.Serialize(caseNumberMap)
				);
				return responseWrapper;
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InterfaceUtility', 'fetchCaseDetail', caseNumber, e);
				return null;
			}
		}

		//Method to fetch Umler details
		public static Map<String, List<UmlerResponseWrapper>> fetchUmlerdetails(List<string> equipmentIds) {
			Map<String, String> requestMap = new Map<String, String>();
			List<UmlerResponseWrapper> responsewrapperlist = new List<UmlerResponseWrapper>();
			Map<String, List<UmlerResponseWrapper>> responseMap = new Map<String, List<UmlerResponseWrapper>>();
			Map<String, Map<String, String>> carMap = new Map<String, Map<String, String>>();
			HttpResponse response;
			try {
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('UMLER');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', CSX_CMP_UmlerRequest.umlerInput(equipmentIds));

				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 200) {
					if (response.getBody() != null) {
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
						if (resultObject != null) {
							Map<String, Object> mainObject = ((Map<String, Object>) resultObject.get('getUMLERDataResponse'));
							Map<String, Object> carDetailsList = (Map<String, Object>) mainObject.get('carDetailsList');
							List<Object> carDetails = (List<Object>) carDetailsList.get('carDetails');
							for (Object carDetail : carDetails) {
								Map<String, Object> carDetailMap = (Map<String, Object>) carDetail;
								String carID = String.valueOf(carDetailMap.get('carID')).deleteWhitespace();
								Map<String, String> elementMap = new Map<String, String>();
								List<Object> elements = (List<Object>) carDetailMap.get('element');
								for (Object element : elements) {
									Map<String, Object> elementMapData = (Map<String, Object>) element;
									String elementID = string.valueOf(elementMapData.get('elementID'));
									Map<String, Object> elementDetails = (Map<String, Object>) elementMapData.get('elementDetails');
									String value = (String) elementDetails.get('value');
									elementMap.put(elementID, value);
								}
								carMap.put(carID, elementMap);
							}
						}
					}
				} else {
					responseMap.put('Error', new List<UmlerResponseWrapper>());
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						'Fetch Umler Details',
						JSON.Serialize(requestMap.get('Body')),
						JSON.serialize(equipmentIds)
					);
				}

				if (!carMap.isEmpty()) {
					for (String equipmentId : carMap.keySet()) {
						Map<String, String> equipmentMap = carMap.get(equipmentId);

						if (equipmentMap.get('9008').substring(0, 4) != 'NTFD') {
							UmlerResponseWrapper umlerresponse = new UmlerResponseWrapper();
							umlerresponse.carId = equipmentId;
							umlerresponse.aaaCarType = (equipmentMap.get('UMET') != null &&
								equipmentMap.get('UMET') != 'NULL')
								? equipmentMap.get('UMET')
								: '';
							umlerresponse.equipmentGroup = (equipmentMap.get('0002') != null &&
								equipmentMap.get('0002') != 'NULL')
								? equipmentMap.get('0002')
								: '';
							umlerresponse.actualOwner = (equipmentMap.get('UMOW') != null &&
								equipmentMap.get('UMOW') != 'NULL')
								? equipmentMap.get('UMOW')
								: '';
							if (
								string.isNotBlank(equipmentMap.get('A135')) &&
								equipmentMap.get('A135') != 'NULL' &&
								equipmentMap.get('A135') != null
							) {
								string insideLengthValue = equipmentMap.get('A135').trim();
								Integer inches = Integer.valueOf(insideLengthValue);
								Integer inchToFeet = inches / 12;
								Integer inchValue = (inches - 12 * Integer.valueOf(inchToFeet));
								string feetInch = String.valueOf(inchToFeet) + 'ft ' + string.valueOf(inchValue) + 'in';
								umlerresponse.insideLength = feetInch;
							} else {
								umlerresponse.insideLength = '';
							}

							//umlerresponse.insideLength = equipmentMap.get('A135') != null ? equipmentMap.get('A135') : '';
							if (
								string.isNotBlank(equipmentMap.get('A138')) &&
								equipmentMap.get('A138') != 'NULL' &&
								equipmentMap.get('A138') != null
							) {
								string insideWidthValue = equipmentMap.get('A138').trim();
								Integer inches = Integer.valueOf(insideWidthValue);
								Integer inchToFeet = inches / 12;
								Integer inchValue = (inches - 12 * Integer.valueOf(inchToFeet));
								string feetInch = String.valueOf(inchToFeet) + 'ft ' + string.valueOf(inchValue) + 'in';
								umlerresponse.insideWidth = feetInch;
							} else {
								umlerresponse.insideWidth = '';
							}
							//umlerresponse.insideWidth = equipmentMap.get('A138') != null ? equipmentMap.get('A138') : '';
							umlerresponse.lessee = (equipmentMap.get('LESE') != null &&
								equipmentMap.get('LESE') != 'NULL')
								? equipmentMap.get('LESE')
								: '';

							if (
								string.isNotBlank(equipmentMap.get('OSLG')) &&
								equipmentMap.get('OSLG') != 'NULL' &&
								equipmentMap.get('OSLG') != null
							) {
								string insideLengthValue = equipmentMap.get('OSLG').trim();
								Integer inches = Integer.valueOf(insideLengthValue);
								Integer inchToFeet = inches / 12;
								Integer inchValue = (inches - 12 * Integer.valueOf(inchToFeet));
								string feetInch = String.valueOf(inchToFeet) + 'ft ' + string.valueOf(inchValue) + 'in';
								umlerresponse.outerLength = feetInch;
							} else {
								umlerresponse.outerLength = '';
							}
							umlerresponse.originalInitial = (equipmentMap.get('9008') != null &&
								equipmentMap.get('9008') != 'NULL')
								? equipmentMap.get('9008')
								: '';
							if (equipmentId.substring(4).length() < 6) {
								umlerresponse.equipmentNumber = equipmentId.substring(4).leftpad(6, '0');
								umlerresponse.equipmentNumber = (equipmentId.replaceFirst('(.{0,4})(.*)', umlerresponse.originalInitial) +
									umlerresponse.equipmentNumber)
									.deleteWhitespace();
							} else {
								umlerresponse.equipmentNumber = (equipmentId.replaceFirst('(.{0,4})(.*)', umlerresponse.originalInitial) +
									equipmentId.substring(4))
									.deleteWhitespace();
							}
							//umlerList.add(umlerresponse);
							responsewrapperlist.add(umlerresponse);
						}
					}
					responseMap.put('Success', responsewrapperlist);
					//system.debug('Umler response ::'+responseMap);
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Umler details',
					json.Serialize(equipmentIds)
				);
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchUmlerdetails',
					JSON.serialize(equipmentIds),
					e
				);
				return null;
			}
			// return responsewrapperlist;
			return responseMap;
		}

		public static void sendClaimStatusUpdateToCustomerService(Map<String, String> claimDetails) {
			try {
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
					'Customer Service Status Update'
				);
				Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', JSON.serialize(claimDetails));
				CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				// if (response.getStatusCode() == 200) {
				// 	//system.debug('Success' + response.getBody());
				// } else {
				// 	CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				// 		'CSX_CMP_InterfaceUtility',
				// 		'sendClaimStatusUpdateToCustomerService',
				// 		JSON.serialize(claimDetails),
				// 		response.getBody()
				// 	);
				// }
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Send Claim Status Update to Customer Service',
					json.Serialize(claimDetails)
				);
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'sendClaimStatusUpdateToCustomerService',
					JSON.serialize(claimDetails),
					e
				);
			}
		}

		//Method to fetch the docId and docName from ECM
		public static ECMResponseWrapper fetchECMDocumentIds(string input) {
			ECMResponseWrapper responsewrapper = new ECMResponseWrapper();
			return responsewrapper;
		}
		//new method
		public static ECMResponseWrapper uploadDocToECM(ECMRequestWrapper reqWrapper) {
			ECMResponseWrapper responsewrapper = new ECMResponseWrapper();
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			Blob propertyBlob;
			Blob bodyBlob;
			CSX_CMP_External_Interface_Endpoint__c endpoint;
			try {
				String fileProperties = CSX_CMP_ECMUploadRequest.generateECMRequest(reqWrapper);
				String filebody = reqWrapper.content;
				propertyBlob = CSX_CMP_HttpFormBuilder.writeBodyParameter('fileProperties', fileProperties);
				bodyBlob = CSX_CMP_HttpFormBuilder.writeBodyParameter('file', filebody);
				String combinedDataAsHex = EncodingUtil.convertToHex(bodyBlob) + EncodingUtil.convertToHex(propertyBlob);
				Blob finalBlob = EncodingUtil.convertFromHex(combinedDataAsHex);
				if (reqWrapper.dDocType == 'FREIGHT_CLAIMS') {
					endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('ECM_Upload_Freight');
				} else {
					endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('ECM_Upload_Revenue');
				}

				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', CSX_CMP_HttpFormBuilder.getContentType());
				response = CSX_CMP_HTTPUtility.getHttpResponseforECM(requestMap, finalBlob);

				if (response.getStatusCode() == 200) {
					if (response.getBody() != '') {
						Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());

						if (resultObject != null) {
							responsewrapper.documentId = String.valueOf(resultObject.get('id'));

							responsewrapper.caseNumToDocIdMap.put(reqWrapper.xEventNumber, String.valueOf(resultObject.get('id')));
							//responsewrapper.documentName = String.valueOf(resultObject.get('documentName'));
						}
					}
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						'Upload Document to ECM',
						JSON.Serialize(reqWrapper),
						''
					);
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'ECM Upload details',
					json.Serialize(reqWrapper)
				);
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InterfaceUtility', 'uploadFilestoECM', null, e);
			}
			return responsewrapper;
		}

		//Method to update Files/Emails in ECM
		public static ECMResponseWrapper updateDocInECM(ECMRequestWrapper reqWrapper) {
			ECMResponseWrapper responsewrapper = new ECMResponseWrapper();
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			String body = '';
			String checkoutEndpoint;
			CSX_CMP_External_Interface_Endpoint__c endpoint;
			try {
				if (reqWrapper.dDocType == 'FREIGHT_CLAIMS') {
					endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('ECM_Upload_Freight');
				} else {
					endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('ECM_Upload_Revenue');
				}
				String boundary = '----------------------------741e90d31eff';
				String fileProperties = '';
				fileProperties += '--' + boundary + '\r\n';
				fileProperties += 'Content-Disposition: form-data; name="metadata"\r\n\r\n';
				fileProperties += '[{"name":"checkout" ,"value":"true"}]\r\n';
				fileProperties += '--' + boundary + '\r\n';

				checkoutEndpoint = endpoint.CSX_CMP_End_Point__c + '/' + reqWrapper.dDocName;
				requestMap.put('Method', 'PATCH');
				requestMap.put('EndpointURL', checkoutEndpoint);
				requestMap.put('Content-Type', CSX_CMP_HttpFormBuilder.getContentType());
				//String fileProperties = '';
				//fileProperties += CSX_CMP_HttpFormBuilder.writeBodyParameter('metadata','{"name":"checkout","value": "true"}');

				//String fileProperties = 'name:metadata,value:[{"name":"checkout","value": "true"}]';
				requestMap.put('Body', fileProperties);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);

				if (response.getStatusCode() == 200) {
					responsewrapper = uploadDocToECM(reqWrapper); //calling above method to repeat same process
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						'Upload Document In ECM',
						JSON.Serialize(reqWrapper),
						''
					);
				}
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'uploadFilesInECM',
					json.Serialize(EncodingUtil.base64Decode(body)),
					e
				);
			}
			return responsewrapper;
		}

		//fetch Mileage
		public static MileageResWrapper fetchMileage(MileageReqWrapper mileageWrap) {
			MileageResWrapper mileageResWrap = new MileageResWrapper();
			Map<String, String> requestMap = new Map<String, String>();
			Map<String, String> rrcodeToMile = new Map<String, String>();
			HttpResponse response;
			try {
				String requestBody = JSON.serialize(mileageWrap);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('Mileage');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);

				if (response.getStatusCode() == 200) {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(response.getBody());
					//string jsonString = '{"application":"SHIPCSX","mileageRoutes":[{"destination":{"city":"LAREDO","state":"TX","stationType":"OPSL"},"origin":{"city":"MIAMI","state":"FL","stationType":"OPSL"},"routeType":"FULL_ROUTE","mileage":1688,"segments":[{"junctionCode":"JACVL","roadCode":"FEC ","mileage":349},{"junctionCode":"NEWOR","roadCode":"CSXT","mileage":616},{"roadCode":"UP  ","mileage":723}]}]}';
					//Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeunTyped(jsonString);
					if (resultObject != null) {
						List<Object> mileageRoutes = (List<Object>) resultObject.get('mileageRoutes');
						if (!mileageRoutes.isEmpty()) {
							for (Object mileRoute : mileageRoutes) {
								Map<String, Object> routeObject = (Map<String, Object>) mileRoute;
								string totalMileage = string.valueOf(routeObject.get('mileage'));

								mileageResWrap.totalMiles = totalMileage;
								List<Object> segmentList = (List<Object>) routeObject.get('segments');
								if (!segmentList.isEmpty()) {
									for (Object segmentObj : segmentList) {
										Map<String, Object> segMap = (Map<String, Object>) segmentObj;
										String junctionCode = '';
										if (segMap.containsKey('junctionCode')) {
											junctionCode = (String) segMap.get('junctionCode');
										}
										String roadCode = (String) segMap.get('roadCode');
										Decimal mileage = (Decimal) segMap.get('mileage');
										string mileageKey = roadCode.trim() + '_' + junctionCode.trim();
										rrcodeToMile.put(mileageKey, String.valueOf(mileage));
										mileageResWrap.segmentMileageMap = rrcodeToMile;
										mileageResWrap.status = response.getStatus(); //'Success';
									}
								}
							}
						} else {
							mileageResWrap.status = system.label.CSX_CMP_Results_not_found;
						}
					}
				} else {
					mileageResWrap.status = response.getStatus(); //'Internal server error';
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						'Fetch Mileage',
						JSON.serialize(mileageWrap),
						''
					);
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Mileage',
					json.Serialize(mileageWrap)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchMileage',
					String.valueOf(mileageWrap),
					ex
				);
			}

			//return rrcodeToMile;
			return mileageResWrap;
		}

		//fetch total Miles
		public static MileageResWrapper fetchTotalMiles(List<TotalMilesReqWrapper> totalMilesReqWrap) {
			MileageResWrapper mileageResWrap = new MileageResWrapper();
			Map<String, String> requestMap = new Map<String, String>();
			string totalMiles;
			HttpResponse response;
			try {
				String requestBody = JSON.serialize(totalMilesReqWrap);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('Total Miles');
				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);
				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);

				if (response.getStatusCode() == 200) {
					//if(response.getBody() != null){
					List<Object> routesInfoList = (List<Object>) JSON.deserializeunTyped(response.getBody());
					//String jsonString = '[{"destination":{"city":"TAMPA","state":"FL"},"mileage":"510","origin":{"city":"JACKSONVILLE","state":"FL"},"route":"CSXT "}]';
					//List<Object> routesInfoList = (List<Object>)JSON.deserializeunTyped(jsonString);

					if (!routesInfoList.isEmpty() && routesInfoList != null && routesInfoList.size() > 0) {
						for (Object objRes : routesInfoList) {
							Map<string, Object> routeInfoMap = (Map<string, Object>) objRes;
							mileageResWrap.totalMiles = string.valueOf(routeInfoMap.get('mileage'));
							mileageResWrap.status = response.getStatus(); //'Success';
						}
						// }
					}
				} else {
					mileageResWrap.status = response.getStatus(); //'Error';
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						'Fetch Total Mileage',
						JSON.serialize(totalMilesReqWrap),
						''
					);
				}
				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Total Miles',
					json.Serialize(totalMilesReqWrap)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'fetchtotalMiles',
					JSON.serialize(totalMilesReqWrap),
					ex
				);
			}

			return mileageResWrap;
		}

		//This method is used to send the claim line amount for each freight bill to SAP
		public static SAPResponseWrapper sendClaimLineToSAP(SAPRequestWrapper requestWrapper) {
			Map<String, String> requestMap = new Map<String, String>();
			SAPResponseWrapper responseWrapper = new SAPResponseWrapper();
			HttpResponse response;

			try {
				String requestBody = JSON.serialize(requestWrapper);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues(
					'Claim Line Endpoint'
				);

				requestMap.put('Method', 'POST');
				requestMap.put('EndpointURL', endpoint.CSX_CMP_End_Point__c);
				requestMap.put('Content-Type', 'application/json');
				requestMap.put('Body', requestBody);

				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);

				/*if (response.getStatusCode() == 201) {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
					if (resultObject != null) {
					responseWrapper.freightBillNumber = Integer.valueOf(resultObject.get(freightBillNumber));
					responseWrapper.claimLinePaymentAmount = Integer.valueOf(resultObject.get(claimLinePaymentAmount));
					responseWrapper.supplierNumber = Integer.valueOf(resultObject.get(supplierNumber));
					responseWrapper.salesforceAutoNumberClaimNumber = String.valueOf(resultObject.get('salesforceAutoNumberClaimNumber'));
					responseWrapper.paymentInvoiceNumber = Integer.valueOf(resultObject.get(paymentInvoiceNumber));
					responseWrapper.status = String.valueOf(resultObject.get('status'));
					}
					} else {
					Map<String, Object> resultObject = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
					responseWrapper.freightBillNumber = Integer.valueOf(resultObject.get(freightBillNumber));
					responseWrapper.claimLinePaymentAmount = Integer.valueOf(resultObject.get(claimLinePaymentAmount));
					responseWrapper.supplierNumber = Integer.valueOf(resultObject.get(supplierNumber));
					responseWrapper.salesforceAutoNumberClaimNumber = String.valueOf(resultObject.get('salesforceAutoNumberClaimNumber'));
					responseWrapper.paymentInvoiceNumber = Integer.valueOf(resultObject.get(paymentInvoiceNumber));
					responseWrapper.status = String.valueOf(resultObject.get('status'));

					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					responseWrapper.status,
					'Claim Line Endpoint',
					'Integration failed with status code: ' + response.getStatusCode(),
					null 
					);
					}*/

				CSX_CMP_InterfaceUtility.logIntegrationTime(
					'CSX_CMP_InterfaceUtility',
					'Fetch Claim Line Endpoint details',
					JSON.serialize(requestWrapper)
				);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_InterfaceUtility',
					'sendClaimLineToSAP',
					JSON.serialize(requestWrapper),
					ex
				);
			}
			return responseWrapper;
		}

		//This method is used to get invoice PDF to SAP
		public static Blob fetchinvoicePDFFromSAP(String arInvoiceNumber) {
			Map<String, String> requestMap = new Map<String, String>();
			HttpResponse response;
			string endPointUrl;
			Blob pdfContent;
            
			try {
				// String requestBody = JSON.serialize(arInvoiceNumber);
				CSX_CMP_External_Interface_Endpoint__c endpoint = CSX_CMP_External_Interface_Endpoint__c.getValues('Invoice PDF');
				endPointUrl = endpoint.CSX_CMP_End_Point__c + arInvoiceNumber + '?invoiceType=CLAIM';
				//endPointUrl = endpoint.CSX_CMP_End_Point__c + arInvoiceNumber + '?invoiceType=GOV';
				//endPointUrl = 'https://integration-dev-zs11iare.it-cpi013-rt.cfapps.us21.hana.ondemand.com/http/v1/freight-invoices/0090000064?invoiceType=GOV';
				requestMap.put('Method', 'GET');
				requestMap.put('EndpointURL', endPointUrl);
				requestMap.put('Content-Type', 'application/json');
				//requestMap.put('Body', requestBody);

				response = CSX_CMP_HTTPUtility.getHttpResponse(requestMap);
				if (response.getStatusCode() == 200 && response.getBody() != null) {
					//string jsonString = response.getBody().toString();
					Map<String, Object> invoicePDFContentMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
					String pdfContentBase64 = (String) invoicePDFContentMap.get('pdfContent');
					pdfContent = EncodingUtil.base64Decode(pdfContentBase64);
				} else {
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						String.valueOf(response.getBody()),
						String.valueOf(response.getStatusCode()),
						arInvoiceNumber,
						response.getBody()
					);
				}

				CSX_CMP_InterfaceUtility.logIntegrationTime('CSX_CMP_InterfaceUtility', 'Fetch Invoice PDF', arInvoiceNumber);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InterfaceUtility', 'fetchinvoicePDFFromSAP', arInvoiceNumber, ex);
			}
			return pdfContent;
		}

		public static void logIntegrationTime(String className, String integrationName, Object parameters) {
			Double responseTimeLong = DateTime.now().getTime();
			Datetime responseTime = DateTime.now();
			CSX_CMP_LoggerUtility.IntegrationTimeLogWrapper integrationTimeLog = new CSX_CMP_LoggerUtility.IntegrationTimeLogWrapper();
			integrationTimeLog.className = className;
			integrationTimeLog.integrationName = integrationName;
			integrationTimeLog.responseTime = responseTime;
			integrationTimeLog.responseTimeLong = responseTimeLong;
			integrationTimeLog.parameters = json.Serialize(parameters);
			CSX_CMP_LoggerUtility.addIntegrationTimeLog(integrationTimeLog);
		}

		public class ECMRequestWrapper {
			public string dDocTitle; //File Name.extention dynamic
			public string dDocType; //"FREIGHT_CLAIMS" for freight and "RevenueClaims" for revenue dynamic
			public string dDocAuthor; //ShipCSX claims integration user
			public string dSecurityGroup; //"Secure" static
			public string dDocAccount; //"020705" for freight claim ,"03080499" for revenue claim
			public string xEventNumber; //Claim #
			public string xIronMtnBoxNum; //VIN #
			public string xCarNumber; //Car Number
			public string content; //Document Content
			public string xCarInitial; //Car Initial
			public string xRMProfileTrigger; //"FreightClaims" for freight ,"RevenueClaims" for revenue
			public string xCategoryID; //Retention Category
			public string revLabel; //1
			public string dId; //documentId
			public string xGroupFour; //railinc class 1 rairoads
			public string xCmisAttachment; //service period
			public string xInvolvedPartyName; //L&D report
			public string filePath; //File Name.extention dynamic
			public string dDocName; // It will store ECM doc Id
			public string xInitial; //Internal Only
			public string xComments; //Comments
			public string xEventDate; //Waybill date
		}

		public class ECMResponseWrapper {
			public string documentId;
			public string documentName;
			public Map<String, String> caseNumToDocIdMap;
			ECMResponseWrapper() {
				caseNumToDocIdMap = new Map<String, String>();
			}
		}

		public class CaseSummaryResponseWrapper {
			@AuraEnabled
			public string caseId;
			@AuraEnabled
			public string caseNumber;
			@AuraEnabled
			public string status;
			@AuraEnabled
			public string caseDate;
			@AuraEnabled
			public string createdBy;
			@AuraEnabled
			public string companyName;
			@AuraEnabled
			public Boolean caseAvailable;
			@AuraEnabled
			public string caseUrl;
		}

		public class CaseDetailResponseWrapper {
			@AuraEnabled
			public string caseNumber;
			@AuraEnabled
			public string createdBy;
			@AuraEnabled
			public string role;
			@AuraEnabled
			public string status;
			@AuraEnabled
			public string companyName;
			@AuraEnabled
			public string contactPhone;
			@AuraEnabled
			public string customerEmail;
			@AuraEnabled
			public string shipCSXUserId;
			@AuraEnabled
			public string onBehalfOf;
			@AuraEnabled
			public string caseReason;
			@AuraEnabled
			public string equipmentId;
			@AuraEnabled
			public string caseDescription;
			@AuraEnabled
			public list<CaseResponse> caseResponses;
			@AuraEnabled
			public list<CaseComment> caseComments;

			CaseDetailResponseWrapper() {
				caseResponses = new List<CaseResponse>();
				caseComments = new List<CaseComment>();
			}
		}

		public class CaseResponse {
			@AuraEnabled
			public string response;
			@AuraEnabled
			public string responseBy;
			@AuraEnabled
			public string responseType;
			@AuraEnabled
			public string createdDate;
		}

		public class CaseComment {
			@AuraEnabled
			public string caseCommentInternal;
			@AuraEnabled
			public string commentBy;
			@AuraEnabled
			public string commentCreatedDate;
		}

		public class ApprovalResponseWrapperBTP {
			public String caseNumber;
			public String integrationStatus;
			public String errorReason;
		}
		public class ApprovalInitationRequestWrapper {
			public String caseNumber;
			public String claimAgentUserId;
			public String claimAmount;
			public String claimSummaryPdfUrl;
			public String documentationLink;
			public String claimId;
			public String comments;
			public String claimType;
			public String firstName;
			public String lastName;
			public String approverEmail;
			public String supplierName;
			public List<ApprovalSequence> approvalSequence;
		}
		public class ApprovalSequence {
			public String approverUserId;
			public String approverType;
			public String approverName;
		}

		public class ShipmentRequestWrapper {
			@AuraEnabled
			public String equipmentNumber;
			@AuraEnabled
			public String equipmentInitial;
			@AuraEnabled
			public String waybillFromDate;
			@AuraEnabled
			public String waybillToDate;
			@AuraEnabled
			public List<string> vinNumber;
			@AuraEnabled
			public List<String> urrwinNumber;
			@AuraEnabled
			public string waybillNumber;
		}

		public class ShipmentResponseWrapper {
			@AuraEnabled
			public string equipmentInitial;
			@AuraEnabled
			public string equipmentNumber;
			@AuraEnabled
			public String waybillNumber;
			@AuraEnabled
			public Date waybillDate;
			@AuraEnabled
			public String waybillControls; //
			@AuraEnabled
			public String stcc;
			@AuraEnabled
			public String stccDescription;
			@AuraEnabled
			public string originRoadNumber;
			@AuraEnabled
			public string originAuditNumber;
			@AuraEnabled
			public String actualOriginCityName; //
			@AuraEnabled
			public String actualOriginStateCode; //
			@AuraEnabled
			public string actualOriginSCAC; //
			@AuraEnabled
			public String actualDestinationStateCode; //
			@AuraEnabled
			public String actualDestinationCityName; //
			@AuraEnabled
			public string actualDestinationSCAC; //
			@AuraEnabled
			public string destinationRoadNumber;
			@AuraEnabled
			public string destinationAuditNumber;
			@AuraEnabled
			public String shipperCode; //
			@AuraEnabled
			public String consigneeCode; //
			@AuraEnabled
			public String urrwinNumber;
			@AuraEnabled
			public Date urrwinDate;
			@AuraEnabled
			public String challengeDate;
			@AuraEnabled
			public String isSettlementDate;
			@AuraEnabled
			public String adjustmentDate;
			@AuraEnabled
			public String billofLadingDate;
			@AuraEnabled
			public String billofLadingNumber; //bolNumI
			@AuraEnabled
			public Integer numberOfCars;
			@AuraEnabled
			public String weight;
			@AuraEnabled
			public Decimal unitRefundPrice;
			@AuraEnabled
			public Decimal receivedAmount; //correctAmount
			@AuraEnabled
			public Decimal claimAmount;
			@AuraEnabled
			public Decimal settlementAmount;
			@AuraEnabled
			public String unitType;
			@AuraEnabled
			public String shipperName;
			@AuraEnabled
			public String shipperAddressLine1; //
			@AuraEnabled
			public String shipperAddressLine2; //
			@AuraEnabled
			public String shipperCityName; //
			@AuraEnabled
			public String shipperStateCode; //
			@AuraEnabled
			public String shipperPostalCode; //
			@AuraEnabled
			public String consigneeName;
			@AuraEnabled
			public String consigneeAddressLine1; //
			@AuraEnabled
			public String consigneeAddressLine2; //
			@AuraEnabled
			public String consigneeCityName; //
			@AuraEnabled
			public String consigneeStateCode; //
			@AuraEnabled
			public String consigneePostalCode; //
			@AuraEnabled
			public String originSwitchRoad;
			@AuraEnabled
			public String destinationSwitchRoad;
			@AuraEnabled
			public String fullRoad;
			@AuraEnabled
			public Integer equipmentPosition; //
			@AuraEnabled
			public String oncomingSCAC; //
			@AuraEnabled
			public String offgoingSCAC; //
			@AuraEnabled
			public String oncomingCityName; //
			@AuraEnabled
			public String oncomingStateCode; //
			@AuraEnabled
			public String offgoingCityName; //
			@AuraEnabled
			public String offgoingStateCode; //
			@AuraEnabled
			public String shipperAsClaimant;
			@AuraEnabled
			public String piggybackPlanNumber; //change name //
			@AuraEnabled
			public String mvManufacturingCode; //change name
			@AuraEnabled
			public String multiCarCount; //need to check
			@AuraEnabled
			public Boolean waybillFoundFlag;
			@AuraEnabled
			public Date freightBillDate;
			@AuraEnabled
			public String freightBillAmount;
			@AuraEnabled
			public String flatCarId; //
			@AuraEnabled
			public String shipperLegalEntityId; //
			@AuraEnabled
			public String consigneeLegalEntityId; //

			@AuraEnabled
			public String patronCode; //added for shipcsx ovecharge customer population

			@AuraEnabled
			public String businessUnit; // added to populate businessUnit

			//Previous Fields
			@AuraEnabled
			public List<string> vinNum;
			//added
			@AuraEnabled
			public String carsOrWeight; //this is not used anywhere
			@AuraEnabled
			public String refundUnitRate; //this is not used anywhere
			@AuraEnabled
			public String equipId; //this is not used anywhere
			@AuraEnabled
			public String refundAmount; //this is not used anywhere
			@AuraEnabled
			public string vin; //this is not used anywhere
			@AuraEnabled
			public String totalCars;
			@AuraEnabled
			public String description;
			@AuraEnabled
			public String commodityNumber; //transportationStcc
			@AuraEnabled
			public String quantity; //packages count
			@AuraEnabled
			public List<PartiesResponseWrapper> parties;

			@AuraEnabled
			public Decimal originalAmount; //amountPaid_OverchargeClaim -- differentName
			@AuraEnabled
			public String remarks; //added new variable

			@AuraEnabled
			public String shipmentType; // added as part of MR-00805 || defect 536

			@AuraEnabled
			public List<CSX_CMP_NewClaimWrapper.Product> products;
			@AuraEnabled
			public List<CSX_CMP_NewClaimWrapper.Distribution> distributions;

			public ShipmentResponseWrapper() {
				parties = new List<PartiesResponseWrapper>();
				products = new List<CSX_CMP_NewClaimWrapper.Product>();
				distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
			}
		}

		//Mileage Wrapper - Start
		public class TotalMilesReqWrapper {
			public OriginMiles origin;
			public String originCarrier;
			public DestinationMiles destination;
			public String destinationCarrier;
		}

		public class MileageReqWrapper {
			public String application = 'SHIPCSX';
			public List<RouteRequests> routeRequests;
		}

		public class RouteRequests {
			public Origin origin;
			public Destination destination;
			public List<Route> route;
			public String routeType = 'FULL_ROUTE';
		}

		public class Origin {
			public String state;
			public String city;
			public String stationType = 'OPSL';
		}

		public class Destination {
			public String state;
			public String city;
			public String stationType = 'OPSL';
		}

		public class Route {
			public String roadCode;
			public String junctionCode;
		}

		public class MileageResWrapper {
			public Map<String, String> segmentMileageMap; //rename
			public String totalMiles;
			public String status;
		}

		public class OriginMiles {
			public String state;
			public String city;
		}

		public class DestinationMiles {
			public String state;
			public String city;
		}

		//Mileage Wrapper - End

		public class FreightbillRequestWrapper {
			public string freightBillNumber; //This will list
			public string waybillControlNumber;
			//public string systemName = 'Salesforce';
		}

		public class FreightbillSAPRequestWrapper {            
			public string systemName = 'Salesforce';
            public List<FreightbillRequestWrapper> freightBillDetails;
		}

		public class ARBalanceResponseWrapper {
			public Decimal totalOutstandingARBalance;
			public Decimal pastDueAR;
			public Decimal financeCharges;
			public Decimal pastDueDateARBalance15Days;
			public String status;
		}

		public class FreightbillResponseWrapper {
			public string freightBillNumber;
			public Decimal billedAmount;
			public Decimal amountRec;
			public Decimal balanceDue;
			public Date waybillDate;
			public String wayBillControlNumber;
		}

		public class PartiesResponseWrapper {
			@AuraEnabled
			public String partyRole; // CN/SH
			@AuraEnabled
			public String leCode; //Le@Code
			@AuraEnabled
			public String partyName; //Account Name
		}

		public class RARSRequestWrapper {
			public string equipmentId;
			public string incidentState;
			public string fromReportedDate;
		}

		public class RARSResponseWrapper {
			public String status; //Success or Error
			public Date incidentDate;
			public String rarNumber;
		}

		public class MTIRequestWrapper {
			public string equipmentInitial;
			public string equipmentNumber;
			public string waybillDate;
			public string equipmentId; //not needed
			public string incidentState; //not needed
			public string reportedDate; // not needed
		}

		public class MTIResponseWrapper {
			public string badOrderNotes;
			public string incidentDate;
			public String trackId;
			public string multipleBadOrders;
			public string status;
		}

		public class UmlerResponseWrapper {
			public String carId;
			public String aaaCarType;
			public String equipmentGroup;
			public String actualOwner;
			public String insideLength;
			public String insideWidth;
			public String lessee;
			public String equipmentNumber;
			public string status;
			public string outerLength;
			public string originalInitial;
		}
		public class EDIClaimStatusReportWrapper {
			@AuraEnabled
			public String claimCreatedDate;
			@AuraEnabled
			public String claimNumber;
			@AuraEnabled
			public String claimantRefNumber;
			@AuraEnabled
			public String claimAmount;
			@AuraEnabled
			public String paidAmount;
			@AuraEnabled
			public String status;
			@AuraEnabled
			public String seclineCode;
			@AuraEnabled
			public String currencyCode;
			@AuraEnabled
			public list<APSettlement> settlement;
		}
		public class APSettlement {
			public String checkNumeber;
			@AuraEnabled
			public String declanationCode;
			@AuraEnabled
			public String dysDate;
			@AuraEnabled
			public String ediSeqNum;
			@AuraEnabled
			public String currencyCode;
		}
		public class InvoiceWrapper {
			public String invoiceNumber { get; set; }
			public String invoiceStatus { get; set; }
			public String externalId { get; set; }
			public String companyCode { get; set; }
			public String invoiceDate { get; set; }
			public String reversalReason { get; set; }
			public String requestType { get; set; }
			public String createdDate { get; set; }
		}
		public class InvoiceCancellationResponseWrapper1 {
			public String invoiceNumber;
			public String status; 
			public String externalId; 
			public String message;
		}
		public class InvoiceCancellationResponseWrapper2{
			public error error{get;set;}
			public list<details> details{get;set;}
			public String traceId{get;set;}
		}
		public class error{
			public String message{get;set;}
			public String target{get;set;}
			public Integer code{get;set;}
		}
		public class details{
			public Integer code{get;set;}
			public String target{get;set;}
			public String message{get;set;}
		}
	


		public class SAPRequestWrapper {
			public String claimNumber;
			public String nationalAccountNumber;
			public String apSettlementAutonumberClaimnumber;
			public String claimOwner;
			public Integer supplierNumber;
			public list<FreightBill> claimLinePaymentAmount;

			public SAPRequestWrapper() {
				claimLinePaymentAmount = new List<FreightBill>();
			}
		}

		public class FreightBill {
			public string frieghtBillNumber;
			public Integer amount;
		}

		public class SAPResponseWrapper {
			public String claimNumber;
			public String salesforceAutoNumberClaimNumber;
			public Integer paymentInvoiceNumber;
			public String status;
			public String errorReason;
		}
	}