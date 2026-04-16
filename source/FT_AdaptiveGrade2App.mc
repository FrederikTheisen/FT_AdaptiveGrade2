import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FT_AdaptiveGrade2App extends Application.AppBase {
    var view as AG2DataField or Null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function onSettingsChanged() as Void {
        AppBase.onSettingsChanged();

        if (view != null) {
            view.updateSettings();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        view = new AG2DataField();
        return [ view ];
    }
}

function getApp() as FT_AdaptiveGrade2App {
    return Application.getApp() as FT_AdaptiveGrade2App;
}
