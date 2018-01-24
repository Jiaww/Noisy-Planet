#version 300 es

uniform mat4 u_Model; 
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj; 

uniform vec4 u_OceanColor;
uniform vec4 u_CoastColor;
uniform vec4 u_FoliageColor;
uniform vec4 u_MountainColor;
uniform vec4 u_SnowColor;
uniform vec4 u_TropicalColor;

uniform vec4 u_HeightsInfo; // x : Ocean, y : Shore, z : Snow, w : Polar, 
uniform vec2 u_TerrainInfo;

uniform float u_Time;
uniform float u_Octave;
uniform float u_Trig;
uniform float u_FloatSpeed;

uniform vec3 u_CamPos;

// Sun Setting
uniform vec3 u_SunPos;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

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

float fbm(vec3 x, float resolution)
{
    x = x * resolution;
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
out float fs_Shininess;

void main()
{
    fs_Col = vs_Col;
    fs_TerrainType = 0.0;
    fs_Shininess = 1.0;
    vec4 vertexPos = vs_Pos;
    fs_Pos = vs_Pos;
    float oceneHeight = length(vertexPos.xyz) + u_HeightsInfo.x;
    vec3 localNormal = normalize(vertexPos.xyz);

    // noise
    vec3 floating;
    if (u_Trig == 1.0){
        floating = vec3(sin(u_Time * 1.0 * u_FloatSpeed));
    } 
    else{
        floating = vec3(0.0);
    }    

// Follow the instructions of 'Implicit Procedural Planet Generation - Report' 4.2, 4.3, 4.5
    float resolution = 4.0;
    float noiseResult = fbm(vertexPos.xyz+floating, resolution) * 2.0;  
    // Tropical
    float heightLevel = clamp(pow(abs(vertexPos.y*5.0), 3.0), 0.005, 1.0);
    noiseResult = pow(noiseResult,  u_TerrainInfo.x * heightLevel);
    vertexPos.xyz += localNormal * noiseResult;
    float height = length(vertexPos.xyz);

    //Generate different colors for different depth of the water
    float gap = clamp((1.0 - (oceneHeight - height)), 0.0, 1.0);
    float gap3 = pow(gap, 3.0);
 
    vec4 oceneColor = u_OceanColor  * gap3;

    float oceneShininess = 0.85;
    float iceShininess = 0.85;
    float foliageShininess = 0.2;
    float tropicalShininess = 0.35;
    float snowShininess = 0.2;
    float coastShininess = 0.1;

    //ocean
    if(height < oceneHeight)
    {
        vertexPos.xyz = oceneHeight * localNormal;

        fs_Pos = vertexPos;
        fs_Shininess = oceneShininess;
        fs_Col = oceneColor;
    }

    //shore
    else
    {
        fs_TerrainType = 1.0;
        float alpha = 0.0;
        float appliedAttitude;
        if(abs(vertexPos.y) > u_HeightsInfo.w)
            alpha = clamp((abs(vertexPos.y) - u_HeightsInfo.w)/(2.0 - u_HeightsInfo.w), 0.0, 1.0);

        //Tropical
        vec4 mixFoliageColor = mix(u_TropicalColor, u_FoliageColor, heightLevel);
        float mixFoliageShininess = mix(tropicalShininess, foliageShininess, heightLevel);

        vec4 terrainColor = mix(mixFoliageColor, u_SnowColor, alpha);
        float terrainShininess = mix(mixFoliageShininess, iceShininess, alpha);
        vertexPos.xyz = height * localNormal;

        float coastLine = oceneHeight + u_HeightsInfo.y * pow(heightLevel, 2.5);
        float snowLine = 1.0 + u_HeightsInfo.z;

        if(height < coastLine)
        {
            fs_Col = u_CoastColor;
            fs_Shininess = coastShininess;
        }
        else if(height >= snowLine)
        {
            fs_TerrainType = 1.0;
            float alpha = clamp( (height - snowLine ) / 0.03, 0.0, 1.0);
            fs_Col = mix(terrainColor, u_SnowColor, alpha);
            fs_Shininess = mix(terrainShininess, snowShininess, alpha);
        }        
        else
        {
            float alpha = clamp( (height - coastLine ) / u_HeightsInfo.y, 0.0, 1.0);
            fs_Col = mix(u_CoastColor, terrainColor, alpha);
            fs_Shininess = mix(coastShininess, terrainShininess, alpha);
        }

    }

    vec4 modelposition = u_Model * vertexPos;
    vec3 sunDirection = normalize(u_SunPos.xyz);
    mat3 invModel = mat3(inverse(u_Model));
    sunDirection = invModel * sunDirection;
    fs_LightVec = vec4(normalize(sunDirection), 1.0);
    vec3 viewVec = u_CamPos.xyz - modelposition.xyz;
    fs_ViewVec = vec4( invModel * normalize(viewVec), length(u_CamPos.xyz));

    gl_Position = u_ViewProj * modelposition;

}
