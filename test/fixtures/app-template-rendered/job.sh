#PBS -l walltime=00:30:00
#PBS -l nodes=1:ppn=12
#PBS -N foobar
#PBS -j oe
#PBS -r n

echo ----
echo Job started at `date`
echo ----
echo This job is working on compute node `cat $PBS_NODEFILE`

echo "TEMP IS 80"

cd $PBS_O_WORKDIR
echo show what PBS_O_WORKDIR is
echo PBS_O_WORKDIR IS `pwd`
echo ----
echo The contents of PBS_O_WORKDIR:
ls -ltr
echo
echo ----
echo
echo creating a file in PBS_O_WORKDIR
whoami > whoami-pbs-o-workdir

cd $TMPDIR
echo ----
echo TMPDIR IS `pwd`
echo ----
echo wait for 42 seconds
sleep 42
echo ----
echo creating a file in TMPDIR
whoami > whoami-tmpdir

# copy the file back to the output subdirectory
pbsdcp -g $TMPDIR/whoami-tmpdir $PBS_O_WORKDIR/output

echo ----
echo Job ended at `date`