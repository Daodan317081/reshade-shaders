/*******************************************************
	ReShade Shader: ColorfulPoster
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#include "Stats.fxh"
#include "Tools.fxh"

#define UI_CATEGORY_POSTERIZATION "Posterization"
#define UI_CATEGORY_PENCILLAYER "Pencil Layer"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_EFFECT "Effect"

/******************************************************************************
	Uniforms
******************************************************************************/

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

////////////////////////// Pencil Layer //////////////////////////
uniform float fUIPencilLayerClipDetails <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Clip Details";
	ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 0.0;

uniform int iUIUseDepthBuffer <
	ui_type = "combo";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Use Depth Buffer Based Outlines";
	ui_tooltip = "Outlines might obstruct Game UI";
	ui_items = "No\0Yes\0Show Depth Buffer\0";
> = 1;

uniform int iUINormalizeChroma <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Normalize Chroma";
	ui_min = 0; ui_max = 1;
> = 1;

uniform int iUIOverrideLumaWeight <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Weight Luma With Average Luma";
	ui_min = 0; ui_max = 1;
> = 1;

uniform int iUIOverrideSaturationWeight <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Weight Saturation With Average Saturation/Current Saturation";
	ui_min = 0; ui_max = 2;
> = 2;

uniform float fUISaturationWeight <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Saturation Weight";
	ui_tooltip = "Reduces the pencil strength\nin areas of high saturation\nDebug -> Saturation Weight";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.3;

uniform float fUILumaWeight <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Luma Weight";
	ui_tooltip = "Reduces the pencil strength\nin bright areas\nDebug -> Luma Weight";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.3;

uniform float fUIOutlineStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Outline Strength";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform float fUIStrengthPencilLayer <
	ui_type = "drag";
	ui_category = UI_CATEGORY_PENCILLAYER;
	ui_label = "Layer Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

////////////////////////// Color //////////////////////////
uniform float fUIColorStrength <
	ui_type = "drag";
	ui_category = "Color";
	ui_label = "Color Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 0.5;

////////////////////////// Debug //////////////////////////
uniform int iUIDebugOverlayPosterizeLevels <
	ui_type = "combo";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "Show Posterization as Curve";
	ui_items = "Off\0On\0";
> = 0;

uniform int iUIDebugMaps <
	ui_type = "combo";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "Show Debug Maps";
	ui_items = "Off\0[POSTERIZATION] Result\0[PENCIL LAYER]: Outlines\0[PENCIL LAYER] Chroma Edges\0[PENCIL LAYER] Saturation Weight\0[PENCIL LAYER] Luma Weight\0[PENCIL LAYER] Overall Weight\0[PENCIL LAYER] Result\0";
> = 0;

////////////////////////// Effect //////////////////////////
uniform float fUIStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_EFFECT;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

/******************************************************************************
	Textures
******************************************************************************/

texture2D texColorfulPosterChroma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterChroma { Texture = texColorfulPosterChroma; };

