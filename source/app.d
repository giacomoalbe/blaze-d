import std.stdio;

import gdk.Event;
import gdk.GLContext;

import gtk.Main;

import Canvas;
import BlazeWindow;

void main(string[] args) {
  Main.init(args);

  int width = 800;
  int height = 600;

  auto win = new BlazeWindow(width, height);

  Main.run();
}
