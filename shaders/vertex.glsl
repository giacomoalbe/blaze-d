#version 130

in vec2 position;
in vec3 color;
in vec2 texCoord;

out vec3 Color;
out vec2 TexCoord;

uniform mat4 transform;

void main() {
  Color = color;
  TexCoord = texCoord;
  gl_Position = transform * vec4(position, 0.0, 1.0);
}
