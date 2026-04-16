import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;

class AG2DataField extends WatchUi.DataField {
    hidden var mConfig as AG2Config;
    hidden var mSettingsStore as AG2SettingsStore;
    hidden var mEngine as AG2GradeEngine;
    hidden var mMetrics as AG2MetricsAggregator;
    hidden var mHistogram as AG2HistogramEngine;
    hidden var mFitWriter as AG2FitFieldWriter;
    hidden var mLayoutClassifier as AG2LayoutClassifier;
    hidden var mViewModelMapper as AG2ViewModelMapper;
    hidden var mRenderer as AG2Renderer;
    hidden var mCurrentResult as AG2ComputeResult;
    hidden var mCurrentLayout as Number;

    function initialize() {
        DataField.initialize();

        mSettingsStore = new AG2SettingsStore();
        mLayoutClassifier = new AG2LayoutClassifier();
        mViewModelMapper = new AG2ViewModelMapper();
        mRenderer = new AG2Renderer();
        mCurrentLayout = AG2LayoutClassifier.LAYOUT_SMALL;

        updateSettings();
    }

    function updateSettings() as Void {
        mConfig = mSettingsStore.load();
        mEngine = new AG2GradeEngine(mConfig);
        mMetrics = new AG2MetricsAggregator();
        mHistogram = new AG2HistogramEngine();
        mFitWriter = new AG2FitFieldWriter();
        mCurrentResult = new AG2ComputeResult();
    }

    function onLayout(dc as Dc) as Void {
        mCurrentLayout = mLayoutClassifier.detect(dc);

        switch (mCurrentLayout) {
            case AG2LayoutClassifier.LAYOUT_SMALL_NARROW:
                View.setLayout(Rez.Layouts.SmallNarrowLayout(dc));
                break;
            case AG2LayoutClassifier.LAYOUT_WIDE:
                View.setLayout(Rez.Layouts.WideLayout(dc));
                break;
            case AG2LayoutClassifier.LAYOUT_LARGE:
                View.setLayout(Rez.Layouts.LargeLayout(dc));
                break;
            case AG2LayoutClassifier.LAYOUT_SMALL:
            default:
                View.setLayout(Rez.Layouts.SmallLayout(dc));
                break;
        }
    }

    function compute(info as Activity.Info) as Void {
        mCurrentResult = mEngine.compute(info, mConfig);
        mMetrics.apply(mCurrentResult, mConfig);
        mHistogram.addGrade(mCurrentResult.gradeFraction * 100.0, mCurrentResult.quality);
        mFitWriter.syncRecord(mCurrentResult, mMetrics, mHistogram);
    }

    function onUpdate(dc as Dc) as Void {
        var model = mViewModelMapper.map(mCurrentResult, mMetrics, mHistogram, mCurrentLayout);
        mRenderer.render(self, model, getBackgroundColor());
        View.onUpdate(dc);
    }

    function onTimerLap() as Void {
        mMetrics.resetLap();
        mFitWriter.syncLap(mMetrics);
    }

    function onTimerPause() as Void {
        mFitWriter.syncSession(mMetrics, mHistogram);
    }

    function onTimerStop() as Void {
        mFitWriter.syncSession(mMetrics, mHistogram);
    }

    function onTimerReset() as Void {
        updateSettings();
    }
}
