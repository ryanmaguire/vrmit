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
 *      Simple benchmark in C of using RK4 with the Coulumb force.            *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 19, 2025                                                 *
 ******************************************************************************/

/*  FILE type and fprintf found here, used for writing data to a file.        */
#include <stdio.h>

/*  malloc, free, and the size_t typedef all provided here.                   */
#include <stdlib.h>

/*  Trig function sin and cos given here, used to parametrize the curve.      */
#include <math.h>

/*  clock_t typedef and the clock function, used for timing the calculation.  */
#include <time.h>

/*  Function prototypes and Vec2 and Vec4 typedefs given here.                */
#include "rk4.h"

/*  We'll use the curve gamma(t) = (cos(2 pi t), sin(2 pi t)). Provide 2 pi.  */
#define TWO_PI (+6.283185307179586E+00)

/*  Benchmark for the simple Runge-Kutta implementation in C.                 */
int main(void)
{
    /*  The number of points used to sample the curve.                        */
    const size_t n_elements = 1 << 18;

    /*  Step size for the Runge-Kutta method.                                 */
    const double h = 0.015625;

    /*  The number of steps taken during RK4.                                 */
    const size_t steps = 128;

    /*  Scale factor for parametrizing the curve, which is the unit circle.   */
    const double factor = TWO_PI / (double)(n_elements - 1);

    /*  Variable for indexing over the points in the circle.                  */
    size_t n;

    /*  Variables for computing the total amount of time needed.              */
    clock_t t0, t1;

    /*  File pointer for writing the the data. The output can easily plotted  *
     *  using a short Python script.                                          */
    FILE *fp;

    /*  Allocate memory for the points along the curve. We track both their   *
     *  position and velocity, and so we work in phase-space.                 */
    Vec4 *u = malloc(sizeof(*u) * n_elements);

    /*  Check if malloc failed before proceeding. It returns NULL if so.      */
    if (!u)
    {
        puts("malloc failed and returned NULL. Aborting.");
        return -1;
    }

    /*  Open a file for the output and given it write permissions.            */
    fp = fopen("data.txt", "w");

    /*  It is possible for fopen to fail, check for this.                     */
    if (!fp)
    {
        puts("fopen failed and returned NULL. Aborting.");

        /*  malloc successfully allocated memory for u. Free before exiting.  */
        free(u);
        return -1;
    }

    /*  Compute the initial position and velocity for the points in the curve.*/
    for (n = 0; n < n_elements; ++n)
    {
        /*  We are using gamma(t) = (cos(2 pi t), sin(2 pi t)).               */
        const double theta = (double)n * factor;
        const double sin_theta = sin(theta);
        const double cos_theta = cos(theta);

        u[n].p.x = cos_theta;
        u[n].p.y = sin_theta;

        /*  The initial velocity is simply "up" in the plane.                 */
        u[n].v.x = 0.0;
        u[n].v.y = 1.0;
    }

    /*  Start the clock and perform Runge-Kutta for each point in the curve.  */
    t0 = clock();

    integrate(coulomb, u, n_elements, h, steps);

    /*  Calculate how long the computation took.                              */
    t1 = clock();
    printf("C Time: %.6f\n", (double)(t1 - t0) / CLOCKS_PER_SEC);

    /*  Write the data to the file so we can plot it later.                   */
    for (n = 0; n < n_elements; ++n)
        fprintf(fp, "%E, %E\n", u[n].v.x, u[n].v.y);

    /*  All done, free the memory and close the file.                         */
    free(u);
    fclose(fp);

    return 0;
}
/*  End of main.                                                              */
