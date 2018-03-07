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


@inventory=root_svc.get_dialog_option("ansible_inventory") rescue []
$evm.log(:info,"    CC- (#{@inventory.class}) inventory=#{@inventory} ")

def add_vm_to_group_inventory(vm,group)
  $evm.log(:info,"    CC- adding vm #{vm.name} to group #{group} from #{@inventory}")
  index=@inventory.index{|a| a[0]==vm.name} rescue @inventory.length
  host=@inventory[index] rescue [vm.name,group,(vm.ipaddresses.first rescue nil)]
  groups=host[1]
  groups=groups+",#{group}"
  host[1]=groups
  @inventory[index]=host
  
  $evm.log(:info,"    CC- group=#{group} vm=#{vm.name} host=#{host} inventory=#{@inventory}")
end

def add_group(svc)
  svc.vms.each{ |vm|
    add_vm_to_group_inventory(vm,svc.name)
  }
end

def mk_inventory(parent_svc)
  $evm.log(:info,"CC- grouping service #{parent_svc.name}")
  add_group(parent_svc)
  parent_svc.direct_service_children.each{|svc|
    $evm.log(:info,"  CC- adding group #{svc.name} to parent")
    mk_inventory(svc)
  }
end


mk_inventory(root_svc)
$evm.log(:info,"CC- groups=#{@inventory}")

#root_svc.set_dialog_option("dialog_param_ansible_groups","#{inventory_groups}")
root_svc.set_dialog_option("ansible_inventory",@inventory)
