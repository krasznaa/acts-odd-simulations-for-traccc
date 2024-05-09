#!/usr/bin/env python3
#
# Script for running a set of ODD simulation jobs for traccc
# performance measurements.
#

# Import the necessary modules.
import argparse
import multiprocessing
import os
import random
import subprocess

def run_odd_sim(args):
   '''Run an ODD simulation job
   '''

   # Tell the user what's happening.
   print('Starting job %i/%i' % (args['job'], args['jobs']))

   # Open the output (log) files.
   output_stdout = open('%s.out' % args['output'], 'w')
   output_stderr = open('%s.err' % args['output'], 'w')

   # Start the simulation job.
   proc = subprocess.Popen( ['python3', args['script'], '--output',
                             args['output']] + args['args'],
                            stdout = output_stdout, stderr = output_stderr )
   proc.communicate()

   # Tell the user that we're done with this simulation.
   print('Finished job %i/%i' % (args['job'], args['jobs']))

   # Return successfully.
   return 0

def main():
   '''C(++) style main function
   '''

   # Parse the command line arguments.
   parser = argparse.ArgumentParser(description='ODD simulation runner')
   parser.add_argument('--acts-dir', '-a', help='Acts source directory')
   parser.add_argument('--output-dir', '-o', help='Output directory')
   args = parser.parse_args()

   # Make the output directory if it doesn't exist yet.
   if not os.path.exists(args.output_dir):
      os.makedirs(args.output_dir)
      pass

   # Figure out the directory that this script is in.
   script_dir = os.path.dirname(os.path.realpath(__file__))

   # The arguments to run the simulation for.
   parameter_pool = []

   # Add the single-muon simulations.
   for nmuon in [1, 10, 100]:
      for pt in [1, 10, 100]:
         parameter_pool += [{
            'output' : args.output_dir + ('/geant4_%imuon_%iGeV.%i' %
                                          (nmuon, pt, i)),
            'args' : ['--geant4',
                      '--gun-multiplicity', str(nmuon),
                      '--gun-pt-range', str(pt), str(pt),
                      '--events', '100',
                      '--skip', str(i * 100)],
            } for i in range(10)]
         pass

   # Add the ttbar simulations.
   for mu in [20, 40, 60, 80, 100, 140, 200, 300]:
      parameter_pool += [{
         'output' : args.output_dir + ('/geant4_ttbar_mu%i.%i' % (mu, i)),
         'args' : ['--geant4',
                   '--ttbar',
                   '--ttbar-pu', str(mu),
                   '--events', '10',
                   '--skip', str(i * 10)],
   } for i in range(50)]

   # Add some common parameters.
   ijob = 1
   for param in parameter_pool:
      param['script'] = args.acts_dir + \
                        '/Examples/Scripts/Python/sim_digi_odd.py'
      param['job'] = ijob
      param['jobs'] = len(parameter_pool)
      param['args'] += ['--digi-config',
                        script_dir + '/odd-digi-geometric-config.json',
                        '--rnd-seed', str(random.randint(0, 10000))]
      ijob += 1
      pass

   # Set up a process pool with 32 workers.
   pool = multiprocessing.Pool(32)

   # Run the simulation on all available cores in parallel.
   pool.map(run_odd_sim, parameter_pool)

   # Return successfully.
   return 0

# Execute the main function.
if __name__ == "__main__":
   import sys
   sys.exit(main())
