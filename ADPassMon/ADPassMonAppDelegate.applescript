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

--- Objects
    property standardUserDefaults : missing value
    property statusMenu :           missing value
    property statusMenuController : missing value
    property theWindow :            missing value
    property defaults :             missing value -- for saved prefs
    property theMessage :           missing value -- for stats display in pref window
    property manualExpireDays :     missing value
    property selectedMethod :       missing value
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

--- Booleans
    property first_run :                true
    property runIfLocal :               false
    property isIdle :                   true
    property isHidden :                 false
    property isManualEnabled :          false
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
    property expireAge :                0
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

--- HANDLERS ---

    -- General error handler
    on errorOut_(theError, showErr)
        log "Script Error: " & theError
        --if showErr = 1 then set my theMessage to theError as text
        --set isIdle to false
    end errorOut_

    -- Need to get the OS version so we can handle Kerberos differently in 10.7+
    on getOS_(sender)
        set my osVersion to (do shell script "sw_vers -productVersion | awk -F. '{print $2}'") as integer
        log "Running on OS 10." & osVersion & ".x"
    end getOS_
    
    -- Check the status of the current account
    on localAccountStatus_(sender)
        try
            set isInLocalDS to (do shell script "dscl . read /Users/$USER AuthenticationAuthority") as string
        on error
            set isInLocalDS to "nope"
        end try
        
        try
            set isInSearchPath to (do shell script "dscl /Search read /Users/$USER AuthenticationAuthority") as string
        on error
            set isInSearchPath to "nope"
        end try
        
        if isInLocalDS is "nope"
            if isInSearchPath is "nope" then
                set my accountStatus to "Error"
                log "Something went wrong, can't find the current user in any directory service."
            else if "Active Directory" is in isInSearchPath or "NetLogon" is in isInSearchPath or "LocalCachedUser" is in isInSearchPath then
                set my accountStatus to "Network"
                log "Running under a network account."
            else
                set my accountStatus to "Error"
                log "Something went wrong, found the current user in the network directory path but the schema doesn't match."
            end if
        else
            if isInSearchPath is "nope" then
                set my accountStatus to "Local"
                log "Running under a local account."
            else if "Active Directory" is in isInLocalDS or "NetLogon" is in isInLocalDS or "LocalCachedUser" is in isInLocalDS then
                set my accountStatus to "Cached"
                log "Running under a locally cached network account."
            else if "Active Directory" is in isInSearchPath or "NetLogon" is in isInSearchPath or "LocalCachedUser" is in isInSearchPath then
                set my accountStatus to "Matched"
                log "Running under a local account with a matching AD account."
            else
                set my accountStatus to "Error"
                log "Something went wrong, found the current user in the search path but the schema doesn't match."
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
            log "Testing Universal Access settings…"
            if osVersion is less than 9
                tell application "System Events"
                    set accStatus to get UI elements enabled
                end tell
                if accStatus is true
                    log "  Enabled"
                else
                    log "  Disabled"
                    accEnable_(me)
                end if
            else -- if we're running 10.9 or later, Accessibility is handled differently
                tell defaults to set my accTest to objectForKey_("accTest")
                if accTest as integer is 1
                    if "80" is in (do shell script "/usr/bin/id -G") -- checks if user is in admin group
                        set accessDialog to (display dialog "ADPassMon's \"Change Password\" feature requires assistive access to open the password panel.
                        
    Enable it now? (requires password)" with icon 2 buttons {"No","Yes"} default button 2)
                        if button returned of accessDialog is "Yes"
                            log "  Prompting for password"
                            try
                                set mavAccStatus to (do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"SELECT * FROM access WHERE client='org.pmbuko.ADPassMon';\"" with administrator privileges)
                            end try
                            if mavAccStatus is ""
                                log "  Not enabled"
                                try
                                    if osVersion is less than 11
                                        do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"INSERT INTO access VALUES('kTCCServiceAccessibility','org.pmbuko.ADPassMon',0,1,1,NULL);\"" with administrator privileges
                                    else
                                        do shell script "sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' \"INSERT INTO access VALUES('kTCCServiceAccessibility','org.pmbuko.ADPassMon',0,1,1,NULL,NULL);\"" with administrator privileges
                                    end if
                                    set my accTest to 0
                                    tell defaults to setObject_forKey_(0, "accTest")
                                on error theError
                                    log "Unable to set access. Error: " & theError
                                end try
                            else
                                set my accTest to 0
                                tell defaults to setObject_forKey_(0, "accTest")
                                log "  Enabled"
                            end if
                        end if
                    else
                        set my accTest to 0
                        tell defaults to setObject_forKey_(0, "accTest")
                        log "  User not admin. Skipping."
                    end if
                else
                    log "  Enabled"
                end if
            end if
        else
            log "Skipping Universal Access Settings Testing..."
        end if
    end accTest_

    -- Prompts to enable Universal Access scripting service
    on accEnable_(sender)
        if "80" is in (do shell script "/usr/bin/id -G") -- checks if user is in admin group
            activate
            set response to (display dialog "ADPassMon's \"Change Password\" feature requires assistive access to open the password panel.
            
Enable it now?" with icon 2 buttons {"No","Yes"} default button 2)
            if button returned of response is "Yes"
                log "  Prompting for password"
                try
                    tell application "System Events"
                        activate
                        set UI elements enabled to true
                    end tell
                    log "  Now enabled"
                on error theError
                    log "  Error: " & theError
                    activate
                    display dialog "Could not enable access for assistive devices." buttons {"OK"} default button 1
                end try
            else -- if No is clicked
                log "  User chose not to enable"
            end if
        else
            log "  Skipping because user not an admin"
        end if
    end accEnable_
    
    -- Check if Checking keychain lock is enabled
    on doKeychainLockCheck_(sender)
        tell defaults to set my enableKeychainLockCheck to objectForKey_("enableKeychainLockCheck") as integer
        if my enableKeychainLockCheck is 1
            log "Testing Keychain Lock state..."
            -- check for login keycchain path
            try
                do shell script "security unlock-keychain -p ~/Library/Keychains/login.keychain"
                set keychainState to "unlocked"
                log "  Keychain unlocked..."
            on error
                set keychainState to "locked"
            end try
            -- If keychain is locked, the prompt user...
            if keychainState is "locked"
                log "  Keychain locked..."
                closeKeychainAccess_(me)
            end if
        else
            log "Skipping Keychain Lock state check..."
        end if
    end doKeychainLockCheck_
    
    -- Check to see if KerbMinder installed
    on KerbMinderTest_(sender)
        tell application "Finder"
            if exists "/Library/Application Support/crankd/KerbMinder.py" as POSIX file
                set my KerbMinderInstalled to true
                log "  KerbMinder installed..."
            else
                set my KerbMinderInstalled to false
            end if
        end tell
    end KerbMinderTest_

    -- Register plist default settings
    on regDefaults_(sender)
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({menu_title: "[ ? ]", ¬
                                            tooltip:tooltip, ¬
                                            first_run:first_run, ¬
                                            runIfLocal:runIfLocal, ¬
                                            passExpires:passExpires, ¬
                                            selectedMethod:0, ¬
                                            isManualEnabled:isManualEnabled, ¬
                                            enableNotifications:enableNotifications, ¬
                                            passwordCheckInterval:passwordCheckInterval, ¬
                                            expireAge:expireAge, ¬
                                            expireDateUnix:expireDateUnix, ¬
                                            pwdSetDate:pwdSetDate, ¬
                                            warningDays:warningDays, ¬
                                            prefsLocked:prefsLocked, ¬
                                            myLDAP:myLDAP, ¬
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
        tell defaults to set my menu_title to objectForKey_("menu_title")
        tell defaults to set my first_run to objectForKey_("first_run")
        tell defaults to set my runIfLocal to objectForKey_("runIfLocal") as boolean
        tell defaults to set my passExpires to objectForKey_("passExpires") as boolean
        tell defaults to set my selectedMethod to objectForKey_("selectedMethod") as integer
        tell defaults to set my isManualEnabled to objectForKey_("isManualEnabled") as integer
        tell defaults to set my enableNotifications to objectForKey_("enableNotifications") as integer
        tell defaults to set my passwordCheckInterval to objectForKey_("passwordCheckInterval") as integer
        tell defaults to set my expireAge to objectForKey_("expireAge") as integer
        tell defaults to set my expireDateUnix to objectForKey_("expireDateUnix") as integer
        tell defaults to set my pwdSetDate to objectForKey_("pwdSetDate") as integer
        tell defaults to set my warningDays to objectForKey_("warningDays")
        tell defaults to set my prefsLocked to objectForKey_("prefsLocked")
        tell defaults to set my myLDAP to objectForKey_("myLDAP")
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
                    log "Triggering notification…"
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
        set domain to (do shell script "/usr/sbin/dsconfigad -show | /usr/bin/awk '/Active Directory Domain/{print $NF}'") as text
        try
            set digResult to (do shell script "/usr/bin/dig +time=2 +tries=1 -t srv _ldap._tcp." & domain) as text
        on error theError
            log "Domain test timed out."
            set my onDomain to false
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(0)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(0)
            return
        end try
        if "ANSWER SECTION" is in digResult
            set my onDomain to true
            log "Domain reachable."
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
            set my onDomain to false
            log "Domain not reachable."
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(0)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(0)
        end if
    end domainTest_

       -- Test to see if we're on the domain
    on intervalDomainTest_(sender)

        -- Grab domain name from bind information
        set domain to (do shell script "/usr/sbin/dsconfigad -show | /usr/bin/awk '/Active Directory Domain/{print $NF}'") as text
        
        -- Test domain connectivity
        try
            set digResult to (do shell script "/usr/bin/dig +time=2 +tries=1 -t srv _ldap._tcp." & domain) as text
        on error theError
            log "Domain test timed out."
            set my onDomain to false
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(0)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(0)
            return
        end try
        
        -- For UI update
        delay 0.1
        
        -- If the get an answer from the above dig command
        if "ANSWER SECTION" is in digResult
            if my onDomain is false
                set my onDomain to true
                set my freshDomain to true
                log "Domain reachable."
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
            set my onDomain to false
            log "Domain not reachable."
            my statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(0)
            my statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(0)
        end if

        -- Run this section only if the domain just became reachable.
        if my onDomain is true and my freshDomain is true
            canPassExpire_(me)
            -- If password can expire
            if passExpires
                -- if we're using Auto and we don't have the password expiration age, check for kerberos ticket
                if my expireDateUnix = 0 and my selectedMethod = 0
                    doKerbCheck_(me)
                    if first_run -- only display prefs window if running for first time
                        if prefsLocked as integer is equal to 0 -- only display the window if prefs are not locked
                            log "First launch, waiting for settings..."
                            theWindow's makeKeyAndOrderFront_(null)
                            set my theMessage to "Welcome!\nPlease choose your configuration options."
                            set first_run to false
                            tell defaults to setObject_forKey_(first_run, "first_run")
                        end if
                    end if
                else if my selectedMethod is 1
                    set my manualExpireDays to expireAge
                    set my isHidden to true
                    set my isManualEnabled to true
                    doProcess_(me)
                else if my selectedMethod is 0
                    set my isHidden to false
                    set my isManualEnabled to false
                    set my manualExpireDays to ""
                    doProcess_(me)
                end if

                watchForWake_(me)

            else
                log "Stopping."
            end if
        end if
    end intervalDomainTest_

    -- Check if password is set to never expire
    on canPassExpire_(sender)
        log "Testing if password can expire…"
        set my uAC to (do shell script "/usr/bin/dscl localhost read /Search/Users/$USER userAccountControl | /usr/bin/awk '/:userAccountControl:/{print $2}'")
        if (count words of uAC) is greater than 1
            set my uAC to last word of uAC
        end if
        try
            if first character of uAC is "6"
                set passExpires to false
                log "  Password does not expire."
                my statusMenu's itemWithTitle_("Re-check Expiration")'s setEnabled_(passExpires as boolean)
                tell defaults to setObject_forKey_(passExpires, "passExpires")
                updateMenuTitle_("[--]", "Your password does not expire.")
                set my theMessage to "Your password does not expire."
            else
                log "  Password does expire."
            end if
        on error
            log "  Could not determine if password expires."
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
            log "Testing for Kerberos ticket…"
            set kerb to do shell script "/usr/bin/klist -t"
            set renewKerb to do shell script "/usr/bin/kinit -R"
            log "  Ticket found and renewed"
            set my isIdle to true
            retrieveDefaults_(me)
            doProcess_(me)
        on error theError
            set my theMessage to "Kerberos ticket expired or not found"
            log "  No ticket found"
            activate
            set response to (display dialog "No Kerberos ticket for Active Directory was found. Do you want to renew it?" with icon 2 buttons {"No","Yes"} default button 2)
            if button returned of response is "Yes"
                renewLionKerb_(me)
            else -- if No is clicked
                log "  User chose not to acquire"
                errorOut_(theError, 1)
            end if
        end try
    end doLionKerb_

    -- Runs when Yes of Lion kerberos renewal dialog (from above) is clicked.
    on renewLionKerb_(sender)
        try
            set thePassword to text returned of (display dialog "Enter your Active Directory password:" default answer "" with hidden answer)
            do shell script "/bin/echo '" & thePassword & "' | /usr/bin/kinit -l 10h -r 10h --password-file=STDIN"
            log "  Ticket acquired"
            display dialog "Kerberos ticket acquired." with icon 1 buttons {"OK"} default button 1
            doLionKerb_(me)
        on error
            try
                set thePassword to text returned of (display dialog "Password incorrect. Please try again:" default answer "" with icon 2 with hidden answer)
                do shell script "/bin/echo '" & thePassword & "' | /usr/bin/kinit -l 24h -r 24h --password-file=STDIN"
                display dialog "Kerboros ticket acquired." with icon 1 buttons {"OK"} default button 1
                doLionKerb_(me)
            on error
                log "  Incorrect password. Skipping."
                display dialog "Too many incorrect attempts. Stopping to avoid account lockout." with icon 2 buttons {"OK"} default button 1
            end try
        end try
    end renewLionKerb_

    -- ad node with scutil fallback to get AD DNS info
    on getDNS_(sender)
        try
            -- find source of user node
            set originalNodeName to (do shell script "/usr/bin/dscl localhost read /Search/Users/$USER OriginalNodeName | grep -o -e '/.*'") as text
            if (count words of originalNodeName) > 0
                set my myLDAP to (do shell script "/usr/bin/dscl localhost read '" & originalNodeName & "' ServerConnection | /usr/bin/awk '/ServerConnection/{print $2}'") as text
                set my mySearchBase to (do shell script "/usr/bin/dscl localhost read '" & originalNodeName & "' LDAPSearchBaseSuffix | /usr/bin/awk '/LDAPSearchBaseSuffix/{print $2}'") as text
            end if
            if (count words of myLDAP) = 0
                -- "first word of" added for 10.7 compatibility, which may return more than one item
                set my myLDAP to first word of (do shell script "/usr/sbin/scutil --dns | /usr/bin/awk '/nameserver\\[0\\]/{print $3}'") as text
            end if
        on error theError
            errorOut_(theError)
        end try
        log "  myLDAP: " & myLDAP
    end getDNS_

    -- Use dsconfigad to get domain name
    -- Use dig to get AD LDAP server from domain name
    on getADLDAP_(sender)
        try
            set myDomain to (do shell script "/usr/sbin/dsconfigad -show | /usr/bin/awk '/Active Directory Domain/{print $NF}'") as text
            try
                set myLDAPresult to (do shell script "/usr/bin/dig +time=2 +tries=1 -t srv _ldap._tcp." & myDomain) as text
            on error theError
                log "Domain test timed out."
                set my onDomain to false
            end try
            if "ANSWER SECTION" is in myLDAPresult
                set my onDomain to true
                -- using "first paragraph" to return only the first ldap server returned by the query
                set myLDAP to last paragraph of (do shell script "/usr/bin/dig -t srv _ldap._tcp." & myDomain & "| /usr/bin/awk '/^_ldap/{print $NF}'") as text
                log "  myDomain: " & myDomain
                log "  myADLDAP: " & myLDAP
            else
                set my onDomain to false
                log "  Can't reach " & myDomain & " domain"
            end if
        on error theError
            errorOut_(theError)
        end try
    end getADLDAP_

    -- Use ldapsearch to get search base if OriginalNodeName method didn't work
    on getSearchBase_(sender)
        if (count of words of my mySearchBase) > 0
            return
        end if
        try
            set my mySearchBase to (do shell script "/usr/bin/ldapsearch -LLL -Q -s base -H ldap://" & myLDAP & " defaultNamingContext | /usr/bin/awk '/defaultNamingContext/{print $2}'") as text
                -- awk -F, '/rootDomainNamingContext/{print $(NF-1)","$NF}' to take only last two search base fields
                log "  mySearchBase: " & mySearchBase
        on error theError
            errorOut_(theError, 1)
        end try
    end getSearchBase_

    -- Use ldapsearch to get password expiration age
    on getExpireAge_(sender)
        try
            set my expireAgeUnix to (do shell script "/usr/bin/ldapsearch -LLL -Q -s base -H ldap://" & myLDAP & " -b " & mySearchBase & " maxPwdAge | /usr/bin/awk -F- '/maxPwdAge/{print $NF/10000000}'") as integer
            if expireAgeUnix is equal to 0
                log "  Couldn't get expireAge. Trying using Manual method."
            else
                set my expireAge to expireAgeUnix / 86400 as integer
                log "  Got expireAge: " & expireAge
                tell defaults to setObject_forKey_(expireAge, "expireAge")
            end if
        on error theError
            errorOut_(theError, 1)
        end try
    end getExpireAge_

    -- Determine when the password was last changed
    on getPwdSetDate_(sender)
        -- number formatter for truncated decimal places
        set fmt to current application's NSNumberFormatter's alloc()'s init()
        fmt's setUsesSignificantDigits_(true)
        fmt's setMaximumSignificantDigits_(7)
        fmt's setMinimumSignificantDigits_(1)
        fmt's setDecimalSeparator_(".")
        
        -- Try & get last set date via dscl, if nothing returned, try via ldap
        set my pwdSetDateUnix to (do shell script "/usr/bin/dscl localhost read /Search/Users/\"$USER\" SMBPasswordLastSet | /usr/bin/awk '/LastSet:/{print $2}'")
        if (count words of pwdSetDateUnix) is equal to 0
            set my pwdSetDateUnix to (do shell script "/usr/bin/ldapsearch -LLLL -Q -H ldap://" & myLDAP & " -b " & mySearchBase & " -s sub \"sAMAccountName=$USER\" pwdLastSet | /usr/bin/awk '/pwdLastSet:/{print $2}'")
            log "psychodata91 pwdSetDateUnix via LDAP: " & pwdSetDateUnix
        end if

        if (count words of pwdSetDateUnix) is greater than 0
            set my pwdSetDateUnix to last word of pwdSetDateUnix
            set my pwdSetDateUnix to ((pwdSetDateUnix as integer) / 10000000 - 11644473600)
            set my pwdSetDate to fmt's stringFromNumber_(pwdSetDateUnix / 86400)
        else if (count words of pwdSetDateUnix) is equal to 0
            set my pwdSetDate to -1
        end if
        log "  New pwdSetDate (" & pwdSetDate & ")"
        -- Now we compare the plist's value for pwdSetDate to the one we just calculated so
        -- we avoid using an old or bad value (i.e. when SMBPasswordLastSet can't be found by dscl)
        tell defaults to set plistPwdSetDate to objectForKey_("pwdSetDate") as real
        statusMenu's setAutoenablesItems_(false)
        if plistPwdSetDate is equal to 0
            set my skipKerb to true
            log "  will be saved to plist."
            tell defaults to setObject_forKey_(pwdSetDate, "pwdSetDate")
            statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(not skipKerb)
            statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(not skipKerb)
        else if plistPwdSetDate is less than or equal to pwdSetDate
            log "  ≥ plist value (" & plistPwdSetDate & ") so we use it"
            tell defaults to setObject_forKey_(pwdSetDate, "pwdSetDate")
            -- If we can get a valid pwdSetDate, then we're on the network, so enable kerb features
            set my skipKerb to false
            statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(not skipKerb)
            statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(not skipKerb)
        else if plistPwdSetDate is greater than pwdSetDate
            log "  < plist value (" & plistPwdSetDate & ") so we ignore it"
            set my pwdSetDate to plistPwdSetDate
             -- If we can't get a valid pwdSetDate, then we're off the network, so disable kerb features
            set my skipKerb to true
            statusMenu's itemWithTitle_("Refresh Kerberos Ticket")'s setEnabled_(not skipKerb)
            statusMenu's itemWithTitle_("Change Password…")'s setEnabled_(not skipKerb)
        end if
    end getPwdSetDate_

    -- Uses 'msDS-UserPasswordExpiryTimeComputed' value from AD to get expiration date.
    on easyMethod_(sender)
        try
            set userName to short user name of (system info)
            set expireDateResult to  (do shell script "/usr/bin/dscl localhost read /Search/Users/" & userName & " msDS-UserPasswordExpiryTimeComputed")
            if "msDS-UserPasswordExpiryTimeComputed" is in expireDateResult
                set my goEasy to true
                set my expireDate to last word of expireDateResult
            else
                set my goEasy to false
                return
            end if
            set my expireDateUnix to do shell script "echo '(" & expireDate & "/10000000)-11644473600' | /usr/bin/bc"
            log "  Got expireDateUnix: " & expireDateUnix
            tell defaults to setObject_forKey_(expireDateUnix, "expireDateUnix")
        on error theError
            errorOut_(theError, 1)
        end try
    end easyMethod_
    
    on easyDate_(timestamp)
        set my expirationDate to do shell script "/bin/date -r" & timestamp
        set todayUnix to do shell script "/bin/date +%s"
        set my daysUntilExp to ((timestamp - todayUnix) / 86400)
        log "    daysUntilExp: " & daysUntilExp
        set my daysUntilExpNice to round daysUntilExp rounding toward zero
        --log "    daysUntilExpNice: " & daysUntilExpNice
    end easyDate_

    -- This is called when the domain is not accessible. It updates the menu display using data
    -- from the plist, which we assume was updated the last time the domain was accessible.
    on offlineUpdate_(sender)
        try
            tell defaults to set unixDate to objectForKey_("expireDateUnix") as integer
            tell defaults to set tooltip to objectForKey_("tooltip") as string
            set todayUnix to do shell script "/bin/date +%s"
            set my daysUntilExp to ((unixDate - todayUnix) / 86400)
            set my daysUntilExpNice to round daysUntilExp rounding toward zero
            updateMenuTitle_((daysUntilExpNice as string) & "d", tooltip)
        on error theError
            errorOut_(theError, 1)
        end try
    end offlineUpdate_

    -- Calculate the number of days until password expiration
    on compareDates_(sender)
        -- number formatter for truncated decimal places
        set fmt to current application's NSNumberFormatter's alloc()'s init()
        fmt's setUsesSignificantDigits_(true)
        fmt's setMaximumSignificantDigits_(7)
        fmt's setMinimumSignificantDigits_(1)
        fmt's setDecimalSeparator_(".")
        try
            set todayUnix to (do shell script "/bin/date +%s")
            set today to (todayUnix / 86400)
            set my daysUntilExp to fmt's stringFromNumber_(expireAge - (today - pwdSetDate)) as real -- removed 'as integer' to avoid rounding issue
            log "  daysUntilExp: " & daysUntilExp
            set my daysUntilExpNice to round daysUntilExp rounding toward zero
            log "  daysUntilExpNice: " & daysUntilExpNice
            log "  macmule test^^"
        on error theError
            errorOut_(theError, 1)
        end try
    end compareDates_

    -- Get the full date of password expiration. daysUntilExp is input. Used by alt method, updates plist.
    on getExpirationDate_(remaining)
        set todayUnix to do shell script "/bin/date +%s"
        set fullDate to (todayUnix) + (remaining * 86400) as string
        -- From http://www.macosxautomation.com/applescript/sbrt/sbrt-02.html
        if fullDate contains "E+" then
            set x to the offset of "." in fullDate
            set y to the offset of "+" in fullDate
            set z to the offset of "E" in fullDate
            set the decimal_adjust to characters (y - (length of fullDate)) thru -1 of fullDate as string as number
            if x is not 0 then
                set the first_part to characters 1 thru (x - 1) of fullDate as string
            else
                set the first_part to ""
            end if
            set the second_part to characters (x + 1) thru (z - 1) of fullDate as string
            set the converted_number to the first_part
            repeat with i from 1 to the decimal_adjust
                try
                    set the converted_number to ¬
                    the converted_number & character i of the second_part
                on error
                    set the converted_number to the converted_number & "0"
                end try
            end repeat
            set my expireDateUnix to converted_number
        else
            set my expireDateUnix to fullDate
        end if
        log "  expireDateUnix: " & expireDateUnix
        tell defaults to setObject_forKey_(expireDateUnix, "expireDateUnix")
        set my expirationDate to (current date) + (remaining * days) as text
        log "  expirationDate: " & expirationDate
    end getExpirationDate_

    -- Updates the menu's title and tooltip
    on updateMenuTitle_(menu_title, tooltip)
        tell defaults to setObject_forKey_(menu_title, "menu_title")
        tell defaults to setObject_forKey_(tooltip, "tooltip")
        statusMenuController's updateDisplay()
    end updateMenuTitle_

    -- The meat of the app; gets the data and does the calculations 
    on doProcess_(sender)
        domainTest_(me)
        if selectedMethod = 0
            log "Starting auto process…"
        else
            log "Starting manual process…"
        end if
        
        try
            if my onDomain is true
                theWindow's displayIfNeeded()
                set my isIdle to false
                set my theMessage to "Working…"
            
                -- Do this if we haven't run before, or the defaults have been reset.
                if my expireDateUnix = 0 and my selectedMethod = 0
                    getADLDAP_(me)
                    easyMethod_(me)
                    if my goEasy is false
                        getSearchBase_(me)
                        getExpireAge_(me)
                    end if
                else
                    log "  Found expireDateUnix in plist: " & expireDateUnix
                    easyMethod_(me)
                end if

                if my goEasy is true and my selectedMethod = 0
                    log "  Using msDS method"
                    easyDate_(expireDateUnix)
                else
                    log "  Using alt method"
                    getPwdSetDate_(me)
                    --compareDates_(me)
                    --getExpirationDate_(daysUntilExp)
                    offlineUpdate_(me)
                end if
                
                updateMenuTitle_((daysUntilExpNice as string) & "d", "Your password expires\n" & expirationDate)
                set my theMessage to "Your password expires in " & daysUntilExpNice & " days\non " & expirationDate
                set my isIdle to true
                doNotify_(daysUntilExpNice)
            else
                log "  Offline. Updating menu…"
                offlineUpdate_(me)
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
                    log "All password fields populated & new & verify match, proceeding with new keychain creation..."
                    createNewKeychain_(me)
                else
                    log "All password fields populated & new & verify match..."
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
            log "Attempting user password change.."
            do shell script "dscl . -passwd /Users/$USER " & quoted form of enteredOldPassword & " " & quoted form of enteredNewPassword
            log "Password changed!"
            set userPasswordChanged to true
            -- Set Keychain settings to make sure they are unlocked
            setKeychainSettings_(me)
            updateKeychainPassword_(me)
        on error errStr
            -- Errors if not connected to org's network
            if errStr contains "eDSServiceUnavailable"
                log "Password change failed. Not connected?"
                display dialog "Password change failed. Please verify that you are connected to your organization's network and try again." with icon 2 buttons {"OK"} default button 1
                if button returned of the result is "OK"
                    changePassword_(me)
                end if
            -- Errors if password change fails due to old pass being wrong or new pass not meeting password policy requirements
            else if errStr contains "eDSAuthMethodNotSupported"
                log "Password change failed. Incorrect or doesn't meet policy."
                display dialog "Password change failed. Please verify that you have entered the correct password in the Old Password field and that your New Password meets your organization's password policy." with icon 2 buttons {"OK"} default button 1
                if button returned of the result is "OK"
                    changePassword_(me)
                end if
            -- Oops, not sure what happened.. :(
            else
                log "Password change failed."
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
                log "Attempting Keychain unlock…"
                -- Unlock the keychain
                do shell script "security unlock-keychain -p " & quoted form of enteredOldPassword & " ~/Library/Keychains/login.keychain"
                -- Make sure that the Keychains password is set to what the new password
                log "Attempting keychain password update…"
                -- Set keychain password
                do shell script "security set-keychain-password -o " & quoted form of enteredOldPassword & " -p " & quoted form of enteredNewPassword & " ~/Library/Keychains/login.keychain"
                -- Log Action
                log "Keychain updated."
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
                -- Advise the user that it's worked
                display dialog "Update successful!" with icon 1 buttons {"OK"} default button 1
                -- Set to front window
                tell application "System Events" to set frontmost of process "ADPassMon" to true
                on error
                -- Log Action
                log "Keychain update failed."
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
            log "User selected create new keychain."
            -- If running 10.9.+, then delete the local items keychain too
            if osVersion is greater than 8
                -- Get the Macs UUID
                set macUUID to do shell script "system_profiler SPHardwareDataType | awk '/Hardware UUID:/{ print $NF}'"
                try -- to delete the local items Keychain dbs
                    do shell script "rm -rf ~/Library/Keychains/" & macUUID & "/*"
                    log "Deleted local items keychain."
                end try
                -- Delete the login Keychain
                deleteLoginKeychain_(me)
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
                -- 10.9.x needs the mac client to restart as securityd or another daemon process owned by the system is used to update the local items keychain
                log "Prompting to restart"
                display dialog "Your Mac needs to restart to finish updating your Keychain. Please dismiss any Local Items keychain prompts, close any open Applications and click Restart Now." with icon 0 buttons {"Later","Restart Now"} default button 2
                -- set to false
                set my keychainCreateNew to false
                -- Restart the Mac
                log "Restarting…"
                tell application "System Events" to restart
            else
                -- Delete the login Keychain
                deleteLoginKeychain_(me)
                -- Create a new login Keychain with the new password entered
                do shell script "security create-keychain -p " & quoted form of enteredNewPassword & " ~/Library/Keychains/login.keychain"
                log "New keychain created."
                -- set to false
                set my keychainCreateNew to false
                -- Set Keychain settings to make sure they are unlocked
                setKeychainSettings_(me)
                -- Close the password prompt window
                closePasswordPromptWindow_(me)
            end if
        on error
            log "Creating a new keychain failed..."
            display dialog "New Keychain creation failed. Please try again" with icon 2 buttons {"OK"} default button 1
            if button returned of the result is "OK" then keychainPasswordPrompt_(me)
        end try
    end createNewKeychain_

    -- Deletes the login keychain using the security command
    on deleteLoginKeychain_(sender)
        try
            do shell script "security delete-keychain ~/Library/Keychains/login.keychain"
            log "Deleted old login keychain."
        on error -- If cannot find the login keychain, then prompt to create a new one.
            log "Couldn't find old Login Keychain."
            cannotFindKeychain_(me)
        end try
    end deleteLoginKeychain_

    -- Set Keychain settings to make sure they are unlocked
    on setKeychainSettings_(sender)
        -- Log Action
        log "Setting keychain settings"
        try
            -- Make sure keychain is not set to lock on sleep
            do shell script "security set-keychain-settings -l ~/Library/Keychains/login.keychain"
            -- Log Action
            log "Set to not lock at sleep"
            -- Make sure keychain is not set to lock after x minutes
            do shell script "security set-keychain-settings -u ~/Library/Keychains/login.keychain"
            -- Log Action
            log "Set to not lock at after time"
            --recheck expiration
            doProcess_(me)
        on error
            -- Log Action
            log "Error setting login.keychain settings..."
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
                log "Retrieved this Macs UUID..."
                try
                    -- Delete the local items Keychain db's if exists
                    do shell script "rm -rf ~/Library/Keychains/" & macUUID & "/*"
                    -- Log Action
                    log "Deleted local items keychain..."
                end try
            end if
        end try
        -- Log Action
        log "Restarting..."
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
    on useManualMethod_(sender)
        log "selectedMethod: " & sender's intValue()
        if sender's intValue() is not 1 -- Auto sends value 1 (on), so Manual is selected
            set my isHidden to true
            set my isManualEnabled to true
            set my selectedMethod to 1
            set my expireAge to manualExpireDays as integer
            tell defaults to setObject_forKey_(1, "selectedMethod")
            tell defaults to setObject_forKey_(manualExpireDays, "expireAge")
            doProcess_(me)
        else -- Auto is selected
            set my isHidden to false
            set my isManualEnabled to false
            set my selectedMethod to 0
            set my expireAge to ""
            set my expireDateUnix to 0
            set my manualExpireDays to ""
            tell defaults to removeObjectForKey_("expireAge")
            tell defaults to removeObjectForKey_("expireDateUnix")
            tell defaults to setObject_forKey_(0, "selectedMethod")
            tell defaults to setObject_forKey_("", "expireAge")
            tell defaults to setObject_forKey_(0, "expireDateUnix")
            doKerbCheck_(me)
        end if
    end useManualMethod_

    -- Bound to Version 1 radio button on the Prefs window
    on useBehaviour1_(sender)
        set selectedBehaviour to 1
        set my isBehaviour2Enabled to 0
        tell defaults to setObject:1 forKey:"selectedBehaviour"
        tell defaults to setObject:0 forKey:"isBehaviour2Enabled"
        -- Disable Keychain Policy options
        set my keychainPolicyEnabled to false
        log "Native password method selected"
    end useBehaviour1_

    -- Bound to Version 2 radio button on the Prefs window
    on useBehaviour2_(sender)
        set selectedBehaviour to 2
        set my isBehaviour2Enabled to 1
        tell defaults to setObject:2 forKey:"selectedBehaviour"
        tell defaults to setObject:1 forKey:"isBehaviour2Enabled"
        -- Enable Keychain Policy options
        set my keychainPolicyEnabled to true
        log "ADPassMon password method selected"
    end useBehaviour2_

    -- Bound to warningDays box in Prefs window
    on setWarningDays_(sender)
        set my warningDays to sender's intValue() as integer
        tell defaults to setObject_forKey_(warningDays, "warningDays")
        log "Set warning days to " & warningDays
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
            log "Set check interval to " & passwordCheckInterval & unit
        on error theError
            log "Could not reset check interval. Error: " & theError
        end try
    end resetIntervalTimer_

    -- Bound to Notify items in menu and Prefs window
    on toggleNotify_(sender)
        if my enableNotifications as boolean is true
            set my enableNotifications to false
            my statusMenu's itemWithTitle_("Use Notifications")'s setState_(0)
            tell defaults to setObject_forKey_(enableNotifications, "enableNotifications")
            log "Disabled notifications."
        else
            set my enableNotifications to true
            my statusMenu's itemWithTitle_("Use Notifications")'s setState_(1)
            tell defaults to setObject_forKey_(enableNotifications, "enableNotifications")
            log "Enabled notifications."
        end if
    end toggleNotify_
    
    on toggleKerbMinder_(sender)
        if my enableKerbMinder as boolean is true
            set my enableKerbMinder to false
            my statusMenu's itemWithTitle_("Use KerbMinder")'s setState_(0)
            tell defaults to setObject_forKey_(enableKerbMinder, "enableKerbMinder")
            log "Disabled KerbMinder."
        else
            set my enableKerbMinder to true
            my statusMenu's itemWithTitle_("Use KerbMinder")'s setState_(1)
            tell defaults to setObject_forKey_(enableKerbMinder, "enableKerbMinder")
            log "Enabled KerbMinder."
        end if
    end toggleKerbMinder_

    -- Bound to Check Keychain items in menu and Prefs window
    on toggleKeychainLockCheck_(sender)
        if my enableKeychainLockCheck is 1
            set my enableKeychainLockCheck to 0
            tell defaults to setObject_forKey_(0, "enableKeychainLockCheck")
            log "Keychain Lock Check disabled"
        else
            set my enableKeychainLockCheck to 1
            tell defaults to setObject_forKey_(1, "enableKeychainLockCheck")
            log " Keychain Lock Check enabled"
        end if
    end toggleKeychainLockCheck_

    -- Bound to Allow Password Change item in Prefs window
    on toggleAllowPasswordChange_(sender)
        -- set to boolean of value
        set allowPasswordChange to allowPasswordChange as boolean
        if allowPasswordChange is true
            set allowPasswordChange to false
            tell defaults to setObject_forKey_(allowPasswordChange, "allowPasswordChange")
            log "Password change disabled"
        else
            set allowPasswordChange to true
            tell defaults to setObject_forKey_(allowPasswordChange, "allowPasswordChange")
            log "Password change enabled"
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
        intervaldomainTest_(me)  -- test domain connectivity

        -- Set a timer to check for domain connectivity every five minutes. (300)
        set my domainTimer to NSTimer's scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(300, me, "intervalDomainTest:", missing value, true)

        -- Set a timer to trigger doProcess handler on an interval and spawn notifications (if enabled).
        set my processTimer to NSTimer's scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_((my passwordCheckInterval * 3600), me, "intervalDoProcess:", missing value, true)

    end startMeUp_

    -- Do processes necessary for app initiation, but check if account is local first
    -- so we can break out if necessary
    on applicationWillFinishLaunching_(sender)
        getOS_(me)
        regDefaults_(me) -- populate plist file with defaults (will not overwrite non-default settings))
        retrieveDefaults_(me) -- load defaults (from plist)
        localAccountStatus_(me)
        if my accountStatus is "Network" or accountStatus is "Cached" then
            startMeUp_(me)
        else if my accountStatus is "Matched" and my runIfLocal is true then
            log "  Proceeding due to manual override."
            startMeUp_(me)
        else if my accountStatus is "Matched" and my runIfLocal is false then
            log "  Manual override not enabled."
            log "  Stopping."
        else
            log "  Stopping."
        end if
    end applicationWillFinishLaunching_

    on applicationShouldTerminate_(sender)
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