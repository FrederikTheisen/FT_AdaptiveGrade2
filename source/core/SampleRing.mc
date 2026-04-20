import Toybox.Lang;

class AG2SampleRing {
    hidden var mValues = [];
    hidden var mSize as Number = 0;
    hidden var mCount as Number = 0;
    hidden var mNextIndex as Number = 0;
    hidden var mTotalDistanceMeters as Float = 0.0;

    function initialize(size as Number) {
        resize(size);
    }

    function resize(size as Number) as Void {
        mSize = size;
        mValues = [];
        for (var i = 0; i < mSize; i++) {
            mValues.add(null);
        }
        mCount = 0;
        mNextIndex = 0;
        mTotalDistanceMeters = 0.0;
    }

    function reset() as Void {
        mCount = 0;
        mNextIndex = 0;
        mTotalDistanceMeters = 0.0;
        for (var i = 0; i < mSize; i++) {
            mValues[i] = null;
        }
    }

    function push(altitudeMeters as Float, distanceMeters as Float, elapsedSeconds as Float) as Void {
        if (mSize <= 0) { return; }

        if (mCount == mSize) {
            var overwritten = mValues[mNextIndex] as AG2Sample or Null;
            if (overwritten != null) {
                mTotalDistanceMeters -= (overwritten as AG2Sample).distanceMeters;
            }
        }

        mValues[mNextIndex] = new AG2Sample(altitudeMeters, distanceMeters, elapsedSeconds);
        mNextIndex = (mNextIndex + 1) % mSize;
        mTotalDistanceMeters += distanceMeters;

        if (mCount < mSize) {
            mCount += 1;
        }

        if (mTotalDistanceMeters < 0.0) {
            mTotalDistanceMeters = 0.0;
        }
    }

    function count() as Number {
        return mCount;
    }

    function capacity() as Number {
        return mSize;
    }

    function getTotalDistanceMeters() as Float {
        return mTotalDistanceMeters;
    }

    function getChronological(limit as Number) as Array {
        var samples = [];
        if (mCount <= 0) { return samples; }

        var sampleCount = limit;
        if (sampleCount > mCount) { sampleCount = mCount; }
        if (sampleCount < 0) { sampleCount = 0; }

        var startIndex = (mNextIndex + mSize - sampleCount) % mSize;
        for (var i = 0; i < sampleCount; i++) {
            var sample = mValues[(startIndex + i) % mSize] as AG2Sample or Null;
            if (sample != null) {
                samples.add(sample);
            }
        }

        return samples;
    }

    function snapshot(windowSize as Number) as AG2BufferSnapshot {
        var snapshot = new AG2BufferSnapshot();
        var samples = getChronological(mCount);
        var accumulatedDistance = 0.0;
        var count = samples.size();

        snapshot.windowSize = windowSize;
        snapshot.windowStartIndex = count - windowSize;
        if (snapshot.windowStartIndex < 0) {
            snapshot.windowStartIndex = 0;
        }

        for (var i = 0; i < count; i++) {
            var sample = samples[i] as AG2Sample;
            snapshot.altitudes.add(sample.altitudeMeters);
            snapshot.distances.add(accumulatedDistance);
            accumulatedDistance += sample.distanceMeters;
        }

        snapshot.totalDistanceMeters = accumulatedDistance;
        return snapshot;
    }
}
