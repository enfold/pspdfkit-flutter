### Configuration Options

Here’s the complete list of configuration options supported by each platform. Note that some options are only supported on a single platform — that’s because of differences in the behavior of both of these platforms. Options that work on only one platform are prefixed with the appropriate platform name: `android` or `iOS`. The options, grouped by category, are shown below.

#### Document Interaction Options

| Configuration Option  | Data Type | Possible Values                               | iOS | Android | Documentation                                                                                                       |
| --------------------- | --------- | --------------------------------------------- | --- | ------- | ------------------------------------------------------------------------------------------------------------------- |
| `scrollDirection`     | `String`  | `horizontal`, `vertical`                      | ✅  | ✅      | Configures the direction of page scrolling in the document view.                                                    |
| `pageTransition`      | `String`  | `scrollPerSpread`, `scrollContinuous`, `curl` | ✅  | ✅      | Configures the page scrolling mode. Note that `curl` mode is only available for iOS and will be ignored on Android. |
| `enableTextSelection` | `Boolean` | `true` / `false`                              | ✅  | ✅      | Allow / disallow text selection.                                                                                    |

#### Document Presentation Options

| Configuration Option    | Data Type | Possible Values                 | iOS | Android | Documentation                                                                                   |
| ----------------------- | --------- | ------------------------------- | --- | ------- | ----------------------------------------------------------------------------------------------- |
| `pageMode`              | `String`  | `single`, `double`, `automatic` | ✅  | ✅      | Configure the page mode.                                                                        |
| `spreadFitting`         | `String`  | `fit`, `fill`, `adaptive`       | ✅  | ✅      | Controls the page fitting mode. `adaptive` mode only works on iOS and has no effect on Android. |
| `showPageLabels`        | `Boolean` | `true` / `false`                | ✅  | ✅      | Displays the current page number.                                                               |
| `startPage`             | `Integer` | -                               | ✅  | ✅      | Configures the starting page number.                                                            |
| `documentLabelEnabled`  | `Bool`    | `true` / `false`                | ✅  | ✅      | Shows an overlay displaying the document name.                                                  |
| `firstPageAlwaysSingle` | `Boolean` | `true` / `false`                | ✅  | ✅      | Option to show the first page separately.                                                       |
| `invertColors`          | `Boolean` | `true` / `false`                | ✅  | ✅      | Inverts the document color if `true`.                                                           |
| `password`              | `String`  | -                               | ✅  | ✅      | The password needed to unlock the document.                                                     |
| `androidGrayScale`      | `Boolean` | `true` / `false`                | ❌  | ✅      | Converts the document colors to grayscale.                                                      |

#### User Interface Options

