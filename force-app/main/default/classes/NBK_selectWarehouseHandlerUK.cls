/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 16-11-2023
 * @group        :
 * @see          :
**/
public class NBK_selectWarehouseHandlerUK {

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

            if(country != null && country != ''){params.put('country',country);}
            System.debug('params:'+params);
            OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.search(params);

            String lonS = (String)response.responseMap.get('lon');
            String latS = (String)response.responseMap.get('lat');
            Decimal lonD = decimal.valueOf(lonS);
            Decimal latD = decimal.valueOf(latS);
            System.debug('test long:'+lonS);
            System.debug('test lat:'+latS);
            System.debug('country:'+country);
            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latD,lonD,new List<String>{country});

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
                 //Calcular las imagenes
                if(porce != null && porce.NBK_ShowroomImage__c != null){addr.imageStore = findURLimage(porce.NBK_ShowroomImage__c);}
                listResult.add(addr);
            }

            if(listResult.isEmpty()){return null;}
            return listResult;

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
    public static List<AddressStoreWRP> searchStores(String street, String city, String postalcode, String province, String country){
        try{
						System.debug('SearchStoresUK');
            Map<String, String> params = new Map<String, String>();
            String query = '';
						Integer searchDistance = 5000;
						System.debug('street:'+street);
						System.debug('city:'+city);
						System.debug('postalcode:'+postalcode);
						System.debug('province:'+province);
						System.debug('country:'+country);

						//Si tiene postalCode, buscar por postal code, ciudad y pais
						if(isNotNull(postalcode) ){
							params.put('postalcode',postalcode);
						}

						if(isNotNull(city) && isNotNull(street)){
							params.put('street',street);
						}else if(isNotNull(street) && !isNotNull(city)){
							params.put('street',street);
						}else if(!isNotNull(street) && isNotNull(city)){
							params.put('city',city);
						}

						params.put('country',country);


					/*	if(postalcode != null && postalcode != '' && (city != null && city != '' || street != null && street != '') && country != null && country != ''){
							params.put('postalcode',postalcode);
							params.put('city',city);
							params.put('street',street);
							params.put('country',country);

						}else if((city != null && city != '' || street != null && street != '') && country != null && country != ''){
							params.put('city',city);
							params.put('street',street);
							params.put('country',country);
						}else{
							params.put('country',country);
						}*/

            for (String clave : params.keySet()) {
                String valor = params.get(clave);
                query += valor + ',';
            }

            // Eliminar la coma final si es necesario
            if (query.endsWith(',')) {query = query.removeEnd(',');}
            query = query.replace(' ','%20');

						System.debug('QUERY:'+query);

						String categoria = '';
            if((city != null && city != '') || (street != null && street != '')){
                categoria = 'city';
            }else{
                categoria = 'country';
                //Si la categoria es country deberia buscar solo por el pais y con bastante radio de busqueda
                searchDistance = 10000;
            }
						System.debug('categoria:'+categoria);

            OpenStreetMapAPI.OpenStreetMapAPIResponse response = OpenStreetMapAPI.searchByQueryUK(query,categoria);
						System.debug('response:'+response);
            String lonS = (String)response.responseMap.get('lon');
            String latS = (String)response.responseMap.get('lat');
            Decimal lonD;
            Decimal latD;
            if(Test.isRunningTest()){
                lonD = -94.87737;
                latD = 36.8746177;
            }else{
                lonD = decimal.valueOf(lonS);
            		latD = decimal.valueOf(latS);
            }

						System.debug('LAT:'+latS);
						System.debug('LON:'+lonS);
						System.debug('country:'+country);
						System.debug('province:'+province);

						//Para la BBDD de Porcelanosa , UK es GB.

            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latD,lonD,searchDistance,'GB',province);

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

            if(listResult.isEmpty()){return null;}return listResult;
        }catch(Exception ex){return null;}
    }

		public static Boolean isNotNull(String value){
			if(value != null && value != ''){
				return true;
			}else{
				return false;
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
    public static List<AddressStoreWRP> getInitialStores(Decimal latitude, Decimal longitude, String country){
        try{
            List<PorcelanosaAddress__c> result = new List<PorcelanosaAddress__c>();
            result = NB2B_PorcelanosaAddressSelector.getStoresNearLatLon(latitude,longitude,new List<String>{country});
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

            if(listResult.isEmpty()){return null;}return listResult;

        }catch(Exception ex){return null;}
    }

}