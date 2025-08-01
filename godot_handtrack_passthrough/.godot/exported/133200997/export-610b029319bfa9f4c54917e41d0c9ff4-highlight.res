RSRC                    ShaderMaterial            ��������                                            I      resource_local_to_scene    resource_name    output_port_for_preview    default_input_values    expanded_output_ports    linked_parent_graph_frame    parameter_name 
   qualifier    default_value_enabled    default_value    script    op_type 	   operator 	   constant    code    graph_offset    mode    modes/blend    modes/depth_draw    modes/cull    modes/diffuse    modes/specular    flags/depth_prepass_alpha    flags/depth_test_disabled    flags/sss_mode_skin    flags/unshaded    flags/wireframe    flags/skip_vertex_transform    flags/world_vertex_coords    flags/ensure_correct_normals    flags/shadows_disabled    flags/ambient_light_disabled    flags/shadow_to_opacity    flags/vertex_lighting    flags/particle_trails    flags/alpha_to_coverage     flags/alpha_to_coverage_and_one    flags/debug_shadow_splits    flags/fog_disabled    nodes/vertex/0/position    nodes/vertex/connections    nodes/fragment/0/position    nodes/fragment/2/node    nodes/fragment/2/position    nodes/fragment/3/node    nodes/fragment/3/position    nodes/fragment/4/node    nodes/fragment/4/position    nodes/fragment/5/node    nodes/fragment/5/position    nodes/fragment/6/node    nodes/fragment/6/position    nodes/fragment/connections    nodes/light/0/position    nodes/light/connections    nodes/start/0/position    nodes/start/connections    nodes/process/0/position    nodes/process/connections    nodes/collide/0/position    nodes/collide/connections    nodes/start_custom/0/position    nodes/start_custom/connections     nodes/process_custom/0/position !   nodes/process_custom/connections    nodes/sky/0/position    nodes/sky/connections    nodes/fog/0/position    nodes/fog/connections    render_priority 
   next_pass    shader    shader_parameter/Color        -   local://VisualShaderNodeColorParameter_nl6jr 	      '   local://VisualShaderNodeVectorOp_8dcmn G	      ,   local://VisualShaderNodeFloatConstant_2331j �	      &   local://VisualShaderNodeFresnel_tghd5 �	      '   local://VisualShaderNodeVectorOp_wy3ip 
         local://VisualShader_wb0u4 O
      5   res://addons/godot-xr-tools/materials/highlight.tres �         VisualShaderNodeColorParameter             Color 
         VisualShaderNodeVectorOp                                               ?   ?   ?         
         VisualShaderNodeFloatConstant          ���=
         VisualShaderNodeFresnel    
         VisualShaderNodeVectorOp             
         VisualShader          C  shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 Color : source_color;



void fragment() {
// ColorParameter:2
	vec4 n_out2p0 = Color;


// FloatConstant:4
	float n_out4p0 = 0.100000;


// VectorOp:3
	vec3 n_out3p0 = vec3(n_out2p0.xyz) * vec3(n_out4p0);


// Fresnel:5
	float n_in5p3 = 1.00000;
	float n_out5p0 = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), n_in5p3);


// VectorOp:6
	vec3 n_out6p0 = vec3(n_out2p0.xyz) * vec3(n_out5p0);


// Output:0
	ALBEDO = n_out3p0;
	EMISSION = n_out6p0;


}
 )   
     %D  pB*             +   
      B   B,            -   
     �C  pB.            /   
     �A  4C0            1   
      B  �C2            3   
     �C  \C4                                                                                             
         ShaderMaterial    E          F          G            H      ���>���>��|?  �?
      RSRC