/******************************************************************************
	Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering chroma to a texture is necessary
void Chroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord,out float3 chroma : SV_Target0) {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	chroma = color - dot(color, LumaCoeff);
	if(iUINormalizeChroma)
		chroma = normalize(chroma);
}

float3 ColorfulPoster_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    
	/*******************************************************
		Get BackBuffer
	*******************************************************/
	float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;

	/*******************************************************
		Calculate chroma and luma; posterize luma
	*******************************************************/
    float luma = dot(backbuffer, LumaCoeff);
    float3 chroma = backbuffer - luma;
	float3 lumaPoster = Tools::Functions::Posterize(luma, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType).rrr;

	/*******************************************************
		Color
	*******************************************************/
	float3 mask, image, colorLayer;

	//Convert RGB to CMYK, set K to 0.0
	float4 backbufferCMYK = Tools::Color::RGBtoCMYK(backbuffer);
	backbufferCMYK.w = 0.0;
	mask = Tools::Color::CMYKtoRGB(backbufferCMYK);
	
	//add chroma and posterized luma
    image = chroma + lumaPoster;

	//Blend with hard light
	image = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));

    //color strength
	colorLayer = lerp(backbuffer, image, fUIColorStrength);

	/*******************************************************
		Create pencil layer
	*******************************************************/
    float3 pencilLayer;
	float3 chromaEdges = dot(Tools::Convolution::Edges(SamplerColorfulPosterChroma, texcoord, CONV_SOBEL, CONV_MAX), 0.5.xxx);
	float saturation = Tools::Color::GetSaturation(backbuffer);

	float satWeight = fUISaturationWeight;
	float lumWeight = fUILumaWeight;

	if(iUIOverrideLumaWeight == 1) {
		lumWeight = tex2Dfetch(shared_SamplerStatsAvgLuma, int4(0, 0, 0, 0)).r;
	}
	if(iUIOverrideSaturationWeight == 1) {
		satWeight = Tools::Color::GetSaturation(tex2Dfetch(shared_SamplerStatsAvgColor, int4(0, 0, 0, 0)).rgb);
	}
	else if(iUIOverrideSaturationWeight == 2) {
		satWeight = saturation;
	}
	
	//Basically the same thing as changing the levels (as in Levels.fx) i guess... 
	chromaEdges = clamp(chromaEdges, fUIPencilLayerClipDetails, 1.0);
	chromaEdges = Tools::Functions::Map(chromaEdges.r, float2(fUIPencilLayerClipDetails, 1.0), FLOAT_RANGE).rrr;

	//Reduce the strength of the pencil layer in (higly) saturated/bright areas (like faces for example)
	float saturationWeight = 1.0 - saturate(pow(saturation, (satWeight) * 4.0));
	float lumaWeight = 1.0 - saturate(pow(luma, (lumWeight) * 4.0));
	float finalWeight = min(saturationWeight, lumaWeight);
	
	chromaEdges *= finalWeight;
	
	//Create outlines based on depth buffer
	float3 outlines = BLACK;
	if(iUIUseDepthBuffer == 1) {
		float depth0 = ReShade::GetLinearizedDepth(texcoord);
		float depth1 = ReShade::GetLinearizedDepth(texcoord + ReShade::PixelSize);
		float depth2 = ReShade::GetLinearizedDepth(texcoord - ReShade::PixelSize);
		float diff1 = abs(depth0 - depth1);
		float diff2 = abs(depth0 - depth2);
		outlines = (diff1 + diff2) < 0.01 ? 0.0.rrr : fUIOutlineStrength.rrr * finalWeight;
	}
	else if(iUIUseDepthBuffer == 2)
		return ReShade::GetLinearizedDepth(texcoord).rrr;

	//Finalize pencil layer
	pencilLayer = saturate(max(chromaEdges, outlines) * fUIStrengthPencilLayer);

	/*******************************************************
		Create result
	*******************************************************/
    float3 result = lerp(colorLayer, BLACK, pencilLayer);

	/*******************************************************
		Show debug stuff
	*******************************************************/
    if(iUIDebugMaps == 1)
        result = lumaPoster;
    else if(iUIDebugMaps == 2)
        result = outlines;
    else if(iUIDebugMaps == 3)
        result = chromaEdges;
    else if(iUIDebugMaps == 4)
        result = saturationWeight;
    else if(iUIDebugMaps == 5)
        result = lumaWeight;
    else if(iUIDebugMaps == 6)
        result = finalWeight;
    else if(iUIDebugMaps == 7)
        result = pencilLayer;

	if(iUIDebugOverlayPosterizeLevels == 1) {
		sctpoint curveStep = Tools::Draw::NewPoint(MAGENTA, 1.0, float2(texcoord.x, 1.0 - Tools::Functions::Posterize(texcoord.x, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType)));
        result = Tools::Draw::Point(result, curveStep, texcoord);
		backbuffer = Tools::Draw::Point(backbuffer, curveStep, texcoord);
	}

	/*******************************************************
		Set overall strength and return
	*******************************************************/
    return lerp(backbuffer, result, fUIStrength);
}

technique ColorfulPoster
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Chroma_PS;
        RenderTarget0 = texColorfulPosterChroma;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = ColorfulPoster_PS;
	}
}