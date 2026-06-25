#include <iostream>
#include <cmath>

#include "RK4Wrapper.hpp"

void RK4Wrapper::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("SetParticles", "size"), &RK4Wrapper::SetParticles);
    ClassDB::bind_method(D_METHOD("SetFieldPositions", "init_positions", "type"), &RK4Wrapper::SetFieldPositions);
    ClassDB::bind_method(D_METHOD("StepIntegrate", "h", "steps"), &RK4Wrapper::StepIntegrate);
    ClassDB::bind_method(D_METHOD("StepIntegrateField", "h", "steps", "type"), &RK4Wrapper::StepIntegrateField);
    ClassDB::bind_method(D_METHOD("AddObject", "object"), &RK4Wrapper::AddObject);
    ClassDB::bind_method(D_METHOD("RemoveObject", "index"), &RK4Wrapper::RemoveObject);
    ClassDB::bind_method(D_METHOD("UpdateObject", "object", "index"), &RK4Wrapper::UpdateObject);
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

void RK4Wrapper::SetFieldPositions(Array init_positions, int type) 
{

    std::vector<Vec3> * positions;
    
    if (type == ELECTRIC_FIELD) 
    {
        positions = &e_positions;
    }
    else if (type == MAGNETIC_FIELD) 
    {
        positions = &b_positions;
    }

    positions->clear();
    for (int i = 0; i < init_positions.size(); i++) 
    {
        Vector3 pos = init_positions[i];
        positions->push_back(Vec3{pos.x, pos.y, pos.z});
    }
}

void RK4Wrapper::AddObject(Object *g_object) 
{
    if (!g_object) return;

    Vector3 pos = g_object->get("pos");
    FieldObject obj;
    obj.p.x = pos.x;
    obj.p.y = pos.y;
    obj.p.z = pos.z;

    int type = g_object->get("object_type");
    if (type == POINT_CHARGE) 
    {
        float q = g_object->get("q");
        obj.type = POINT_CHARGE;
        obj.data.charge = Charge{q};
        objects.push_back(obj);
    }
    else if (type == BAR_MAGNET) 
    {
        Vector3 m = g_object->get("m");
        obj.type = BAR_MAGNET;
        obj.data.bar_magnet.m.x = m.x;
        obj.data.bar_magnet.m.y = m.y;
        obj.data.bar_magnet.m.z = m.z;
        objects.push_back(obj);
    }
}

void RK4Wrapper::RemoveObject(int index) 
{
    if (index < 0 || index >= objects.size()) return;
    objects.erase(objects.begin() + index);
}

void RK4Wrapper::UpdateObject(Object *g_object, int index) 
{
    if (!g_object) return;
    if (index < 0 || index >= objects.size()) return;

    Vector3 pos = g_object->get("pos");

    int type = g_object->get("object_type");
    if (objects[index].type != type) return;

    if (type == POINT_CHARGE) 
    {
        float q = g_object->get("q");
        objects[index].p.x = pos.x;
        objects[index].p.y = pos.y;
        objects[index].p.z = pos.z;
        objects[index].data.charge.q = q;
    }
    else if (type == BAR_MAGNET) 
    {
        Vector3 m = g_object->get("m");
        objects[index].p.x = pos.x;
        objects[index].p.y = pos.y;
        objects[index].p.z = pos.z;

        objects[index].data.bar_magnet.m.x = m.x;
        objects[index].data.bar_magnet.m.y = m.y;
        objects[index].data.bar_magnet.m.z = m.z;
    }
}


Array RK4Wrapper::StepIntegrate(double h, int steps) 
{
    integrate(net_force, particles.data(), particles.size(), h, static_cast<size_t> (steps), objects.data(), objects.size());

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

        for (const FieldObject& obj : objects) 
        {
            double dx = particles[i].p.x - obj.p.x;
            double dy = particles[i].p.y - obj.p.y;
            double dz = particles[i].p.z - obj.p.z;

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

Array RK4Wrapper::StepIntegrateField(double h, int steps, int type) 
{
    std::vector<Vec3> * positions;
    field field_func = nullptr;

    if (type == ELECTRIC_FIELD) 
    {
        positions = &e_positions;
        field_func = net_e_field_norm;
    }
    else if (type == MAGNETIC_FIELD) 
    {
        positions = &b_positions;
        field_func = net_b_field_norm;
    }
    else 
    {
        return Array();
    }

    integrate_field(field_func, positions->data(), positions->size(), h, static_cast<size_t> (steps), objects.data(), objects.size());

    Array states;
    std::uniform_real_distribution<> distr(-6.0, 6.0);

    for (int i = 0; i < positions->size(); i++) 
    {
        bool bad_value =
            !std::isfinite(positions->at(i).x) ||
            !std::isfinite(positions->at(i).y) ||
            !std::isfinite(positions->at(i).z);

        if (bad_value)
            continue;

        bool too_close = false;
        bool too_far = false;

        for (const FieldObject& obj : objects) 
        {
            double dx = positions->at(i).x - obj.p.x;
            double dy = positions->at(i).y - obj.p.y;
            double dz = positions->at(i).z - obj.p.z;

            if (dx * dx + dy * dy + dz * dz < 0.25 * 0.25)
            {
                too_close = true;
                break;
            }
        }

        if (std::abs(positions->at(i).x) > 6 || 
            std::abs(positions->at(i).y) > 6 || 
            std::abs(positions->at(i).z) > 6)
        {
            too_far = true;
        }

        Array state;
        Vector3 pos(positions->at(i).x, positions->at(i).y, positions->at(i).z);

        state.append(pos);
        state.append(too_far || too_close);

        states.append(state);
    }
    return states;
}