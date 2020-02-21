// Skyrim Special Edition - BSLightingShader Defines

// All the groundwork for this can be found in Nukem's project here: https://github.com/Nukem9/SkyrimSETest/tree/master/skyrim64_test/src/patches/TES/BSShader/Shaders

// techniques 
// 0 None
// 1 Envmap - #define ENVMAP
// 2 Glowmap - #define GLOWMAP
// 3 Parallax - #define PARALLAX
// 4 Facegen - #define FACEGEN  (Face Tint)
// 5 FacegenRGBTint - #define FACEGEN_RGB_TINT (Skin Tint)
// 6 Hair - #define HAIR (Hair Tint)
// 7 ParallaxOcc - #define PARALLAX_OCC
// 8 MTLand - #define MULTI_TEXTURE, #define LANDSCAPE
// 9 LODLand - #define LODLANDSCAPE
// 10 Unknown - Unused (SNOW)
// 11 MultiLayerParallax - #define MULTI_LAYER_PARALLAX, #define ENVMAP
// 12 Tree - #define TREE_ANIM
// 13 LODObj - #define LODOBJECTS
// 14 MultiIndexTriShapeSnow - #define MULTI_INDEX, #define SPARKLE
// 15 LODObjHD - #define LODOBJECTSHD
// 16 Eye - #define EYE
// 17 Unknown - Unused (#define CLOUD, #define INSTANCED)
// 18 LODLandNoise - #define LODLANDSCAPE, #define LODLANDNOISE
// 19 MTLandLODBlend - #define MULTI_TEXTURE, #define LANDSCAPE, #define LOD_LAND_BLEND

// flags
// 1<<0 Vc - #define VC
// 1<<1 Sk - #define SKINNED
// 1<<2 Msn - #define MODELSPACENORMALS
// 1<<9 Spc - #define SPECULAR
// 1<<10 Sss - #define SOFT_LIGHTING
// 1<<11 Rim - #define RIM_LIGHTING
// 1<<12 Bk - #define BACK_LIGHTING
// 1<<13 Sh - #define SHADOW_DIR
// 1<<14 DfSh - #define DEFSHADOW
// 1<<15 Projuv - #define PROJECTED_UV
// 1<<15 DwDecals - #define DEPTH_WRITE_DECALS (HAIR technique only)
// 1<<16 (None) - #define ANISO_LIGHTING
// 1<<17 Aspc - #define AMBIENT_SPECULAR
// 1<<18 Wmap - #define WORLD_MAP
// 1<<19 BaseSnow - #define BASE_OBJECT_IS_SNOW
// 1<<20 Atest - #define DO_ALPHA_TEST
// 1<<21 Snow - #define SNOW
// 1<<22 (None) - #define CHARACTER_LIGHT
// 1<<23 (Aam) - #define ADDITIONAL_ALPHA_MASK

// check for repeated techniques

#undef HAS_TECHNIQUE
#undef TECHNIQUE_IS_ENVMAP
#undef TECHNIQUE_IS_MTLAND
#undef TECHNIQUE_IS_LODLANDSCAPE

#if defined(ENVMAP)
#define HAS_TECHNIQUE
#define TECHNIQUE_IS_ENVMAP
#endif

#if defined(GLOWMAP)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(PARALLAX)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(FACEGEN)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(FACEGEN_RGB_TINT)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(HAIR)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(PARALLAX_OCC)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(MULTI_TEXTURE) && defined(LANDSCAPE)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#define TECHNIQUE_IS_MTLAND
#endif

#if (defined(MULTI_TEXTURE) && !defined(LANDSCAPE)) || (!defined(MULTI_TEXTURE) && defined(LANDSCAPE))
#error MULTI_TEXTURE and LANDSCAPE must be used together
#endif

#if defined(LODLANDSCAPE)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#define TECHNIQUE_IS_LODLANDSCAPE
#endif

#if defined(MULTI_LAYER_PARALLAX)
#if defined(HAS_TECHNIQUE) && !defined(TECHNIQUE_IS_ENVMAP)
#error multiple techniques defined
#endif
#if !defined(TECHNIQUE_IS_ENVMAP)
#error MULTI_LAYER_PARALLAX requires ENVMAP to also be defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(TREE_ANIM)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(LODOBJECTS)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(MULTI_INDEX) && defined(SPARKLE)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if (defined(MULTI_INDEX) && !defined(SPARKLE)) || (!defined(MULTI_INDEX) && defined(SPARKLE))
#error MULTI_INDEX and SPARKLE must be used together
#endif

