/**************************************************************************************
Apex Class Name     : CSX_CMP_UmlerRequest
Function            : Class for generating Umler Request body
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           03/14/2024       First version of this class.
*************************************************************************************/
public class CSX_CMP_UmlerRequest {
	public static string umlerInput(List<string> equipmentIds) {
		DateTime todayDate = DateTime.now();
		string formatdate = todayDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('getUMLERData');
		gen.writeStartObject();
		gen.writeFieldName('commonHeader');
		gen.writeStartObject();
		gen.writeStringField('consumerID', 'SY');
		gen.writeStringField('transactionName', 'getUMLERData');
		gen.writeStringField('timestamp', formatdate); //string.valueOf(todayDate)
		gen.writeStringField('invokedBy', 'JWDS_APP');
		gen.writeEndObject();
		gen.writeFieldName('elementIDList');
		gen.writeStartObject();
		gen.writeFieldName('element');
		gen.writeStartArray();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'UMET');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', '0002');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'UMOW');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'A135');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'OSLG');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'LESE');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', '9008');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeStartObject();
		gen.writeStringField('elementID', 'A138');
		gen.writeStringField('filter', 'EQPT');
		gen.writeEndObject();
		gen.writeEndArray();
		gen.writeEndObject();
		gen.writeFieldName('carIDList');
		gen.writeStartArray();
		gen.writeStartObject();
		gen.writeFieldName('carID');
		gen.writeStartArray();
		for (String equpId : equipmentIds) {
			gen.writeString(equpId);
		}
		gen.writeEndArray();
		gen.writeEndObject();
		gen.writeEndArray();
		gen.writeEndObject();
		gen.writeEndObject();
		string jsonString = gen.getAsString();
		return jsonString;
	}
}