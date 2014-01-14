Mac-Linux-USB-Loader
====================

Tool allowing you to put a Linux distro on a USB drive and make it bootable on Intel Macs using EFI.

![Mac Linux USB Loader logo](Mac-Linux-USB-Loader/Images.xcassets/AppIcon.appiconset/Icon.png)

General Information
-------------------

This is the Mac Linux USB Loader, a tool allowing you to take an ISO of a Linux distribution and make it boot using EFI. It requires a single USB drive formatted as FAT with at least 2 GB free recommended. The application is available in English and a number of other languages. For all supported languages, see the TRANSLATIONS file. This project also contains the Compatibility Tester, a related but separate tool to test your Mac's Linux compatibility.

The tool is necessary to make certain Linux distributions boot that do not have EFI booting support. Many distributions are adding this with the release of Windows 8, but it has not been finalized and is still nonstandard by most distros. Many common distributions are supported, like Ubuntu and Linux Mint.

If you wish to contribute to the code or fork the repository, please do so. Please note that all of the code in the _working_ branch is unstable, and should not be used on production machines. The _stable_ branch contains stable, tested code. The current version of Mac Linux USB Loader is 2.0. Version numbers will likely be higher in development branches.

I created this tool, if you care, for several reasons:

- None of the other tools available (esp. unetbootin) feel native and operate as you would expect on the Mac platform.
- None of the other methods of which I am aware have the ability to make the archives boot on Intel Macs.
- It was personally a pain in the neck getting Linux distros to boot via USB on Macs.

That being said, it does have a few shortcomings:

- Linux fails to have graphics on some Macs (i.e Macbook Pros with nVidia graphics), which in some cases prevents boot, but this is not necessarily an issue with Mac Linux USB Loader as much as it is an issue with the video drivers that ship with most distros. Luckily, with Enterprise, which has been included with Mac Linux USB Loader since 2.0, you can use persistence to install the necessary video drivers on distributions like Ubuntu, helping to alleviate the issue.
- It only detects up to 10 USB ports. I chose 10 because it is unlikely someone will have more ports than that. If they do, then maybe I'll do something about it, but the only computer I've even seen that had more than a few ports was a desktop PC with six, but given that PCs do not run OS X that would not really limit us anyway.

Building from Source
--------------------

1. Clone from git:
    `git clone https://github.com/SevenBits/Mac-Linux-USB-Loader.git`
    `git checkout -b rewrite`
1. Run `pod install` (requires [Cocoapods](http://cocoapods.org)).
1. Either open `Mac Linux USB Loader.xcworkspace` and do an archive build or run `xcodebuild` from the command line.

Acknowledgements
----------------

- Used the eraser icon by Oliver Scholtz.
    [link](http://www.iconfinder.com/icondetails/24217/128/clean_delete_eraser_icon)
- Used the boot icon from Aha-Soft.
    [link](http://www.iconfinder.com/icondetails/128585/96/boot_icon)