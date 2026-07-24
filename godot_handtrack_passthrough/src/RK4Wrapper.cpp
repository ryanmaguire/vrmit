#include <iostream>
#include <cmath>

#include "RK4Wrapper.hpp"

void RK4Wrapper::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("GetNetEField", "pos"), &RK4Wrapper::GetNetEField);
    ClassDB::bind_method(D_METHOD("GetNetBField", "pos"), &RK4Wrapper::GetNetBField);
    ClassDB::bind_method(D_METHOD("GetFieldColors", "positions", "type"), &RK4Wrapper::GetFieldColors);
    ClassDB::bind_method(D_METHOD("BuildFieldLines", "seeds", "h", "max_steps", "type"), &RK4Wrapper::BuildFieldLines);
    ClassDB::bind_method(D_METHOD("SetParticles", "size"), &RK4Wrapper::SetParticles);
    ClassDB::bind_method(D_METHOD("SetFieldPositions", "init_positions", "type"), &RK4Wrapper::SetFieldPositions);
    ClassDB::bind_method(D_METHOD("StepIntegrate", "h", "steps"), &RK4Wrapper::StepIntegrate);
    ClassDB::bind_method(D_METHOD("StepIntegrateField", "h", "steps", "type"), &RK4Wrapper::StepIntegrateField);
    ClassDB::bind_method(D_METHOD("AddObject", "object"), &RK4Wrapper::AddObject);
    ClassDB::bind_method(D_METHOD("RemoveObject", "index"), &RK4Wrapper::RemoveObject);
    ClassDB::bind_method(D_METHOD("UpdateObject", "object", "index"), &RK4Wrapper::UpdateObject);
}

Vector3 RK4Wrapper::GetNetEField(Vector3 pos)
{
    Vec3 p;
    p.x = pos.x;
    p.y = pos.y;
    p.z = pos.z;

    Vec3 E = net_e_field(&p, objects.data(), objects.size());
    return Vector3(E.x, E.y, E.z);
}

Vector3 RK4Wrapper::GetNetBField(Vector3 pos)
{
    Vec3 p;
    p.x = pos.x;
    p.y = pos.y;
    p.z = pos.z;

    Vec3 B = net_b_field(&p, objects.data(), objects.size());
    return Vector3(B.x, B.y, B.z);
}

PackedColorArray RK4Wrapper::GetFieldColors(const PackedVector3Array &positions, int type)
{
    const Color electric_weak(0.0, 0.35, 1.0, 1.0);
    const Color electric_strong(1.0, 0.15, 0.0, 1.0);
    const Color magnetic_weak(1.0, 0.859, 0.0, 1.0);
    const Color magnetic_strong(0.0, 0.644, 0.0, 1.0);
    const double strength_log_scale = std::log(100000.0);

    PackedColorArray colors;
    colors.resize(positions.size());

    Color *color_data = colors.ptrw();
    const Vector3 *position_data = positions.ptr();

    Color previous_color;
    Vector3 previous_position;
    bool has_previous = false;

    for (int64_t i = 0; i < positions.size(); ++i)
    {
        const Vector3 &position = position_data[i];

        // Line segments duplicate their shared endpoint. Reuse its color rather
        // than evaluating the same field twice.
        if (
            has_previous &&
            position.x == previous_position.x &&
            position.y == previous_position.y &&
            position.z == previous_position.z
        )
        {
            color_data[i] = previous_color;
            continue;
        }

        const Vec3 point = {position.x, position.y, position.z};
        Vec3 field_value = {0.0, 0.0, 0.0};
        Color weak_color(1.0, 1.0, 1.0, 1.0);
        Color strong_color(1.0, 1.0, 1.0, 1.0);

        if (type == ELECTRIC_FIELD)
        {
            field_value = net_e_field(
                &point,
                objects.data(),
                objects.size()
            );
            weak_color = electric_weak;
            strong_color = electric_strong;
        }
        else if (type == MAGNETIC_FIELD)
        {
            field_value = net_b_field(
                &point,
                objects.data(),
                objects.size()
            );
            weak_color = magnetic_weak;
            strong_color = magnetic_strong;
        }

        const double strength = std::sqrt(
            field_value.x * field_value.x +
            field_value.y * field_value.y +
            field_value.z * field_value.z
        );
        double blend = std::log1p(strength) / strength_log_scale;
        if (blend < 0.0)
            blend = 0.0;
        else if (blend > 1.0)
            blend = 1.0;

        previous_color = weak_color.lerp(strong_color, blend);
        previous_position = position;
        has_previous = true;
        color_data[i] = previous_color;
    }

    return colors;
}

