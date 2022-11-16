import { LightningElement , track , wire  } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderList from '@salesforce/apex/ProductOrderController.getOrderList';
import addProducts from '@salesforce/apex/ProductOrderController.addProducts';

export default class OrderTable extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @track orderId; 
    @track totalPrice = 0;
    @track aFamilyTotalPrice = 0;
    @track bFamilyTotalPrice = 0;
    @track cFamilyTotalPrice = 0;
    @track dFamilyTotalPrice = 0;

    orderData = [];
    orderColumns = [{ label: 'Product Name', fieldName: 'Name', type: 'text'},
                    { label: 'Quantity', fieldName: 'Quantity', type: "text"},
                    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', },
                    { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency'},
                    {
                        type: 'button-icon',
                        fixedWidth: 50,
                        typeAttributes:
                        {
                            iconName: 'utility:delete',
                            name: 'delete',
                            iconClass: 'slds-icon-text-error'
                        }
                    }];
    _wiredOrderData;
    @wire(getOrderList, { orderId: '$orderId' })
    wiredRecords(wireResult) {
        const { data, error } = wireResult;
        this._wiredOrderData = wireResult;
        if(data){
            this.totalPrice = 0;
            this.aFamilyTotalPrice = 0;
            this.bFamilyTotalPrice = 0;
            this.cFamilyTotalPrice = 0;
            this.dFamilyTotalPrice = 0;
            for(let i=0; i<data.length; i++){
                let orderList = JSON.parse(JSON.stringify(data))
                this.orderData.push({"Id" : orderList[i].Id, 
                    "Name" : orderList[i].Product2.Name, 
                    "UnitPrice" : orderList[i].UnitPrice, 
                    "TotalPrice" : orderList[i].TotalPrice, 
                    "Quantity" : orderList[i].Quantity, 
                    "Family" : orderList[i].Product2.Family});
                this.totalPrice += orderList[i].TotalPrice;

                if(orderList[i].Product2.Family == 'A'){
                    this.aFamilyTotalPrice += orderList[i].TotalPrice;
                }  else if (orderList[i].Product2.Family == 'B') {
                    this.bFamilyTotalPrice += orderList[i].TotalPrice;
                } else if (orderList[i].Product2.Family == 'C') {
                    this.cFamilyTotalPrice += orderList[i].TotalPrice;
                } else {
                    this.dFamilyTotalPrice += orderList[i].TotalPrice;
                }
            }
            this.orderData = [...this.orderData];  
        }
        if(error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Wire error!',
                    message: error,
                    variant: 'error'
                })
            );
        }
    };

    connectedCallback() {
        registerListener('pubsubselectedidsubmit', this.addNewProducts, this);    
        this.orderId = this.pageRef.state.c__id;
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    addNewProducts(selectedProductIds) {
        if(selectedProductIds != null){
            addProducts({orderId: this.orderId, productIdList : selectedProductIds})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record created!',
                        variant: 'success'
                    })
                );   
                this.orderData = [];  
                return refreshApex(this._wiredOrderData);  
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Insert Error!',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
        }
    }

    deleteProducts(event){
        const row = event.detail.row;
        const orderItem = JSON.parse(JSON.stringify(row));
        deleteRecord(orderItem.Id)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted!',
                        variant: 'success'
                    })
                );    
                this.orderData = [];  
                return refreshApex(this._wiredOrderData);               
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Delete Error!',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}