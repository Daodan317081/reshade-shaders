/*******************************************************
	ReShade Shader: Adaptive Tint
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/

#include "ReShade.fxh"
#include "Stats.fxh"
#include "Tools.fxh"

#ifndef UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH
	#define UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH 300
#endif

#define UI_CATEGORY_CURVES "Curves"
#define UI_CATEGORY_COLOR "Color"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_GENERAL "General"
#define UI_TOOLTIP_DEBUG "Enable Technique 'AdaptiveTintDebug'\n#define UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH=xyz\nDefault width is 300"

uniform int iUIWhiteLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "White Level Curve (red)";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_items = "Linear: x * (value - y) + z\0Square: x * (value - y)^2 + z\0Cube: x * (value - y)^2 + z\0";
> = 0;

uniform float3 f3UICurveWhiteParam <
	ui_type = "drag";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Curve Parameters";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(1.0, 0.0, 0.0);

uniform int iUIBlackLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Black Level Curve (cyan)";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_items = "Linear: x * (value - y) + z\0Square: x * (value - y)^2 + z\0Cube: x * (value - y)^3 + z\0";
> = 0;

uniform float3 f3UICurveBlackParam <
	ui_type = "drag";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Curve Parameters";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(0.2, 0.0, 0.0);

uniform float fUIColorTempScaling <
	ui_type = "drag";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Color Temperature Scaling";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = 1.0; ui_max = 10.0;
	ui_step = 0.01;
> = 2.0;

uniform float fUISaturation <
	ui_type = "drag";
	ui_label = "Saturation";
	ui_category = UI_CATEGORY_COLOR;
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float3 fUITintWarm <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "Warm Tint";
> = float3(0.04, 0.04, 0.02);

uniform float3 fUITintCold <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "Cold Tint";
> = float3(0.02, 0.04, 0.04);

uniform int iUIDebug <
	ui_type = "combo";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "Show Tint Layer";
	ui_items = "Off\0Tint\0Factor\0";
> = 0;

uniform float fUIDebugLineWidth <
	ui_type = "drag";
	ui_category = UI_CATEGORY_DEBUG;
	ui_min = 0.0; ui_max = 10.0;
	ui_step = 0.1;
> = 5.0;

uniform int2 i2UIDebugStatsWindowPos <
	ui_type = "drag";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "Stats Window Position";
	ui_min = 0; ui_max = BUFFER_WIDTH;
	ui_step = 1;
> = int2(0, 0);

uniform float fUIStrength <
	ui_type = "drag";
	ui_category = UI_CATEGORY_GENERAL;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

/*******************************************************
	Debug image
*******************************************************/
texture2D texAdaptiveTintDebug { Width = UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH; Height = UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH * ((float)BUFFER_HEIGHT/(float)BUFFER_WIDTH); Format = RGBA8; };
sampler SamplerAdaptiveTintDebug { Texture = texAdaptiveTintDebug; };

/*******************************************************
	Checkerboard
*******************************************************/
texture2D texAlphaCheckerboard < source = "alpha-checkerboard.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerAlphaCheckerboard { Texture = texAlphaCheckerboard; };

/*******************************************************
	Functions
*******************************************************/
float2 CalculateLevels(float avgLuma) {
	float2 level = float2(0.0, 0.0);

	if(iUIBlackLevelFormula == 2)
		level.x = f3UICurveBlackParam.x * pow(avgLuma - f3UICurveBlackParam.y, 3) + f3UICurveBlackParam.z;
	else if(iUIBlackLevelFormula == 1)
		level.x = f3UICurveBlackParam.x * pow(avgLuma - f3UICurveBlackParam.y, 2) + f3UICurveBlackParam.z;
	else
		level.x = f3UICurveBlackParam.x * (avgLuma - f3UICurveBlackParam.y) + f3UICurveBlackParam.z;
	
	if(iUIWhiteLevelFormula == 2)
		level.y = f3UICurveWhiteParam.x * pow(avgLuma - f3UICurveWhiteParam.y, 3) + f3UICurveWhiteParam.z;
	else if(iUIWhiteLevelFormula == 1)
		level.y = f3UICurveWhiteParam.x * pow(avgLuma - f3UICurveWhiteParam.y, 2) + f3UICurveWhiteParam.z;
	else
		level.y = f3UICurveWhiteParam.x * (avgLuma - f3UICurveWhiteParam.y) + f3UICurveWhiteParam.z;

	return saturate(level);
}

float GetColorTemp(float2 texcoord) {
	float colorTemp = tex2D(shared_SamplerStatsAvgColorTemp, 0.5.xx).x;
	return Tools::Functions::Map(colorTemp * fUIColorTempScaling, YIQ_I_RANGE, FLOAT_RANGE);
}

/*******************************************************
	Main Shader
*******************************************************/
float3 AdaptiveTint_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	/*******************************************************
		Get BackBuffer and both LUTs
	*******************************************************/
	float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 lutWarm = fUITintWarm * backbuffer;
	float3 lutCold = fUITintCold * backbuffer;

	/*******************************************************
		Interpolate between both LUTs
	*******************************************************/
	float colorTemp = GetColorTemp(texcoord);
	float3 tint = lerp(lutCold, lutWarm, colorTemp);

	/*******************************************************
		Apply black and white levels to luma, desaturate
	*******************************************************/
	float3 luma   = dot(backbuffer, LumaCoeff).rrr;
	float2 levels = CalculateLevels(tex2D(shared_SamplerStatsAvgLuma, 0.5.xx).x);
	float3 factor = Tools::Functions::Level(luma.r, levels.x, levels.y).rrr;
	float3 result = lerp(tint, lerp(luma, backbuffer, fUISaturation + 1.0), factor);

	/*******************************************************
		Debug
	*******************************************************/
	if(iUIDebug == 1) //tint
		return lerp(tint, tex2D(SamplerAlphaCheckerboard, texcoord).rgb, factor);
	if(iUIDebug == 2) //factor
		return lerp(BLACK, WHITE, factor);

	return lerp(backbuffer, result, fUIStrength);
}

