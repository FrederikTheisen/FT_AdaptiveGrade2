import Toybox.Activity;
import Toybox.Lang;

class AG2GradeEngine {
    hidden var mGradeSamples as AG2SampleRing;
    hidden var mLastAltitude as Float or Null;
    hidden var mLastElapsedSeconds as Float or Null;

    function initialize(config as AG2Config) {
        mGradeSamples = new AG2SampleRing(config.sampleWindow);
        clearRuntime();
    }

    function clearRuntime() as Void {
        mGradeSamples.reset();
        mLastAltitude = null;
        mLastElapsedSeconds = null;
    }

    function compute(info as Activity.Info, config as AG2Config) as AG2ComputeResult {
        if (mGradeSamples.count() == 0 && config.sampleWindow != 0) {
            mGradeSamples.resize(config.sampleWindow);
        }

        var result = new AG2ComputeResult();

        var speed = (info has :currentSpeed) ? info.currentSpeed : null;
        var altitude = (info has :altitude) ? info.altitude : null;
        var elapsedMs = (info has :elapsedTime) ? info.elapsedTime : null;
        if (speed == null || altitude == null || elapsedMs == null) {
            return result;
        }

        var speedValue = speed.toFloat();
        var altitudeValue = altitude.toFloat();
        var elapsedSeconds = elapsedMs.toFloat() / 1000.0;

        if (mLastAltitude == null || mLastElapsedSeconds == null) {
            mLastAltitude = altitudeValue;
            mLastElapsedSeconds = elapsedSeconds;
            result.status = "BUFFERING";
            return result;
        }

        var dt = elapsedSeconds - (mLastElapsedSeconds as Float);
        var altitudeDelta = altitudeValue - (mLastAltitude as Float);
        var sampleDistance = speedValue * dt;

        if (dt <= 0.0 || dt > 5.0 || sampleDistance < 0.1 || altitudeDelta.abs() > 10.0) {
            clearRuntime();
            mLastAltitude = altitudeValue;
            mLastElapsedSeconds = elapsedSeconds;
            result.status = "RESET";
            return result;
        }

        var instantGrade = altitudeDelta / sampleDistance;
        if (instantGrade > config.maxAllowedGrade) { instantGrade = config.maxAllowedGrade; }
        if (instantGrade < -config.maxAllowedGrade) { instantGrade = -config.maxAllowedGrade; }

        mGradeSamples.push(instantGrade);

        result.sampleCount = mGradeSamples.count();
        result.windowSize = config.maxGradeWindow;
        if (result.windowSize > result.sampleCount) {
            result.windowSize = result.sampleCount;
        }

        if (result.sampleCount < config.minGradeWindow) {
            result.status = "BUFFERING";
        } else {
            result.gradeFraction = mGradeSamples.averageRecent(result.windowSize);
            result.quality = result.windowSize.toFloat() / config.maxGradeWindow.toFloat();
            result.currentSpeed = speedValue;
            result.sampleDistanceMeters = sampleDistance;
            result.vam = speedValue * result.gradeFraction * 3600.0;
            result.isActive = true;
            result.status = "ACTIVE";
        }

        mLastAltitude = altitudeValue;
        mLastElapsedSeconds = elapsedSeconds;

        return result;
    }
}
