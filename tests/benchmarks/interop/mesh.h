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
 *      Provides forward declarations for the functions used in the C#        *
 *      routine, and also provides a typedef for surface functions.           *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 18, 2025                                                 *
 ******************************************************************************/

/*  Include guard to prevent including this file twice.                       */
#ifndef VRMIT_TESTS_BENCHMARKS_INTEROP_MESH_H
#define VRMIT_TESTS_BENCHMARKS_INTEROP_MESH_H

/*  Function pointer for surfaces of the form z = f(x, y).                    */
typedef double (*surface)(double, double);

/******************************************************************************
 *  Function:                                                                 *
 *      mesh                                                                  *
 *  Purpose:                                                                  *
 *      Produces a mesh for a surface.                                        *
 *  Arguments:                                                                *
 *      f (surface):                                                          *
 *          The function we are generating a surface mesh for.                *
 *      data (double *):                                                      *
 *          Array for the values of the mesh. data[width*x + y] holds         *
 *          the value of the (x, y) pixel.                                    *
 *      x_min (double):                                                       *
 *          The left edge of the rectangle under the surface.                 *
 *      x_max (double):                                                       *
 *          The right edge of the rectangle under the surface.                *
 *      y_min (double):                                                       *
 *          The bottom edge of the rectangle under the surface.               *
 *      y_max (double):                                                       *
 *          The top edge of the rectangle under the surface.                  *
 *      width (ulong):                                                        *
 *          The number of pixels in the x-axis.                               *
 *      height (ulong):                                                       *
 *          The number of pixels in the y-axis.                               *
 *  Output:                                                                   *
 *      None (void).                                                          *
 ******************************************************************************/
extern void
mesh(surface f,
     double * const data,
     double xmin, double xmax,
     double ymin, double ymax,
     size_t width, size_t height);

/******************************************************************************
 *  Function:                                                                 *
 *      gaussian                                                              *
 *  Purpose:                                                                  *
 *      Produces a 2D Gaussian, exp(-x^2 - y^2)                               *
 *  Arguments:                                                                *
 *      x (double):                                                           *
 *          The x coordinate.                                                 *
 *      y (double):                                                           *
 *          The y coordinate.                                                 *
 *  Output:                                                                   *
 *      out (double):                                                         *
 *          The Gaussian exp(-x^2 - y^2).                                     *
 ******************************************************************************/
extern double gaussian(double x, double y);

#endif
/*  End of include guard.                                                     */
