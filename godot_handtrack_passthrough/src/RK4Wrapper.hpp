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
        std::vector<Vec6> particles; 
        std::vector<Charge> charges;
        std::mt19937 gen;

    protected:
        static void _bind_methods();

    public:
        Array SetParticles(int size);
        void SetCharges(Array g_charges);
        void AddCharge(Object *g_charge);
        void UpdateCharge(Object *g_charge, int index);
        Array StepIntegrate(double h, int steps);
};