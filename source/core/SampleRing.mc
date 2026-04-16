class AG2SampleRing {
    hidden var mValues as Array<Float> = [];
    hidden var mSize as Number = 0;
    hidden var mCount as Number = 0;
    hidden var mNextIndex as Number = 0;

    function initialize(size as Number) {
        resize(size);
    }

    function resize(size as Number) as Void {
        mSize = size;
        mValues = [];
        for (var i = 0; i < mSize; i++) {
            mValues.add(0.0);
        }
        mCount = 0;
        mNextIndex = 0;
    }

    function reset() as Void {
        mCount = 0;
        mNextIndex = 0;
        for (var i = 0; i < mSize; i++) {
            mValues[i] = 0.0;
        }
    }

    function push(value as Float) as Void {
        mValues[mNextIndex] = value;
        mNextIndex = (mNextIndex + 1) % mSize;

        if (mCount < mSize) {
            mCount += 1;
        }
    }

    function count() as Number {
        return mCount;
    }

    function averageRecent(maxSamples as Number) as Float {
        if (mCount <= 0) { return 0.0; }

        var sampleCount = maxSamples;
        if (sampleCount > mCount) { sampleCount = mCount; }

        var total = 0.0;
        for (var i = 0; i < sampleCount; i++) {
            var idx = (mNextIndex + mSize - 1 - i) % mSize;
            total += mValues[idx];
        }

        return total / sampleCount;
    }
}
