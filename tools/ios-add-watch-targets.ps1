# Patches ios/Runner.xcodeproj/project.pbxproj to add DozeAlertWatch +
# DozeAlertWatchWidgets targets and embed them in Runner.
# Idempotent: skips if DozeAlertWatch is already present.
# Run from repo root: powershell -File tools/ios-add-watch-targets.ps1

$ErrorActionPreference = "Stop"
$pbx = Join-Path $PSScriptRoot "..\ios\Runner.xcodeproj\project.pbxproj"
$pbx = (Resolve-Path $pbx).Path
$text = Get-Content -Raw -Path $pbx

if ($text -match 'DozeAlertWatch\.app') {
  Write-Host 'Watch targets already present in project.pbxproj - nothing to do.'
  exit 0
}

# Use single-quoted here-strings so PowerShell does not expand $(...) or choke on paths.
function Insert-BeforeMarker {
  param([string]$Content, [string]$Marker, [string]$Insert)
  if (-not $Content.Contains($Marker)) {
    throw "Marker not found: $Marker"
  }
  return $Content.Replace($Marker, ($Insert + "`r`n" + $Marker))
}

$buildFiles = @'
		36DAE8D84FA7FD06AB353AE9 /* DozeAlertWatchApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = F1EC8492282DB710EB326001 /* DozeAlertWatchApp.swift */; };
		374A1E0CE0B825DE1B0A0A74 /* TripScreen.swift in Sources */ = {isa = PBXBuildFile; fileRef = F3A0FB24B9ED949794764A53 /* TripScreen.swift */; };
		8F551B76E586294790031A0B /* AlarmScreen.swift in Sources */ = {isa = PBXBuildFile; fileRef = 14ECE462DD0458AB22C73661 /* AlarmScreen.swift */; };
		5D132BB65269660A6C50CAE6 /* TripStateStore.swift in Sources */ = {isa = PBXBuildFile; fileRef = 439842864138A1305D7EA928 /* TripStateStore.swift */; };
		0C843286D4812082BAC21F08 /* WatchAlarmController.swift in Sources */ = {isa = PBXBuildFile; fileRef = 01DBA930901941DAB10FC1D2 /* WatchAlarmController.swift */; };
		E81B29083F3BB4DA0E4FACC9 /* TripState.swift in Sources */ = {isa = PBXBuildFile; fileRef = 228A4AAE27C33B102858A3A9 /* TripState.swift */; };
		1332F45542FF4D03967FD3E4 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 430176535EB06EDB92DA3A1D /* Assets.xcassets */; };
		F99501FFCB1BEAD5A6D8EDEC /* DozeAlertWatchWidgets.swift in Sources */ = {isa = PBXBuildFile; fileRef = 50F047F2F1DA43D35F234E52 /* DozeAlertWatchWidgets.swift */; };
		B069EC4AA5864BF6E6EEB8D9 /* TripState.swift in Widgets Sources */ = {isa = PBXBuildFile; fileRef = 228A4AAE27C33B102858A3A9 /* TripState.swift */; };
		96DF9873C93408668F8F0B6F /* DozeAlertWatch.app in Embed Watch Content */ = {isa = PBXBuildFile; fileRef = DA440360527BBD7F6AE5C346 /* DozeAlertWatch.app */; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };
		DB3D11B2316359193E1B4687 /* DozeAlertWatchWidgets.appex in Embed Foundation Extensions */ = {isa = PBXBuildFile; fileRef = EDD6D98AE87E601AB04270D3 /* DozeAlertWatchWidgets.appex */; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };
'@

