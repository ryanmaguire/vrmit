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
typedef struct Vec2 {
    double x, y;
} Vec2;

/*  Struct for points in R^4, which is the phase-space of a particle in 2D.   */
typedef struct Vec4 {
    Vec2 p, v;
} Vec4;

/*  Function pointer for force functions / vector fields, F: R^2 -> R^2.      */
typedef Vec2 (*force)(const Vec2 * const);

/*  Coulomb's law in the plane, given by an inverse square law.               */
extern Vec2 coulomb(const Vec2 * const position);

/*  The Runge-Kutta vector for the phase-space differential equation.         */
extern Vec4
rk4_factor(const Vec4 * const u0, double h, const Vec4 * const u1, force f);

/*  Runge-Kutta integrator for 2D second order ODEs.                          */
extern void rk4(force f, Vec4 * const u, double h, size_t steps);

/*  Integrator for a general force over a specified number of points.         */
extern void
integrate(force f, Vec4 * const u, size_t n_elements, double h, size_t steps);

#endif
/*  End of include guard.                                                     */
