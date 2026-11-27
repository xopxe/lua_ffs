#version 330 core

// must behave like fsim/surface.lua:M.sine_wave
#define M_PI 3.1415926535897932384626433832795
#define g_accel 9.8

layout (location = 0) in vec3 aPos;
//layout (location = 1) in vec3 aNormal;

out vec3 FragPos;
out vec3 Normal;

// as many waves as the surface has, up to MAX_WAVES (keep in sync with the .lua)
#define MAX_WAVES 16
uniform int n_waves = 0;
uniform vec4 waves[MAX_WAVES];  // amplitude, length, dirx, diry
uniform float h0 = 0.0;

uniform float x_min = 0.0;
uniform float y_min = 0.0;
uniform float x_step = 0.1;
uniform float y_step = 0.1;

uniform float t = 0.0;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    float T = t+100.0;

    vec3 pos = aPos;  // the mesh is a flat grid at z = 0
    pos.x = x_min + pos.x*x_step;
    pos.y = y_min + pos.y*y_step;
    pos.z += h0;
    
    vec3 normal = vec3(0.0, 0.0, 1.0);

    for (int i=0; i<n_waves; i++) {
      float amplitude = waves[i].x;
      float dirx = waves[i].z;
      float diry = waves[i].w;
      float w = 2/waves[i].y;
      float phi = sqrt( g_accel*M_PI*w );
      float phase = (pos.x*dirx+pos.y*diry)*w + T*phi;

      pos.z += amplitude * sin(phase);

      float dh = w*amplitude*cos(phase);
      normal += vec3( -dirx*dh, -diry*dh, 0.0);
    }


    FragPos = vec3(model * vec4(pos, 1.0));
    Normal = mat3(transpose(inverse(model))) * normalize(normal);
    
    gl_Position = projection * view * vec4(FragPos, 1.0);
}
