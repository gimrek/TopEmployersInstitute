import { LightningElement ,api, wire, track} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import getProductList from '@salesforce/apex/ProductOrderController.getProductList';

export default class ProductTable extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track products;
    productData =[];
    productColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'List Price', fieldName: 'UnitPrice', type:'currency'}                
    ];
    selectedProductIds = [];

    connectedCallback() {
        let orderId = this.pageRef.state.c__id;
        getProductList({ orderId: orderId } )
            .then(result => {
                this.products = result;
                for(let i=0; i<this.products.length; i++){
                    if(this.products[i].PricebookEntries != undefined){
                        for(let j=0; j<this.products[i].PricebookEntries.length; j++){
                            this.productData.push({"Id" : this.products[i].Id, 
                                                    "Name" : this.products[i].Name, 
                                                    "UnitPrice" : this.products[i].PricebookEntries[j].UnitPrice});
                        }
                    }
                    
                }
                this.productData = [...this.productData];
            });
    }

    handleRowSelection(event){
        const selectedRows = event.detail.selectedRows;
        this.selectedProductIds = [];
        for(let i=0; i<selectedRows.length; i++){
            this.selectedProductIds.push(selectedRows[i].Id);
        }
        
    }

    handleAddToOrder(){
        fireEvent(this.pageRef, 'pubsubselectedidsubmit', this.selectedProductIds);
    }
}