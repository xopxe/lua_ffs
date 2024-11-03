#version 330 core
out vec4 FragColor;

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;    
    float shininess;
}; 

struct Light {
    //vec3 position;
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform sampler2D texture1;

in vec3 FragPos;  
in vec3 Normal;  
in vec2 TexCoord;
  
uniform vec3 viewPos;
uniform Material material;
uniform Light light;

void main()
{
    // ambient
    vec3 ambient = light.ambient * material.ambient;
    
    // diffuse 
    vec3 norm = normalize(Normal);
    //vec3 lightDir = normalize(light.position - FragPos);
    vec3 lightDir = normalize(light.direction);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * (diff * material.diffuse);
    
    // specular
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    float fresnel = 1.0; //pow( 1-dot(viewDir, norm), 5);
    vec3 specular = light.specular * (spec * material.specular)*fresnel;  
        
    vec3 result = specular + (ambient+diffuse)*vec3(texture(texture1, TexCoord));
    FragColor = vec4(result, 1.0);
} 



/*
#version 330 core
out vec4 FragColor;

in vec2 TexCoord;
in vec3 Normal;  

// texture sampler
uniform sampler2D texture1;
uniform vec3 lightColor = vec3(1.0,1.0,1.0);
uniform vec3 lightDir = vec3(0.0,0.0,1.0);
uniform float ambientStrength = 0.1;
    
void main()
{
    // ambient
    vec3 ambient = ambientStrength * lightColor;
    
    // diffuse 
    vec3 norm = normalize(Normal);
    
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;
  
    vec3 result = (ambient + diffuse) * vec3(texture(texture1, TexCoord));
    FragColor = vec4(result, 1.0);
}
*/
