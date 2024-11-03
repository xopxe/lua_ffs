#version 330 core
out vec4 FragColor;

in vec3 FragPos;  
  
uniform vec3 viewPos;
uniform vec3 color = vec3(1.0,1.0,1.0);

void main()
{
    FragColor = vec4(color, 1.0);
} 
