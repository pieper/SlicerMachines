# SlicerMachines
Bootable machine images with Slicer and friends preloaded

This is a work in progress.


## Overall goal
Make it easy and quick to access a Slicer desktop environment
with useful software pre-installed and ready to go.

The `aws-image` script creates a customized image that includes
nvidia drivers, X windows, and Slicer ready to run with access
via nvc.

The result is an AMI in AWS that can be used as the boot image
for a VM instance.

## Use cases
* Start up consistent GPU-enabled application environments
* Set up consistent state for testing
* Set up identical machines for training
* To access high-performance computers multicore/multi-GPU/large memory
* Pre-load a machine with data so that users can jump on and start working
* Run Slicer as a compute or render server
* Run a Slicelet as a service
* Bring up a back-end for a jupyter notebook
* Bring up as many machines as needed to run jobs in parallel

## The goal of these scripts
Automate the process of configuring and publishing the disk image
so that new versions of the OS, Slicer, and various extensions
can be easily created and made avalailable.

## Longer term goals
* port to other VM environments (e.g. Google Cloud Platform, Azure, local VMs...)
* support various Slicer Solution targets, like SlicerMorph, SlicerDMRI, etc.
* include a useful ecosystem of other tools preloaded (R, Blender, etc).
* consider creating the images on a regular basis so users can get access to the latest code
* create a simple front-end for users to boot, securely access, and manage their VM instances

## Earlier work
* https://github.com/QIICR/SlicerGCPSetup
* https://github.com/pieper/SlicerDockers

## Supported by
* NSF Advances in Biological Informatics Collaborative grant to ABI-1759883
* NIH NIMH 5R01MH119222-02 Harmonizing multi-site diffusion mri acquisitions for neuroscientific analysis across ages and brain disorders

# Usage

## Making an image
* Install and configure `aws cli` on your account
* Configure the variables at the top of `scripts/aws-image.sh`
** `KEY` is your personal security key registered with AWS
** `SLICER_EXTS` is a list of Slicer extensions to install.  Be sure to list all dependencies in reverse order or the install process will stall with a permission dialog.
* Run the script and a machine image will be created in about 10 minutes.

### Keeping a log for debug
A command linke the following is suggested:
```
 ./scripts/gcp-image.sh 2>&1 | tee gcp-log-$(date +%s)
```
or
```
 ./scripts/aws-image.sh 2>&1 | tee gcp-log-$(date +%s)
```

## Using an image

An example pulic AMI created with this script is: ami-09c0ee62c398960e7

Use it as the boot image for a machine like a `g3.4xlarge` (other g3 GPU machines should workas well).  Machines take about a minute to boot.  Be sure to request a public IP.

Once you have the machine running with a public IP you can run this to tunnel the vnc connection with whatever PEM you used and IP AWS provided.  Tunnel port 6080 as in the following example:
```
ssh -i /Users/pieper/.ssh/condatest.pem ubuntu@54.167.32.251 -L 5432:localhost:6080
```

Then connect to `localhost:5432` in your browser

Using an image from one GCP project to in a different billing project: see scripts/gcp-machine.sh


## Troubleshooting

If the connection hangs you can try running `sudo systemctl restart slicerX` and `sudo systemctl restart slicer`


## TODO
* Look at using Chrome Remote Desktop: https://cloud.google.com/solutions/chrome-desktop-remote-on-compute-engine
* Consider pre-installing other software (R-Studio, machine learning libraries, chrome, etc)

## Installing MONAILabel
Example commands to experiment with [MONAILabel](https://github.com/Project-MONAI/MONAILabel).
```
sudo apt-get install python3-pip
python3 -m pip install --upgrade pip setuptools wheel
pip3 install torch==1.9.0+cu111 torchvision==0.10.0+cu111 torchaudio===0.9.0 -f https://download.pytorch.org/whl/torch_stable.html
pip3 install git+https://github.com/Project-MONAI/MONAILabel#egg=monailabel

```
