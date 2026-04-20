import Toybox.Graphics;
import Toybox.WatchUi;

class AG2Renderer {
    function initialize() {
    }

    function prepare(view as WatchUi.View, model as AG2ViewModel, backgroundColor as ColorValue) as Void {
        var background = view.findDrawableById("Background") as Background;
        if (background != null) {
            background.setColor(backgroundColor);
        }

        var foregroundColor = Graphics.COLOR_BLACK;
        var secondaryColor = Graphics.COLOR_DK_GRAY;
        if (backgroundColor == Graphics.COLOR_BLACK) {
            foregroundColor = Graphics.COLOR_WHITE;
            secondaryColor = Graphics.COLOR_LT_GRAY;
        }

        var title = view.findDrawableById("title") as Text;
        if (title != null) {
            title.setColor(secondaryColor);
            title.setText(model.title);
            title.setVisible(model.title.length() > 0);
        }

        var value = view.findDrawableById("value") as Text;
        if (value != null) {
            if (model.qualityState == "IDLE") {
                value.setColor(Graphics.COLOR_LT_GRAY);
            } else {
                value.setColor(foregroundColor);
            }
            value.setText(model.value);
        }

        var status = view.findDrawableById("status") as Text;
        if (status != null) {
            status.setColor(foregroundColor);
            status.setText(model.status);
            status.setVisible(model.status.length() > 0);
        }

        var meta = view.findDrawableById("meta") as Text;
        if (meta != null) {
            meta.setVisible(model.showMeta);
            meta.setColor(secondaryColor);
            meta.setText(model.meta);
        }

        var detail = view.findDrawableById("detail") as Text;
        if (detail != null) {
            detail.setVisible(model.showDetail);
            detail.setColor(secondaryColor);
            detail.setText(model.detail);
        }

        var graph = view.findDrawableById("graph") as AG2GraphDrawable;
        if (graph != null) {
            graph.setVisible(model.showBufferGraph || model.showHistogramGraph);
            graph.configure(model.layout, model.bufferSnapshot, model.histogramSnapshot, model.showBufferGraph, model.showHistogramGraph, model.qualityState, backgroundColor);
        }
    }

    function drawGraphs(dc as Dc, model as AG2ViewModel, backgroundColor as ColorValue) as Void {
    }
}
