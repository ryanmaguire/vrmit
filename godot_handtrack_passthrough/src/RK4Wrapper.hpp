#pragma once

#include <vector>
#include <random>

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/typed_dictionary.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector3.hpp>

extern "C" 
{
    #include "rk4.h"
}

using namespace godot;

class RK4Wrapper : public Node3D
{
    GDCLASS(RK4Wrapper, Node3D)

    private:
        std::vector<FieldObject> objects;
        // Particle Flow
        std::vector<Vec6> solar_bodies, solar_workspace;
        std::vector<float> solar_masses;
        std::vector<Vec6> particles; 
        // Field Lines
        std::vector<Vec3> e_positions;
        std::vector<Vec3> b_positions;

        std::mt19937 gen;

    protected:
        static void _bind_methods();

    public:
        Vector3 GetNetEField(Vector3 pos);
        Vector3 GetNetBField(Vector3 pos);
        PackedColorArray GetFieldColors(const PackedVector3Array &positions, int type);
        Array BuildFieldLines(const PackedVector3Array &seeds, float h, int max_steps, int type);

        bool SetSolarBodies(const PackedVector3Array &positions, const PackedVector3Array &velocities, const PackedFloat32Array &masses);
        PackedVector3Array StepSolarSystem(float h);

        Array SetParticles(int size);
        void SetFieldPositions(Array init_positions, int type);

        void AddObject(Object *g_object);
        void RemoveObject(int index);
        void UpdateObject(Object *g_object, int index);

        Array StepIntegrate(float h, int steps);
        Array StepIntegrateField(float h, int steps, int type);
};
