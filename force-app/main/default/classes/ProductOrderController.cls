public with sharing class ProductOrderController {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductList(String orderId) {
        Order order = [SELECT Pricebook2Id 
                        FROM Order 
                        WHERE Id = :orderId];
        return [SELECT 
                    Id,
                    Name,
                    (SELECT 
                        UnitPrice 
                    FROM PricebookEntries 
                    WHERE Pricebook2Id = :order.Pricebook2Id) 
                FROM Product2];
    }

    @AuraEnabled(cacheable = true)
    public static List<OrderItem> getOrderList(String orderId) {
        return [SELECT 
                    Id, 
                    Product2.Name,
                    Product2.Family,
                    UnitPrice,
                    TotalPrice,
                    Quantity 
                FROM OrderItem 
                WHERE Order.Id = :orderId];
    }

    @AuraEnabled
    public static void addProducts(String orderId, List<String> productIdList) {
        Order order = [SELECT 
                            Id, 
                            Pricebook2Id 
                        FROM Order 
                        WHERE ID = :orderId];
        List<OrderItem> orderItems = [SELECT 
                                            Id, 
                                            Product2Id, 
                                            Quantity 
                                        FROM OrderItem 
                                        WHERE OrderId = :order.Id];

        Map<String, OrderItem> productIdToQuantity = new Map<String, OrderItem>();
        for(OrderItem orderItem : orderItems){
            productIdToQuantity.put(orderItem.Product2Id, orderItem);
        }  
        List<PricebookEntry> pricebookEntryList = [SELECT 
                                                        Id, 
                                                        Product2Id,
                                                        UnitPrice
                                                    FROM PricebookEntry 
                                                    WHERE Pricebook2Id =: order.Pricebook2Id 
                                                    AND Product2Id IN :productIdList];
        
        Map<String, String> productIdToPriceBookEntryId = new Map<String, String>();
        Map<String, Decimal> productIdToUnitPrice = new Map<String, Decimal>();
        for(PricebookEntry pricebookEntry : pricebookEntryList){
            productIdToPriceBookEntryId.put(pricebookEntry.Product2Id, pricebookEntry.Id);
            productIdToUnitPrice.put(pricebookEntry.Product2Id, pricebookEntry.UnitPrice);
        }                                            

        List<OrderItem> insertOrderItems = new List<OrderItem>();
        List<OrderItem> updateOrderItems = new List<OrderItem>();
        for(String productId : productIdList){
            if(productIdToQuantity.get(productId) == null){
                OrderItem orderItem = new OrderItem();
                orderItem.OrderId = order.Id;
                orderItem.UnitPrice = productIdToUnitPrice.get(productId);
                orderItem.Product2id = productId;
                orderItem.PricebookEntryId= productIdToPriceBookEntryId.get(productId);
                orderItem.Quantity = 1;
                insertOrderItems.add(orderItem);
            }else{
                OrderItem orderItem = productIdToQuantity.get(productId);
                orderItem.Quantity += 1;
                updateOrderItems.add(orderItem);
            }
        }
        update updateOrderItems;
        insert insertOrderItems;
    }    
}