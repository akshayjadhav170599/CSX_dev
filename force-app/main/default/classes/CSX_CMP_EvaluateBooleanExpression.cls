/**
@Author       - Infosys
@Name         - BooleanExpression
@Created Date - 12/17/2023
@Description  - This Apex class is used to convert the string expression into boolean result
                (TRUE AND (TRUE AND FALSE))
@RICEFW reference - CMP-E-0425                
*/
public with sharing class CSX_CMP_EvaluateBooleanExpression {
    
    static Map<String, String> logicTypes = new Map<String, String>();
    static Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>();
    
    // Evaluate a boolean expreassion 
    public static Boolean eval(String expression) {        
        try{
            // If expression contains all TRUE or FALSE
            if(expression.containsNone('FALSE')) { return TRUE; }        
            if(expression.containsNone('TRUE')) { return FALSE; }
            fillLogic();
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EvaluateBooleanExpression', 'eval', expression, ex);  
        }  
        return Boolean.valueOf(evaluateExpression(expression.toUpperCase()));
    }
    
    // Evaluate the expression
    public static String evaluateExpression(String expression) {   
        try{
            for(String logicType : logicTypes.keySet()) {
                if(expression.contains(logicType)) {
                    expression = simplifyExpression(expression, logicTypes.get(logicType));
                }
            }
            
            if(expression.contains('AND') || expression.contains('OR') || expression.contains('(')) {
                expression = evaluateExpression(expression);
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EvaluateBooleanExpression', 'evaluateExpression', expression, ex);  
        } 
        return expression;
    }
    
     // Simplify the expression
    public static string simplifyExpression(String expression, String logicType){
        try{
            Map<String, String> logic = new Map<String, String>(expressionLogic.get(logicType));
        
            for(String key : logic.keySet()) {
                expression = expression.replace(key, logic.get(key));
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EvaluateBooleanExpression', 'simplifyExpression', expression +'_'+logicType, ex);  
        }
        
        return expression;
    } 
    
    // Fill AND and OR Logic
    public static void fillLogic() {
        try{
            Map<String, String> andLogic = new Map<String, String>();
            Map<String, String> orLogic = new Map<String, String>();
            Map<String, String> braceLogic = new Map<String, String>();
            
            logicTypes.put('AND', 'AND');
            logicTypes.put('OR', 'OR');
            logicTypes.put('(', 'BRACES');
            
            // AND Logic
            andLogic.put('TRUE AND TRUE', 'TRUE');
            andLogic.put('TRUE AND FALSE', 'FALSE');
            andLogic.put('FALSE AND TRUE', 'FALSE');
            andLogic.put('FALSE AND FALSE', 'FALSE');
            expressionLogic.put('AND', andLogic);
            
            // OR Logic
            orLogic.put('TRUE OR TRUE', 'TRUE');
            orLogic.put('TRUE OR FALSE', 'TRUE');
            orLogic.put('FALSE OR TRUE', 'TRUE');
            orLogic.put('FALSE OR FALSE', 'FALSE');
            expressionLogic.put('OR', orLogic);
            
            // Braces Logic
            braceLogic.put('(TRUE)', 'TRUE');
            braceLogic.put('(FALSE)', 'FALSE');
            expressionLogic.put('BRACES', braceLogic);
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EvaluateBooleanExpression', 'fillLogic', json.serialize(expressionLogic), ex);  
        } 
    }

}