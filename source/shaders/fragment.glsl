#version 330 core

in vec3 Color;

layout (location = 0) out vec4 FragColor;

uniform vec4 ourColor;

void main() {
  // All white
  //FragColor = vec4(0.7, 0.5, 1.0, 1.0);
  //FragColor = vec4(Color, 1.0);
  FragColor = ourColor;
}
