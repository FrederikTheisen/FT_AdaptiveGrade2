import Toybox.Lang;

const AG2_GRAPHMODE_BOTH = 0;
const AG2_GRAPHMODE_BUFFER = 1;
const AG2_GRAPHMODE_HISTOGRAM = 2;

const AG2_SMALL_FIELD_VAM = 0;
const AG2_SMALL_FIELD_DIST = 1;
const AG2_SMALL_FIELD_CLIMBMAX = 2;
const AG2_SMALL_FIELD_CLIMBVAM = 3;

const AG2_RESET_MIN_DISTANCE_METERS = 0.1;
const AG2_RESET_MAX_SAMPLE_GAP_SECONDS = 5.0;
const AG2_RESET_ALTITUDE_JUMP_METERS = 10.0;
const AG2_QUALITY_SCALE = 0.005;

class AG2Config {
    var sampleWindow as Number = 35;
    var minGradeWindow as Number = 7;
    var maxGradeWindow as Number = 20;
    var thresholdLogDist as Float = 0.1;
    var thresholdLogMax as Float = 0.5;
    var thresholdLight as Float = 0.035;
    var thresholdSteep as Float = 0.08;
    var enableLogging as Boolean = true;
    var enableGradeLogging as Boolean = false;
    var graphMode as Number = 0;
    var smallFieldData as Number = 3;
    var maxAllowedGrade as Float = 0.3;

    function initialize() {
    }

    function normalize() as Void {
        if (sampleWindow < 10) { sampleWindow = 10; }
        if (sampleWindow > 180) { sampleWindow = 180; }

        if (minGradeWindow < 3) { minGradeWindow = 3; }
        if (maxGradeWindow < minGradeWindow) { maxGradeWindow = minGradeWindow; }
        if (maxGradeWindow > sampleWindow) { sampleWindow = maxGradeWindow; }

        if (thresholdLogDist < 0.0) { thresholdLogDist = 0.0; }
        if (thresholdLogDist > 1.0) { thresholdLogDist = 1.0; }

        if (thresholdLogMax < 0.0) { thresholdLogMax = 0.0; }
        if (thresholdLogMax > 1.0) { thresholdLogMax = 1.0; }

        if (thresholdLight < 0.0) { thresholdLight = 0.0; }
        if (thresholdLight > 1.0) { thresholdLight = 1.0; }

        if (thresholdSteep < 0.0) { thresholdSteep = 0.0; }
        if (thresholdSteep > 1.0) { thresholdSteep = 1.0; }
        if (thresholdSteep < thresholdLight) { thresholdSteep = thresholdLight; }

        if (graphMode < AG2_GRAPHMODE_BOTH || graphMode > AG2_GRAPHMODE_HISTOGRAM) {
            graphMode = AG2_GRAPHMODE_BUFFER;
        }

        if (smallFieldData < AG2_SMALL_FIELD_VAM || smallFieldData > AG2_SMALL_FIELD_CLIMBVAM) {
            smallFieldData = AG2_SMALL_FIELD_VAM;
        }

        if (maxAllowedGrade <= 0.0) { maxAllowedGrade = 0.3; }
    }
}
