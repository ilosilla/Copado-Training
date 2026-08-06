/**
* @author 		Ramón Prades
* @date 		March 2023
* @group 		Prices
* @description 	Schedules some price-related tasks
*/
public with sharing class BatchPriceScheduler implements Schedulable {
    public BatchPriceScheduler() {
    }

    public void execute(SchedulableContext context) {
        BatchPriceCleaner.executeInBatch();
    }
}