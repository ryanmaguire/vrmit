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
 *      Provides the mesh function and the Gaussian surface.                  *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 18, 2025                                                 *
 ******************************************************************************/

/*  printf found here. We'll print the processing time in the mesh function.  */
#include <stdio.h>

/*  The exponential function, exp, is provided here.                          */
#include <math.h>

/*  clock_t type and clock function found here.                               */
#include <time.h>

/*  Forward declarations and surface typedef given here.                      */
#include "mesh.h"

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
double gaussian(double x, double y)
{
    const double rsq = x*x + y*y;
    return exp(-rsq);
}

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
void
mesh(surface f,
     double * const data,
     double x_min, double x_max,
     double y_min, double y_max,
     size_t width, size_t height)
{
    /*  We'll time how long the computation takes. Get the current time.      */
    const clock_t t1 = clock();

    /*  Variable for the ending time.                                         */
    clock_t t2;

    /*  Variables for looping over the x and y axes.                          */
    size_t x_ind, y_ind;

    /*  We convert from the pixel plane to the Cartesian plane using these    *
     *  scale factors. The x index varies from 0 to width - 1, whereas the x  *
     *  coordinate starts at x_min and ends at x_max, hence the affine        *
     *  transformation T given by:                                            *
     *                                                                        *
     *                  x_max - x_min                                         *
     *      T(x_ind) =  ------------- x_ind + x_min                           *
     *                    width - 1                                           *
     *                                                                        *
     *  takes us from the x index to the x value. A similar transform may be  *
     *  defined for the y-axis, save the slopes of these transforms.          */
    const double x_scale = (x_max - x_min) / (double)(width - 1);
    const double y_scale = (y_max - y_min) / (double)(height - 1);

    /*  The generated mesh is row-major, the (x, y) pixel is given by         *
     *  ind = width * x + y. Loop over the x-axis first.                      */
    for (x_ind = 0; x_ind < width; ++x_ind)
    {
        /*  Get the current x-coordinate using the affine transform.          */
        const double x = (double)x_ind * x_scale + x_min;

        /*  The index for the pixel is x_ind * width + y_ind. Save the shift  *
         *  factor, it makes it easier to index the array.                    */
        const size_t x_shift = x_ind * width;

        /*  We fix the x-coordinate and then loop along a vertical strip of   *
         *  pixels. Compute the function along this strip.                    */
        for (y_ind = 0; y_ind < width; ++y_ind)
        {
            /*  Affine transformation for the y-coordinate.                   */
            const double y = (double)y_ind * y_scale + y_min;

            /*  Index for the (x, y) pixel.                                   */
            const size_t ind = x_shift + y_ind;

            /*  Compute and write the value to the mesh.                      */
            data[ind] = f(x, y);
        }
        /*  End of y for-loop.                                                */
    }
    /*  End of x for-loop.                                                    */

    /*  Get this final time and print how long this took to compute.          */
    t2 = clock();
    printf("C Time:  %.6f\n", (double)(t2 - t1) / CLOCKS_PER_SEC);
}
/*  End of mesh.                                                              */
