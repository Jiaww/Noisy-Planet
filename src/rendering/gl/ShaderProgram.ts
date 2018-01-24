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
  unifOceanColor: WebGLUniformLocation;
  unifSnowColor: WebGLUniformLocation;
  unifCoastColor: WebGLUniformLocation;
  unifFoliageColor: WebGLUniformLocation;
  unifTropicalColor: WebGLUniformLocation;
  unifMountainColor: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifTrig: WebGLUniformLocation;
  unifHeightsInfo: WebGLUniformLocation;
  unifTerrainInfo: WebGLUniformLocation;
  unifCamPos: WebGLUniformLocation;
  unifOctave: WebGLUniformLocation;
  unifFloatSpeed: WebGLUniformLocation;
  unifSunPos: WebGLUniformLocation;
  unifSunLight: WebGLUniformLocation;

// Other Settings for testing
  unifColor: WebGLUniformLocation;
  unifColor2: WebGLUniformLocation;
  unifScaleSpeed: WebGLUniformLocation;
  unifRotateSpeed: WebGLUniformLocation;
  unifFloatAmp: WebGLUniformLocation;
  unifResolution: WebGLUniformLocation;
  unifCamDir: WebGLUniformLocation;
  unifEnvMap: WebGLUniformLocation;

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
    this.unifModel        = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr   = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj     = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifOceanColor   = gl.getUniformLocation(this.prog, "u_OceanColor");
    this.unifSnowColor    = gl.getUniformLocation(this.prog, "u_SnowColor");
    this.unifCoastColor   = gl.getUniformLocation(this.prog, "u_CoastColor");
    this.unifFoliageColor = gl.getUniformLocation(this.prog, "u_FoliageColor");
    this.unifTropicalColor= gl.getUniformLocation(this.prog, "u_TropicalColor");
    this.unifMountainColor= gl.getUniformLocation(this.prog, "u_MountainColor");
    this.unifHeightsInfo  = gl.getUniformLocation(this.prog, "u_HeightsInfo");
    this.unifTerrainInfo  = gl.getUniformLocation(this.prog, "u_TerrainInfo");
    this.unifCamPos       = gl.getUniformLocation(this.prog, "u_CamPos");
    this.unifOctave       = gl.getUniformLocation(this.prog, "u_Octave");
    this.unifFloatSpeed   = gl.getUniformLocation(this.prog, "u_FloatSpeed");
    this.unifTime         = gl.getUniformLocation(this.prog, "u_Time");
    this.unifTrig         = gl.getUniformLocation(this.prog, "u_Trig");
    this.unifSunPos       = gl.getUniformLocation(this.prog, "u_SunPos");
    this.unifSunLight     = gl.getUniformLocation(this.prog, "u_SunLight"); // r,g,b, intensity

    // Other Setting for testing
    this.unifColor        = gl.getUniformLocation(this.prog, "u_Color");
    this.unifColor2       = gl.getUniformLocation(this.prog, "u_Color2");
    this.unifScaleSpeed   = gl.getUniformLocation(this.prog, "u_ScaleSpeed");
    this.unifRotateSpeed  = gl.getUniformLocation(this.prog, "u_RotateSpeed");
    this.unifFloatAmp     = gl.getUniformLocation(this.prog, "u_FloatAmp");
    this.unifResolution   = gl.getUniformLocation(this.prog, "u_Resolution");
    this.unifCamDir       = gl.getUniformLocation(this.prog, "u_CamDir");
    this.unifEnvMap       = gl.getUniformLocation(this.prog, "u_EnvMap");
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

  // Set Colors
  setColors(oceanColor: vec4, snowColor: vec4, coastColor: vec4, foliageColor: vec4, tropicalColor: vec4, mountainColor: vec4){
    this.use();
    if (this.unifOceanColor !== -1)
      gl.uniform4fv(this.unifOceanColor, oceanColor);
    if (this.unifSnowColor !== -1)
      gl.uniform4fv(this.unifSnowColor, snowColor);
    if (this.unifCoastColor !== -1)
      gl.uniform4fv(this.unifCoastColor, coastColor);
    if (this.unifFoliageColor !== -1)
      gl.uniform4fv(this.unifFoliageColor, foliageColor);
    if (this.unifTropicalColor !== -1)
      gl.uniform4fv(this.unifTropicalColor, tropicalColor);
    if (this.unifMountainColor !== -1)
      gl.uniform4fv(this.unifMountainColor, mountainColor);
  }

  setHeightsInfo(heightsInfo: vec4){
    this.use();
    if (this.unifHeightsInfo !== -1)
      gl.uniform4fv(this.unifHeightsInfo, heightsInfo);
  }

  setTerrainInfo(terrainInfo: vec2){
    this.use();
    if (this.unifHeightsInfo !== -1)
      gl.uniform2fv(this.unifTerrainInfo, terrainInfo);
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

  setFloatAmp(floatAmp: number){
    this.use();
    if (this.unifFloatAmp !== -1){
      gl.uniform1f(this.unifFloatAmp, floatAmp);
    }
  }
  
  setResolution(resolution: vec2) {
    this.use();
    if (this.unifResolution !== -1) {
      gl.uniform2fv(this.unifResolution, resolution);
    }
  }

  setCamInfo(camPos: vec3, camDir: vec3) {
    this.use();
    if (this.unifCamPos !== -1) {
      gl.uniform3fv(this.unifCamPos, camPos);
    }
    if (this.unifCamDir !== -1) {
      gl.uniform3fv(this.unifCamDir, camDir);
    }
  }

  setSunSettings(sunPos: vec3, sunLight: vec4){
    this.use();
    if (this.unifSunPos !== -1) {
      gl.uniform3fv(this.unifSunPos, sunPos);
    }
    if (this.unifSunLight !== -1) {
      gl.uniform4fv(this.unifSunLight, sunLight);
    }
  }
  
  setEnvMap(envMap: WebGLTexture){
    this.use();
    if (this.unifEnvMap !== -1) {
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, envMap);
      gl.uniform1i(this.unifEnvMap, 0);
    }
  }
  
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
