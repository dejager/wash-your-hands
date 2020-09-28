#include <metal_stdlib>
using namespace metal;

#define nc0 float4(0.0, 157.0, 113.0, 270.0)
#define nc1 float4(1.0, 158.0, 114.0, 271.0)

float2 processHash2AnimInput(float r, float x) {
  return float2(fract(15.32354 * (r + x)), fract(17.25865 * (r + x)));
}

float2 hash2Anim(float2 x, float anim) {
  float r = 523.0 * sin(dot(x, float2(53.3158, 43.6143)));

  float xa1 = fract(anim);
  float xb1 = anim - xa1;

  anim += 0.5;

  float xa2 = fract(anim);
  float xb2 = anim - xa2;


  float2 z1 = processHash2AnimInput(r, xb1);
  r = r + 1.0;
  float2 z2 = processHash2AnimInput(r, xb1);
  r = r + 1.0;
  float2 z3 = processHash2AnimInput(r, xb2);
  r = r + 1.0;
  float2 z4 = processHash2AnimInput(r, xb2);

  return (mix(z1, z2, xa1) + mix(z3, z4, xa2)) * 0.5;
}

float nilHash(float2 x) {
  return fract(523.0 * sin(dot(x, float2(53.3158, 43.6143))));
}

float4 hash4(float4 x) {
  return fract(sin(x) * 753.5453123);
}
float2 hash2(float2 x) {
  return fract(sin(x) * 753.5453123);
}

float noise2(float2 x) {
  float2 p = floor(x);
  float2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);

  float n = p.x + p.y * 157.0;
  float2 s1 = mix(hash2(float2(n) + nc0.xy), hash2(float2(n) + nc1.xy), float2(f.x));
  return mix(s1.x, s1.y, f.y);
}

float noise3( float3 x ) {
  float3 p = floor(x);
  float3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);

  float n = p.x + dot(p.yz, float2(157.0, 113.0));
  float4 s1 = mix(hash4(float4(n) + nc0), hash4(float4(n) + nc1), float4(f.x));
  return mix(mix(s1.x, s1.y, f.y), mix(s1.z, s1.w, f.y), f.z);
}

float4 bubble(float2 te, float2 pos, float numCells) {
  float d = dot(te, te);

  float2 te1 = te + (pos - float2(0.5, 0.5)) * 0.4 / numCells;
  float2 te2 = -te1;
  float zb1 = max(pow(noise2(te2 * 1000.11 * d),10.0),0.01);
  float zb2 = noise2(te1 * 1000.11 * d);
  float zb3 = noise2(te1 * 200.11 * d);
  float zb4 = noise2(te1 * 200.11 * d + float2(20.0));

  float4 colorb = float4(1.0);
  colorb.xyz = colorb.xyz * (0.7 + noise2(te1 * 1000.11 * d) * 0.3);

  zb2 = max(pow(zb2, 20.1), 0.01);
  colorb.xyz = colorb.xyz * (zb2 * 1.9);

  float4 color = float4(noise2(te2 * 10.8),
                        noise2(te2 * 9.5 + float2(15.0, 15.0)),
                        noise2(te2 * 11.2 + float2(12.0, 12.0)),
                        1.0);

  color = mix(color, float4(1.0), noise2(te2 * 20.5 + float2(200.0, 200.0)));
  color.xyz = color.xyz * (0.7 + noise2(te2 * 1000.11 * d) * 0.3);
  color.xyz = color.xyz * (0.2 + zb1 * 1.9);

  float r1 = max(min((0.033 - min(0.04, d)) * 100.0 / sqrt(numCells), 1.0), -1.6);
  float d2 = (0.06 - min(0.06,d)) * 10.0;
  d = (0.04 - min(0.04, d)) * 10.0;
	color.xyz = color.xyz + colorb.xyz * d * 1.5;

  float f1 = min(d * 10.0, 0.5 - d) * 2.2;
  f1=pow(f1, 4.0);
  float f2 = min(min(d * 4.1, 0.9 - d) * 2.0 * r1, 1.0);

  float f3 = min(d2 * 2.0, 0.7 - d2) * 2.2;
  f3=pow(f3, 4.0);

	return float4(color * max(min(f1 + f2, 1.0), -0.5) + float4(zb3) * f3 - float4(zb4) * (f2 * 0.5 + f1) * 0.5);
}

float4 cells(float2 p, float2 move, float numCells, float count, float blur, float time) {
  float2 uv = p;
  float2 inp = p + move;
  inp *= numCells;
  float d = 1.0;
  float2 te;
  float2 pos;
  for (int xo = -1; xo <= 1; xo++) {
    for (int yo = -1; yo <= 1; yo++) {
      float2 tp = floor(inp) + float2(xo, yo);
      float2 rr = fmod(tp, numCells);
      tp = tp + (hash2Anim(rr, time * 0.1) + hash2Anim(rr, time * 0.1 + 0.25)) * 0.5;
      float2 l = inp - tp;
      float dr=dot(l, l);
      if (nilHash(rr) > count) {
        if (d > dr) {
          d = dr;
          pos = tp;
        }
      }
    }
  }
  if (d >= 0.06) {
    return float4(0.0);
  }
  
  te = inp - pos;

  if (d < 0.04) {
    uv = uv + te * (d) * 2.0;
  }
  if (blur > 0.0001) {
    float4 c = float4(0.0);
    for (float x = -1.0; x < 1.0; x += 0.5) {
      for (float y = -1.0; y < 1.0; y += 0.5) {
        c += bubble(te + float2(x, y) * blur, p, numCells);
      }
    }
    return c * 0.05;
  }

  return bubble(te, p, numCells);
}

float4 processColor(float4 color, float4 colorIn, float multiplier) {
  return max(color - float4(dot(colorIn, colorIn)) * 0.1, 0.0) + colorIn * multiplier;
}

kernel void sanitize(texture2d<float, access::write> o[[texture(0)]],
                              constant float &time [[buffer(0)]],
                              constant float2 *touchEvent [[buffer(1)]],
                              constant int &numberOfTouches [[buffer(2)]],
                              ushort2 gid [[thread_position_in_grid]]) {

  int width = o.get_width();
  int height = o.get_height();
  float2 res = float2(width, height);
  float2 uv = (float2(gid) * 2.0 - res.xy) / res.y;

  float2 l1 = float2(time * 0.02, time * 0.02);
  float2 l2 = float2(-time * 0.01, time * 0.007);
  float2 l3 = float2(0.0,time * 0.01);

  float4 color = float4(0.0, 0.0, 0.0, 1.0);

  float4 color1 = cells(uv, float2(20.2449, 93.78) + l1, 2.0, 0.5, 0.005, time);
  float4 color2 = cells(uv, float2(0.0, 0.0), 3.0, 0.5, 0.003, time);
  float4 color3 = cells(uv, float2(230.79, 193.2) + l2,4.0, 0.5, 0.0, time);
  float4 color4 = cells(uv, float2(200.19, 393.2) + l3, 7.0, 0.8, 0.01, time);
  float4 color5 = cells(uv, float2(10.3245, 233.645) + l3, 9.2, 0.9, 0.02, time);
  float4 color6 = cells(uv, float2(10.3245, 233.645) + l3, 14.2, 0.95, 0.05, time);

  color = processColor(color, color6, 1.6);
  color = processColor(color, color5, 1.6);
  color = processColor(color, color4, 1.3);
  color = processColor(color, color3, 1.1);
  color = processColor(color, color2, 1.4);
  color = processColor(color, color1, 1.8);

  o.write(color, gid);
}
