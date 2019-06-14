import std;
import std.stdio;
import std.string;

import bindbc.opengl;
import bindbc.glfw;

class Canvas {
  GLFWwindow* window;
  int width, height;
  string title;
  GLuint[] vaos, vbos, programs;
  GLuint[string] shaders;

  float[] vertices;

  this(int width, int height, string title) {
    this.width = width;
    this.height = height;
    this.title = title;

    writefln("Creating canvas with W: %d H: %d Title: %s", width, height, title);

    initGL();
  }

  ~this() {
    foreach(programId; this.programs) {
      writeln("Deleting program: ", programId);
      glDeleteProgram(programId);
    }

    foreach(shaderName, shaderId; this.shaders) {
      writeln("Deleting shader: ", shaderName);
      glDeleteShader(shaderId);
    }

    foreach(vboId; this.vbos) {
      writeln("Deleting VBO: ", vboId);
      glDeleteBuffers(1, &vboId);
    }

    foreach(vaoId; this.vaos) {
      writeln("Deleting VAO: ", vaoId);
      glDeleteVertexArrays(1, &vaoId);
    }

    glfwTerminate();
  }

  void render() {
    // todo
    // glDrawArrays(GL_TRIANGLES, 0, 6);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(this.vaos[0]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
  }

  void initGL() {
    loadGLFW();

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    glfwInit();

    this.window = glfwCreateWindow(
        this.width,
        this.height,
        toStringz(this.title),
        null,
        null
        );

    glfwMakeContextCurrent(window);

    auto loadOpenGLStatus = loadOpenGL();

    switch (loadOpenGLStatus) {
      case GLSupport.noContext:
        writeln("No context provided");
        break;

      default:
        writeln("OpenGL version loaded: ", loadOpenGLStatus);
    }
  }

  void generateGeomtry() {
    this.vertices ~= [-0.5f, -0.5f];
    this.vertices ~= [-0.5f,  0.5f];
    this.vertices ~= [0.5f, -0.5f];

    this.vertices ~= [-0.5f, 0.5f];
    this.vertices ~= [0.5f, 0.5f];
    this.vertices ~= [0.5f, -0.5f];
  }

  void computeShaders() {
    // Shaders
    string vertexShaderSrcString = q{
#version 330 core

      layout (location = 0) in vec2 position;

      void main() {
        gl_Position = vec4(position, 0.0, 1.0);
      }
    };

    string fragmentShaderSrcString = q{
#version 330 core

      layout (location = 0) out vec4 FragColor;

      void main() {
        // All white
        FragColor = vec4(0.7, 0.5, 1.0, 1.0);
      }
    };

    auto vertexShaderSrc = toStringz(vertexShaderSrcString);
    auto fragmentShaderSrc = toStringz(fragmentShaderSrcString);

    this.shaders["vertex"] = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(shaders["vertex"], 1, &vertexShaderSrc, null);
    glCompileShader(shaders["vertex"]);

    char *infoLog;
    int success;

    glGetShaderiv(shaders["vertex"], GL_COMPILE_STATUS, &success);

    if (!success) {
      glGetShaderInfoLog(shaders["vertex"], 512, null, infoLog);
      writeln("VERTEX:COMPILE:ERROR");
      writeln(infoLog);
    }

    this.shaders["fragment"] = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(shaders["fragment"], 1, &fragmentShaderSrc, null);
    glCompileShader(shaders["fragment"]);

    glGetShaderiv(shaders["fragment"], GL_COMPILE_STATUS, &success);

    if (!success) {
      glGetShaderInfoLog(shaders["fragment"], 512, null, infoLog);
      writeln("FRAGMENT:COMPILE:ERROR");
      writeln(infoLog);
    }

    this.programs ~= glCreateProgram();

    glAttachShader(this.programs[0], this.shaders["vertex"]);
    glAttachShader(this.programs[0], this.shaders["fragment"]);

    glBindFragDataLocationIndexed(this.programs[0], 0, 1, "FragColor");

    glLinkProgram(this.programs[0]);
    glUseProgram(this.programs[0]);
  }

  void initGraphics() {
    GLuint vao, vbo;

    // VAO
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // VBO
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    this.vaos ~= vao;
    this.vbos ~= vbo;

    this.generateGeomtry();

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);

    this.computeShaders();

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, cast(void*) 0);
    glEnableVertexAttribArray(0);

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    glBindVertexArray(this.vaos[0]);
  }

  void loop() {
    initGraphics();

    while (!glfwWindowShouldClose(window)) {
      glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
      glClear(GL_COLOR_BUFFER_BIT);

      render();

      glfwSwapBuffers(window);
      glfwPollEvents();
    }
  }
}

int main() {
  Canvas canvas = new Canvas(800, 600, "Canvas");
  canvas.loop();

  return 0;
}
