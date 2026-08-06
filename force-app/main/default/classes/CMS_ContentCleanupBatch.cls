/**
 * @author         Ramón Prades
 * @date           March 2026
 * @group          CMS
 *
 * Class: CMS_ContentCleanupBatch
 *
 * Purpose:
 *   Lists CMS content from a workspace, shows whether it is published and how many
 *   ProductMedia records reference it, and optionally unpublishes and deletes
 *   orphan content.
 *
 * Notes:
 *   - The batch always reads content from a single workspace.
 *   - Orphan content means ProductMedia usage count = 0.
 *   - Unpublish and delete actions are only attempted for orphan content.
 *   - Delete is performed at variant level through ConnectApi.ManagedContent.deleteManagedContentVariant(...).
 */
global class CMS_ContentCleanupBatch implements Database.Batchable<String>, Database.Stateful {

    public static final String MODE_LIST_ONLY = 'LIST_ONLY';
    public static final String MODE_UNPUBLISH_ONLY = 'UNPUBLISH_ONLY';
    public static final String MODE_DELETE = 'DELETE';
    //public static final String MODE_UNPUBLISH_AND_DELETE = MODE_DELETE;

    private static final Integer BATCH_SIZE = 10;
    private static final String LOG_SCENARIO = 'PIM';
    private static final String LOG_TAG = 'PIM Images Cleanup';

    private Id workspaceId;
    private Datetime beforeDate;
    private String mode;
    private Integer maxItems;
    private SystemLog logger;

    private Integer totalContentsRead = 0;
    private Integer totalOrphans = 0;
    private Integer totalUnpublished = 0;
    private Integer totalDeletedVariants = 0;
    private Integer totalErrors = 0;

    private List<ResultRowDTO> resultRows = new List<ResultRowDTO>();

    @TestVisible private List<String> testContentIds;
    @TestVisible private Map<String, String> testContentNamesById;
    @TestVisible private Map<String, Integer> testUsageCountByContentId;
    @TestVisible private Map<String, String> testPublishedStatusByContentId;
    @TestVisible private Map<String, List<String>> testVariantIdsByContentId;
    @TestVisible private List<ManagedContent> testWorkspaceContents;
    @TestVisible private List<ManagedContent> testNamedContents;
    @TestVisible private Set<String> testUnpublishedContentIds = new Set<String>();
    @TestVisible private Set<String> testDeletedVariantIds = new Set<String>();
    @TestVisible private Set<String> testUnpublishErrorContentIds = new Set<String>();
    @TestVisible private Set<String> testDeleteErrorVariantIds = new Set<String>();

    global static void executeBatch(Id workspaceId) {
        Database.executeBatch(new CMS_ContentCleanupBatch(workspaceId), BATCH_SIZE);
    }

    global static void executeBatch(Id workspaceId, Datetime beforeDate, String mode, Integer maxItems) {
        Database.executeBatch(new CMS_ContentCleanupBatch(workspaceId, beforeDate, mode, maxItems), BATCH_SIZE);
    }

    global CMS_ContentCleanupBatch(Id workspaceId) {
        this(workspaceId, null, MODE_LIST_ONLY, null);
    }

    global CMS_ContentCleanupBatch(Id workspaceId, Datetime beforeDate, String mode, Integer maxItems) {
        this.workspaceId = workspaceId;
        this.beforeDate = beforeDate;
        this.mode = String.isBlank(mode) ? MODE_LIST_ONLY : mode.trim().toUpperCase();
        if (this.mode == 'UNPUBLISH_AND_DELETE') {
            this.mode = MODE_DELETE;
        }
        this.maxItems = maxItems;
        this.logger = new SystemLog(LOG_SCENARIO);
        this.logger.setTag(LOG_TAG);
    }

    global Iterable<String> start(Database.BatchableContext bc) {
        List<String> contentIds = this.loadWorkspaceContentIds();
        return contentIds;
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        Map<String, String> contentNamesById = this.loadContentNames(scope);
        Map<String, Integer> usageCountByContentId = this.loadUsageCount(scope);
        Map<String, String> publishedStatusByContentId = this.loadPublishedStatus(scope);
        Map<String, List<String>> variantIdsByContentId = this.loadVariantIds(scope);

        for (String contentId : scope) {
            this.totalContentsRead++;

            ResultRowDTO row = new ResultRowDTO();
            row.contentId = contentId;
            row.name = contentNamesById.get(contentId);
            row.title = row.name;
            row.publishedStatus = publishedStatusByContentId.containsKey(contentId)
                ? publishedStatusByContentId.get(contentId)
                : 'Unknown';
            row.usageCount = usageCountByContentId.containsKey(contentId)
                ? usageCountByContentId.get(contentId)
                : 0;

            List<String> variantIds = variantIdsByContentId.get(contentId);
            if (variantIds == null) {
                variantIds = new List<String>();
            }

            if (row.usageCount == 0) {
                this.totalOrphans++;
            }

            if (this.mode != MODE_LIST_ONLY && row.usageCount == 0) {
                if (this.isAlreadyUnpublished(row.publishedStatus)) {
                    row.unpublishResult = 'ALREADY_UNPUBLISHED';
                } else {
                    try {
                        this.unpublishContent(contentId);
                        row.unpublishResult = 'OK';
                        this.totalUnpublished++;
                    } catch (Exception ex) {
                        row.unpublishResult = 'ERROR: ' + ex.getMessage();
                        this.totalErrors++;
                        this.logger.addError('Error unpublishing content ' + contentId + ' (' + row.name + ')');
                        this.logger.addError(ex);
                    }
                }

                if (
                    this.mode == MODE_DELETE &&
                    (row.unpublishResult == 'OK' || row.unpublishResult == 'ALREADY_UNPUBLISHED')
                ) {
                    Integer deleted = 0;
                    List<String> deleteErrors = new List<String>();

                    for (String variantId : variantIds) {
                        try {
                            this.deleteVariant(variantId);
                            deleted++;
                            this.totalDeletedVariants++;
                        } catch (Exception ex) {
                            deleteErrors.add(ex.getMessage());
                            this.totalErrors++;
                            this.logger.addError('Error deleting variant ' + variantId + ' for content ' + contentId);
                            this.logger.addError(ex);
                        }
                    }

                    if (variantIds.isEmpty()) {
                        row.deleteResult = 'NO_VARIANTS';
                    } else if (deleteErrors.isEmpty()) {
                        row.deleteResult = 'OK (' + deleted + ')';
                    } else {
                        row.deleteResult = 'ERROR (' + deleted + '/' + variantIds.size() + '): ' + deleteErrors[0];
                    }
                }
            } else if (this.mode != MODE_LIST_ONLY && row.usageCount > 0) {
                row.unpublishResult = 'IN_USE';
                if (this.mode == MODE_DELETE) {
                    row.deleteResult = 'IN_USE';
                }
            }

            this.resultRows.add(row);
        }
    }

    global void finish(Database.BatchableContext bc) {
        String summary = 'CMS cleanup. Contents: ' + this.totalContentsRead + ', orphans: ' + this.totalOrphans + ', unpublished: ' + this.totalUnpublished + ', deleted variants: ' + this.totalDeletedVariants + ', errors: ' + this.totalErrors;
        if (this.logger.hasErrors() || this.totalErrors > 0) {
            summary = 'ERRORS: ' + summary;
            this.logger.addSection('Summary');
            this.logger.addInfo('Contents processed: ' + this.totalContentsRead);
            this.logger.addInfo('Orphan contents: ' + this.totalOrphans);
            this.logger.addInfo('Contents unpublished: ' + this.totalUnpublished);
            this.logger.addInfo('Variants deleted: ' + this.totalDeletedVariants);
            this.logger.addInfo('Errors: ' + this.totalErrors);
            this.logger.setSummary(summary);
            this.logger.saveLog(true);
        }

        this.sendResultEmail();
    }

    @TestVisible
    public void setTestData(
        List<String> contentIds,
        Map<String, String> contentNamesById,
        Map<String, Integer> usageCountByContentId,
        Map<String, String> publishedStatusByContentId,
        Map<String, List<String>> variantIdsByContentId
    ) {
        this.testContentIds = contentIds;
        this.testContentNamesById = contentNamesById;
        this.testUsageCountByContentId = usageCountByContentId;
        this.testPublishedStatusByContentId = publishedStatusByContentId;
        this.testVariantIdsByContentId = variantIdsByContentId;
    }

    @TestVisible
    public void setTestManagedContents(List<ManagedContent> workspaceContents, List<ManagedContent> namedContents) {
        this.testWorkspaceContents = workspaceContents;
        this.testNamedContents = namedContents;
    }

    @TestVisible
    public String testGetMode() {
        return this.mode;
    }

    @TestVisible
    public void setTestErrors(Set<String> unpublishContentIds, Set<String> deleteVariantIds) {
        this.testUnpublishErrorContentIds = unpublishContentIds == null ? new Set<String>() : unpublishContentIds;
        this.testDeleteErrorVariantIds = deleteVariantIds == null ? new Set<String>() : deleteVariantIds;
    }

    @TestVisible
    public String testBuildHtmlResult() {
        return this.buildHtmlResult();
    }

    @TestVisible
    public String testMapPublishStatus(Object fieldValue) {
        return this.mapPublishStatus(fieldValue);
    }

    @TestVisible
    public List<String> testLoadWorkspaceContentIds() {
        return this.loadWorkspaceContentIds();
    }

    @TestVisible
    public Map<String, String> testLoadContentNames(List<String> contentIds) {
        return this.loadContentNames(contentIds);
    }

    @TestVisible
    public Map<String, Integer> testLoadUsageCount(List<String> contentIds) {
        return this.loadUsageCount(contentIds);
    }

    @TestVisible
    public Map<String, String> testLoadPublishedStatus(List<String> contentIds) {
        return this.loadPublishedStatus(contentIds);
    }

    @TestVisible
    public Map<String, List<String>> testLoadVariantIds(List<String> contentIds) {
        return this.loadVariantIds(contentIds);
    }

    @TestVisible
    public void testAddLoggerError() {
        this.logger.addError('Test error');
    }

    private List<String> loadWorkspaceContentIds() {
        if (Test.isRunningTest() && this.testContentIds != null) {
            return new List<String>(this.testContentIds);
        }

        List<String> contentIds = new List<String>();
        Id workspaceId = this.workspaceId;
        Datetime beforeDate = this.beforeDate;
        String query =
            'SELECT Id, Name ' +
            'FROM ManagedContent ' +
            'WHERE AuthoredManagedContentSpaceId = :workspaceId';

        if (beforeDate != null) {
            query += ' AND CreatedDate < :beforeDate';
        }

        query += ' ORDER BY Name ASC';

        List<ManagedContent> contents = Test.isRunningTest() && this.testWorkspaceContents != null
            ? this.testWorkspaceContents
            : Database.query(query);

        for (ManagedContent content : contents) {
            contentIds.add(String.valueOf(content.Id));
            if (this.maxItems != null && this.maxItems > 0 && contentIds.size() >= this.maxItems) {
                break;
            }
        }

        return contentIds;
    }

    private Map<String, String> loadContentNames(List<String> contentIds) {
        if (Test.isRunningTest() && this.testContentNamesById != null) {
            return new Map<String, String>(this.testContentNamesById);
        }

        Map<String, String> contentNamesById = new Map<String, String>();
        if (contentIds.isEmpty()) {
            return contentNamesById;
        }

        List<ManagedContent> contents = Test.isRunningTest() && this.testNamedContents != null
            ? this.testNamedContents
            : [
                SELECT Id, Name
                FROM ManagedContent
                WHERE Id IN :contentIds
            ];

        for (ManagedContent content : contents) {
            contentNamesById.put(String.valueOf(content.Id), content.Name);
        }
        return contentNamesById;
    }

    private Map<String, Integer> loadUsageCount(List<String> contentIds) {
        if (Test.isRunningTest() && this.testUsageCountByContentId != null) {
            return new Map<String, Integer>(this.testUsageCountByContentId);
        }

        Map<String, Integer> usageCountByContentId = new Map<String, Integer>();
        if (contentIds.isEmpty()) {
            return usageCountByContentId;
        }

        for (AggregateResult ar : [
            SELECT ElectronicMediaId contentId, COUNT(Id) usageCount
            FROM ProductMedia
            WHERE ElectronicMediaId IN :contentIds
            GROUP BY ElectronicMediaId
        ]) {
            usageCountByContentId.put(
                String.valueOf(ar.get('contentId')),
                Integer.valueOf(String.valueOf(ar.get('usageCount')))
            );
        }

        return usageCountByContentId;
    }

    private Map<String, String> loadPublishedStatus(List<String> contentIds) {
        if (Test.isRunningTest() && this.testPublishedStatusByContentId != null) {
            return new Map<String, String>(this.testPublishedStatusByContentId);
        }

        Map<String, String> publishedStatusByContentId = new Map<String, String>();
        if (contentIds.isEmpty()) {
            return publishedStatusByContentId;
        }

        Map<String, Schema.SObjectField> fieldMap = ManagedContentVariant.SObjectType.getDescribe().fields.getMap();
        String publishField = null;
        if (fieldMap.containsKey('IsPublished')) {
            publishField = 'IsPublished';
        } else if (fieldMap.containsKey('PublishStatus')) {
            publishField = 'PublishStatus';
        } else if (fieldMap.containsKey('PublicationStatus')) {
            publishField = 'PublicationStatus';
        }

        String query = 'SELECT Id, ManagedContentId';
        if (publishField != null) {
            query += ', ' + publishField;
        }
        query += ' FROM ManagedContentVariant WHERE ManagedContentId IN :contentIds';

        for (SObject row : Database.query(query)) {
            String contentId = String.valueOf(row.get('ManagedContentId'));
            String currentStatus = publishedStatusByContentId.get(contentId);
            if (currentStatus == 'Published') {
                continue;
            }

            String nextStatus = 'Unknown';
            if (publishField == null) {
                nextStatus = 'Unknown';
            } else {
                Object fieldValue = row.get(publishField);
                nextStatus = this.mapPublishStatus(fieldValue);
            }
            publishedStatusByContentId.put(contentId, nextStatus);
        }

        return publishedStatusByContentId;
    }

    private String mapPublishStatus(Object fieldValue) {
        if (fieldValue == null) {
            return 'Unknown';
        }

        String value = String.valueOf(fieldValue).toUpperCase();
        if (value == 'TRUE' || value == 'PUBLISHED' || value == 'LIVE') {
            return 'Published';
        }
        if (value == 'FALSE' || value == 'UNPUBLISHED' || value == 'DRAFT') {
            return 'Unpublished';
        }
        return value;
    }

    private Boolean isAlreadyUnpublished(String publishedStatus) {
        return publishedStatus == 'Unpublished';
    }

    private Map<String, List<String>> loadVariantIds(List<String> contentIds) {
        if (Test.isRunningTest() && this.testVariantIdsByContentId != null) {
            Map<String, List<String>> out = new Map<String, List<String>>();
            for (String contentId : this.testVariantIdsByContentId.keySet()) {
                out.put(contentId, new List<String>(this.testVariantIdsByContentId.get(contentId)));
            }
            return out;
        }

        Map<String, List<String>> variantIdsByContentId = new Map<String, List<String>>();
        if (contentIds.isEmpty()) {
            return variantIdsByContentId;
        }

        for (ManagedContentVariant variant : [
            SELECT Id, ManagedContentId
            FROM ManagedContentVariant
            WHERE ManagedContentId IN :contentIds
        ]) {
            String contentId = String.valueOf(variant.ManagedContentId);
            if (!variantIdsByContentId.containsKey(contentId)) {
                variantIdsByContentId.put(contentId, new List<String>());
            }
            variantIdsByContentId.get(contentId).add(String.valueOf(variant.Id));
        }
        return variantIdsByContentId;
    }

    private void unpublishContent(String contentId) {
        if (Test.isRunningTest()) {
            if (this.testUnpublishErrorContentIds.contains(contentId)) {
                throw new IllegalArgumentException('Test unpublish error for content ' + contentId);
            }
            this.testUnpublishedContentIds.add(contentId);
            return;
        }

        ConnectApi.ManagedContentUnpublishInput input = new ConnectApi.ManagedContentUnpublishInput();
        input.contentIds = new List<String>{ contentId };
        input.contextContentSpaceId = this.workspaceId;
        ConnectApi.ManagedContent.unpublish(input);
    }

    private void deleteVariant(String variantId) {
        if (Test.isRunningTest()) {
            if (this.testDeleteErrorVariantIds.contains(variantId)) {
                throw new IllegalArgumentException('Test delete error for variant ' + variantId);
            }
            this.testDeletedVariantIds.add(variantId);
            return;
        }

        ConnectApi.ManagedContent.deleteManagedContentVariant(variantId);
    }

    private void sendResultEmail() {
        if (Test.isRunningTest()) {
            return;
        }

        Mail mail = new Mail();
        mail.setTo(UserInfo.getUserId());
        mail.setSubject('CMS content cleanup - ' + this.mode);
        mail.setHtml(this.buildHtmlResult());
        mail.send();
    }

    private String buildHtmlResult() {
        String html = '<html><body>';
        html += '<h2>CMS Content Cleanup</h2>';
        html += '<p><b>Workspace:</b> ' + this.workspaceId + '<br/>';
        html += '<b>Mode:</b> ' + this.mode + '<br/>';
        html += '<b>Contents:</b> ' + this.totalContentsRead + '<br/>';
        html += '<b>Orphans:</b> ' + this.totalOrphans + '<br/>';
        html += '<b>Unpublished:</b> ' + this.totalUnpublished + '<br/>';
        html += '<b>Deleted variants:</b> ' + this.totalDeletedVariants + '<br/>';
        html += '<b>Errors:</b> ' + this.totalErrors + '</p>';

        html += '<table border="1" cellpadding="4" cellspacing="0">';
        html += '<tr>';
        html += '<th>Name</th>';
        html += '<th>Title</th>';
        html += '<th>Published</th>';
        html += '<th>ProductMedia Uses</th>';
        html += '<th>Unpublish</th>';
        html += '<th>Delete</th>';
        html += '</tr>';

        for (ResultRowDTO row : this.resultRows) {
            html += '<tr>';
            html += '<td>' + this.htmlEncode(row.name) + '</td>';
            html += '<td>' + this.htmlEncode(row.title) + '</td>';
            html += '<td>' + this.htmlEncode(row.publishedStatus) + '</td>';
            html += '<td>' + this.htmlEncode(String.valueOf(row.usageCount)) + '</td>';
            html += '<td>' + this.htmlEncode(row.unpublishResult) + '</td>';
            html += '<td>' + this.htmlEncode(row.deleteResult) + '</td>';
            html += '</tr>';
        }

        html += '</table>';
        html += '</body></html>';
        return html;
    }

    private String htmlEncode(String value) {
        if (value == null) {
            return '';
        }
        String out = value.replace('&', '&amp;');
        out = out.replace('<', '&lt;');
        out = out.replace('>', '&gt;');
        return out;
    }

    public class ResultRowDTO {
        public String contentId;
        public String name = '';
        public String title = '';
        public String publishedStatus = 'Unknown';
        public Integer usageCount = 0;
        public String unpublishResult = '';
        public String deleteResult = '';
    }
}