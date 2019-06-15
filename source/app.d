import std;
import std.stdio;
import std.string;

import bindbc.opengl;
import bindbc.glfw;

class ShaderProgram {
  GLint id;
  GLuint[string] shaders;

  this(string vertexShaderPath, string fragmentShaderPath) {
    File vertexShaderFile = File(vertexShaderPath);
    File fragmentShaderFile = File(fragmentShaderPath);

    string vertexShaderFileContent = "";
    string fragmentShaderFileContent = "";

    while (!vertexShaderFile.eof()) {
      vertexShaderFileContent ~= vertexShaderFile.readln();
    }

    while (!fragmentShaderFile.eof()) {
      fragmentShaderFileContent ~= fragmentShaderFile.readln();
    }

    vertexShaderFile.close();
    fragmentShaderFile.close();

    auto vertexShaderSrc = toStringz(vertexShaderFileContent);
    auto fragmentShaderSrc = toStringz(fragmentShaderFileContent);

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

    this.id = glCreateProgram();

    glAttachShader(this.id, this.shaders["vertex"]);
    glAttachShader(this.id, this.shaders["fragment"]);

    glBindFragDataLocationIndexed(this.id, 0, 1, "FragColor");

    glLinkProgram(this.id);
    glUseProgram(this.id);
  }

  ~this() {
    writeln("Deleting program: ", this.id);
    glDeleteProgram(this.id);

    foreach(shaderName, shaderId; this.shaders) {
      writeln("Deleting shader: ", shaderName);
      glDeleteShader(shaderId);
    }
  }

  void use() {
    glUseProgram(id);
  }

  void setFloat(string uniformName, float[] floats) {
    int uniformNameId = glGetUniformLocation(this.id, uniformName.toStringz);

    if (uniformNameId > -1) {
      switch (floats.length) {
        case 1:
          glUniform1f(uniformNameId, floats[0]);
          break;
        case 2:
          glUniform2f(uniformNameId, floats[0], floats[1]);
          break;
        case 3:
          glUniform3f(uniformNameId, floats[0], floats[1], floats[2]);
          break;
        case 4:
          glUniform4f(uniformNameId, floats[0], floats[1], floats[2], floats[3]);
          break;
        default:
          break;
      }
    }
  }
}

class Canvas {
  GLFWwindow* window;
  int width, height, NUM_TRIS;
  string title;
  GLuint[] vaos, vbos, elements;
  GLuint[string] shaders;
  ShaderProgram shaderProgram;

  float[] vertices;

  this(int width, int height, string title) {
    this.width = width;
    this.height = height;
    this.title = title;
    this.NUM_TRIS = 1;


    writefln("Creating canvas with W: %d H: %d Title: %s", width, height, title);

    initGL();

    this.shaderProgram = new ShaderProgram("source/shaders/vertex.glsl", "source/shaders/fragment.glsl");
  }

  ~this() {
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

    float timeValue = glfwGetTime();
    float greenValue = (sin(timeValue * 2) / 2.0f) + 0.5f;

    this.shaderProgram.use();
    this.shaderProgram.setFloat("ourColor", [0.0f, greenValue, 0.0f, 1.0f]);


    //glDrawArrays(GL_TRIANGLES, 0, this.NUM_TRIS * 3);
    glDrawElements(GL_TRIANGLES, 3 * this.NUM_TRIS, GL_UNSIGNED_INT, cast(void*) 0);
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
    this.vertices ~= [-0.5f, -0.5f, 1.0f, 1.0f, 1.0f]; // SW
    this.vertices ~= [-0.5f,  0.5f, 1.0f, 1.0f, 1.0f]; // NW
    this.vertices ~= [ 0.5f,  0.5f, 0.0f, 0.0f, 0.0f]; // NE
    this.vertices ~= [ 0.5f, -0.5f, 0.0f, 0.0f, 0.0f]; // SE

    this.elements ~= [0, 1, 3];
    this.elements ~= [1, 2, 3];

    this.NUM_TRIS = 2;
  }


  void initGraphics() {
    GLuint vao, vbo, ebo;

    // VAO
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // VBO
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    // EBO
    glGenBuffers(1, &ebo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);

    this.vaos ~= vao;
    this.vbos ~= vbo;
    this.vbos ~= ebo;

    this.generateGeomtry();

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, this.elements.length * float.sizeof, this.elements.ptr, GL_STATIC_DRAW);

    // Enable Position attribute
    GLint posAttrib = glGetAttribLocation(this.shaderProgram.id, "position");
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
        5 * float.sizeof,
        cast(void*) 0);
    glEnableVertexAttribArray(posAttrib);

    GLint colAttrib = glGetAttribLocation(this.shaderProgram.id, "color");
    glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
        5 * float.sizeof,
        cast(void*) (2 * float.sizeof));
    glEnableVertexAttribArray(colAttrib);

    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);
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
