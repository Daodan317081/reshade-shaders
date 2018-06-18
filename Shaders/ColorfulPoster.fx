/*******************************************************
	ReShade Shader: ColorfulPoster
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#include "Tools.fxh"

#define UI_CATEGORY_POSTERIZATION "Posterization"
#define UI_CATEGORY_OUTLINES "Outlines (needs depth buffer)"
#define UI_CATEGORY_EDGES "Edge Detection Weight"
#define UI_CATEGORY_COLOR "Color"
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

//Outlines
uniform int iUIOutlinesEnableThreshold <
	ui_type = "combo";
	ui_category = UI_CATEGORY_OUTLINES;
	ui_label = "Enable Threshold";
	ui_items = "Off\0On\0";
> = 0;

uniform float fUIOutlinesThreshold <
	ui_type = "drag";
	ui_category = UI_CATEGORY_OUTLINES;
	ui_label = "Threshold";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform int iUIOutlinesFadeWithDistance <
	ui_type = "combo";
	ui_category = UI_CATEGORY_OUTLINES;
	ui_label = "Distance Weight";
	ui_tooltip = "Outlines fade with increasing distance (or inverse)";
	ui_items = "No\0Decrease\0Increase\0";
> = 0;

uniform float fUIOutlinesStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_OUTLINES;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

//Edge Detection
#ifdef COLORFUL_POSTER_EXTENDED_CONTROLS
uniform int iUILumaKernel <
	ui_type = "combo";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Luma edge detection kernel";
	ui_items = "Sobel\0Prewitt\0Scharr\0Sobel 2\0Diff-Edges\0";
> = 4;
/* Doesn't work in d3d9
uniform int iUILumaEdgeMergeMethod <
	ui_type = "combo";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Luma edges merge method";
	ui_items = "Multiplication\0Dotproduct\0X\0Y\0Addition\0Maximum\0";
> = 5;
*/
#endif

uniform float fUILumaEdgesStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Luma";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#ifdef COLORFUL_POSTER_EXTENDED_CONTROLS
uniform int iUIChromaKernel <
	ui_type = "combo";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Chroma edge detection kernel";
	ui_items = "Sobel\0Prewitt\0Scharr\0Sobel 2\0Diff-Edges\0";
> = 3;
/* Doesn't work in d3d9
uniform int iUIChromaEdgeMergeMethod <
	ui_type = "combo";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Chroma edges merge method";
	ui_items = "Multiplication\0Dotproduct\0X\0Y\0Addition\0Maximum\0";
> = 5;
*/
#endif

uniform float fUIChromaEdgesStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Chroma";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

////////////////////////// Color //////////////////////////

uniform float3 fUILineColor <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
	ui_label = "Line Color";
> = float3(0.0, 0.0, 0.0);

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
	ui_items = "Off\0Posterized Luma\0Depth Buffer Outlines\0Luma Edges\0Chroma Edges\0Pencil Layer\0Show Depth Buffer\0";
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
texture2D texColorfulPosterLuma { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerColorfulPosterLuma { Texture = texColorfulPosterLuma; };

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

	//Convert RGB to CMYK, add cyan tint, set K to 0.0
	float4 backbufferCMYK = Tools::Color::RGBtoCMYK(backbuffer);
	backbufferCMYK.xyz += float3(0.2, -0.1, -0.2);
	backbufferCMYK.w = 0.0;

	//Convert back to RGB
	mask = Tools::Color::CMYKtoRGB(saturate(backbufferCMYK));
	
	//add chroma and posterized luma
	image = chroma + lumaPoster;

	//Blend with hard light
	colorLayer = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));

	/*******************************************************
		Create PencilLayer
	*******************************************************/
	float3 lumaEdges, chromaEdges, pencilLayer;

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
	float3 outlinesDepthBuffer = (diffNS + diffWE + diffNWSE + diffSWNE);

	if(iUIOutlinesEnableThreshold == 1)
		outlinesDepthBuffer = outlinesDepthBuffer < fUIOutlinesThreshold ? 0.0 : 1.0;

	if(iUIOutlinesFadeWithDistance == 1)
		outlinesDepthBuffer *= (1.0 - depthC);
	else if(iUIOutlinesFadeWithDistance == 2)
		outlinesDepthBuffer *= depthC;
		
	outlinesDepthBuffer *= fUIOutlinesStrength.rrr;

#ifdef COLORFUL_POSTER_EXTENDED_CONTROLS
	if(iUILumaKernel != 4)
		lumaEdges = Tools::Convolution::Edges(SamplerColorfulPosterLuma, texcoord, iUILumaKernel, CONV_MAX).rrr * fUILumaEdgesStrength;
	else
		lumaEdges = Tools::Functions::DiffEdges(SamplerColorfulPosterLuma, texcoord).rrr * fUILumaEdgesStrength;

	if(iUIChromaKernel != 4)
		chromaEdges = Tools::Convolution::Edges(SamplerColorfulPosterChroma, texcoord, iUIChromaKernel, CONV_MAX).rrr * fUIChromaEdgesStrength;
	else
		chromaEdges = Tools::Functions::DiffEdges(SamplerColorfulPosterChroma, texcoord).rrr * fUILumaEdgesStrength;
#else
	lumaEdges = Tools::Functions::DiffEdges(SamplerColorfulPosterLuma, texcoord).rrr * fUILumaEdgesStrength;
	chromaEdges = Tools::Convolution::Edges(SamplerColorfulPosterChroma, texcoord, CONV_SOBEL2, CONV_MAX).rrr * fUIChromaEdgesStrength;
#endif

	//Finalize pencil layer
	pencilLayer = saturate(outlinesDepthBuffer + lumaEdges + chromaEdges);

	/*******************************************************
		Create result
	*******************************************************/
	float3 result = lerp(colorLayer, fUILineColor, pencilLayer);

	/*******************************************************
		Show debug stuff
	*******************************************************/
	if(iUIDebugMaps == 1)
		result = lumaPoster;
	else if(iUIDebugMaps == 2)
		result = lerp(1.0.rrr, fUILineColor, outlinesDepthBuffer);
	else if(iUIDebugMaps == 3)
		result = lerp(1.0.rrr, fUILineColor, lumaEdges);
	else if(iUIDebugMaps == 4)
		result = lerp(1.0.rrr, fUILineColor, chromaEdges);
	else if(iUIDebugMaps == 5)
		result = lerp(1.0.rrr, fUILineColor, pencilLayer);
	else if(iUIDebugMaps == 6)
		return ReShade::GetLinearizedDepth(texcoord).rrr;

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