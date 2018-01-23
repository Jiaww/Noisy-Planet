#version 300 es

uniform mat4 u_Model; 
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj; 

uniform vec4 u_SunPosition;
uniform vec4 u_OceanColor;
uniform vec4 u_CoastColor;
uniform vec4 u_FoliageColor;
uniform vec4 u_MountainColor;
uniform vec4 u_SnowColor;

uniform vec4 u_HeightsInfo; // x : Ocean, y : Shore, z : Snow, w : Polar, 
uniform vec2 u_TerrainInfo;

uniform float u_Time;
uniform float u_Octave;
uniform float u_Trig;
uniform float u_FloatSpeed;

uniform vec3 u_CamPos;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

const vec4 lightPos = vec4(5, 5, 3, 1);

// rotation matrix for fbm octaves
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

// Return a random direction in a circle
vec3 random3( vec3 p ) {
    return normalize(2.0 * fract(sin(vec3(dot(p,vec3(78.233, 127.1, 311.7)),dot(p,vec3(138.11,269.5,183.3)),dot(p,vec3(12.388, 165.24, 278.322))))*43758.5453) - 1.0);
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
    vec3 gradient = random3(gridPoint);
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

float fbm(vec3 x)
{
  float v = 0.0;
  float a = 0.5;
  vec3 shift = vec3(100.0);
  for (int i = 0; i < int(u_Octave); ++i)
  {
   v += a * PerlinNoise(x);
   x = x * 2.0 + shift;
   a *= 0.5;
  }  
  return v;
}


out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_ViewVec;
out float fs_TerrainType;
out float fs_Roughness;

float OceanNoise(vec3 vertexPos, float oceneHeight, float noiseResult, float blendFactor)
{
    float relativeWaterDepth = min(1.0, (oceneHeight - noiseResult) * 15.0);
    float oceanTime = u_Time * 100.0;
    float shallowWaveRefraction = 4.0;
    float waveMagnitude = 0.0002;
    float waveLength = mix(0.007, 0.0064, blendFactor);
    float shallowWavePhase = (vertexPos.y - noiseResult * shallowWaveRefraction) * (1.0 / waveLength);
    float deepWavePhase    = (atan(vertexPos.z, vertexPos.x) + PerlinNoise(vertexPos.xyz * 15.0) * 0.075) * (1.5 / waveLength);
    return (cos(shallowWavePhase + oceanTime  * 1.5) * sqrt(1.0 - relativeWaterDepth) + cos(deepWavePhase + oceanTime  * 2.0) * 2.5 * (1.0 - abs(vertexPos.y)) * (relativeWaterDepth * relativeWaterDepth)) * waveMagnitude;
}

void main()
{
    fs_Col = vs_Col;
    fs_TerrainType = 0.0;
    fs_Roughness = 0.0;
    vec4 vertexPos = vs_Pos;
    fs_Pos = vs_Pos;
    float oceneHeight = length(vertexPos.xyz) + u_HeightsInfo.x;
    vec3 localNormal = normalize(vertexPos.xyz);

    // noise
    vec3 floating;
    if (u_Trig == 1.0){
        floating = vec3(sin(u_Time * 2.0 * u_FloatSpeed));
    } 
    else{
        floating = vec3(0.0);
    }    

    float u_resolution = 4.0;
    float noiseResult = fbm((vertexPos.xyz+floating)*u_resolution) * 2.0;  
    noiseResult = pow(noiseResult,  u_TerrainInfo.x);
    vertexPos.xyz += localNormal * noiseResult;
    float height = length(vertexPos.xyz);

    float gap = clamp((1.0 - (oceneHeight - height)), 0.0, 1.0);
    float gap5 = pow(gap, 3.0);
 
    vec4 ocenColor = u_OceanColor  * gap5;
    float oceneRougness = 0.15;
    float iceRougness = 0.15;
    float foliageRougness = 0.8;
    float snowRougness = 0.8;
    float shoreRougness = 0.9;

    //ocean
    if(height < oceneHeight)
    {
        //float gap10 = pow(pow(gap, 100.0), 0.8);

        //float wave = OceanNoise(vertexPos.xyz, oceneHeight, noiseResult, gap10);  
        //vertexPos.xyz = (oceneHeight + wave) * localNormal;
        vertexPos.xyz = oceneHeight * localNormal;

        fs_Pos = vertexPos;
        fs_Roughness = oceneRougness;
        fs_Col = ocenColor;
    }

    //shore
    else
    {
        fs_TerrainType = 1.0;
        float appliedAttitude;
        if(abs(vertexPos.y) > u_HeightsInfo.w)
            appliedAttitude = clamp((abs(vertexPos.y) - u_HeightsInfo.w) * 3.0, 0.0, 1.0);
        else        
           appliedAttitude = 0.0;

        vec4 terrainColor = mix(u_FoliageColor, u_SnowColor, appliedAttitude);
        float terrainRoughness = mix(foliageRougness, iceRougness, appliedAttitude);
        vertexPos.xyz = height * localNormal;

        float oceneLine = oceneHeight + u_HeightsInfo.y;
        float snowLine = 1.0 + u_HeightsInfo.z;

        if(height < oceneLine)
        {
            fs_Col = u_CoastColor;
            fs_Roughness = shoreRougness;
        }
        else if(height >= snowLine)
        {
            fs_TerrainType = 1.0;
            float alpha = clamp( (height - snowLine ) / 0.03, 0.0, 1.0);
            fs_Col = mix(terrainColor, u_SnowColor, alpha);
            fs_Roughness = mix(terrainRoughness, snowRougness, alpha);
        }        
        else
        {
            float alpha = clamp( (height - oceneLine ) / u_HeightsInfo.y, 0.0, 1.0);
            fs_Col = mix(u_CoastColor, terrainColor, alpha);
            fs_Roughness = mix(shoreRougness, terrainRoughness, alpha);
        }

    }

    vec4 modelposition = u_Model * vertexPos;
    vec3 sunDirection = normalize(lightPos.xyz);
    mat3 invModel = mat3(inverse(u_Model));
    sunDirection = invModel * sunDirection;
    fs_LightVec = vec4(normalize(sunDirection), 1.0);
    vec3 viewVec = u_CamPos.xyz - modelposition.xyz;
    fs_ViewVec = vec4( invModel * normalize(viewVec), length(u_CamPos.xyz));

    gl_Position = u_ViewProj * modelposition;

}
