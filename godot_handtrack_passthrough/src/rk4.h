/******************************************************************************
 *                                  LICENSE                                   *
 ******************************************************************************
 *  This file is part of vrmit.                                               *
 *                                                                            *
 *  vrmit is free software: you can redistribute it and/or modify             *
 *  it under the terms of the GNU General Public License as published by      *
 *  the Free Software Foundation, either version 3 of the License, or         *
 *  (at your option) any later version.                                       *
 *                                                                            *
 *  vrmit is distributed in the hope that it will be useful,                  *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 *  GNU General Public License for more details.                              *
 *                                                                            *
 *  You should have received a copy of the GNU General Public License         *
 *  along with vrmit.  If not, see <https://www.gnu.org/licenses/>.           *
 ******************************************************************************
 *  Purpose:                                                                  *
 *      Provides the RK4 integrator and electromagnetic force.                *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 19, 2025                                                 *
 ******************************************************************************/

/*  Include guard to prevent including this file twice.                       */
#ifndef VRMIT_TESTS_BENCHMARKS_INTEROP_RK4_H
#define VRMIT_TESTS_BENCHMARKS_INTEROP_RK4_H

/*  size_t typedef provided here.                                             */
#include <stddef.h>

/*  Simple struct for points in the Cartesian plane.                          */
typedef struct Vec3 {
    double x, y, z;
} Vec3;

/*  Struct for points in R^4, which is the phase-space of a particle in 2D.   */
typedef struct Vec6 {
    Vec3 p, v;
} Vec6;

typedef struct Charge {
    Vec3 p;
    double q;
} Charge;

/*  Function pointer for force functions / vector fields, F: R^2 -> R^2.      */
typedef Vec3 (*force)(const Vec3 * const, const Charge * const, size_t const);

/*  Coulomb's law in the plane, given by an inverse square law.               */
extern Vec3 coulomb(const Vec3 * const position, const Charge * charges, size_t charge_count);

/*  The Runge-Kutta vector for the phase-space differential equation.         */
extern Vec6
rk4_factor(const Vec6 * const u0, double h, const Vec6 * const u1, force f, const Charge * charges, size_t charge_count);

/*  Runge-Kutta integrator for 2D second order ODEs.                          */
extern void rk4(force f, Vec6 * const u, double h, size_t steps, const Charge * charges, size_t charge_count);

/*  Integrator for a general force over a specified number of points.         */
extern void
integrate(force f, Vec6 * const u, size_t n_elements, double h, size_t steps, const Charge * charges, size_t charge_count);

#endif
/*  End of vrmitMeshInteropBenchmark.                                         */