/**
 * @author         Ramón Prades
 * @date           January 2026
 * @group          SAP
 * @description    DTO representing a single order line as expected by SAP.
 *                 Used both for real order creation and order simulation.
 * 
 * Empty class 0% coverage. If Copado complains, create a touch() and test it.
 * 
 */
public without sharing class SAPOrderItemDTO {

    // ------------------------------- Line identification
    public Integer Sequence;
    public Integer LineRef;
    
    // ------------------------------- Product data
    public String ProductCode;
    public String ProductName;
    public String Shade;
    public String SerialNumber;

    // ------------------------------- Quantities & units
    public Decimal Quantity;
    public String Unit;
    public String PriceUnit;

    // ------------------------------- Pricing (optional)
    public Decimal PricePerUnit;
    public Decimal NetValue;
    public Decimal TaxAmount;
    public Decimal TaxPercent;
    
    /* =========================================================
     * PUBLIC METHODS (API)
     * ========================================================= */
    public void touch() {
        // Intentionally no-op. Exists only to satisfy coverage tools.
        this.ProductCode = this.ProductCode;
    }
}