// Jonathans Changes:
// 1. Modified RK4 class functions/variables to use newly defined Vec3/6 instead of previously defined Vec2/4
// 2. Added a RK4 Wrapper

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
using System.Collections.Generic;
using Godot;
using System.Xml;
using System.Numerics;

namespace vrmitRK4InteropBenchmark
{
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
	public struct Vec3
	{
		public double x, y, z;

		public Vec3(double a, double b, double c)
		{
			x = a;
			y = b;
			z = c;
		}
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
	public struct Vec6
	{
		public Vec3 p, v;

		public Vec6(Vec3 pos, Vec3 vel)
		{
			p = pos;
			v = vel;
		}
	}

	public struct Charge
	{
		public Vec3 p;
		public double q;

		public Charge(Vec3 pos, double charge)
		{
			p = pos;
			q = charge;
		}
	}

	/*  Class for testing the relative performance of C / C# routines.        */
	public class RK4
	{
		/*  C equivalent of a function pointer. This can be any 2D force or   *
		 *  vector field F: R^2 -> R^2.                                       */
		public delegate Vec3 Force(ref Vec3 position);

		[DllImport("librk4", EntryPoint = "coulomb")]
		public static extern Vec3 CCoulomb(ref Vec3 position);

		[DllImport("librk4", EntryPoint = "rk4")]
		public static extern void
		CRK4(Force f, ref Vec6 u, double h, ulong steps);

		[DllImport("librk4", EntryPoint = "integrate")]
		public static extern void
		CIntegrate(Force f, Vec6[] u, ulong n_pts, double h, ulong size_t);

