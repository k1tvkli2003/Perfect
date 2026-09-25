/// pg-tasks Copy fidelity receipt: Stage 36 contract.
///
/// Exact live-copy strings from the accepted pg-tasks composition pages
/// (design/04-copy-manifests/copy.json: 5 pages x 8 roles = 40 entries).
/// All five pages share one subtitle; titles differ per page. The Tasks
/// workspace crown must render these verbatim constants — never a widget-local
/// paraphrase. Unknown page IDs fall back to the default crown, never empty.
abstract final class PlannerTasksCopy {
  /// Accepted pg-tasks-default title.
  static const String defaultTitle = 'Tasks';

  /// Shared subtitle across all five accepted pg-tasks pages.
  static const String defaultSubtitle =
      'Search, filter and act without losing the working context.';

  /// Exact accepted title per pg-tasks composition page.
  static const Map<String, String> titlesByPage = <String, String>{
    'pg-tasks-default': 'Tasks',
    'pg-tasks-search': 'Search tasks',
    'pg-tasks-filtered': 'Filtered tasks',
    'pg-tasks-dense': 'Dense task workspace',
    'pg-tasks-bulk': 'Bulk task actions',
  };

  /// Resolves the accepted title for [pageId], falling back to the default
  /// crown when the page is unknown.
  static String titleFor(String pageId) => titlesByPage[pageId] ?? defaultTitle;
}
