import { LightningElement, track } from 'lwc';
import fetchAccounts from '@salesforce/apex/AccountPagingService.fetchAccounts';

export default class AccountPaginator extends LightningElement {
    // State
    @track rows = [];
    @track totalRecords = 0;
    @track totalPages = 0;
    @track pageNumber = 1;
    @track pageSize = 10;
    @track loading = false;
    @track errorMessage = '';
    @track searchKey = '';
    @track sortDirection = 'ASC';

    pageSizeOptions = [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '25', value: 25 }
    ];

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        { label: 'Industry', fieldName: 'Industry' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' },
        { label: 'Type', fieldName: 'Type' },
        { label: 'Owner', fieldName: 'OwnerName' }
    ];

    connectedCallback() {
        this.loadPage();
    }

    async loadPage() {
        this.loading = true;
        this.errorMessage = '';
        try {
            const result = await fetchAccounts({
                pageNumber: this.pageNumber,
                pageSize: this.pageSize,
                searchKey: this.searchKey,
                sortDirection: this.sortDirection
            });
            this.totalRecords = result?.totalRecords ?? 0;
            this.totalPages = result?.totalPages ?? 0;
            const data = result?.records ?? [];
            // Flatten Owner.Name for datatable display
            this.rows = data.map(r => ({
                ...r,
                OwnerName: r?.Owner?.Name
            }));
        } catch (e) {
            this.errorMessage = e?.body?.message || e?.message || 'Error loading Accounts';
            // reset to safe defaults
            this.rows = [];
            this.totalRecords = 0;
            this.totalPages = 0;
        } finally {
            this.loading = false;
        }
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value || '';
    }

    handleSearch() {
        this.pageNumber = 1;
        this.loadPage();
    }

    handlePageSizeChange(event) {
        this.pageSize = Number(event.detail.value);
        this.pageNumber = 1;
        this.loadPage();
    }

    handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.loadPage();
        }
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.loadPage();
        }
    }

    handleSortToggle() {
        this.sortDirection = this.sortDirection === 'ASC' ? 'DESC' : 'ASC';
        this.pageNumber = 1;
        this.loadPage();
    }

    get isPrevDisabled() {
        return this.loading || this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.loading || this.pageNumber >= this.totalPages || this.totalPages === 0;
    }

    get pageInfo() {
        return `Page ${this.totalPages === 0 ? 0 : this.pageNumber} of ${this.totalPages}`;
    }

    get showEmpty() {
        return !this.loading && this.rows.length === 0;
    }
}
