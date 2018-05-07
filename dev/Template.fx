#include "ReShade.fxh"
#include "../Shaders/Tools.fxh"

/******************************************************************************
	Uniforms
******************************************************************************/
#define UI_CATEGORY_POSTERIZATION "Posterization Luma"
#define UI_CATEGORY_POSTERIZATION2 "Posterization Hue"
////////////////////////// Posterization //////////////////////////
uniform int iUILumaLevels <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Luma Posterize Levels";
	ui_min = 1; ui_max = 20;
> = 16;

uniform int iUIStepType <
	ui_type = "combo";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Curve Type";
	ui_items = "Linear\0Smoothstep\0Logistic\0";
> = 2;

uniform float fUIStepContinuity <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Continuity";
    ui_tooltip = "Broken up <-> Connected";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.5;

uniform float fUISlope <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Slope Logistic Curve";
	ui_min = 0.0; ui_max = 40.0;
	ui_step = 0.1;
> = 20.0;

uniform float fUIXOffset <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "x-offset";
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float fUIYOffset <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "y-offset";
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform int iUILumaLevels2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "Luma Posterize Levels";
	ui_min = 1; ui_max = 20;
> = 16;

uniform int iUIStepType2 <
	ui_type = "combo";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "Curve Type";
	ui_items = "Linear\0Smoothstep\0Logistic\0";
> = 2;

uniform float fUIStepContinuity2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "Continuity";
    ui_tooltip = "Broken up <-> Connected";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.5;

uniform float fUISlope2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "Slope Logistic Curve";
	ui_min = 0.0; ui_max = 40.0;
	ui_step = 0.1;
> = 20.0;

uniform float fUIXOffset2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "x-offset";
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float fUIYOffset2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION2;
	ui_label = "y-offset";
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform int iUIDebug <
	ui_type = "combo";
	ui_category = "Debug";
	ui_label = "Debug";
	ui_items = "None\0Saturation\0saturation poster\0luma\0luma poster\0max(sat, luma)\0";
> = 0;

////////////////////////// Effect //////////////////////////
uniform float fUIStrength <
	ui_type = "drag";
	ui_category = "Effect";
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform int iUIDebugOverlayPosterizeLevels <
	ui_type = "combo";
	ui_label = "Show Posterization as Curve";
	ui_items = "Off\0On\0";
> = 0;

/******************************************************************************
	Textures
******************************************************************************/

texture2D texTemplate { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerTemplate { Texture = texTemplate; };

/******************************************************************************
	Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering chroma to a texture is necessary
void Texture_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord,out float3 color : SV_Target0) {
    color = tex2D(ReShade::BackBuffer, texcoord).rgb;
}

float3 Template_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    
	float3 color = tex2D(SamplerTemplate, texcoord).rgb;
	float3 saturation = Tools::Color::GetSaturation(color);
	float3 saturation_poster = Tools::Functions::Posterize(saturation.r + fUIYOffset, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType).rrr + fUIXOffset;
    float3 luma = dot(color, float3(0.2126, 0.7151, 0.0721));
	float3 luma_poster = Tools::Functions::Posterize(luma.r + fUIYOffset2, iUILumaLevels2, fUIStepContinuity2, fUISlope2, iUIStepType2).rrr + fUIXOffset2;

	float3 result;

	if(iUIDebug == 1)
		result = saturation;
	else if(iUIDebug == 2)
		result = saturation_poster;
	else if(iUIDebug == 3)
		result = luma;
	else if(iUIDebug == 4)
		result = luma_poster;
	else if(iUIDebug == 5)
		result = max(saturation.x, luma.x).rrr;

	if(iUIDebugOverlayPosterizeLevels == 1) {
		sctpoint curveStep = Tools::Draw::NewPoint(MAGENTA, 1.0, float2(texcoord.x, 1.0 - Tools::Functions::Posterize(texcoord.x + fUIYOffset, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType) + fUIXOffset));
        result = Tools::Draw::Point(result, curveStep, texcoord);
		sctpoint curveStep2 = Tools::Draw::NewPoint(BLUE, 1.0, float2(texcoord.x, 1.0 - Tools::Functions::Posterize(texcoord.x + fUIYOffset2, iUILumaLevels2, fUIStepContinuity2, fUISlope2, iUIStepType2) + fUIXOffset2));
        result = Tools::Draw::Point(result, curveStep2, texcoord);
	}

	sctpoint on = Tools::Draw::NewPoint(BLUE, 1.0, float2(texcoord.x < 20 * ReShade::PixelSize.x ? texcoord.x : -1, texcoord.y < 20 * ReShade::PixelSize.y ? texcoord.y : -1));
    result = Tools::Draw::Point(result, on, texcoord);

    return lerp(color, result, fUIStrength);
}

technique Template
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Texture_PS;
        RenderTarget0 = texTemplate;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Template_PS;
	}
}