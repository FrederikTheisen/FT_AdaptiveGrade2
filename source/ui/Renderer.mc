import Toybox.Graphics;
import Toybox.WatchUi;

class AG2Renderer {
    function initialize() {
    }

    function render(view as WatchUi.View, model as AG2ViewModel, backgroundColor as ColorValue) as Void {
        var background = view.findDrawableById("Background") as Background;
        if (background != null) {
            background.setColor(backgroundColor);
        }

        var foregroundColor = Graphics.COLOR_BLACK;
        if (backgroundColor == Graphics.COLOR_BLACK) {
            foregroundColor = Graphics.COLOR_WHITE;
        }

        var title = view.findDrawableById("title") as Text;
        if (title != null) {
            title.setColor(Graphics.COLOR_LT_GRAY);
            title.setText(model.title);
        }

        var value = view.findDrawableById("value") as Text;
        if (value != null) {
            value.setColor(foregroundColor);
            value.setText(model.value);
        }

        var status = view.findDrawableById("status") as Text;
        if (status != null) {
            status.setColor(foregroundColor);
            status.setText(model.status);
        }

        var meta = view.findDrawableById("meta") as Text;
        if (meta != null) {
            meta.setVisible(model.showMeta);
            meta.setColor(Graphics.COLOR_LT_GRAY);
            meta.setText(model.meta);
        }
    }
}
