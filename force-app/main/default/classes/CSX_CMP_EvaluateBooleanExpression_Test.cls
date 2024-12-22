/**
@Author       - Infosys
@Name         - BooleanExpression
@Created Date - 03/17/2024
@Description  - This test class is used to cover CSX_CMP_EvaluateBooleanExpression class.
@RICEFW reference - CMP-E-0425                
*/
@isTest
public class CSX_CMP_EvaluateBooleanExpression_Test {
    
    // Test method to evaluate simple boolean expressions
	@isTest
	static void testSimpleExpressions() {
		String expression;
        
        // Asserts that evaluating 'TRUE' returns true
		expression = 'TRUE';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation is true');
        
        // Asserts that evaluating 'FALSE' returns false.
		expression = 'FALSE';
		System.assertEquals(false, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation is false');
        
		// Asserts that 'TRUE AND FALSE' evaluates to false
		expression = 'TRUE AND FALSE';
		System.assertEquals(false, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation must be false');
        
        // Asserts that 'TRUE OR FALSE' evaluates to true
		expression = 'TRUE OR FALSE';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation must be true');
	}
	
    // Test method to evaluate boolean expressions with logical operators
	@isTest
	static void testExpressionsWithLogic() {
        
        // Asserts that 'TRUE AND TRUE' evaluates to true.
		String expression = 'TRUE AND TRUE';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation must be true');
        
        // Asserts that '(TRUE AND FALSE) OR TRUE' evaluates to true.
		expression = '(TRUE AND FALSE) OR TRUE';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation should be true');
        
		// Asserts that 'FALSE OR FALSE' evaluates to false.
		expression = 'FALSE OR FALSE';
		System.assertEquals(false, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation should be false ');
        
        // Asserts that 'FALSE OR (TRUE AND TRUE)' evaluates to true.
		expression = 'FALSE OR (TRUE AND TRUE)';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation should get true');
        
		// Asserts that '(TRUE)' evaluates to true.
		expression = '(TRUE)';
		System.assertEquals(true, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluates to true');
        
        // Asserts that 'FALSE OR (FALSE)' evaluates to false.
		expression = 'FALSE OR (FALSE)';
		System.assertEquals(false, CSX_CMP_EvaluateBooleanExpression.eval(expression), 'Evaluation must be false');
	}

}