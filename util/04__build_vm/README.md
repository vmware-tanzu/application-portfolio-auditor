This directory contains the scripts and descriptors to package and test "Application Portfolio Auditor" within a Virtual machine.

[Vagrant](https://www.vagrantup.com/) is used to build virtual machines managed using [VirtualBox](https://www.virtualbox.org/) and provisioned with [Ansible](https://www.ansible.com/) scripts.

While you will be able to run the created VMs wherever you want, those instructions and scripts have only been written and tested on MacOS.


## Prerequisites

To build VMs and test "Application Portfolio Auditor" following those instructions, you will need to have [Vagrant](https://www.vagrantup.com/) incl. some additional plugins, [VirtualBox](https://www.virtualbox.org/) and [Ansible](https://www.ansible.com/) installed.

Install Vagrant, Ansible & VirtualBox

    $ brew install ansible vagrant virtualbox

    # Optional for VMware provider on Mac 
    # Note: Might have to reinstall the driver in case of "communications error with the Vagrant VMware Utility driver"
    brew install --cask vagrant-vmware-utility

Install required vagrant plugins

    $ vagrant plugin install vagrant-vbguest

    # Does NOT work on ARM at the moment (https://github.com/sprotheroe/vagrant-disksize/issues/45)
    $ vagrant plugin install vagrant-disksize

    # To run on ARM hardware
    $ vagrant plugin install vagrant-vmware-desktop


## Build and test VMs

1. Retrieve and copy locally the latest "Application Portfolio Auditor" [distribution](https://via.vmw.com/arg-release) you want to use. 

2. Edit `build_vm_centos.sh` or `build_vm_ubuntu.sh` to point to the distribution you want to use (set `DIST_ZIP` to point to your local copy of the zipped distribution).

3. Run either `build_vm_centos.sh` or `build_vm_ubuntu.sh` to build either a CentOS or Ubuntu VM and get a test report generated and copied to your local `/tmp` directory.


## Manual execution

### Ansible

To run the Ansible scripts manually on the VM, execute the following command:

    $ export ANSIBLE_HOST_KEY_CHECKING=false
    $ export DIST_ZIP="/PATH_TO_ZIP_DISTRIBUTION/application-portfolio-auditor__$(date +"%Y_%m_%d").zip"
    $ ansible-playbook ansible-auditor-centos.yml -i ansible-inventory --extra-vars "auditor_local_zip=${DIST_ZIP}" -v

### Vagrant

Some useful Vagrant commands

    # Destroy the CentOS VM
    $ vagrant destroy -f application-portfolio-auditor-centos

    # Stop the CentOS VM
    $ vagrant halt application-portfolio-auditor-centos

    # SSH into the CentOS VM
    $ vagrant ssh application-portfolio-auditor-centos

Copy files from running instance

    $ vagrant plugin install vagrant-scp
    $ vagrant scp <some_local_file_or_dir> [vm_name]:<somewhere_on_the_vm>


### Build and execute everything

The following command will update the tools, build a full zipped distribution and then build a CentOS VM:

    $ ./util/01__setup/download_and_update_tools.sh; ./util/00__release/bundle_scripts.sh; ./util/04__package/build_vm.sh


## Exporting the VM 

### (Optional) Make some adjustments to the VM

Example - adding specific rules to the VM:

    $ vagrant scp /your/local/custom-bins.yaml application-portfolio-auditor-centos:/opt/auditor/application-portfolio-auditor/conf/CSA/custom-bins.yaml
    $ vagrant scp /your/local/custom-rules.yaml application-portfolio-auditor-centos:/opt/auditor/application-portfolio-auditor/conf/CSA/custom-rules/.

### Cleanup the VM before exporting

    $ vagrant ssh application-portfolio-auditor-centos
    $ sudo yum clean all
    $ history -c
    $ exit

### Export the VM

Stop the running instance of your virtual machine:

    $ vagrant halt

Export the VM by opening VirtualBox and opening the "File -> Export appliance" menu. Then configure the settings at will to export the VM as an OVA file.

The default user / password for VMs created with vagrant are `vagrant` / `vagrant`. Application Portfolio Auditor is in the `/opt/auditor/application-portfolio-auditor` folder.