/*******************************************************
	Generate small image for shader debug/setup
*******************************************************/

void Show_Stats_PS(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float3 result : SV_Target0) {	
	float2 texSize = (float2)tex2Dsize(SamplerAdaptiveTintDebug, 0);
	float2 margin = float2(0.02, 0.05);
	float2 offset = fUIDebugLineWidth;

	float3 originalBackBuffer = tex2D(shared_SamplerStats, texcoord).rgb;
	float3 originalLuma = dot(originalBackBuffer, LumaCoeff).xxx;

	float3 avgColor = tex2D(shared_SamplerStatsAvgColor, 0.5.xx).rgb;
	float avgLuma = tex2D(shared_SamplerStatsAvgLuma, 0.5.xx).r;
	float2 levels = CalculateLevels(avgLuma);
	float3 factor = saturate(Tools::Functions::Level(avgLuma, levels.x, levels.y).rrr);
	
	float2 curves = CalculateLevels(texcoord.x);
	float3 localFactor = saturate(Tools::Functions::Level(originalLuma.r, levels.x, levels.y).rrr);

	sctpoint background = Tools::Draw::NewPoint(lerp(BLACK, WHITE, localFactor), offset, texcoord);
	
	float3 warm = Tools::Color::YIQtoRGB(float3(0.5, YIQ_I_RANGE.y, 0.0));
	float3 cold = Tools::Color::YIQtoRGB(float3(0.5, YIQ_I_RANGE.x, 0.0));

	sctpoint scaleTemp			= Tools::Draw::NewPoint(lerp(cold, warm, texcoord.y / (1.0 - margin.y)), offset,
														float2(texcoord.x < margin.x ? texcoord.x : -1,	texcoord.y < 1.0 - margin.y ? texcoord.y : -1));
	sctpoint markerTemp 		= Tools::Draw::NewPoint(BLACK, offset,
														float2(texcoord.x < margin.x ? texcoord.x : -1,	GetColorTemp(texcoord)));
	sctpoint scaleAvgColor 		= Tools::Draw::NewPoint(avgColor, offset,
														float2(texcoord.x < margin.x ? texcoord.x : -1,	texcoord.y > 1.0 - margin.y ? texcoord.y : -1));
	sctpoint scaleLuma 			= Tools::Draw::NewPoint(lerp(1.0, 0.0, (1.0 - texcoord.x) / (1.0 - margin.x)).rrr,	offset,
														float2(texcoord.x > margin.x ? texcoord.x : -1,	texcoord.y > 1.0 - margin.y ? texcoord.y : -1));
	sctpoint markerAvgLuma 		= Tools::Draw::NewPoint(MAGENTA, offset,
														float2((avgLuma + margin.x) / (1.0 - margin.x),	texcoord.y > 1.0 - margin.y ? texcoord.y : -1));
	sctpoint markerLevelWhite 	= Tools::Draw::NewPoint(RED, offset,
														float2((levels.y + margin.x) / (1.0 - margin.x),	texcoord.y > 1.0 - margin.y ? texcoord.y : -1));
	sctpoint markerLevelBlack 	= Tools::Draw::NewPoint(CYAN, offset,
														float2((levels.x + margin.x) / (1.0 - margin.x),	texcoord.y > 1.0 - margin.y ? texcoord.y : -1));
	sctpoint curveWhite 		= Tools::Draw::NewPoint(RED, offset,
														float2(texcoord.x, 1.0 - curves.y));
	sctpoint curveBlack 		= Tools::Draw::NewPoint(CYAN, offset,
														float2(texcoord.x, 1.0 - curves.x));

	result = Tools::Draw::Point(BLACK,	background,			texcoord);
	result = Tools::Draw::Point(result,	scaleTemp,			texcoord);
	result = Tools::Draw::Point(result,	scaleAvgColor,		texcoord);
	result = Tools::Draw::Point(result,	scaleLuma,			texcoord);
	result = Tools::Draw::Point(result,	markerAvgLuma,		texcoord);
	result = Tools::Draw::Point(result,	markerLevelWhite,	texcoord);
	result = Tools::Draw::Point(result,	markerLevelBlack,	texcoord);
	result = Tools::Draw::Point(result,	markerTemp,			texcoord);
	result = Tools::Draw::Point(result,	curveWhite,			texcoord);
	result = Tools::Draw::Point(result,	curveBlack,			texcoord);
}

/*******************************************************
	Draw Debugimage on backbuffer
*******************************************************/

float3 AdaptiveTint_Merge_Stats_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;
	int2 texsize = tex2Dsize(SamplerAdaptiveTintDebug, 0);
	int x = clamp(i2UIDebugStatsWindowPos.x, 0, BUFFER_WIDTH - texsize.x);
	int y = clamp(i2UIDebugStatsWindowPos.y, 0, BUFFER_HEIGHT - texsize.y);
	return Tools::Draw::OverlaySampler(backbuffer, SamplerAdaptiveTintDebug, 1.0, texcoord, int2(x,y), 1.0);
}

technique AdaptiveTint
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AdaptiveTint_PS;
	}
}


technique AdaptiveTintDebug {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Show_Stats_PS;
		RenderTarget0 = texAdaptiveTintDebug;
	}
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AdaptiveTint_Merge_Stats_PS;
	}
}