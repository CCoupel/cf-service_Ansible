#
# Description: <Method description here>
#
# inclure en entete de playbook:
#- name: bootstrap VMs
#  hosts: 127.0.0.1
# connection: local
#  gather_facts: false
#  tasks:
#          - name: make inventory
#            add_host: 
#              name: "{{ item.0 }}"
#              group: "{{ item.1 }}"
#              ansible_ssh_host: "{{ item.2 }}"
#            with_items:
#            - "{{ ansible_inventory }}"

prov=$evm.root["miq_provision"]
root_svc=$evm.root["service"]
until root_svc.parent_service.nil? do root_svc=root_svc.parent_service end

$evm.log(:info,"CC- prov=#{prov.inspect}")
$evm.log(:info,"CC- svc=#{root_svc.inspect}")
#$evm.log(:info,"CC- root=#{$evm.root.attributes}")

vms=root_svc.vms
inventory=[]

vms.each{|vm|
  svc=vm.direct_service
  host=[]
  host[2]=vm.ipaddresses.first rescue nil
  host[1]="all"
  host[0]=vm.name
  $evm.log(:info, "CC- adding host #{host[0]} (#{host[2]}) to group #{host[1]})")
  inventory << host
}

$evm.log(:info,"CC- VMs=#{inventory}")

#root_svc.set_dialog_option("dialog_param_ansible_inventory","#{inventory}")
root_svc.set_dialog_option("ansible_inventory",inventory)
root_svc.set_dialog_option("hosts","localhost")
