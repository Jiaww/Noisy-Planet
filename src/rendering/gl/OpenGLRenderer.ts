import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';
import {controls} from '../../main'

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = vec4.fromValues(controls.Color[0]/255, controls.Color[1]/255, controls.Color[2]/255, 1);
    let color2 = vec4.fromValues(controls.Color2[0]/255, controls.Color2[1]/255, controls.Color2[2]/255, 1);
    var d = new Date();
    let time = (d.getTime()) / 30000.0;
    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    prog.setGeometryColor2(color2);
    console.log(controls.Color);
    console.log(controls.Color2);
    prog.updateTime(Math.sin(time));
    prog.setTrig(controls.FunnyTrig);
    prog.setScaleSpeed(controls.ScaleSpeed);
    prog.setRotateSpeed(controls.RotateSpeed);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
