public with sharing class NB2B_StockCallOutResponseWrapper {
    
    public Decimal availstk;
    public String name;
    public String product;
    public String salesorg;
    public Decimal totalstk;
    public String umb;
    public String umbEn;


    public NB2B_StockCallOutResponseWrapper(Decimal availstk, String name, String product, String salesorg, Decimal totalstk, String umb, String umbEn){
        this.availstk=availstk;
        this.name=name;
        this.product=product;
        this.salesorg=salesorg;
        this.totalstk=totalstk;
        this.umb=umb;
        this.umbEn=umbEn;
    } 
 
}