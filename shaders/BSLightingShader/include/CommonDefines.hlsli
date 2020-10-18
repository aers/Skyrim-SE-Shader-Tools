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

#define M_PI  3.14159265358979323846 // PI
#define M_2PI 6.28318530717958647692 // PI * 2

const static float4x4 M_IdentityMatrix =
{
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 1 }
};