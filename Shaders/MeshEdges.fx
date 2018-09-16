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
    float4 depthEven = float4(  ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.w)),
                                ReShade::GetLinearizedDepth(texcoord + float2(0.0, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.x, 0.0)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, 0.0))   );

    float4 depthOdd  = float4(  ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.w)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.x, pix.y)),
                                ReShade::GetLinearizedDepth(texcoord + float2(pix.z, pix.w)) );
    
    //Normalize values
    float2 mind = float2(MIN4(depthEven), MIN4(depthOdd));
    float2 maxd = float2(MAX4(depthEven), MAX4(depthOdd));
    float span = MAX2(maxd) - MIN2(mind) + 0.00001;
    c /= span;
    depthEven /= span;
    depthOdd /= span;
    //Calculate the distance of the surrounding pixels to the center
    float4 diffsEven = abs(depthEven - c);
    float4 diffsOdd = abs(depthOdd - c);
    //Calculate the difference of the distances
    float2 retVal = float2( max(abs(diffsEven.x - diffsEven.y), abs(diffsEven.z - diffsEven.w)),
                            max(abs(diffsOdd.x - diffsOdd.y), abs(diffsOdd.z - diffsOdd.w))     );

    return MAX2(retVal);
}

technique MeshEdges {
    pass {
        VertexShader = PostProcessVS; 
        PixelShader = MeshEdges_PS; 
        /* RenderTarget = BackBuffer */
    }
}