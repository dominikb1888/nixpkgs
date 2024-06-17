#!/bin/zsh
# Credit: Original idea and script disable.sh by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3

# Disabling unwanted services on macOS Big Sur (11), macOS Monterey (12) and macOS Ventura (13)
# Disabling SIP is required  ("csrutil disable" from Terminal in Recovery)
# Modifications are written in /private/var/db/com.apple.xpc.launchd/ disabled.plist, disabled.501.plist
# To revert, delete /private/var/db/com.apple.xpc.launchd/ disabled.plist and disabled.501.plist and reboot; sudo rm -r /private/var/db/com.apple.xpc.launchd/*


# user
TODISABLE=()

TODISABLE+=('com.apple.accessibility.MotionTrackingAgent' \
'com.apple.AMPArtworkAgent' \
'com.apple.AMPDeviceDiscoveryAgent' \
'com.apple.AMPLibraryAgent' \
'com.apple.AddressBook.ContactsAccountsService' \
'com.apple.AddressBook.abd' \
'com.apple.BiomeAgent' \
'com.apple.CalendarAgent' \
'com.apple.CallHistoryPluginHelper' \
'com.apple.CloudPhotosConfiguration' \
'com.apple.CloudSettingsSyncAgent' \
'com.apple.CommCenter-osx' \
'com.apple.ContactsAgent' \
'com.apple.CoreLocationAgent' \
'com.apple.DiagnosticReportCleanup.plist' \
'com.apple.ManagedClient.cloudconfigurationd' \
'com.apple.ManagedClientAgent.enrollagent' \
'com.apple.Maps.mapspushd' \
'com.apple.Maps.pushdaemon' \
'com.apple.ReportCrash' \
'com.apple.ReportCrash.Self' \
'com.apple.ReportPanic' \
'com.apple.Safari.SafeBrowsing.Service' \
'com.apple.SafariCloudHistoryPushAgent' \
'com.apple.SafariHistoryServiceAgent' \
'com.apple.SafariLaunchAgent' \
'com.apple.SafariNotificationAgent' \
'com.apple.SafariPlugInUpdateNotifier' \
'com.apple.ScreenTimeAgent' \
'com.apple.Siri.agent' \
'com.apple.TMHelperAgent' \
'com.apple.TMHelperAgent.SetupOffer' \
'com.apple.TrustEvaluationAgent' \
'com.apple.UsageTrackingAgent' \
'com.apple.WiFiVelocityAgent' \
'com.apple.ap.adprivacyd' \
'com.apple.ap.adservicesd' \
'com.apple.ap.promotedcontentd' \
'com.apple.appstoreagent' \
'com.apple.assistant_service' \
'com.apple.assistantd' \
'com.apple.avconferenced' \
'com.apple.biomesyncd' \
'com.apple.calaccessd' \
'com.apple.cloudd' \
'com.apple.cloudpaird' \
'com.apple.cloudphotod' \
'com.apple.dataaccess.dataaccessd' \
'com.apple.ensemble' \
'com.apple.familycircled' \
'com.apple.familycontrols.useragent' \
'com.apple.familynotificationd' \
'com.apple.financed' \
'com.apple.followupd' \
'com.apple.gamed' \
'com.apple.geod' \
'com.apple.geodMachServiceBridge' \
'com.apple.helpd' \
'com.apple.homed' \
'com.apple.iCloudNotificationAgent' \
'com.apple.iCloudUserNotifications' \
'com.apple.iTunesHelper.launcher' \
'com.apple.icloud.fmfd' \
'com.apple.icloud.searchpartyuseragent' \
'com.apple.imagent' \
'com.apple.imautomatichistorydeletionagent' \
'com.apple.imtransferagent' \
'com.apple.intelligenceplatformd' \
'com.apple.itunescloudd' \
'com.apple.knowledge-agent' \
'com.apple.macos.studentd' \
'com.apple.mediaanalysisd' \
'com.apple.mediastream.mstreamd' \
'com.apple.mobiledeviceupdater' \
'com.apple.networkserviceproxy' \
'com.apple.networkserviceproxy-osx' \
'com.apple.newsd' \
'com.apple.nsurlsessiond' \
'com.apple.parsec-fbf' \
'com.apple.parsecd' \
'com.apple.passd' \
'com.apple.photoanalysisd' \
'com.apple.photolibraryd' \
'com.apple.progressd' \
'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \
'com.apple.quicklook' \
'com.apple.quicklook.ThumbnailsAgent' \
'com.apple.quicklook.ui.helper' \
'com.apple.rapportd-user' \
'com.apple.remindd' \
'com.apple.routined' \
'com.apple.safaridavclient' \
'com.apple.screensharing.MessagesAgent' \
'com.apple.screensharing.agent' \
'com.apple.screensharing.menuextra' \
'com.apple.security.cloudkeychainproxy3' \
'com.apple.sharingd' \
'com.apple.sidecar-hid-relay' \
'com.apple.sidecar-relay' \
'com.apple.siri.context.service' \
'com.apple.siriknowledged' \
'com.apple.softwareupdate_notify_agent' \
'com.apple.suggestd' \
'com.apple.telephonyutilities.callservicesd' \
'com.apple.tipsd' \
'com.apple.triald' \
'com.apple.universalaccessd' \
'com.apple.videosubscriptionsd' \
'com.apple.weatherd')

for agent in "${TODISABLE[@]}"
do

	[ -f /System/Library/LaunchDaemons/${daemon}.plist ] && {
 	echo "- Daemon ${daemon} exists, disabling"
        sudo launchctl unload -wF /System/Library/LaunchDaemons/${daemon}.plist
        launchctl unload -wF /System/Library/LaunchDaemons/${daemon}.plist
	      mv /System/Library/LaunchDaemons/${daemon}.plist ~/DisabledLaunchDaemons/${daemon}.plist
	echo "[OK] Daemon ${daemon} disabled"
  } || {
 	echo "! Daemon ${daemon} does not exist"
  }

done

launchctl unload -w /System/Library/LaunchAgents/com.apple.cloudpaird.plist

# system
TODISABLE=()

TODISABLE+=('com.apple.bootpd' \
'com.apple.backupd' \
'com.apple.backupd-helper' \
'com.apple.cloudd' \
'com.apple.cloudpaird' \
'com.apple.cloudphotod' \
'com.apple.CloudPhotosConfiguration' \
'com.apple.CoreLocationAgent' \
'com.apple.coreduetd' \
'com.apple.dhcp6d' \
'com.apple.familycontrols' \
'com.apple.findmymacmessenger' \
'com.apple.followupd' \
'com.apple.FollowUpUI' \
'com.apple.ftp-proxy' \
'com.apple.ftpd' \
'com.apple.GameController.gamecontrollerd' \
'com.apple.icloud.fmfd' \
'com.apple.icloud.searchpartyd' \
'com.apple.itunescloudd' \
'com.apple.locationd' \
'com.apple.ManagedClient.cloudconfigurationd' \
'com.apple.networkserviceproxy' \
'com.apple.netbiosd' \
'com.apple.nsurlsessiond' \
'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \
'com.apple.rapportd' \
'com.apple.screensharing' \
'com.apple.security.cloudkeychainproxy3' \
'com.apple.siri.morphunassetsupdaterd' \
'com.apple.siriinferenced' \
'com.apple.triald.system' \
'com.apple.wifianalyticsd')

for daemon in "${TODISABLE[@]}"
do
	[ -f /System/Library/LaunchDaemons/${daemon}.plist ] && {
 	echo "- Daemon ${daemon} exists, disabling"
        sudo launchctl unload -wF /System/Library/LaunchDaemons/${daemon}.plist
        launchctl unload -wF /System/Library/LaunchDaemons/${daemon}.plist
	      mv /System/Library/LaunchDaemons/${daemon}.plist ~/DisabledLaunchDaemons/${daemon}.plist
	echo "[OK] Daemon ${daemon} disabled"
  } || {
 	echo "! Daemon ${daemon} does not exist"
  }
done
