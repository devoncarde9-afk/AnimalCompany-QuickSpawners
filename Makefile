TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = XD_QuickSpawners

XD_QuickSpawners_FILES = XD_QuickSpawners.x
XD_QuickSpawners_CFLAGS = -fobjc-arc
XD_QuickSpawners_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
