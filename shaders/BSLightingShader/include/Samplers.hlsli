#define Sample2D(tex, uv) t##tex.Sample(s##tex, uv)
#define SampleCube(tex, uv) t##tex.Sample(s##tex, uv)

// Don't need ifdef spaghetti here, the compiler is smart enough to handle it
#if defined(PIXELSHADER)

SamplerState sDiffuse : register(s0);
SamplerState sNormal : register(s1);
SamplerState sSpecular : register(s2);
SamplerState sHeight : register(s3);
SamplerState sTint : register(s3);
SamplerState sProjectedDiffuse : register(s3);
SamplerState sDetail : register(s4);
SamplerState sEnv : register(s4);
SamplerState sEnvMask : register(s5);
SamplerState sGlow : register(s6);
SamplerState sMultiLayerParallax : register(s8);
SamplerState sProjectedNormal : register(s8);
SamplerState sBackLightMask : register(s9);
SamplerState sProjectedNormalDetail : register(s10);
SamplerState sProjectedNoise : register(s11);
SamplerState sSubSurface : register(s12);
SamplerState sWorldMapOverlayNormal : register(s12);
SamplerState sWorldMapOverlayNormalSnow : register(s13);
SamplerState sShadowMask : register(s14);
SamplerState sLODNoise : register(s15);

Texture2D tDiffuse : register(t0);
Texture2D tNormal : register(t1);
Texture2D tSpecular : register(t2);
Texture2D tHeight : register(t3);
Texture2D tTint : register(t3);
Texture2D tProjectedDiffuse : register(t3);
Texture2D tDetail : register(t4);
TextureCube tEnv : register(t4);
Texture2D tEnvMask : register(t5);
Texture2D tGlow : register(t6);
Texture2D tProjectedNormal : register(t8);
Texture2D tMultiLayerParallax : register(t8);
Texture2D tBackLightMask : register(t9);
Texture2D tProjectedNormalDetail : register(t10);
Texture2D tProjectedNoise : register(t11);
Texture2D tSubSurface : register(t12);
Texture2D tWorldMapOverlayNormal : register(t12);
Texture2D tWorldMapOverlayNormalSnow : register(t13);
Texture2D tShadowMask : register(t14);
Texture2D tLODNoise : register(t15);

// MTLand uses nearly entirely separate samplers

SamplerState sMTLandDiffuseBase : register(s0);
SamplerState sMTLandDiffuse1 : register(s1);
SamplerState sMTLandDiffuse2 : register(s2);
SamplerState sMTLandDiffuse3 : register(s3);
SamplerState sMTLandDiffuse4 : register(s4);
SamplerState sMTLandDiffuse5 : register(s5);
SamplerState sMTLandNormalBase : register(s7);
SamplerState sMTLandNormal1 : register(s8);
SamplerState sMTLandNormal2 : register(s9);
SamplerState sMTLandNormal3 : register(s10);
SamplerState sMTLandNormal4 : register(s11);
SamplerState sMTLandNormal5 : register(s12);
SamplerState sMTLandTerrainOverlayTexture : register(s13);
SamplerState sMTLandTerrainNoiseTexture : register(s15);

Texture2D tMTLandDiffuseBase : register(t0);
Texture2D tMTLandDiffuse1 : register(t1);
Texture2D tMTLandDiffuse2 : register(t2);
Texture2D tMTLandDiffuse3 : register(t3);
Texture2D tMTLandDiffuse4 : register(t4);
Texture2D tMTLandDiffuse5 : register(t5);
Texture2D tMTLandNormalBase : register(t7);
Texture2D tMTLandNormal1 : register(t8);
Texture2D tMTLandNormal2 : register(t9);
Texture2D tMTLandNormal3 : register(t10);
Texture2D tMTLandNormal4 : register(t11);
Texture2D tMTLandNormal5 : register(t12);
Texture2D tMTLandTerrainOverlayTexture : register(t13);
Texture2D tMTLandTerrainNoiseTexture : register(t15);

#endif