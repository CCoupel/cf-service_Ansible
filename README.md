# cf-service_Ansible
Prepare service before calling Ansible Bootstrap Playbook
It will make a dynamic inventory for Ansible based on root service name hierachie and "Ansible" category tags.
The "check_servers" playbook test the connectivity of all VM to determine wether it is a linux or a Windows and make groups based on it.

# How to integrate:
1- create a catalogitem called ansible_Bootstrap for example.
  make this catalogitem based on the bootstrap.yml playbook
  define the mandatory extra_vars:
  - playbooks: the default value is the attribut name of the instance that will call the catalogitem (let say also playbooks)
  - ansible_inventory: the default value is the attribut name of the instance that will call the catalogitem (let say also ansible_inventory)
2- create a new dialog based on this catalog item
3- create a button to call the Ansible post config service from a service
    namespace: Service/Provisioning/StateMachines 
    class: StateMachines_Ansible
    instance: Ansible_Post_config_VM 
4- the instance called has the attributes:
  - playbook: the playbook to run after the bootstrap
  - svc_vm_vms: (not yet implemented) describe how the service is run:
      - svc: the ansible service is launched on all VMs of the service the request is started
      - vms: when called from a vm object, the inventory is made with all the vms of the parent service
      - vm: an Ansible service is run on each vm of the service
# add extra vars:
to include extra-vars for the playbooks, for example the extra var "external_page" with value "http://ext_page"
1- in the instance "call_Ansible_Post_config_VM" set the value '"http://ext_page"' as extravar1 attribute, don't forget the double cote to indicate that the attribute is a string. You can set any ruby code for value as it goes throu eval method.
2- update the catalogitem to add the extravar definition. The name is the extravar name as used in the playbook ("http://ext_page"), the value is the name of the attribute describing the value (extravar1).
3- update the dialog by creating a new one.
