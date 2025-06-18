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
 *      Very simple benchmarking test for C / C# interop. We compute a mesh   *
 *      for a Gaussian surface in three ways:                                 *
 *                                                                            *
 *          C routine using a C surface function (C-C).                       *
 *          C routine using a C# surface function (C-C#).                     *
 *          C# routine using a C# surface function (C#-C#).                   *
 *                                                                            *
 *      All routines use C# data (real numbers and arrays), and the main      *
 *      routine is done at the C# level as well. The difference is how the    *
 *      mesh function and surface function are implemented.                   *
 *                                                                            *
 *      The tests used a Gaussian surface on a 1024x1024 grid, double         *
 *      precision. Using mono for C# and GCC for C, the benchmarks produce:   *
 *                                                                            *
 *          C-C:    0.005688 Seconds                                          *
 *          C-C#:   0.016809 Seconds                                          *
 *          C#-C#:  0.099781 Seconds                                          *
 *                                                                            *
 *      So C-C > C#-C# > C-C#, with C-C being about three times faster than   *
 *      C#-C#, and C#-C# being about 6 times faster than C-C#.                *
 *                                                                            *
 *      This makes sense, passing C# data to a C function, and then having    *
 *      that C routine make calls to a different C# function (the surface     *
 *      parametrization) seems like it would be slower than just C# passing   *
 *      data to C# functions, or C data being passed between C functions.     *
 *                                                                            *
 *      The takeaway, if there are routines that can be written in C, and     *
 *      only require basic data (numbers, buffers, etc.), and not more        *
 *      complex data (function pointers / delegates), then a noticeable       *
 *      improvement can be made by doing this.                                *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 18, 2025                                                 *
 ******************************************************************************/

/*  The "Array" class is found here, used for clearing the data array.        */
using System;

/*  StreamWriter found here, using for writing data to files.                 */
using System.IO;

namespace vrmitMeshInteropBenchmark
{
    /*  Class for testing the relative performance of C / C# routines.        */
    public class Benchmark
    {
        /*  Main routine for generating our 1024x1024 mesh.                   */
        public static void Main(string[] args)
        {
            /*  We'll be plotting over the square [-1, 1]x[-1, 1].            */
            const double xmin = -1.0;
            const double xmax = +1.0;
            const double ymin = -1.0;
            const double ymax = +1.0;

            /*  1024 pixels in both the x and y axes, 1,048,576 pixels total. */
            const ulong width = 1024;
            const ulong height = 1024;

            /*  Data array for the mesh. It is 1D, the (x, y) pixel is given  *
             *  by the index x * width + y. We may safely pass this array to  *
             *  C functions that want double pointers.                        */
            double[] data = new double[width * height];

            /*  Initialize the data to zero.                                  */
            Array.Clear(data, 0, data.Length);

            /*  C mesh routine with a C Gaussian. Pass data from C# to C.     */
            Mesh.CMesh(
                Mesh.CGaussian, data, xmin, xmax, ymin ,ymax, width, height
            );

            /*  Write the data to a text file. Plots are made in Python.      */
            using (StreamWriter writer = new StreamWriter("datacc.txt"))
            {
                foreach (var val in data)
                    writer.WriteLine(val);
            }

            /*  For fair benchmarks, reset the data to zero for the next set. */
            Array.Clear(data, 0, data.Length);

            /*  C# mesh routine with C# Gaussian. Simply call the function.   */
            Mesh.CSMesh(
                Mesh.CSGaussian, data, xmin, xmax, ymin ,ymax, width, height
            );

            /*  Write the C#-C# data, make sure the file name is different.   */
            using (StreamWriter writer = new StreamWriter("datacscs.txt"))
            {
                foreach (var val in data)
                    writer.WriteLine(val);
            }

            /*  Once again, clear out data for the next set.                  */
            Array.Clear(data, 0, data.Length);

            /*  C mesh routine with C# Gaussian. The C routine expects a      *
             *  function pointer, the C# interop allows a delegate to take    *
             *  the place of such a variable. Pass the data to the C function.*/
            Mesh.CMesh(
                Mesh.CSGaussian, data, xmin, xmax, ymin ,ymax, width, height
            );

            using (StreamWriter writer = new StreamWriter("dataccs.txt"))
            {
                foreach (var val in data)
                {
                    writer.WriteLine(val);
                }
            }
        }
        /*  End of Main.                                                      */
    }
    /*  End of Benchmark.                                                     */
}
/*  End of vrmitMeshInteropBenchmark.                                         */
