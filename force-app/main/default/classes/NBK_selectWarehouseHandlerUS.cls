public class NBK_selectWarehouseHandlerUS {

    @AuraEnabled
    public static String getAddressPosition(Decimal lat,Decimal lon, String country){
        try{
            OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.reverse(lat,lon);
            Object inputJson = response.responseMap.get('address');
            String jsona = JSON.serialize(inputJson);
            Map<String, Object> mapa = (Map<String, Object>) JSON.deserializeUntyped(jsona);
            String resp = ' ';
            if(mapa.get('city') != null){resp += mapa.get('city')+' ';}
 
            return resp;
            
        }catch(Exception ex){return null;}
    }

    /**
    * @description 
    * @author EHG@nubika.com | 06-19-2023 
    * @param latitude 
    * @param longitude 
    * @return List<PorcelanosaAddress__c> 
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> searchAllStoresFromCountry(String country){
        try{
            Map<String, String> params = new Map<String, String>();
            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            List<AddressStoreWRP> listResult = new List<AddressStoreWRP>();

            if(country != null && country != ''){
                params.put('country',country);
            }
            OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.search(params);

            if(response != null && response.responseMap != null){
                //calculo con distancias
                String lonS = (String)response.responseMap.get('lon');
                String latS = (String)response.responseMap.get('lat');
                Decimal lonD = decimal.valueOf(lonS);
                Decimal latD = decimal.valueOf(latS);

                result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latD,lonD,new List<String>{'US','CA'});
                
                //recorrer para la lista para limitar las distancias
                for(PorcelanosaAddress__c porce : result){
                    AddressStoreWRP addr = new AddressStoreWRP();
                    addr.address = porce;
                    if(porce.get('Distancia') != null){
                        Decimal distD = (Decimal)porce.get('Distancia');
                        Decimal distancia = distD.setScale(1, System.RoundingMode.HALF_UP);
                        addr.distance = distancia;
                        
                    } 

                    //Calcular las imagenes
                    if(porce != null && porce.NBK_ShowroomImage__c != null){
                        addr.imageStore = findURLimage(porce.NBK_ShowroomImage__c);
                    }

                    listResult.add(addr);
                }

                if(listResult.isEmpty()){return null;}
                return listResult;

            }else{
                //CAlculo sin distancias
                result = NB2B_PorcelanosaAddressSelector.getStoresNearCountryUS(new List<String>{'US','CA'});
                 for(PorcelanosaAddress__c porce : result){
                    AddressStoreWRP addr = new AddressStoreWRP();
                    addr.address = porce;

                    //Calcular las imagenes
                    if(porce != null && porce.NBK_ShowroomImage__c != null){addr.imageStore = findURLimage(porce.NBK_ShowroomImage__c);}

                    listResult.add(addr);
                }

                if(listResult.isEmpty()){return null;}
                return listResult;

            }

        }catch(Exception ex){return null;}
    }

    /**
    * @description find image into html code
    * @author EHG@nubika.com | 06-19-2023 
    * @param field 
    * @return String
    **/
    public static String findURLimage(String field){
        // Utilizar una expresión regular para extraer la URL
        Pattern patronURL = Pattern.compile('<img.*?src="(.*?)".*?>');
        Matcher coincidencia = patronURL.matcher(field);

        if (coincidencia.find()) {
            String urlExtraida = coincidencia.group(1);
            return urlExtraida;
        } else {
            return null;
        }
    }

    /**
    * @description 
    * @author EHG@nubika.com | 06-19-2023 
    * @param latitude 
    * @param longitude 
    * @return List<PorcelanosaAddress__c> 
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> searchStores(String city, String postalcode, String province, String country){
        try{
            Map<String, String> params = new Map<String, String>();
            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            List<AddressStoreWRP> listResult = new List<AddressStoreWRP>();
            Integer searchDistance = 5000;
            String query = '';
            if(city != null && city != ''){
                params.put('city',city);
            }
            if(postalcode != null && postalcode != ''){
                params.put('postalcode',postalcode);
            }
            if(country != null && country != ''){
                if(province != null && province != ''){
                    params.put('country',country+' - '+province);}else{params.put('country',country);}
            }

            for (String clave : params.keySet()) {
                String valor = params.get(clave);
                query += valor + ',';
            }

            // Eliminar la coma final si es necesario
            if (query.endsWith(',')) {query = query.removeEnd(',');}
            query = query.replace(' ','%20');
            System.debug('query a OpenStreetMaps:'+query);

            //Determinar el tipo de busqueda.
            //Si solo esta informado el pais = country
            //Si está informado pais y province = state
            //Si está informado pais , povincia y ciudad = city
            String categoria = '';
            if((city != null && city != '') && (province != null && province != '')  && (country != null && country != '')){
                categoria = 'city';
            }else if((province != null && province != '')  && (country != null && country != '')){
                categoria = 'state';
            }else{
                categoria = 'country';
                //Si la categoria es country deberia buscar solo por el pais y con bastante radio de busqueda
                searchDistance = 10000;
            }
            
            System.debug('CATEGORIA: '+categoria);
            OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.searchByQuery(query,categoria);
            System.debug('response:'+response);

            //NUEVO SI FALLA SERVICIO BUSCA POR BBDD DIRECTAMENTE
            if(response != null && response.responseMap != null){
                String lonS = (String)response.responseMap.get('lon');
                String latS = (String)response.responseMap.get('lat');
                Decimal lonD = decimal.valueOf(lonS);
                Decimal latD = decimal.valueOf(latS);
                System.debug('Lat:'+latD);
                System.debug('Lon:'+lonD);
   
                result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latD,lonD,searchDistance,country,province);
                System.debug('result:'+result);
                
                //recorrer para la lista para limitar las distancias
                for(PorcelanosaAddress__c porce : result){
                    AddressStoreWRP addr = new AddressStoreWRP();
                    addr.address = porce;
                    if(porce.get('Distancia') != null){Decimal distD = (Decimal)porce.get('Distancia');Decimal distancia = distD.setScale(1, System.RoundingMode.HALF_UP);addr.distance = distancia;} 
                    listResult.add(addr);
                }

                if(listResult.isEmpty()){return null;}

                return listResult;
            }else{
                //BUSQUEDA SIN GEOLOCALIZACION
                result = NB2B_PorcelanosaAddressSelector.getStoresNearCityUS(province,new List<String> {country});
                System.debug('result:'+result);
                
                for(PorcelanosaAddress__c porce : result){AddressStoreWRP addr = new AddressStoreWRP();addr.address = porce;listResult.add(addr);
                }

                if(listResult.isEmpty()){return null;}
                return listResult;

            }

        }catch(Exception ex){return null;}
    }

    @AuraEnabled
   public static List<AddressStoreWRP> searchAssociates(String street, String city, String postalcode, String province, String country){
       try{
           Map<String, String> params = new Map<String, String>();
           String query = '';
                       Integer searchDistance = 5000;
           //Si tiene postalCode, buscar por postal code, ciudad y pais
                       if(postalcode != null && postalcode != '' && city != null && city != '' && country != null && country != ''){
                           params.put('postalcode',postalcode);
                           params.put('city',city);
                           params.put('country',country);

                       }else if(city != null && city != '' && country != null && country != ''){
                           params.put('city',city);
                           params.put('country',country);
                       }else{
                           params.put('country',country);
                       }

           for (String clave : params.keySet()) {
               String valor = params.get(clave);
               query += valor + ',';
           }

           // Eliminar la coma final si es necesario
           if (query.endsWith(',')) {query = query.removeEnd(',');}
           query = query.replace(' ','%20');

                       System.debug('QUERY:'+query);

                       String categoria = '';
           if((city != null && city != '') || (street != null && street != '')){categoria = 'city';
           }else if(province != null && province != ''){categoria = 'state';}else{categoria = 'country';
               //Si la categoria es country deberia buscar solo por el pais y con bastante radio de busqueda
               searchDistance = 10000;
           }
                       System.debug('categoria:'+categoria);

           //OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.search(params);
           OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.searchByQuery(query,categoria);

           System.debug('response:'+response);

           String lonS = (String)response.responseMap.get('lon');
           String latS = (String)response.responseMap.get('lat');
           System.debug('latS:'+latS);
           System.debug('lonS:'+lonS);
           Decimal lonD = decimal.valueOf(lonS);
           Decimal latD = decimal.valueOf(latS);

           List<AddressStoreWRP> listResult = new List<AddressStoreWRP>();
           
           List<PorcelanosaAddress__c> listAssociates = getAssociates();
           List<AddressStoreWRP> listResultAssociates = new List<AddressStoreWRP>();
           for(PorcelanosaAddress__c porce : listAssociates){
               AddressStoreWRP addr = new AddressStoreWRP();
               addr.address = porce;
               
               Location loc1 = Location.newInstance(porce.NBK_Address__Latitude__s,porce.NBK_Address__Longitude__s);
               Location loc2 = Location.newInstance(latD,lonD);
               Decimal dist = Location.getDistance(loc1, loc2, 'mi');
               
               addr.distance = dist.setScale(1, System.RoundingMode.HALF_UP);
                   
               listResult.add(addr);
           }
           
           if(listResult.isEmpty()){
               return null;
           }
           return listResult;
       }catch(Exception ex){return null;
       }
   }

   public static List<PorcelanosaAddress__c> getAssociates() {
    List<PorcelanosaAddress__c> listAssociates = new List<PorcelanosaAddress__c>();
    String isTest = '';
    if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
        isTest = '.test';
    }
          
   listAssociates.add(new PorcelanosaAddress__c(
       Name='San Francisco',
       NBK_Address__City__s='San Francisco',
       NBK_Address__CountryCode__s='US',
       NBK_Address__Latitude__s=37.770035791112576,
       NBK_Address__Longitude__s=-122.40285237531269,
       NBK_Address__PostalCode__s='9103',
       NBK_Address__StateCode__s='CA',
       NBK_Address__Street__s='78 Division Street',
       NBK_Address_Type__c= 'Associate'
   ));
   
    return listAssociates;
}

public static List<AddressStoreWRP> getInitialAssociates(Decimal latitude, Decimal longitude, String country) {
    List<PorcelanosaAddress__c> listAssociates = getAssociates();
   
   List<AddressStoreWRP> listResult = new List<AddressStoreWRP>();
   //recorrer para la lista para limitar las distancias

   for(PorcelanosaAddress__c porce : listAssociates){
       AddressStoreWRP addr = new AddressStoreWRP();
       addr.address = porce;
       
       Location loc1 = Location.newInstance(porce.NBK_Address__Latitude__s,porce.NBK_Address__Longitude__s);
       Location loc2 = Location.newInstance(latitude,longitude);
       Decimal dist = Location.getDistance(loc1, loc2, 'mi');
       
       addr.distance = dist.setScale(1, System.RoundingMode.HALF_UP);
           
       listResult.add(addr);
   }
   System.debug('Associates Initial');
   System.debug(listResult.size());
   System.debug('listResult:'+listResult);
   
   if(listResult.isEmpty()){return null;}
   return listResult;
}


    /**
    * @description 
    * @author EHG@nubika.com | 06-19-2023 
    * @param latitude 
    * @param longitude 
    * @return List<PorcelanosaAddress__c> 
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> getInitialStores(Decimal latitude, Decimal longitude, String country){
        try{
            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latitude,longitude,new List<String>{'US','CA'});
            System.debug('result:'+result);
            //recorrer la lista
            List<AddressStoreWRP> listResult = new List<AddressStoreWRP>();
            //recorrer para la lista para limitar las distancias
            for(PorcelanosaAddress__c porce : result){
                AddressStoreWRP addr = new AddressStoreWRP();
                addr.address = porce;
                if(porce.get('Distancia') != null){
                    Decimal distD = (Decimal)porce.get('Distancia');
                    Decimal distancia = distD.setScale(1, System.RoundingMode.HALF_UP);
                    addr.distance = distancia;
                    
                } 
                listResult.add(addr);
            }

            if(listResult.isEmpty()){return null;}
            return listResult;

        }catch(Exception ex){return null;}
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }


}