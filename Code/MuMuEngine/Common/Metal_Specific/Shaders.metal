//
//  Shaders.metal
//  MuMuEngine
//
//  Created by Nicolás Miari on 2018/08/30.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/**
 References:
 https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
 https://stackoverflow.com/a/596241/433373
 http://weblog.jamisbuck.org/2016/2/27/bloom-effect-in-metal.html
 */

/**
 Global constants (set once per draw call and shared by all vertices in that
 call; a bit like GLSL uniforms).
 */
struct Constants {
    float4x4 modelViewProjection;
    float4 tintColor;
};

/**
 Input to the VERTEX shader:
 */
struct VertexIn {
    float4 position  [[ attribute(0) ]];
    float2 texCoords [[ attribute(1) ]];
};

/**
 Output from Vertex shader, input to fragement shader.
 */
struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

/**
 Output from fragment shader.
 */
struct FragmentOut {
    float4 color0 [[ color(0)]];
    float4 color1 [[ color(1)]];
};

/**
 Vertex Function
 */
vertex VertexOut sprite_vertex_transform(const device VertexIn *vertices [[buffer(0)]],
                                         constant Constants &uniforms [[buffer(1)]],
                                         uint vertexId [[vertex_id]]) {

    float4 modelPosition = vertices[vertexId].position;

    VertexOut out;

    // Multiplying the model position by the model-view-projection matrix moves
    // us into clip space:
    out.position = uniforms.modelViewProjection * modelPosition;

    // Copy the vertex texture coordinates:
    out.texCoords = vertices[vertexId].texCoords;

    // Done
    return out;
}

/**
 Fragment Function
 */
fragment float4 sprite_fragment_textured(VertexOut fragmentIn [[stage_in]],
                                        texture2d<float, access::sample> tex2d [[texture(0)]],
                                        constant Constants &uniforms [[buffer(1)]],
                                        sampler sampler2d [[sampler(0)]]) {

     // Sample the texture to get the surface color at this point

     float4 surfaceColor = tex2d.sample(sampler2d, fragmentIn.texCoords);


     // Modulate by tint color:
    return surfaceColor * uniforms.tintColor;
}

/**
 - todo: Code a shader that renders the fragments' luminosity to the alpha
 channel of the color attachment, effectivley applying an alpha mask.
 */
/*
fragment FragmentOut sprite_fragment_textured(VertexOut fragmentIn [[stage_in]],
                                              texture2d<float, access::sample> tex2d [[texture(0)]],
                                              //constant Constants &uniforms [[buffer(0)]],
                                              sampler sampler2d [[sampler(0)]]) {

    // Outputs two colors, one to each buffer
    FragmentOut out;

    // Sample the texture to get the surface color at this point
    float4 surfaceColor = float4(tex2d.sample(sampler2d, fragmentIn.texCoords).rgba);

    float3 coefficients = float3(0.2126, 0.7152, 0.0722);
    float luma = dot(coefficients, surfaceColor.rgb) * surfaceColor.a;
    float threshold = 0.5;
    float4 black = float4(0, 0, 0, 0);

    // Color buffer:
    out.color0 = surfaceColor; // TODO: apply unifrm tint

    // Glow threshold buffer:
    out.color1 = luma > threshold ? surfaceColor :  black;

    // Done
    return out;
}*/

