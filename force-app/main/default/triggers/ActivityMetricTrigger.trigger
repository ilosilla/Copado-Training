trigger ActivityMetricTrigger on ActivityMetric (after update, after insert) {
    zflib_TriggerDomainClass.triggerHandler(ActivityMetricsDomain.class);
}