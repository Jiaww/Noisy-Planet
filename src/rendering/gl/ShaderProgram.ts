import {vec2, vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifColor2: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifTrig: WebGLUniformLocation;
  unifScaleSpeed: WebGLUniformLocation;
  unifRotateSpeed: WebGLUniformLocation;
  unifOctave: WebGLUniformLocation;
  unifFloatSpeed: WebGLUniformLocation;
  // unifResolution: WebGLUniformLocation;
  // unifCamPos: WebGLUniformLocation;
  // unifCamDir: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifColor2     = gl.getUniformLocation(this.prog, "u_Color2");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");
    this.unifTrig       = gl.getUniformLocation(this.prog, "u_Trig");
    this.unifScaleSpeed = gl.getUniformLocation(this.prog, "u_ScaleSpeed");
    this.unifRotateSpeed= gl.getUniformLocation(this.prog, "u_RotateSpeed");
    this.unifOctave     = gl.getUniformLocation(this.prog, "u_Octave");
    this.unifFloatSpeed= gl.getUniformLocation(this.prog, "u_FloatSpeed");
    // this.unifResolution = gl.getUniformLocation(this.prog, "u_Resolution");
    // this.unifCamPos = gl.getUniformLocation(this.prog, "u_CamPos");
    // this.unifCamDir = gl.getUniformLocation(this.prog, "u_CamDir");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setGeometryColor2(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor2, color);
    }
  }

  updateTime(time: number){
    this.use();
    if (this.unifTime !== -1){
      gl.uniform1f(this.unifTime, time);
    }
  }

  setTrig(trig: boolean) {
    this.use();
    if (this.unifTrig !== -1) {
      if (trig){
        gl.uniform1f(this.unifTrig, 1.0);
      }
      else{
        gl.uniform1f(this.unifTrig, 0.0);
      }
    }
  }

  setScaleSpeed(scaleSpeed: number) {
    this.use();
    if (this.unifScaleSpeed !== -1) {
      gl.uniform1f(this.unifScaleSpeed, scaleSpeed);
    }
  }

  setRotateSpeed(rotateSpeed: number) {
    this.use();
    if (this.unifRotateSpeed !== -1) {
      gl.uniform1f(this.unifRotateSpeed, rotateSpeed);
    }
  }

  setFloatSpeed(floatSpeed: number) {
    this.use();
    if (this.unifFloatSpeed !== -1) {
      gl.uniform1f(this.unifFloatSpeed, floatSpeed);
    }
  }

  setOctave(octave: number) {
    this.use();
    if (this.unifOctave !== -1) {
      gl.uniform1f(this.unifOctave, octave);
    }
  }
  // setResolution(resolution: vec2) {
  //   this.use();
  //   if (this.unifResolution !== -1) {
  //     gl.uniform2fv(this.unifResolution, resolution);
  //   }
  // }

  // setCamInfo(camPos: vec3, camDir: vec3) {
  //   this.use();
  //   if (this.unifCamPos !== -1) {
  //     gl.uniform3fv(this.unifCamPos, camPos);
  //   }
  //   if (this.unifCamDir !== -1) {
  //     gl.uniform3fv(this.unifCamDir, camDir);
  //   }
  // }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
