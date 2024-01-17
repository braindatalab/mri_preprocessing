# MRI Preprocessing with sMRIprep Pipeline

This repository documents how structural MRI brain imaging data for a large number of subjects is preprocessed using the [sMRIprep](https://www.nipreps.org/smriprep/) pipeline, which is provided as a docker image. The approach here described scales up the preprocessing by using a scheduler that runs multiple Docker instances of the pipeline in parallel.

The documentation is divided into 4 sections:

1. Downloading data
2. Setting up Docker
3. Setting up Task Spooler
4. Monitoring & error handling

Besides the documentation, this repository also contains useful shell scripts. The procedures and tools described here have been applied to MRI brain scans from more than 3600 subjects originating from the [HBN](http://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/About.html) dataset. This how-to will use the HBN dataset as an example case (referred to as the HBN project).

For functional MRI data, the closely related [fMRIprep](https://fmriprep.org/en/latest/index.html) pipeline can be used. It should be possible to apply the same procedures and tools described here.

## Downloading data

The MRI and EEG data of the [HBN dataset](http://fcon_1000.projects.nitrc.org/indi/cmi_healthy_brain_network/downloads/downloads_MRI_R1_1.html) is stored on an AWS S3 bucket, where it is organized into folders by participant.

To visually inspect the data on the S3 bucket a GUI-based file-browser like [Cyberduck](https://cyberduck.io/) can be used. For the actual download, it is more convenient to use a cli-based tool like [Rclone](https://rclone.org/).

In the case of the HBN project, the MRI data was downloaded to PTB workstation e84460 under `/scratch/hbnetdata/MRI`. As a result, the folder `MRI` contained all downloaded  participant folders. The folder structure within a participant folder is compliant with the [BIDS](https://bids-specification.readthedocs.io/en/stable/index.html) standard.

### Rclone

After installation, first create a new configuration for a remote resource with the command `rclone config` and then select option `n) New remote`. For the HBN S3 bucket, the following configuration details need to be specified (the name can be chosen arbitrarily):

```bash
name = hbn-remote
type = s3
provider = AWS
region = us-east-1
acl = private
endpoint = s3.amazonaws.com
```

To copy files from the remote resource, use the command `rclone copy`. This command can be used with the [filtering](https://rclone.org/filtering/) option  `--filter-from` to link to a filter file. This file is a simple [text file](misc/filter_example.txt) where patterns to be excluded are indicated by lines starting with `-`, and patterns to be included by lines starting with `+`.

```bash
# Rclone copy
rclone copy hbn-remote:/fcp-indi/data/Projects/HBN/MRI/Site-SI /scratch/hbnetdata/MRI/
```
```bash
# Rclone copy with --filter-from option
rclone copy --filter-from=~/filter.txt remote:/fcp-indi/data/Projects/HBN/MRI/Site-SI /scratch/hbnetdata/MRI/
```

In the case of the HBN project, the shell script [`download_script.sh`](scripts/download_script.sh) was used to start 4 concurrent `rclone copy` threads, one for each site.

## Setting up Docker

The sMRIprep pipeline is provided as a [Docker image](https://hub.docker.com/r/nipreps/smriprep/tags/). In order to run the pipeline, [Docker](https://www.docker.com/products/docker-desktop/) needs to be installed. Due to security reasons, only the [rootless version of Docker](https://docs.docker.com/engine/security/rootless/) can be installed on PTB workstations. In that case, it might be necessary to change the proxy settings of the default configuration of Docker so that it can connect to the internet, which is required for pulling images from Docker Hub.

Once Docker is running, the image of the pipeline needs to be downloaded with the command `docker pull nipreps/smriprep:latest`. Then the pipeline can be started as a Docker container instance using the `docker run` command, which is quite comprehensive:

```bash
docker run --rm \
	-v /scratch/hbnetdata/MRI:/data:ro \
	-v /scratch/hbnetdata/derivatives:/output \
	-v /scratch/hbnetdata/work:/work \
	-v $HOME/license.txt:/opt/freesurfer/license.txt \
	nipreps/smriprep:latest \
	/data /output \
	participant \
	--participant-label sub-NDARxxxxxxxx \
	--nprocs 4 \
	--omp-nthreads 8 \
	--mem-gb 8 \
	--work-dir /work \
	--output-spaces MNIPediatricAsym:cohort-2
```

The `-v` option for the `docker run` command is used to [bind-mount](https://unix.stackexchange.com/questions/198590/what-is-a-bind-mount#198591) a volume. This allows the container to access directories outside of it. For example, `-v /scratch/hbnetdata/MRI:/data:ro` implies that the folder `/MRI` outside the container is mapped to the folder `data` within the container. The suffix `:ro` denotes that the folder `/data` is read-only.

The lines following `nipreps/smriprep:latest \` are commands and arguments for the actual container instance, i.e. the pipeline. There are 3 positional arguments that need to be specified: `bids_dir`, `output_dir` and `analysis_level`. Here the `bids_dir` is set to `/data`, which is mapped to `/MRI` containing the raw participant data. The `output_dir` is set to `/output`, which is mapped to `/derivatives`. The `analysis_level` is set to `participant`, which is the default preprocessing mode.  

A container instance should only be assigned one single subject. Assigning multiple subjects results in performance drops and a longer duration per subject, and it can even lead to blocking the entire pipeline. The latter is the case when one subject in the queue takes extremely long to preprocess or does not terminate at all. 

The options `--nprocs`, `omp-nthreads` and `--mem-gb` specify what hardware resources are allocated to the container. After running performance tests, it was observed that 4 (logical) CPU cores, 8 threads and 8 GB of RAM per container delivered the best results with respect to duration.

A working directory can be specified with the `--work-dir` option and also needs to be bind-mounted beforehand with the `-v`option as part of the `docker run` command. In practice, when working with a large number of subjects to be preprocessed, the working directory grows rapidly in size and should be emptied periodically.

Please consult the [sMRIprep usage page](https://www.nipreps.org/smriprep/usage.html) for more details on additional arguments.

Useful Docker commands and options:
```bash
# Get system-wide information
docker info
```
```bash
# Automatically remove the container when it exits
docker run --rm  
```
```bash
# Allocate a pseudo-TTY connected to the container's stdin; creating an interactive `bash` shell in the container.
docker run --it
```
```bash
# Run container in background and print container ID; results in stdout stream from container not being shown in shell
docker run --detach
```
```bash
# List containers
docker ps
docker ps -f "status=exited"
```
```bash
# Display a live stream of container(s) resource usage statistics
docker stats
```
```bash
# Stop and remove container
docker container stop [OPTIONS] CONTAINER [CONTAINER...]
docker rm [OPTIONS] CONTAINER [CONTAINER...]
```
```bash
# Remove image
docker image rm [OPTIONS] IMAGE [IMAGE...]
```
## Setting up Task Spooler

[Task Spooler](https://github.com/justanhduc/task-spooler) is a light-weight scheduler for UNIX-based systems that can be used to run multiple container instances of the sMRIprep pipeline in parallel. After installation, use the command `ts` to start the scheduler.

In the case of the HBN project, the workstation provided had a CPU with 128 cores (equaling 256 CPU threads when Hyper-Threading is activated) and 1024 GB of RAM. Given that a single container requires 4 CPU threads, it is possible to run 64 instances in parallel. To ensure a safety buffer, 60 jobs instead of 64 were chosen. 

A new job can be added to the queue with the command `ts [command]`. As soon as a single job finishes, a new one is fetched from the queue and executed until the queue is empty. An individual job terminates with an exit code. Exit code`0` indicates a successful termination, `1` indicates termination with error, and `-119` is returned when the job is manually stopped. The latter is the case when using the command `docker stop [container]`to stop a container instance and, as a result, the superordinate scheduler job.

The shell script [`add-jobs.sh`](scripts/add_jobs.sh) was used to add jobs to the queue automatically. The script iterates over a list of subject-ids and executes `ts docker run [...]` for every id.

Useful Task Spooler commands:
```bash
# Start task spooler application and/or show overview
ts
```
```bash
# Specify number of jobs running in parallel
ts -S 60
```
```bash
# Get information for specific job with id
ts -i 1
```
```bash
# Clear list of finished tasks (does not reset index)
ts -C 
```
```bash
# Kill ts scheduler (does reset index when starting ts again)
ts -K 
```
## Monitoring & error handling

The preprocessing operation can be monitored using the `ts` command, which shows a list consisting of jobs currently running and those still left in the queue. For details on specific jobs, use the `ts -i` command. In addition to that, the `docker ps` command can be used to list all active containers and see how long they have been running. 

While a subject took on average 8-10 hours to preprocess with the given hardware as part of the HBN project, some subjects can take very long (multiple days) to finish, which results in blocking computing resources for a longer period of time and slowing down the overall operation. The reason for this is low-quality imaging data, which can be related to head motion or other acquisition-related factors. To mitigate this problem, one can introduce a *policy* that can be implemented in a manual or automatic way.

One such *policy* can be to discard jobs that have been running for more than a fixed amount of time. One can use the `docker ps` command to detect affected containers and discard them using the `docker stop [container]` command, resulting in the corresponding job terminating with an exit code of `-119`. This procedure can be automated with a cron job.

Other useful shell commands:
```bash
# Find all subjects that have (smriprep report) html file and store ids in txt file
ls *.html | awk -F '.' '{print $1}' | awk -F '-' '{print $2}' > html-subjects.txt
```
```bash
# Delete subject directories given file with subject ids
cat subjects_2_exclude.txt | awk '{print "/scratch/hbnetdata/MRI/sub-" $0}' | xargs -I{} rm -r{}
```
```bash
# List subjects where ts job terminated with return code 1 (assuming jobs are listed in ts queue)
ts | grep -E '^.*\s{3}1\s{3}.*$' | awk -F ' ' '{print $1}' | xargs -I{} ts -i {} | grep -oP '(--participant-label )\w+' | awk -F ' ' '{print $2}'
```

## Retrieving preprocessed data

- The derivatives for all subjects are stored in two folders: freesurfer and sMRIprep
- FreeSurfer-related statistics can be generated as csv files with the shell script [`freesurfer_stats_retrieval.sh`](scripts/fs_stats_generation.sh). The files generated by the script can be combined into one single dataframe using the notebook [`merge_fs_stats.ipynb`](misc/merge_fs_stats_files.ipynb).
- Imaging files that are located within the sMRIprep folder can be copied to a specified target location using the script [`copy_images.sh`](scripts/copy_images.sh)