float3 GetBackLighting(float3 a_lightDirection, float3 a_lightColour, float3 a_backMask, float3 a_Normal)
{
	float backIntensity = dot(a_Normal, -a_lightDirection);

	return a_lightColour * a_backMask * backIntensity;
}

void GetBacklightMask(inout psInternalData data)
{
    data.backlightMask = Sample2D(BackLightMask, data.input.TexCoords.xy).xyz;
}