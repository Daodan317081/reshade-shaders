#include "ReShade.fxh"

#define MAX2(v) max(v.x, v.y)
#define MIN2(v) min(v.x, v.y)
#define MAX4(v) max(v.x, max(v.y, max(v.z, v.w)))
#define MIN4(v) min(v.x, min(v.y, min(v.z, v.w)))

float3 MeshEdges_PS(float4 vpos:SV_Position, float2 texcoord:TexCoord):SV_Target {
    float4 pix = float4(ReShade::PixelSize, -ReShade::PixelSize);

    //Get depth of center pixel
    float c = ReShade::GetLinearizedDepth(texcoord);

    //Get depth of surrounding pixels
    float4 d = float4(  ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.w)),
                        ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.y)),
                        ReShade::GetLinearizedDepth(texcoord + float2(pix.x, 0.0)),
                        ReShade::GetLinearizedDepth(texcoord + float2(pix.z, 0.0))   );

    //Normalize values
    float mind = MIN4(d);
    float maxd = MAX4(d);
    float span = max(c, maxd) - min(c, mind) + 0.00001;
    c /= span;
    d /= span;

    //Calculate the distance of the surrounding pixels to the center
    float4 diffs = abs(d - c);

    //Calculate the difference of the distances
    float2 diffs2 = float2(abs(diffs.x - diffs.y), abs(diffs.z - diffs.w));

    return MAX2(diffs2);
}

technique MeshEdges {
    pass {
        VertexShader = PostProcessVS; 
        PixelShader = MeshEdges_PS; 
        /* RenderTarget = BackBuffer */
    }
}