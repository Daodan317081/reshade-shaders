#include "ReShade.fxh"

uniform int iUIOutlinesEnableThreshold <
	ui_type = "combo";
	ui_label = "Enable Threshold";
	ui_items = "Off\0On\0";
> = 0;

uniform float fUIOutlinesThreshold <
	ui_type = "drag";
	ui_label = "Threshold";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform int iUIOutlinesFadeWithDistance <
	ui_type = "combo";
	ui_label = "Distance Weight";
	ui_tooltip = "Outlines fade with increasing distance (or inverse)";
	ui_items = "No\0Decrease\0Increase\0";
> = 0;

float3 Outlines_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	float depthC = ReShade::GetLinearizedDepth(texcoord);
	float depthN = ReShade::GetLinearizedDepth(texcoord + float2(0.0, -ReShade::PixelSize.y));
	float depthNE = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, -ReShade::PixelSize.y));
	float depthE = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, 0.0));
	float depthSE = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, ReShade::PixelSize.y));
	float depthS = ReShade::GetLinearizedDepth(texcoord + float2(0.0, ReShade::PixelSize.y));
	float depthSW = ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, ReShade::PixelSize.y));
	float depthW = ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, 0.0));
	float depthNW = ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, -ReShade::PixelSize.y));

	float diffNS = abs(depthN - depthS);
	float diffWE = abs(depthW - depthE);
	float diffNWSE = abs(depthNW - depthSE);
	float diffSWNE = abs(depthSW - depthNE);

	float outlines = (diffNS + diffWE + diffNWSE + diffSWNE);

	if(iUIOutlinesEnableThreshold == 1)
		outlines = outlines < fUIOutlinesThreshold ? 0.0 : 1.0;

	if(iUIOutlinesFadeWithDistance == 1)
		outlines *= (1.0 - depthC);
	else if(iUIOutlinesFadeWithDistance == 2)
		outlines *= depthC;

	return outlines;
}

technique Outlines
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Outlines_PS;
	}
}