/*******************************************************
	ReShade Shader: LayerMergeTest
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#include "Tools.fxh"

uniform int iUILayerMode <
	ui_type = "combo";
	ui_label = "Layer Mode";
	ui_items = "LAYER_MODE_NORMAL\0LAYER_MODE_MULTIPLY\0LAYER_MODE_DIVIDE\0LAYER_MODE_SCREEN\0LAYER_MODE_OVERLAY\0LAYER_MODE_DODGE\0LAYER_MODE_BURN\0LAYER_MODE_HARDLIGHT\0LAYER_MODE_SOFTLIGHT\0LAYER_MODE_GRAINEXTRACT\0LAYER_MODE_GRAINMERGE\0LAYER_MODE_DIFFERENCE\0LAYER_MODE_ADDITION\0LAYER_MODE_SUBTRACT\0LAYER_MODE_DARKENONLY\0LAYER_MODE_LIGHTENONLY\0";
> = 0;

texture texImage < source = "image.jpg"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerImage { Texture = texImage; };

float3 Final_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 mask = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 image = tex2D(SamplerImage, texcoord).rgb;
    return Tools::Color::LayerMerge(mask, image, iUILayerMode);
}

technique LayerMergeTest
{
    pass {
		VertexShader = PostProcessVS;
		PixelShader = Final_PS;
	}
}