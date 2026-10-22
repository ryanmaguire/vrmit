// YUV to RGB conversion, using the ITU-R BT.601 convention

shader_type spatial;
render_mode unshaded;

uniform sampler2D camera_y; 
uniform sampler2D camera_uv;

// Fragment runs for EVERY pixel in the texture. This is important to make this conversion
void fragment() {
    // Flip the image
    vec2 fixed_uv = vec2(1.0 - UV.x, 1.0 - UV.y);
    
    // Extract values
    float y = texture(camera_y, fixed_uv).r;
    vec2 uv_val = texture(camera_uv, fixed_uv).rg - vec2(0.5, 0.5);
    
    // Standard conversion formula for YUV to RGB
    float r = y + 1.402 * uv_val.y;
    float g = y - 0.344136 * uv_val.x - 0.714136 * uv_val.y;
    float b = y + 1.772 * uv_val.x;
    
    ALBEDO = vec3(r, g, b);
}