#include <iostream>
#include <cmath>

#include "RK4Wrapper.hpp"

void RK4Wrapper::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("SetParticles", "particles", "size"), &RK4Wrapper::SetParticles);
    ClassDB::bind_method(D_METHOD("SetCharges", "charges"), &RK4Wrapper::SetCharges);
    ClassDB::bind_method(D_METHOD("StepIntegrate", "h", "steps"), &RK4Wrapper::StepIntegrate);
}

RK4Wrapper::RK4Wrapper() 
{
    UtilityFunctions::print("YAY");
}

RK4Wrapper::~RK4Wrapper() 
{
    UtilityFunctions::print("NAY");
}

void RK4Wrapper::SetParticles(Array g_particles, int size) 
{
    particles.clear();
    for (int i = 0; i < size; i++) 
    {
        Node3D *particle = Object::cast_to<Node3D>(g_particles[i]);

        if (!particle)
            continue;

        Vector3 pos = particle->get_position();

        particles.push_back(Vec6{Vec3{pos.x, pos.y, pos.z}, Vec3{0, 0, 0}});
    }
}

void RK4Wrapper::SetCharges(Array g_charges) 
{
    charges.clear();
    for (const Variant& v : g_charges)
    {
        const Dictionary c = v;

        Vector3 pos = c["location"];
        float q = c["charge"];
        
        charges.push_back(Charge{Vec3{pos.x, pos.y, pos.z}, q});
    }
}

Array RK4Wrapper::StepIntegrate(double h, int steps) 
{
    integrate(coulomb, particles.data(), particles.size(), h, static_cast<size_t> (steps), charges.data(), charges.size());

    Array states;
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> distr(-5.0, 5.0);

    for (int i = 0; i < particles.size(); i++) 
    {
        bool too_close = false;

        for (const Charge& c : charges) 
        {
            if (sqrt((particles[i].p.x - c.p.x) * (particles[i].p.x - c.p.x) +
            (particles[i].p.y - c.p.y) * (particles[i].p.y - c.p.y) +
            (particles[i].p.z - c.p.z) * (particles[i].p.z - c.p.z)) < 0.25) 
            {
                too_close = true;
                break;
            }
        }

        if (too_close || std::abs(particles[i].p.x) > 5 || abs(particles[i].p.y) > 5 || abs(particles[i].p.z) > 5) 
        {
            particles[i].v = Vec3{0, 0, 0};
            particles[i].p = Vec3{distr(gen), distr(gen), distr(gen)};

        }

        Array state;
        Vector3 pos(particles[i].p.x, particles[i].p.y, particles[i].p.z);
        Vector3 vel(particles[i].v.x, particles[i].v.y, particles[i].v.z);

        state.append(pos);
        state.append(vel);
        state.append(vel.is_zero_approx());
        states.append(state);
    }

    return states;
}