#if defined(LODOBJECTSHD)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(EYE)
#if defined(HAS_TECHNIQUE)
#error multiple techniques defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(LODLANDNOISE)
#if defined(HAS_TECHNIQUE) && !defined(TECHNIQUE_IS_LODLANDSCAPE)
#error multiple techniques defined
#endif
#if !defined(TECHNIQUE_IS_LODLANDSCAPE)
#error LODLANDNOISE requires LODLANDSCAPE to also be defined
#endif
#define HAS_TECHNIQUE
#endif

#if defined(LOD_LAND_BLEND)
#if defined(HAS_TECHNIQUE) && !defined(TECHNIQUE_IS_MTLAND)
#error multiple techniques defined
#endif
#if !defined(TECHNIQUE_IS_MTLAND)
#error LOD_LAND_BLEND requires MULTI_TEXTURE and LANDSCAPE to also be defined
#endif
#define HAS_TECHNIQUE
#endif

// guard against incompatible flags

#if defined(MODELSPACENORMALS)
#if defined(PARALLAX) || defined(PARALLAX_OCC) || defined(MULTI_LAYER_PARALLAX)
#error PARALLAX techniques are incompatible with MODELSPACENORMALS because the vertex shader does not provide a tangent space conversion matrix
#endif
#if defined(MULTI_TEXTURE)
#error MULTI_TEXTURE techniques are incompatible with MODELSPACENORMALS due to re-use of texture slot 2
#endif
#if defined(ANISO_LIGHTING)
#error ANISO_LIGHTING flag is incompatible with MODELSPACENORMALS because it requires access to the vertex normal
#endif
#endif

#if defined(MULTI_TEXTURE) && (defined(SOFT_LIGHTING) || defined(RIM_LIGHTING))
#error MULTI_TEXTURE technique incompatible with SOFT_LIGHTING and RIM_LIGHTING flags due to re-use of texture slot 12
#endif

#if defined(MULTI_TEXTURE) && defined(BACK_LIGHTING)
#error MULTI_TEXTURE technique incompatible with BACK_LIGHTING flag due to re-use of texture slot 9
#endif

#if defined(PROJECTED_UV)
#if defined(PARALLAX)
#error PARALLAX technique is incompatible with PROJETED_UV flag due to re-use of texture slot 3
#endif
#if defined(MULTI_LAYER_PARALLAX)
#error MULTI_LAYER_PARALLAX technique is incompatible with PROJECTED_UV flag due to re-use of texture slot 8
#endif
#if defined(FACEGEN)
#error FACEGEN technique is incompatible with PROJECTED_UV flag due to re-use of texture slot 3
#endif
#if defined(MULTI_TEXTURE)
#error MULTI_TEXTURE technique is incompatible with PROJECTED_UV flag due to re-use of multiple texture slots
#endif
#endif

#if defined(DEPTH_WRITE_DECALS)
#if !defined(HAIR)
#error DEPTH_WRITE_DECALS flag is only compatible with the HAIR technique
#endif
#if defined(PIXELSHADER) && !defined(DO_ALPHA_TEST)
#error DEPTH_WRITE_DECALS requires the DO_ALPHA_TEST flag when compiling the pixel shader
#endif
#endif

// set some extra defines to avoid large if statements in the main shader
// note: in the game's renderer PARALLAX, PARALLAXOCC, FACEGEN, and FACEGEN_RGB_TINT do not update the eye (view) position so this output will be wrong unless specular is also enabled
// in vertex shader RIM_LIGHTING and AMBIENT_SPECULAR force SPECULAR flag, creating the view direction vector, even though those flags aren't used to generate vertex shader combinations
#if defined(SPECULAR) || defined(RIM_LIGHTING) || defined(AMBIENT_SPECULAR) || defined(ENVMAP) || defined(PARALLAX) || defined(PARALLAX_OCC) || defined(FACEGEN) || defined(FACEGEN_RGB_TINT) || defined(MULTI_LAYER_PARALLAX) || defined(EYE)
#define HAS_VIEW_DIRECTION_VECTOR_OUTPUT
#endif

#if defined(SKINNED) || defined(ENVMAP) || defined(EYE) || defined(MULTI_LAYER_PARALLAX)
#define DRAW_IN_WORLDSPACE
#endif

// this transform is primarly used to take normals into common space
// since common space is model space by default, its not present if there are model space normals and the shader is not drawing in world space
#if defined(DRAW_IN_WORLDSPACE) || !defined(MODELSPACENORMALS)
#define HAS_COMMON_TRANSFORM
#endif