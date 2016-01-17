# yourTubeiOS
yourTube for iOS


This is a basic attempt to port over https://github.com/lechium/yourTube to iOS. For the initial basic versions, if you can't build this yourself you will need to have some apt-7 strict and openssh installed on your iOS device to get this installed.


Steps to install from the pre-included deb package.

1. ssh into your iOS device

    ssh root@yourdevice.local

2. install wget and shell-cmds (optional, you may already have them)

    apt-get install wget shell-cmds -y --force-yes

3. download the deb file

    wget --no-check-certificate https://github.com/lechium/yourTubeiOS/raw/master/com.nito.ytbrowser_1.0-1_iphoneos-arm.deb

4. install the deb file

    dpkg -i com.nito.ytbrowser_1.0-1_iphoneos-arm.deb

5. the previous install will likely fail due to missing depenendencies

    apt-get install -f -y --force-yes

6. kill SpringBoard

    killall -9 SpringBoard

7. reload springboard apps
    
    su -c uicache mobile

at this point you should have a red play "yourTube" icon somewhere, you should be good to go!

    