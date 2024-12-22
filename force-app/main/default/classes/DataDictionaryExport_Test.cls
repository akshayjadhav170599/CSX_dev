@isTest
private class DataDictionaryExport_Test {

    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account> ();
        for (Integer i = 0; i < 5; i++){
            testAccounts.add(new Account(Name = 'Test Account' +i, Industry = 'Technology'));
        } 
        insert testAccounts;
        
        
    }
}