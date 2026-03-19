#!/usr/bin/env bash

if [ -z "${MACOS_DEFAULTS}" ]; then
    echo "MACOS_DEFAULTS is not set, skipping..."
    exit 0
fi

set -eufo pipefail

# ~/.macos — https://mths.be/macos

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

run_or_warn() {
    local description="$1"
    shift

    if ! "$@"; then
        echo "warning: ${description} failed, continuing..." >&2
    fi
}

defaults_write_or_warn() {
    local domain="$1"
    local key="${2:-unknown}"
    shift 2

    if ! defaults write "${domain}" "${key}" "$@"; then
        echo "warning: defaults write for ${domain}.${key} failed, continuing..." >&2
    fi
}

sudo_defaults_write_or_warn() {
    local domain="$1"
    local key="${2:-unknown}"
    shift 2

    if ! sudo defaults write "${domain}" "${key}" "$@"; then
        echo "warning: sudo defaults write for ${domain}.${key} failed, continuing..." >&2
    fi
}

defaults_current_host_write_or_warn() {
    local domain="$1"
    local key="${2:-unknown}"
    shift 2

    if ! defaults -currentHost write "${domain}" "${key}" "$@"; then
        echo "warning: defaults -currentHost write for ${domain}.${key} failed, continuing..." >&2
    fi
}

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Set computer name (as done via System Preferences → Sharing)
#sudo scutil --set ComputerName "0x6D746873"
#sudo scutil --set HostName "0x6D746873"
#sudo scutil --set LocalHostName "0x6D746873"
#sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "0x6D746873"

# Set Dark apperance
defaults_write_or_warn NSGlobalDomain AppleInterfaceStyle Dark

# Set sidebar icon size to medium
defaults_write_or_warn NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Reduce spacing between menu bar items
# Reference: https://flaky.build/built-in-workaround-for-applications-hiding-under-the-macbook-pro-notch
defaults_write_or_warn -globalDomain NSStatusItemSelectionPadding -int 8
defaults_write_or_warn -globalDomain NSStatusItemSpacing -int 8
#ps -A | grep Core | grep -v grep | awk '{ print $1 }' | xargs kill -9
# # Revert to the original values
# defaults delete -globalDomain NSStatusItemSelectionPadding
# defaults delete -globalDomain NSStatusItemSpacing

# Always show scrollbars
defaults_write_or_warn NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
# Possible values: `WhenScrolling`, `Automatic` and `Always`

# Save to disk (not to iCloud) by default
defaults_write_or_warn NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable the “Are you sure you want to open this application?” dialog
defaults_write_or_warn com.apple.LaunchServices LSQuarantine -bool false

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
if "${LSREGISTER}" -h 2>&1 | grep -q -- " -kill"; then
    "${LSREGISTER}" -kill -r -domain local -domain system -domain user
else
    "${LSREGISTER}" -gc -all local,system,user
fi

# Display ASCII control characters using caret notation in standard text views
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
defaults_write_or_warn NSGlobalDomain NSTextShowsControlCharacters -bool true

# Set Help Viewer windows to non-floating mode
defaults_write_or_warn com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo_defaults_write_or_warn /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Disable automatic capitalization as it’s annoying when typing code
defaults_write_or_warn NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults_write_or_warn NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults_write_or_warn NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults_write_or_warn NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults_write_or_warn NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Enable press-and-hold for keys
defaults_write_or_warn NSGlobalDomain ApplePressAndHoldEnabled -bool true

# Set a blazingly fast keyboard repeat rate
defaults_write_or_warn NSGlobalDomain KeyRepeat -int 2
defaults_write_or_warn NSGlobalDomain InitialKeyRepeat -int 15

# Set language and text formats
defaults_write_or_warn NSGlobalDomain AppleLanguages -array "en-RS" "sr-RS" "sr-Latn-RS"
defaults_write_or_warn NSGlobalDomain AppleLocale -string "en_RS@currency=EUR"
defaults_write_or_warn NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults_write_or_warn NSGlobalDomain AppleMetricUnits -bool true

# Show language menu in the top right corner of the boot screen
sudo_defaults_write_or_warn /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set the timezone; see `sudo systemsetup -listtimezones` for other values
run_or_warn "set timezone to Europe/Belgrade" sudo systemsetup -settimezone "Europe/Belgrade" > /dev/null

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults_write_or_warn com.apple.screensaver askForPassword -int 1
defaults_write_or_warn com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults_write_or_warn com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults_write_or_warn com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults_write_or_warn com.apple.screencapture disable-shadow -bool true

# Enable subpixel font rendering on non-Apple LCDs
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults_write_or_warn NSGlobalDomain AppleFontSmoothing -int 1

# Enable HiDPI display modes (requires restart)
sudo_defaults_write_or_warn /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults_write_or_warn com.apple.finder QuitMenuItem -bool true

# Finder: disable window animations and Get Info animations
defaults_write_or_warn com.apple.finder DisableAllAnimations -bool true

# Set Home as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults_write_or_warn com.apple.finder NewWindowTarget -string "PfHm"
defaults_write_or_warn com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Finder: show hidden files by default
defaults_write_or_warn com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults_write_or_warn NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
#defaults write com.apple.finder ShowStatusBar -bool true

