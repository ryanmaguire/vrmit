#include <iostream>
#include <cmath>

#include "RK4Wrapper.hpp"

void RK4Wrapper::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("SetParticles", "size"), &RK4Wrapper::SetParticles);
    ClassDB::bind_method(D_METHOD("SetCharges", "charges"), &RK4Wrapper::SetCharges);
    ClassDB::bind_method(D_METHOD("StepIntegrate", "h", "steps"), &RK4Wrapper::StepIntegrate);
    ClassDB::bind_method(D_METHOD("AddCharge", "charge"), &RK4Wrapper::AddCharge);
    ClassDB::bind_method(D_METHOD("UpdateCharge", "charge", "index"), &RK4Wrapper::UpdateCharge);
}

Array RK4Wrapper::SetParticles(int size) 
{
    Array initial_positions;
    particles.clear();
    std::uniform_real_distribution<> distr(-6.0, 6.0);

    for (int i = 0; i < size; i++) 
    {
        particles.push_back(Vec6{Vec3{distr(gen), distr(gen), distr(gen)}, Vec3{0, 0, 0}});
        initial_positions.append(Vector3(particles[i].p.x, particles[i].p.y, particles[i].p.z));
    }

    return initial_positions;
}

void RK4Wrapper::SetCharges(Array g_charges) 
{
    charges.clear();
    for (int i = 0; i < g_charges.size(); i++)
    {
        Object *obj = Object::cast_to<Object>(g_charges[i]);

        Vector3 pos = obj->get("pos");
        float q = obj->get("q");
        
        charges.push_back(Charge{Vec3{pos.x, pos.y, pos.z}, q});
    }
}

void RK4Wrapper::AddCharge(Object *g_charge) 
{
    Vector3 pos = g_charge->get("pos");
    float q = g_charge->get("q");
    
    charges.push_back(Charge{Vec3{pos.x, pos.y, pos.z}, q});
}

void RK4Wrapper::UpdateCharge(Object *g_charge, int index) 
{
    if (!g_charge) return;
    if (index < 0 || index >= charges.size()) return;

    Vector3 pos = g_charge->get("pos");
    float q = g_charge->get("q");

    charges[index].p.x = pos.x;
    charges[index].p.y = pos.y;
    charges[index].p.z = pos.z;
    charges[index].q = q;
}


Array RK4Wrapper::StepIntegrate(double h, int steps) 
{
    integrate(coulomb, particles.data(), particles.size(), h, static_cast<size_t> (steps), charges.data(), charges.size());

    Array states;
    std::uniform_real_distribution<> distr(-6.0, 6.0);

    for (int i = 0; i < particles.size(); i++) 
    {
        bool bad_value =
            !std::isfinite(particles[i].p.x) ||
            !std::isfinite(particles[i].p.y) ||
            !std::isfinite(particles[i].p.z) ||
            !std::isfinite(particles[i].v.x) ||
            !std::isfinite(particles[i].v.y) ||
            !std::isfinite(particles[i].v.z);
        bool too_close = false;
        bool regenerated = false;

        for (const Charge& c : charges) 
        {
            double dx = particles[i].p.x - c.p.x;
            double dy = particles[i].p.y - c.p.y;
            double dz = particles[i].p.z - c.p.z;

            if (dx * dx + dy * dy + dz * dz < 0.25 * 0.25)
            {
                too_close = true;
                break;
            }
        }

        if (bad_value || too_close || std::abs(particles[i].p.x) > 6 || std::abs(particles[i].p.y) > 6 || std::abs(particles[i].p.z) > 6) 
        {
            particles[i].v = Vec3{0, 0, 0};
            particles[i].p = Vec3{distr(gen), distr(gen), distr(gen)};
            regenerated = true;
        }

        Array state;
        Vector3 pos(particles[i].p.x, particles[i].p.y, particles[i].p.z);
        Vector3 vel(particles[i].v.x, particles[i].v.y, particles[i].v.z);

        state.append(pos);
        state.append(vel);
        state.append(regenerated);
        states.append(state);
    }

    return states;
}