#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 extent;
    float phase;
    float corner;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 point = (qt_TexCoord0 - 0.5) * extent;
    float wave = sin(3.14159265 * phase);
    float amplitude = 6.0 * wave * wave;
    vec2 halfSize = max(extent * 0.5 - vec2(amplitude + 0.5), vec2(1.0));
    float radius = min(corner, min(halfSize.x, halfSize.y));
    vec2 q = abs(point) - halfSize + radius;
    float distance = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    distance += amplitude * sin(3.0 * atan(point.y, point.x) - phase * 8.0);
    float feather = max(fwidth(distance), 0.65);
    float coverage = 1.0 - smoothstep(-feather, feather, distance);
    fragColor = texture(source, qt_TexCoord0) * coverage * qt_Opacity;
}
