#version 430 core

out vec4 o_fragout;
in DATA 
{

	vec3 pos;
	vec3 rgb;
   	vec2 uv;
   	vec3 normal;

   	mat4 projection;
   	mat4 view;
   	mat4 model;

   	vec3 fpos;

} i_data;

uniform vec3 u_camerapos;

struct material
{
	sampler2D diffuse;
	sampler2D specular;
	sampler2D normal;
	float shininess;
};

uniform vec3 u_globalambient;

// point light
struct pointlight 
{
	vec3 position;
  
    vec3 diffuse;
    vec3 specular;

	float constant;
    float quadratic;
    float linear;

	float intensity;
};

// spotlight
struct spotlight 
{
	vec3 position;
  
    vec3 diffuse;
    vec3 specular;

	float constant;
    float quadratic;
    float linear;

	vec3 angle;
	float innercone;
	float outercone;
	float intensity;
};

// sunlight
struct sunlight 
{
	vec3 diffuse;
    vec3 specular;

	vec3 angle;
};

// lighting type functions
vec3 point(pointlight plight, material mat, vec3 camerapos, vec3 fnormal, vec3 fpos, vec2 uv)
{
	vec3 lightvec = plight.position - fpos;


    // ambient light prevents the object from being completely dark when in shadow
	vec3 ambient = u_globalambient * vec3(texture(mat.diffuse, uv));


	// normalize the given vertex normal data
	// normalize forces the data to be between a value of 0 and 1
	vec3 normal = normalize(fnormal);

	// normalize the different between the light position and the current object position
	vec3 lightdir = normalize(lightvec);

	// calculate the diffuse - the dot product between the light direction and the normal
	// dot product defines how much the normal faces the direction of the light
	// if the dot product is greater than 0, then the light is on the object
	float diff = max(dot(normal, lightdir), 0.0f);

	vec3 diffuse = plight.diffuse * diff * vec3(texture(mat.diffuse, uv));

	// normalize the difference betweens the camera position and the current object position
	vec3 viewdir = normalize(camerapos - fpos);

	// find the direction of the reflection
	// reflect() requires the direction of the light and the normal of the object

	// first "flip" the light direction by negating it
	// this is because the light direction is in the opposite direction of the normal
	// doing this makes the light point towards the normal

	vec3 reflectiondir = reflect(-lightdir, normal);

	// specular = the dot product to the power of shininess
	float spec = 
	  pow
	( max // return the dot product if it is greater than 0
	( dot(viewdir, reflectiondir),						  0.0f), mat.shininess // <-- pow(dotproduct, shininess)
	  // dot product of the view & reflection direction   ^ max(dotproduct, 0.0f)
	);

	// multiply the color of the light with the specular data
	vec3 specular = plight.specular * (spec * vec3(texture(mat.specular, uv)));
	
	// do intensity
	diffuse  *= plight.intensity;
	specular *= plight.intensity;

	// do attenuation
	float dist = length(lightvec); // get length of light position & object position
	float attenuation = 1.0 / (plight.constant + plight.linear * dist + plight.quadratic * (dist * dist)); 
	diffuse  *= attenuation;
	specular *= attenuation;


	// add everything together
	vec3 pointlight = ambient + diffuse + specular;

	return pointlight;
}

vec3 spot(spotlight splight, material mat, vec3 camerapos, vec3 fnormal, vec3 fpos, vec2 uv)
{
	// reduced comments as it uses most the same concepts

	// diffuse
	vec3 lightvec = splight.position - fpos;

	vec3 ambient = u_globalambient * vec3(texture(mat.diffuse, uv));

	vec3 normal = normalize(fnormal);
	vec3 lightdir = normalize(lightvec);
	float diff = max(dot(normal, lightdir), 0.0f);
	vec3 diffuse = splight.diffuse * diff * vec3(texture(mat.diffuse, uv));

	// specular
	vec3 viewdir = normalize(camerapos - fpos);
	vec3 reflectiondir = reflect(-lightdir, normal);
	float spec = pow(max(dot(viewdir, reflectiondir), 0.0f), mat.shininess);
	vec3 specular = splight.specular * (spec * vec3(texture(mat.specular, uv)));

	// spotlight specific calculations
	float theta = dot(lightdir, normalize(-splight.angle));
	float epsilon = splight.innercone - splight.outercone;
	float intensity = clamp((theta - splight.outercone) / epsilon, 0.0, splight.intensity); 
	diffuse  *= intensity;
	specular *= intensity;

	// attenuation
	float dist = length(lightvec);
	float attenuation = 1.0 / (splight.constant + splight.linear * dist + splight.quadratic * (dist * dist)); 
	diffuse  *= attenuation;
	specular *= attenuation;  

	// add everything together
	vec3 spotlight = ambient + diffuse + specular;

	return spotlight;
}

vec3 sun(sunlight slight, material mat, vec3 camerapos, vec3 fnormal, vec3 fpos, vec2 uv)
{
	// diffuse
	vec3 ambient = u_globalambient * vec3(texture(mat.diffuse, uv));

	vec3 normal = normalize(fnormal);
	vec3 lightdir = normalize(-slight.angle);
	float diff = max(dot(normal, lightdir), 0.0f);
	vec3 diffuse = slight.diffuse * diff * vec3(texture(mat.diffuse, uv));

	// specular
	vec3 viewdir = normalize(camerapos - fpos);
	vec3 reflectiondir = reflect(-lightdir, normal);
	float spec = pow(max(dot(viewdir, reflectiondir), 0.0f), mat.shininess);
	vec3 specular = slight.specular * (spec * vec3(texture(mat.specular, uv)));

	// add everything together
	vec3 sunlight = ambient + diffuse + specular;

	return sunlight;
}

#define MAXLIGHTS 53

// uniforms
uniform material u_material;
uniform pointlight u_pointlight[MAXLIGHTS];
uniform spotlight u_spotlight[MAXLIGHTS];
uniform sunlight u_sunlight[1];

uniform int pointlightnum = 0;
uniform int spotlightnum = 0;
uniform int sunlightnum = 0;


void main()
{	
	// output
    vec3 outp;

    for(int i = 0; i < pointlightnum; i++)
	{
		outp += point(u_pointlight[i], u_material, u_camerapos, i_data.normal, i_data.fpos, i_data.uv);
	}

	for(int i = 0; i < spotlightnum; i++) 
	{
		outp += spot(u_spotlight[i], u_material, u_camerapos, i_data.normal, i_data.fpos, i_data.uv);
	}

	for(int i = 0; i < sunlightnum; i++)
	{
        outp += sun(u_sunlight[i], u_material, u_camerapos, i_data.normal, i_data.fpos, i_data.uv);
	}

	o_fragout = vec4(outp, 1.0f);

}