#version 300 es

#define SUMMED

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2; // The color 2 with which to render this instance of geometry.
// uniform vec4 u_Specular_Color;
uniform float u_Time; // The color with which to render this instance of geometry.
uniform float u_Octave;
uniform float u_Trig;
uniform float u_FloatSpeed;
uniform vec3 u_CamPos;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_Noise;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


void main()
{
    // Material base color (before shading)
    vec4 diffuseColor;

    // Calculate the diffuse term for Lambert shading
    vec3 lightDir = vec3(lightPos) - vec3(fs_Pos);
    lightDir = normalize(lightDir);
    
    vec3 normal = normalize(vec3(fs_Nor));
    float diffuseTerm = dot(normal, normalize(lightDir));
    float specularTerm = 0.0;
    if (diffuseTerm > 0.0){
        vec3 viewDir = u_CamPos - vec3(fs_Pos);
        viewDir = normalize(viewDir);
        vec3 halfDir = normalize(lightDir + viewDir);
        float specAngle = max(dot(halfDir, normal), 0.0);
        specularTerm = 0.5 * pow(specAngle, 16.0);

    }
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    //out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    float interp = clamp(fs_Noise / 0.05, 0.0, 1.0);
    diffuseColor = u_Color * interp + u_Color2 * (1.0 - interp);
    out_Col = vec4(diffuseColor.rgb * lightIntensity + vec3(0.9, 0.9, 0.9) * specularTerm, diffuseColor.a);
    //out_Col = vec4(vec3(fs_Noise), 1.0);
}
