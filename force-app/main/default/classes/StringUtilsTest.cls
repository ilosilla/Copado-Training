@isTest public  class StringUtilsTest {
    @isTest public static void toUpperCase() {
        String result = StringUtils.toUpperCase('text');
        System.assertEquals('TEXT', result);
    }

    @isTest public static void splitName1() {
        String name = 'Porras';
        Map<String, String> result = new Map<String, String>();        
        result = StringUtils.splitName(name);
        String lastName = result.get('lastName');
        System.assertEquals('Porras', lastName);
    }

    @isTest public static void splitName2() {
        String name = 'Paco Porras';
        Map<String, String> result = new Map<String, String>();        
        result = StringUtils.splitName(name);
        String firstName = result.get('firstName');
        String lastName = result.get('lastName');
        System.assertEquals('Paco', firstName);
        System.assertEquals('Porras', lastName);
    }

    @isTest public static void splitName3() {
        String name = 'Paco Manuel Porras';
        Map<String, String> result = new Map<String, String>();        
        result = StringUtils.splitName(name);
        String firstName = result.get('firstName');
        String lastName = result.get('lastName');
        System.assertEquals('Paco Manuel', firstName);
        System.assertEquals('Porras', lastName);
    }

    @isTest public static void splitName4() {
        String name = 'Paco Manuel Porras Martín';
        Map<String, String> result = new Map<String, String>();        
        result = StringUtils.splitName(name);
        String firstName = result.get('firstName');
        String lastName = result.get('lastName');
        System.assertEquals('Paco Manuel', firstName);
        System.assertEquals('Porras Martín', lastName);
    }

} // class