# Display full POSIX path as Finder window title
defaults_write_or_warn com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults_write_or_warn com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
#defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults_write_or_warn com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults_write_or_warn NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults_write_or_warn NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults_write_or_warn com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults_write_or_warn com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults_write_or_warn com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
defaults_write_or_warn com.apple.finder WarnOnEmptyTrash -bool false

# Show the ~/Library folder
#chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Set the icon size of Dock items to 16 pixels
defaults_write_or_warn com.apple.dock tilesize -int 16

# Minimize windows into their application’s icon
defaults_write_or_warn com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications in the Dock
defaults_write_or_warn com.apple.dock show-process-indicators -bool true

# Wipe all (default) app icons from the Dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
#defaults write com.apple.dock persistent-apps -array

# Don’t automatically rearrange Spaces based on most recent use
defaults_write_or_warn com.apple.dock mru-spaces -bool false

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

# Privacy: don’t send search queries to Apple
defaults_write_or_warn com.apple.Safari UniversalSearchEnabled -bool false
defaults_write_or_warn com.apple.Safari SuppressSearchSuggestions -bool true

# Press Tab to highlight each item on a web page
defaults_write_or_warn com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults_write_or_warn com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Show the full URL in the address bar (note: this still hides the scheme)
defaults_write_or_warn com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults_write_or_warn com.apple.Safari AutoOpenSafeDownloads -bool false

# Allow hitting the Backspace key to go to the previous page in history
defaults_write_or_warn com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# Disable Safari’s thumbnail cache for History and Top Sites
defaults_write_or_warn com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# Make Safari’s search banners default to Contains instead of Starts With
defaults_write_or_warn com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults_write_or_warn com.apple.Safari IncludeDevelopMenu -bool true
defaults_write_or_warn com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults_write_or_warn com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults_write_or_warn NSGlobalDomain WebKitDeveloperExtras -bool true

# Enable continuous spellchecking
defaults_write_or_warn com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
# Disable auto-correct
defaults_write_or_warn com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# Disable AutoFill
defaults_write_or_warn com.apple.Safari AutoFillFromAddressBook -bool false
defaults_write_or_warn com.apple.Safari AutoFillPasswords -bool false
defaults_write_or_warn com.apple.Safari AutoFillCreditCardData -bool false
defaults_write_or_warn com.apple.Safari AutoFillMiscellaneousForms -bool false

# Warn about fraudulent websites
defaults_write_or_warn com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Disable plug-ins
defaults_write_or_warn com.apple.Safari WebKitPluginsEnabled -bool false
defaults_write_or_warn com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false

# Block pop-up windows
defaults_write_or_warn com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults_write_or_warn com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false

# Disable auto-playing video
#defaults write com.apple.Safari WebKitMediaPlaybackAllowsInline -bool false
#defaults write com.apple.SafariTechnologyPreview WebKitMediaPlaybackAllowsInline -bool false
#defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false
#defaults write com.apple.SafariTechnologyPreview com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false

# Enable “Do Not Track”
defaults_write_or_warn com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Update extensions automatically
defaults_write_or_warn com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Mail                                                                        #
###############################################################################

# Disable send and reply animations in Mail.app
defaults_write_or_warn com.apple.mail DisableReplyAnimations -bool true
defaults_write_or_warn com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults_write_or_warn com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Display emails in threaded mode, sorted by date (oldest at the top)
defaults_write_or_warn com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults_write_or_warn com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults_write_or_warn com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

# Disable inline attachments (just show the icons)
defaults_write_or_warn com.apple.mail DisableInlineAttachmentViewing -bool true

# Disable automatic spell checking
defaults_write_or_warn com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

# Only use UTF-8 in Terminal.app
defaults_write_or_warn com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults_write_or_warn com.apple.terminal SecureKeyboardEntry -bool true

###############################################################################
# Time Machine                                                                #
###############################################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults_write_or_warn com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults_write_or_warn com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults_write_or_warn com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults_write_or_warn com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults_write_or_warn com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults_write_or_warn com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Address Book, Dashboard, iCal, TextEdit, and Disk Utility                   #
###############################################################################

# Use plain text mode for new TextEdit documents
defaults_write_or_warn com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults_write_or_warn com.apple.TextEdit PlainTextEncoding -int 4
defaults_write_or_warn com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the debug menu in Disk Utility
defaults_write_or_warn com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults_write_or_warn com.apple.DiskUtility advanced-image-options -bool true

###############################################################################
# Mac App Store                                                               #
###############################################################################

# Enable the automatic update check
defaults_write_or_warn com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults_current_host_write_or_warn com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

# Disable continuous spell checking
defaults_write_or_warn com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
	"Address Book" \
	"Calendar" \
	"cfprefsd" \
	"Contacts" \
	"Dock" \
	"Finder" \
	"Mail" \
	"Messages" \
	"Photos" \
	"Safari" \
	"SystemUIServer" \
	"Terminal" \
	"iCal"; do
	killall "${app}" &> /dev/null || true
done

killall Dock

launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

echo "Done. Note that some of these changes require a logout/restart to take effect."
