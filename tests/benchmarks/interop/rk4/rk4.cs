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
 *      Provides the RK4 class for our benchmark. This contains the wrappers  *
 *      for the C functions (found in rk4.cs), as well as the C# equivalents. *
 ******************************************************************************
 *  Author:     Ryan Maguire                                                  *
 *  Date:       June 19, 2025                                                 *
 ******************************************************************************/

/*  Math class, which provides Sqrt, found here.                              */
using System;

/*  InteropServices allows us to call native C code from a library file.      */
using System.Runtime.InteropServices;

namespace vrmitRK4InteropBenchmark
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct Vec2
    {
        public double x, y;

        public Vec2(double a, double b)
        {
            x = a;
            y = b;
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct Vec4
    {
        public Vec2 p, v;

        public Vec4(Vec2 pos, Vec2 vel)
        {
            p = pos;
            v = vel;
        }
    }

    /*  Class for testing the relative performance of C / C# routines.        */
    public class RK4
    {
        /*  C equivalent of a function pointer. This can be any 2D force or   *
         *  vector field F: R^2 -> R^2.                                       */
        public delegate Vec2 Force(ref Vec2 position);

        [DllImport("librk4", EntryPoint = "coulomb")]
        public static extern Vec2 CCoulomb(ref Vec2 position);

        [DllImport("librk4", EntryPoint = "rk4")]
        public static extern void
        CRK4(Force f, ref Vec4 u, double h, ulong steps);

        [DllImport("librk4", EntryPoint = "integrate")]
        public static extern void
        CIntegrate(Force f, Vec4[] u, ulong n_pts, double h, ulong size_t);

        public static Vec2 CSCoulomb(ref Vec2 position)
        {
            double rsq = position.x * position.x + position.y * position.y;
            double r = Math.Sqrt(rsq);
            double scale = 1.0 / (r * rsq);

            Vec2 outval;

            outval.x = position.x * scale;
            outval.y = position.y * scale;
            return outval;
        }

        /**********************************************************************
         *  Function:                                                         *
         *      RK4Factor                                                     *
         *  Purpose:                                                          *
         *      Computes the perturbation factors for the phase-space version *
         *      of RK4. The increment in RK4 is given by a linear combination *
         *      of 4 points in phase space, each of which has a similar       *
         *      formula. This calculates the locations of these points.       *
         *  Arguments:                                                        *
         *      u0 (ref Vec4):                                                *
         *          The current location of the point for the ODE.            *
         *      h (double):                                                   *
         *          The step size used in RK4.                                *
         *      u1 (ref Vec4):                                                *
         *          The perturbation point, these are the k_n's in            *
         *          the RK4 method.                                           *
         *      f (Force):                                                    *
         *          The force on the particle. We use Newton's 2nd law and    *
         *          apply RK4 to find the path of the particle.               *
         *  Output:                                                           *
         *      outval (Vec4):                                                *
         *          The new perturbation factor, one of the k_n terms.        *
         **********************************************************************/
        static Vec4 RK4Factor(ref Vec4 u0, double h, ref Vec4 u1, Force f)
        {
            /*  Declare a variable for the output.                            */
            Vec4 outval;

            /*  Place holder for the Euler-like step used to compute p and v. */
            Vec2 p;

            /*  u1 acts like the velocity in phase-space, and u0 is the       *
             *  position. Calculate the new point by applying Euler's method. */
            p.x = u0.p.x + h * u1.p.x;
            p.y = u0.p.y + h * u1.p.y;

            /*  Same idea, but for the velocity component in phase-space.     *
             *  Here, u1 acts as acceleration, and u0 acts as velocity.       */
            outval.p.x = u0.v.x + h * u1.v.x;
            outval.p.y = u0.v.y + h * u1.v.y;

            /*  The new velocity is given by the force at the current point.  */
            outval.v = f(ref p);

            return outval;
        }
        /*  End of RK4Factor.                                                 */

        /**********************************************************************
         *  Function:                                                         *
         *      CSRK4                                                         *
         *  Purpose:                                                          *
         *      Performs RK4 to numerical solve an ODE.                       *
         *  Arguments:                                                        *
         *      f (Force):                                                    *
         *          The force on the particle. We use Newton's 2nd law and    *
         *          apply RK4 to find the path of the particle.               *
         *      u (ref Vec4):                                                 *
         *          The initial position and velocity of the particle.        *
         *      h (double):                                                   *
         *          The step size.                                            *
         *      steps (ulong):                                                *
         *          The number of steps to perform.                           *
         *  Output:                                                           *
         *      None (void).                                                  *
         **********************************************************************/
        public static void CSRK4(Force f, ref Vec4 u, double h, ulong steps)
        {
            /*  Index for keeping track of the number of iterations performed.*/
            ulong n = 0;

            /*  Constant multiples of h used in the computation.              */
            double h0 = 0.5 * h;
            double h1 = h * 0.1666666666666667;

            /*  Current acceleration vector given by the starting position.   */
            Vec2 a = f(ref u.p);

            /*  Compute the initial Runge-Kutta factors.                      */
            Vec4 k1 = new Vec4(u.v, a);
            Vec4 k2 = RK4Factor(ref u, h0, ref k1, f);
            Vec4 k3 = RK4Factor(ref u, h0, ref k2, f);
            Vec4 k4 = RK4Factor(ref u, h, ref k2, f);

            /*  Iteratively performed RK4.                                    */
            for (n = 0; n < steps; ++n)
            {
                /*  We numerically solve d^2/dt^2 p = F(p) in two steps.      *
                 *  First we compute the velocity dp / dt, meaning we solve   *
                 *  dv / dt = F(p). We solve numerically with the Runge-Kutta *
                 *  method. We use this v to compute p via dp/dt = v, solving *
                 *  numerically again. So long as dt is small, the error      *
                 *  should be small as well. Error is O(h^4).                 */
                u.p.x += h1 * (k1.p.x + 2.0*k2.p.x + 2.0*k3.p.x + k4.p.x);
                u.p.y += h1 * (k1.p.y + 2.0*k2.p.y + 2.0*k3.p.y + k4.p.y);

                /*  Velocity component of the RK4 update.                     */
                u.v.x += h1 * (k1.v.x + 2.0*k2.v.x + 2.0*k3.v.x + k4.v.x);
                u.v.y += h1 * (k1.v.y + 2.0*k2.v.y + 2.0*k3.v.y + k4.v.y);

                /*  Update the Runge-Kutta factors.                           */
                a = f(ref u.p);

                k1.p = u.v;
                k1.v = a;

                k2 = RK4Factor(ref u, h0, ref k1, f);
                k3 = RK4Factor(ref u, h0, ref k2, f);
                k4 = RK4Factor(ref u, h, ref k2, f);
            }
        }
        /*  End of CSRK4.                                                     */

        /**********************************************************************
         *  Function:                                                         *
         *      CSIntegrate                                                   *
         *  Purpose:                                                          *
         *      Given a set of data points, performs RK4 on all of them.      *
         *  Arguments:                                                        *
         *      f (Force):                                                    *
         *          The force on the particle. We use Newton's 2nd law and    *
         *          apply RK4 to find the path of the particle.               *
         *      u (ref Vec4):                                                 *
         *          Array with the initial positions and velocities           *
         *          of the particles.                                         *
         *      n_pts (ulong):                                                *
         *          The number of elements in the "u" array.                  *
         *      h (double):                                                   *
         *          The step size.                                            *
         *      steps (ulong):                                                *
         *          The number of steps to perform.                           *
         *  Output:                                                           *
         *      None (void).                                                  *
         **********************************************************************/
        public static void
        CSIntegrate(Force f, Vec4[] u, ulong n_pts, double h, ulong steps)
        {
            /*  Variable for indexing over the array.                         */
            ulong n;

            /*  Start the clock and perform Runge-Kutta for each point.       */
            DateTime start = DateTime.Now;

            /*  Loop through each point and apply RK4.                        */
            for (n = 0; n < n_pts; ++n)
                CSRK4(f, ref u[n], h, steps);

            /*  Calculate how long it took to perform RK4.                    */
            DateTime end = DateTime.Now;
            TimeSpan duration = end - start;
            Console.WriteLine($"C# Time: {duration.TotalSeconds}");
        }
        /*  End of CSIntegrate.                                               */
    }
    /*  End of RK4.                                                           */
}
/*  End of vrmitRK4InteropBenchmark.                                          */
