#include "ReShade.fxh"

uniform int iUIOutlinesFadeWithDistance <
	ui_type = "combo";
	ui_label = "Distance Weight";
	ui_tooltip = "Outlines fade with increasing distance (or inverse)";
	ui_items = "No\0Decrease\0Increase\0";
> = 0;

float3 Outlines_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	return Tools::Functions::GetDepthBufferOutlines(texcoord, iUIOutlinesFadeWithDistance);
}

technique Outlines
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Outlines_PS;
	}
}