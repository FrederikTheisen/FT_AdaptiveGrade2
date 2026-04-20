import Toybox.Lang;

class AG2MetricsAggregator {
    var distLightMeters as Float = 0.0;
    var distSteepMeters as Float = 0.0;
    var maxGradeFraction as Float = 0.0;
    var currentVam as Float = 0.0;
    var averageVam as Float = 0.0;

    hidden var mSumAscentVam as Float = 0.0;
    hidden var mAscentSamples as Number = 0;
    hidden var mLapGradeSum as Float = 0.0;
    hidden var mLapGradeCount as Number = 0;

    function initialize() {
    }

    function apply(result as AG2ComputeResult, config as AG2Config) as Void {
        if (!result.isActive) {
            currentVam = 0.0;
            return;
        }

        currentVam = result.vam;

        if (shouldAccLightDist(result, config)) {
            distLightMeters += result.sampleDistanceMeters;
        }

        if (shouldAccAvgVam(result, config)) {
            mSumAscentVam += result.vam;
            mAscentSamples += 1;
            averageVam = mSumAscentVam / mAscentSamples;
        }

        if (shouldAccSteepDist(result, config)) {
            distSteepMeters += result.sampleDistanceMeters;
        }

        if (shouldCalcMaxGrade(result, config) && result.gradeFraction > maxGradeFraction) {
            maxGradeFraction = result.gradeFraction;
        }

        mLapGradeSum += result.gradeFraction;
        mLapGradeCount += 1;
    }

    function getLapAverageGradePercent() as Float {
        if (mLapGradeCount <= 0) { return 0.0; }
        return (mLapGradeSum / mLapGradeCount) * 100.0;
    }

    function resetLap() as Void {
        mLapGradeSum = 0.0;
        mLapGradeCount = 0;
    }

    hidden function shouldAccLightDist(result as AG2ComputeResult, config as AG2Config) as Boolean {
        return result.gradeFraction >= config.thresholdLight && result.quality >= config.thresholdLogDist;
    }

    hidden function shouldAccSteepDist(result as AG2ComputeResult, config as AG2Config) as Boolean {
        return result.gradeFraction >= config.thresholdSteep && result.quality >= config.thresholdLogDist;
    }

    hidden function shouldAccAvgVam(result as AG2ComputeResult, config as AG2Config) as Boolean {
        return result.gradeFraction >= config.thresholdLight && result.quality >= config.thresholdLogDist;
    }

    hidden function shouldCalcMaxGrade(result as AG2ComputeResult, config as AG2Config) as Boolean {
        if (result.quality < config.thresholdLogMax) { return false; }
        return result.windowSize > config.minGradeWindow || result.windowSize == config.maxGradeWindow;
    }
}
