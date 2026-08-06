@isTest
public class CMS_ContentCleanupBatchTest {

    @isTest
    static void testStaticExecuteBatchDefault() {
        Test.startTest();
        CMS_ContentCleanupBatch.executeBatch(UserInfo.getUserId());
        Test.stopTest();
    }

    @isTest
    static void testStaticExecuteBatchWithParameters() {
        Test.startTest();
        CMS_ContentCleanupBatch.executeBatch(
            UserInfo.getUserId(),
            Datetime.newInstance(2026, 1, 1, 0, 0, 0),
            CMS_ContentCleanupBatch.MODE_LIST_ONLY,
            5
        );
        Test.stopTest();
    }

    @isTest
    static void testListOnlyMode() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_LIST_ONLY,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000002AAA', '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg',
                '20Y000000000002AAA' => 'B-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0,
                '20Y000000000002AAA' => 5
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published',
                '20Y000000000002AAA' => 'Unpublished'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA' },
                '20Y000000000002AAA' => new List<String>{ '9Ps000000000002AAA' }
            }
        );

        Iterable<String> scope = batch.start(null);
        List<String> contentIds = new List<String>();
        for (String contentId : scope) {
            contentIds.add(contentId);
        }

        batch.execute(null, contentIds);
        batch.finish(null);

        Assert.areEqual(0, batch.testUnpublishedContentIds.size(), 'List mode should not unpublish content.');
        Assert.areEqual(0, batch.testDeletedVariantIds.size(), 'List mode should not delete variants.');
    }

    @isTest
    static void testUnpublishOnlyMode() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_UNPUBLISH_ONLY,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA', '20Y000000000002AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg',
                '20Y000000000002AAA' => 'B-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0,
                '20Y000000000002AAA' => 3
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published',
                '20Y000000000002AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA' },
                '20Y000000000002AAA' => new List<String>{ '9Ps000000000002AAA' }
            }
        );

        Iterable<String> scope = batch.start(null);
        List<String> contentIds = new List<String>();
        for (String contentId : scope) {
            contentIds.add(contentId);
        }

        batch.execute(null, contentIds);
        batch.finish(null);

        Assert.isTrue(batch.testUnpublishedContentIds.contains('20Y000000000001AAA'), 'Orphan content should be unpublished.');
        Assert.isFalse(batch.testUnpublishedContentIds.contains('20Y000000000002AAA'), 'In-use content should not be unpublished.');
    }

    @isTest
    static void testUnpublishAndDeleteMode() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_DELETE,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA', '9Ps000000000002AAA' }
            }
        );

        Iterable<String> scope = batch.start(null);
        List<String> contentIds = new List<String>();
        for (String contentId : scope) {
            contentIds.add(contentId);
        }

        batch.execute(null, contentIds);
        batch.finish(null);

        Assert.isTrue(batch.testUnpublishedContentIds.contains('20Y000000000001AAA'), 'Orphan content should be unpublished.');
        Assert.areEqual(2, batch.testDeletedVariantIds.size(), 'All variants should be deleted.');
    }

    @isTest
    static void testUnpublishAndDeleteModeWithNoVariants() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(UserInfo.getUserId());
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>()
            }
        );

        batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_DELETE,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>()
            }
        );

        batch.execute(null, new List<String>{ '20Y000000000001AAA' });

        Assert.isTrue(batch.testUnpublishedContentIds.contains('20Y000000000001AAA'), 'Orphan content should be unpublished.');
        Assert.areEqual(0, batch.testDeletedVariantIds.size(), 'No variants should be deleted.');
    }

    @isTest
    static void testDeleteErrorAndInUseBranch() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_DELETE,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA', '20Y000000000002AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg',
                '20Y000000000002AAA' => 'B-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0,
                '20Y000000000002AAA' => 2
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published',
                '20Y000000000002AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA', '9Ps000000000002AAA' },
                '20Y000000000002AAA' => new List<String>{ '9Ps000000000003AAA' }
            }
        );
        batch.setTestErrors(null, new Set<String>{ '9Ps000000000002AAA' });

        batch.execute(null, new List<String>{ '20Y000000000001AAA', '20Y000000000002AAA' });
        batch.finish(null);

        Assert.isTrue(batch.testUnpublishedContentIds.contains('20Y000000000001AAA'), 'Orphan content should be unpublished.');
        Assert.isFalse(batch.testUnpublishedContentIds.contains('20Y000000000002AAA'), 'In-use content should not be unpublished.');
        Assert.isTrue(batch.testDeletedVariantIds.contains('9Ps000000000001AAA'), 'Successful variant delete should be tracked.');
        Assert.isFalse(batch.testDeletedVariantIds.contains('9Ps000000000002AAA'), 'Errored variant delete should not be tracked.');
    }

    @isTest
    static void testFallbacksAndHtmlHelpers() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_LIST_ONLY,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>(),
            new Map<String, String>(),
            new Map<String, List<String>>()
        );

        batch.execute(null, new List<String>{ '20Y000000000001AAA' });
        String html = batch.testBuildHtmlResult();

        Assert.isTrue(html.contains('A-image.jpg'), 'HTML should include the content name.');
        Assert.isTrue(html.contains('Unknown'), 'HTML should include fallback published status.');
        Assert.isTrue(html.contains('0'), 'HTML should include fallback usage count.');
        Assert.areEqual('Unknown', batch.testMapPublishStatus(null), 'Null publish value should map to Unknown.');
        Assert.areEqual('Published', batch.testMapPublishStatus(true), 'True should map to Published.');
        Assert.areEqual('Unpublished', batch.testMapPublishStatus(false), 'False should map to Unpublished.');
        Assert.areEqual('Published', batch.testMapPublishStatus('LIVE'), 'LIVE should map to Published.');
        Assert.areEqual('Unpublished', batch.testMapPublishStatus('DRAFT'), 'DRAFT should map to Unpublished.');
        Assert.areEqual('CUSTOM', batch.testMapPublishStatus('custom'), 'Unknown values should be uppercased and returned as-is.');
    }

    @isTest
    static void testEmptyLoadHelpersAndErrorSummary() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_LIST_ONLY,
            null
        );

        Assert.areEqual(0, batch.testLoadWorkspaceContentIds().size(), 'No workspace content should be returned in test by default.');
        Assert.areEqual(0, batch.testLoadContentNames(new List<String>()).size(), 'Empty content list should return empty names.');
        Assert.areEqual(0, batch.testLoadUsageCount(new List<String>()).size(), 'Empty content list should return empty usage counts.');
        Assert.areEqual(0, batch.testLoadPublishedStatus(new List<String>()).size(), 'Empty content list should return empty published status.');
        Assert.areEqual(0, batch.testLoadVariantIds(new List<String>()).size(), 'Empty content list should return empty variants.');

        batch.testAddLoggerError();
        batch.finish(null);
    }

    @isTest
    static void testInjectedHelperMaps() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_LIST_ONLY,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA', '20Y000000000002AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 4
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA' }
            }
        );

        Assert.areEqual(2, batch.testLoadWorkspaceContentIds().size(), 'Injected content ids should be returned.');
        Assert.areEqual('A-image.jpg', batch.testLoadContentNames(new List<String>{ '20Y000000000001AAA' }).get('20Y000000000001AAA'), 'Injected names should be returned.');
        Assert.areEqual(4, batch.testLoadUsageCount(new List<String>{ '20Y000000000001AAA' }).get('20Y000000000001AAA'), 'Injected usage counts should be returned.');
        Assert.areEqual('Published', batch.testLoadPublishedStatus(new List<String>{ '20Y000000000001AAA' }).get('20Y000000000001AAA'), 'Injected publish status should be returned.');
        Assert.areEqual(1, batch.testLoadVariantIds(new List<String>{ '20Y000000000001AAA' }).get('20Y000000000001AAA').size(), 'Injected variant ids should be returned.');
    }

    @isTest
    static void testLegacyModeAliasAndManagedContentHooks() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            'UNPUBLISH_AND_DELETE',
            1
        );

        ManagedContent workspaceContent1 = (ManagedContent) JSON.deserialize(
            '{"attributes":{"type":"ManagedContent"},"Id":"20Y000000000001AAA","Name":"B-image.jpg"}',
            ManagedContent.class
        );
        ManagedContent workspaceContent2 = (ManagedContent) JSON.deserialize(
            '{"attributes":{"type":"ManagedContent"},"Id":"20Y000000000002AAA","Name":"A-image.jpg"}',
            ManagedContent.class
        );
        ManagedContent namedContent = (ManagedContent) JSON.deserialize(
            '{"attributes":{"type":"ManagedContent"},"Id":"20Y000000000002AAA","Name":"A-image.jpg"}',
            ManagedContent.class
        );

        batch.setTestManagedContents(
            new List<ManagedContent>{ workspaceContent1, workspaceContent2 },
            new List<ManagedContent>{ namedContent }
        );

        Assert.areEqual(CMS_ContentCleanupBatch.MODE_DELETE, batch.testGetMode(), 'Legacy mode name should be normalized to DELETE.');
        Assert.areEqual(1, batch.testLoadWorkspaceContentIds().size(), 'Max items should stop workspace content loading.');
        Assert.areEqual('A-image.jpg', batch.testLoadContentNames(new List<String>{ '20Y000000000002AAA' }).get('20Y000000000002AAA'), 'Named content hook should be returned.');
    }

    @isTest
    static void testUnpublishErrorSkipsDelete() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_DELETE,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Published'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA' }
            }
        );
        batch.setTestErrors(new Set<String>{ '20Y000000000001AAA' }, null);

        Iterable<String> scope = batch.start(null);
        List<String> contentIds = new List<String>();
        for (String contentId : scope) {
            contentIds.add(contentId);
        }

        batch.execute(null, contentIds);
        batch.finish(null);

        Assert.areEqual(0, batch.testDeletedVariantIds.size(), 'Variants should not be deleted if unpublish fails.');
    }

    @isTest
    static void testDeleteModeSkipsUnpublishWhenAlreadyUnpublished() {
        CMS_ContentCleanupBatch batch = new CMS_ContentCleanupBatch(
            UserInfo.getUserId(),
            null,
            CMS_ContentCleanupBatch.MODE_DELETE,
            null
        );
        batch.setTestData(
            new List<String>{ '20Y000000000001AAA' },
            new Map<String, String>{
                '20Y000000000001AAA' => 'A-image.jpg'
            },
            new Map<String, Integer>{
                '20Y000000000001AAA' => 0
            },
            new Map<String, String>{
                '20Y000000000001AAA' => 'Unpublished'
            },
            new Map<String, List<String>>{
                '20Y000000000001AAA' => new List<String>{ '9Ps000000000001AAA' }
            }
        );

        batch.execute(null, new List<String>{ '20Y000000000001AAA' });

        Assert.areEqual(0, batch.testUnpublishedContentIds.size(), 'Already unpublished content should not be unpublished again.');
        Assert.isTrue(batch.testDeletedVariantIds.contains('9Ps000000000001AAA'), 'Delete should still run for unpublished orphan content.');
    }
}