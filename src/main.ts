import {vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
export const controls = {
  tesselations: 8,
  'Load Scene': loadScene, // A function pointer, essentially
  Color: [255, 0, 0],
  Color2: [0, 255, 255],  
  Shader: 'perlin3D',
  FunnyTrig: false,
  ScaleSpeed: 1.0,
  RotateSpeed: 1.0,
  Octave: 7.0,
  FloatSpeed: 1.0,
  FloatAmp: 1.0,
  OceanColor: [38, 152, 232, 1.0],
  OceanHeight: 1.0,
  CoastColor: [233, 200, 143, 1.0],
  CoastHeight: 0.02,
  FoliageColor: [22, 120, 22, 1.0],  
  MountainColor: [62, 35, 3, 1.0],
  SnowColor: [255, 255, 255, 1.0],
  SnowHeight: 1.10,
  PolarCaps: [155, 214, 236, 1.0],
  PolarCapsAttitude: 1.1,
  TerrainExp: 0.63,
  TerrainSeed: 0.0,
};


let icosphere: Icosphere;
let square: Square;
let cube: Cube;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 12).step(1);
  gui.add(controls, 'Load Scene');
  var colorSetting = gui.addFolder('Color Setting');
  colorSetting.addColor(controls, 'Color');
  colorSetting.addColor(controls, 'Color2');
  colorSetting.addColor(controls, 'OceanColor');
  colorSetting.addColor(controls, 'SnowColor');
  colorSetting.addColor(controls, 'CoastColor');
  colorSetting.addColor(controls, 'MountainColor');
  colorSetting.addColor(controls, 'FoliageColor');

  var formSetting = gui.addFolder('Form Setting');
  formSetting.add(controls, 'OceanHeight', 0.0, 1.50).step(0.01);
  formSetting.add(controls, 'CoastHeight', 0.0, 0.04).step(0.01);
  formSetting.add(controls, 'SnowHeight', 0.0, 2.00).step(0.01);
  formSetting.add(controls, 'PolarCapsAttitude', 0.0, 3.0).step(0.01);
  formSetting.add(controls, 'TerrainExp', 0.0, 1.0).step(0.01);
  formSetting.add(controls, 'TerrainSeed', 0.0, 100.0).step(1.0);

  gui.add(controls, 'Shader', ['lambert', 'funny', 'perlin3D', 'perlin3D_BlinnPhong', 'RayTracing'])
  gui.add(controls, 'FunnyTrig')
  gui.add(controls, 'ScaleSpeed', 0.1, 10.0).step(0.1);
  gui.add(controls, 'RotateSpeed', 0, 2.0).step(0.1);
  gui.add(controls, 'Octave', 0.0, 10.0).step(1.0);
  gui.add(controls, 'FloatSpeed', 0.0, 10.0).step(0.1);
  gui.add(controls, 'FloatAmp', 0.0, 10.0).step(0.1);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.0, 0.0, 0.00, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const funny = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/funny-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/funny-frag.glsl')),
  ]);

  const perlin3D = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/perlin3D-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/perlin3D-frag.glsl')),
  ]);

  const perlin3D_BP = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/perlin3D_BlinnPhong-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/perlin3D_BlinnPhong-frag.glsl')),
  ]);

  const planet = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const cloud = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/cloud-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/cloud-frag.glsl')),
  ]);
  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
    gl.enable(gl.BLEND);
    gl.enable(gl.DEPTH_TEST);
    gl.enable(gl.CULL_FACE);
    gl.cullFace(gl.FRONT);
    let shader;
    if (controls.Shader == 'lambert')
      shader = lambert;
    else if (controls.Shader == 'funny')
      shader = funny;
    else if (controls.Shader == 'perlin3D')
      shader = perlin3D;
    else if (controls.Shader == 'perlin3D_BlinnPhong')
      shader = perlin3D_BP;
    else if (controls.Shader == 'RayTracing')
      shader = planet
    if (shader == planet){
      renderer.render(camera, shader, [
      icosphere,
      //square,
      //cube,
    ]);
      renderer.render(camera, cloud, [
      icosphere,
      //square,
      //cube,
    ]);
    }
    else{
      renderer.render(camera, shader, [
      icosphere,
      //square,
      //cube,
    ]);
    }
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