$fileRefs = @'
		DA440360527BBD7F6AE5C346 /* DozeAlertWatch.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DozeAlertWatch.app; sourceTree = BUILT_PRODUCTS_DIR; };
		EDD6D98AE87E601AB04270D3 /* DozeAlertWatchWidgets.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = DozeAlertWatchWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR; };
		F1EC8492282DB710EB326001 /* DozeAlertWatchApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DozeAlertWatchApp.swift; sourceTree = "<group>"; };
		F3A0FB24B9ED949794764A53 /* TripScreen.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TripScreen.swift; sourceTree = "<group>"; };
		14ECE462DD0458AB22C73661 /* AlarmScreen.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AlarmScreen.swift; sourceTree = "<group>"; };
		439842864138A1305D7EA928 /* TripStateStore.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TripStateStore.swift; sourceTree = "<group>"; };
		01DBA930901941DAB10FC1D2 /* WatchAlarmController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WatchAlarmController.swift; sourceTree = "<group>"; };
		6E70C31123D12E3085DF3AEA /* Watch Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = Info.plist; path = Info.plist; sourceTree = "<group>"; };
		679BC54D82BC902D2A0E8104 /* DozeAlertWatch.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = DozeAlertWatch.entitlements; sourceTree = "<group>"; };
		430176535EB06EDB92DA3A1D /* Watch Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = Assets.xcassets; path = Assets.xcassets; sourceTree = "<group>"; };
		228A4AAE27C33B102858A3A9 /* TripState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TripState.swift; sourceTree = "<group>"; };
		50F047F2F1DA43D35F234E52 /* DozeAlertWatchWidgets.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DozeAlertWatchWidgets.swift; sourceTree = "<group>"; };
		364D9A59063B64A92E3ABB3D /* Widgets Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = Info.plist; path = Info.plist; sourceTree = "<group>"; };
		5E5F70C51862967461D5CD0C /* DozeAlertWatchWidgets.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = DozeAlertWatchWidgets.entitlements; sourceTree = "<group>"; };
		72D5BB11C7363F381CF7A178 /* DozeAlert.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = DozeAlert.entitlements; sourceTree = "<group>"; };
'@

$proxies = @'
		799EF3552BDAFE7936EF5F53 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 97C146E61CF9000F007C117D /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = A98D45612B76313D21BED641;
			remoteInfo = DozeAlertWatch;
		};
		12163472D4390877FAD7E196 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 97C146E61CF9000F007C117D /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 539D5689C3030996081FCE4F;
			remoteInfo = DozeAlertWatchWidgets;
		};
'@

$copyPhases = @'
		982F7CCACDA7B84A167034B4 /* Embed Watch Content */ = {
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "$(CONTENTS_FOLDER_PATH)/Watch";
			dstSubfolderSpec = 16;
			files = (
				96DF9873C93408668F8F0B6F /* DozeAlertWatch.app in Embed Watch Content */,
			);
			name = "Embed Watch Content";
			runOnlyForDeploymentPostprocessing = 0;
		};
		2B71EA983FA4811BEBF1D512 /* Embed Foundation Extensions */ = {
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				DB3D11B2316359193E1B4687 /* DozeAlertWatchWidgets.appex in Embed Foundation Extensions */,
			);
			name = "Embed Foundation Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		};
'@

$frameworks = @'
		38608607C2F551A220CBF19A /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		E7597A21FB1BE9AE64C07955 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
'@

$groups = @'
		2177ED5C7DCA9994E8290BD8 /* DozeAlertWatch */ = {
			isa = PBXGroup;
			children = (
				F1EC8492282DB710EB326001 /* DozeAlertWatchApp.swift */,
				F3A0FB24B9ED949794764A53 /* TripScreen.swift */,
				14ECE462DD0458AB22C73661 /* AlarmScreen.swift */,
				439842864138A1305D7EA928 /* TripStateStore.swift */,
				01DBA930901941DAB10FC1D2 /* WatchAlarmController.swift */,
				6E70C31123D12E3085DF3AEA /* Watch Info.plist */,
				679BC54D82BC902D2A0E8104 /* DozeAlertWatch.entitlements */,
				430176535EB06EDB92DA3A1D /* Watch Assets.xcassets */,
			);
			path = DozeAlertWatch;
			sourceTree = "<group>";
		};
		EC2A06DDC9FA3AFE4492FC60 /* DozeAlertWatchWidgets */ = {
			isa = PBXGroup;
			children = (
				50F047F2F1DA43D35F234E52 /* DozeAlertWatchWidgets.swift */,
				364D9A59063B64A92E3ABB3D /* Widgets Info.plist */,
				5E5F70C51862967461D5CD0C /* DozeAlertWatchWidgets.entitlements */,
			);
			path = DozeAlertWatchWidgets;
			sourceTree = "<group>";
		};
		C6899F335C2417398DA68C08 /* DozeAlertWatchShared */ = {
			isa = PBXGroup;
			children = (
				228A4AAE27C33B102858A3A9 /* TripState.swift */,
			);
			path = DozeAlertWatchShared;
			sourceTree = "<group>";
		};
'@

