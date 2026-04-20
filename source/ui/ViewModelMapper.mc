import Toybox.System;
import Toybox.WatchUi;
import Toybox.Lang;

class AG2ViewModelMapper {
    hidden var mIsMetric as Boolean;

    function initialize() {
        mIsMetric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
    }

    function map(result as AG2ComputeResult, metrics as AG2MetricsAggregator, histogram as AG2HistogramEngine, bufferSnapshot as AG2BufferSnapshot, histogramSnapshot as AG2HistogramSnapshot or Null, config as AG2Config, layout as Number, graphMode as Number, fitWriter as AG2FitFieldWriter) as AG2ViewModel {
        var model = new AG2ViewModel();
        model.layout = layout;
        model.title = getTitleString(layout, result, config, fitWriter);
        model.value = formatGrade(result.gradeFraction);
        model.status = getStatusLine(layout, result, config, fitWriter);
        model.qualityState = getQualityState(result, config);

        model.meta = getMetaString(metrics, config, layout);
        model.showMeta = layout != AG2LayoutClassifier.LAYOUT_SMALL_NARROW && model.meta.length() > 0;

        if (layout == AG2LayoutClassifier.LAYOUT_WIDE || layout == AG2LayoutClassifier.LAYOUT_LARGE) {
            model.detail = "10s " + histogram.getHighGradeForTime(10.0).format("%.1f") + "% | 1m " + histogram.getHighGradeForTime(60.0).format("%.1f") + "% | 30m " + histogram.getHighGradeForTime(1800.0).format("%.1f") + "%";
            model.showDetail = true;
        }

        model.bufferSnapshot = bufferSnapshot;
        model.histogramSnapshot = histogramSnapshot;

        if (layout == AG2LayoutClassifier.LAYOUT_LARGE) {
            if (graphMode == AG2_GRAPHMODE_BOTH) {
                model.showBufferGraph = true;
                model.showHistogramGraph = histogramSnapshot != null;
            } else if (graphMode == AG2_GRAPHMODE_BUFFER) {
                model.showBufferGraph = true;
            } else if (graphMode == AG2_GRAPHMODE_HISTOGRAM) {
                model.showHistogramGraph = histogramSnapshot != null;
            }
        } else if (layout == AG2LayoutClassifier.LAYOUT_SMALL_NARROW) {
            model.showBufferGraph = graphMode != AG2_GRAPHMODE_HISTOGRAM;
            model.showHistogramGraph = graphMode != AG2_GRAPHMODE_BUFFER && histogramSnapshot != null;
        }

        return model;
    }

    hidden function getTitleString(layout as Number, result as AG2ComputeResult, config as AG2Config, fitWriter as AG2FitFieldWriter) as String {
        var version = WatchUi.loadResource(Rez.Strings.Version);

        if (layout == AG2LayoutClassifier.LAYOUT_WIDE || layout == AG2LayoutClassifier.LAYOUT_LARGE) {
            var title = WatchUi.loadResource(Rez.Strings.UI_Title_Grade) + " " + version;
            var statusSummary = getHeaderStatusSummary(result, config, fitWriter);

            if (statusSummary.length() > 0) {
                title += " | " + statusSummary;
            }

            if (result.isActive) {
                title += " | Q " + result.quality.format("%.2f");
            }

            return title;
        }

        return WatchUi.loadResource(Rez.Strings.UI_Title_Grade_Short) + " " + version;
    }

    hidden function getStatusLine(layout as Number, result as AG2ComputeResult, config as AG2Config, fitWriter as AG2FitFieldWriter) as String {
        if (layout == AG2LayoutClassifier.LAYOUT_WIDE || layout == AG2LayoutClassifier.LAYOUT_LARGE) {
            return "";
        }

        return getStatusString(result, config, fitWriter);
    }

    hidden function formatGrade(gradeFraction as Float) as String {
        var gradePercent = gradeFraction * 100.0;
        if (gradePercent.abs() < 0.05) {
            return "0.0%";
        }
        return gradePercent.format("%+.1f") + "%";
    }

