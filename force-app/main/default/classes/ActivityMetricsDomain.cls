/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		ActivityMetrics
* @description 	Activity Metrics Einstein domain class
*/
public class ActivityMetricsDomain extends zflib_TriggerDomainClass {

    public ActivityMetricsDomain() {
        super();
    }

    public ActivityMetricsDomain(List<ActivityMetric> metrics) {
        super(metrics);
    }

    public override zflib_TriggerDomainClass cast() {
        return (ActivityMetricsDomain) this;
    } 

    public override Type getSObjectType() {
        return ActivityMetricsDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/

    public override void onAfterInsert() {
        List<ActivityMetric> metricsToUpdate = new List<ActivityMetric>();
        
        for (ActivityMetric metric : (List<ActivityMetric>) this.Records) {
            if (metric.LastEmailDateTime != null) {
                metricsToUpdate.add(metric);
            }
        }
        ActivityDateService.updateFromActivityMetrics(metricsToUpdate);
        
        
    } //onAfterInsert
    
    public override void onAfterUpdate(Map<Id,SObject> existingRecords) {
        List<ActivityMetric> metricsToUpdate = new List<ActivityMetric>();
        
        for (ActivityMetric metric : (List<ActivityMetric>) this.Records) {            
            if (metric.LastEmailDateTime != null && metric.LastEmailDateTime != ((ActivityMetric) existingRecords.get(metric.Id)).LastEmailDateTime) {
                metricsToUpdate.add(metric);
            }
        }
        ActivityDateService.updateFromActivityMetrics(metricsToUpdate);
        
    } //onAfterUpdate
}