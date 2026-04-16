import Toybox.Lang;

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
    var simpleMode as Boolean = false;
    var maxAllowedGrade as Float = 0.3;

    function initialize() {
    }

    function normalize() as Void {
        if (sampleWindow < 10) { sampleWindow = 10; }
        if (sampleWindow > 180) { sampleWindow = 180; }

        if (minGradeWindow < 3) { minGradeWindow = 3; }
        if (maxGradeWindow < minGradeWindow) { maxGradeWindow = minGradeWindow; }
        if (maxGradeWindow > sampleWindow) { maxGradeWindow = sampleWindow; }
    }
}
