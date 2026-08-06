@IsTest
public class Nb2b_ProductCarousel_Test {
    
    @TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupAllData();
	}

    @IsTest
	public static void getProductsInitialTest(){
		Test.startTest();
            getProductsInitial();
		Test.stopTest();
	}

    private static void getProductsInitial() {
        Nb2b_ProductCarousel.WrapperSalida test = new Nb2b_ProductCarousel.WrapperSalida();
        test.id = 'id';
        test.name = 'name';
        test.description = 'test';
        test.imagen = 'test';
        test.url = '#';
        test.textore = 'test';
        test.price = '0';

		List<Nb2b_ProductCarousel.WrapperSalida> result = Nb2b_ProductCarousel.getProductsInitial();
	}
}