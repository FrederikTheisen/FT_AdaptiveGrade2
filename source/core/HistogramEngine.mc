class AG2HistogramEngine {
    hidden var mTrackedSeconds as Number = 0;
    hidden var mBestGradePercent as Float = 0.0;

    function initialize() {
    }

    function reset() as Void {
        mTrackedSeconds = 0;
        mBestGradePercent = 0.0;
    }

    function addGrade(gradePercent as Float, quality as Float) as Void {
        if (quality < 0.1) { return; }

        mTrackedSeconds += 1;
        if (gradePercent > mBestGradePercent) {
            mBestGradePercent = gradePercent;
        }
    }

    function getHighGradeForTime(seconds as Float) as Float {
        return mBestGradePercent;
    }

    function getTrackedSeconds() as Number {
        return mTrackedSeconds;
    }
}
