#version 300 es

//#extension GL_OES_standard_derivatives : enable
precision highp float;
#define PI 3.1415926535897932384626422832795028841971

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

uniform vec4 u_SunLight; // r, g, b, intensity

uniform sampler2D u_EnvMap;

// Return a random direction in a circle
vec3 random3( vec3 p, float seed ) {
    return normalize(2.0 * fract(sin(vec3(
        dot(p,vec3(78.233, 127.1, 311.7)+vec3(23.146, 12.37, 221.574)*seed),
        dot(p,vec3(138.11,269.5,183.3)+vec3(35.26, 6.3117, 41.74)*seed),
        dot(p,vec3(12.388, 165.24, 278.322)+vec3(29.111, 188.327, 64.574)*seed)
        ))*43758.5453) - 1.0);
}

float surflet3D(vec3 P, vec3 gridPoint)
{
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float distZ = abs(P.z - gridPoint.z);
    float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
    float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);
    float tZ = 1.0 - 6.0 * pow(distZ, 5.0) + 15.0 * pow(distZ, 4.0) - 10.0 * pow(distZ, 3.0);

    // Get the random vector for the grid point
    vec3 gradient = random3(gridPoint, u_TerrainInfo.y);
    // Get the vector from the grid point to P
    vec3 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY * tZ;
}

float PerlinNoise(vec3 uvw)
{
    // Tile the space
    vec3 uvwXLYLZL = floor(uvw);
    vec3 uvwXLYHZL = uvwXLYLZL + vec3(0,1,0);
    vec3 uvwXLYHZH = uvwXLYLZL + vec3(0,1,1);
    vec3 uvwXLYLZH = uvwXLYLZL + vec3(0,0,1);
    vec3 uvwXHYLZL = uvwXLYLZL + vec3(1,0,0);
    vec3 uvwXHYHZL = uvwXLYLZL + vec3(1,1,0);
    vec3 uvwXHYLZH = uvwXLYLZL + vec3(1,0,1);
    vec3 uvwXHYHZH = uvwXLYLZL + vec3(1,1,1);

    return ((surflet3D(uvw, uvwXLYLZL) + surflet3D(uvw, uvwXLYHZL) + surflet3D(uvw, uvwXLYHZH) + surflet3D(uvw, uvwXLYLZH) + 
    surflet3D(uvw, uvwXHYLZL) + surflet3D(uvw, uvwXHYHZL) + surflet3D(uvw, uvwXHYLZH) + surflet3D(uvw, uvwXHYHZH))+1.0)/2.0;
}

#define Epsilon 0.0001

float fbm(vec3 x, float resolution, int LOD)
{
    x =  x * resolution;
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0);
    for (int i = 0; i < LOD; ++i)
    {
    v += a * PerlinNoise(x);
    x = x * 2.0 + shift;
    a *= 0.5;
    }  
    return v;
}

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_ViewVec;
in float fs_TerrainType;
in float fs_Shininess;

out vec4 out_Col; // This is the final output color that you will see on your

                  // screen for the pixel that is currently being processed.

// All of the computation happen in local space
void main()
{
    // Material base color (before shading)
    vec3 normalVec = normalize(fs_Nor.xyz);
    vec4 diffuseColor = fs_Col;

    float Shininess = fs_Shininess;

    vec3 specularTerm = vec3(0.0);
    vec3 SpecularColor = vec3(1.0, 1.0, 1.0);

    vec3 localNormal = normalize(fs_Pos.xyz);

    //Terrain-atmosphere Color Interpolation

// The 'detail normal' method is learned from Byumjin Kim, this is the only way to deal with current situation,
// Because the vertex position is changed in vertex shader, but the normal still pass from cpu still unchanged, thus
// we have to recompute the normals. 

// Implicit Procedural Planet Generation - Report 4.4.2 Level of Detail
    //terrain
    if(fs_TerrainType > 0.0)
    {
        float resolution = 4.0;
        int LOD = int(10.0 * (1.0 - smoothstep(0.0, u_Octave, log(length(u_CamPos.xyz)))));
        float noise = fbm(fs_Pos.xyz, resolution, LOD) * 2.0;
        noise = pow(noise,  u_TerrainInfo.x);
        vec4 vertexPos = fs_Pos;
        vertexPos.xyz += localNormal * noise;
       //detail normal
        normalVec = normalize(cross( dFdx(vertexPos.xyz), dFdy(vertexPos.xyz)));         
        float NolN= clamp(dot(localNormal, normalVec), 0.0, 1.0);
        diffuseColor = mix(u_MountainColor, diffuseColor, NolN*NolN*NolN);       
    }
    else
    {
        vec4 vertexPos = fs_Pos;
         //detail normal
        normalVec = normalize(cross( dFdx(vertexPos.xyz), dFdy(vertexPos.xyz))); 
        // Near Polar
        float Interp = clamp((abs(fs_Pos.y) - u_HeightsInfo.w)/(2.0 - u_HeightsInfo.w), 0.0, 1.0);
        diffuseColor = mix(diffuseColor, u_SnowColor, pow(Interp, 2.5));
    }
    float diffuseTerm = clamp(dot(normalVec, normalize(fs_LightVec.xyz)), 0.0, 1.0);
    //Lambert
    // if(u_SunPosition.w == 0.0)
    // {
    // }
    // //Blinn_Phong
    // else if(u_SunPosition.w == 1.0)
    // {
    vec3 halfVec = fs_ViewVec.xyz + fs_LightVec.xyz;

    halfVec = normalize(halfVec);        
    //Intensity of the specular light
    float NoH = clamp(dot( normalVec, halfVec ), 0.0, 1.0);
    specularTerm = vec3(pow(clamp(NoH, 0.0, 1.0), pow(200.0, Shininess))) * SpecularColor * Shininess;

    // }

    float ambientTerm = 0.0;
    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier

                                                            //to simulate ambient lighting. This ensures that faces that are not

                                                            //lit by our point light are not completely black.


    vec3 reflecVec = reflect(-fs_ViewVec.xyz, normalVec);
    //Envmap
    vec2 st;
    st.x = (atan(reflecVec.z, reflecVec.x) + PI) / (2.0*PI);
    st.y = acos(reflecVec.y) / PI;
    vec4 envColor = texture(u_EnvMap, st) * Shininess;

    // vec4 envColor = texture(u_EnvMap, vN) * Shininess * 0.5;
    // Compute final shaded color
    vec4 planetColor = vec4( ( diffuseColor.rgb + specularTerm + envColor.xyz) * lightIntensity, 1.0);
    out_Col = vec4(planetColor.xyz * u_SunLight.rgb * u_SunLight.a, 1.0);
}
