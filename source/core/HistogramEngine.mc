import Toybox.Lang;

class AG2HistogramEngine {
    var minBin as Float = -25.0;
    var minQuality as Float = 0.5;
    var computed as Boolean = false;
    var computedSampledBinRange as Array<Number> = [0, 0];
    var computedHistogramForRange as Array<Float> = [];

    hidden var mBins = [];
    hidden var mBinSize as Float = 1.0;
    hidden var mNumBins as Number = 0;
    hidden var mTrackedSeconds as Number = 0;

    function initialize(minQuality as Float) {
        self.minQuality = minQuality;
        reset();
    }

    function reset() as Void {
        mTrackedSeconds = 0;
        computed = false;
        computedSampledBinRange = [0, 0];
        computedHistogramForRange = [];
        mBins = [];

        for (var i = minBin; i < 25.0; i += mBinSize) {
            mBins.add(0);
        }

        mNumBins = mBins.size();
    }

    function addGrade(gradePercent as Float, quality as Float) as Void {
        if (quality < minQuality) { return; }

        var binIndex = getBinIndex(gradePercent);
        if (binIndex < 0) { binIndex = 0; }
        if (binIndex >= mNumBins) { binIndex = mNumBins - 1; }

        if (mNumBins > 0) {
            mBins[binIndex] = (mBins[binIndex] as Number) + 1;
            mTrackedSeconds += 1;
        }
    }

    function shouldUpdate() as Boolean {
        if (mTrackedSeconds < 100) { return true; }
        if (mTrackedSeconds < 500) { return mTrackedSeconds % 2 == 0; }
        if (mTrackedSeconds < 2000) { return mTrackedSeconds % 4 == 0; }
        if (mTrackedSeconds < 5000) { return mTrackedSeconds % 8 == 0; }
        return mTrackedSeconds % 16 == 0;
    }

    function compute() as Void {
        if (mTrackedSeconds <= 0) {
            computed = false;
            computedSampledBinRange = [0, 0];
            computedHistogramForRange = [];
            return;
        }

        var sampledRange = getSampledBinRange();
        if (sampledRange[0] > 21) { sampledRange[0] = 21; }
        if (sampledRange[1] < 28) { sampledRange[1] = 28; }

        computedSampledBinRange = sampledRange;
        computedHistogramForRange = getHistogramForRange(sampledRange);
        computed = true;
    }

    function getBinIndex(gradePercent as Float) as Number {
        var binIndex = ((gradePercent - minBin) / mBinSize).toNumber();
        if (binIndex < 0) { return 0; }
        if (binIndex >= mNumBins) { return mNumBins - 1; }
        return binIndex;
    }

    function getGradeForBin(binIndex as Number) as Float {
        if (binIndex < 0 || binIndex >= mNumBins) { return 0.0; }
        return minBin + binIndex * mBinSize + mBinSize / 2.0;
    }

    function getHighGrade(percent as Float) as Float {
        if (mTrackedSeconds <= 0) { return 0.0; }

        var pct = percent;
        var range = computedSampledBinRange;
        if (!computed) {
            range = getSampledBinRange();
        }

        if (pct <= 0.0) { return getGradeForBin(range[1]); }
        if (pct >= 100.0) { return getGradeForBin(range[0]); }

        var target = mTrackedSeconds * (pct / 100.0);
        var cumulative = 0.0;

        for (var i = mNumBins - 1; i >= 0; i--) {
            var binCount = (mBins[i] as Number).toFloat();
            if (binCount <= 0.0) { continue; }

            var cumulativeAbove = cumulative;
            cumulative += binCount;

            if (cumulative >= target) {
                var binLower = minBin + i * mBinSize;
                var binUpper = binLower + mBinSize;
                var countNeeded = target - cumulativeAbove;

                if (countNeeded < 0.0) { countNeeded = 0.0; }
                if (countNeeded > binCount) { countNeeded = binCount; }

                var fractionInBin = countNeeded / binCount;
                return binUpper - fractionInBin * mBinSize;
            }
        }

        return minBin;
    }

    function getHighGradeForTime(seconds as Float) as Float {
        if (mTrackedSeconds <= 0) { return 0.0; }
        var percent = (seconds / mTrackedSeconds.toFloat()) * 100.0;
        return getHighGrade(percent);
    }

    function getTrackedSeconds() as Number {
        return mTrackedSeconds;
    }

    function getSnapshot(currentGradePercent as Float) as AG2HistogramSnapshot or Null {
        if (!computed || computedHistogramForRange.size() == 0) { return null; }

        var snapshot = new AG2HistogramSnapshot();
        snapshot.rangeStart = computedSampledBinRange[0];
        snapshot.rangeEnd = computedSampledBinRange[1];
        snapshot.currentBinIndex = getBinIndex(currentGradePercent) - computedSampledBinRange[0];
        snapshot.tickStep = getTickStep(snapshot.rangeEnd - snapshot.rangeStart);

        for (var i = snapshot.rangeStart; i <= snapshot.rangeEnd; i++) {
            snapshot.gradeCenters.add(getGradeForBin(i) - 0.5);
        }

        for (var j = 0; j < computedHistogramForRange.size(); j++) {
            snapshot.values.add(computedHistogramForRange[j]);
        }

        return snapshot;
    }

    hidden function getSampledBinRange() as Array {
        var minSampled = 0;
        var maxSampled = mNumBins - 1;
        var found = false;

        for (var i = 0; i < mNumBins; i++) {
            if ((mBins[i] as Number) > 0) {
                if (!found) {
                    minSampled = i;
                    found = true;
                }
                maxSampled = i;
            }
        }

        return [minSampled, maxSampled];
    }

    hidden function getHistogramForRange(range as Array) as Array {
        var values = [];
        if (mTrackedSeconds <= 0) { return values; }

        for (var i = range[0]; i <= range[1]; i++) {
            values.add((mBins[i] as Number).toFloat() / mTrackedSeconds.toFloat());
        }

        return values;
    }

    hidden function getTickStep(binSpan as Number) as Number {
        if (binSpan >= 35) { return 10; }
        if (binSpan >= 18) { return 5; }
        if (binSpan >= 10) { return 2; }
        return 1;
    }
}
