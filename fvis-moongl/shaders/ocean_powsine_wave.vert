#version 330 core

// must behave like fsim/surface.lua:M.powsine_wave
#define M_PI 3.1415926535897932384626433832795
#define g_accel 9.8

layout (location = 0) in vec3 aPos;
//layout (location = 1) in vec3 aNormal;

out vec3 FragPos;
out vec3 Normal;

uniform vec4 amplitude;
uniform vec4 length;
uniform vec4 dirx;
uniform vec4 diry;
uniform float K = 3.0;

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

    vec3 pos = aPos;  //aPos.z must be at h0
    pos.x = x_min + pos.x*x_step;
    pos.y = y_min + pos.y*y_step;
    
    vec3 normal = vec3(0.0, 0.0, 1.0);

    for (int i=0; i<4; i++) {
      float w = 2/length[i];
      float phi = sqrt( g_accel*M_PI*w );
      float phase = (pos.x*dirx[i]+pos.y*diry[i])*w + T*phi;
      float sin_phase = sin(phase);
      float cos_phase = sin(phase);

      pos.z += 2*amplitude[i] * (pow( 0.5*(sin_phase+1) , K) - 1.0);

      float dh = K*w*amplitude[i]*pow( 0.5*(sin_phase+1.0) , K-1)*cos_phase;
      normal += vec3( -dirx[i]*dh, -diry[i]*dh, 0.0);
    }


    FragPos = vec3(model * vec4(pos, 1.0));
    Normal = mat3(transpose(inverse(model))) * normalize(normal);
    
    gl_Position = projection * view * vec4(FragPos, 1.0);
}
