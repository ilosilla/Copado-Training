public with sharing class BusinessTripTransformRequest {
    @InvocableMethod(label='Request Trip to Trip Clone')
    public static List<Results> cloneToTripInvocable(List<String> tripIds) {
        List<Results> results = new List<Results>();

        String tripId = tripIds[0];
        //Create a Results object to hold the return values
        Results result = new Results();
        result.outputMember = BusinessTripController.cloneToTrip(tripId);
        results.add(result);
        return results;
    }

    public class Results {
        @InvocableVariable(label='Records for Output' description='yourDescription' required=true)
        public String outputMember;
    }
}