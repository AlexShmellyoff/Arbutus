import { LightningElement, api, wire, track } from 'lwc';
import getQuoteNotes from '@salesforce/apex/PredefinedQuoteNotesController.getQuoteNotes';
import getAllCategories from '@salesforce/apex/PredefinedQuoteNotesController.getAllCategories';
import getNotesByCategory from '@salesforce/apex/PredefinedQuoteNotesController.getNotesByCategory';
import saveNoteSelections from '@salesforce/apex/PredefinedQuoteNotesController.saveNoteSelections';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';

export default class QuoteNotesTable extends LightningElement {
    @api recordId;

    @track data = [];
    @track selectedRowIds = [];
    @track allCategories = [];
    @track selectedCategory = null;
    @track isCategoryModalOpen = false;

    wiredResult;

    columns = [
        { label: 'Note Name', fieldName: 'name' },
        { label: 'Note Details', fieldName: 'details' },
        { label: 'Category', fieldName: 'category' }
    ];

    categoryColumns = [
        { label: 'Category', fieldName: 'category' }
    ];

    @wire(getQuoteNotes, { quoteId: '$recordId' })
    wiredNotes(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.data = data.map(note => ({
                id: note.Id,
                name: note.Name,
                details: note.NoteDetails__c,
                category: note.Category__c
            }));
            this.selectedRowIds = this.data.map(note => note.id);
        } else if (error) {
            console.error('Error loading quote notes', error);
        }
    }

    connectedCallback() {
        refreshApex(this.wiredResult);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // handleNoteRowSelection(event) {
    //     switch (event.detail.config.action) {
    //         case 'selectAllRows':
                
    //             console.log('[VDO]Selected rows:', event.detail.selectedRows);
    //             break;
    //         case 'deselectAllRows':
    //             console.log('[VDO]Deselected rows:', event.detail.selectedRows);
    //             break;
    //         case 'rowSelect':
    //             console.log('[VDO]Row selected:', event.detail.config.value);
    //             break;
    //         case 'rowDeselect':
    //             console.log('[VDO]Row deselected:', event.detail.config.value);
    //             break;
    //         default:
    //             break;
    //     }
    // }

    // handleSave() {
    //     console.log('Saving selected notes:', JSON.stringify(this.selectedRowIds));
    //     const idsToSave = this.data.map(row => row.id);
    //     saveNoteSelections({ selectedNoteIds: idsToSave, quoteId: this.recordId })
    //         .then(() => {
    //             refreshApex(this.wiredResult);
    //             this.closeModal();
    //         })
    //         .catch(error => console.error('Save error', error));
    // }

    handleNoteRowSelection(event) {
        const selectedRows = event.detail.selectedRows || [];
        this.selectedRowIds = selectedRows.map(row => row.id); // ✅ Always update selectedRowIds
    
        console.log('[VDO]Currently selected rows:', this.selectedRowIds);
    }

    handleSave() {
        const selectedRows = this.template.querySelector('lightning-datatable')?.getSelectedRows() || [];
        const idsToSave = selectedRows.map(row => row.id);
    
        console.log('Saving selected notes:', JSON.stringify(idsToSave));
    
        saveNoteSelections({ selectedNoteIds: idsToSave, quoteId: this.recordId })
            .then(() => {
                // First close the modal
                this.dispatchEvent(new CloseActionScreenEvent());
    
                // Then wait a little and refresh
                setTimeout(() => {
                    window.location.reload();
                }, 500); // small delay to let modal close cleanly
            })
            .catch(error => console.error('Save error', error));
    }

    handleRemoveSelected() {
        const selectedRows = this.template.querySelector('lightning-datatable')?.getSelectedRows() || [];
        const selectedIds = new Set(selectedRows.map(row => row.id));
        this.data = this.data.filter(row => !selectedIds.has(row.id));
        this.selectedRowIds = [];
    }

    openCategoryModal() {
        getAllCategories()
            .then(categories => {
                this.allCategories = categories.map((cat, index) => ({
                    id: index.toString(),
                    category: cat
                }));
                this.isCategoryModalOpen = true;
            })
            .catch(error => console.error('Error fetching categories', error));
    }

    closeCategoryModal() {
        this.selectedCategory = null;
        this.isCategoryModalOpen = false;
    }

    handleCategoryRowSelection(event) {
        const selected = event.detail.selectedRows;
        this.selectedCategory = selected.length > 0 ? selected[0].category : null;
    }

    handleAddCategoryClick() {
        if (!this.selectedCategory) return;

        getNotesByCategory({ category: this.selectedCategory })
            .then(result => { 
                const newNotes = result.map(note => ({
                    id: note.Id,
                    name: note.Name,
                    details: note.NoteDetails__c,
                    category: note.Category__c
                }));

                const existingIds = new Set(this.data.map(r => r.id));
                const filtered = newNotes.filter(n => !existingIds.has(n.id));

                this.data = [...this.data, ...filtered];
                this.closeCategoryModal();
            })
            .catch(error => console.error('Error loading notes by category', error));
    }
}