Array RK4Wrapper::BuildFieldLines(const PackedVector3Array &seeds, double h, int max_steps, int type)
{
    Array output;
    if (seeds.is_empty() || max_steps <= 0)
        return output;

    field field_func = nullptr;
    if (type == ELECTRIC_FIELD)
        field_func = net_e_field_norm;
    else if (type == MAGNETIC_FIELD)
        field_func = net_b_field_norm;
    else
        return output;

    const int64_t seed_count = seeds.size();
    const bool bidirectional = type == MAGNETIC_FIELD;
    const int64_t trajectory_count =
        bidirectional ? seed_count * 2 : seed_count;
    std::vector<Vec3> positions(trajectory_count);
    std::vector<bool> active(trajectory_count, true);
    std::vector<Vec3> previous_directions(trajectory_count);
    std::vector<bool> has_previous_direction(
        trajectory_count,
        false
    );
    std::vector<std::vector<Vector3>> trajectory_points(
        trajectory_count
    );
    int64_t active_count = trajectory_count;
    const double boundary =
        type == MAGNETIC_FIELD ? 10.0 : 6.0;
    // Stop only at a true near-null. Legitimate outer dipole lines can be weak,
    // so a higher cutoff truncates them before they return to a magnet.
    const double magnetic_null_squared = 1e-12;

    const Vector3 *seed_data = seeds.ptr();
    for (int64_t i = 0; i < trajectory_count; ++i)
    {
        const int64_t seed_index = bidirectional ? i / 2 : i;
        const Vector3 &seed = seed_data[seed_index];
        positions[i] = Vec3{seed.x, seed.y, seed.z};
        trajectory_points[i].reserve(max_steps + 1);
        trajectory_points[i].push_back(seed);
    }

    for (int step = 0; step < max_steps && active_count > 0; ++step)
    {
        for (int64_t i = 0; i < trajectory_count; ++i)
        {
            if (!active[i])
                continue;

            if (type == MAGNETIC_FIELD)
            {
                const Vec3 field_value = net_b_field(
                    &positions[i],
                    objects.data(),
                    objects.size()
                );
                const double magnitude_squared =
                    field_value.x * field_value.x +
                    field_value.y * field_value.y +
                    field_value.z * field_value.z;

                if (
                    !std::isfinite(magnitude_squared) ||
                    magnitude_squared < magnetic_null_squared
                )
                {
                    active[i] = false;
                    --active_count;
                    continue;
                }
            }

            const Vec3 previous_position = positions[i];
            const double step_size =
                bidirectional && i % 2 == 1 ? -h : h;
            rk4_field(
                field_func,
                &positions[i],
                step_size,
                1,
                objects.data(),
                objects.size()
            );

            const Vec3 &position = positions[i];
            const bool invalid =
                !std::isfinite(position.x) ||
                !std::isfinite(position.y) ||
                !std::isfinite(position.z);
            const bool too_far =
                std::abs(position.x) > boundary ||
                std::abs(position.y) > boundary ||
                std::abs(position.z) > boundary;
            bool too_close = false;

            if (!invalid)
            {
                for (const FieldObject &object : objects)
                {
                    if (
                        type == ELECTRIC_FIELD &&
                        object.type != POINT_CHARGE
                    )
                        continue;
                    if (
                        type == MAGNETIC_FIELD &&
                        object.type != BAR_MAGNET
                    )
                        continue;

                    const double dx = position.x - object.p.x;
                    const double dy = position.y - object.p.y;
                    const double dz = position.z - object.p.z;
                    if (dx * dx + dy * dy + dz * dz < 0.25 * 0.25)
                    {
                        too_close = true;
                        break;
                    }
                }
            }

            bool sharp_turn = false;
            if (!invalid && type == MAGNETIC_FIELD)
            {
                const Vec3 displacement = {
                    position.x - previous_position.x,
                    position.y - previous_position.y,
                    position.z - previous_position.z
                };
                const double displacement_squared =
                    displacement.x * displacement.x +
                    displacement.y * displacement.y +
                    displacement.z * displacement.z;

                if (displacement_squared < 1e-12)
                {
                    sharp_turn = true;
                }
                else
                {
                    const double inverse_length =
                        1.0 / std::sqrt(displacement_squared);
                    const Vec3 direction = {
                        displacement.x * inverse_length,
                        displacement.y * inverse_length,
                        displacement.z * inverse_length
                    };

                    if (has_previous_direction[i])
                    {
                        const Vec3 &previous = previous_directions[i];
                        sharp_turn =
                            direction.x * previous.x +
                            direction.y * previous.y +
                            direction.z * previous.z < 0.0;
                    }

                    previous_directions[i] = direction;
                    has_previous_direction[i] = true;
                }
            }

            if (invalid || too_far || too_close || sharp_turn)
            {
                active[i] = false;
                --active_count;
                continue;
            }

            trajectory_points[i].push_back(
                Vector3(position.x, position.y, position.z)
            );
        }
    }

    output.resize(seed_count);
    for (int64_t i = 0; i < seed_count; ++i)
    {
        if (!bidirectional)
        {
            const std::vector<Vector3> &source = trajectory_points[i];
            PackedVector3Array line;
            line.resize(source.size());
            Vector3 *line_data = line.ptrw();

            for (size_t point = 0; point < source.size(); ++point)
                line_data[point] = source[point];

            output[i] = line;
            continue;
        }

        const std::vector<Vector3> &forward =
            trajectory_points[i * 2];
        const std::vector<Vector3> &backward =
            trajectory_points[i * 2 + 1];
        const size_t combined_size =
            backward.size() + forward.size() - 1;
        PackedVector3Array line;
        line.resize(combined_size);
        Vector3 *line_data = line.ptrw();
        size_t output_index = 0;

        for (auto point = backward.rbegin(); point != backward.rend(); ++point)
            line_data[output_index++] = *point;

        // The seed is already the last point copied from the backward half.
        for (size_t point = 1; point < forward.size(); ++point)
            line_data[output_index++] = forward[point];

        output[i] = line;
    }

    return output;
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
