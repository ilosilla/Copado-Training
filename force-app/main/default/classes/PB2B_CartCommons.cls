/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          B2B
 * @description    Common utility methods to work with the B2B shopping cart
 */ 
public class PB2B_CartCommons {
    
    public static void clearValidations(CartExtension.CartValidationOutputList outputList, CartExtension.CartValidationOutputTypeEnum outputType) {
        for (Integer i = (outputList.size() - 1); i >= 0; i--) {
            CartExtension.CartValidationOutput cvo = outputList.get(i);
            if (cvo.getType() == outputType) {
                outputList.remove(cvo);
            }
        }
    } // clearValidationOutputs

    public static void clearTaxValidations(CartExtension.CartValidationOutputList outputList) {
        PB2B_CartCommons.clearValidations(outputList, CartExtension.CartValidationOutputTypeEnum.TAXES);        
    }

    public static void clearShippingValidations(CartExtension.CartValidationOutputList outputList) {
        PB2B_CartCommons.clearValidations(outputList, CartExtension.CartValidationOutputTypeEnum.SHIPPING);        
    }

    public static Decimal getCartWeightKg(Id cartId) {
        List<CartItem> items = [
            SELECT TotalWeight
            FROM CartItem
            WHERE CartId = :cartId
              AND Type   = 'Product'
        ];
        Decimal total = 0;
        for (CartItem item : items) {
            if (item.TotalWeight != null) {
                total += item.TotalWeight;
            }
        }
        return total;
    }



} // class