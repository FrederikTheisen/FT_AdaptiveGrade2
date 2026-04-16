import Toybox.Lang;

class AG2ComputeResult {
    var gradeFraction as Float = 0.0;
    var quality as Float = 0.0;
    var sampleDistanceMeters as Float = 0.0;
    var currentSpeed as Float = 0.0;
    var vam as Float = 0.0;
    var sampleCount as Number = 0;
    var windowSize as Number = 0;
    var isActive as Boolean = false;
    var status as String = "NO_DATA";

    function initialize() {
    }
}

class AG2ViewModel {
    var title as String = "";
    var value as String = "";
    var status as String = "";
    var meta as String = "";
    var showMeta as Boolean = true;

    function initialize() {
    }
}
