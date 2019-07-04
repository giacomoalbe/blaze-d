import std;

import gdk.Screen;

import gtk.MainWindow;
import gtk.Label;
import gtk.Grid;
import gtk.Scale;
import gtk.Range;
import gtk.CssProvider;
import gtk.StyleContext;

import Canvas;
//import Slider;

class BlazeWindow : MainWindow {
  this(int width, int height) {
    super("Blaze");

    CssProvider cssProvider = new CssProvider();
    cssProvider.loadFromPath("assets/style.css");

    StyleContext.addProviderForScreen(Screen.getDefault(), cssProvider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    Canvas canvas = new Canvas();

    Grid mainGrid = new Grid();

    Label label = new Label("");
    label.setSizeRequest(50, 20);

    Scale range = new Scale(GtkOrientation.HORIZONTAL, 0, 100, 1);
    range.setDrawValue(false);
    range.setHexpand(true);

    range.addOnValueChanged(delegate(Range range) {
        auto value = range.getValue() / 100;
        canvas.setMixFactor(value);
        label.setText(to!string(cast(int) (value * 100)) ~ " %");
    });

    label.setText("0 %");

    Label scaleLabel = new Label("");
    scaleLabel.setSizeRequest(50, 20);

    Scale scaleRange = new Scale(GtkOrientation.HORIZONTAL, 0, 300, 10);
    scaleRange.setDrawValue(false);
    scaleRange.setHexpand(true);

    scaleRange.addOnValueChanged(delegate(Range range) {
        auto value = range.getValue() / 100;
        canvas.setScale(value);
        scaleLabel.setText(to!string(cast(int) (value * 100)));
    });

    scaleLabel.setText("0");
    scaleRange.setValue(100.0f);

    Label rotateLabel = new Label("");
    rotateLabel.setSizeRequest(50, 20);

    Scale rotateRange = new Scale(GtkOrientation.HORIZONTAL, 0, 360, 1);
    rotateRange.setDrawValue(false);
    rotateRange.setHexpand(true);

    rotateRange.addOnValueChanged(delegate(Range range) {
        auto value = range.getValue();
        canvas.setRotation(value);
        rotateLabel.setText(to!string(cast(int) value));
    });

    rotateLabel.setText("0");
    rotateRange.setValue(0.0f);

    mainGrid.attach(canvas, 0, 0, 2, 1);
    mainGrid.attach(range, 0, 1, 1, 1);
    mainGrid.attach(label, 1, 1, 1, 1);
    mainGrid.attach(scaleRange, 0, 2, 1, 1);
    mainGrid.attach(scaleLabel, 1, 2, 1, 1);
    mainGrid.attach(rotateRange, 0, 3, 1, 1);
    mainGrid.attach(rotateLabel, 1, 3, 1, 1);

    mainGrid.setHexpand(true);
    mainGrid.setVexpand(true);

    add(mainGrid);

    mainGrid.showAll();

    setDefaultSize(width, height);
    showAll();
  }
}