| Configuration Option          | Data Type           | Possible Values                                                                                                                                                                                                                                                                                                                         | iOS | Android | Documentation                                                                                                                                                                                                         |
| ----------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inlineSearch`                | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ✅  | ✅      | Sets the type of search bar to be inline or modular.                                                                                                                                                                  |
| `toolbarTitle`                | `String`            | -                                                                                                                                                                                                                                                                                                                                       | ✅  | ✅      | Sets the title of the toolbar. Note: For iOS, you need to set `documentLabelEnabled`, `iOSUseParentNavigationBar`, and `iOSAllowToolbarTitleChange` to `false` in your configuration before setting the custom title. |
| `showActionNavigationButtons` | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ✅  | ✅      | Show action navigation buttons.                                                                                                                                                                                       |
| `userInterfaceViewMode`       | `String`            | `automatic`, `automaticBorderPages`, `automaticNoFirstLastPage`, `always`, `alwaysVisible`, `alwaysHidden`, `never`                                                                                                                                                                                                                     | ✅  | ✅      | Configures the user interface visibility.                                                                                                                                                                             |
| `immersiveMode`               | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ✅  | ✅      | Hides the user interface if set to `true`.                                                                                                                                                                            |
| `appearanceMode`              | `String`            | `default`, `night`, `sepia`                                                                                                                                                                                                                                                                                                             | ✅  | ✅      | Sets the appearance mode for the document.                                                                                                                                                                            |
| `settingsMenuItems`           | [Array of `String`] | `pageTransition`, `scrollDirection`, `androidTheme`, `iOSAppearance`, `androidPageLayout`, `iOSPageMode`, `iOSSpreadFitting`, `androidScreenAwake`, `iOSBrightness`                                                                                                                                                                     | ✅  | ✅      | Options that will be presented in the settings menu. The options prefixed with iOS or Android only work on the respective platform. Options without any prefix work on both platforms.                                |
| `androidShowSearchAction`     | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables / disables document search functionality. For iOS, add `searchButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                           |
| `androidShowOutlineAction`    | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables / disables outline menu in the activity. For iOS, add `outlineButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                           |
| `androidShowBookmarksAction`  | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables / disables the bookmark list. For iOS, add `bookmarkButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                                     |
| `androidShowShareAction`      | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables the display of share features. For iOS, add `activityButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                                    |
| `androidShowPrintAction`      | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables the printing option in the menu, if applicable, for the document and the device. For iOS, add `printButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.     |
| `androidShowDocumentInfoView` | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables the display of document information. For iOS, add `outlineButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                               |
| `androidEnableDocumentEditor` | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ❌  | ✅      | Enables / disables the document editor button. For iOS, add `documentEditorButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality.                                      |
| `androidDarkThemeResource`    | `String`            | -                                                                                                                                                                                                                                                                                                                                       | ❌  | ✅      | The resource string for the dark theme.                                                                                                                                                                               |
| `androidDefaultThemeResource` | `String`            | -                                                                                                                                                                                                                                                                                                                                       | ❌  | ✅      | The resource string for the default theme.                                                                                                                                                                            |
| `iOSLeftBarButtonItems`       | [Array of `String`] | `closeButtonItem`, `outlineButtonItem`, `searchButtonItem`, `thumbnailsButtonItem`, `documentEditorButtonItem`, `printButtonItem`, `openInButtonItem`, `emailButtonItem`, `messageButtonItem`, `annotationButtonItem`, `bookmarkButtonItem`, `brightnessButtonItem`, `activityButtonItem`, `settingsButtonItem`, `readerViewButtonItem` | ✅  | ❌      | Set the left bar button items. For Android, set individual options such as `androidShowOutlineAction`, `androidShowSearchAction`, etc. to achieve the same functionality.                                             |
| `iOSRightBarButtonItems`      | [Array of `String`] | `closeButtonItem`, `outlineButtonItem`, `searchButtonItem`, `thumbnailsButtonItem`, `documentEditorButtonItem`, `printButtonItem`, `openInButtonItem`, `emailButtonItem`, `messageButtonItem`, `annotationButtonItem`, `bookmarkButtonItem`, `brightnessButtonItem`, `activityButtonItem`, `settingsButtonItem`, `readerViewButtonItem` | ✅  | ❌      | Set the right bar button items. For Android, set individual options such as `androidShowOutlineAction`, `androidShowSearchAction`, etc. to achieve the same functionality.                                            |
| `iOSAllowToolbarTitleChange`  | `Boolean`           | `true` / `false`                                                                                                                                                                                                                                                                                                                        | ✅  | ❌      | Allow PSPDFKit to change the title of this view controller.                                                                                                                                                           |

#### Thumbnail Options

| Configuration Option             | Data Type | Possible Values                                                      | iOS | Android | Documentation                                                                                                                                                                                |
| -------------------------------- | --------- | -------------------------------------------------------------------- | --- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `showThumbnailBar`               | `String`  | `none`, `default`, `floating`, `pinned`, `scrubberBar`, `scrollable` | ✅  | ✅      | Thumbnail bar mode controls the display of page thumbnails viewing a document.                                                                                                               |
| `androidShowThumbnailGridAction` | `Boolean` | `true` / `false`                                                     | ❌  | ✅      | Displays an action bar icon to show a grid of thumbnail pages. For iOS, add `thumbnailsButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality. |

#### Annotation, Forms, and Bookmark Options

| Configuration Option              | Data Type | Possible Values  | iOS | Android | Documentation                                                                                                                                               |
| --------------------------------- | --------- | ---------------- | --- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enableAnnotationEditing`         | `Boolean` | `true` / `false` | ✅  | ✅      | Configuration to enable / disable editing all annotations.                                                                                                  |
| `androidShowAnnotationListAction` | `Boolean` | `true` / `false` | ❌  | ✅      | Enables the list of annotations. For iOS, add `outlineButtonItem` to `iOSLeftBarButtonItems` or `iOSRightBarButtonItems` to achieve the same functionality. |