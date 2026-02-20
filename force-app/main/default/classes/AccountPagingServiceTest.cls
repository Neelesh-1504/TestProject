/**
 * Unit tests for AccountPagingService
 */
@IsTest
private class AccountPagingServiceTest {
    @TestSetup
    static void setupData() {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 26; i++) {
            Account a = new Account();
            a.Name = 'Test Account ' + (i < 10 ? '0' : '') + String.valueOf(i);
            a.Industry = (Math.mod(i, 2) == 0) ? 'Technology' : 'Finance';
            a.Phone = '123-456-789' + String.valueOf(i);
            a.Type = (Math.mod(i, 3) == 0) ? 'Prospect' : 'Customer';
            accts.add(a);
        }
        insert accts;
    }

    @IsTest
    static void testDefaultPage() {
        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(1, 10, null, 'ASC');
        Test.stopTest();

        System.assert(ap != null, 'Page should not be null');
        System.assertEquals(10, ap.records.size(), 'Default fetch should return 10 records');
        System.assertEquals(26, ap.totalRecords, 'Total records should match inserted size');
        System.assertEquals(1, ap.pageNumber, 'Page number should be 1');
        System.assertEquals(10, ap.pageSize, 'Page size should be 10');
        System.assertEquals((Integer) Math.ceil(26 / 10.0), ap.totalPages, 'Total pages calculation is incorrect');
    }

    @IsTest
    static void testSecondPage() {
        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(2, 10, null, 'ASC');
        Test.stopTest();

        System.assertEquals(2, ap.pageNumber, 'Should be page 2');
        System.assertEquals(10, ap.records.size(), 'Second page should have 10 records');
    }

    @IsTest
    static void testLastPageRemainder() {
        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(3, 10, null, 'ASC');
        Test.stopTest();

        System.assertEquals(3, ap.pageNumber, 'Should be page 3');
        System.assertEquals(6, ap.records.size(), 'Last page should have remaining 6 records');
    }

    @IsTest
    static void testSearchFilter() {
        // Add one specifically named account to ensure filter
        insert new Account(Name = 'UniqueMatch-XYZ', Industry = 'Retail');

        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(1, 10, 'UniqueMatch', 'ASC');
        Test.stopTest();

        System.assertEquals(1, ap.pageNumber, 'Search on first page');
        System.assertTrue(ap.totalRecords >= 1, 'Should find at least one match');
        Boolean containsUnique = false;
        for (Account a : ap.records) {
            if (a.Name != null && a.Name.contains('UniqueMatch')) {
                containsUnique = true;
                break;
            }
        }
        System.assertEquals(true, containsUnique, 'Results should include the specifically inserted matched account');
    }

    @IsTest
    static void testSortDirectionValidation() {
        // Invalid sort should default to ASC and not throw
        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(1, 5, null, 'INVALID');
        Test.stopTest();

        System.assertEquals(1, ap.pageNumber, 'Page number should be valid');
        System.assertEquals(5, ap.pageSize, 'Page size should be respected');
        System.assertEquals(true, ap.records.size() <= 5, 'Should return at most requested size');
    }

    @IsTest
    static void testZeroResults() {
        Test.startTest();
        AccountPagingService.AccountPage ap = AccountPagingService.fetchAccounts(1, 10, 'NO_SUCH_NAME_123456', 'ASC');
        Test.stopTest();

        System.assertEquals(0, ap.totalRecords, 'Total records should be zero for no matches');
        System.assertEquals(0, ap.records.size(), 'No records should be returned');
        System.assertEquals(1, ap.pageNumber, 'Page number remains 1');
        System.assertEquals(10, ap.pageSize, 'Page size default');
        System.assertEquals(0, ap.totalPages, 'Total pages 0 when no records');
    }
}
