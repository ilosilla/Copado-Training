/**
 * Description: Class used to search the OpenStreetMap dataset using Nominatim API.
 *              API Documentation: https://nominatim.org/release-docs/develop/api/Overview/
 *
 * Verson: 2.0.0
 */
public with sharing class OpenStreetMapAPI {
    /**
     * Description: Inner class to store the API callout response
     *              and provide methods to return the response
     *              in different format as per the requirement.
     *
     * Properties:  responseMap {Map<String, Object>} - API callout response data
     *
     * Methods:     1) asMap {Map<String, Object>} - returns the response
     *              as Map<String, Object> to be used in Apex Class
     *
     *              2) asJSONString {String} - returns the response as String
     *              to be used in Lightning component JavaScript method
     */
    public class OpenStreetMapAPIResponse {
        public Map<String, Object> responseMap;

        public Map<String, Object> asMap() {
            return this.responseMap;
        }

        public String asJSONString() {
            return JSON.serialize(this.responseMap);
        }
    }

    /**
     * Description: Method to perform search on OpenStreetMap dataset.
     *
     * Parameters:  params {Map<String, String>} - Map of query parameters
     *              to be used in the URI enpoint to perform search.
     *
     *              Example:
     *              new Map<String, String> {
     *                  'city' => 'Kolkata',
     *                  'country' => 'India'
     *              }
     *
     * Return Type: Instance of the class OpenStreetMapAPIResponse which contains
     *              the response data in responseMap property.
     */
    public static OpenStreetMapAPIResponse search(Map<String, String> params) {
        try {
            String endPoint = generateURIEndpoint(params);
            return call(new OpenStreetMapAPIResponse(), endPoint,'country');
        } catch (Exception ex) {
            // TODO: Handle exception
            return new OpenStreetMapAPIResponse();
        }
    }

    public static OpenStreetMapAPIResponse searchByQuery(String query,String cat) {
        try {
            System.debug('searchByQuery');
            String endPoint = generateURIEndpoint(query);
            OpenStreetMapAPIResponse resp = call(new OpenStreetMapAPIResponse(), endPoint,cat);
            return resp;

        } catch (Exception ex) {
            return new OpenStreetMapAPIResponse();
        }
    }

		public static OpenStreetMapAPIResponse searchByQueryUK(String query,String cat) {
			try {
					System.debug('searchByQueryUK');
					String endPoint = generateURIEndpoint(query);
					OpenStreetMapAPIResponse resp = callUK(new OpenStreetMapAPIResponse(), endPoint,cat);
					return resp;

			} catch (Exception ex) {
					return new OpenStreetMapAPIResponse();
			}
	}

	public static OpenStreetMapAPIResponse searchByQueryFR(String query,String cat) {
		try {
				System.debug('searchByQueryUK');
				String endPoint = generateURIEndpoint(query);
				OpenStreetMapAPIResponse resp = callFR(new OpenStreetMapAPIResponse(), endPoint,cat);
				return resp;

		} catch (Exception ex) {
				return new OpenStreetMapAPIResponse();
		}
}


    public static OpenStreetMapAPIResponse reverse(Decimal lat, Decimal lon) {
        try {
            String endPoint = generateURIEndpointreverse(lat,lon);
            return callreverse(new OpenStreetMapAPIResponse(), endPoint);
        } catch (Exception ex) {
            // TODO: Handle exception
            return new OpenStreetMapAPIResponse();
        }
    }

    /**
     * Description: Method to perform the actual API callout to the Nominatim API
     *
     * Parameters:  1) apiResponse {OpenStreetMapAPIResponse} - instance of the class
     *              OpenStreetMapAPIResponse to store the API callout response
     *
     *              2) endPoint {String} - URI endpoint for GET request
     *
     * Return Type: Instance of the class OpenStreetMapAPIResponse which contains
     *              the response data in responseMap property.
     */
    public static OpenStreetMapAPIResponse call(OpenStreetMapAPIResponse apiResponse,String endPoint,String cat) {

        Map<String, Object> responseMap = new Map<String, Object>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod(OpenStreetMapConstants.METHOD_GET);
        request.setEndpoint(endPoint);
        request.setHeader(
            OpenStreetMapConstants.CONTENT_TYPE,
            OpenStreetMapConstants.APPLICATION_JSON
        );
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == OpenStreetMapConstants.SUCCESS_STATUS_CODE) {
            String inputJson = response.getBody();

            List<Object> responseList = (List<Object>) JSON.deserializeUntyped(
                inputJson
            );
            Decimal maxImport = 0;
            for (Object respObj : responseList) {
                //Tener en cuenta la categoria de la busqueda
                Map<String, Object> mapaAux = (Map<String, Object>) respObj;

                //Este filtro solo lo tiene que hacer cuando cat != city
                if(cat != 'city'){
                    String catResul = (String)mapaAux.get('addresstype');
                    if(cat != null && catResul != null && catResul == cat){
                        //filtramos por categoria
                        Decimal actImport = (Decimal)mapaAux.get('importance');
                        if(actImport > maxImport){
                            maxImport = actImport;
                        }
                    }
                }else{ // SI es igual a city no tiene en cuenta la cat
                    Decimal actImport = (Decimal)mapaAux.get('importance');
                    if(actImport > maxImport){
                        maxImport = actImport;
                    }
                }

            }
            for (Object respObj : responseList) {
                Map<String, Object> mapaAux = (Map<String, Object>) respObj;
                Decimal actImport = (Decimal)mapaAux.get('importance');
                if(actImport == maxImport){
                    if(cat != 'city'){
                        String catResul = (String)mapaAux.get('addresstype');
                        if(cat != null && catResul != null && catResul == cat){
                            responseMap = (Map<String, Object>) respObj;
                        }
                    }else{
                        responseMap = (Map<String, Object>) respObj;
                    }
                }
            }

            if (responseMap != null) {
                apiResponse.responseMap = responseMap;
            }
        } else {
            apiResponse.responseMap = new Map<String, Object>();
        }
        System.debug('apiresonpse:'+apiResponse);
        return apiResponse;
    }

		public static OpenStreetMapAPIResponse callUK(OpenStreetMapAPIResponse apiResponse,String endPoint,String cat) {
        System.debug('callUK');
				System.debug('cat:'+cat);
				System.debug('endPoint:'+endPoint);
        Map<String, Object> responseMap = new Map<String, Object>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod(OpenStreetMapConstants.METHOD_GET);
        request.setEndpoint(endPoint);
        request.setHeader(
            OpenStreetMapConstants.CONTENT_TYPE,
            OpenStreetMapConstants.APPLICATION_JSON
        );
        HttpResponse response = http.send(request);
        System.debug('response.getBody():'+response.getBody());

        if (
            response.getStatusCode() ==
            OpenStreetMapConstants.SUCCESS_STATUS_CODE
        ) {
            String inputJson = response.getBody();

            List<Object> responseList = (List<Object>) JSON.deserializeUntyped(
                inputJson
            );
           System.debug('RECORRIENDO RESULTADOS:');
            Decimal maxImport = 0;
            for (Object respObj : responseList) {
                System.debug('respObj:'+respObj);
                //Tener en cuenta la categoria de la busqueda
                Map<String, Object> mapaAux = (Map<String, Object>) respObj;
                System.debug('importancia:'+(Decimal)mapaAux.get('importance'));

                //Este filtro solo lo tiene que hacer cuando cat != city
                if(cat != 'city'){
                    System.debug('addresstype:'+mapaAux.get('addresstype'));
                    String catResul = (String)mapaAux.get('addresstype');
                    if(cat != null && catResul != null && catResul == cat){
                        //filtramos por categoria
                        Decimal actImport = (Decimal)mapaAux.get('importance');
                        System.debug('actImport:'+actImport);
                        if(actImport > maxImport){
                            maxImport = actImport;
                        }
                    }
                }else{ // SI es igual a city no tiene en cuenta la cat
                    Decimal actImport = (Decimal)mapaAux.get('importance');
                    System.debug('actImport:'+actImport);
                    if(actImport > maxImport){
                        maxImport = actImport;
                    }
                }

            }
            System.debug('maxImport:'+maxImport);
            for (Object respObj : responseList) {
                Map<String, Object> mapaAux = (Map<String, Object>) respObj;
                Decimal actImport = (Decimal)mapaAux.get('importance');
                if(actImport == maxImport){
                    if(cat != 'city'){
                        String catResul = (String)mapaAux.get('addresstype');
                        if(cat != null && catResul != null && catResul == cat){
                            responseMap = (Map<String, Object>) respObj;
                        }
                    }else{
                        responseMap = (Map<String, Object>) respObj;
                    }
                }
            }



            if (responseMap != null) {
                apiResponse.responseMap = responseMap;
            }
        } else {
            apiResponse.responseMap = new Map<String, Object>();
        }
        System.debug('apiresonpse:'+apiResponse);
        return apiResponse;
    }

		public static OpenStreetMapAPIResponse callFR(OpenStreetMapAPIResponse apiResponse,String endPoint,String cat) {
			System.debug('callUK');
			System.debug('cat:'+cat);
			System.debug('endPoint:'+endPoint);
			Map<String, Object> responseMap = new Map<String, Object>();

			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setMethod(OpenStreetMapConstants.METHOD_GET);
			request.setEndpoint(endPoint);
			request.setHeader(
					OpenStreetMapConstants.CONTENT_TYPE,
					OpenStreetMapConstants.APPLICATION_JSON
			);
			HttpResponse response = http.send(request);
			System.debug('response.getBody():'+response.getBody());

			if (
					response.getStatusCode() ==
					OpenStreetMapConstants.SUCCESS_STATUS_CODE
			) {
					String inputJson = response.getBody();

					List<Object> responseList = (List<Object>) JSON.deserializeUntyped(
							inputJson
					);
				 System.debug('RECORRIENDO RESULTADOS:');
					Decimal maxImport = 0;
					for (Object respObj : responseList) {
							System.debug('respObj:'+respObj);
							//Tener en cuenta la categoria de la busqueda
							Map<String, Object> mapaAux = (Map<String, Object>) respObj;
							System.debug('importancia:'+(Decimal)mapaAux.get('importance'));

							//Este filtro solo lo tiene que hacer cuando cat != city
							if(cat != 'city'){
									System.debug('addresstype:'+mapaAux.get('addresstype'));
									String catResul = (String)mapaAux.get('addresstype');
									if(cat != null && catResul != null && catResul == cat){
											//filtramos por categoria
											Decimal actImport = (Decimal)mapaAux.get('importance');
											System.debug('actImport:'+actImport);
											if(actImport > maxImport){
													maxImport = actImport;
											}
									}
							}else{ // SI es igual a city no tiene en cuenta la cat
									Decimal actImport = (Decimal)mapaAux.get('importance');
									System.debug('actImport:'+actImport);
									if(actImport > maxImport){
											maxImport = actImport;
									}
							}

					}
					System.debug('maxImport:'+maxImport);
					for (Object respObj : responseList) {
							Map<String, Object> mapaAux = (Map<String, Object>) respObj;
							Decimal actImport = (Decimal)mapaAux.get('importance');
							if(actImport == maxImport){
									if(cat != 'city'){
											String catResul = (String)mapaAux.get('addresstype');
											if(cat != null && catResul != null && catResul == cat){
													responseMap = (Map<String, Object>) respObj;
											}
									}else{
											responseMap = (Map<String, Object>) respObj;
									}
							}
					}



					if (responseMap != null) {
							apiResponse.responseMap = responseMap;
					}
			} else {
					apiResponse.responseMap = new Map<String, Object>();
			}
			System.debug('apiresonpse:'+apiResponse);
			return apiResponse;
	}



    public static OpenStreetMapAPIResponse callreverse(
        OpenStreetMapAPIResponse apiResponse,
        String endPoint
    ) {
        Map<String, Object> responseMap = new Map<String, Object>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod(OpenStreetMapConstants.METHOD_GET);
        request.setEndpoint(endPoint);
        request.setHeader(
            OpenStreetMapConstants.CONTENT_TYPE,
            OpenStreetMapConstants.APPLICATION_JSON
        );
        HttpResponse response = http.send(request);

        if (
            response.getStatusCode() ==
            OpenStreetMapConstants.SUCCESS_STATUS_CODE
        ) {
            String inputJson = response.getBody();

            Object responseList = (Object) JSON.deserializeUntyped(
                inputJson
            );
            responseMap = (Map<String, Object>) responseList;

            if (responseMap != null) {
                apiResponse.responseMap = responseMap;
            }
        } else {
            apiResponse.responseMap = new Map<String, Object>();
        }
        System.debug('apiresonpse:'+apiResponse);
        return apiResponse;
    }

    /**
     * Description: Method to convert the query parameter passed as
     *              Map<String, String> to String to be used in request URI
     *
     * Parameters:  params {Map<String, String>} - Map of query parameters
     *              to be used in the URI enpoint to perform search.
     *
     *              Example:
     *              new Map<String, String> {
     *                  'city' => 'Kolkata',
     *                  'country' => 'India'
     *              }
     *
     * Return Type: query String.
     *
     *              Example: The above input returns the below output:
     *              https://nominatim.openstreetmap.org/search?city=Kolkata&country=India&format=jsonv2&limit=1&accept-language=en-US
     */
    public static String generateURIEndpoint(Map<String, String> params) {
        String endPoint = 'https://nominatim.openstreetmap.org/search?';
        Set<String> paramSet = new Set<String>();
        List<String> paramList = new List<String>();
        if (params != null) {
            for (String param : params.keySet()) {
                if (
                    param != null &&
                    params.get(param) != null &&
                    OpenStreetMapConstants.AVAILABLE_QUERY_PARAMS.contains(
                        param.toLowerCase()
                    )
                ) {
                    String p =
                        param.toLowerCase() +
                        '=' +
                        (params.get(param)).toLowerCase();
                    paramSet.add(p);
                }
            }
        }
        if (paramSet.size() > 0) {
            paramList.addAll(paramSet);
            endPoint += String.join(paramList, '&');
            endPoint += OpenStreetMapConstants.URL_SUFFIX;
        }
        return endPoint;
    }

    public static String generateURIEndpoint(String query) {
        return 'https://nominatim.openstreetmap.org/search?q='+query+'&format=json';
    }

    public static String generateURIEndpointreverse(Decimal lat, Decimal lon) {
        String endPoint = 'https://nominatim.openstreetmap.org/reverse?lat='+lat+'&lon='+lon;
        endPoint += OpenStreetMapConstants.URL_SUFFIX;
        return endPoint;
    }
}