#version 300 es

//#extension GL_OES_standard_derivatives : enable
precision highp float;
#define PI 3.1415926535897932384626422832795028841971
#define TwoPi 6.28318530717958647692
#define InvPi 0.31830988618379067154
#define Inv2Pi 0.15915494309189533577
#define Inv4Pi 0.07957747154594766788

//uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_SunPosition;
uniform vec4 u_OceanColor;
uniform vec4 u_CoastColor;
uniform vec4 u_FoliageColor;
uniform vec4 u_MountainColor;
uniform vec4 u_SnowColor;
uniform vec4 u_HeightsInfo;
uniform vec3 u_CamPos;
uniform float u_Time;
uniform vec2 u_TerrainInfo;
uniform float u_Octave;


// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_LightVec;
in float fs_Alpha;

out vec4 out_Col; // This is the final output color that you will see on your

                  // screen for the pixel that is currently being processed.


void main()
{
    // Material base color (before shading)
    vec4 vertexPos = fs_Pos;
    vec3 normalVec = normalize(cross( dFdx(vertexPos.xyz), dFdy(vertexPos.xyz))); 
    vec4 diffuseColor = vec4(0.98, 0.98, 0.98, 1.0);

    float diffuseTerm = clamp(dot(normalVec, normalize(fs_LightVec.xyz)), 0.0, 0.7);
    //Lambert

    float ambientTerm = 0.1;
    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier

                                                            //to simulate ambient lighting. This ensures that faces that are not

                                                            //lit by our point light are not completely black.

    out_Col = vec4(diffuseColor.xyz * lightIntensity, fs_Alpha);
}
