#version 130

in vec3 Color;
in vec2 TexCoord;

out vec4 FragColor;

uniform vec4 ourColor;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform float mixFactor;

void main() {
  // All white
  //FragColor = vec4(0.7, 0.5, 1.0, 1.0);
  //FragColor = vec4(Color, 1.0);
  //FragColor = ourColor;
  FragColor = mix(
      texture(tex0, TexCoord),
      texture(tex1, TexCoord),
      mixFactor
  );
}
