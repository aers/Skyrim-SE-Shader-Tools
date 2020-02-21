// Skyrim Special Edition - BSLightingShader vertex shader 

// from FO4 EffectMAX.fx
float4 GetFog(float3 apPosition, float afNearInverseFarMinusNear, float afInverseFarMinusNear, float afPower, float afClamp, float3 NearColor, float3 FarColor)
{
    float4 ret;
    float dist = length(apPosition);
    ret.a = min(pow(saturate(dist * afInverseFarMinusNear - afNearInverseFarMinusNear), afPower), afClamp);
    ret.rgb = lerp(NearColor, FarColor, ret.a);

    return ret;
}

// tree branch animation in wind
// credit to arha for writing this out for me
float GetTreeDisplacement(float3 apVertexPosition, float4 aTreeParams, float afWindTimer, float afVertexAlpha)
{
    float windBase = aTreeParams.w * aTreeParams.y * afWindTimer.x; // constantly increasing values scaled by per-object tuning
    float2 windBands = windBase * float2(0.1, 0.25); // two bands of animation
    float cheapVertDistance = dot(apVertexPosition.xyz, float3(1, 1, 1)); // make objects with different object-space positions animate differently
    float2 windScales = frac(windBands + cheapVertDistance + float2(0.5, 0.5)); // combine together to get two [0, 1) bands
    float2 rescaledWind = (windScales * 2) - 1; // rescale to [-1, 1)
    float2 sawWave = 3 - abs(rescaledWind) * 2; // saw wave
    float2 curvedSaw = abs(rescaledWind) * abs(rescaledWind); // shape the wave
    float2 combinedSaw = sawWave * curvedSaw; // combine both waves together
    float displacementScale = (combinedSaw.x + combinedSaw.y * 0.1) * aTreeParams.z * afVertexAlpha;

    return displacementScale;
}

