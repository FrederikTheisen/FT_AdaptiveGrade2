import Toybox.Graphics;
import Toybox.System;

class AG2LayoutClassifier {
    enum {
        LAYOUT_SMALL,
        LAYOUT_SMALL_NARROW,
        LAYOUT_WIDE,
        LAYOUT_LARGE
    }

    hidden var mDeviceProfile as AG2DeviceProfile;

    function initialize() {
        mDeviceProfile = new AG2DeviceProfile();
    }

    function detect(dc as Dc) as Number {
        var widthView = dc.getWidth();
        var heightView = dc.getHeight();
        var widthDevice = System.getDeviceSettings().screenWidth;

        var unitFactor = 1.0;
        if (mDeviceProfile.isX50()) {
            unitFactor = 1.7;
        }

        if (widthView < widthDevice / 2 + 10) {
            return LAYOUT_SMALL;
        }

        if (heightView < 70 && mDeviceProfile.isX50()) {
            return LAYOUT_SMALL_NARROW;
        }

        if (heightView < 120 * unitFactor) {
            return LAYOUT_WIDE;
        }

        return LAYOUT_LARGE;
    }
}
