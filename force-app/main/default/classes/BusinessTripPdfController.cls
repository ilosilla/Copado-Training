/**
* @author Ivan Losilla
* @date October 2025
* @group Reports
* @test BusinessTripControllerTest
*/
public class BusinessTripPdfController {
    public BusinessTrip__c header { get; set; }

    // Wrappers para iterar en PDF
    public List<BusinessTripController.BusinessTripVisitWrapper> visitWrappers { get; set; }
    public List<BusinessTripController.BusinessTripStrategyWrapper> strategyWrappers { get; set; }
    public Map<Id, List<ContentDocumentLink>> files { get; set; }
    public String baseUrl { get; set; }

    public BusinessTripPdfController() {
        String tripIdParam = ApexPages.currentPage().getParameters().get('tripId');

        if (String.isBlank(tripIdParam) == false) {
            BusinessTripController.businesssTripData trip = BusinessTripController.getBusinessTrip(tripIdParam);

            // Wrappers
            visitWrappers = trip.visits;
            strategyWrappers = trip.strategies;
            header = trip.header;
            files = trip.fileLinks;
            baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        }
    }
}