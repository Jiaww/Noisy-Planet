#version 300 es

#define SUMMED
//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time; // The color with which to render this instance of geometry.
uniform float u_Octave;
uniform float u_Trig;
uniform float u_FloatSpeed;
uniform float u_FloatAmp;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float fs_Noise;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

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
    noise = SummedNoise(vec3(modelposition) + floating, u_Octave);
#endif  
    noise = pow(noise, 3.0);
    fs_Noise = noise;
    vec4 noise_Pos = modelposition + noise * u_FloatAmp * fs_Nor;
    fs_Pos = noise_Pos;
    gl_Position = u_ViewProj * noise_Pos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