$targets = @'
		A98D45612B76313D21BED641 /* DozeAlertWatch */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A848E34BB24AD80528993303 /* Build configuration list for PBXNativeTarget "DozeAlertWatch" */;
			buildPhases = (
				008EE9A4C2AB156494ED78D6 /* Sources */,
				38608607C2F551A220CBF19A /* Frameworks */,
				E49291DA3418D2575AD26D9E /* Resources */,
				2B71EA983FA4811BEBF1D512 /* Embed Foundation Extensions */,
			);
			buildRules = (
			);
			dependencies = (
				1058B1951E3FC3E8D4E62633 /* PBXTargetDependency */,
			);
			name = DozeAlertWatch;
			productName = DozeAlertWatch;
			productReference = DA440360527BBD7F6AE5C346 /* DozeAlertWatch.app */;
			productType = "com.apple.product-type.application";
		};
		539D5689C3030996081FCE4F /* DozeAlertWatchWidgets */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 30F61F89146FB274B4BA6FA0 /* Build configuration list for PBXNativeTarget "DozeAlertWatchWidgets" */;
			buildPhases = (
				A7EA33A176DFDE91A1CE3A54 /* Sources */,
				E7597A21FB1BE9AE64C07955 /* Frameworks */,
				6F4AC51B0250629EFFD7846F /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = DozeAlertWatchWidgets;
			productName = DozeAlertWatchWidgets;
			productReference = EDD6D98AE87E601AB04270D3 /* DozeAlertWatchWidgets.appex */;
			productType = "com.apple.product-type.app-extension";
		};
'@

$resources = @'
		E49291DA3418D2575AD26D9E /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				1332F45542FF4D03967FD3E4 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		6F4AC51B0250629EFFD7846F /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
'@

$sources = @'
		008EE9A4C2AB156494ED78D6 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				36DAE8D84FA7FD06AB353AE9 /* DozeAlertWatchApp.swift in Sources */,
				374A1E0CE0B825DE1B0A0A74 /* TripScreen.swift in Sources */,
				8F551B76E586294790031A0B /* AlarmScreen.swift in Sources */,
				5D132BB65269660A6C50CAE6 /* TripStateStore.swift in Sources */,
				0C843286D4812082BAC21F08 /* WatchAlarmController.swift in Sources */,
				E81B29083F3BB4DA0E4FACC9 /* TripState.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		A7EA33A176DFDE91A1CE3A54 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				F99501FFCB1BEAD5A6D8EDEC /* DozeAlertWatchWidgets.swift in Sources */,
				B069EC4AA5864BF6E6EEB8D9 /* TripState.swift in Widgets Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
'@

$deps = @'
		64FCD42B8D48D3C07DEBF18A /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = A98D45612B76313D21BED641 /* DozeAlertWatch */;
			targetProxy = 799EF3552BDAFE7936EF5F53 /* PBXContainerItemProxy */;
		};
		1058B1951E3FC3E8D4E62633 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 539D5689C3030996081FCE4F /* DozeAlertWatchWidgets */;
			targetProxy = 12163472D4390877FAD7E196 /* PBXContainerItemProxy */;
		};
'@

$watchConfigs = @'
		F364C30177BA6F20C24CF495 /* Debug */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatch/DozeAlertWatch.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatch/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = NO;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Debug;
		};
		0D3F31A3064AA127BEAEFA46 /* Release */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatch/DozeAlertWatch.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatch/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Release;
		};
		0314C291D8A30D4730434B9B /* Profile */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatch/DozeAlertWatch.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatch/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Profile;
		};
		5BF824C6687E15A5BE39A75C /* Debug */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				APPLICATION_EXTENSION_API_ONLY = YES;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatchWidgets/DozeAlertWatchWidgets.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatchWidgets/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = NO;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Debug;
		};
		1238009C1760798491E31E57 /* Release */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				APPLICATION_EXTENSION_API_ONLY = YES;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatchWidgets/DozeAlertWatchWidgets.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatchWidgets/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Release;
		};
		8719F179637F8590346BFC74 /* Profile */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = B7E4C0002F2A000100WATCHXC /* Watch.xcconfig */;
			buildSettings = {
				APPLICATION_EXTENSION_API_ONLY = YES;
				CODE_SIGN_ENTITLEMENTS = DozeAlertWatchWidgets/DozeAlertWatchWidgets.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DozeAlertWatchWidgets/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
				PRODUCT_BUNDLE_IDENTIFIER = app.dozealert.watch.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				VERSIONING_SYSTEM = "apple-generic";
				WATCHOS_DEPLOYMENT_TARGET = 10.0;
			};
			name = Profile;
		};
'@

$configLists = @'
		A848E34BB24AD80528993303 /* Build configuration list for PBXNativeTarget "DozeAlertWatch" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				F364C30177BA6F20C24CF495 /* Debug */,
				0D3F31A3064AA127BEAEFA46 /* Release */,
				0314C291D8A30D4730434B9B /* Profile */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		30F61F89146FB274B4BA6FA0 /* Build configuration list for PBXNativeTarget "DozeAlertWatchWidgets" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				5BF824C6687E15A5BE39A75C /* Debug */,
				1238009C1760798491E31E57 /* Release */,
				8719F179637F8590346BFC74 /* Profile */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
