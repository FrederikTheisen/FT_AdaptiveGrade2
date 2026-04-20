import Toybox.Lang;

class AG2Sample {
    var altitudeMeters as Float = 0.0;
    var distanceMeters as Float = 0.0;
    var elapsedSeconds as Float = 0.0;

    function initialize(altitudeMeters as Float, distanceMeters as Float, elapsedSeconds as Float) {
        self.altitudeMeters = altitudeMeters;
        self.distanceMeters = distanceMeters;
        self.elapsedSeconds = elapsedSeconds;
    }
}

class AG2RegressionResult {
    var slopeFraction as Float = 0.0;
    var quality as Float = 0.0;
    var windowDistanceMeters as Float = 0.0;

    function initialize() {
    }
}

class AG2BufferSnapshot {
    var altitudes = [];
    var distances = [];
    var windowStartIndex as Number = 0;
    var windowSize as Number = 0;
    var totalDistanceMeters as Float = 0.0;
    var currentGradeFraction as Float = 0.0;
    var quality as Float = 0.0;

    function initialize() {
    }
}

class AG2HistogramSnapshot {
    var rangeStart as Number = 0;
    var rangeEnd as Number = 0;
    var gradeCenters = [];
    var values = [];
    var currentBinIndex as Number = -1;
    var tickStep as Number = 1;

    function initialize() {
    }
}

class AG2ComputeResult {
    var gradeFraction as Float = 0.0;
    var quality as Float = 0.0;
    var sampleDistanceMeters as Float = 0.0;
    var currentSpeed as Float = 0.0;
    var altitudeMeters as Float = 0.0;
    var elapsedSeconds as Float = 0.0;
    var vam as Float = 0.0;
    var sampleCount as Number = 0;
    var windowSize as Number = 0;
    var windowDistanceMeters as Float = 0.0;
    var totalBufferedDistanceMeters as Float = 0.0;
    var isActive as Boolean = false;
    var status as String = "NO_DATA";
    var resetReason as String = "";

    function initialize() {
    }
}

class AG2ViewModel {
    var layout as Number = 0;
    var title as String = "";
    var value as String = "0.0%";
    var status as String = "";
    var meta as String = "";
    var detail as String = "";
    var showMeta as Boolean = true;
    var showDetail as Boolean = false;
    var qualityState as String = "IDLE";
    var showBufferGraph as Boolean = false;
    var showHistogramGraph as Boolean = false;
    var bufferSnapshot as AG2BufferSnapshot or Null = null;
    var histogramSnapshot as AG2HistogramSnapshot or Null = null;

    function initialize() {
    }
}
