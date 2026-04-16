import Toybox.System;
import Toybox.Lang;

class AG2DeviceProfile {
    const X30_PARTNUMS = ["006-B3121-00", "006-B3122-00", "006-B2713-00", "006-B3570-00", "006-B3095-00", "006-B4169-00"];
    const X50_PARTNUMS = ["006-B4634-00", "006-B4440-00", "006-B4633-00"];

    function initialize() {
    }

    function isX30() as Boolean {
        return X30_PARTNUMS.indexOf(System.getDeviceSettings().partNumber) > -1;
    }

    function isX50() as Boolean {
        return X50_PARTNUMS.indexOf(System.getDeviceSettings().partNumber) > -1;
    }
}
