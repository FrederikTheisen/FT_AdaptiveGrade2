import Toybox.Activity;
import Toybox.Lang;
import Toybox.Math;

class AG2GradeEngine {
    hidden var mConfig as AG2Config;
    hidden var mGradeSamples as AG2SampleRing;
    hidden var mLastAltitude as Float or Null;
    hidden var mLastElapsedSeconds as Float or Null;
    hidden var mGradeWindowSize as Number = 0;

    function initialize(config as AG2Config) {
        mConfig = config;
        mGradeSamples = new AG2SampleRing(config.sampleWindow);
        clearRuntime();
    }

    function clearRuntime() as Void {
        mGradeSamples.reset();
        mLastAltitude = null;
        mLastElapsedSeconds = null;
        mGradeWindowSize = mConfig.minGradeWindow;
    }

    function compute(info as Activity.Info) as AG2ComputeResult {
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
        result.currentSpeed = speedValue;
        result.altitudeMeters = altitudeValue;
        result.elapsedSeconds = elapsedSeconds;

        if (mLastAltitude == null || mLastElapsedSeconds == null) {
            mLastAltitude = altitudeValue;
            mLastElapsedSeconds = elapsedSeconds;
            result.status = "BUFFERING";
            return result;
        }

        var dt = elapsedSeconds - (mLastElapsedSeconds as Float);
        var altitudeDelta = altitudeValue - (mLastAltitude as Float);
        var sampleDistance = speedValue * dt;
        result.sampleDistanceMeters = sampleDistance;

        var resetReason = getResetReason(dt, sampleDistance, altitudeDelta);
        if (resetReason.length() > 0) {
            clearRuntime();
            mLastAltitude = altitudeValue;
            mLastElapsedSeconds = elapsedSeconds;
            result.status = "RESET";
            result.resetReason = resetReason;
            return result;
        }

        mGradeSamples.push(altitudeValue, sampleDistance, elapsedSeconds);

        result.sampleCount = mGradeSamples.count();
        result.totalBufferedDistanceMeters = mGradeSamples.getTotalDistanceMeters();

        if (result.sampleCount < mConfig.minGradeWindow) {
            result.status = "BUFFERING";
        } else {
            adaptWindowSize(result.sampleCount);

            var regression = computeRegression(mGradeWindowSize);
            result.windowSize = mGradeWindowSize;
            result.windowDistanceMeters = regression.windowDistanceMeters;
            result.gradeFraction = clampGrade(regression.slopeFraction);
            result.quality = regression.quality;
            result.currentSpeed = speedValue;
            result.vam = speedValue * result.gradeFraction * 3600.0;
            result.isActive = true;
            result.status = "ACTIVE";
        }

        mLastAltitude = altitudeValue;
        mLastElapsedSeconds = elapsedSeconds;

        return result;
    }

    function getBufferSnapshot(result as AG2ComputeResult) as AG2BufferSnapshot {
        var snapshot = mGradeSamples.snapshot(result.windowSize);
        snapshot.currentGradeFraction = result.gradeFraction;
        snapshot.quality = result.quality;
        return snapshot;
    }

    hidden function getResetReason(dt as Float, sampleDistance as Float, altitudeDelta as Float) as String {
        if (dt <= 0.0) { return "TIME_RESET"; }
        if (dt > AG2_RESET_MAX_SAMPLE_GAP_SECONDS) { return "TIME_GAP"; }
        if (sampleDistance < AG2_RESET_MIN_DISTANCE_METERS) { return "LOW_SPEED"; }
        if (altitudeDelta.abs() > AG2_RESET_ALTITUDE_JUMP_METERS) { return "ALTITUDE_JUMP"; }
        return "";
    }

    hidden function clampGrade(gradeFraction as Float) as Float {
        if (gradeFraction > mConfig.maxAllowedGrade) { return mConfig.maxAllowedGrade; }
        if (gradeFraction < -mConfig.maxAllowedGrade) { return -mConfig.maxAllowedGrade; }
        return gradeFraction;
    }

    hidden function adaptWindowSize(sampleCount as Number) as Void {
        var currentWindow = mGradeWindowSize;
        if (currentWindow > sampleCount) { currentWindow = sampleCount; }
        if (currentWindow < mConfig.minGradeWindow) { currentWindow = mConfig.minGradeWindow; }

        var mainSlope = computeRegression(currentWindow).slopeFraction;
        var minSlope = computeRegression(mConfig.minGradeWindow).slopeFraction;
        var gradeDiff = (mainSlope - minSlope).abs();

        if (gradeDiff > 0.02) {
            mGradeWindowSize -= 3;
        } else if (gradeDiff > 0.015) {
            mGradeWindowSize -= 2;
        } else if (gradeDiff > 0.0075) {
            mGradeWindowSize -= 1;
        } else if (gradeDiff < 0.004 && mGradeWindowSize <= mConfig.maxGradeWindow / 2) {
            mGradeWindowSize += 1;
        } else if (gradeDiff < 0.002) {
            mGradeWindowSize += 1;
        }

        if (mGradeWindowSize < mConfig.minGradeWindow) { mGradeWindowSize = mConfig.minGradeWindow; }
        if (mGradeWindowSize > mConfig.maxGradeWindow) { mGradeWindowSize = mConfig.maxGradeWindow; }
        if (mGradeWindowSize > sampleCount) { mGradeWindowSize = sampleCount; }
    }

    hidden function computeRegression(windowSize as Number) as AG2RegressionResult {
        var regression = new AG2RegressionResult();
        var samples = mGradeSamples.getChronological(windowSize);
        var count = samples.size();
        if (count <= 0) { return regression; }

        var xValues = [];
        var distance = 0.0;
        var sumX = 0.0;
        var sumY = 0.0;

        for (var i = 0; i < count; i++) {
            var sample = samples[i] as AG2Sample;
            distance += sample.distanceMeters;
            xValues.add(distance);
            sumX += distance;
            sumY += sample.altitudeMeters;
        }

        regression.windowDistanceMeters = distance;
        if (count < 2) { return regression; }

        var meanX = sumX / count;
        var meanY = sumY / count;
        var covXY = 0.0;
        var varX = 0.0;

        for (var j = 0; j < count; j++) {
            var currentSample = samples[j] as AG2Sample;
            var dx = xValues[j] - meanX;
            var dy = currentSample.altitudeMeters - meanY;
            covXY += dx * dy;
            varX += dx * dx;
        }

        if (varX <= 0.0) { return regression; }

        regression.slopeFraction = covXY / varX;
        if (count <= 2) {
            regression.quality = 0.0;
            return regression;
        }

        var sse = 0.0;
        for (var k = 0; k < count; k++) {
            var sampleForError = samples[k] as AG2Sample;
            var expectedAltitude = meanY + regression.slopeFraction * (xValues[k] - meanX);
            var residual = expectedAltitude - sampleForError.altitudeMeters;
            sse += residual * residual;
        }

        var sem = Math.sqrt((sse / (count - 2).toFloat()) / varX);
        regression.quality = AG2_QUALITY_SCALE / (AG2_QUALITY_SCALE + sem);
        return regression;
    }
}
