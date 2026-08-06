/**
* @author 		Ramón Prades
* @date 		January 2022
* @group 		Utils
* @description 	Mockup generator para poder probar los métos de SAPAddressHelper que llaman a SAP
*/
@isTest global class SAPAddressHelperMockupTest implements HttpCalloutMock {
    
    // GET
    global HttpResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token', 'x111ds');
        res.setHeader('set-cookie', 'x111ds');
        String url = req.getEndpoint();

        // GET 
        if (req.getMethod() == 'GET') {
            // If string 9999999 is in url, raise error. Otherwise, empty list
            if (url.indexOf('9999999') >= 0) {
                res.setStatusCode(404);        
            } else  {
                List<SAPAddressHelper.AddressDTO> l = new List<SAPAddressHelper.AddressDTO>(); 
                SAPAddressHelper.AddressDTO dto = new SAPAddressHelper.AddressDTO();
                dto.addresstype = 'D';
                dto.city = 'BUSHEY';
                dto.countrycode = 'GB';
                dto.email = 'rxxxx@porcelanosa.cxm';
                dto.mobile = '111 222 111';
                dto.name = 'WATKIN JONES HOMES';
                dto.phone = '666 000 222';
                dto.postalcode = 'RG1 8BN';
                dto.sapid = '0005109559';
                dto.street = 'KINGS MEADOW ROAD';                
                l.add(dto);                
                res.setBody(JSON.serialize(l));
                res.setStatusCode(200);    
            }
        } 
        
        if (req.getMethod() == 'POST' || req.getMethod() == 'PUT') {
            if (url.containsIgnoreCase('/register')) {
                if (url.indexOf('9999999') >= 0) {
                    res.setStatusCode(400);
                } else {
                    res.setStatusCode(201);
                }
                return res;
            }
            if (url.indexOf('9999999') >= 0) {
                res.setStatusCode(404);        
            } else  {
                ContactPointAddress cp = (ContactPointAddress) JSON.deserialize(req.getBody(), ContactPointAddress.class); 
                if (String.isNotBlank(cp.Name)) {
                    System.debug('RETORNO ESTA ADDRESS ' + JSON.serialize(cp));
                    res.setBody(JSON.serialize(cp));
                    res.setStatusCode(200);    
                } else {
                    res.setStatusCode(400);    
                }
            }
        }

        if (req.getMethod() <> 'GET' && req.getMethod() <> 'POST' && req.getMethod() <> 'PUT') {
            res.setStatusCode(500);    
        }

        return res;

    } // respond
} // class