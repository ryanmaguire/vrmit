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
 *      Provides the Mesh class for our benchmark. This contains the wrappers *
 *      for the C functions (found in mesh.c), as well as the C# equivalents. *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 18, 2025                                                 *
 ******************************************************************************/

/*  Math class, which provides Exp, found here.                               */
using System;

/*  InteropServices allows us to call native C code from a library file.      */
using System.Runtime.InteropServices;

namespace vrmitMeshInteropBenchmark
{
    /*  Class for testing the relative performance of C / C# routines.        */
    public class Mesh
    {
        /*  C equivalent of a function pointer. This can be any surface of    *
         *  the form z = f(x, y) parametrized over a rectangle in the plane.  */
        public delegate double SurfaceFunction(double x, double y);

        /*  Import the C mesh generating function. C# does not allow pointer  *
         *  syntax without using the "unsafe" block, but it does have arrays. *
         *  double[] is a substitute for double *. Similarly, C# does not     *
         *  have size_t, but ulong works provided that size_t and ulong are   *
         *  both the same size. On the machine this test was run on both      *
         *  represent 64-bit unsigned integers.                               */
        [DllImport("libmesh", EntryPoint = "mesh")]
        public static extern void
        CMesh(SurfaceFunction f,
              double[] data,
              double xmin, double xmax,
              double ymin, double ymax,
              ulong width,
              ulong height);

        /*  Import the C surface function, f(x, y) = exp(-x^2 - y^2).         */
        [DllImport("libmesh", EntryPoint = "gaussian")]
        public static extern double CGaussian(double x, double y);

        /*  Create the same Gaussian function, but in C#.                     */
        public static double CSGaussian(double x, double y)
        {
            double rsq = x*x + y*y;
            return Math.Exp(-rsq);
        }

        /**********************************************************************
         *  Function:                                                         *
         *      CSMesh                                                        *
         *  Purpose:                                                          *
         *      C# equivalent of the C mesh function. It creates the mesh for *
         *      a given surface over a specified rectangle.                   *
         *  Arguments:                                                        *
         *      f (SurfaceFunction):                                          *
         *          The function we are generating a surface mesh for.        *
         *      data (double []):                                             *
         *          Array for the values of the mesh. data[width*x + y] holds *
         *          the value of the (x, y) pixel.                            *
         *      x_min (double):                                               *
         *          The left edge of the rectangle under the surface.         *
         *      x_max (double):                                               *
         *          The right edge of the rectangle under the surface.        *
         *      y_min (double):                                               *
         *          The bottom edge of the rectangle under the surface.       *
         *      y_max (double):                                               *
         *          The top edge of the rectangle under the surface.          *
         *      width (ulong):                                                *
         *          The number of pixels in the x-axis.                       *
         *      height (ulong):                                               *
         *          The number of pixels in the y-axis.                       *
         *  Output:                                                           *
         *      None (void).                                                  *
         **********************************************************************/
        public static void
        CSMesh(SurfaceFunction f,
               double[] data,
               double x_min, double x_max,
               double y_min, double y_max,
               ulong width, ulong height)
        {
            /*  System contains DateTime, use this to time the computation.   */
            DateTime start = DateTime.Now;

            /*  We convert from the pixel plane to the Cartesian plane using  *
             *  these scale factors. The x index varies from 0 to width - 1,  *
             *  whereas the x coordinate starts at x_min and ends at x_max,   *
             *  the affine transformation:                                    *
             *                                                                *
             *                  x_max - x_min                                 *
             *      T(x_ind) =  ------------- x_ind + x_min                   *
             *                    width - 1                                   *
             *                                                                *
             *  takes us from the x index to the x value. A similar transform *
             *  exists for the y-axis, save the slopes of the transforms.     */
            double x_scale = (x_max - x_min) / (double)(width - 1);
            double y_scale = (y_max - y_min) / (double)(height - 1);

            /*  Variables for looping over the coordinate axes.               */
            ulong x_ind, y_ind;

            /*  The generated mesh is row-major, the (x, y) pixel is given by *
             *  ind = width * x + y. Loop over the x-axis first.              */
            for (x_ind = 0; x_ind < width; ++x_ind)
            {
                /*  Get the current x-coordinate using the affine transform.  */
                double x = (double)x_ind * x_scale + x_min;

                /*  The index for the pixel is x_ind * width + y_ind. Save    *
                 *  the shift factor, it makes it easier to index the array.  */
                ulong x_shift = x_ind * width;

                /*  We fix the x-coordinate and then loop along a vertical    *
                 *  strip of pixels. Compute the function along this strip.   */
                for (y_ind = 0; y_ind < width; ++y_ind)
                {
                    /*  Affine transformation for the y-coordinate.           */
                    double y = (double)y_ind * y_scale + y_min;

                    /*  Index for the (x, y) pixel.                           */
                    ulong ind = x_shift + y_ind;

                    /*  Compute and write the value to the mesh.              */
                    data[ind] = f(x, y);
                }
                /*  End of y for-loop.                                        */
            }
            /*  End of x for-loop.                                            */

            /*  Calculate how long it took to generate the mesh.              */
            DateTime end = DateTime.Now;
            TimeSpan duration = end - start;
            Console.WriteLine($"C# Time: {duration.TotalSeconds}");
        }
        /*  End of CSMesh.                                                    */
    }
    /*  End of Mesh.                                                          */
}
/*  End of vrmitMeshInteropBenchmark.                                         */
