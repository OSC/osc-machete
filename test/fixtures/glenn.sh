#PBS -l walltime=00:30:00
#PBS -l nodes=1:ppn=10
#PBS -N foobar
#PBS -j oe
#PBS -r n

echo ----
echo Job started at `date`
echo ----
echo This job is working on compute node `cat $PBS_NODEFILE`

echo "TEMP IS 80"
