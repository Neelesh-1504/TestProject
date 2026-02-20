/**
 * @description Service to paginate Account records with optional search and sorting.
 * Enforced with sharing and FLS via WITH SECURITY_ENFORCED. Designed for Flow/Apex and LWC usage.
 * Uses Database methods with error handling and Return Early pattern.
 * 
 * Exposed method: fetchAccounts(pageNumber, pageSize, searchKey, sortDirection)
 * - pageNumber: 1-based page index
 * - pageSize: number of records per page
 * - searchKey: optional substring match on Name (case-insensitive)
 * - sortDirection: &#39;ASC&#39; or &#39;DESC&#39; for Name
 */
public with sharing class AccountPagingService {
    // Use enums over string constants
    public enum SORT_DIRECTION { ASC, DESC; }

    public class AccountPage {
        @AuraEnabled public List<Account> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer totalPages;

        public AccountPage(List<Account> recs, Integer total, Integer pageNum, Integer size) {
            records = recs;
            totalRecords = total;
            pageNumber = pageNum;
            pageSize = size;
            totalPages = (size > 0) ? (Integer) Math.ceil((Decimal) total / size) : 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static AccountPage fetchAccounts(Integer pageNumber, Integer pageSize, String searchKey, String sortDirection) {
        // Return Early validation
        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }
        if (pageSize == null || pageSize <= 0) {
            pageSize = 10;
        }
        SORT_DIRECTION sortDir;
        try {
            sortDir = (sortDirection == null) ? SORT_DIRECTION.ASC : SORT_DIRECTION.valueOf(sortDirection.toUpperCase());
        } catch (Exception e) {
            sortDir = SORT_DIRECTION.ASC;
        }

        Integer offsetVal = (pageNumber - 1) * pageSize;

        // Build where clause
        String whereClause = '';
        if (searchKey != null && searchKey.trim().length() > 0) {
            // Note: bind variables aren't supported in dynamic WHERE fragments. Build LIKE literal safely.
            String safe = String.escapeSingleQuotes(searchKey.trim());
            whereClause = 'WHERE Name LIKE \'%' + safe + '%\'';
        }

        // Count query
        Integer totalCount = 0;
        try {
            if (whereClause == '') {
                totalCount = [SELECT COUNT() FROM Account WITH SECURITY_ENFORCED];
            } else {
                totalCount = (Integer) Database.countQuery('SELECT COUNT() FROM Account ' + whereClause + ' WITH SECURITY_ENFORCED');
            }
        } catch (Exception eCount) {
            // Surface a clear error
            throw new AuraHandledException('Failed to count Account records: ' + eCount.getMessage());
        }

        // If no records, return early
        if (totalCount == 0) {
            return new AccountPage(new List<Account>(), 0, pageNumber, pageSize);
        }

        // Main query with selected fields and Owner relationship
        String baseSoql = 'SELECT Id, Name, Industry, Phone, Type, Owner.Name FROM Account ';
        String orderLimit = ' ORDER BY Name ' + String.valueOf(sortDir) + ' LIMIT :pageSize OFFSET :offsetVal';

        List<Account> rows = new List<Account>();
        try {
            if (whereClause == '') {
                rows = Database.query(baseSoql + 'WITH SECURITY_ENFORCED' + orderLimit);
            } else {
                rows = Database.query(baseSoql + whereClause + ' WITH SECURITY_ENFORCED' + orderLimit);
            }
        } catch (Exception eQuery) {
            throw new AuraHandledException('Failed to fetch Account records: ' + eQuery.getMessage());
        }

        return new AccountPage(rows, totalCount, pageNumber, pageSize);
    }
}
