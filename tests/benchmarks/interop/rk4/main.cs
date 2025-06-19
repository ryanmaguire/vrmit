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
 *      Very simple benchmarking test for C / C# interop.                     *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 19, 2025                                                 *
 ******************************************************************************/

/*  Math class found here, which contains Cos and Sin.                        */
using System;

/*  StreamWriter found here, using for writing data to files.                 */
using System.IO;

namespace vrmitRK4InteropBenchmark
{
    /*  Class for testing the relative performance of C / C# routines.        */
    public class Benchmark
    {
        public static void ResetData(Vec4[] data, ulong n_elements)
        {
            double factor = 2.0 * Math.PI / (double)(n_elements - 1);
            ulong n;

            for (n = 0; n < n_elements; ++n)
            {
                double t = (double) n * factor;
                double cos_t = Math.Cos(t);
                double sin_t = Math.Sin(t);

                data[n].p.x = cos_t;
                data[n].p.y = sin_t;

                data[n].v.x = 0.0;
                data[n].v.y = 1.0;
            }
        }

        public static void Main(string[] args)
        {
            /*  The number of points used to sample the curve.                */
            const ulong n_elements = 1 << 18;

            /*  Step size for the Runge-Kutta method.                         */
            const double h = 0.015625;

            /*  The number of steps taken during RK4.                         */
            const ulong steps = 128;

            Vec4[] data = new Vec4[n_elements];

            ResetData(data, n_elements);

            RK4.CIntegrate(RK4.CCoulomb, data, n_elements, h, steps);

            using (StreamWriter writer = new StreamWriter("datacc.txt"))
            {
                foreach (var val in data)
                    writer.WriteLine($"{val.p.x}, {val.p.y}");
            }

            ResetData(data, n_elements);
            RK4.CIntegrate(RK4.CSCoulomb, data, n_elements, h, steps);

            using (StreamWriter writer = new StreamWriter("dataccs.txt"))
            {
                foreach (var val in data)
                    writer.WriteLine($"{val.p.x}, {val.p.y}");
            }

            ResetData(data, n_elements);
            RK4.CSIntegrate(RK4.CSCoulomb, data, n_elements, h, steps);

            using (StreamWriter writer = new StreamWriter("datacscs.txt"))
            {
                foreach (var val in data)
                    writer.WriteLine($"{val.p.x}, {val.p.y}");
            }
        }
        /*  End of Main.                                                      */
    }
    /*  End of Benchmark.                                                     */
}
/*  End of vrmitMeshInteropBenchmark.                                         */
