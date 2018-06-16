#include "ReShade.fxh"


/******************************************************************************
	Uniforms
******************************************************************************/

////////////////////////// Effect //////////////////////////
#ifdef ASPECT_RATIO_FLOAT
uniform float fUIAspectRatio <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 20.0;
	ui_step = 0.01;
> = 1.0;
#else
uniform int2 iUIAspectRatio <
	ui_type = "drag";
	ui_min = 0; ui_max = 20;
> = int2(16, 9);
#endif

uniform int iUIGridFrations <
	ui_type = "drag";
	ui_min = 1; ui_max = 5;
> = 3;

uniform float4 UIGridColor <
	ui_type = "color";
    ui_label = "Grid Color";
> = float4(0.0, 0.0, 0.0, 1.0);

/******************************************************************************
	Pixel Shader
******************************************************************************/

float3 AspectRatioComposition_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 retVal = color;

	float userAspectRatio;

	#ifdef ASPECT_RATIO_FLOAT
	userAspectRatio = fUIAspectRatio;
	#else
	userAspectRatio = (float)iUIAspectRatio.x / (float)iUIAspectRatio.y;
	#endif

	float borderSize, fractionWidth;

	if(userAspectRatio < ReShade::AspectRatio)
	{
		borderSize = (BUFFER_WIDTH - BUFFER_HEIGHT * userAspectRatio) / 2.0;
		fractionWidth = (BUFFER_WIDTH - 2 * borderSize) / iUIGridFrations;
		
		if(vpos.x < borderSize || vpos.x > (BUFFER_WIDTH - borderSize))
			retVal = UIGridColor.rgb;

		if( (vpos.y % (BUFFER_HEIGHT / iUIGridFrations)) < 1)
			retVal = UIGridColor.rgb;

		if( ((vpos.x - borderSize) % fractionWidth) < 1)
			retVal = UIGridColor.rgb;		
	}
	else
	{
		borderSize = (BUFFER_HEIGHT - BUFFER_WIDTH / userAspectRatio) / 2.0;
		fractionWidth = (BUFFER_HEIGHT - 2 * borderSize) / iUIGridFrations;

		if(vpos.y < borderSize || vpos.y > (BUFFER_HEIGHT - borderSize))
			retVal = UIGridColor.rgb;

		if( (vpos.x % (BUFFER_WIDTH / iUIGridFrations)) < 1)
			retVal = UIGridColor.rgb;
			
		if( ((vpos.y - borderSize) % fractionWidth) < 1)
			retVal = UIGridColor.rgb;	
	}

    return lerp(color, retVal, UIGridColor.w);
}

technique AspectRatioComposition
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AspectRatioComposition_PS;
	}
}