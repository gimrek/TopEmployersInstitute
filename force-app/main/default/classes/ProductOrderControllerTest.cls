@isTest 
public with sharing class ProductOrderControllerTest {
    @TestSetup
    static void createTestData(){
        List<Product2> products= new List<Product2>();
        for(integer i=0;i<5;i++){
            Product2 p1= new Product2(Name='Apple '+i,
                                     Family='A',
                                     IsActive=true );
            products.add(p1);
        }
        for(integer i=0;i<5;i++){
            Product2 p2= new Product2(Name='Orange '+i,
                                     Family='B',
                                     IsActive=true );
            products.add(p2);
        }
        for(integer i=0;i<5;i++){
            Product2 p3= new Product2(Name='Kiwi '+i,
                                     Family='B',
                                     IsActive=true );
            products.add(p3);
        }
        for(integer i=0;i<5;i++){
            Product2 p4= new Product2(Name='Peach '+i,
                                     Family='A',
                                     IsActive=true );
            products.add(p4);
        }
        insert products;

        List<Product2> productList = [SELECT Name, Family, IsActive FROM Product2];     
        List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();
        for(Product2 product : productList){
            PricebookEntry pricebookEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 100,
                IsActive = true
            );
            priceBookEntryList.add(pricebookEntry);
        }                                 
        insert priceBookEntryList;

        Account account = new Account(
            Name = 'Test Account',
            Rating = 'Hot',
            Industry = 'Banking',
            Phone = '9087654321'
        );
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId()
        );
        insert order;

        List<OrderItem> orderItemList = new List<OrderItem>();
        List<PricebookEntry> pricebookEntryListFromDB = [SELECT Id, Product2Id FROM PricebookEntry];
        for(PricebookEntry pricebookEntry : pricebookEntryListFromDB){
            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                Quantity = 1,
                UnitPrice = 100,
                Product2id = pricebookEntry.Product2Id,
                PricebookEntryId = pricebookEntry.Id
            );
            orderItemList.add(orderItem);
        }
        insert orderItemList;
    }
    
    @isTest static void test_ProductOrderController(){
        Order order = [SELECT Id FROM Order LIMIT 1];
        
        List<String> productIdSet = new List<String>();
        List<Product2> productList = [SELECT Id FROM Product2 LIMIT 10];
        for(Product2 product : productList){
            productIdSet.add(product.Id);
        }

        Product2 productNew = new Product2(Name = 'Apple New ',
                                            Family = 'A',
                                            IsActive = true );
        insert productNew;
        PricebookEntry pricebookEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                        Product2Id = productNew.Id,
                                                        UnitPrice = 100,
                                                        IsActive = true
                                                    );
        insert pricebookEntry;

        productIdSet.add(productNew.Id);

        Test.startTest();
        ProductOrderController.getProductList(order.Id);
        ProductOrderController.getOrderList(order.Id);
        ProductOrderController.addProducts(order.Id, productIdSet);
        Test.stopTest();
    }
}