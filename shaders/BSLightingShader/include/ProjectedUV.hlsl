void ApplyProjectedUV(inout psInternalData data)
{
    // ProjectedUVParams.z is probably UV tiling scale or something like that from the lighting property
    float2 projectedUVCoords = data.input.TexCoords.zw * ProjectedUVParams.z;
    float projUVNoiseSample = Sample2D(ProjectedNoise, projectedUVCoords.xy).x;
    float3 projDirN = normalize(data.input.ProjectionDir.xyz);
    float NdotP = dot(data.commonSpaceNormal.xyz, projDirN.xyz);
    
    float projDiffuseIntensity = NdotP * data.input.VertexColour.w - ProjectedUVParams.w - (ProjectedUVParams.x * projUVNoiseSample);
    
    float3 cb_ProjectedUVColour = ProjectedUVParams2.xyz;
    float gs_fProjectedUVDiffuseNormalTilingScale = ProjectedUVParams3.x;
    float gs_fProjectedUVNormalDetailTilingScale = ProjectedUVParams3.y;
    float cb_EnableProjectedUVNormals = ProjectedUVParams3.w;
    
    if (cb_EnableProjectedUVNormals > 0.5)
    {
        float3 projectedNormalSample = Sample2D(ProjectedNormal, gs_fProjectedUVDiffuseNormalTilingScale * projectedUVCoords).xyz;
        float3 projectedNormal = projectedNormalSample * 2 - 1;
        float3 projectedNormalDetailSample = Sample2D(ProjectedNormalDetail, gs_fProjectedUVNormalDetailTilingScale * projectedUVCoords).xyz;

        float3 projectedNormalCombined = projectedNormalDetailSample * 2 + float3(projectedNormal.x, projectedNormal.y, -1);
        projectedNormalCombined.xy = projectedNormalCombined.xy + float2(-1, -1);
        projectedNormalCombined.z = projectedNormalCombined.z * projectedNormal.z;

        float3 projectedNormalCombinedN = normalize(projectedNormalCombined);

        float3 projectedDiffuseSample = Sample2D(ProjectedDiffuse, gs_fProjectedUVDiffuseNormalTilingScale * projectedUVCoords).xyz;

        float projDiffuseIntensityInterpolation = smoothstep(-0.100000, 0.100000, projDiffuseIntensity);

        // note that this only modifies the original normal, not the common space one that is used for lighting calculation
        // it ends up only being used later on for the view space normal used for the normal map output which is used for later image space shaders
        // unsure if this is a bug
        data.normal.xyz = lerp(data.normal.xyz, projectedNormalCombinedN.xyz, projDiffuseIntensityInterpolation);
        data.diffuseColour.xyz = lerp(data.diffuseColour, projectedDiffuseSample * cb_ProjectedUVColour, projDiffuseIntensityInterpolation);
    }
    else
    {
        if (projDiffuseIntensity > 0)
        {
            data.diffuseColour.xyz = cb_ProjectedUVColour.xyz;
        }

    }
}