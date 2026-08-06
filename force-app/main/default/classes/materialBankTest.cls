/**
* @author 		Ramón Prades
* @date 		$CURRENT_MONTH_NAME $CURRENT_YEAR
* @group 		Accounts
* @description 	Enter a description con variable ${fileExtname}
*/
@isTest public with sharing class materialBankTest {

    @isTest private static void test1() {
        String content = '<?xml version="1.0"?> <root> <row> <CONSIGNEE>7936</CONSIGNEE> <CREATEDATE>05-10-2022 02:53:55</CREATEDATE> <row> <ORDERDATE>2022-05-08</ORDERDATE> <ORDERED1NAME>Mark Franzen</ORDERED1NAME> <SHIPPED1NAME>Linda Mares Titus</SHIPPED1NAME> <EntityId>123099</EntityId> <CONTACT1EMAIL>mfranzen@porcelanosa-usa.com</CONTACT1EMAIL> <SHIPPED1EMAIL>linda.mares.titus@gmail.com</SHIPPED1EMAIL> <CONTACT1PHONE>206-265-1150</CONTACT1PHONE> <STREET1>55700 Pinehurst</STREET1> <Company>LMT Design</Company> <City>La Quinta</City> <State>California</State> <Zip>92253-4721</Zip> <CompanyPractice>Manufacturer/Distributor</CompanyPractice> <Title>Account Executive</Title> <row> <ORDERID>0012587211212</ORDERID> <TRACKINGNO>272906133528</TRACKINGNO> <row> <ProjectName>LMT Design</ProjectName> <QTYORIGINAL>1.0000</QTYORIGINAL> <SKU>100213694</SKU> <Name>Aqua</Name> <MBShipped>Y</MBShipped> <MBSKU>100396934</MBSKU> <SerialSKU/> <Color>Green</Color> <ProjectType>Residential</ProjectType> <ProjectPhase>Concept Design</ProjectPhase> <ProjectDescription>Designer is selecting tile for their home in CA- lives in Tacoma Wa though.</ProjectDescription> </row> <row> <ProjectName>LMT Design</ProjectName> <QTYORIGINAL>1.0000</QTYORIGINAL> <SKU>100213723</SKU> <Name>Aqua</Name> <MBShipped>Y</MBShipped> <MBSKU>100396935</MBSKU> <SerialSKU/> <Color>Blue</Color> <ProjectType>Residential</ProjectType> <ProjectPhase>Concept Design</ProjectPhase> <ProjectDescription>Designer is selecting tile for their home in CA- lives in Tacoma Wa though.</ProjectDescription> </row> <row> <ProjectName>LMT Design</ProjectName> <QTYORIGINAL>1.0000</QTYORIGINAL> <SKU>100272795</SKU> <Name>Crystal</Name> <MBShipped>Y</MBShipped> <MBSKU>100209972</MBSKU> <SerialSKU/> <Color>Blue</Color> <ProjectType>Residential</ProjectType> <ProjectPhase>Specification</ProjectPhase> <ProjectDescription>Designer is selecting tile for their home in CA- lives in Tacoma Wa though.</ProjectDescription> </row> <row> <ProjectName>LMT Design</ProjectName> <QTYORIGINAL>1.0000</QTYORIGINAL> <SKU>100272796</SKU> <Name>Crystal</Name> <MBShipped>Y</MBShipped> <MBSKU>100209975</MBSKU> <SerialSKU/> <Color>Navy</Color> <ProjectType>Residential</ProjectType> <ProjectPhase>Specification</ProjectPhase> <ProjectDescription>Designer is selecting tile for their home in CA- lives in Tacoma Wa though.</ProjectDescription> </row> </row> <MOBILEPHONE/> <CONTACTPREFERENCE>Any</CONTACTPREFERENCE> <RELATEDPRODUCTS/> <SHIPPINGMETHOD>FedEx Priority Overnight</SHIPPINGMETHOD> </row> </row> </root>';
        MaterialBankParser parser = new MaterialBankParser();
        parser.content = content;
        parser.fileName = 'FICHERIN';
        parser.parse();
        parser.execute();
    }
}