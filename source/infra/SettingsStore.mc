import Toybox.Application;

class AG2SettingsStore {
    function initialize() {
    }

    function load() as AG2Config {
        var config = new AG2Config();

        var sampleWindow = Application.Properties.getValue("buffer_length");
        if (sampleWindow instanceof Number) { config.sampleWindow = sampleWindow; }

        var minGradeWindow = Application.Properties.getValue("buffer_fit_min");
        if (minGradeWindow instanceof Number) { config.minGradeWindow = minGradeWindow; }

        var maxGradeWindow = Application.Properties.getValue("buffer_fit_max");
        if (maxGradeWindow instanceof Number) { config.maxGradeWindow = maxGradeWindow; }

        var thresholdLogDist = Application.Properties.getValue("threshold_log_dist");
        if (thresholdLogDist instanceof Number) { config.thresholdLogDist = thresholdLogDist.toFloat(); }

        var thresholdLogMax = Application.Properties.getValue("threshold_log_max");
        if (thresholdLogMax instanceof Number) { config.thresholdLogMax = thresholdLogMax.toFloat(); }

        var thresholdLight = Application.Properties.getValue("threshold_light");
        if (thresholdLight instanceof Number) { config.thresholdLight = thresholdLight.toFloat() / 100.0; }

        var thresholdSteep = Application.Properties.getValue("threshold_steep");
        if (thresholdSteep instanceof Number) { config.thresholdSteep = thresholdSteep.toFloat() / 100.0; }

        var enableLogging = Application.Properties.getValue("enable_logging");
        if (enableLogging instanceof Boolean) { config.enableLogging = enableLogging; }

        var enableGradeLogging = Application.Properties.getValue("enable_grade_logging");
        if (enableGradeLogging instanceof Boolean) { config.enableGradeLogging = enableGradeLogging; }

        var graphMode = Application.Properties.getValue("graphmode");
        if (graphMode instanceof Number) { config.graphMode = graphMode; }

        var smallFieldData = Application.Properties.getValue("small_field_data");
        if (smallFieldData instanceof Number) { config.smallFieldData = smallFieldData; }

        config.normalize();
        return config;
    }
}
