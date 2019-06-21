import std.stdio;

import gdk.Event;
import gdk.GLContext;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.GLArea;

import glcore;

class MyArea : GLArea {
  this() {
    writeln("Once the stone you crwling under");
    setAutoRender(true);

    addOnRender(&render);
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);

    showAll();
  }

  void realize(Widget) {
    makeCurrent();
  }

  void unrealize(Widget) {
    makeCurrent();
  }

  bool render(GLContext ctx, GLArea a) {
    makeCurrent();

    glClearColor(1.0f, 0.5f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glFlush();

    return true;
  }
}

class GLWindow : MainWindow {
  this(int width, int height) {
    super("GtkD: BindBC OpenGL");

    MyArea glarea = new MyArea();
    add(glarea);

    setDefaultSize(width, height);
    showAll();
  }
}

void main(string[] args) {
  Main.init(args);

  int width = 800;
  int height = 600;

  auto win = new GLWindow(width, height);

  Main.run();
}