    hidden function getStatusString(result as AG2ComputeResult, config as AG2Config, fitWriter as AG2FitFieldWriter) as String {
        if (!fitWriter.isLoggingEnabled()) {
            return WatchUi.loadResource(Rez.Strings.UI_Status_LoggingDisabled);
        }

        if (fitWriter.hasFieldSetupError()) {
            return WatchUi.loadResource(Rez.Strings.UI_Status_FieldError);
        }

        switch (result.status) {
            case "BUFFERING":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Buffering) + " " + result.sampleCount.format("%d") + "/" + config.minGradeWindow.format("%d");
            case "ACTIVE":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Active) + " " + result.windowSize.format("%d") + "s | Q " + result.quality.format("%.2f");
            case "RESET":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Reset) + " " + getResetLabel(result.resetReason);
            default:
                return WatchUi.loadResource(Rez.Strings.UI_Status_NoData) + " " + config.minGradeWindow.format("%d") + "/" + config.maxGradeWindow.format("%d") + "/" + config.sampleWindow.format("%d") + "s";
        }
    }

    hidden function getHeaderStatusSummary(result as AG2ComputeResult, config as AG2Config, fitWriter as AG2FitFieldWriter) as String {
        if (!fitWriter.isLoggingEnabled()) {
            return "LOG OFF";
        }

        if (fitWriter.hasFieldSetupError()) {
            return "FIT ERR";
        }

        switch (result.status) {
            case "BUFFERING":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Buffering) + " " + result.sampleCount.format("%d") + "/" + config.minGradeWindow.format("%d");
            case "ACTIVE":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Active);
            case "RESET":
                return WatchUi.loadResource(Rez.Strings.UI_Status_Reset) + " " + getResetLabel(result.resetReason);
            default:
                return WatchUi.loadResource(Rez.Strings.UI_Status_NoData);
        }
    }

    hidden function getResetLabel(resetReason as String) as String {
        switch (resetReason) {
            case "LOW_SPEED":
                return "STOP";
            case "TIME_GAP":
                return "GAP";
            case "ALTITUDE_JUMP":
                return "ALT";
            case "TIME_RESET":
                return "RESET";
            default:
                return "";
        }
    }

    hidden function getQualityState(result as AG2ComputeResult, config as AG2Config) as String {
        if (!result.isActive) { return "IDLE"; }
        if (result.quality >= config.thresholdLogMax) { return "GOOD"; }
        if (result.quality >= config.thresholdLogDist) { return "WARN"; }
        return "BAD";
    }

    hidden function getMetaString(metrics as AG2MetricsAggregator, config as AG2Config, layout as Number) as String {
        if (layout == AG2LayoutClassifier.LAYOUT_SMALL) {
            switch (config.smallFieldData) {
                case AG2_SMALL_FIELD_DIST:
                    return "L " + formatDistance(metrics.distLightMeters) + " | H " + formatDistance(metrics.distSteepMeters);
                case AG2_SMALL_FIELD_CLIMBMAX:
                    return "CL " + formatDistance(metrics.distLightMeters) + " | MAX " + (metrics.maxGradeFraction * 100.0).format("%.1f") + "%";
                case AG2_SMALL_FIELD_CLIMBVAM:
                    return "CL " + formatDistance(metrics.distLightMeters) + " | VAM " + formatVam(metrics.currentVam);
                case AG2_SMALL_FIELD_VAM:
                default:
                    return "VAM " + formatVam(metrics.currentVam) + " | AVG " + formatVam(metrics.averageVam);
            }
        }

        if (layout == AG2LayoutClassifier.LAYOUT_WIDE || layout == AG2LayoutClassifier.LAYOUT_LARGE) {
            return "L " + formatDistance(metrics.distLightMeters) + " | H " + formatDistance(metrics.distSteepMeters) + " | MAX " + (metrics.maxGradeFraction * 100.0).format("%.1f") + "%";
        }

        return "MAX " + (metrics.maxGradeFraction * 100.0).format("%.1f") + "% | VAM " + formatVam(metrics.currentVam);
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

    hidden function formatVam(vam as Float) as String {
        if (mIsMetric) {
            return vam.format("%.0f") + "m/h";
        }
        return (vam * 3.28).format("%.0f") + "ft/h";
    }
}
