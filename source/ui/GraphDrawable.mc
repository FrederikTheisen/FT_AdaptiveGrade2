import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AG2GraphDrawable extends WatchUi.Drawable {
    hidden var mLayout as Number = AG2LayoutClassifier.LAYOUT_SMALL;
    hidden var mBufferSnapshot as AG2BufferSnapshot or Null = null;
    hidden var mHistogramSnapshot as AG2HistogramSnapshot or Null = null;
    hidden var mShowBuffer as Boolean = false;
    hidden var mShowHistogram as Boolean = false;
    hidden var mForegroundColor as ColorValue = Graphics.COLOR_BLACK;
    hidden var mLineColor as ColorValue = Graphics.COLOR_LT_GRAY;
    hidden var mBarColor as ColorValue = Graphics.COLOR_DK_GRAY;
    hidden var mAccentColor as ColorValue = Graphics.COLOR_RED;
    hidden var mPlotMinX as Float = 0.0;
    hidden var mPlotXRange as Float = 1.0;
    hidden var mPlotMinY as Float = 0.0;
    hidden var mPlotYRange as Float = 1.0;

    function initialize() {
        Drawable.initialize({
            :identifier => "graph"
        });
    }

    function configure(layout as Number, bufferSnapshot as AG2BufferSnapshot or Null, histogramSnapshot as AG2HistogramSnapshot or Null, showBuffer as Boolean, showHistogram as Boolean, qualityState as String, backgroundColor as ColorValue) as Void {
        mLayout = layout;
        mBufferSnapshot = bufferSnapshot;
        mHistogramSnapshot = histogramSnapshot;
        mShowBuffer = showBuffer;
        mShowHistogram = showHistogram;

        if (backgroundColor == Graphics.COLOR_BLACK) {
            mForegroundColor = Graphics.COLOR_WHITE;
            mLineColor = Graphics.COLOR_DK_GRAY;
            mBarColor = Graphics.COLOR_LT_GRAY;
        } else {
            mForegroundColor = Graphics.COLOR_BLACK;
            mLineColor = Graphics.COLOR_LT_GRAY;
            mBarColor = Graphics.COLOR_DK_GRAY;
        }

        switch (qualityState) {
            case "GOOD":
                mAccentColor = Graphics.COLOR_DK_GREEN;
                break;
            case "WARN":
                mAccentColor = Graphics.COLOR_ORANGE;
                break;
            case "BAD":
                mAccentColor = Graphics.COLOR_RED;
                break;
            default:
                mAccentColor = mForegroundColor;
                break;
        }
    }

    function draw(dc as Dc) as Void {
        if (!mShowBuffer && !mShowHistogram) { return; }

        var x = locX;
        var y = locY;
        var w = width;
        var h = height;

        if (w <= 0 || h <= 0) {
            x = 0;
            y = 0;
            w = dc.getWidth();
            h = dc.getHeight();
        }

        if (mLayout == AG2LayoutClassifier.LAYOUT_LARGE) {
            x = 3;
            y = (dc.getHeight() * 55 / 100).toNumber();
            w = dc.getWidth() - 6;
            h = dc.getHeight() - y - 3;
        }

        if (mShowBuffer && mShowHistogram) {
            var halfHeight = h / 2;
            drawBufferPlot(dc, x, y, w, halfHeight - 1);
            drawHistogramPlot(dc, x, y + halfHeight, w, h - halfHeight);
        } else if (mShowBuffer) {
            drawBufferPlot(dc, x, y, w, h);
        } else if (mShowHistogram) {
            drawHistogramPlot(dc, x, y, w, h);
        }
    }

    hidden function drawBufferPlot(dc as Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var snapshot = mBufferSnapshot;
        if (snapshot == null) { return; }

        var altitudes = (snapshot as AG2BufferSnapshot).altitudes;
        var distances = (snapshot as AG2BufferSnapshot).distances;
        var sampleCount = altitudes.size();
        if (sampleCount < 2) { return; }

        var minX = distances[0];
        var maxX = distances[sampleCount - 1];
        if (maxX - minX < 50.0) {
            minX = maxX - 50.0;
        }

        var minY = altitudes[0];
        var maxY = altitudes[0];

        for (var i = 0; i < sampleCount; i++) {
            if (altitudes[i] < minY) { minY = altitudes[i]; }
            if (altitudes[i] > maxY) { maxY = altitudes[i]; }
        }

        var xRange = maxX - minX;
        var yRangeData = maxY - minY;
        if (yRangeData < 0.1 * xRange) {
            var midY = (maxY + minY) / 2.0;
            minY = midY - 0.05 * xRange;
            maxY = midY + 0.05 * xRange;
        }

        minY -= 1.0;
        maxY += 1.0;
        var yRange = maxY - minY;
        if (xRange <= 0.0 || yRange <= 0.0) { return; }

        mPlotMinX = minX;
        mPlotXRange = xRange;
        mPlotMinY = minY;
        mPlotYRange = yRange;

        dc.setClip(x, y, w, h);
        dc.setColor(mLineColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        for (var j = 0; j < sampleCount - 1; j++) {
            var x1 = x + ((distances[j] - minX) / xRange) * (w - 1);
            var x2 = x + ((distances[j + 1] - minX) / xRange) * (w - 1);
            var y1 = y + h - 1 - ((altitudes[j] - minY) / yRange) * (h - 1);
            var y2 = y + h - 1 - ((altitudes[j + 1] - minY) / yRange) * (h - 1);
            dc.drawLine(x1, y1, x2, y2);
        }

        drawRegressionLine(dc, snapshot as AG2BufferSnapshot, x, y, w, h);

        dc.clearClip();
        dc.setColor(mForegroundColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x, y, w, h);
    }

    hidden function drawRegressionLine(dc as Dc, snapshot as AG2BufferSnapshot, x as Number, y as Number, w as Number, h as Number) as Void {
        if (snapshot.windowSize < 2) { return; }

        var altitudes = snapshot.altitudes;
        var distances = snapshot.distances;
        var sampleCount = altitudes.size();
        var windowStart = snapshot.windowStartIndex;
        if (windowStart >= sampleCount - 1) { return; }

        var sumX = 0.0;
        var sumY = 0.0;
        var count = 0;
        for (var i = windowStart; i < sampleCount; i++) {
            sumX += distances[i];
            sumY += altitudes[i];
            count += 1;
        }

        if (count <= 0) { return; }

        var meanX = sumX / count.toFloat();
        var meanY = sumY / count.toFloat();
        var xStart = distances[windowStart];
        var xEnd = distances[sampleCount - 1];
        var yStart = meanY + snapshot.currentGradeFraction * (xStart - meanX);
        var yEnd = meanY + snapshot.currentGradeFraction * (xEnd - meanX);

        var px1 = x + ((xStart - mPlotMinX) / mPlotXRange) * (w - 1);
        var px2 = x + ((xEnd - mPlotMinX) / mPlotXRange) * (w - 1);
        var py1 = y + h - 1 - ((yStart - mPlotMinY) / mPlotYRange) * (h - 1);
        var py2 = y + h - 1 - ((yEnd - mPlotMinY) / mPlotYRange) * (h - 1);

        dc.setColor(mAccentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(px1, py1, px2, py2);
    }

    hidden function drawHistogramPlot(dc as Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var snapshot = mHistogramSnapshot;
        if (snapshot == null) { return; }

        var values = (snapshot as AG2HistogramSnapshot).values;
        var currentBinIndex = (snapshot as AG2HistogramSnapshot).currentBinIndex;
        var gradeCenters = (snapshot as AG2HistogramSnapshot).gradeCenters;
        if (values.size() <= 0) { return; }

        var maxValue = 0.0;
        for (var i = 0; i < values.size(); i++) {
            if (values[i] > maxValue) { maxValue = values[i]; }
        }
        if (maxValue <= 0.0) { return; }

        maxValue *= 1.1;

        var innerWidth = w - 2;
        var labelBandHeight = getHistogramLabelBandHeight(h);
        var innerHeight = h - labelBandHeight - 2;
        if (innerHeight < 6) {
            innerHeight = h - 2;
            labelBandHeight = 0;
        }

        var plotTop = y + 1;
        var plotBottom = plotTop + innerHeight;
        var binWidth = innerWidth.toFloat() / values.size().toFloat();

        dc.setClip(x, y, w, h);
        dc.setPenWidth(1);

        if (labelBandHeight > 0) {
            dc.setColor(mLineColor, Graphics.COLOR_TRANSPARENT);
            for (var tickIndex = 0; tickIndex < values.size(); tickIndex++) {
                if (!shouldDrawHistogramTick(snapshot as AG2HistogramSnapshot, tickIndex)) { continue; }

                var tickLeft = x + 1 + (tickIndex.toFloat() * binWidth).toNumber();
                var tickRight = x + 1 + (((tickIndex + 1).toFloat() * binWidth).toNumber());
                var tickCenter = tickLeft + ((tickRight - tickLeft) / 2);
                dc.drawLine(tickCenter, plotTop, tickCenter, plotBottom);
            }
        }

        for (var j = 0; j < values.size(); j++) {
            var x1 = x + 1 + (j.toFloat() * binWidth).toNumber();
            var x2 = x + 1 + (((j + 1).toFloat() * binWidth).toNumber());
            var barWidth = x2 - x1;
            if (barWidth < 1) { barWidth = 1; }
            var fillWidth = barWidth;
            if (fillWidth > 1) { fillWidth -= 1; }

            var barHeight = ((values[j] / maxValue) * innerHeight).toNumber();
            if (barHeight < 1) { barHeight = 1; }
            var y1 = plotBottom - barHeight;

            if (j == currentBinIndex) {
                dc.setColor(mAccentColor, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(mBarColor, Graphics.COLOR_TRANSPARENT);
            }

            dc.fillRectangle(x1, y1, fillWidth, barHeight);
        }

        dc.clearClip();

        if (labelBandHeight > 0) {
            drawHistogramLabels(dc, snapshot as AG2HistogramSnapshot, gradeCenters, x, y, w, h, binWidth);
        }

        dc.setColor(mForegroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, w, h);
    }

    hidden function getHistogramLabelBandHeight(h as Number) as Number {
        if (h >= 28) { return 11; }
        if (h >= 20) { return 9; }
        return 0;
    }

    hidden function shouldDrawHistogramTick(snapshot as AG2HistogramSnapshot, index as Number) as Boolean {
        var gradeValue = (snapshot.gradeCenters[index] as Float).toNumber();
        if (index == 0 || index == snapshot.gradeCenters.size() - 1) { return true; }
        return gradeValue % snapshot.tickStep == 0;
    }

    hidden function drawHistogramLabels(dc as Dc, snapshot as AG2HistogramSnapshot, gradeCenters as Array, x as Number, y as Number, w as Number, h as Number, binWidth as Float) as Void {
        dc.setColor(mForegroundColor, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < gradeCenters.size(); i++) {
            if (!shouldDrawHistogramTick(snapshot, i)) { continue; }

            var x1 = x + 1 + (i.toFloat() * binWidth).toNumber();
            var x2 = x + 1 + (((i + 1).toFloat() * binWidth).toNumber());
            var centerX = x1 + ((x2 - x1) / 2);
            var label = (gradeCenters[i] as Float).format("%.0f") + "%";

            dc.drawText(centerX, y + h - 5, Graphics.FONT_SYSTEM_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
