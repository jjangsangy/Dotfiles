# How To Harden your Mac
10 Simple Ways To Improve Your Opsec

# 1. [Reset NVRAM](https://support.apple.com/en-us/HT204063)


> Note: If your Mac is using a firmware password, this key combination causes your Mac to start up from macOS Recovery instead.
> Turn off the firmware password before resetting NVRAM.


1. Shut down your Mac, then turn it on and immediately hold down these four keys together: Option, Command, P, and R.
2. Keep holding the keys for about 20 seconds, during which your Mac might appear to restart.
    - If you have a Mac that plays a startup sound when you turn it on, you can release the keys after the second startup sound.
3. When your Mac finishes starting up, you might want to open System Preferences and adjust any settings that were reset, such as sound volume, display resolution, startup disk selection, or time zone.

# 2. [Reset the System Management Controller (SMC)](https://support.apple.com/en-us/HT201295)

First, determine whether the battery is removable.
Mac notebook computers that have a nonremovable battery include MacBook Pro (Early 2009 and later), all models of MacBook Air, MacBook (Late 2009), and MacBook (Retina, 12-inch, Early 2015 and later).

## If the battery is nonremovable:

1. Shut down your Mac.
2. Using the built-in keyboard, press Shift-Control-Option on the left side of the keyboard, then press the power button at the same time. Hold these keys and the power button for 10 seconds.
3. If you have a MacBook Pro with Touch ID, the Touch ID button is also the power button.
4. Release all keys.
5. Press the power button again to turn on your Mac.


## If the battery is removable:

1. Shut down your Mac.600
2. Remove the battery. (Learn about removing the battery in MacBook and MacBook Pro computers.)
3. Press and hold the power button for five seconds.
4. Press the power button to turn on your Mac.

## For Desktops (Super Easy)

1. Unplug your desktop from the power for atleast 15 seconds

# 3. Enable full disk encryption

Next thing is enabling full disk encryption.
This can be done on macOS from the system preferences in the "Security" section on the "FileVault" tab.
Write down your recovery key and keep it far away in a place you know you will have access to.
If possible memorize your recovery key. Memorizing your key is far superior than writing it down as you also gain 5th amendment protection from non-incrimination in the united states.

# 4. Enforce Strict Harware Decryption Practices

When a Mac using FileVault encryption is placed into standby mode, a FileVault key (yes, this key is encrypted) is stored in EFI (firmware) so that it can quickly come out of standby mode when woken from deep sleep.

For 99% of users, that hardly matters and it’s not a security concern, but for those who are concerned about absolute maximum security and protecting a Mac from some unusually aggressive attacks (i.e. espionage level), you can set OS X to automatically destroy that FileVault key when it’s placed in power-saving standby mode, preventing that stored key from being a potential weak point or attack target.

```sh
    $ sudo pmset -a destroyfvkeyonstandby 1
    $ sudo pmset -a hibernatemode 25
    $ sudo pmset -a powernap 0
    $ sudo pmset -a standby 0
    $ sudo pmset -a standbydelay 0
    $ sudo pmset -a autopoweroff 0
```

# 5. Set a firmware password

```sh
    $ sudo firmwarepasswd -setpasswd -setmode command
```

# 6. Ask for password immediately


```sh
    $ defaults write com.apple.screensaver askForPassword -int 1
    $ defaults write com.apple.screensaver askForPasswordDelay -int 0
```

# 7. Fix OpenSSL and curl

macOS comes with an OpenSSL version that is like 100 years old...

Installing the current one and building a new curl that uses that newer OpenSSL might be a little paranoid, but this is what I always do:

```
    $ brew install openssl
    $ brew install curl --with-openssl
    $ brew link --force curl
```

# 8. Mac SSH Config

Create `~/.ssh/config` file

```sh
    $ mkdir -m 700 -p "~/.ssh"
    $ touch "~/.ssh/config" && chmod 600 "~/.ssh/config"
```

In the config file

```conf
Host *
  PasswordAuthentication no
  ChallengeResponseAuthentication no
  HashKnownHosts yes
  UseKeyChain no
```

# 9. Show All Extensions

A common attack vector uses the fact that modern OS's will hide the extensions on known filetypes.

Files like "AnnaKournikova.jpg.exe" would spread worms through email.

```sh
    $ defaults write NSGlobalDomain AppleShowAllExtensions -bool true
```

# 10. Disable Crash Reporter

Because I hate this thing

```sh
    $ defaults write com.apple.CrashReporter DialogType none
```

