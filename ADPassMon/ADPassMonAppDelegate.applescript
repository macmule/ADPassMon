--  ADPassMonAppDelegate.applescript
--  ADPassMon
--
--  Created by Peter Bukowinski on 3/24/11 (and updated many times since)
--
--  This software is released under the terms of the MIT license.
--  Copyright (C) 2015 by Peter Bukowinski and Ben Toms
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--  
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--  
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.
---------------------------------------------------------------------------------

script ADPassMonAppDelegate

--- PROPERTIES ---    

--- Classes
    property parent :                   class "NSObject"
    property NSMenu :                   class "NSMenu"
    property NSThread :                 class "NSThread" -- for 'sleep'-like feature
    property NSMenuItem :               class "NSMenuItem"
    property NSTimer :                  class "NSTimer" -- so we can do stuff at regular intervals
    property NSUserNotificationCenter : class "NSUserNotificationCenter" -- for notification center
    property NSWorkspace :              class "NSWorkspace" -- for sleep notification
    property NSNumberFormatter :        class "NSNumberFormatter" -- for number formatting
    property NSLocale :                 class "NSLocale" -- for locale
    property NSApp  : current application's class "NSApp"
    
--- Objects
    property standardUserDefaults : missing value
    property statusMenu :           missing value
    property statusMenuController : missing value
    property theWindow :            missing value
    property defaults :             missing value -- for saved prefs
    property theMessage :           missing value -- for stats display in pref window
    property thePassword :          missing value
    property toggleNotifyButton :   missing value
    property processTimer :         missing value
    property domainTimer :          missing value
    property passwordPromptWindow : missing value
    property passwordPromptWindowText : missing value
    property passwordPromptWindowTitle : missing value
    property passwordPromptWindowButton1 : missing value
    property changePasswordPromptWindowTitle : "Change Password"
    property changePasswordPromptWindowButton1 : "Change"
    property changePasswordPromptWindowText : "Please complete all the fields below.
    
You must be connected to your organization's network to update your password.
    
Your login keychain will also be updated."
    property oldPassword : missing value
    property newPassword : missing value
    property verifyPassword : missing value
    property enteredOldPassword : missing value
    property enteredNewPassword : missing value
    property enteredVerifyPassword : missing value
    property checkKeychainLock : false
    property keychainState : missing value
    property isBehaviour2Enabled : missing value
    property unlockKeychainPasswordWindowTitle : "Your Keychain is locked!"
    property unlockKeychainPasswordWindowButton1 : "Update"
    property unlockKeychainPasswordWindowText : "If you know the last password you used to login to the Mac, please complete all the fields below and click Update.
    
If you do not know your keychain password, enter your new password in the New and Verify fields, then click 'Create New Keychain'."
    property pwPolicyTest : missing value
    property pwPolicyString : missing value
    property logMe : missing value
    property appVersion : missing value
    property buildVersion : missing value
    property userName : missing value
    property domain : missing value
    property numberFormatter : missing value
    property usLocale : missing value
    property digResult : missing value
    property manualExpireDays : missing value
    
--- Booleans
    property first_run :                true
    property runIfLocal :               false
    property isIdle :                   true
    property isHidden :                 false
    property enableNotifications :      true
    property enableKerbMinder :         false
    property prefsLocked :              false
    property launchAtLogin :            false
    property skipKerb :                 false
    property onDomain :                 false
    property freshDomain :              false
    property passExpires :              true
    property goEasy :                   false
    property showChangePass :           false
    property KerbMinderInstalled :      false
    property enablePasswordPromptWindowButton2 : false
    property firstPasswordCheckPassed : true
    property userPasswordChanged :      false
    property pwPolicyUpdateExternal :   false
    property allowPasswordChange :      true
    property keychainCreateNew :        false
    property enablePasswordPolicy :     false
    property keychainPolicyEnabled :    false
    property passwordCheckPassed :      false
    
--- Other Properties
    property accountStatus :            ""
    property warningDays :              14
    property menu_title :               "[ ? ]"
    property accTest :                  1
    property tooltip :                  "Waiting for data…"
    property osVersion :                ""
    property kerb :                     ""
    property myLDAP :                   ""
    property mySearchBase :             ""
    property expireAge :                60
    property expireAgeUnix :            ""
    property expireDate:                ""
    property expireDateUnix:            ""
    property uAC :                      ""
    property pwdSetDate :               ""
    property pwdSetDateUnix :           0
    property plistPwdSetDate :          0
    property pwPolicy :                 ""
    property pwPolicyButton :           "OK"
    property today :                    ""
    property todayUnix :                ""
    property daysUntilExp :             ""
    property daysUntilExpNice :         ""
    property expirationDate :           ""
    property mavAccStatus :             ""
    property passwordCheckInterval :    4  -- hours
    property enableKeychainLockCheck :  ""
    property selectedBehaviour :        1
    property keychainPolicy :           ""
    property pwPolicyURLButtonTitle :   ""
    property pwPolicyURLButtonURL :     ""
    property pwPolicyURLButtonBrowser : ""
    property selectedMethod :           0

