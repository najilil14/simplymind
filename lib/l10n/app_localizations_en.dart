// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SimplyMind';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get reset => 'Reset';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get more => 'More';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get importJson => 'Import JSON';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportPng => 'Export image (PNG)';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportTooltip => 'Export';

  @override
  String get exportedJson => 'Mind map exported as JSON';

  @override
  String get exportedPng => 'Mind map exported as PNG';

  @override
  String get exportedPdf => 'Mind map exported as PDF';

  @override
  String get exportImageFailed => 'Could not export image';

  @override
  String get exportPdfFailed => 'Could not export PDF';

  @override
  String get newMindMap => 'New mind map';

  @override
  String get createMindMap => 'Create mind map';

  @override
  String get renameMindMap => 'Rename mind map';

  @override
  String deleteMindMapTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteCannotUndo => 'This cannot be undone.';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'e.g. Project brainstorm';

  @override
  String get template => 'Template';

  @override
  String get noMindMapsYet => 'No mind maps yet';

  @override
  String get noMindMapsHint =>
      'Create your first map and start branching ideas.';

  @override
  String importedMap(String title) {
    return 'Imported \"$title\"';
  }

  @override
  String get importInvalid => 'That file is not a valid mind map.';

  @override
  String nodeCount(int count) {
    return '$count node';
  }

  @override
  String nodeCountPlural(int count) {
    return '$count nodes';
  }

  @override
  String todayAt(String time) {
    return 'Today $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday $time';
  }

  @override
  String get categoryAll => 'All';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryNew => 'New';

  @override
  String get newCategory => 'New category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryHint => 'e.g. Work, Personal';

  @override
  String get createCategory => 'Create category';

  @override
  String get moveToCategory => 'Move to category';

  @override
  String get homeReserved => '\"Home\" is reserved for uncategorized maps';

  @override
  String get homeReservedShort => '\"Home\" is reserved';

  @override
  String categoryExists(String name) {
    return 'Category \"$name\" already exists';
  }

  @override
  String deleteCategoryTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryBody =>
      'Maps in this category move back to Home. The maps themselves are not deleted.';

  @override
  String renameCategoryItem(String name) {
    return 'Rename \"$name\"';
  }

  @override
  String deleteCategoryItem(String name) {
    return 'Delete \"$name\"';
  }

  @override
  String get organizeMapsTitle => 'Organize your maps?';

  @override
  String organizeMapsBody(int count) {
    return 'You have more than $count mind maps. Create categories to keep them tidy.';
  }

  @override
  String get notNow => 'Not now';

  @override
  String noMapsInCategory(String name) {
    return 'No maps in $name';
  }

  @override
  String get noMapsInCategoryHint =>
      'Create a new mind map here, or move an existing one into this category.';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get dmca => 'DMCA';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get feedbackPrefill =>
      'I\'m using SimplyMind and I have some feedback for you: ';

  @override
  String whatsAppFailed(String url, String number) {
    return 'Could not open WhatsApp. Open $url manually, or message $number.';
  }

  @override
  String get layoutMap => 'Map';

  @override
  String get layoutList => 'List';

  @override
  String get layoutStep => 'Step';

  @override
  String get layoutGraph => 'Graph';

  @override
  String get layoutMapDesc => 'Free positioning by dragging';

  @override
  String get layoutListDesc => 'Indented outline, top to bottom';

  @override
  String get layoutStepDesc => 'Numbered sequence with arrows';

  @override
  String get layoutGraphDesc => 'Radial branches around the node';

  @override
  String get layoutInherit => 'Inherit';

  @override
  String get layoutInheritDesc => 'Follow the map template';

  @override
  String get statusNone => 'No status';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDone => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get mapSettings => 'Map settings';

  @override
  String nodePaddingLabel(int px) {
    return 'Node padding: $px px';
  }

  @override
  String get nodePaddingHelp =>
      'Space between the text and the node box. The change is previewed live and saved with this mind map.';

  @override
  String get focusMode => 'Focus mode';

  @override
  String get showControls => 'Show controls';

  @override
  String get editNode => 'Edit node';

  @override
  String get newNode => 'New node';

  @override
  String get newIdea => 'New idea';

  @override
  String get nodeColor => 'Node color';

  @override
  String get customColor => 'Custom color';

  @override
  String get useCustomColor => 'Use custom color';

  @override
  String get nodeStatus => 'Node status';

  @override
  String get branchTemplate => 'Branch template';

  @override
  String get addChild => 'Add child';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveRight => 'Move right';

  @override
  String get moveDown => 'Move down';

  @override
  String get promote => 'Promote (sibling of parent)';

  @override
  String get status => 'Status';

  @override
  String get color => 'Color';

  @override
  String get deleteBranch => 'Delete branch';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get fitAllNodes => 'Fit all nodes';

  @override
  String get hintBanner =>
      'Drag onto a node to attach · Promote: ⇈ · Double-tap: edit';

  @override
  String get hintBannerCompact =>
      'Drag onto a node to attach\nPromote: ⇈ · Double-tap: edit';

  @override
  String get themeVivid => 'Vivid';

  @override
  String get themePastel => 'Pastel';

  @override
  String get themeEarth => 'Earth';

  @override
  String get hue => 'Hue';

  @override
  String get sat => 'Sat';

  @override
  String get bright => 'Bright';

  @override
  String get layoutSection => 'Layout';

  @override
  String get starterSection => 'Starter';

  @override
  String get starterBlank => 'Blank';

  @override
  String get starterPrd => 'PRD';

  @override
  String get starterEntities => 'Entities';

  @override
  String get starterBlankDesc => 'One central node. Build from scratch.';

  @override
  String get starterPrdDesc =>
      'Product requirements outline: problem, goals, users, scope.';

  @override
  String get starterEntitiesDesc =>
      'Sample entities with attributes — a sketch of related tables.';

  @override
  String get prdProblem => 'Problem / opportunity';

  @override
  String get prdGoals => 'Goals';

  @override
  String get prdGoalExample => 'Goal 1';

  @override
  String get prdUsers => 'Users & personas';

  @override
  String get prdPersona => 'Persona';

  @override
  String get prdRequirements => 'Requirements';

  @override
  String get prdMustHave => 'Must have';

  @override
  String get prdNiceToHave => 'Nice to have';

  @override
  String get prdScope => 'Scope';

  @override
  String get prdInScope => 'In scope';

  @override
  String get prdOutOfScope => 'Out of scope';

  @override
  String get prdMetrics => 'Success metrics';

  @override
  String get prdQuestions => 'Open questions';

  @override
  String get entityUser => 'User';

  @override
  String get entityAccount => 'Account';

  @override
  String get entityOrder => 'Order';

  @override
  String get entityProduct => 'Product';

  @override
  String get attrId => 'id';

  @override
  String get attrName => 'name';

  @override
  String get attrEmail => 'email';

  @override
  String get attrUserId => 'userId';

  @override
  String get attrAccountId => 'accountId';

  @override
  String get attrStatus => 'status';

  @override
  String get attrTotal => 'total';

  @override
  String get attrSku => 'sku';

  @override
  String get attrPrice => 'price';

  @override
  String get howToUse => 'How to use';

  @override
  String get helpIntro =>
      'SimplyMind is a local, offline-first mind map. Maps stay on this device as JSON. This guide covers the home list, the canvas editor, starters, export, and install.';

  @override
  String get helpHomeTitle => 'Home: your maps';

  @override
  String get helpHomeBody =>
      'The home screen lists every mind map on this device, newest first. Tap a map to open the editor. Use the ⋮ menu on a row to rename, duplicate, move to a category, export JSON, or delete.\n\nThe + New mind map button starts a title, starter, and layout. Import JSON from the folder icon in the top bar.';

  @override
  String get helpCreateTitle => 'Create: starter and layout';

  @override
  String get helpCreateBody =>
      'Starter is the content you begin with. Blank is one central node. PRD is a product-outline (problem, goals, users, requirements, scope). Entities is a sketch of related tables (User, Account, Order, Product) with fields as children — not a full database diagram.\n\nLayout is how nodes sit: Map (drag freely), List (outline), Step (numbered flow), Graph (around the parent). You can change layout later in the editor. Picking PRD suggests List; Entities suggests Graph.';

  @override
  String get helpEditTitle => 'Editor: nodes and branches';

  @override
  String get helpEditBody =>
      'Tap a node to select it and show the toolbar. Double-tap to edit text. + adds a child (in Map mode it finds free space near siblings). Drag a non-root node onto another to reparent. Promote (⇈) makes a node a sibling of its parent.\n\nIn List/Step/Graph, use the arrow buttons to reorder siblings. Branch template overrides layout for that subtree. Status (none / in progress / done) and color live on each node. Map settings (tune icon) change padding between text and the box.';

  @override
  String get helpCanvasTitle => 'Canvas: zoom and focus';

  @override
  String get helpCanvasBody =>
      'Pinch or use + / − to zoom. Fit-all shows every node on screen (also used when you first open a map). Focus mode (fullscreen icon) hides the top bar and overlays so you can think on a wider canvas. The hint at the bottom summarizes drag, promote, and double-tap.';

  @override
  String get helpOrganizeTitle => 'Categories';

  @override
  String get helpOrganizeBody =>
      'Maps start in Home. After many maps, SimplyMind offers categories. Create them from More or the chip row. Filter with All / Home / your names. Move a map from its ⋮ menu. Deleting a category sends maps back to Home; it does not delete the maps.';

  @override
  String get helpExportTitle => 'Export, import, and share';

  @override
  String get helpExportBody =>
      'In the editor, the share menu exports JSON (editable backup), PNG (picture of the whole map), or PDF. JSON import is on the home screen. PNG/PDF redraw the full tree — not a screenshot of the current zoom.';

  @override
  String get helpOfflineTitle => 'Web, install, and offline';

  @override
  String get helpOfflineBody =>
      'On the website you can Add to Home Screen. After one online visit, the app can open without internet (service worker). Maps stay in local storage. Open the site on HTTPS. iOS may clear unused site data after weeks — export JSON if you need a backup. Native Android/iOS builds store data on the device without that web limit.';

  @override
  String get helpLanguageTitle => 'Language';

  @override
  String get helpLanguageBody =>
      'More → Language: follow the device, English, or Bahasa Indonesia. Menus and this guide change; text you typed in nodes does not.';

  @override
  String get helpFeedbackTitle => 'Feedback and legal';

  @override
  String get helpFeedbackBody =>
      'More → Send feedback opens WhatsApp with a short pre-filled message. Privacy Policy and DMCA are in the same menu.';

  @override
  String get relations => 'Relations';

  @override
  String get manageRelations => 'Manage relations';

  @override
  String get addRelation => 'Add relation';

  @override
  String get editRelation => 'Edit relation';

  @override
  String get removeRelation => 'Remove relation';

  @override
  String get relationTarget => 'Link to node';

  @override
  String get relationLabel => 'Relation label';

  @override
  String get relationLabelHint => 'e.g. belongs to';

  @override
  String get relationCardinality => 'Cardinality';

  @override
  String get relationCardinalityHint => 'e.g. N:1';

  @override
  String get noRelations => 'No extra relations yet.';

  @override
  String get noRelationTargets => 'Every other node is already linked.';

  @override
  String get relationBelongsTo => 'belongs to';

  @override
  String get relationContains => 'contains';

  @override
  String get helpRelationsTitle => 'Extra relations';

  @override
  String get helpRelationsBody =>
      'A node has one parent for layout, but it can also have many extra relations. Select a node → Relations, choose another node, then add an optional label and cardinality (for example belongs to, N:1). Relations use curved dashed arrows attached to box edges and do not change the tree layout. A relation that duplicates a parent-child branch is not drawn twice.';
}
