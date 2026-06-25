#pragma once

#include <vector>
#include <random>

#include <godot_cpp/classes/node3d.hpp>
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
        std::vector<Vec6> particles; 
        // Field Lines
        std::vector<Vec3> e_positions;
        std::vector<Vec3> b_positions;

        std::mt19937 gen;

    protected:
        static void _bind_methods();

    public:
        Array SetParticles(int size);
        void SetFieldPositions(Array init_positions, int type);

        void AddObject(Object *g_object);
        void RemoveObject(int index);
        void UpdateObject(Object *g_object, int index);

        Array StepIntegrate(double h, int steps);
        Array StepIntegrateField(double h, int steps, int type);
};