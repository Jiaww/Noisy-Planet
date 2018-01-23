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

uniform vec3 u_CamPos;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

const vec4 lightPos = vec4(5, 5, 3, 1);

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

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

float noise_sum_abs(vec3 p)
{   
    float a = 1., r = 0., s=0.;
    
    for (int i=0; i<2; i++) {
      r += a*abs(PerlinNoise(p)); s+= a; p *= 2.; a*=.5;
    }
    
    return (r/s-.135)/(.06*3.);
}

out vec4 fs_Pos;
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out float fs_Alpha;

void main()
{
    vec4 vertexPos = vs_Pos;
    fs_Pos = vs_Pos;
    vec3 localNormal = normalize(vertexPos.xyz);
    float u_resolution = 4.0;
    float noiseResult = noise_sum_abs(vertexPos.xyz*u_resolution) * 2.0;  
    noiseResult = pow(noiseResult,  0.2);
    // Push more away from center
    vertexPos.xyz += localNormal * (noiseResult - 0.18);
    float height = length(vertexPos.xyz);
    float groundHeight = length(vs_Pos);

    fs_Alpha = pow(height - groundHeight + 0.20, 15.0);

    noiseResult = pow(noiseResult,  0.5);
    vertexPos.xyz = vs_Pos.xyz + localNormal * (noiseResult - 0.04);

    mat4 rotMat = rotationMatrix(vec3(0,1,0), u_Time * 2.0);
    mat4 model = u_Model * rotMat;
    vec4 modelposition = model * vertexPos;
    vec3 sunDirection = normalize(lightPos.xyz);
    mat3 invModel = mat3(inverse(model));
    sunDirection = invModel * sunDirection;
    fs_LightVec = vec4(normalize(sunDirection), 1.0);

    gl_Position = u_ViewProj * modelposition;

}