'@

$text = Insert-BeforeMarker $text '/* End PBXBuildFile section */' $buildFiles
$text = Insert-BeforeMarker $text '/* End PBXFileReference section */' $fileRefs
$text = Insert-BeforeMarker $text '/* End PBXContainerItemProxy section */' $proxies
$text = Insert-BeforeMarker $text '/* End PBXCopyFilesBuildPhase section */' $copyPhases
$text = Insert-BeforeMarker $text '/* End PBXFrameworksBuildPhase section */' $frameworks
$text = Insert-BeforeMarker $text '/* End PBXGroup section */' $groups
$text = Insert-BeforeMarker $text '/* End PBXNativeTarget section */' $targets
$text = Insert-BeforeMarker $text '/* End PBXResourcesBuildPhase section */' $resources
$text = Insert-BeforeMarker $text '/* End PBXSourcesBuildPhase section */' $sources
$text = Insert-BeforeMarker $text '/* End PBXTargetDependency section */' $deps
$text = Insert-BeforeMarker $text '/* End XCBuildConfiguration section */' $watchConfigs
$text = Insert-BeforeMarker $text '/* End XCConfigurationList section */' $configLists

# Normalize newlines so here-string literals match the pbxproj (CRLF vs LF).
$text = $text -replace "`r`n", "`n" -replace "`r", "`n"
function Norm([string]$s) { return ($s -replace "`r`n", "`n" -replace "`r", "`n") }

