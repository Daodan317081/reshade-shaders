/*******************************************************
	ReShade Shader: ColorfulPoster
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#include "Tools.fxh"

#define UI_CATEGORY_POSTERIZATION "Posterization"
#define UI_CATEGORY_OUTLINES "Outlines"
#define UI_CATEGORY_DIFFEDGES "Diff Edges"
#define UI_CATEGORY_CONVOLUTIONSETTINGS "Convolution Settings"
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
> = 8;

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
> = 1.0;

uniform float fUISlope <
	ui_type = "drag";
	ui_category = UI_CATEGORY_POSTERIZATION;
	ui_label = "Slope Logistic Curve";
	ui_min = 0.0; ui_max = 40.0;
	ui_step = 0.1;
> = 10.0;

////////////////////////// Pencil Layer //////////////////////////

uniform float fUIStrengthOutlinesDepthBuffer <
	ui_type = "drag";
	ui_category = UI_CATEGORY_OUTLINES;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform float fUIStrengthDiffEdges <
	ui_type = "drag";
	ui_category = UI_CATEGORY_DIFFEDGES;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform int iUIConvSource <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CONVOLUTIONSETTINGS;
	ui_label = "Source";
	ui_items = "Color\0Luma\0Chroma\0";
> = 2;

uniform int iUIEdgeType <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CONVOLUTIONSETTINGS;
	ui_label = "Kernel Type";
	ui_items = "CONV_SOBEL\0CONV_PREWITT\0CONV_SCHARR\0CONV_SOBEL2\0";
> = 3;

uniform int iUIEdgeMergeMethod <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CONVOLUTIONSETTINGS;
	ui_label = "Merge Method";
	ui_items = "CONV_MUL\0CONV_DOT\0CONV_X\0CONV_Y\0CONV_ADD\0CONV_MAX\0";
> = 5;

uniform float fUIStrengthPencilLayer2 <
	ui_type = "drag";
	ui_category = UI_CATEGORY_CONVOLUTIONSETTINGS;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 0.5;

////////////////////////// Color //////////////////////////

uniform int iUITint <
	ui_type = "combo";
	ui_category = "Color";
	ui_label = "Tint";
	ui_items = "Neutral\0Cyan\0Magenta\0Yellow\0";
> = 0;

uniform float fUIColorStrength <
	ui_type = "drag";
	ui_category = "Color";
	ui_label = "Strength";
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
	ui_items = "Off\0[POSTERIZATION] Result\0[PENCIL LAYER]: Outlines\0[PENCIL LAYER] Diff Edges\0[PENCIL LAYER] Convolution\0[PENCIL LAYER] Result\0";
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

texture2D texColorfulPosterLuma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterLuma { Texture = texColorfulPosterLuma; };

texture2D texColorfulPosterChroma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterChroma { Texture = texColorfulPosterChroma; };

/******************************************************************************
	Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering chroma to a texture is necessary
void Chroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 chroma : SV_Target0, out float3 luma : SV_Target1) {
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	luma = dot(color, LumaCoeff);
	chroma = color - luma;
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

	if(iUITint == 1)
		backbufferCMYK.xyz += float3(0.2, -0.1, -0.2);
	else if(iUITint == 2)
		backbufferCMYK.xyz += float3(-0.1, 0.2, -0.1);
	else if(iUITint == 3)
		backbufferCMYK.xyz += float3(-0.1, -0.1, 0.4);

	mask = Tools::Color::CMYKtoRGB(saturate(backbufferCMYK));
	
	//add chroma and posterized luma
	image = chroma + lumaPoster;

	//Blend with hard light
	image = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));

	//color strength
	colorLayer = lerp(backbuffer, image, fUIColorStrength);

	/*******************************************************
		Create PencilLayer
	*******************************************************/
	float depthC =  ReShade::GetLinearizedDepth(texcoord);
	float depthN =  ReShade::GetLinearizedDepth(texcoord + float2(0.0, -ReShade::PixelSize.y));
	float depthNE = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, -ReShade::PixelSize.y));
	float depthE =  ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, 0.0));
	float depthSE = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, ReShade::PixelSize.y));
	float depthS =  ReShade::GetLinearizedDepth(texcoord + float2(0.0, ReShade::PixelSize.y));
	float depthSW = ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, ReShade::PixelSize.y));
	float depthW =  ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, 0.0));
	float depthNW = ReShade::GetLinearizedDepth(texcoord + float2(-ReShade::PixelSize.x, -ReShade::PixelSize.y));
	float diffNS = abs(depthN - depthS);
	float diffWE = abs(depthW - depthE);
	float diffNWSE = abs(depthNW - depthSE);
	float diffSWNE = abs(depthSW - depthNE);
	float3 outlinesDepthBuffer = (diffNS + diffWE + diffNWSE + diffSWNE) * (1.0 - depthC) * fUIStrengthOutlinesDepthBuffer.rrr;

	float3 pencilLayer1 = Tools::Functions::DiffEdges(ReShade::BackBuffer, texcoord).rrr * fUIStrengthDiffEdges;

	float3 pencilLayer2;
	
	if(iUIConvSource == 1)
		pencilLayer2 = Tools::Convolution::Edges(SamplerColorfulPosterLuma, texcoord, iUIEdgeType, iUIEdgeMergeMethod).rrr * fUIStrengthPencilLayer2;
	else if(iUIConvSource == 2)
		pencilLayer2 = Tools::Convolution::Edges(SamplerColorfulPosterChroma, texcoord, iUIEdgeType, iUIEdgeMergeMethod).rrr * fUIStrengthPencilLayer2;
	else
		pencilLayer2 = Tools::Convolution::Edges(ReShade::BackBuffer, texcoord, iUIEdgeType, iUIEdgeMergeMethod).rrr * fUIStrengthPencilLayer2;

	//Finalize pencil layer
	float3 pencilLayer = saturate(outlinesDepthBuffer + pencilLayer1 + pencilLayer2);

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
		result = outlinesDepthBuffer;
	else if(iUIDebugMaps == 3)
		result = pencilLayer1;
	else if(iUIDebugMaps == 4)
		result = pencilLayer2;
	else if(iUIDebugMaps == 5)
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
		RenderTarget1 = texColorfulPosterLuma;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = ColorfulPoster_PS;
	}
}