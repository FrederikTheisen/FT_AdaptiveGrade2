import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class AG2FitFieldWriter {
    hidden var mHost as WatchUi.DataField or Null;
    hidden var mConfig as AG2Config or Null;
    hidden var mIsMetric as Boolean = true;
    hidden var mLoggingEnabled as Boolean = true;
    hidden var mGradeLoggingEnabled as Boolean = false;
    hidden var mFieldSetupError as Boolean = false;

    hidden var mGradeField;
    hidden var mClimbDistField;
    hidden var mLapAvgGradeField;
    hidden var mMaxGradeForTimeField;

    function initialize(host as WatchUi.DataField, config as AG2Config) {
        mHost = host;
        mIsMetric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
        configure(config);
    }

    function configure(config as AG2Config) as Void {
        mConfig = config;
        mLoggingEnabled = config.enableLogging;
        mGradeLoggingEnabled = config.enableGradeLogging;
        mFieldSetupError = false;

        if (!mLoggingEnabled || mHost == null) { return; }

        mFieldSetupError = true;

        try {
            if (mGradeLoggingEnabled) {
                if (mGradeField == null) {
                    mGradeField = (mHost as WatchUi.DataField).createField(
                        WatchUi.loadResource(Rez.Strings.GC_ChartTitle_Grade), 30,
                        FitContributor.DATA_TYPE_FLOAT,
                        {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>WatchUi.loadResource(Rez.Strings.Unit_Grade)}
                    );
                }
            } else {
                mGradeField = null;
            }

            if (mClimbDistField == null) {
                mClimbDistField = (mHost as WatchUi.DataField).createField(
                    WatchUi.loadResource(Rez.Strings.GC_ClimbDist), 31,
                    FitContributor.DATA_TYPE_STRING,
                    {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"", :count=>16}
                );
            }

            if (mMaxGradeForTimeField == null) {
                mMaxGradeForTimeField = (mHost as WatchUi.DataField).createField(
                    WatchUi.loadResource(Rez.Strings.GC_MaxGrdTime), 37,
                    FitContributor.DATA_TYPE_STRING,
                    {:mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.Unit_Grade), :count=>16}
                );
            }

            if (mLapAvgGradeField == null) {
                mLapAvgGradeField = (mHost as WatchUi.DataField).createField(
                    WatchUi.loadResource(Rez.Strings.GC_Lap_AvgGrade), 36,
                    FitContributor.DATA_TYPE_FLOAT,
                    {:mesgType=>FitContributor.MESG_TYPE_LAP, :units=>WatchUi.loadResource(Rez.Strings.Unit_Grade)}
                );
            }
        } catch (ex) {
        }

        if (mGradeField != null) { mGradeField.setData(0.0); }
        if (mClimbDistField != null) { mClimbDistField.setData(formatDistance(0.0) + " / " + formatDistance(0.0)); }
        if (mLapAvgGradeField != null) { mLapAvgGradeField.setData(0.0); }
        if (mMaxGradeForTimeField != null) { mMaxGradeForTimeField.setData("NA/NA/NA"); }

        mFieldSetupError = false;
    }

    function hasFieldSetupError() as Boolean {
        return mFieldSetupError;
    }

    function isLoggingEnabled() as Boolean {
        return mLoggingEnabled;
    }

    function syncRecord(result as AG2ComputeResult, metrics as AG2MetricsAggregator, histogram as AG2HistogramEngine) as Void {
        if (!mLoggingEnabled) { return; }
        if (mGradeField == null) { return; }

        try {
            mGradeField.setData(result.gradeFraction * 100.0);
        } catch (ex) {
            mFieldSetupError = true;
        }
    }

    function syncLap(metrics as AG2MetricsAggregator) as Void {
        if (!mLoggingEnabled || mLapAvgGradeField == null) { return; }

        try {
            mLapAvgGradeField.setData(metrics.getLapAverageGradePercent());
        } catch (ex) {
            mFieldSetupError = true;
        }
    }

    function syncSession(metrics as AG2MetricsAggregator, histogram as AG2HistogramEngine) as Void {
        if (!mLoggingEnabled) { return; }

        var climbDistString = formatDistance(metrics.distLightMeters) + " / " + formatDistance(metrics.distSteepMeters);
        if (mClimbDistField != null) {
            try {
                mClimbDistField.setData(climbDistString);
            } catch (ex) {
                mFieldSetupError = true;
            }
        }

        var maxGradeForTime = histogram.getHighGradeForTime(10.0).format("%.1f");
        maxGradeForTime += "/" + histogram.getHighGradeForTime(60.0).format("%.1f");
        maxGradeForTime += "/" + histogram.getHighGradeForTime(1800.0).format("%.1f");

        if (mMaxGradeForTimeField != null) {
            try {
                mMaxGradeForTimeField.setData(maxGradeForTime);
            } catch (ex) {
                mFieldSetupError = true;
            }
        }
    }

    hidden function formatDistance(distanceMeters as Float) as String {
        if (mIsMetric) {
            if (distanceMeters < 1000.0) {
                return distanceMeters.format("%.0f") + "m";
            }

            var distanceKm = distanceMeters / 1000.0;
            if (distanceKm >= 100.0) { return distanceKm.format("%.0f") + "km"; }
            return distanceKm.format("%.1f") + "km";
        }

        var distanceFt = distanceMeters * 3.28;
        if (distanceFt < 1000.0) {
            return distanceFt.format("%.0f") + "ft";
        }

        var distanceMi = (distanceMeters / 1000.0) * 0.62;
        if (distanceMi >= 100.0) { return distanceMi.format("%.0f") + "mi"; }
        return distanceMi.format("%.1f") + "mi";
    }
}