 		public static Vec3 CSCoulomb(ref Vec3 position)
		{
			double rsq = (position.x * position.x) + (position.y * position.y) + (position.z * position.z);
			double r = Math.Sqrt(rsq);
			double scale = 1.0 / (r * rsq);

			Vec3 outval;

			outval.x = position.x * scale;
			outval.y = position.y * scale;
			outval.z = position.z * scale;
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
		static Vec6 RK4Factor(ref Vec6 u0, double h, ref Vec6 u1, Force f)
		{
			/*  Declare a variable for the output.                            */
			Vec6 outval;

			/*  Place holder for the Euler-like step used to compute p and v. */
			Vec3 p;

			/*  u1 acts like the velocity in phase-space, and u0 is the       *
			 *  position. Calculate the new point by applying Euler's method. */
			p.x = u0.p.x + h * u1.p.x;
			p.y = u0.p.y + h * u1.p.y;
			p.z = u0.p.z + h * u1.p.z;

			/*  Same idea, but for the velocity component in phase-space.     *
			 *  Here, u1 acts as acceleration, and u0 acts as velocity.       */
			outval.p.x = u0.v.x + h * u1.v.x;
			outval.p.y = u0.v.y + h * u1.v.y;
			outval.p.z = u0.v.z + h * u1.v.z;

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
		 *      u (ref Vec6):                                                 *
		 *          The initial position and velocity of the particle.        *
		 *      h (double):                                                   *
		 *          The step size.                                            *
		 *      steps (ulong):                                                *
		 *          The number of steps to perform.                           *
		 *  Output:                                                           *
		 *      None (void).                                                  *
		 **********************************************************************/
		public static void CSRK4(Force f, ref Vec6 u, double h, ulong steps)
		{
			/*  Index for keeping track of the number of iterations performed.*/
			ulong n = 0;

			/*  Constant multiples of h used in the computation.              */
			double h0 = 0.5 * h;
			double h1 = h * 0.1666666666666667;

			/*  Current acceleration vector given by the starting position.   */
			Vec3 a = f(ref u.p);

			/*  Compute the initial Runge-Kutta factors.                      */
			Vec6 k1 = new Vec6(u.v, a);
			Vec6 k2 = RK4Factor(ref u, h0, ref k1, f);
			Vec6 k3 = RK4Factor(ref u, h0, ref k2, f);
			Vec6 k4 = RK4Factor(ref u, h, ref k3, f);

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
				u.p.z += h1 * (k1.p.z + 2.0*k2.p.z + 2.0*k3.p.z + k4.p.z);

				/*  Velocity component of the RK4 update.                     */
				u.v.x += h1 * (k1.v.x + 2.0*k2.v.x + 2.0*k3.v.x + k4.v.x);
				u.v.y += h1 * (k1.v.y + 2.0*k2.v.y + 2.0*k3.v.y + k4.v.y);
				u.v.z += h1 * (k1.v.z + 2.0*k2.v.z + 2.0*k3.v.z + k4.v.z);

				/*  Update the Runge-Kutta factors.                           */
				a = f(ref u.p);

				k1.p = u.v;
				k1.v = a;

				k2 = RK4Factor(ref u, h0, ref k1, f);
				k3 = RK4Factor(ref u, h0, ref k2, f);
				k4 = RK4Factor(ref u, h, ref k3, f);
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
		 *      u (ref Vec6):                                                 *
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
		CSIntegrate(Force f, Vec6[] u, ulong n_pts, double h, ulong steps)
		{
			/*  Variable for indexing over the array.                         */
			ulong n;

			/*  Start the clock and perform Runge-Kutta for each point.       */
			//DateTime start = DateTime.Now;

			/*  Loop through each point and apply RK4.                        */
			for (n = 0; n < n_pts; ++n)
				CSRK4(f, ref u[n], h, steps);

			/*  Calculate how long it took to perform RK4.                    */
			/*DateTime end = DateTime.Now;
			TimeSpan duration = end - start;
			Console.WriteLine($"C# Time: {duration.TotalSeconds}");*/
		}
		/*  End of CSIntegrate.                                               */
	}
	/*  End of RK4.                                                           */
	public partial class RK4Wrapper : Node3D
	{
		private Vec6[] _particles; // Contains every particle's state (position, velocity)
		private int _particles_size; // size of _particles array
		//private Vec6 _state;
		private List<Charge> _charges = new List<Charge>(); // Vec3, charge
		private Random _rand = new Random();

		public void SetParticles(Godot.Collections.Array particles, int size)
		{
			_particles_size = size;
			_particles = new Vec6[_particles_size];
			for (int i = 0; i < size; i++)
			{
				Node3D particle = (Node3D) particles[i];
				Godot.Vector3 pos = particle.Position;
				_particles[i] = new Vec6(new Vec3(pos.X, pos.Y, pos.Z), new Vec3(0, 0, 0));
			}
		}

		public void SetCharges(Godot.Collections.Array charges)
		{
			_charges.Clear();
			foreach (Godot.Collections.Dictionary d in charges)
			{
				Godot.Vector3 pos = (Godot.Vector3) d["location"];
				float q = (float) d["charge"];

				_charges.Add(new Charge(
					new Vec3(pos.X, pos.Y, pos.Z), q
				));
			}
		}
		public Vec3 NetColoumbForce(ref Vec3 position)
		{
			Vec3 net_outval = new Vec3(0.0, 0.0, 0.0);
			foreach (Charge c in _charges)
			{
				double dx = (position.x - c.p.x);
				double dy = (position.y - c.p.y);
				double dz = (position.z - c.p.z);
				double rsq = (dx * dx) + (dy * dy) + (dz * dz);

				double r = Math.Sqrt(rsq);
				double scale = c.q / (r * rsq);

				net_outval.x += dx * scale;
				net_outval.y += dy * scale;
				net_outval.z += dz * scale;
			}

			return net_outval;
		}

		public Godot.Collections.Array StepIntegrate(double h, int steps)
		{
			RK4.CSIntegrate(NetColoumbForce, _particles, (ulong) _particles_size, h, (ulong) steps);

			Godot.Collections.Array states = new Godot.Collections.Array(); 

			for (int i = 0; i < _particles_size; i++)
			{
				bool too_close = false;

				foreach(Charge charge in _charges)
				{
					if (Math.Sqrt((_particles[i].p.x - charge.p.x) * (_particles[i].p.x - charge.p.x) +
					(_particles[i].p.y - charge.p.y) * (_particles[i].p.y - charge.p.y) + 
					(_particles[i].p.z - charge.p.z) * (_particles[i].p.z - charge.p.z)) < 0.25)
					{
						too_close = true;
						break;
					}
				}

				if (too_close || Math.Abs(_particles[i].p.x) > 9 || Math.Abs(_particles[i].p.y) > 9 || Math.Abs(_particles[i].p.z) > 9)
				{
					_particles[i].v = new Vec3(0, 0, 0);
					_particles[i].p = new Vec3(
						(float)(-6 + 12 * _rand.NextDouble()),
						(float)(-6 + 12 * _rand.NextDouble()),
						(float)(-6 + 12 * _rand.NextDouble())
					);
				}
				Godot.Collections.Array state = new Godot.Collections.Array();
				state.Add(new Godot.Vector3((float) _particles[i].p.x, (float) _particles[i].p.y, (float) _particles[i].p.z));
				state.Add(new Godot.Vector3((float) _particles[i].v.x, (float) _particles[i].v.y, (float) _particles[i].v.z));

				states.Add(state);
			}
			return states;
		}
	}
}
/*  End of vrmitRK4InteropBenchmark.                                          */
