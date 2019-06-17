import std;
import std.conv;
import std.stdio;
import std.string;

import bindbc.opengl;
import bindbc.glfw;

import imaged;

struct Texture {
  GLuint id;
  GLuint unit;
}

class ShaderProgram {
  GLint id;
  GLuint[string] shaders;
  Texture[] textures;

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

    GLchar[] infoLog = new GLchar[512];
    int success;

    glGetShaderiv(shaders["vertex"], GL_COMPILE_STATUS, &success);

    if (!success) {
      writeln("VERTEX:COMPILE:ERROR");
      glGetShaderInfoLog(shaders["vertex"], 512, cast(int*)0, infoLog.ptr);
      writeln(infoLog);
    }

    this.shaders["fragment"] = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(shaders["fragment"], 1, &fragmentShaderSrc, null);
    glCompileShader(shaders["fragment"]);

    glGetShaderiv(shaders["fragment"], GL_COMPILE_STATUS, &success);

    if (!success) {
      writeln("FRAGMENT:COMPILE:ERROR");
      glGetShaderInfoLog(shaders["fragment"], 512, cast(int*)0, infoLog.ptr);
      writeln(infoLog);
    }

    this.id = glCreateProgram();


    glAttachShader(this.id, this.shaders["vertex"]);
    glAttachShader(this.id, this.shaders["fragment"]);

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

  void setInt(string uniformName, int value) {
    int uniformNameId = glGetUniformLocation(this.id, uniformName.toStringz);

    if (uniformNameId > -1) {
      glUniform1i(uniformNameId, value);
    }
  }

  void generateTexture(string texturePath, GLuint textureUnit = 0) {
    IMGError error;
    GLuint texId;

    glGenTextures(1, &texId);
    glActiveTexture(GL_TEXTURE0 + textureUnit);
    glBindTexture(GL_TEXTURE_2D, texId);

    Texture newText = {
      id: texId,
      unit: GL_TEXTURE0 + textureUnit
    };

    this.textures ~= newText;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    Image textureImg = load(texturePath, error);

    if (error.code) {
      writeln("Error in reading/parsing texture");
    } else {
      writefln("Generating texture with: W: %d H: %d", textureImg.width, textureImg.height);

      string imageFileExt = texturePath.split(".")[1];

      glTexImage2D(
          GL_TEXTURE_2D,
          0, // mipmap level
          GL_RGB,
          textureImg.width,
          textureImg.height,
          0, // legacy stuff
          imageFileExt == "png" ? GL_RGBA : GL_RGB, // format for texture storage
          GL_UNSIGNED_BYTE, // format of the stored texture data
          textureImg.pixels.ptr
        );

      // Generate mipmap for the current bound texture buffer
      glGenerateMipmap(GL_TEXTURE_2D);
    }
  }

  void renderTexture() {
    foreach(i, tex; this.textures) {
      this.setInt("tex" ~ to!string(i), cast(int)i);

      glActiveTexture(tex.unit);
      glBindTexture(GL_TEXTURE_2D, tex.id);
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

    this.shaderProgram = new ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl");

    initEventHandling();
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

  extern (C) static void onWindowRezize(GLFWwindow *window, int width, int height) nothrow {
    try {
      glViewport(0, 0, width, height);
    } catch (Exception e) {
    }
  }

  extern (C) static void onKeyPress(GLFWwindow *window, int key, int scancode, int action, int mods) nothrow {
    try {
      if (action == GLFW_PRESS) {
        switch (key) {
          case GLFW_KEY_ESCAPE:
          case GLFW_KEY_Q:
            glfwSetWindowShouldClose(window, true);
            break;

          case GLFW_KEY_A:
            writeln("Adding cube: ");
            break;

          case GLFW_KEY_H:
            writeln("Getting help: ");
            break;

          default:
            writeln("Pressed key: ", key, scancode, action);
        }
      }
    } catch (Exception e) {
    }
  }

  void initEventHandling() {
    glfwSetWindowSizeCallback(this.window, &onWindowRezize);
    glfwSetKeyCallback(this.window, &onKeyPress);
  }

  void render() {
    // glDrawArrays(GL_TRIANGLES, 0, 6);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(this.vaos[0]);

    float timeValue = glfwGetTime();
    float sinValue = (sin(timeValue * 2) / 2.0f) + 0.5f;

    this.shaderProgram.renderTexture();

    this.shaderProgram.use();
    this.shaderProgram.setFloat("mixFactor", [sinValue]);

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
    //               [  x      y     r     g     b     s     t  ]
    this.vertices ~= [-0.9f, -0.9f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f]; // SW
    this.vertices ~= [-0.9f,  0.9f, 1.0f, 1.0f, 1.0f, 0.0f, 3.0f]; // NW
    this.vertices ~= [ 0.9f,  0.9f, 0.0f, 0.0f, 0.0f, 2.0f, 3.0f]; // NE
    this.vertices ~= [ 0.9f, -0.9f, 0.0f, 0.0f, 0.0f, 2.0f, 0.0f]; // SE

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

    //this.shaderProgram.generateTexture("assets/container.jpg");
    this.shaderProgram.generateTexture("assets/wall.jpg", 0);
    this.shaderProgram.generateTexture("assets/awesomeface.png", 1);

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, this.elements.length * float.sizeof, this.elements.ptr, GL_STATIC_DRAW);

    // Enable Position attribute
    GLint posAttrib = glGetAttribLocation(this.shaderProgram.id, "position");
    GLint colAttrib = glGetAttribLocation(this.shaderProgram.id, "color");
    GLint texAttrib = glGetAttribLocation(this.shaderProgram.id, "texCoord");

    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
        7 * float.sizeof,
        cast(void*) (0 * float.sizeof));
    glEnableVertexAttribArray(posAttrib);

    glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
        7 * float.sizeof,
        cast(void*) (2 * float.sizeof));
    glEnableVertexAttribArray(colAttrib);

    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE,
        7 * float.sizeof,
        cast(void*) (5 * float.sizeof));
    glEnableVertexAttribArray(texAttrib);

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