VS_OUTPUT VSMain(VS_INPUT input)
{
    VS_OUTPUT vsout;

    // represents the 4x4 world transformation matrix
    float4x4 v_World4x4;
    // represents the common space vertex position
    precise float4 v_VertexPos;
    precise float4 v_ModelVertexPos;
    float4 v_VertexColor;

    // vertex color is set to (1,1,1,1) if there isn't any; all pixel shaders use the vertex shader flag
#if defined(VC)
    v_VertexColor = input.VertexColor;
#else
    v_VertexColor = float4(1, 1, 1, 1);
#endif

#if defined(HAS_COMMON_TRANSFORM) && !defined(MODELSPACENORMALS)
    // bitangent is in the VertexPos, Normal, Binormal w
    // normal+tangent are stored as a single byte 0-255 and must be transformed to [-1, 1]
    float3 bitangent = float3(input.VertexPos.w, input.Normal.w * 2 - 1, input.Binormal.w * 2 - 1);
    float3 tangent = input.Binormal.xyz * 2 - 1;
    float3 normal = input.Normal.xyz * 2 - 1;
#endif

#if defined(TREE_ANIM)
    v_VertexPos = float4(input.VertexPos.xyz + normal * GetTreeDisplacement(input.VertexPos.xyz, TreeParams, WindTimers.x, v_VertexColor.w), 1);
#else
    v_VertexPos = float4(input.VertexPos.xyz, 1);
#endif

    v_World4x4 = float4x4(World[0], World[1], World[2], float4(0, 0, 0, 1));

#if defined(SKINNED)
    int4 boneOffsets = (int4)(input.BoneIndices * 765.01);
    float3x4 AdjustedModelToSkinnedWorldMatrix = 0;

    float4 PosAdjustX = float4(-0, 0, -0, -CurrentPosAdjust.x);
    float4 PosAdjustY = float4(-0, 0, -0, -CurrentPosAdjust.y);
    float4 PosAdjustZ = float4(-0, 0, -0, -CurrentPosAdjust.z);

    // we could optimize a later set of skinning away by adjusting after but need to match the depth pass shader for now or else we get issues
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.x * float3x4(Bones[boneOffsets.x] + PosAdjustX, Bones[boneOffsets.x + 1] + PosAdjustY, Bones[boneOffsets.x + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.y * float3x4(Bones[boneOffsets.y] + PosAdjustX, Bones[boneOffsets.y + 1] + PosAdjustY, Bones[boneOffsets.y + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.z * float3x4(Bones[boneOffsets.z] + PosAdjustX, Bones[boneOffsets.z + 1] + PosAdjustY, Bones[boneOffsets.z + 2] + PosAdjustZ);
    AdjustedModelToSkinnedWorldMatrix += input.BoneWeights.w * float3x4(Bones[boneOffsets.w] + PosAdjustX, Bones[boneOffsets.w + 1] + PosAdjustY, Bones[boneOffsets.w + 2] + PosAdjustZ);

    // update world matrix to skinned world matrix
    v_World4x4[0] = AdjustedModelToSkinnedWorldMatrix[0];
    v_World4x4[1] = AdjustedModelToSkinnedWorldMatrix[1];
    v_World4x4[2] = AdjustedModelToSkinnedWorldMatrix[2];
#endif

#if defined(DRAW_IN_WORLDSPACE)
    v_ModelVertexPos = v_VertexPos;
    // update common space vertex position
    v_VertexPos = float4(dot(v_VertexPos, v_World4x4[0]), dot(v_VertexPos, v_World4x4[1]), dot(v_VertexPos, v_World4x4[2]), 1);
#endif

#if defined(LODLANDSCAPE)
    precise float4 WorldVertexPos = mul(v_World4x4, v_VertexPos);
    float2 LodVertexDist = abs(WorldVertexPos.xy - HighDetailRange.xy);
    if (LodVertexDist.x < HighDetailRange.z && LodVertexDist.y < HighDetailRange.w)
    {
        v_VertexPos.z = input.VertexPos.z - ((WorldVertexPos.z / 1e+009) + 230);
    }
#endif

#if defined(SKINNED)
    vsout.ProjVertexPos = mul(ViewProjMatrix, v_VertexPos);
#else
    float4x4 ModelProjMatrix = mul(ViewProjMatrix, v_World4x4);
#if defined(DRAW_IN_WORLDSPACE)
    // this is necessary because simply doing ViewProjMatrix, v_VertexPos (which is in worldspace) causes precision differences from the original bethesda shaders
    vsout.ProjVertexPos = mul(ModelProjMatrix, v_ModelVertexPos);
#else
    vsout.ProjVertexPos = mul(ModelProjMatrix, v_VertexPos);
#endif
#endif

#if defined(LODLANDSCAPE)
    float LODVertexZAdjust = min(1, max(0, (vsout.ProjVertexPos.z - 70000)) * 0.0001);
    vsout.ProjVertexPos.z = LODVertexZAdjust * 0.5 + vsout.ProjVertexPos.z;
#endif

    vsout.TexCoords.xy = input.TexCoords.xy * TexCoordOffset.zw + TexCoordOffset.xy;

#if defined(MULTI_TEXTURE)
    float2 LandBlendTexCoords = vsout.TexCoords.xy * float2(0.0104167, 0.0104167) + LandBlendParams.xy;
    vsout.TexCoords.zw = LandBlendTexCoords * float2(1, -1) + float2(0, 1);
#elif defined(PROJECTED_UV)
    vsout.TexCoords.z = dot(TextureProj[0], v_VertexPos);
    vsout.TexCoords.w = dot(TextureProj[1], v_VertexPos);
#endif

#if defined(WORLD_MAP)
    vsout.WorldMapVertexPos = mul(v_World4x4, v_VertexPos).xyz + WorldMapOverlayParameters.xyz;
#elif defined(DRAW_IN_WORLDSPACE)
    vsout.WorldSpaceVertexPos = v_VertexPos.xyz;
#else
    vsout.ModelSpaceVertexPos = v_VertexPos.xyz;
#endif

#if defined(HAS_COMMON_TRANSFORM)
#if defined(SKINNED)
    float3x4 ModelToSkinnedWorldMatrix = 0;

    ModelToSkinnedWorldMatrix += input.BoneWeights.x * float3x4(Bones[boneOffsets.x], Bones[boneOffsets.x + 1], Bones[boneOffsets.x + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.y * float3x4(Bones[boneOffsets.y], Bones[boneOffsets.y + 1], Bones[boneOffsets.y + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.z * float3x4(Bones[boneOffsets.z], Bones[boneOffsets.z + 1], Bones[boneOffsets.z + 2]);
    ModelToSkinnedWorldMatrix += input.BoneWeights.w * float3x4(Bones[boneOffsets.w], Bones[boneOffsets.w + 1], Bones[boneOffsets.w + 2]);
#endif
#if defined(MODELSPACENORMALS)
#if defined(SKINNED)
    vsout.ModelWorldTransform0 = normalize(ModelToSkinnedWorldMatrix[0].xyz);
    vsout.ModelWorldTransform1 = normalize(ModelToSkinnedWorldMatrix[1].xyz);
    vsout.ModelWorldTransform2 = normalize(ModelToSkinnedWorldMatrix[2].xyz);
#else
    vsout.ModelWorldTransform0 = World[0].xyz;
    vsout.ModelWorldTransform1 = World[1].xyz;
    vsout.ModelWorldTransform2 = World[2].xyz;
#endif
#elif defined(DRAW_IN_WORLDSPACE)
#if defined(SKINNED)
    float3 w_bitangent = normalize(mul(ModelToSkinnedWorldMatrix, bitangent));
    float3 w_tangent = normalize(mul(ModelToSkinnedWorldMatrix, tangent));
    float3 w_normal = normalize(mul(ModelToSkinnedWorldMatrix, normal));
#else
    float3 w_bitangent = mul(v_World4x4, bitangent);
    float3 w_tangent = mul(v_World4x4, tangent);
    float3 w_normal = mul(v_World4x4, normal);
#endif
    // tbn is usually tangent, bitangent, normal but bethesda shaders use btn
    // we want this transposed since the transform is Tangent->X not X->Tangent
    float3x3 w_tbn = transpose(float3x3(w_bitangent, w_tangent, w_normal));
    vsout.TangentWorldTransform0 = w_tbn[0];
    vsout.TangentWorldTransform1 = w_tbn[1];
    vsout.TangentWorldTransform2 = w_tbn[2];
#else
    float3x3 tbn = transpose(float3x3(bitangent, tangent, normal));
    vsout.TangentModelTransform0 = tbn[0];
    vsout.TangentModelTransform1 = tbn[1];
    vsout.TangentModelTransform2 = tbn[2];
#endif
#endif

    // this is done in common space, v_VertexPos will give us correct output
#if defined(HAS_VIEW_DIRECTION_VECTOR_OUTPUT)
    vsout.ViewDirectionVec.xyz = EyePosition - v_VertexPos.xyz;
#endif

#if defined(EYE)
    precise float4 EyeCenter;
    // if (IsRightEye) EyeCenter = RightEyeCenter else EyeCenter = LeftEyeCenter
    EyeCenter.xyz = (RightEyeCenter.xyz - LeftEyeCenter.xyz) * input.IsRightEye + LeftEyeCenter.xyz;
    EyeCenter.w = 1;
    // EYE technique is always drawn in worldspace
    precise float3 WorldEyeCenter = float3(dot(EyeCenter.xyzw, v_World4x4[0].xyzw), dot(EyeCenter.xyzw, v_World4x4[1].xyzw), dot(EyeCenter.xyzw, v_World4x4[2].xyzw));
    // direction from vertex to eye center
    vsout.EyeDirectionVec.xyz = normalize(v_VertexPos.xyz - WorldEyeCenter);
#endif

#if defined(PROJECTED_UV)
    vsout.ProjDir.xyz = TextureProj[2].xyz;
#endif

#if defined(MULTI_TEXTURE)
    vsout.BlendWeight0 = input.BlendWeight0;
    float2 LandAdjustedPos = LandBlendParams.zw - v_VertexPos;
    float LandAdjustedPosLen = length(LandAdjustedPos);
    float OffsetLandAdjustedPosLen = saturate(0.000375601 * (9625.6 - LandAdjustedPosLen));
    vsout.BlendWeight1.w = 1 - OffsetLandAdjustedPosLen;
    vsout.BlendWeight1.xyz = input.BlendWeight1.xyz;
#endif

#if defined(MODELSPACENORMALS)
#if defined(SKINNED)
    float3x3 ModelViewMatrix = mul(ViewMatrix, ModelToSkinnedWorldMatrix);
#else
    float3x3 ModelViewMatrix = mul(ViewMatrix, v_World4x4);
#endif
    vsout.ModelViewTransform0 = ModelViewMatrix[0];
    vsout.ModelViewTransform1 = ModelViewMatrix[1];
    vsout.ModelViewTransform2 = ModelViewMatrix[2];
#else
#if defined(DRAW_IN_WORLDSPACE)
    float3x3 TangentModelViewMatrix = mul(ViewMatrix, w_tbn);
#else
    float3x3 ModelViewMatrix = mul(ViewMatrix, v_World4x4);
    float3x3 TangentModelViewMatrix = mul(ModelViewMatrix, tbn);
#endif
    vsout.TangentViewTransform0 = TangentModelViewMatrix[0];
    vsout.TangentViewTransform1 = TangentModelViewMatrix[1];
    vsout.TangentViewTransform2 = TangentModelViewMatrix[2];
#endif

#if defined(DRAW_IN_WORLDSPACE)
    vsout.WorldVertexPos = v_VertexPos;
#else
    vsout.WorldVertexPos = mul(v_World4x4, v_VertexPos);
#endif


#if defined(DRAW_IN_WORLDSPACE)
    precise float4 v_PrevVertexPos = float4(input.VertexPos.xyz, 1);
#else
    // primarily to catch LODLANDSCAPE edited vertex pos
    precise float4 v_PrevVertexPos = float4(v_VertexPos.xyz, 1);
#endif

#if defined(SKINNED)
    float3x4 ModelToSkinnedPreviousWorldMatrix = 0;

    PosAdjustX = float4(-0, 0, -0, -PreviousPosAdjust.x);
    PosAdjustY = float4(-0, 0, -0, -PreviousPosAdjust.y);
    PosAdjustZ = float4(-0, 0, -0, -PreviousPosAdjust.z);

    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.x * float3x4(PreviousBones[boneOffsets.x] + PosAdjustX, PreviousBones[boneOffsets.x + 1] + PosAdjustY, PreviousBones[boneOffsets.x + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.y * float3x4(PreviousBones[boneOffsets.y] + PosAdjustX, PreviousBones[boneOffsets.y + 1] + PosAdjustY, PreviousBones[boneOffsets.y + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.z * float3x4(PreviousBones[boneOffsets.z] + PosAdjustX, PreviousBones[boneOffsets.z + 1] + PosAdjustY, PreviousBones[boneOffsets.z + 2] + PosAdjustZ);
    ModelToSkinnedPreviousWorldMatrix += input.BoneWeights.w * float3x4(PreviousBones[boneOffsets.w] + PosAdjustX, PreviousBones[boneOffsets.w + 1] + PosAdjustY, PreviousBones[boneOffsets.w + 2] + PosAdjustZ);

    vsout.PreviousWorldVertexPos.xyzw =
        float4(dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[0]),
            dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[1]),
            dot(v_PrevVertexPos, ModelToSkinnedPreviousWorldMatrix[2]),
            1);
#else
    vsout.PreviousWorldVertexPos = mul(float4x4(PreviousWorld[0], PreviousWorld[1], PreviousWorld[2], float4(0, 0, 0, 1)), v_PrevVertexPos);
#endif

    vsout.VertexColor = v_VertexColor;
    vsout.FogParam = GetFog(vsout.ProjVertexPos.xyz, FogParam.x, FogParam.y, FogParam.z, FogParam.w, FogNearColor.xyz, FogFarColor.xyz);

    return vsout;
}