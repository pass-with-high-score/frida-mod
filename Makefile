TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = DebInstallerApp

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = DebInstallerApp

DebInstallerApp_FILES = main.m DebInstallerAppAppDelegate.m RootViewController.m
DebInstallerApp_FRAMEWORKS = UIKit CoreGraphics
DebInstallerApp_CFLAGS = -fobjc-arc
DebInstallerApp_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
