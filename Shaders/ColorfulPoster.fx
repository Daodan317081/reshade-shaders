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
uniform float fUIDiffEdgesStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_EDGES;
	ui_label = "Luma";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform float fUIConvStrength <
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

/******************************************************************************
	Pixel Shader
******************************************************************************/

//Convolution gets currently done with samplers, so rendering chroma to a texture is necessary
void Chroma_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 chroma : SV_Target0) {
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	chroma = color - dot(color, LumaCoeff);
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

	backbufferCMYK.xyz += float3(0.2, -0.1, -0.2);
	backbufferCMYK.w = 0.0;

	mask = Tools::Color::CMYKtoRGB(saturate(backbufferCMYK));
	
	//add chroma and posterized luma
	image = chroma + lumaPoster;

	//Blend with hard light
	colorLayer = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));

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
	float3 outlinesDepthBuffer = (diffNS + diffWE + diffNWSE + diffSWNE);

	if(iUIOutlinesEnableThreshold == 1)
		outlinesDepthBuffer = outlinesDepthBuffer < fUIOutlinesThreshold ? 0.0 : 1.0;

	if(iUIOutlinesFadeWithDistance == 1)
		outlinesDepthBuffer *= (1.0 - depthC);
	else if(iUIOutlinesFadeWithDistance == 2)
		outlinesDepthBuffer *= depthC;
		
	outlinesDepthBuffer *= fUIOutlinesStrength.rrr;

	float3 lumaEdges = Tools::Functions::DiffEdges(ReShade::BackBuffer, texcoord).rrr * fUIDiffEdgesStrength;

	float3 chromaEdges = Tools::Convolution::Edges(SamplerColorfulPosterChroma, texcoord, CONV_SOBEL2, CONV_MAX).rrr * fUIConvStrength;

	//Finalize pencil layer
	float3 pencilLayer = saturate(outlinesDepthBuffer + lumaEdges + chromaEdges);

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
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = ColorfulPoster_PS;
	}
}