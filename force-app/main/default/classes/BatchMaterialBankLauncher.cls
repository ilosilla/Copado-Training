public class BatchMaterialBankLauncher implements Schedulable, Database.AllowsCallouts {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new BatchMaterialBankImporter());
    }
}