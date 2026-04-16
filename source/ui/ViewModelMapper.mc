import Toybox.WatchUi;

class AG2ViewModelMapper {
    function initialize() {
    }

    function map(result as AG2ComputeResult, metrics as AG2MetricsAggregator, histogram as AG2HistogramEngine, layout as Number) as AG2ViewModel {
        var model = new AG2ViewModel();
        model.title = WatchUi.loadResource(Rez.Strings.UI_Title_Grade);

        if (result.isActive) {
            model.value = (result.gradeFraction * 100.0).format("%+.1f") + "%";
        } else {
            model.value = "0.0%";
        }

        switch (result.status) {
            case "BUFFERING":
                model.status = WatchUi.loadResource(Rez.Strings.UI_Status_Buffering) + " " + result.sampleCount.format("%d");
                break;
            case "ACTIVE":
                model.status = WatchUi.loadResource(Rez.Strings.UI_Status_Active) + " " + result.windowSize.format("%d") + "s";
                break;
            case "RESET":
                model.status = WatchUi.loadResource(Rez.Strings.UI_Status_Reset);
                break;
            default:
                model.status = WatchUi.loadResource(Rez.Strings.UI_Status_NoData);
                break;
        }

        model.meta = "MAX " + (metrics.maxGradeFraction * 100.0).format("%.1f") + "% | VAM " + metrics.currentVam.format("%.0f");
        model.showMeta = layout != AG2LayoutClassifier.LAYOUT_SMALL_NARROW;

        return model;
    }
}
