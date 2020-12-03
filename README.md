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

## This code goals
Automate the process of configuring and publishing the disk image
so that new versions of the OS, Slicer, and various extensions
can be easily created and made avalailable.

## Longer term goals
* port to other VM environments (e.g. Google Cloud Platform, Azure, local VMs...)
* support various Slicer Solution targets, like SlicerMorph, SlicerDMRI, etc.
* include a useful ecosystem of other tools preloaded (R, Blender, etc).
* consider creating the images on a regular basis so users can get access to the latest code
* create a simple front-end for users to boot, access, and manage their VM instances

## Earlier work
* https://github.com/QIICR/SlicerGCPSetup
* https://github.com/pieper/SlicerDockers

## Supported by
* NSF Advances in Biological Informatics Collaborative grant to ABI-1759883
* NIH NIMH 5R01MH119222-02 Harmonizing multi-site diffusion mri acquisitions for neuroscientific analysis across ages and brain disorders
