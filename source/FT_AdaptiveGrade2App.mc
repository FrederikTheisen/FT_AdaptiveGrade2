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
        var inputDelegate = new AG2InputDelegate(view);
        return [ view, inputDelegate ];
    }
}

class AG2InputDelegate extends WatchUi.InputDelegate {
    hidden var mDataField as AG2DataField;

    function initialize(dataField as AG2DataField) {
        InputDelegate.initialize();
        mDataField = dataField;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        return mDataField.handleTap(clickEvent);
    }
}

function getApp() as FT_AdaptiveGrade2App {
    return Application.getApp() as FT_AdaptiveGrade2App;
}
