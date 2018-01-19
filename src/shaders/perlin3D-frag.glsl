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
uniform vec4 u_Color2; // The color with which to render this instance of geometry.
uniform float u_Time; // The color with which to render this instance of geometry.
uniform float u_Octave;
uniform float u_Trig;
uniform float u_FloatSpeed;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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

    return surflet3D(uvw, uvwXLYLZL) + surflet3D(uvw, uvwXLYHZL) + surflet3D(uvw, uvwXLYHZH) + surflet3D(uvw, uvwXLYLZH) + 
    surflet3D(uvw, uvwXHYLZL) + surflet3D(uvw, uvwXHYHZL) + surflet3D(uvw, uvwXHYLZH) + surflet3D(uvw, uvwXHYHZH);
}

vec3 PositionToGrid(vec3 pos, float size){
    vec3 uvw = (pos - vec3(-1.0, -1.0, -1.0))/2.0;
    return uvw * size;
}

float SummedNoise(vec3 p, float num_octs){
    if (num_octs == 0.0)
        return 0.0;
    float summedNoise = 0.0;
    float amplitude = 0.5;
    float summedAmp = 0.0;
    for(int i = 2; i <= int(pow(2.0, num_octs)); i *= 2) {
        vec3 uvw = PositionToGrid(p, float(i));
        uvw = m * uvw;
        float perlin = abs(PerlinNoise(uvw));// * amplitude;
        summedNoise += perlin * amplitude;
        summedAmp += amplitude;
        amplitude *= 0.5;
    }
    return summedNoise/summedAmp;
}// rotation matrix for fbm octaves

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    //out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    // noise
    vec3 floating;
    if (u_Trig == 1.0){
        floating = vec3(sin(u_Time * 10.0 * u_FloatSpeed));
    } 
    else{
        floating = vec3(0.0);
    }    
    float noise;
#ifdef SUMMED
    noise = SummedNoise(vec3(fs_Pos) + floating, u_Octave);
#endif  
    diffuseColor = u_Color * (1.0 - (1.0 - noise)*(1.0 - noise)) + u_Color2 * (1.0 - noise) * (1.0 - noise);
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    // out_Col = vec4(vec3(noise), 1.0);
}
