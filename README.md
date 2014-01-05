# gentoo-install.sh

## Credits

gentoo-install.sh is forked from Michael Mol's gentoo-install script. Please see https://github.com/mikemol/gentoo-install/


## License

gentoo-install.sh installs Gentoo on a new VMware based (ESXi, VMware Workstation,VMware Fusion) virtual maschine.

Copyright (C) 2014 Frederik Schaller

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Important, Read This!

Only use this script when you know what your are doing! You need specific Gentoo knowledge if the script should be useful for you. **Note that the script partions your primary hard drive. All your data on this drive will be lost! Backup all your data before using this script!**

The Gentoo instance created by this script is **not** ready for production use.

## Overview

By default the script installs a Gentoo instance using LVM, a hardened kernel and a custom partition layout. The kernel installed by the script comes with predefined settings for a VMware based guest operating system (ESXi, VMware Workstation, VMware Fusion).

## Requirements

The script was developed to be used in a newly created VMware based virtual maschine (guest). The requirements are:

* You need a SCSI based harddrive `/dev/sda` with at least a size of 20 GB (note that the script only allocates approx. 19 GB no matter how the size of your drive is)
* You need **one** network card, if it is not an Intel's E1000 or VMXnet you have to provide a specific kernel config file

## Installation

* Download the Gentoo Live CD image from [http://www.gentoo.org/main/en/where.xml]
* Boot with `gentoo doscsi dolvm`
* Download the script with `wget https://raw.github.com/myschaller/gentoo-install/master/gentoo-install.sh /tmp/gentoo-install.sh`
* Set the execution flag for the script `chmod 755 /tmp/gentoo-install.sh`
* Adjust the settings to your needs in the configuration section `nano -w /tmp/gentoo-install.sh`
* Run the script `/tmp/gentoo-install.sh`
* Based on the specs of the maschine wait several hours ;-) The script automatically boots into the new system. The password set for root is "**Hello.**"
