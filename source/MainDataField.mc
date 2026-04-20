import Toybox.Activity;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class AG2DataField extends WatchUi.DataField {
    hidden var mConfig as AG2Config or Null;
    hidden var mSettingsStore as AG2SettingsStore;
    hidden var mEngine as AG2GradeEngine or Null;
    hidden var mMetrics as AG2MetricsAggregator or Null;
    hidden var mHistogram as AG2HistogramEngine or Null;
    hidden var mFitWriter as AG2FitFieldWriter or Null;
    hidden var mLayoutClassifier as AG2LayoutClassifier;
    hidden var mViewModelMapper as AG2ViewModelMapper;
    hidden var mRenderer as AG2Renderer;
    hidden var mCurrentResult as AG2ComputeResult or Null;
    hidden var mCurrentLayout as Number;
    hidden var mCurrentGraphMode as Number;
    hidden var mViewWidth as Number;
    hidden var mViewHeight as Number;

    function initialize() {
        DataField.initialize();

        mSettingsStore = new AG2SettingsStore();
        mLayoutClassifier = new AG2LayoutClassifier();
        mViewModelMapper = new AG2ViewModelMapper();
        mRenderer = new AG2Renderer();
        mCurrentLayout = AG2LayoutClassifier.LAYOUT_SMALL;
        mCurrentGraphMode = AG2_GRAPHMODE_BOTH;
        mViewWidth = 0;
        mViewHeight = 0;

        updateSettings();
    }

    function updateSettings() as Void {
        mConfig = mSettingsStore.load();
        mEngine = new AG2GradeEngine(mConfig);
        mMetrics = new AG2MetricsAggregator();
        mHistogram = new AG2HistogramEngine(mConfig.thresholdLogMax);
        mFitWriter = new AG2FitFieldWriter(self, mConfig);
        mCurrentResult = new AG2ComputeResult();
        mCurrentGraphMode = mConfig.graphMode;
    }

    function onLayout(dc as Dc) as Void {
        mViewWidth = dc.getWidth();
        mViewHeight = dc.getHeight();
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
        mCurrentResult = mEngine.compute(info);
        mMetrics.apply(mCurrentResult, mConfig);
        if (mCurrentResult.isActive) {
            mHistogram.addGrade(mCurrentResult.gradeFraction * 100.0, mCurrentResult.quality);
            if (mHistogram.shouldUpdate()) {
                mHistogram.compute();
            }
        }
        mFitWriter.syncRecord(mCurrentResult, mMetrics, mHistogram);
        mFitWriter.syncLap(mMetrics);
    }

    function onUpdate(dc as Dc) as Void {
        var bufferSnapshot = mEngine.getBufferSnapshot(mCurrentResult);
        var histogramSnapshot = mHistogram.getSnapshot(mCurrentResult.gradeFraction * 100.0);
        var model = mViewModelMapper.map(mCurrentResult, mMetrics, mHistogram, bufferSnapshot, histogramSnapshot, mConfig, mCurrentLayout, mCurrentGraphMode, mFitWriter);
        mRenderer.prepare(self, model, getBackgroundColor());
        View.onUpdate(dc);
        mRenderer.drawGraphs(dc, model, getBackgroundColor());
    }

    function onTimerLap() as Void {
        mMetrics.resetLap();
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

    function handleTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var shouldToggleGraph = false;

        if (mCurrentLayout == AG2LayoutClassifier.LAYOUT_LARGE) {
            var y = clickEvent.getCoordinates()[1];
            if (y > mViewHeight / 2 - 5) {
                shouldToggleGraph = true;
            }
        } else if (mCurrentLayout == AG2LayoutClassifier.LAYOUT_SMALL_NARROW) {
            shouldToggleGraph = true;
        }

        if (!shouldToggleGraph) { return false; }

        mCurrentGraphMode = (mCurrentGraphMode + 1) % 3;
        WatchUi.requestUpdate();
        return true;
    }
}