$oldRoot = Norm @'
		97C146E51CF9000F007C117D = {
			isa = PBXGroup;
			children = (
				9740EEB11CF90186004384FC /* Flutter */,
				97C146F01CF9000F007C117D /* Runner */,
				97C146EF1CF9000F007C117D /* Products */,
				331C8082294A63A400263BE5 /* RunnerTests */,
			);
'@
$newRoot = Norm @'
		97C146E51CF9000F007C117D = {
			isa = PBXGroup;
			children = (
				9740EEB11CF90186004384FC /* Flutter */,
				97C146F01CF9000F007C117D /* Runner */,
				2177ED5C7DCA9994E8290BD8 /* DozeAlertWatch */,
				EC2A06DDC9FA3AFE4492FC60 /* DozeAlertWatchWidgets */,
				C6899F335C2417398DA68C08 /* DozeAlertWatchShared */,
				97C146EF1CF9000F007C117D /* Products */,
				331C8082294A63A400263BE5 /* RunnerTests */,
			);
'@
if (-not $text.Contains($oldRoot)) { throw 'Root group block not found' }
$text = $text.Replace($oldRoot, $newRoot)

$oldProducts = Norm @'
		97C146EF1CF9000F007C117D /* Products */ = {
			isa = PBXGroup;
			children = (
				97C146EE1CF9000F007C117D /* Runner.app */,
				331C8081294A63A400263BE5 /* RunnerTests.xctest */,
			);
'@
$newProducts = Norm @'
		97C146EF1CF9000F007C117D /* Products */ = {
			isa = PBXGroup;
			children = (
				97C146EE1CF9000F007C117D /* Runner.app */,
				DA440360527BBD7F6AE5C346 /* DozeAlertWatch.app */,
				EDD6D98AE87E601AB04270D3 /* DozeAlertWatchWidgets.appex */,
				331C8081294A63A400263BE5 /* RunnerTests.xctest */,
			);
'@
if (-not $text.Contains($oldProducts)) { throw 'Products group block not found' }
$text = $text.Replace($oldProducts, $newProducts)

$oldEnt = 'A1B2C3D4E5F60718293A4B5F /* Runner.entitlements */,'
$newEnt = "A1B2C3D4E5F60718293A4B5F /* Runner.entitlements */,`n`t`t`t`t72D5BB11C7363F381CF7A178 /* DozeAlert.entitlements */,"
if (-not $text.Contains($oldEnt)) { throw 'Runner.entitlements ref not found' }
$text = $text.Replace($oldEnt, $newEnt)

$oldRunnerPhases = Norm @'
			buildPhases = (
				9740EEB61CF901F6004384FC /* Run Script */,
				97C146EA1CF9000F007C117D /* Sources */,
				97C146EB1CF9000F007C117D /* Frameworks */,
				97C146EC1CF9000F007C117D /* Resources */,
				9705A1C41CF9048500538489 /* Embed Frameworks */,
				3B06AD1E1E4923F5004D2608 /* Thin Binary */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Runner;
'@
$newRunnerPhases = Norm @'
			buildPhases = (
				9740EEB61CF901F6004384FC /* Run Script */,
				97C146EA1CF9000F007C117D /* Sources */,
				97C146EB1CF9000F007C117D /* Frameworks */,
				97C146EC1CF9000F007C117D /* Resources */,
				9705A1C41CF9048500538489 /* Embed Frameworks */,
				982F7CCACDA7B84A167034B4 /* Embed Watch Content */,
				3B06AD1E1E4923F5004D2608 /* Thin Binary */,
			);
			buildRules = (
			);
			dependencies = (
				64FCD42B8D48D3C07DEBF18A /* PBXTargetDependency */,
			);
			name = Runner;
'@
if (-not $text.Contains($oldRunnerPhases)) { throw 'Runner buildPhases block not found' }
$text = $text.Replace($oldRunnerPhases, $newRunnerPhases)

$oldAttrs = Norm @'
				TargetAttributes = {
					331C8080294A63A400263BE5 = {
						CreatedOnToolsVersion = 14.0;
						TestTargetID = 97C146ED1CF9000F007C117D;
					};
					97C146ED1CF9000F007C117D = {
						CreatedOnToolsVersion = 7.3.1;
						LastSwiftMigration = 1100;
					};
				};
'@
$newAttrs = Norm @'
				TargetAttributes = {
					331C8080294A63A400263BE5 = {
						CreatedOnToolsVersion = 14.0;
						TestTargetID = 97C146ED1CF9000F007C117D;
					};
					97C146ED1CF9000F007C117D = {
						CreatedOnToolsVersion = 7.3.1;
						LastSwiftMigration = 1100;
					};
					A98D45612B76313D21BED641 = {
						CreatedOnToolsVersion = 16.0;
					};
					539D5689C3030996081FCE4F = {
						CreatedOnToolsVersion = 16.0;
					};
				};
'@
if (-not $text.Contains($oldAttrs)) { throw 'TargetAttributes block not found' }
$text = $text.Replace($oldAttrs, $newAttrs)

$oldTargetsList = Norm @'
			targets = (
				97C146ED1CF9000F007C117D /* Runner */,
				331C8080294A63A400263BE5 /* RunnerTests */,
			);
'@
$newTargetsList = Norm @'
			targets = (
				97C146ED1CF9000F007C117D /* Runner */,
				A98D45612B76313D21BED641 /* DozeAlertWatch */,
				539D5689C3030996081FCE4F /* DozeAlertWatchWidgets */,
				331C8080294A63A400263BE5 /* RunnerTests */,
			);
'@
if (-not $text.Contains($oldTargetsList)) { throw 'Project targets list not found' }
$text = $text.Replace($oldTargetsList, $newTargetsList)

# Wire App Group entitlements on Runner Debug/Release/Profile target configs.
$needle = "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`r`n`t`t`t`tCLANG_ENABLE_MODULES = YES;`r`n`t`t`t`tCURRENT_PROJECT_VERSION"
$replacement = "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`r`n`t`t`t`tCLANG_ENABLE_MODULES = YES;`r`n`t`t`t`tCODE_SIGN_ENTITLEMENTS = Runner/DozeAlert.entitlements;`r`n`t`t`t`tCURRENT_PROJECT_VERSION"
# Normalize newlines for match
$normalized = $text -replace "`r`n", "`n"
$needleN = "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`n`t`t`t`tCLANG_ENABLE_MODULES = YES;`n`t`t`t`tCURRENT_PROJECT_VERSION"
$replN = "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;`n`t`t`t`tCLANG_ENABLE_MODULES = YES;`n`t`t`t`tCODE_SIGN_ENTITLEMENTS = Runner/DozeAlert.entitlements;`n`t`t`t`tCURRENT_PROJECT_VERSION"
$count = ([regex]::Matches($normalized, [regex]::Escape($needleN))).Count
if ($count -lt 3) {
  throw "Expected 3 Runner target configs to patch for entitlements, found $count"
}
$normalized = $normalized.Replace($needleN, $replN)
$text = $normalized -replace "`n", "`r`n"

Set-Content -Path $pbx -Value $text -NoNewline -Encoding utf8
Write-Host ('Patched {0} with DozeAlertWatch + DozeAlertWatchWidgets targets.' -f $pbx)
Write-Host 'On Mac: open ios/Runner.xcworkspace, set Team on Watch + Widgets, enable App Group group.app.dozealert.'