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
 *      Provides a standalone C equivalent of main.cs. This function calls    *
 *      the same C routine that main.cs does, but here we simply have C       *
 *      routines calling other C routines, only a C compiler is needed.       *
 *                                                                            *
 *      This allows us to benchmark how much overhead occurs from passing the *
 *      C# data to the C routines. There is basically no difference:          *
 *                                                                            *
 *          main.c:             0.005573 Seconds                              *
 *          main.cs (C-C):      0.005688 Seconds                              *
 *          main.cs (C-C#):     0.099781 Seconds                              *
 *          main.cs (C#-C#):    0.016809 Seconds                              *
 *                                                                            *
 *      Where C-C means both the mesh routine and surface function were       *
 *      implemented in C (data was passed by C#), C-C# means the mesh         *
 *      function was implemented in C and the surface function was done in C#,*
 *      and C#-C# mean both were done in C#.                                  *
 *                                                                            *
 *      Astonishingly, having the C# routine pass data to the C functions is  *
 *      nearly identical to having the C compiler do everything. There is a   *
 *      noticeable difference between using only C# and using C / C# hybrid,  *
 *      the C / C# hybrid is about 3 times faster.                            *
 *                                                                            *
 *      While this is a small test, it likely these numbers would scale with  *
 *      larger computations.                                                  *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 18, 2025                                                 *
 ******************************************************************************/

/*  The FILE type and fprintf, used for writting data, both found here.       */
#include <stdio.h>

/*  malloc and free given here, as is the size_t typedef.                     */
#include <stdlib.h>

/*  The Gaussian and mesh function prototypes are provided here.              */
#include "mesh.h"

/*  Routine for generating a Gaussian mesh and writing it to a text file.     */
int main(void)
{
    /*  We'll be plotting over the square [-1, 1] x [-1, 1].                  */
    const double xmin = -1.0;
    const double xmax = +1.0;
    const double ymin = -1.0;
    const double ymax = +1.0;

    /*  1024 pixels in both the x and y axes, 1,048,576 pixels total.         */
    const size_t width = 1024;
    const size_t height = 1024;
    const size_t length = width * height;

    /*  Variable for indexing over the mesh array.                            */
    size_t n;

    /*  File pointer for the output text file.                                */
    FILE *fp;


    /*  Allocate memory for the data array.                                   */
    double * data = malloc(sizeof(*data) * length);

    /*  malloc returns NULL on failure. Check for this before proceeding.     */
    if (!data)
    {
        puts("malloc failed and returned NULL. Aborting.");
        return -1;
    }

    /*  Open the data file and give it write permissions.                     */
    fp = fopen("data.txt", "w");

    /*  fopen also returns NULL on error. Check for this.                     */
    if (!fp)
    {
        puts("fopen returned NULL. No file to write to. Aborting.");

        /*  malloc was successful, free the memory before aborting.           */
        free(data);
        return -1;
    }

    /*  Compute the mesh using a Gaussian surface.                            */
    mesh(gaussian, data, xmin, xmax, ymin ,ymax, width, height);

    /*  Write the data to the text file.                                      */
    for (n = 0; n < length; ++n)
        fprintf(fp, "%.15f\n", data[n]);

    /*  Free the allocated memory and close the file.                         */
    free(data);
    fclose(fp);

    return 0;
}
/*  End of main.                                                              */
