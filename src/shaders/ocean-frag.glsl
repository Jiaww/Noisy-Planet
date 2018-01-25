#version 300 es

//#extension GL_OES_standard_derivatives : enable
precision highp float;
#define PI 3.1415926535897932384626422832795028841971

//uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_SunPosition;
uniform vec4 u_OceanColor;
uniform vec4 u_SnowColor;
uniform vec4 u_HeightsInfo;
uniform vec3 u_CamPos;
uniform float u_Time;
uniform vec2 u_TerrainInfo;
uniform float u_Shader;

uniform vec4 u_SunLight; // r, g, b, intensity

uniform sampler2D u_EnvMap;
uniform vec2 u_Trig;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_ViewVec;

out vec4 out_Col; // This is the final output color that you will see on your

                  // screen for the pixel that is currently being processed.

// All of the computation happen in local space
void main()
{
    // Material base color (before shading)
    vec3 normalVec = normalize(fs_Pos.xyz);
    vec4 diffuseColor = fs_Col;

    float Shininess = 0.85;
    vec3 specularTerm = vec3(0.0);
    vec3 SpecularColor = vec3(1.0, 1.0, 1.0);

    // Near Polar
    float Interp = clamp((abs(fs_Pos.y) - (u_HeightsInfo.w-1.0))/(2.0 - u_HeightsInfo.w), 0.0, 1.0);
    diffuseColor = mix(diffuseColor, u_SnowColor, pow(Interp, 2.5));

    float diffuseTerm = clamp(dot(normalVec, normalize(fs_LightVec.xyz)), 0.0, 1.0);
    //Lambert

    //Blinn_Phong
    if(u_Shader == 1.0)
    {
        vec3 halfVec = fs_ViewVec.xyz + fs_LightVec.xyz;
        halfVec = normalize(halfVec);        
        //Intensity of the specular light
        float NoH = clamp(dot( normalVec, halfVec ), 0.0, 1.0);
        specularTerm = vec3(pow(clamp(NoH, 0.0, 1.0), pow(200.0, Shininess))) * SpecularColor * Shininess;
    }

    float ambientTerm = 0.0;
    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier

                                                            //to simulate ambient lighting. This ensures that faces that are not

                                                            //lit by our point light are not completely black.

    vec4 envColor = vec4(0.0);
    if (u_Trig.y == 1.0){
        vec3 reflecVec = reflect(-fs_ViewVec.xyz, normalVec);
        //Envmap
        vec2 st;
        st.x = (atan(reflecVec.z, reflecVec.x) + PI) / (2.0*PI);
        st.y = acos(reflecVec.y) / PI;
        envColor = texture(u_EnvMap, st) * Shininess;
    }

    // vec4 envColor = texture(u_EnvMap, vN) * Shininess * 0.5;
    // Compute final shaded color
    vec4 planetColor = vec4( ( diffuseColor.rgb + specularTerm + envColor.xyz) * lightIntensity, 1.0);
    out_Col = vec4(planetColor.xyz * u_SunLight.rgb * u_SunLight.a, 1.0);
}