--- HANDLERS ---

    -- General error handler
    on errorOut_(theError, showErr)
        set logMe to "Script Error: " & theError
        logToFile_(me)
        --if showErr = 1 then set my theMessage to theError as text
        --set isIdle to false
    end errorOut_

    -- Log Version of ADPassMon
    on logVersion_(sender)
        -- Get ADPassMon version & build number
        set mainBundle to current application's class "NSBundle"'s mainBundle()
        set appVersion to mainBundle's objectForInfoDictionaryKey_("CFBundleShortVersionString")
        set buildVersion to mainBundle's objectForInfoDictionaryKey_("CFBundleVersion")
        -- Log ADPassMon version
        set logMe to "ADPassMon Version: " & appVersion & " (" & buildVersion & ")"
        logToFile_(me)
    end logVersion_
    
    -- Need to get the OS version so we can handle Kerberos differently in 10.7+
    on getOS_(sender)
        set my osVersion to (do shell script "sw_vers -productVersion | awk -F. '{print $2}'") as integer
        set logMe to "Running on OS 10." & osVersion & ".x"
        logToFile_(me)
    end getOS_
    
    -- Get username, for folks with spaces in usernames
    on getUserName_(sender)
        set userName to short user name of (system info)
        set logMe to "Username: " & userName
        logToFile_(me)
    end getUserName_
    
    -- Check the status of the current account
    on localAccountStatus_(sender)
        try
            set isInLocalDS to (do shell script "dscl . read /Users/" & quoted form of userName & " AuthenticationAuthority") as string
        on error
            set isInLocalDS to "nope"
        end try
        try
            set isInSearchPath to (do shell script "dscl /Search read /Users/" & quoted form of userName & " AuthenticationAuthority") as string
        on error
            set isInSearchPath to "nope"
        end try
        
        if isInLocalDS is "nope"
            if isInSearchPath is "nope" then
                set my accountStatus to "Error"
                set logMe to "Something went wrong, can't find the current user in any directory service."
                logToFile_(me)
            else if "Active Directory" is in isInSearchPath or "NetLogon" is in isInSearchPath or "LocalCachedUser" is in isInSearchPath then
                set my accountStatus to "Network"
                set logMe to "Running under a network account."
                logToFile_(me)
            else
                set my accountStatus to "Error"
                set logMe to "Something went wrong, found the current user in the network directory path but the schema doesn't match."
                logToFile_(me)
            end if
        else
            if isInSearchPath is "nope" then
                set my accountStatus to "Local"
                set logMe to "Running under a local account."
                logToFile_(me)
            else if "Active Directory" is in isInLocalDS or "NetLogon" is in isInLocalDS or "LocalCachedUser" is in isInLocalDS then
                set my accountStatus to "Cached"
                set logMe to "Running under a locally cached network account."
                logToFile_(me)
            else if "Active Directory" is in isInSearchPath or "NetLogon" is in isInSearchPath or "LocalCachedUser" is in isInSearchPath then
                set my accountStatus to "Matched"
                set logMe to "Running under a local account with a matching AD account."
                logToFile_(me)
            else
                set my accountStatus to "Error"
                set logMe to "Something went wrong, found the current user in the search path but the schema doesn't match."
                logToFile_(me)
            end if
        end if
    end localAccountStatus_

    -- Check & log the selected Behaviour
    on doSelectedBehaviourCheck_(sender)
        if selectedBehaviour is 1
            useBehaviour1_(me)
            acctest_(me)
        else
            useBehaviour2_(me)
            set my passwordPromptWindowTitle to changePasswordPromptWindowTitle
            set my passwordPromptWindowButton1 to changePasswordPromptWindowButton1
            set my passwordPromptWindowText to changePasswordPromptWindowText
        end if
    end doSelectedBehaviourCheck_

    -- Tests if Universal Access scripting service is enabled
    on accTest_(sender)
        -- Skip if Behaviour 2 is selected
        if selectedBehaviour is 1
            set logMe to "Testing Universal Access settings…"
            logToFile_(me)
            if osVersion is less than 9
                tell application "System Events"
                    set accStatus to get UI elements enabled
                end tell
                if accStatus is true
                    set logMe to "Enabled 254"
                    logToFile_(me)
                else
                    set logMe to "Disabled"
                    logToFile_(me)
                    accEnable_(me)
                end if
            else -- if we're running 10.9 or later, Accessibility is handled differently
                tell defaults to set my accTest to objectForKey_("accTest")
                if accTest as integer is 1
                    if "80" is in (do shell script "/usr/bin/id -G") -- checks if user is in admin group
                        set accessDialog to (display dialog "ADPassMon's \"Change Password\" feature requires assistive access to open the password panel.
                        
    Enable it now? (requires password)" with icon 2 buttons {"No","Yes"} default button 2)
                        if button returned of accessDialog is "Yes"
                            set logMe to "Prompting for password"
                            logToFile_(me)
                            try
                                set mavAccStatus to (do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"SELECT * FROM access WHERE client='org.pmbuko.ADPassMon';\"" with administrator privileges)
                            end try
                            if mavAccStatus is ""
                                set logMe to "Not enabled"
                                logToFile_(me)
                                try
                                    if osVersion is less than 11
                                        do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"INSERT INTO access VALUES('kTCCServiceAccessibility','org.pmbuko.ADPassMon',0,1,1,NULL);\"" with administrator privileges
                                    else
                                        do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"INSERT INTO access VALUES('kTCCServiceAccessibility','org.pmbuko.ADPassMon',0,1,1,NULL,NULL);\"" with administrator privileges
                                    end if
                                    set my accTest to 0
                                    tell defaults to setObject_forKey_(0, "accTest")
                                on error theError
                                    set logMe to "Unable to set access. Error: " & theError
                                    logToFile_(me)
                                end try
                            else
                                set my accTest to 0
                                tell defaults to setObject_forKey_(0, "accTest")
                                set logMe to "Enabled"
                                logToFile_(me)
                            end if
                        end if
                    else
                        set my accTest to 0
                        tell defaults to setObject_forKey_(0, "accTest")
                        set logMe to "User not admin. Skipping."
                        logToFile_(me)
                    end if
                else
                    set logMe to "Skipping Accessibility check..."
                    logToFile_(me)
                end if
            end if
        else
            set logMe to "Skipping Universal Access Settings Testing..."
            logToFile_(me)
        end if
    end accTest_

    -- Prompts to enable Universal Access scripting service
    on accEnable_(sender)
        if "80" is in (do shell script "/usr/bin/id -G") -- checks if user is in admin group
            activate
            set response to (display dialog "ADPassMon's \"Change Password\" feature requires assistive access to open the password panel.
            
Enable it now?" with icon 2 buttons {"No","Yes"} default button 2)
            if button returned of response is "Yes"
                set logMe to "Prompting for password"
                logToFile_(me)
                try
                    tell application "System Events"
                        activate
                        set UI elements enabled to true
                    end tell
                    set logMe to "Now enabled"
                    logToFile_(me)
                on error theError
                    set logMe to "Error: " & theError
                    logToFile_(me)
                    activate
                    display dialog "Could not enable access for assistive devices." buttons {"OK"} default button 1
                end try
            else -- if No is clicked
                set logMe to "User chose not to enable"
                logToFile_(me)
            end if
        else
            set logMe to "Skipping because user not an admin"
            logToFile_(me)
        end if
    end accEnable_
    
    -- Check if Checking keychain lock is enabled
    on doKeychainLockCheck_(sender)
        tell defaults to set my enableKeychainLockCheck to objectForKey_("enableKeychainLockCheck") as integer
        if my enableKeychainLockCheck is 1
            set logMe to "Testing Keychain Lock state..."
            logToFile_(me)
            -- check for login keycchain path
            try
                do shell script "security unlock-keychain -p ~/Library/Keychains/login.keychain"
                set keychainState to "unlocked"
                set logMe to "Keychain unlocked..."
                logToFile_(me)
            on error
                set keychainState to "locked"
            end try
            -- If keychain is locked, the prompt user...
            if keychainState is "locked"
                set logMe to "Keychain locked..."
                logToFile_(me)
                closeKeychainAccess_(me)
            end if
        else
            set logMe to "Skipping Keychain Lock state check..."
            logToFile_(me)
        end if
    end doKeychainLockCheck_
    
    -- Check to see if KerbMinder installed
    on KerbMinderTest_(sender)
        tell application "Finder"
            if exists "/Library/Application Support/crankd/KerbMinder.py" as POSIX file
                set my KerbMinderInstalled to true
                set logMe to "KerbMinder installed..."
                logToFile_(me)
            else
                set my KerbMinderInstalled to false
            end if
        end tell
    end KerbMinderTest_

    -- Register plist default settings
    on regDefaults_(sender)
        set logMe to "Registering defaults.."
        logToFile_(me)
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({menu_title: "[ ? ]", ¬
                                            tooltip:tooltip, ¬
                                            first_run:first_run, ¬
                                            runIfLocal:runIfLocal, ¬
                                            passExpires:passExpires, ¬
                                            selectedMethod:0, ¬
                                            enableNotifications:enableNotifications, ¬
                                            passwordCheckInterval:passwordCheckInterval, ¬
                                            expireAge:expireAge, ¬
                                            expireDateUnix:expireDateUnix, ¬
                                            warningDays:warningDays, ¬
                                            prefsLocked:prefsLocked, ¬
                                            pwPolicy:pwPolicy, ¬
                                            pwPolicyButton:pwPolicyButton, ¬
                                            accTest:accTest, ¬
                                            enableKerbMinder:enableKerbMinder, ¬
                                            launchAtLogin:launchAtLogin, ¬
                                            enableKeychainLockCheck:0, ¬
                                            selectedBehaviour:1, ¬
                                            isBehaviour2Enabled:0, ¬
                                            keychainPolicy:keychainPolicy, ¬
                                            changePasswordPromptWindowTitle:changePasswordPromptWindowTitle, ¬
                                            changePasswordPromptWindowText:changePasswordPromptWindowText, ¬
                                            pwPolicyURLButtonTitle:pwPolicyURLButtonTitle, ¬
                                            pwPolicyURLButtonURL:pwPolicyURLButtonURL, ¬
                                            pwPolicyURLButtonBrowser:pwPolicyURLButtonBrowser, ¬
                                            allowPasswordChange:allowPasswordChange })
    end regDefaults_

    -- Get values from plist
    on retrieveDefaults_(sender)
        set logMe to "Retrieving defaults.."
        logToFile_(me)
        tell defaults to set my menu_title to objectForKey_("menu_title")
        tell defaults to set my first_run to objectForKey_("first_run")
        tell defaults to set my runIfLocal to objectForKey_("runIfLocal") as boolean
        tell defaults to set my passExpires to objectForKey_("passExpires") as boolean
        tell defaults to set my selectedMethod to objectForKey_("selectedMethod") as integer
        tell defaults to set my enableNotifications to objectForKey_("enableNotifications") as integer
        tell defaults to set my passwordCheckInterval to objectForKey_("passwordCheckInterval") as integer
        tell defaults to set my expireAge to objectForKey_("expireAge") as integer
        tell defaults to set my expireDateUnix to objectForKey_("expireDateUnix")
        tell defaults to set my warningDays to objectForKey_("warningDays")
        tell defaults to set my prefsLocked to objectForKey_("prefsLocked")
        tell defaults to set my pwPolicy to objectForKey_("pwPolicy")
        tell defaults to set my pwPolicyButton to objectForKey_("pwPolicyButton")
        tell defaults to set my accTest to objectForKey_("accTest") as integer
        tell defaults to set my enableKerbMinder to objectForKey_("enableKerbMinder")
        tell defaults to set my launchAtLogin to objectForKey_("launchAtLogin")
        tell defaults to set my enableKeychainLockCheck to objectForKey_("enableKeychainLockCheck") as integer
        tell defaults to set my selectedBehaviour to objectForKey_ ("selectedBehaviour") as integer
        tell defaults to set my isBehaviour2Enabled to objectForKey_("isBehaviour2Enabled") as integer
        tell defaults to set my keychainPolicy to objectForKey_("keychainPolicy") as string
        tell defaults to set my changePasswordPromptWindowTitle to objectForKey_("changePasswordPromptWindowTitle")
        tell defaults to set my changePasswordPromptWindowText to objectForKey_("changePasswordPromptWindowText")
        tell defaults to set my pwPolicyURLButtonTitle to objectForKey_("pwPolicyURLButtonTitle")
        tell defaults to set my pwPolicyURLButtonURL to objectForKey_("pwPolicyURLButtonURL")
        tell defaults to set my pwPolicyURLButtonBrowser to objectForKey_("pwPolicyURLButtonBrowser") as string
        tell defaults to set my allowPasswordChange to objectForKey_("allowPasswordChange")
    end retrieveDefaults_

    -- Disable notifications if running < 10.8
    on notifySetup_(sender)
        if osVersion is less than 8
            set my enableNotifications to false
        else
            -- set this app to handle notification responses
            current application's NSUserNotificationCenter's defaultUserNotificationCenter's setDelegate_(me)
        end if
    end notifySetup_
    
    -- notifications should always be displayed (can be overridden in system Notification prefs)
    on userNotificationCenter_shouldPresentNotification_(aCenter, aNotification)
        return yes
    end userNotificationCenter_shouldPresentNotification_
    
    -- handler for notification click events
    on userNotificationCenter_didActivateNotification_(aCenter, aNotification)
        set userActivationType to (aNotification's activationType) as integer
        -- 0 none
        -- 1 contents clicked
        -- 2 action button clicked
        if userActivationType is 1
            -- do something if contents are clicked. We're currently ignoring this.
        else if userActivationType is 2
            changePassword_(me)
        end if
    end userNotificationCenter_didActivateNotification_

    -- This handler is sent daysUntilExpNice and will trigger an alert if ≤ warningDays
    on doNotify_(sender)
        if sender as integer ≤ my warningDays as integer
            if osVersion is greater than 7
                if my enableNotifications as boolean is true
                    set logMe to "Triggering notification…"
                    logToFile_(me)
                    set ncTitle to "Password Expiration Warning"
                    set ncMessage to "Your password will expire in " & sender & " days on " & expirationDate
                    sendNotificationWithTitleAndMessage_(ncTitle, ncMessage)
                end if
            end if
        end if
    end doNotify_

    -- Notification text
    on sendNotificationWithTitleAndMessage_(aTitle, aMessage)
        set myNotification to current application's NSUserNotification's alloc()'s init()
        set myNotification's title to aTitle
        set myNotification's informativeText to aMessage
        set myNotification's actionButtonTitle to "Change"
        current application's NSUserNotificationCenter's defaultUserNotificationCenter's deliverNotification_(myNotification)
    end sendNotificationWithTitleAndMessage_

    -- Trigger doProcess handler on wake from sleep
    on watchForWake_(sender)
        tell (NSWorkspace's sharedWorkspace())'s notificationCenter() to ¬
            addObserver_selector_name_object_(me, "doProcessWithWait:", "NSWorkspaceDidWakeNotification", missing value)
    end watchForWake_

    -- Open Ticket Viewer
    on ticketViewer_(sender)
        tell application "Ticket Viewer" to activate
    end ticketViewer_

    -- Test to see if we're on the domain
    on domainTest_(sender)
        -- Test domain connectivity
        try
            set my digResult to (do shell script "/usr/bin/dig +time=2 +tries=1 -t srv _ldap._tcp." & domain) as text
            set my onDomain to true
            set logMe to "Domain test succeeded."
            logToFile_(me)
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(1)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(1)
        on error
            set logMe to "Domain test timed out."
            logToFile_(me)
            set my onDomain to false
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(0)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(0)
        end try
        -- For UI update
        delay 0.1
        -- If the get an answer from the above dig command
        if "ANSWER SECTION" is in digResult and my onDomain is true
            if my onDomain is false
                set my onDomain to true
                set my freshDomain to true
                set logMe to "Domain reachable."
                logToFile_(me)
            else
                set my freshDomain to false
            end if
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(1)
            -- Set variable to boolean
            set allowPasswordChange to allowPasswordChange as boolean
            tell defaults to set my pwPolicyURLButtonTitle to objectForKey_("pwPolicyURLButtonTitle") as string
            tell defaults to set my pwPolicyURLButtonURL to objectForKey_("pwPolicyURLButtonURL") as string
            -- If password change is allowed, show
            if allowPasswordChange is true
                my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(1)
            -- If password change is not allowed, but a password policy is set, show (as this will show policy).
            else if pwPolicyURLButtonTitle is not equal to "" and pwPolicyURLButtonURL is not equal to ""
                my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(1)
            end if
        else
            offlineUpdate_(me)
        end if

        -- Run this section only if the domain just became reachable.
        if my onDomain is true and my freshDomain is true
            canPassExpire_(me)
            -- If password can expire
            if passExpires
                -- if we're using Auto and we don't have the password expiration age, check for kerberos ticket
                if my expireDateUnix = 0 and selectedMethod = 0
                    doKerbCheck_(me)
                    if first_run -- only display prefs window if running for first time
                        if prefsLocked as integer is equal to 0 -- only display the window if prefs are not locked
                            set logMe to "First launch, waiting for settings..."
                            logToFile_(me)
                            theWindow's makeKeyAndOrderFront_(null)
                            set my theMessage to "Welcome!\nPlease choose your configuration options."
                            set first_run to false
                            tell defaults to setObject_forKey_(first_run, "first_run")
                        end if
                    end if
                else if my selectedMethod is 1
                    set my isHidden to false
                else if my selectedMethod is 0
                    set my isHidden to true
                end if
                watchForWake_(me)
            else
                set logMe to "Stopping."
                logToFile_(me)
                quit
            end if
        end if
    end domainTest_

    -- Check if password is set to never expire
    on canPassExpire_(sender)
        set logMe to "Testing if password can expire…"
        logToFile_(me)
        set my uAC to (do shell script "/usr/bin/dscl localhost read /Search/Users/" & quoted form of userName & " userAccountControl | /usr/bin/awk '/:userAccountControl:/{print $2}'")
        if (count words of uAC) is greater than 1
            set my uAC to last word of uAC
        end if
        try
            if first character of uAC is "6"
                set passExpires to false
                set logMe to "Password does not expire."
                logToFile_(me)
                my statusMenu's itemWithTitle_("Re-check Expiration")'s setEnabled_(passExpires as boolean)
                tell defaults to setObject_forKey_(passExpires, "passExpires")
                updateMenuTitle_("[--]", "Your password does not expire.")
                set my theMessage to "Your password does not expire."
                set logMe to theMessage
                logToFile_(me)
            else
                set logMe to "Password does expire."
                logToFile_(me)
            end if
        on error
            set logMe to "Could not determine if password expires."
            logToFile_(me)
        end try
    end canPassExpire_

    -- Checks for domain connectivity before checking for ticket. Also bound to Refresh Kerb menu item.
    on doKerbCheck_(sender)
        if my onDomain is true and my passExpires is true and my skipKerb is false
            if selectedMethod = 0
                doLionKerb_(me)
            else -- if selectedMethod = 1
                doProcess_(me)
            end if
        else -- if skipKerb is true
            doProcess_(me)
        end if
    end doKerbCheck_

    -- Need to handle Lion's kerberos differently from older OSes
    on doLionKerb_(sender)
        try
            set logMe to "Testing for Kerberos ticket…"
            logToFile_(me)
            set kerb to do shell script "/usr/bin/klist -t"
            set renewKerb to do shell script "/usr/bin/kinit -R"
            set logMe to "Ticket found and renewed"
            logToFile_(me)
            set my isIdle to true
            retrieveDefaults_(me)
            doProcess_(me)
        on error theError
            set my theMessage to "Kerberos ticket expired or not found"
            set logMe to theMessage
            logToFile_(me)
            activate
            set response to (display dialog "No Kerberos ticket for Active Directory was found. Do you want to renew it?" with icon 2 buttons {"No","Yes"} default button 2)
            if button returned of response is "Yes"
                renewLionKerb_(me)
            else -- if No is clicked
                set logMe to "User chose not to acquire"
                logToFile_(me)
                errorOut_(theError, 1)
            end if
        end try
    end doLionKerb_

    -- Runs when Yes of Lion kerberos renewal dialog (from above) is clicked.
    on renewLionKerb_(sender)
        try
            set thePassword to text returned of (display dialog "Enter your Active Directory password:" default answer "" with hidden answer)
            do shell script "/bin/echo '" & thePassword & "' | /usr/bin/kinit -l 10h -r 10h --password-file=STDIN"
            set logMe to "Ticket acquired"
            logToFile_(me)
            display dialog "Kerberos ticket acquired." with icon 1 buttons {"OK"} default button 1
            doLionKerb_(me)
        on error
            try
                set thePassword to text returned of (display dialog "Password incorrect. Please try again:" default answer "" with icon 2 with hidden answer)
                do shell script "/bin/echo '" & thePassword & "' | /usr/bin/kinit -l 24h -r 24h --password-file=STDIN"
                display dialog "Kerboros ticket acquired." with icon 1 buttons {"OK"} default button 1
                doLionKerb_(me)
            on error
                set logMe to "Incorrect password. Skipping."
                logToFile_(me)
                display dialog "Too many incorrect attempts. Stopping to avoid account lockout." with icon 2 buttons {"OK"} default button 1
            end try
        end try
    end renewLionKerb_

    -- Use dsconfigad to get domain name
    -- Use dig to get AD LDAP server from domain name
    on getADLDAP_(sender)
        try
            set myDomain to (do shell script "/usr/sbin/dsconfigad -show | /usr/bin/awk '/Active Directory Domain/{print $NF}'") as text
            try
                set myLDAPresult to (do shell script "/usr/bin/dig +time=2 +tries=1 -t srv _ldap._tcp." & myDomain) as text
            on error theError
                set logMe to "Launch domain test timed out."
                logToFile_(me)
                set my onDomain to false
            end try
            if "ANSWER SECTION" is in myLDAPresult
                set my onDomain to true
                -- using "first paragraph" to return only the first ldap server returned by the query
                set myLDAP to last paragraph of (do shell script "/usr/bin/dig -t srv _ldap._tcp." & myDomain & " | /usr/bin/awk '/^_ldap/{print $NF}'") as text
                set logMe to "myDomain: " & myDomain
                logToFile_(me)
                set logMe to "myLDAP: " & myLDAP
                logToFile_(me)
            else
                set my onDomain to false
                set logMe to "Can't reach " & myDomain & " domain"
                logToFile_(me)
            end if
        on error theError
            errorOut_(theError)
        end try
    end getADLDAP_

    -- Use ldapsearch to get search base
    on getSearchBase_(sender)
        try
            set my mySearchBase to (do shell script "/usr/bin/ldapsearch -LLL -Q -s base -H ldap://" & myLDAP & " defaultNamingContext | /usr/bin/awk '/defaultNamingContext/{print $2}'") as text
                set logMe to "mySearchBase: " & mySearchBase
                logToFile_(me)
        on error theError
            errorOut_(theError)
        end try
    end getSearchBase_

    -- Use ldapsearch to get password expiration age
    on getExpireAge_(sender)
        try
            set my expireAgeUnix to (do shell script "/usr/bin/ldapsearch -LLL -Q -s base -H ldap://" & myLDAP & " -b " & mySearchBase & " maxPwdAge | /usr/bin/awk -F- '/maxPwdAge/{print $NF/10000000}'") as integer
            if expireAgeUnix is equal to 0
                set logMe to "Couldn't get expireAge. Trying using Manual method."
                logToFile_(me)
            else
                set my expireAge to expireAgeUnix / 86400 as integer
                set logMe to "Got expireAge: " & expireAge
                logToFile_(me)
                tell defaults to setObject_forKey_(expireAge, "expireAge")
            end if
        on error theError
            errorOut_(theError, 1)
        end try
    end getExpireAge_

    -- Uses 'msDS-UserPasswordExpiryTimeComputed' value from AD to get expiration date.
    on easyMethod_(sender)
        try
            set expireDateResult to last paragraph of (do shell script "/usr/bin/dscl localhost read /Search/Users/" & quoted form of userName & " msDS-UserPasswordExpiryTimeComputed")
            if "msDS-UserPasswordExpiryTimeComputed" is in expireDateResult
                set my goEasy to true
                set my expireDate to last word of expireDateResult
            else
                set my goEasy to false
                return
            end if
            set my expireDateUnix to do shell script "echo '(" & expireDate & "/10000000)-11644473600' | /usr/bin/bc"
            set logMe to "Got expireDateUnix from msDS: " & expireDateUnix
            logToFile_(me)
            tell defaults to setObject_forKey_(expireDateUnix, "expireDateUnix")
        on error theError
            errorOut_(theError, 1)
        end try
    end easyMethod_

    -- Use epoch to get expiration date
    on easyDate_(timestamp)
        set my expirationDate to do shell script "/bin/date -r" & timestamp
        set logMe to "expirationDate: " & expirationDate
        logToFile_(me)
        set todayUnix to (do shell script "/bin/date +%s")
        set logMe to "Today epoch: " & todayUnix
        logToFile_(me)
        set my daysUntilExp to ((timestamp - todayUnix) / 86400)
        set logMe to "ms-DS daysUntilExp: " & daysUntilExp
        logToFile_(me)
        set my daysUntilExpNice to round daysUntilExp rounding down
        set logMe to "ms-DS daysUntilExpNice: " & daysUntilExpNice
        logToFile_(me)
        updateMenuTitle_(daysUntilExpNice, expirationDate)
    end easyDate_

    -- If ms-DS cannot be used, try via DSCL and if that fails LDAP
    on altMethod_(sender)
        getSearchBase_(me)
        -- If we're set to Automatic discovery
        if my selectedMethod is 0
            getExpireAge_(me)
        end if
        set my pwdSetDateUnix to (do shell script "/usr/bin/dscl localhost read /Search/Users/" & quoted form of userName & " SMBPasswordLastSet | /usr/bin/awk '/LastSet:/{print $2}'")
        if (count words of pwdSetDateUnix) is equal to 0
            set my pwdSetDateUnix to (do shell script "/usr/bin/ldapsearch -LLLL -Q -H ldap://" & myLDAP & " -b " & mySearchBase & " -s sub \"sAMAccountName=" & quoted form of userName & "\" pwdLastSet | /usr/bin/awk '/pwdLastSet:/{print $2}'")
            set logMe to "pwdSetDateUnix via LDAP: " & pwdSetDateUnix
            logToFile_(me)
        else
            set logMe to "pwdSetDateUnix via DSCL: " & last word of pwdSetDateUnix
            logToFile_(me)
        end if
        if pwdSetDateUnix is equal to 0
            set logMe to "Cannot get pwdSetDate"
            logToFile_(me)
        else
            set my pwdSetDateUnix to last word of pwdSetDateUnix
            set my pwdSetDateUnix to ((pwdSetDateUnix / 10000000) - 11644473600)
            set my pwdSetDate to numberFormatter's stringFromNumber_(pwdSetDateUnix)
            set logMe to "pwdSetDate epoch: " & pwdSetDate
            logToFile_(me)
            altGetExpiryDate_(me)
        end if
    end altMethod_

    -- Calculate the number of days until password expiration
    on altGetExpiryDate_(sender)
        try
            set todayUnix to (do shell script "/bin/date +%s")
            set logMe to "Today epoch: " & todayUnix
            logToFile_(me)
            set daysSinceSet to (todayUnix - pwdSetDate) / 86400
            set logMe to "Days Since Set: " & daysSinceSet
            logToFile_(me)
            set my daysUntilExp to (expireAge - daysSinceSet)
            set logMe to "alt daysUntilExp: " & daysUntilExp
            logToFile_(me)
            set my daysUntilExpNice to round daysUntilExp rounding down
            set logMe to "alt daysUntilExpNice: " & daysUntilExpNice
            logToFile_(me)
            set secondsTilExpiry to numberFormatter's stringFromNumber_((expireAge - daysSinceSet) * 86400 as integer)
            set logMe to "alt secondsTilExpiry: " & secondsTilExpiry
            logToFile_(me)
            set my expireDateUnix to numberFormatter's stringFromNumber_(todayUnix + secondsTilExpiry)
            set logMe to "Got expireDateUnix from alt: " & expireDateUnix
            logToFile_(me)
            tell defaults to setObject_forKey_(expireDateUnix, "expireDateUnix")
            set my expirationDate to do shell script "/bin/date -r" & expireDateUnix
            set logMe to "expirationDate: " & expirationDate
            logToFile_(me)
            updateMenuTitle_(daysUntilExpNice, expirationDate)
        on error theError
           errorOut_(theError, 1)
        end try
    end altGetExpiryDate_

    -- This is called when the domain is not accessible. It updates the menu display using data
    -- from the plist, which we assume was updated the last time the domain was accessible.
    on offlineUpdate_(sender)
        set logMe to "Offline. Updating menu…"
        logToFile_(me)
        try
            tell defaults to set my expireDateUnix to objectForKey_("expireDateUnix") as string
            set logMe to "Using expireDateUnix from plist: " & expireDateUnix
            logToFile_(me)
            set my todayUnix to (do shell script "/bin/date +%s") as string
            set logMe to "Today epoch: " & todayUnix
            logToFile_(me)
            set my daysUntilExp to (expireDateUnix - todayUnix) / 86400
            set logMe to "Offline daysUntilExp: " & daysUntilExp
            logToFile_(me)
            set my daysUntilExpNice to round daysUntilExp rounding down
            set logMe to "Offline daysUntilExpNice: " & daysUntilExpNice
            logToFile_(me)
            set my expirationDate to do shell script "/bin/date -r" & expireDateUnix
            set logMe to "Offline expirationDate: " & expirationDate
            logToFile_(me)
            updateMenuTitle_(daysUntilExpNice, expirationDate)
        end try
    end offlineUpdate_

    -- Updates the menu's title and tooltip
    on updateMenuTitle_(daysUntilExpNice, expirationDate)
        tell defaults to setObject_forKey_((daysUntilExpNice as string) & "d", "menu_title")
        tell defaults to setObject_forKey_("Your password expires on:\n" & expirationDate, "tooltip")
        set my isIdle to true
        set my theMessage to "Your password expires in " & daysUntilExpNice & " days\non " & expirationDate
        doNotify_(daysUntilExpNice)
        statusMenuController's updateDisplay()
    end updateMenuTitle_

    -- The meat of the app; gets the data and does the calculations 
    on doProcess_(sender)
        if my selectedMethod = 0
            set logMe to "Starting auto process…"
            logToFile_(me)
            set my isHidden to true
        else
            set logMe to "Starting manual process…"
            logToFile_(me)
            set my isHidden to false
        end if
        domainTest_(me)
        try
            if my onDomain is true
                theWindow's displayIfNeeded()
                set my theMessage to "Working…"
                set my isIdle to false
                logToFile_(me)
                getADLDAP_(me)
                -- Do this if we haven't run before, or the defaults have been reset.
                if my expireDateUnix = 0 and my selectedMethod = 0
                    easyMethod_(me)
                    if my goEasy is false
                        altMethod_(me)
                    end if
                else
                    easyMethod_(me)
                end if
                if my goEasy is true and my selectedMethod = 0
                    set logMe to "Using msDS method"
                    logToFile_(me)
                    altMethod_(me)
                    --easyDate_(expireDateUnix)
                else
                    set logMe to "Using alt method"
                    logToFile_(me)
                    altMethod_(me)
                end if
            end if
        on error theError
            errorOut_(theError, 1)
        end try
        -- Check for Selected Behaviour
        doSelectedBehaviourCheck_(me)
        -- Check for Keychain Lock
        doKeychainLockCheck_(me)
    end doProcess_
    
    on doProcessWithWait_(sender)
        tell current application's NSThread to sleepForTimeInterval_(15)
        doProcess_(me)
    end doProcessWithWait_

    on intervalDoProcess_(sender)
        doProcess_(me)
    end intervalDoProcess_

    on intervalDomainTest_(sender)
        domainTest_(me)
    end intervalDomainTest_

--- INTERFACE BINDING HANDLERS ---

    -- Bound to About item
    on about_(sender)
        activate
        current application's NSApp's orderFrontStandardAboutPanel_(null)
    end about_

    -- Bound to Change Password menu item
    on changePassword_(sender)
        -- Open System Preferences if Behaviour 1 is set
        if selectedBehaviour is 1
            tell defaults to set my pwPolicy to objectForKey_("pwPolicy") as string
            -- Display password policy
            if my pwPolicy is not ""
                pwPolicyDisplay_(me)
            end if
            -- Open System Preferences
            set allowPasswordChange to allowPasswordChange as boolean
            if allowPasswordChange is true
                tell application "System Preferences"
                    try -- to use UI scripting
                        set current pane to pane id "com.apple.preferences.users"
                        activate
                        delay 1
                        tell application "System Events"
                            tell application process "System Preferences"
                                click radio button "Password" of tab group 1 of window "Users & Groups"
                                click button "Change Password…" of tab group 1 of window "Users & Groups"
                                click button "Change Password…" of window 1
                            end tell
                        end tell
                        on error theError
                        errorOut_(theError, 1)
                    end try
                end tell
            end if
        else
            -- If Behaviour 2 is enabled, then use the different password change mechanism
            -- Close the Prefs window if open
            closeMainWindow_(me)
            -- Check for pwpolicy, & if set.. prompt
            tell defaults to set pwPolicy to objectForKey_("pwPolicy") as string
            if pwPolicy is not ""
                pwPolicyDisplay_(me)
            end if
            -- If user did not chose to update externally or was not prompted, then continue
            set allowPasswordChange to allowPasswordChange as boolean
            set pwPolicyUpdateExternal to pwPolicyUpdateExternal as boolean
            if allowPasswordChange is true
                if pwPolicyUpdateExternal is false
                    -- Set passwordPromptWindows settings
                    set my enablePasswordPromptWindowButton2 to false
                    set my passwordPromptWindowText to changePasswordPromptWindowText
                    showPasswordPromptWindow_(me)
                end if
            end if
        end if
    end changePassword_

    -- Check to see if Keychain Access is open, as can cause some issues. Prompt use to close
    on closeKeychainAccess_(sender)
        -- Close the Prefs window if open
        closeMainWindow_(me)
        tell application "System Events"
            set ProcessList to name of every process
            if "Keychain Access" is in ProcessList
                display dialog "Keychain Access needs to be closed to proceed." with icon 2 buttons {"Cancel","Close Keychain Access"} default button 2
                if button returned of the result is "Close Keychain Access"
                    set ThePID to unix id of process "Keychain Access"
                    do shell script "kill -KILL " & ThePID
                end if
            end if
        end tell
        -- Run the update keychain handler
        keychainPasswordPrompt_(me)
    end closeKeychainAccess_

    -- Launch the password prompt window to change Keychain Password
    on keychainPasswordPrompt_(sender)
        -- Show keychain policy if set
        tell defaults to set my keychainPolicy to objectForKey_("keychainPolicy") as string
        if keychainPolicy is not equal to ""
            tell application "System Events"
                display dialog keychainPolicy with icon 2 buttons {"OK"} default button 1
            end tell
        end if
        -- If the password prompt window is not set to change, then display Keychain unlock details.
        set my passwordPromptWindowTitle to unlockKeychainPasswordWindowTitle
        set my passwordPromptWindowButton1 to unlockKeychainPasswordWindowButton1
        set my passwordPromptWindowText to unlockKeychainPasswordWindowText
        set my enablePasswordPromptWindowButton2 to true
        -- Close the Prefs window if open
        closeMainWindow_(me)
        -- Show the password prompt window
        showPasswordPromptWindow_(me)
    end keychainPasswordPrompt_

    -- Check entered passwords
    on enteredPasswordCheck_(sender)
        -- Get the value of entered passwords
        set the enteredOldPassword to (oldPassword's stringValue()) as string
        set the enteredNewPassword to (newPassword's stringValue()) as string
        set the enteredVerifyPassword to (verifyPassword's stringValue()) as string
        -- Check that all password fields are filled out if changing password & not at keychain prompt
        if my passwordPromptWindowButton1 is equal to "Change"
            if enteredOldPassword is equal to "" or enteredNewPassword is equal to "" or enteredVerifyPassword is equal to ""
                tell application "System Events"
                    display dialog "Please fill out all password fields." with icon 2 buttons {"OK"} default button 1
                end tell
                changePassword_(me)
                set firstPasswordCheckPassed to false
            end if
        else
            if enteredNewPassword is equal to "" or enteredVerifyPassword is equal to ""
                tell application "System Events"
                    display dialog "Please fill out both the New & Verify password fields" with icon 2 buttons {"OK"} default button 1
                end tell
                keychainPasswordPrompt_(me)
                set firstPasswordCheckPassed to false
            end if
        end if
        -- If the above check have been passed, verify that the new & verify passwords are the same
        if firstPasswordCheckPassed is equal to true
            -- Check that the new & verify passwords are the same, prompt if not. Then return to password prompt window.
            if my enteredNewPassword does not equal enteredVerifyPassword
                tell application "System Events"
                    display dialog "Your New & Verified passwords did not match. Please try again." with icon 2 buttons {"OK"} default button 1
                end tell
                -- If fails, go back to handler that called this handler
                if my passwordPromptWindowButton1 is equal to "Change"
                    changePassword_(me)
                else
                    keychainPasswordPrompt_(me)
                end if
            else
                -- set to boolean of value
                set my keychainCreateNew to keychainCreateNew as boolean
                -- If we're creating a new keychain
                if keychainCreateNew is true
                    set logMe to "All password fields populated & new & verify match, proceeding with new keychain creation..."
                    createNewKeychain_(me)
                else
                    set logMe to "All password fields populated & new & verify match..."
                    attemptChangePassword_(me)
                end if
            end if
        end if
    end enteredPasswordCheck_

    -- Attempt change password -  the meat of v2 behaviour
    on attemptChangePassword_(sender)
        -- If changing password, change keychain pass too.
        if passwordPromptWindowButton1 is equal to "Change"
            updatePassword_(me)
        else
            set userPasswordChanged to true
            updateKeychainPassword_(me)
        end if
    end attemptChangePassword_

    -- Try & reset the users password via dscl
    on updatePassword_(sender)
        try
            set logMe to "Attempting user password change.."
            do shell script "dscl . -passwd /Users/" & quoted form of userName & " " & quoted form of enteredOldPassword & " " & quoted form of enteredNewPassword
            set logMe to "Password changed!"
            logToFile_(me)
            set userPasswordChanged to true
            -- Set Keychain settings to make sure they are unlocked
            setKeychainSettings_(me)
            updateKeychainPassword_(me)
        on error errStr
            -- Errors if not connected to org's network
            if errStr contains "eDSServiceUnavailable"
                set logMe to "Password change failed. Not connected?"
                logToFile_(me)
                display dialog "Password change failed. Please verify that you are connected to your organization's network and try again." with icon 2 buttons {"OK"} default button 1
                if button returned of the result is "OK"
                    changePassword_(me)
                end if
            -- Errors if password change fails due to old pass being wrong or new pass not meeting password policy requirements
            else if errStr contains "eDSAuthMethodNotSupported"
                set logMe to "Password change failed. Incorrect or doesn't meet policy."
                logToFile_(me)
                display dialog "Password change failed. Please verify that you have entered the correct password in the Old Password field and that your New Password meets your organization's password policy." with icon 2 buttons {"OK"} default button 1
                if button returned of the result is "OK"
                    changePassword_(me)
                end if
            -- Oops, not sure what happened.. :(
            else
                set logMe to "Password change failed."
                logToFile_(me)
                display dialog "Password change failed. Please try again." with icon 2 buttons {"OK"} default button 1
                if button returned of the result is "OK"
                    changePassword_(me)
                end if
            end if
        end try
    end updatePassword_

    -- Try & update the users keychain password
    on updateKeychainPassword_(sender)
        -- If we've changed password
        if userPasswordChanged is equal to true
            try
                -- Log Action
                set logMe to "Attempting Keychain unlock…"
                logToFile_(me)
                -- Unlock the keychain
                do shell script "security unlock-keychain -p " & quoted form of enteredOldPassword & " ~/Library/Keychains/login.keychain"
                -- Make sure that the Keychains password is set to what the new password
                set logMe to "Attempting keychain password update…"
                logToFile_(me)
                -- Set keychain password
                do shell script "security set-keychain-password -o " & quoted form of enteredOldPassword & " -p " & quoted form of enteredNewPassword & " ~/Library/Keychains/login.keychain"
                -- Log Action
                set logMe to "Keychain updated."
                logToFile_(me)
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
                -- Advise the user that it's worked
                display dialog "Update successful!" with icon 1 buttons {"OK"} default button 1
                -- Set to front window
                tell application "System Events" to set frontmost of process "ADPassMon" to true
            on error
                -- Log Action
                set logMe to "Keychain update failed."
                logToFile_(me)
                -- Display dialog to user
                display dialog "Keychain update failed. Please try again" with icon 2 buttons {"OK"} default button 1
                -- If OK button is clicked then try & update the users keychain password
                if button returned of the result is "OK" then keychainPasswordPrompt_(me)
            end try
        end if
    end updateKeychainPassword_

    on createNewKeychainButton_(sender)
        -- If create new keychain button was pressed,
        set my keychainCreateNew to true
        -- Check entered passwords
        enteredPasswordCheck_(me)
    end createNewKeychainButton_

    -- Create a new keychain
    on createNewKeychain_(sender)
        try
            -- Log option choosen
            set logMe to "User selected create new keychain."
            -- If running 10.9.+, then delete the local items keychain too
            if osVersion is greater than 8
                -- Get the Macs UUID
                set macUUID to do shell script "system_profiler SPHardwareDataType | awk '/Hardware UUID:/{ print $NF}'"
                try -- to delete the local items Keychain dbs
                    do shell script "rm -rf ~/Library/Keychains/" & macUUID & "/*"
                    set logMe to "Deleted local items keychain."
                    logToFile_(me)
                end try
                -- Delete the login Keychain
                deleteLoginKeychain_(me)
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
                -- 10.9.x needs the mac client to restart as securityd or another daemon process owned by the system is used to update the local items keychain
                set logMe to "Prompting to restart"
                logToFile_(me)
                display dialog "Your Mac needs to restart to finish updating your Keychain. Please dismiss any Local Items keychain prompts, close any open Applications and click Restart Now." with icon 0 buttons {"Later","Restart Now"} default button 2
                -- set to false
                set my keychainCreateNew to false
                -- Restart the Mac
                set logMe to "Restarting…"
                logToFile_(me)
                tell application "System Events" to restart
            else
                -- Delete the login Keychain
                deleteLoginKeychain_(me)
                -- Create a new login Keychain with the new password entered
                do shell script "security create-keychain -p " & quoted form of enteredNewPassword & " ~/Library/Keychains/login.keychain"
                set logMe to "New keychain created."
                logToFile_(me)
                -- set to false
                set my keychainCreateNew to false
                -- Set Keychain settings to make sure they are unlocked
                setKeychainSettings_(me)
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
            end if
        on error
            set logMe to "Creating a new keychain failed..."
            logToFile_(me)
            display dialog "New Keychain creation failed. Please try again" with icon 2 buttons {"OK"} default button 1
            if button returned of the result is "OK" then keychainPasswordPrompt_(me)
        end try
    end createNewKeychain_

    -- Deletes the login keychain using the security command
    on deleteLoginKeychain_(sender)
        try
            do shell script "security delete-keychain ~/Library/Keychains/login.keychain"
            set logMe to "Deleted old login keychain."
            logToFile_(me)
        on error -- If cannot find the login keychain, then prompt to create a new one.
            set logMe to "Couldn't find old Login Keychain."
            logToFile_(me)
            cannotFindKeychain_(me)
        end try
    end deleteLoginKeychain_

    -- Set Keychain settings to make sure they are unlocked
    on setKeychainSettings_(sender)
        -- Log Action
        set logMe to "Setting keychain settings"
        try
            -- Make sure keychain is not set to lock on sleep
            do shell script "security set-keychain-settings -l ~/Library/Keychains/login.keychain"
            -- Log Action
            set logMe to "Set to not lock at sleep"
            logToFile_(me)
            -- Make sure keychain is not set to lock after x minutes
            do shell script "security set-keychain-settings -u ~/Library/Keychains/login.keychain"
            -- Log Action
            set logMe to "Set to not lock at after time"
            logToFile_(me)
            --recheck expiration
            doProcess_(me)
        on error
            -- Log Action
            set logMe to "Error setting login.keychain settings..."
            logToFile_(me)
        end try
    end setKeychainSettings_

    -- If cannot find Keychain
    on cannotFindKeychain_(sender)
        -- Prompt user
        display dialog "No login keychain found. Please restart to create a new keychain." with icon 0 buttons ("Restart Now")
        try
            -- If running 10.9.+, then delete the local items keychain too
            if osVersion is greater than 8
                -- Get the Macs UUID
                set macUUID to do shell script "system_profiler SPHardwareDataType | awk '/Hardware UUID:/{ print $NF}'"
                -- Log Action
                set logMe to "Retrieved this Macs UUID..."
                logToFile_(me)
                try
                    -- Delete the local items Keychain db's if exists
                    do shell script "rm -rf ~/Library/Keychains/" & macUUID & "/*"
                    -- Log Action
                    set logMe to "Deleted local items keychain..."
                    logToFile_(me)
                end try
            end if
        end try
        -- Log Action
        set logMe to "Restarting..."
        logToFile_(me)
        -- Restart the Mac
        tell application "System Events" to restart
    end cannotFindKeychain_

    -- pwPolicy advanced display settings
    on pwPolicyDisplay_(sender)
        -- Retrieve pwPolicyURL's variables values, quoted to resolve issues with spaces
        tell defaults to set my pwPolicyURLButtonTitle to objectForKey_("pwPolicyURLButtonTitle") as string
        tell defaults to set my pwPolicyURLButtonURL to objectForKey_("pwPolicyURLButtonURL") as string
        tell defaults to set my pwPolicyURLButtonBrowser to objectForKey_("pwPolicyURLButtonBrowser") as string
        tell defaults to set my pwpolicyButton to objectForKey_("pwPolicyButton") as string
        -- Reset pwPolicyUpdateExternal so it's state isn't remembered accross multiple policy display calls
        set pwPolicyUpdateExternal to false
        -- If either pwPolicyURLButtonTitle or pwPolicyURLButtonURL is not set, then display standard pwPolicy prompt
        if pwPolicyURLButtonTitle is "" or pwPolicyURLButtonURL is ""
            -- If pwPolicyButton is not set
            if pwPolicyButton is ""
                -- Display password policy dialog
                tell application "System Events" to display dialog pwPolicy with icon 2 buttons {"OK"}
            -- if pwPolicyButton is set
            else
                -- Display password policy dialog with custom button
                tell application "System Events" to display dialog pwPolicy with icon 2 buttons {pwPolicyButton}
            end if
			-- Set variable to boolean
            set allowPasswordChange to allowPasswordChange as boolean
            -- If password change is  not allowed, then proceed
            if allowPasswordChange is false
                -- If password change is disabled, then don't proceed.
                set pwPolicyUpdateExternal to true
            end if
        -- If both pwPolicyURLButtonTitle or pwPolicyURLButtonURL are set, then display second button
        else if pwPolicyURLButtonTitle is not equal to "" and pwPolicyURLButtonURL is not equal to ""
            -- Display password policy dialog
            set allowPasswordChange to allowPasswordChange as boolean
            -- Change button text to better reflect behaviour when allowPasswordChange is set to false
            if  allowPasswordChange is true
                tell application "System Events" to display dialog pwPolicy with icon 2 buttons {"OK", pwPolicyURLButtonTitle}
            else
                tell application "System Events" to display dialog pwPolicy with icon 2 buttons {"Cancel", pwPolicyURLButtonTitle}
            end if
            -- If pwPolicyURLButtonTitle...
            if button returned of the result is pwPolicyURLButtonTitle
                -- If pwPolicyURLButton is not set, then open pwPolicyURLButtonURL in the default browser
                if pwPolicyURLButtonBrowser is equal to ""
                    -- Open URL in the default browser
                    open location pwPolicyURLButtonURL
                    -- If users chose the URL, then we don't want to proceed
                    set pwPolicyUpdateExternal to true
                -- If pwPolicyURLBrowser is set, then open pwPolicyURLButtonURL in the selected browser
                else
                    -- Open URL in the selected browser
                    tell application pwPolicyURLButtonBrowser to open location pwPolicyURLButtonURL
                    -- Bring selected browser to front
                    tell application pwPolicyURLButtonBrowser to activate
                    -- If users chose the URL, then we don't want to proceed
                    set pwPolicyUpdateExternal to true
                end if
            else
                -- Set variable to boolean
                set allowPasswordChange to allowPasswordChange as boolean
                -- If password change is  not allowed, then proceed
                if allowPasswordChange is false
                    -- If password change is disabled, then don't proceed.
                    set pwPolicyUpdateExternal to true
                end if
            end if
        end if
    end pwPolicyDisplay_

    -- Bound to Prefs menu item
    on showMainWindow_(sender)
        activate
        theWindow's makeKeyAndOrderFront_(null)
    end showMainWindow_

    -- Open Password Prompt window
    on showPasswordPromptWindow_(sender)
        set oldPassword's stringValue to "" as string
        set NewPassword's stringValue to "" as string
        set VerifyPassword's stringValue to "" as string
        activate
        passwordPromptWindow's makeKeyAndOrderFront_(me)
        set passwordPromptWindow's level to 3
    end showPasswordPromptWindow_

    -- Close the Prefs Menu
    on closeMainWindow_(sender)
        theWindow's orderOut_(null)
    end closeMainWindow_

    -- Close the password prompt window
    on closePasswordPromptWindow_(sender)
        passwordPromptWindow's orderOut_(null)
    end closePasswordPromptWindow_

    -- Bound to Quit menu item
    on quit_(sender)
        quit
    end quit_

    -- Bound to Auto radio buttons and Manual text field in Prefs window
    on useAutoMethod_(sender)
        set logMe to "Automatic expiration method..."
        logToFile_(me)
        set my isHidden to true
        set my selectedMethod to 0
        set my expireAge to ""
        tell defaults to removeObjectForKey_("expireAge")
        tell defaults to removeObjectForKey_("expireDateUnix")
        tell defaults to setObject:0 forKey:"selectedMethod"
        doProcess_(me)
    end useAutoMethod_

    -- Bound to Auto radio buttons and Manual text field in Prefs window
    on useManualMethod_(sender)
        set logMe to "Manual expiration method..."
        logToFile_(me)
        set my isHidden to false
        set my selectedMethod to 1
        tell defaults to set my expireAge to objectForKey_("expireAge") as integer
        tell defaults to setObject:1 forKey:"selectedMethod"
        tell defaults to setObject_forKey_(expireAge, "expireAge")
        doProcess_(me)
    end useManualMethod_

    -- Look for changes to text field, update as needed.
    on controlTextDidChange_(aNotification)
        set logMe to "whoop!"
        logToFile_(me)
        if aNotification's object() is manualExpireDays() then
            set expireAge to manualExpireDays's intValue()
            set logMe to "Manually set expire age to: " & expireAge
            logToFile_(me)
            doProcess_(me)
        end if
    end controlTextDidChange_

    -- Bound to Version 1 radio button on the Prefs window
    on useBehaviour1_(sender)
        set selectedBehaviour to 1
        set my isBehaviour2Enabled to 0
        tell defaults to setObject:1 forKey:"selectedBehaviour"
        tell defaults to setObject:0 forKey:"isBehaviour2Enabled"
        -- Disable Keychain Policy options
        set my keychainPolicyEnabled to false
        set logMe to "Native password method selected"
        logToFile_(me)
    end useBehaviour1_

    -- Bound to Version 2 radio button on the Prefs window
    on useBehaviour2_(sender)
        set selectedBehaviour to 2
        set my isBehaviour2Enabled to 1
        tell defaults to setObject:2 forKey:"selectedBehaviour"
        tell defaults to setObject:1 forKey:"isBehaviour2Enabled"
        -- Enable Keychain Policy options
        set my keychainPolicyEnabled to true
        set logMe to "ADPassMon password method selected"
        logToFile_(me)
    end useBehaviour2_

    -- Bound to warningDays box in Prefs window
    on setWarningDays_(sender)
        set my warningDays to sender's intValue() as integer
        tell defaults to setObject_forKey_(warningDays, "warningDays")
        set logMe to "Set warning days to " & warningDays
        logToFile_(me)
    end setWarningDays_

    -- Bound to passwordCheckInterval box in Prefs window
    on setPasswordCheckInterval_(sender)
        set my passwordCheckInterval to sender's intValue() as integer
        tell defaults to setObject_forKey_(passwordCheckInterval, "passwordCheckInterval")
        -- reset the timer
        resetIntervalTimer_(me)
    end setPasswordCheckInterval_

    -- Timer function
    on resetIntervalTimer_(sender)
        my processTimer's invalidate() -- kills the existing timer
        -- start a timer with the new interval
        set unit to " hours"
        if my passwordCheckInterval is equal to 1 then set unit to " hour"
        try
            set my processTimer to current application's NSTimer's scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_((my passwordCheckInterval as integer * 3600), me, "intervalDoProcess:", missing value, true)
            set logMe to "Set check interval to " & passwordCheckInterval & unit
        on error theError
            set logMe to "Could not reset check interval. Error: " & theError
        end try
    end resetIntervalTimer_

    -- Bound to Notify items in menu and Prefs window
    on toggleNotify_(sender)
        if my enableNotifications as boolean is true
            set my enableNotifications to false
            my statusMenu's itemWithTitle_("Use Notifications")'s setState_(0)
            tell defaults to setObject_forKey_(enableNotifications, "enableNotifications")
            set logMe to "Disabled notifications."
            logToFile_(me)
        else
            set my enableNotifications to true
            my statusMenu's itemWithTitle_("Use Notifications")'s setState_(1)
            tell defaults to setObject_forKey_(enableNotifications, "enableNotifications")
            set logMe to "Enabled notifications."
            logToFile_(me)
        end if
    end toggleNotify_
    
    on toggleKerbMinder_(sender)
        if my enableKerbMinder as boolean is true
            set my enableKerbMinder to false
            my statusMenu's itemWithTitle_("Use KerbMinder")'s setState_(0)
            tell defaults to setObject_forKey_(enableKerbMinder, "enableKerbMinder")
            set logMe to "Disabled KerbMinder."
            logToFile_(me)
        else
            set my enableKerbMinder to true
            my statusMenu's itemWithTitle_("Use KerbMinder")'s setState_(1)
            tell defaults to setObject_forKey_(enableKerbMinder, "enableKerbMinder")
            set logMe to "Enabled KerbMinder."
            logToFile_(me)
        end if
    end toggleKerbMinder_

    -- Bound to Check Keychain items in menu and Prefs window
    on toggleKeychainLockCheck_(sender)
        if my enableKeychainLockCheck is 1
            set my enableKeychainLockCheck to 0
            tell defaults to setObject_forKey_(0, "enableKeychainLockCheck")
            set logMe to "Keychain Lock Check disabled"
            logToFile_(me)
        else
            set my enableKeychainLockCheck to 1
            tell defaults to setObject_forKey_(1, "enableKeychainLockCheck")
            set logMe to " Keychain Lock Check enabled"
            logToFile_(me)
        end if
    end toggleKeychainLockCheck_

    -- Bound to Allow Password Change item in Prefs window
    on toggleAllowPasswordChange_(sender)
        -- set to boolean of value
        set allowPasswordChange to allowPasswordChange as boolean
        if allowPasswordChange is true
            set allowPasswordChange to false
            tell defaults to setObject_forKey_(allowPasswordChange, "allowPasswordChange")
            set logMe to "Password change disabled"
            logToFile_(me)
        else
            set allowPasswordChange to true
            tell defaults to setObject_forKey_(allowPasswordChange, "allowPasswordChange")
            set logMe to "Password change enabled"
            logToFile_(me)
        end if
    end toggleAllowPasswordChange_

    -- Bound to Revert button in Prefs window
    on revertDefaults_(sender)
        tell defaults to removeObjectForKey_("menu_title")
        tell defaults to removeObjectForKey_("first_run")
        tell defaults to removeObjectForKey_("passExpires")
        tell defaults to removeObjectForKey_("tooltip")
        tell defaults to removeObjectForKey_("selectedMethod")
        tell defaults to removeObjectForKey_("enableNotifications")
        tell defaults to removeObjectForKey_("passwordCheckInterval")
        tell defaults to removeObjectForKey_("expireAge")
        tell defaults to removeObjectForKey_("expireDateUnix")
        tell defaults to removeObjectForKey_("pwdSetDate")
        tell defaults to removeObjectForKey_("warningDays")
        tell defaults to removeObjectForKey_("prefsLocked")
        tell defaults to removeObjectForKey_("myLDAP")
        tell defaults to removeObjectForKey_("pwPolicy")
        tell defaults to removeObjectForKey_("pwPolicyButton")
        tell defaults to removeObjectForKey_("accTest")
        tell defaults to removeObjectForKey_("enableKerbMinder")
        tell defaults to removeObjectForKey_("enableKerbMinder")
        tell defaults to removeObjectForKey_("enableKeychainLockCheck")
        tell defaults to removeObjectForKey_("selectedBehaviour")
        tell defaults to removeObjectForKey_("isBehaviour2Enabled")
        tell defaults to removeObjectForKey_("keychainPolicy")
        tell defaults to removeObjectForKey_("changePasswordPromptWindowTitle")
        tell defaults to removeObjectForKey_("changePasswordPromptWindowText")
        tell defaults to removeObjectForKey_("pwPolicyURLButtonTitle")
        tell defaults to removeObjectForKey_("pwPolicyURLButtonURL")
        tell defaults to removeObjectForKey_("pwPolicyURLButtonBrowser")
        tell defaults to removeObjectForKey_("allowPasswordChange")
        tell defaults to removeObjectForKey_("passwordCheckInterval")
        do shell script "defaults delete org.pmbuko.ADPassMon"
        retrieveDefaults_(me)
        statusMenuController's updateDisplay()
        set my theMessage to "ADPassMon has been reset.
Please choose your configuration options."
        set logMe to theMessage
        logToFile_(me)
    end revertDefaults_

--- INITIAL LOADING SECTION ---
    
    -- Creates the status menu and its items, using some values determined by other handlers
    on createMenu_(sender)
        set statusMenu to (my NSMenu's alloc)'s initWithTitle_("statusMenu")
        statusMenu's setAutoenablesItems_(false)
        
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("About ADPassMon…")
        menuItem's setTarget_(me)
        menuItem's setAction_("about:")
        menuItem's setEnabled_(true)
        statusMenu's addItem_(menuItem)
        menuItem's release()

        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Use Notifications")
        menuItem's setTarget_(me)
        menuItem's setAction_("toggleNotify:")
        menuItem's setEnabled_(true)
        menuItem's setState_(enableNotifications as integer)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Use KerbMinder")
        menuItem's setTarget_(me)
        menuItem's setAction_("toggleKerbMinder:")
        menuItem's setEnabled_(true)
        menuItem's setHidden_(not KerbMinderInstalled)
        menuItem's setState_(enableKerbMinder as integer)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Preferences…")
        menuItem's setTarget_(me)
        menuItem's setAction_("showMainWindow:")
        menuItem's setEnabled_(not prefsLocked)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        statusMenu's addItem_(my NSMenuItem's separatorItem)
		
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Refresh Kerberos Ticket")
        menuItem's setTarget_(me)
        menuItem's setAction_("doKerbCheck:")
        menuItem's setEnabled_(onDomain as boolean)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Launch Ticket Viewer")
        menuItem's setTarget_(me)
        menuItem's setAction_("ticketViewer:")
        menuItem's setEnabled_(true)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Re-check Expiration")
        menuItem's setTarget_(me)
        menuItem's setAction_("doProcess:")
        menuItem's setEnabled_(passExpires as boolean)
        statusMenu's addItem_(menuItem)
        menuItem's release()

        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Change Password…")
        menuItem's setTarget_(me)
        menuItem's setAction_("changePassword:")
        menuItem's setEnabled_(onDomain as boolean)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        statusMenu's addItem_(my NSMenuItem's separatorItem)
		
        set menuItem to (my NSMenuItem's alloc)'s init
        menuItem's setTitle_("Exit")
        menuItem's setTarget_(me)
        menuItem's setAction_("quit:")
        menuItem's setEnabled_(true)
        statusMenu's addItem_(menuItem)
        menuItem's release()
        
        -- Instantiate the statusItemController object and set it to use the statusMenu we just created
        set statusMenuController to (current application's class "StatusMenuController"'s alloc)'s init
        statusMenuController's createStatusItemWithMenu_(statusMenu)
        statusMenu's release()
    end createMenu_

    -- Do processes necessary for app initiation
    on startMeUp_(sender)
        KerbMinderTest_(me)
        notifySetup_(me)
        doSelectedBehaviourCheck_(me) -- Check for Selected Behaviour
        createMenu_(me)  -- build and display the status menu item
        doProcess_(me)

        -- Set a timer to check for domain connectivity every ten minutes. (600)
        set my domainTimer to NSTimer's scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(600, me, "intervalDomainTest:", missing value, true)

        -- Set a timer to trigger doProcess handler on an interval and spawn notifications (if enabled).
        set my processTimer to NSTimer's scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_((my passwordCheckInterval * 3600), me, "intervalDoProcess:", missing value, true)

    end startMeUp_

    ----- LOGGING -----
    -- Log to file
    on logToFile_(sender)
        -- Comment out before release.. this will send log messages to Xcode's log
        --log logMe
        -- Get time & date of command execution for log file
        set timeStamp to do shell script "/bin/date"
        -- Write message to log file
        try
            do shell script "/bin/echo " & timeStamp & space & quoted form of logMe & ">> ~/Library/Logs/ADPassMon.log"
            on error
            -- Write message to log file
            do shell script "/bin/echo " & timeStamp & space & quoted form of logMe & ">> ~/Library/Logs/ADPassMon.log"
        end try
        -- Set to false so we don't create a newline until next time the app is run
        set logNewLine to false
    end logToFile_

    -- To try & correct decimal mark issues
    on setupNumberFormatter_(sender)
        set numberFormatter to NSNumberFormatter's alloc()'s init()
        set usLocale to NSLocale's alloc()'s initWithLocaleIdentifier_("en_US")
        numberFormatter's setUsesSignificantDigits_(true)
        numberFormatter's setMaximumSignificantDigits_(7)
        numberFormatter's setMinimumSignificantDigits_(1)
        numberFormatter's setDecimalSeparator_(".")
        numberFormatter's setNumberStyle:(current application's NSNumberFormatterNoStyle)
        set logMe to "Set number formatter"
        logToFile_(me)
    end setupNumberFormatter_

    on checkBound_(sender)
        -- Grab domain name from bind information, if bound
        set domain to (do shell script "/usr/sbin/dsconfigad -show | /usr/bin/awk '/Active Directory Domain/{print $NF}'") as text
    end checkBound_

    -- Do processes necessary for app initiation, but check if account is local first
    -- so we can break out if necessary
    on applicationWillFinishLaunching_(sender)
        set logMe to "Launching....."
        logToFile_(me) -- Logging function
        logVersion_(me) -- Log version of ADPassMon, including build
        getOS_(me) -- Get OS version of the mac running ADPassMon
        getUserName_(me) -- Get username, this includes those with spaces in the username
        setupNumberFormatter_(me) -- Remove formatting, for different decimal marks
        regDefaults_(me) -- Populate plist file with defaults (will not overwrite non-default settings))
        retrieveDefaults_(me) -- Load defaults (from plist)
        checkBound_(me) -- Check to see if we're bound. Exit if not.
        localAccountStatus_(me) -- Get account details
        -- quit if not bound, else proceed with account check
        if domain is equal to "" then
            set logMe to "Not bound, quitting..."
            logToFile_(me)
            quit
        -- if a "standard" AD setup
        else if my accountStatus is "Network" or accountStatus is "Cached" then
            startMeUp_(me)
        -- If a local account, but same username in AD found if runIfLocal set to true
        else if my accountStatus is "Matched" and my runIfLocal is true then
            set logMe to "Proceeding due to local account manual override."
            logToFile_(me)
            startMeUp_(me)
        -- If a local account, but if runIfLocal set to false
        else if my accountStatus is "Matched" and my runIfLocal is false then
            set logMe to "Local account manual override not enabled (runIfLocal)..."
            logToFile_(me)
            quit
        -- If something else happened
        else
            set logMe to "Something went wrong with account status check..."
            logToFile_(me)
            quit
        end if
    end applicationWillFinishLaunching_

    on applicationShouldTerminate_(sender)
        -- Terminate app
        return current application's NSTerminateNow
    end applicationShouldTerminate_

    -- This will immediately release the space in the menubar on quit
    on applicationWillTerminate_(notification)
        try -- adding this to avoid errors when running under local accounts
            statusMenuController's releaseStatusItem()
            statusMenuController's release()
        end try
    end applicationWillTerminate_

end script
