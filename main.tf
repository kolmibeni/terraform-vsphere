terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
}   

# IMRC Private Cloud
# provider "vsphere" {
#   user           = "administrator@vsphere.local"
#   password       = "Auto63906#"
#   vsphere_server = "10.116.234.100"
#   allow_unverified_ssl = true
# }

# Test Server 
provider "vsphere" {
  user           = "administrator@vsphere.local"
  password       = "@ut0Lab95619"
  vsphere_server = "192.168.119.2"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "TestDatacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore_20"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "TestCluster"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "resource_pool" {
  name = "TestResourcePool"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "DSwitch-VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_folder" "parent" {
  path = "k8s-cluster"
  type = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# JUST SIMPLY CREATE EMPTY VM
# resource "vsphere_virtual_machine" "vm" {
#   name             = "TerraformTestVM"
#   resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id     = data.vsphere_datastore.datastore.id
#   folder = vsphere_folder.parent.id
#   wait_for_guest_net_timeout = 0

#   num_cpus         = 1
#   memory           = 1024
#   guest_id         = "other3xLinux64Guest"
#   network_interface {
#     network_id = data.vsphere_network.network.id
#   }
#   disk {
#     label = "disk0"
#     size  = 20
#   }
# }



# FOR CREATING VM FROM TEMPLATE
data "vsphere_virtual_machine" "template" {
  name          = "ubuntu_20.04_template_k8sready"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "control_plane" {
  name = "110-control-plane"
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  folder = vsphere_folder.parent.path

  num_cpus = 2
  memory = 4096

  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type

  wait_for_guest_net_timeout = 0

  disk {
    label = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]  
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = "control-plane"
        domain    = "control-plane"
      }
      network_interface {
        ipv4_address = "192.168.119.110"
        ipv4_netmask = 24
      }
      ipv4_gateway = "192.168.119.1"
    }
  }

}
  

# resource "vsphere_virtual_machine" "ansible_server" {
#   name = "120-ansible-server"
#   resource_pool_id = data.vsphere_resource_pool.resource_pool.id
#   datastore_id = data.vsphere_datastore.datastore.id
#   folder = vsphere_folder.parent.path

#   num_cpus = 2
#   memory = 4096

#   guest_id         = data.vsphere_virtual_machine.template.guest_id
#   scsi_type        = data.vsphere_virtual_machine.template.scsi_type

#   wait_for_guest_net_timeout = 0

#   disk {
#     label = "disk0"
#     size             = data.vsphere_virtual_machine.template.disks.0.size
#     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
#   }

#   network_interface {
#     network_id = data.vsphere_network.network.id
#     adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]  
#   }

#   clone {
#     template_uuid = data.vsphere_virtual_machine.template.id
#     customize {
#       linux_options {
#         host_name = "ansible-server"
#         domain    = "ansible-server"
#       }
#       network_interface {
#         ipv4_address = "192.168.119.120"
#         ipv4_netmask = 24
#       }
#       ipv4_gateway = "192.168.119.1"
#     }
#   }

# }
  