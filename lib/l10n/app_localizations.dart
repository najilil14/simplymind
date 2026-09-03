import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SimplyMind'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @exportPng.
  ///
  /// In en, this message translates to:
  /// **'Export image (PNG)'**
  String get exportPng;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTooltip;

  /// No description provided for @exportedJson.
  ///
  /// In en, this message translates to:
  /// **'Mind map exported as JSON'**
  String get exportedJson;

  /// No description provided for @exportedPng.
  ///
  /// In en, this message translates to:
  /// **'Mind map exported as PNG'**
  String get exportedPng;

  /// No description provided for @exportedPdf.
  ///
  /// In en, this message translates to:
  /// **'Mind map exported as PDF'**
  String get exportedPdf;

  /// No description provided for @exportImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export image'**
  String get exportImageFailed;

  /// No description provided for @exportPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export PDF'**
  String get exportPdfFailed;

  /// No description provided for @newMindMap.
  ///
  /// In en, this message translates to:
  /// **'New mind map'**
  String get newMindMap;

  /// No description provided for @createMindMap.
  ///
  /// In en, this message translates to:
  /// **'Create mind map'**
  String get createMindMap;

  /// No description provided for @renameMindMap.
  ///
  /// In en, this message translates to:
  /// **'Rename mind map'**
  String get renameMindMap;

  /// No description provided for @deleteMindMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteMindMapTitle(String title);

  /// No description provided for @deleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteCannotUndo;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Project brainstorm'**
  String get titleHint;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @noMindMapsYet.
  ///
  /// In en, this message translates to:
  /// **'No mind maps yet'**
  String get noMindMapsYet;

  /// No description provided for @noMindMapsHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first map and start branching ideas.'**
  String get noMindMapsHint;

  /// No description provided for @importedMap.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{title}\"'**
  String importedMap(String title);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file is not a valid mind map.'**
  String get importInvalid;

  /// No description provided for @nodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} node'**
  String nodeCount(int count);

  /// No description provided for @nodeCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes'**
  String nodeCountPlural(int count);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayAt(String time);

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get categoryNew;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get renameCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Personal'**
  String get categoryHint;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get createCategory;

  /// No description provided for @moveToCategory.
  ///
  /// In en, this message translates to:
  /// **'Move to category'**
  String get moveToCategory;

  /// No description provided for @homeReserved.
  ///
  /// In en, this message translates to:
  /// **'\"Home\" is reserved for uncategorized maps'**
  String get homeReserved;

  /// No description provided for @homeReservedShort.
  ///
  /// In en, this message translates to:
  /// **'\"Home\" is reserved'**
  String get homeReservedShort;

  /// No description provided for @categoryExists.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" already exists'**
  String categoryExists(String name);

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryTitle(String name);

  /// No description provided for @deleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Maps in this category move back to Home. The maps themselves are not deleted.'**
  String get deleteCategoryBody;

  /// No description provided for @renameCategoryItem.
  ///
  /// In en, this message translates to:
  /// **'Rename \"{name}\"'**
  String renameCategoryItem(String name);

  /// No description provided for @deleteCategoryItem.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"'**
  String deleteCategoryItem(String name);

  /// No description provided for @organizeMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your maps?'**
  String get organizeMapsTitle;

  /// No description provided for @organizeMapsBody.
  ///
  /// In en, this message translates to:
  /// **'You have more than {count} mind maps. Create categories to keep them tidy.'**
  String organizeMapsBody(int count);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @noMapsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No maps in {name}'**
  String noMapsInCategory(String name);

  /// No description provided for @noMapsInCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Create a new mind map here, or move an existing one into this category.'**
  String get noMapsInCategoryHint;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @dmca.
  ///
  /// In en, this message translates to:
  /// **'DMCA'**
  String get dmca;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @feedbackPrefill.
  ///
  /// In en, this message translates to:
  /// **'I\'m using SimplyMind and I have some feedback for you: '**
  String get feedbackPrefill;

  /// No description provided for @whatsAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Open {url} manually, or message {number}.'**
  String whatsAppFailed(String url, String number);

  /// No description provided for @layoutMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get layoutMap;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @layoutStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get layoutStep;

  /// No description provided for @layoutGraph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get layoutGraph;

  /// No description provided for @layoutMapDesc.
  ///
  /// In en, this message translates to:
  /// **'Free positioning by dragging'**
  String get layoutMapDesc;

  /// No description provided for @layoutListDesc.
  ///
  /// In en, this message translates to:
  /// **'Indented outline, top to bottom'**
  String get layoutListDesc;

  /// No description provided for @layoutStepDesc.
  ///
  /// In en, this message translates to:
  /// **'Numbered sequence with arrows'**
  String get layoutStepDesc;

  /// No description provided for @layoutGraphDesc.
  ///
  /// In en, this message translates to:
  /// **'Radial branches around the node'**
  String get layoutGraphDesc;

  /// No description provided for @layoutInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get layoutInherit;

  /// No description provided for @layoutInheritDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow the map template'**
  String get layoutInheritDesc;

  /// No description provided for @statusNone.
  ///
  /// In en, this message translates to:
  /// **'No status'**
  String get statusNone;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map settings'**
  String get mapSettings;

  /// No description provided for @nodePaddingLabel.
  ///
  /// In en, this message translates to:
  /// **'Node padding: {px} px'**
  String nodePaddingLabel(int px);

  /// No description provided for @nodePaddingHelp.
  ///
  /// In en, this message translates to:
  /// **'Space between the text and the node box. The change is previewed live and saved with this mind map.'**
  String get nodePaddingHelp;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get focusMode;

  /// No description provided for @showControls.
  ///
  /// In en, this message translates to:
  /// **'Show controls'**
  String get showControls;

  /// No description provided for @editNode.
  ///
  /// In en, this message translates to:
  /// **'Edit node'**
  String get editNode;

  /// No description provided for @newNode.
  ///
  /// In en, this message translates to:
  /// **'New node'**
  String get newNode;

  /// No description provided for @newIdea.
  ///
  /// In en, this message translates to:
  /// **'New idea'**
  String get newIdea;

  /// No description provided for @nodeColor.
  ///
  /// In en, this message translates to:
  /// **'Node color'**
  String get nodeColor;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @useCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Use custom color'**
  String get useCustomColor;

  /// No description provided for @nodeStatus.
  ///
  /// In en, this message translates to:
  /// **'Node status'**
  String get nodeStatus;

  /// No description provided for @branchTemplate.
  ///
  /// In en, this message translates to:
  /// **'Branch template'**
  String get branchTemplate;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @moveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get moveLeft;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveRight.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get moveRight;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promote (sibling of parent)'**
  String get promote;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @deleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get deleteBranch;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @fitAllNodes.
  ///
  /// In en, this message translates to:
  /// **'Fit all nodes'**
  String get fitAllNodes;

  /// No description provided for @hintBanner.
  ///
  /// In en, this message translates to:
  /// **'Drag onto a node to attach · Promote: ⇈ · Double-tap: edit'**
  String get hintBanner;

  /// No description provided for @hintBannerCompact.
  ///
  /// In en, this message translates to:
  /// **'Drag onto a node to attach\nPromote: ⇈ · Double-tap: edit'**
  String get hintBannerCompact;

  /// No description provided for @themeVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get themeVivid;

  /// No description provided for @themePastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get themePastel;

  /// No description provided for @themeEarth.
  ///
  /// In en, this message translates to:
  /// **'Earth'**
  String get themeEarth;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @bright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get bright;

  /// No description provided for @layoutSection.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layoutSection;

  /// No description provided for @starterSection.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starterSection;

  /// No description provided for @starterBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get starterBlank;

  /// No description provided for @starterPrd.
  ///
  /// In en, this message translates to:
  /// **'PRD'**
  String get starterPrd;

  /// No description provided for @starterEntities.
  ///
  /// In en, this message translates to:
  /// **'Entities'**
  String get starterEntities;

  /// No description provided for @starterBlankDesc.
  ///
  /// In en, this message translates to:
  /// **'One central node. Build from scratch.'**
  String get starterBlankDesc;

  /// No description provided for @starterPrdDesc.
  ///
  /// In en, this message translates to:
  /// **'Product requirements outline: problem, goals, users, scope.'**
  String get starterPrdDesc;

  /// No description provided for @starterEntitiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Sample entities with attributes — a sketch of related tables.'**
  String get starterEntitiesDesc;

  /// No description provided for @prdProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem / opportunity'**
  String get prdProblem;

  /// No description provided for @prdGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get prdGoals;

  /// No description provided for @prdGoalExample.
  ///
  /// In en, this message translates to:
  /// **'Goal 1'**
  String get prdGoalExample;

  /// No description provided for @prdUsers.
  ///
  /// In en, this message translates to:
  /// **'Users & personas'**
  String get prdUsers;

  /// No description provided for @prdPersona.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get prdPersona;

  /// No description provided for @prdRequirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get prdRequirements;

  /// No description provided for @prdMustHave.
  ///
  /// In en, this message translates to:
  /// **'Must have'**
  String get prdMustHave;

  /// No description provided for @prdNiceToHave.
  ///
  /// In en, this message translates to:
  /// **'Nice to have'**
  String get prdNiceToHave;

  /// No description provided for @prdScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get prdScope;

  /// No description provided for @prdInScope.
  ///
  /// In en, this message translates to:
  /// **'In scope'**
  String get prdInScope;

  /// No description provided for @prdOutOfScope.
  ///
  /// In en, this message translates to:
  /// **'Out of scope'**
  String get prdOutOfScope;

  /// No description provided for @prdMetrics.
  ///
  /// In en, this message translates to:
  /// **'Success metrics'**
  String get prdMetrics;

  /// No description provided for @prdQuestions.
  ///
  /// In en, this message translates to:
  /// **'Open questions'**
  String get prdQuestions;

  /// No description provided for @entityUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get entityUser;

  /// No description provided for @entityAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get entityAccount;

  /// No description provided for @entityOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get entityOrder;

  /// No description provided for @entityProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get entityProduct;

  /// No description provided for @attrId.
  ///
  /// In en, this message translates to:
  /// **'id'**
  String get attrId;

  /// No description provided for @attrName.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get attrName;

  /// No description provided for @attrEmail.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get attrEmail;

  /// No description provided for @attrUserId.
  ///
  /// In en, this message translates to:
  /// **'userId'**
  String get attrUserId;

  /// No description provided for @attrAccountId.
  ///
  /// In en, this message translates to:
  /// **'accountId'**
  String get attrAccountId;

  /// No description provided for @attrStatus.
  ///
  /// In en, this message translates to:
  /// **'status'**
  String get attrStatus;

  /// No description provided for @attrTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get attrTotal;

  /// No description provided for @attrSku.
  ///
  /// In en, this message translates to:
  /// **'sku'**
  String get attrSku;

  /// No description provided for @attrPrice.
  ///
  /// In en, this message translates to:
  /// **'price'**
  String get attrPrice;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'SimplyMind is a local, offline-first mind map. Maps stay on this device as JSON. This guide covers the home list, the canvas editor, starters, export, and install.'**
  String get helpIntro;

  /// No description provided for @helpHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home: your maps'**
  String get helpHomeTitle;

  /// No description provided for @helpHomeBody.
  ///
  /// In en, this message translates to:
  /// **'The home screen lists every mind map on this device, newest first. Tap a map to open the editor. Use the ⋮ menu on a row to rename, duplicate, move to a category, export JSON, or delete.\n\nThe + New mind map button starts a title, starter, and layout. Import JSON from the folder icon in the top bar.'**
  String get helpHomeBody;

  /// No description provided for @helpCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create: starter and layout'**
  String get helpCreateTitle;

  /// No description provided for @helpCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Starter is the content you begin with. Blank is one central node. PRD is a product-outline (problem, goals, users, requirements, scope). Entities is a sketch of related tables (User, Account, Order, Product) with fields as children — not a full database diagram.\n\nLayout is how nodes sit: Map (drag freely), List (outline), Step (numbered flow), Graph (around the parent). You can change layout later in the editor. Picking PRD suggests List; Entities suggests Graph.'**
  String get helpCreateBody;

  /// No description provided for @helpEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor: nodes and branches'**
  String get helpEditTitle;

  /// No description provided for @helpEditBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a node to select it and show the toolbar. Double-tap to edit text. + adds a child (in Map mode it finds free space near siblings). Drag a non-root node onto another to reparent. Promote (⇈) makes a node a sibling of its parent.\n\nIn List/Step/Graph, use the arrow buttons to reorder siblings. Branch template overrides layout for that subtree. Status (none / in progress / done) and color live on each node. Map settings (tune icon) change padding between text and the box.'**
  String get helpEditBody;

  /// No description provided for @helpCanvasTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas: zoom and focus'**
  String get helpCanvasTitle;

  /// No description provided for @helpCanvasBody.
  ///
  /// In en, this message translates to:
  /// **'Pinch or use + / − to zoom. Fit-all shows every node on screen (also used when you first open a map). Focus mode (fullscreen icon) hides the top bar and overlays so you can think on a wider canvas. The hint at the bottom summarizes drag, promote, and double-tap.'**
  String get helpCanvasBody;

  /// No description provided for @helpOrganizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get helpOrganizeTitle;

  /// No description provided for @helpOrganizeBody.
  ///
  /// In en, this message translates to:
  /// **'Maps start in Home. After many maps, SimplyMind offers categories. Create them from More or the chip row. Filter with All / Home / your names. Move a map from its ⋮ menu. Deleting a category sends maps back to Home; it does not delete the maps.'**
  String get helpOrganizeBody;

  /// No description provided for @helpExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export, import, and share'**
  String get helpExportTitle;

  /// No description provided for @helpExportBody.
  ///
  /// In en, this message translates to:
  /// **'In the editor, the share menu exports JSON (editable backup), PNG (picture of the whole map), or PDF. JSON import is on the home screen. PNG/PDF redraw the full tree — not a screenshot of the current zoom.'**
  String get helpExportBody;

  /// No description provided for @helpOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Web, install, and offline'**
  String get helpOfflineTitle;

  /// No description provided for @helpOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'On the website you can Add to Home Screen. After one online visit, the app can open without internet (service worker). Maps stay in local storage. Open the site on HTTPS. iOS may clear unused site data after weeks — export JSON if you need a backup. Native Android/iOS builds store data on the device without that web limit.'**
  String get helpOfflineBody;

  /// No description provided for @helpLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get helpLanguageTitle;

  /// No description provided for @helpLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'More → Language: follow the device, English, or Bahasa Indonesia. Menus and this guide change; text you typed in nodes does not.'**
  String get helpLanguageBody;

  /// No description provided for @helpFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback and legal'**
  String get helpFeedbackTitle;

  /// No description provided for @helpFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'More → Send feedback opens WhatsApp with a short pre-filled message. Privacy Policy and DMCA are in the same menu.'**
  String get helpFeedbackBody;

  /// No description provided for @relations.
  ///
  /// In en, this message translates to:
  /// **'Relations'**
  String get relations;

  /// No description provided for @manageRelations.
  ///
  /// In en, this message translates to:
  /// **'Manage relations'**
  String get manageRelations;

  /// No description provided for @addRelation.
  ///
  /// In en, this message translates to:
  /// **'Add relation'**
  String get addRelation;

  /// No description provided for @editRelation.
  ///
  /// In en, this message translates to:
  /// **'Edit relation'**
  String get editRelation;

  /// No description provided for @removeRelation.
  ///
  /// In en, this message translates to:
  /// **'Remove relation'**
  String get removeRelation;

  /// No description provided for @relationTarget.
  ///
  /// In en, this message translates to:
  /// **'Link to node'**
  String get relationTarget;

  /// No description provided for @relationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation label'**
  String get relationLabel;

  /// No description provided for @relationLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. belongs to'**
  String get relationLabelHint;

  /// No description provided for @relationCardinality.
  ///
  /// In en, this message translates to:
  /// **'Cardinality'**
  String get relationCardinality;

  /// No description provided for @relationCardinalityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. N:1'**
  String get relationCardinalityHint;

  /// No description provided for @noRelations.
  ///
  /// In en, this message translates to:
  /// **'No extra relations yet.'**
  String get noRelations;

  /// No description provided for @noRelationTargets.
  ///
  /// In en, this message translates to:
  /// **'Every other node is already linked.'**
  String get noRelationTargets;

  /// No description provided for @relationBelongsTo.
  ///
  /// In en, this message translates to:
  /// **'belongs to'**
  String get relationBelongsTo;

  /// No description provided for @relationContains.
  ///
  /// In en, this message translates to:
  /// **'contains'**
  String get relationContains;

  /// No description provided for @helpRelationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra relations'**
  String get helpRelationsTitle;

  /// No description provided for @helpRelationsBody.
  ///
  /// In en, this message translates to:
  /// **'A node has one parent for layout, but it can also have many extra relations. Select a node → Relations, choose another node, then add an optional label and cardinality (for example belongs to, N:1). Relations use curved dashed arrows attached to box edges and do not change the tree layout. A relation that duplicates a parent-child branch is not drawn twice.'**
  String get helpRelationsBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
