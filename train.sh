#!/usr/bin/env bash
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    if ! pyenv which python | grep -q "neuralangelo"; then
      pyenv activate neuralangelo
    fi
    echo "Using pyenv $(pyenv version-name)"
else
    echo "Using conda"
    eval "$(conda shell.bash hook)"
    conda activate completion
fi

echo "============================="
echo "         JOB INFOS           "
echo "============================="
echo "Node List: " "$SLURM_NODELIST"
echo "Job ID: " "$SLURM_JOB_ID"
echo "Job Name:" "$SLURM_JOB_NAME"
echo "Partition: " "$SLURM_JOB_PARTITION"
echo "Submit directory:" "$SLURM_SUBMIT_DIR"
echo "Submit host:" "$SLURM_SUBMIT_HOST"
echo "Nodes:" "$SLURM_JOB_NUM_NODES"
echo "Tasks per node:" "$SLURM_NTASKS_PER_NODE"
echo "In the directory: $(pwd)"
echo "As the user: $(whoami)"
echo "Python version: $(python -c 'import sys; print(sys.version)')"
echo "pip version: $(pip --version)"

nvidia-smi

start_time=$(date +%s)
echo "Job started on $(date)"
echo

echo "============================="
echo "         JOB OUTPUT          "
echo "============================="
cd /home/humt_ma/USERDIR/git/neuralangelo

export MASTER_PORT=$(expr 10000 + $(echo -n $SLURM_JOBID | tail -c 4))
NUM_GPU=$(echo $CUDA_VISIBLE_DEVICES | tr ',' '\n' | wc -l)  

if [ "$SLURM_JOB_NAME" = "interactive" ]; then
  echo "Running in interactive mode with $NUM_GPU GPUs"
  if [ "$NUM_GPU" -eq 1 ]; then
    python train.py "$@" --single_gpu --show_pbar
  else
    torchrun --master_port="$MASTER_PORT" --nproc_per_node="$NUM_GPU" train.py "$@" --show_pbar
  fi
else
  echo "Running on SLURM with $NUM_GPU GPUs"
  if [ "$NUM_GPU" -eq 1 ]; then
    srun python train.py "$@" --single_gpu
  else
    srun torchrun --master_port=$MASTER_PORT --nproc_per_node="$NUM_GPU" train.py "$@"
  fi
fi

echo "Job ended on $(date)"
end_time=$(date +%s)
total_time=$((end_time - start_time))
echo "Job execution took " ${total_time} " s"
