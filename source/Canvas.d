import std;
import std.conv;
import std.stdio;
import std.string;

import gl3n.math;
import gl3n.util;
import gl3n.linalg;

import core.time;
import glib.Timeout;

import gdk.GLContext;

import gtk.Widget;
import gtk.GLArea;

import glcore;
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

    const(char)* vertexShaderSrc = vertexShaderFileContent.ptr;
    const(char)* fragmentShaderSrc = fragmentShaderFileContent.ptr;

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

  void setTransform(mat4 transform) {
    auto transformUniformId = glGetUniformLocation(this.id, "transform");
    glUniformMatrix4fv(transformUniformId, 1, GL_FALSE, transform.value_ptr);
  }

  void renderTexture() {
    foreach(i, tex; this.textures) {
      this.setInt("tex" ~ to!string(i), cast(int)i);

      glActiveTexture(tex.unit);
      glBindTexture(GL_TEXTURE_2D, tex.id);
    }
  }
}

class Canvas : GLArea {
  GLuint[] vaos, vbos, elements;
  GLuint[string] shaders;
  ShaderProgram shaderProgram;
  int NUM_TRIS;
  uint renderTickCounter;
  Timeout renderTick;
  float mixFactor;
  mat4 transform, scale, rotation;

  float[] vertices;

  this() {
    setAutoRender(true);

    setSizeRequest(300,300);
    setHexpand(true);
    setVexpand(true);

    addOnRender(&render);
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);

    mixFactor = 0.0f;

    transform = mat4.identity();
    scale = mat4.identity();
    rotation = mat4.identity();

    showAll();

    this.NUM_TRIS = 1;
  }

  void realize(Widget) {
    makeCurrent();
    initGraphics();
  }

  void unrealize(Widget) {
    makeCurrent();

    foreach(vboId; this.vbos) {
      writeln("Deleting VBO: ", vboId);
      glDeleteBuffers(1, &vboId);
    }

    foreach(vaoId; this.vaos) {
      writeln("Deleting VAO: ", vaoId);
      glDeleteVertexArrays(1, &vaoId);
    }
  }

  bool render(GLContext ctx, GLArea a) {
    makeCurrent();

    drawCanvas();

    glFlush();

    return true;
  }

  void setMixFactor(float mixFactor) {
    this.mixFactor = mixFactor;
    this.queueDraw();
  }

  void setScale(float factor) {
    this.scale = mat4.identity().scale(factor, factor, factor);
    this.updateTransform();
  }

  void setRotation(float factor) {
    this.rotation = mat4.identity().rotatex(radians(factor));
    this.updateTransform();
  }

  void updateTransform() {
    this.transform = this.rotation * this.scale;
    this.queueDraw();
  }

  void drawCanvas() {
    // glDrawArrays(GL_TRIANGLES, 0, 6);
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(this.vaos[0]);

    //float sinValue = (sin(cast(float) this.renderTickCounter * 2000) / 2.0f) + 0.5f;

    this.shaderProgram.renderTexture();

    this.shaderProgram.use();
    this.shaderProgram.setFloat("mixFactor", [this.mixFactor]);
    this.shaderProgram.setTransform(this.transform);

    //glDrawArrays(GL_TRIANGLES, 0, this.NUM_TRIS * 3);
    glDrawElements(GL_TRIANGLES, 3 * this.NUM_TRIS, GL_UNSIGNED_INT, cast(void*) 0);
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
    this.shaderProgram = new ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl");

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
}
